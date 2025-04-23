# === Imports ===
# Standard Library
import base64
import requests
import json
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
    "blip-vqa-base": os.getenv("BILP_VQA_BASE"),
    "llava": os.getenv("LLAVA"),
    "bakllava" : os.getenv("BAKLLAVA"),
    "moondream" : os.getenv("MOONDREAM"),
    "chat-gph-vision" : os.getenv("GPH_VISION"),
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
        upload_path = save_uploaded_image(image)
        logger.info(f"Image received: {upload_path}")

        model = model_type_loader(option)
        img = Image.open(upload_path).convert('RGB')

        start_time = time.time()
        results = model(img)
        processing_time = round(time.time() - start_time, 2)
        logger.info(f"Detection completed in {processing_time}s")

        try:
            with open(upload_path, "rb") as f:
                caption = client.image_to_text(
                    f.read(),
                    model="Salesforce/blip-image-captioning-base"
                ).generated_text
        except Exception:
            logger.warning("Caption generation failed", exc_info=True)
            caption = "Caption unavailable"

        analyzed_path = os.path.join(
            ANALYZED_DIR,
            f"analyzed_{datetime.now().strftime('%Y%m%d_%H%M%S')}{Path(upload_path).suffix}"
        )
        shutil.move(upload_path, analyzed_path)

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
        option: str = Form(..., description="Model type ('blip-vqa-base' or 'llava')"),
        question: str = Form(..., description="Question about the image"),
        image: UploadFile = File(..., description="Image file")
):
    """Visual Question Answering endpoint"""
    try:
        # To be removed later:
        if option == "vqa_model_2": option = "llava"
        upload_path = save_uploaded_image(image)
        logger.info(f"VQA request received: {question}")

        if option == "blip-vqa-base":
            vqa_pipeline = pipeline(
                "visual-question-answering",
                model=MODEL_PATHS[option],
                device=-1
            )
            img = Image.open(upload_path).convert('RGB')
            start_time = time.time()
            result = vqa_pipeline(question=question, image=img)
            processing_time = round(time.time() - start_time, 2)
            answer = result[0]['answer']

        elif option == "llava" or option == "bakllava" or option == "moondream" or option == "chat-gph-vision":
            if option == "chat-gph-vision": model = "mskimomadto/chat-gph-vision"
            else: model = option
            logger.info(f"Model used: {model}")
            with open(upload_path, "rb") as image_file:
                image_base64 = base64.b64encode(image_file.read()).decode('utf-8')
            prompt = f"{question}"

            start_time = time.time()
            ollama_url = "http://localhost:11434/api/generate"
            payload = {
                "model": model,
                "prompt": prompt,
                "stream": False,
                "images": [image_base64]
            }

            response = requests.post(ollama_url, data=json.dumps(payload))
            response.raise_for_status()
            processing_time = round(time.time() - start_time, 2)
            answer = response.json().get("response", "No answer received")

        else:
            raise HTTPException(400, "Invalid model option")

        analyzed_path = os.path.join(
            ANALYZED_DIR,
            f"vqa_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{Path(upload_path).name}"
        )
        shutil.move(upload_path, analyzed_path)

        return {
            "status": "success",
            "answer": answer,
            "processing_time": processing_time,
            "analyzed_path": analyzed_path
        }

    except requests.exceptions.RequestException as e:
        logger.error(f"Ollama API error: {str(e)}")
        raise HTTPException(503, "Llava model service unavailable")
    except HTTPException:
        raise
    except Exception as e:
        logger.error("VQA processing error", exc_info=True)
        raise HTTPException(500, "Internal server error")


# === Application Entry Point ===
if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")