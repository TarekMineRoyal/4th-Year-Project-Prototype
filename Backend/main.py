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
from transformers import pipeline

# === Application Configuration ===
# Environment Variables
load_dotenv()

# Logging Setup
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# FastAPI Setup
app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["POST"],
    allow_headers=["*"],
)

# Directory Configuration
UPLOAD_DIR = "uploads"
ANALYZED_DIR = "analyzed"
Path(UPLOAD_DIR).mkdir(exist_ok=True)
Path(ANALYZED_DIR).mkdir(exist_ok=True)

# Model Paths (configured via environment variables)
MODEL_PATHS = {
    "yolov8n": os.getenv("MODEL_YOLOv8n"),
    "yolov8m": os.getenv("MODEL_YOLOv8m"),
    "yolov8x": os.getenv("MODEL_YOLOv8x"),
    "blip-vqa-base": "models/blip-vqa-base"
}

# Hugging Face Client
client = InferenceClient(
    provider="hf-inference",
    api_key=os.getenv("HF_API_KEY")
)


# === Model Management ===
def model_type_loader(option: str) -> YOLO:
    """Load YOLO model with validation and error handling"""
    try:
        if option not in MODEL_PATHS:
            raise ValueError(f"Unsupported model: {option}")

        model_path = MODEL_PATHS[option]
        if not os.path.exists(model_path):
            raise FileNotFoundError(f"Missing model file: {model_path}")

        logger.info(f"Loading model: {model_path}")
        model = YOLO(model_path)
        logger.info(f"Model loaded successfully: {option}")
        return model

    except Exception as e:
        logger.error(f"Model loading error: {str(e)}")
        raise


# === Helper Functions ===
def save_uploaded_image(image: UploadFile) -> str:
    """Validate image type and save with timestamp"""
    if not image.content_type.startswith('image/'):
        raise HTTPException(400, "Invalid file type - only images allowed")

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    file_ext = os.path.splitext(image.filename)[1]
    save_path = os.path.join(UPLOAD_DIR, f"upload_{timestamp}{file_ext}")

    with open(save_path, "wb") as buffer:
        shutil.copyfileobj(image.file, buffer)

    return save_path


# === API Endpoints ===
@app.post("/upload")
async def upload_image(
        option: str = Form(..., description="Model type (yolov8n/m/x)"),
        image: UploadFile = File(..., description="Image file")
):
    """Object detection and image captioning endpoint"""
    try:
        # Image Validation & Storage
        upload_path = save_uploaded_image(image)
        logger.info(f"Image received: {upload_path}")

        # Model Execution
        model = model_type_loader(option)
        img = Image.open(upload_path).convert('RGB')

        # Object Detection
        start_time = time.time()
        results = model(img)
        processing_time = round(time.time() - start_time, 2)
        logger.info(f"Detection completed in {processing_time}s")

        # Caption Generation
        try:
            with open(upload_path, "rb") as f:
                caption = client.image_to_text(
                    f.read(),
                    model="Salesforce/blip-image-captioning-base"
                ).generated_text
        except Exception:
            logger.warning("Caption generation failed", exc_info=True)
            caption = "Caption unavailable"

        # File Management
        analyzed_path = os.path.join(
            ANALYZED_DIR,
            f"analyzed_{datetime.now().strftime('%Y%m%d_%H%M%S')}{Path(upload_path).suffix}"
        )
        shutil.move(upload_path, analyzed_path)

        # Result Formatting
        detections = [
            f"{result.names[int(box.cls)]} ({float(box.conf) * 100:.1f}%)"
            for result in results
            for box in result.boxes
        ]

        return {
            "status": "success",
            "detections": detections,
            "caption": caption,
            "processing_time": processing_time,
            "analyzed_path": analyzed_path
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error("Processing error", exc_info=True)
        raise HTTPException(500, "Internal server error")


@app.post("/vqa")
async def vqa_endpoint(
        option: str = Form(..., description="Must be 'blip-vqa-base'"),
        question: str = Form(..., description="Question about the image"),
        image: UploadFile = File(..., description="Image file")
):
    """Visual Question Answering endpoint"""
    try:
        # Input Validation
        if option != "blip-vqa-base":
            raise HTTPException(400, "Invalid model option")

        upload_path = save_uploaded_image(image)
        logger.info(f"VQA request received: {question}")

        # Model Initialization
        vqa_pipeline = pipeline(
            "visual-question-answering",
            model=MODEL_PATHS[option],
            device=-1  # -1 for CPU, 0+ for GPU
        )

        # Inference Execution
        start_time = time.time()
        img = Image.open(upload_path).convert('RGB')
        result = vqa_pipeline(question=question, image=img)
        processing_time = round(time.time() - start_time, 2)

        # File Management
        analyzed_path = os.path.join(
            ANALYZED_DIR,
            f"vqa_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{Path(upload_path).name}"
        )
        shutil.move(upload_path, analyzed_path)

        return {
            "status": "success",
            "answer": result[0]['answer'],
            "processing_time": processing_time,
            "analyzed_path": analyzed_path
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error("VQA processing error", exc_info=True)
        raise HTTPException(500, "Internal server error")


# === Application Entry Point ===
if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")