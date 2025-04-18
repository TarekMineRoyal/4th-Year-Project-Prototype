# === Imports ===
# Standard Library
import shutil
from datetime import datetime
from pathlib import Path
import os
import logging
import time

# Third-Party
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from ultralytics import YOLO
from PIL import Image
from huggingface_hub import InferenceClient
from dotenv import load_dotenv

# === App Configuration ===
# Load environment variables
load_dotenv()

# Logging Configuration
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI()

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["POST"],
    allow_headers=["*"],
)

# Directory Setup
UPLOAD_DIR = "uploads"
ANALYZED_DIR = "analyzed"
Path(UPLOAD_DIR).mkdir(exist_ok=True)
Path(ANALYZED_DIR).mkdir(exist_ok=True)

# Model Configuration
MODEL_PATHS = {
    "yolov8n": os.getenv("MODEL_YOLOv8n"),
    "yolov8m": os.getenv("MODEL_YOLOv8m"),
    "yolov8x": os.getenv("MODEL_YOLOv8x")
}

# Hugging Face Inference Client
client = InferenceClient(
    provider="hf-inference",
    api_key=os.getenv("HF_API_KEY")
)


# === Model Loading Function ===
def model_type_loader(option: str) -> YOLO:
    """Load YOLO model with error handling and logging"""
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


# === Helper Functions ===
def save_uploaded_image(image: UploadFile) -> str:
    """Validate and save uploaded image with timestamp"""
    if not image.content_type.startswith('image/'):
        raise HTTPException(400, detail="Only image files allowed")

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    file_ext = os.path.splitext(image.filename)[1]
    upload_path = os.path.join(UPLOAD_DIR, f"upload_{timestamp}{file_ext}")

    with open(upload_path, "wb") as buffer:
        shutil.copyfileobj(image.file, buffer)

    return upload_path


# === API Endpoints ===
@app.post("/upload")
async def upload_image(
        option: str = Form(...),
        image: UploadFile = File(...)
):
    try:
        # 1. Save and validate image
        upload_path = save_uploaded_image(image)
        logger.info(f"Image saved to: {upload_path}")

        # 2. Load selected YOLO model
        model = model_type_loader(option)

        # 3. Perform object detection
        start_time = time.time()
        img = Image.open(upload_path).convert('RGB')
        results = model(img)
        processing_time = round(time.time() - start_time, 2)
        logger.info(f"YOLO processing completed in {processing_time}s")

        # 4. Generate image caption with BLIP
        try:
            with open(upload_path, "rb") as f:
                image_bytes = f.read()
            caption_result = client.image_to_text(
                image_bytes,
                model="Salesforce/blip-image-captioning-base"
            )
            caption = caption_result.generated_text
        except Exception as e:
            logger.warning("BLIP captioning failed, using default message", exc_info=True)
            caption = "Caption generation failed"

        # 5. Move processed file to analyzed directory
        analyzed_path = os.path.join(
            ANALYZED_DIR,
            f"analyzed_{datetime.now().strftime('%Y%m%d_%H%M%S')}{os.path.splitext(upload_path)[1]}"
        )
        shutil.move(upload_path, analyzed_path)
        logger.info(f"File moved to: {analyzed_path}")

        # 6. Format detection results
        detections = []
        for result in results:
            for box in result.boxes:
                detections.append(
                    f"{result.names[int(box.cls)]} ({float(box.conf) * 100:.1f}%)"
                )

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


# === Entry Point ===
if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")