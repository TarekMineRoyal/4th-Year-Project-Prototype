import shutil
from datetime import datetime
from pathlib import Path
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from ultralytics import YOLO
from PIL import Image
import time
import os
import logging
from huggingface_hub import InferenceClient  # New import

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI()

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["POST"],
    allow_headers=["*"],
)

# Directory setup
UPLOAD_DIR = "uploads"
ANALYZED_DIR = "analyzed"
Path(UPLOAD_DIR).mkdir(exist_ok=True)
Path(ANALYZED_DIR).mkdir(exist_ok=True)

MODEL_PATHS = {
    "yolov8n": "D:/DEV/Forth Year Project/prototype/Backend/models/yolov8n.pt",
    "yolov8m": "D:/DEV/Forth Year Project/prototype/Backend/models/yolov8m.pt",
    "yolov8x": "D:/DEV/Forth Year Project/prototype/Backend/models/yolov8x.pt"
}

# Hugging Face API setup
client = InferenceClient(
    provider="hf-inference",
    api_key="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",
)

def model_type_loader(option: str):
    """Load model from local path with enhanced error handling"""
    try:
        if option not in MODEL_PATHS:
            raise ValueError(f"Unknown model option: {option}")

        model_path = MODEL_PATHS[option]
        if not os.path.exists(model_path):
            raise FileNotFoundError(f"Model file not found at: {model_path}")

        logger.info(f"Loading model: {model_path}")
        model = YOLO(model_path)
        logger.info(f"Successfully loaded model: {option}")
        return model

    except Exception as e:
        logger.error(f"Model loading failed: {str(e)}")
        raise


@app.post("/upload")
async def upload_image(
        option: str = Form(...),
        image: UploadFile = File(...)
):
    try:
        # 1. Validate and save image
        if not image.content_type.startswith('image/'):
            raise HTTPException(400, detail="Only image files allowed")

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        file_ext = os.path.splitext(image.filename)[1]
        upload_path = os.path.join(UPLOAD_DIR, f"upload_{timestamp}{file_ext}")

        logger.info(f"Saving uploaded file to: {upload_path}")
        with open(upload_path, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)

        # 2. Load YOLO model
        model = model_type_loader(option)

        # 3. Process with YOLO
        logger.info("Starting YOLO processing")
        start_time = time.time()

        img = Image.open(upload_path)
        if img.mode != 'RGB':
            img = img.convert('RGB')

        results = model(img)  # YOLO inference
        processing_time = round(time.time() - start_time, 2)
        logger.info(f"YOLO processing completed in {processing_time}s")

        # 4. Generate caption with BLIP

        # output = client.image_to_text(img, model="Salesforce/blip-image-captioning-base")
        logger.info("Generating caption with BLIP")
        with open(upload_path, "rb") as f:
            image_bytes = f.read()

        try:

            caption_result = client.image_to_text(image_bytes, model="Salesforce/blip-image-captioning-base")
            caption = caption_result.generated_text  # Extracting the actual text
        except Exception as e:
            logger.warning("BLIP captioning failed, using default message")
            caption = "Caption generation failed"

        # 5. Move to analyzed directory
        analyzed_path = os.path.join(ANALYZED_DIR, f"analyzed_{timestamp}{file_ext}")
        shutil.move(upload_path, analyzed_path)
        logger.info(f"Moved file to: {analyzed_path}")

        # 6. Format detections
        detections = []
        for result in results:
            for box in result.boxes:
                detections.append(
                    f"{result.names[int(box.cls)]} ({float(box.conf) * 100:.1f}%)"
                )
        print(caption)
        return {
            "detections": detections,
            "caption": caption,
            "processing_time": processing_time
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Processing failed: {str(e)}", exc_info=True)
        raise HTTPException(500, detail=str(e))


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")