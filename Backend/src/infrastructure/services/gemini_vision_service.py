import time
import io
import structlog
from PIL import Image
from fastapi import HTTPException
import google.generativeai as genai

from src.application.services.vision_service import VisionService
from src.domain.entities import ImageFile, AnalysisResult

# Get a logger instance for this module
logger = structlog.get_logger(__name__)


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
        logger.info(
            "Attempting to analyze image with Gemini.",
            model_option=model_option
        )

        # We handle Llava as an exception for now, but in a real scenario,
        # it would have its own service implementation.
        if model_option == "llava":
            logger.warning("Unsupported model requested.", model_option="llava")
            raise HTTPException(status_code=400, detail="Llava model is not supported in this service.")

        try:
            # Open image from bytes
            img = Image.open(io.BytesIO(image.content))

            start_time = time.time()

            logger.debug("Sending request to Gemini API.")
            model = genai.GenerativeModel(model_option)
            response = model.generate_content([prompt, img])

            processing_time = round(time.time() - start_time, 2)

            logger.info(
                "Received response from Gemini successfully.",
                processing_time=processing_time,
                response_length=len(response.text)
            )

            return AnalysisResult(
                text=response.text,
                processing_time=processing_time
            )

        except Exception as e:
            # logger.exception will automatically include stack trace info
            logger.exception("Error communicating with Gemini API.")
            # We still raise an HTTPException to give a clean error to the user.
            # The detailed error is now in our logs.
            raise HTTPException(status_code=500, detail=f"An error occurred with the vision model: {str(e)}")