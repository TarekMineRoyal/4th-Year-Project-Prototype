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
from PIL import Image
from dotenv import load_dotenv
import google.generativeai as genai

# === Application Configuration ===
# Environment Variables
load_dotenv()

# Configure the Gemini API client
try:
    genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
except TypeError:
    logging.warning("Gemini API key not found. Gemini models will not be available.")

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
@app.post("/vqa")
async def vqa_endpoint(
        option: str = Form(..., description="Model name (e.g., 'gemini-1.5-flash', 'llava')"),
        question: str = Form(..., description="Question about the image"),
        image: UploadFile = File(..., description="Image file")
):
    """Visual Question Answering endpoint"""
    upload_path = save_uploaded_image(image)
    logger.info(f"VQA request received for model '{option}' with question: '{question}'")

    system_prompt = """You are a helpful and cautious AI assistant for a visually impaired user. Your primary goal is to provide clear, accurate, and safe information about the user's surroundings based on an image.

Follow these rules for every response:
1. Safety First: Your absolute first priority is the user's safety. If you see any potential hazards (sharp objects, hot surfaces, obstacles, spills, things that might fall), mention them clearly and upfront before answering the user's question.
2. Be Direct: Directly answer the user's specific question first.
3. Be Concise: After answering the question, you may add one brief, relevant sentence of context if necessary. Avoid long, poetic descriptions.
4. State Uncertainty: If you are not sure about something, say so clearly. It is better to say "I can't be certain" than to guess."""

    prompt = f"{system_prompt}\n\nUser's Question: '''{question}'''"
    answer = ""
    processing_time = 0.0

    try:
        if option in ["gemini-1.5-flash-latest", "gemini-2.5-flash-preview-05-20"]:
            logger.info(f"Using Gemini model: {option}")
            img = None
            try:
                img = Image.open(upload_path)
                start_time = time.time()

                model = genai.GenerativeModel(option)
                response = model.generate_content([prompt, img])

                processing_time = round(time.time() - start_time, 2)
                answer = response.text
            finally:
                if img:
                    img.close()  # Ensure the image file is closed


        elif option == "llava":
            model = "llava:latest"
            logger.info(f"Model used: {model}")
            with open(upload_path, "rb") as image_file:
                image_base64 = base64.b64encode(image_file.read()).decode('utf-8')
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
            raise HTTPException(400, f"Invalid model option received: {option}")

        # Move the file after all operations are complete
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
    except Exception as e:
        logger.error(f"VQA processing error: {e}", exc_info=True)
        raise HTTPException(500, "Internal server error")

# Add this new endpoint to your Backend/main.py file

@app.post("/ocr")
async def ocr_endpoint(
        image: UploadFile = File(..., description="Image file with text")
):
    """Optical Character Recognition endpoint"""
    upload_path = save_uploaded_image(image)
    logger.info("OCR request received")

    prompt = "Extract all text from this image exactly as it appears. If there is no text, say so."
    text_response = ""
    processing_time = 0.0

    try:
        img = None
        try:
            img = Image.open(upload_path)
            start_time = time.time()

            # Use the same Gemini model you use for VQA
            model = genai.GenerativeModel('gemini-2.5-flash-preview-05-20')
            response = model.generate_content([prompt, img])

            processing_time = round(time.time() - start_time, 2)
            text_response = response.text
        finally:
            if img:
                img.close()  # Ensure the image file is closed

        # Move the analyzed file
        analyzed_path = os.path.join(
            ANALYZED_DIR,
            f"ocr_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{Path(upload_path).name}"
        )
        shutil.move(upload_path, analyzed_path)

        return {
            "status": "success",
            "text": text_response,
            "processing_time": processing_time
        }
    except Exception as e:
        logger.error(f"OCR processing error: {e}", exc_info=True)
        raise HTTPException(500, "Internal server error")

# === Application Entry Point ===
if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")

