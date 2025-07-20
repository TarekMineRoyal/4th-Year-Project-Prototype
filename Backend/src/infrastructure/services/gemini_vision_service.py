import time
import logging
from PIL import Image
import io
from fastapi import HTTPException
import google.generativeai as genai

from src.application.services.vision_service import VisionService
from src.domain.entities import ImageFile, AnalysisResult


class GeminiVisionService(VisionService):
    """
    A concrete implementation of the VisionService that uses the Google Gemini API.
    """

    def __init__(self):
        # The configuration is expected to be loaded once at startup.
        # We can add a check here if needed.
        pass

    def analyze_image(
            self,
            image: ImageFile,
            prompt: str,
            model_option: str
    ) -> AnalysisResult:
        """
        Analyzes an image using the specified Gemini model.
        """
        logging.info(f"Sending request to Gemini model: {model_option}")

        # We handle Llava as an exception for now, but in a real scenario,
        # it would have its own service implementation.
        if model_option == "llava":
            raise HTTPException(status_code=400, detail="Llava model is not supported in this service.")

        try:
            # Open image from bytes
            img = Image.open(io.BytesIO(image.content))

            start_time = time.time()

            model = genai.GenerativeModel(model_option)
            response = model.generate_content([prompt, img])

            processing_time = round(time.time() - start_time, 2)

            logging.info(f"Received response from Gemini in {processing_time}s.")

            return AnalysisResult(
                text=response.text,
                processing_time=processing_time
            )

        except Exception as e:
            logging.error(f"Error communicating with Gemini API: {e}", exc_info=True)
            raise HTTPException(status_code=500, detail=f"An error occurred with the vision model: {str(e)}")