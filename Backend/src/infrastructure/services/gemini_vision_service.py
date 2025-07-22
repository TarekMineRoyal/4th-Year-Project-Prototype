import time
import io
import structlog
from PIL import Image
from fastapi import HTTPException
import google.generativeai as genai
from google.api_core import exceptions as google_exceptions  # Import google exceptions

from src.application.services.vision_service import VisionService
from src.domain.entities import ImageFile, AnalysisResult

logger = structlog.get_logger(__name__)


class GeminiVisionService(VisionService):
    """
    A concrete implementation of the VisionService that uses the Google Gemini API.
    """

    def __init__(self):
        pass

    def analyze_image(
            self,
            image: ImageFile,
            prompt: str,
            model_option: str
    ) -> AnalysisResult:
        """
        Analyzes an image using the specified Gemini model with an increased timeout.
        """
        logger.info(
            "Attempting to analyze image with Gemini.",
            model_option=model_option
        )

        if model_option == "llava":
            logger.warning("Unsupported model requested.", model_option="llava")
            raise HTTPException(status_code=400, detail="Llava model is not supported in this service.")

        try:
            img = Image.open(io.BytesIO(image.content))

            start_time = time.time()
            logger.debug("Sending request to Gemini API.")

            model = genai.GenerativeModel(model_option)

            # --- THE FIX ---
            # Set a longer timeout for the API request (e.g., 120 seconds).
            # The default is often too short for complex image analysis.
            request_options = {"timeout": 120}

            # Pass the request_options to the generate_content call
            response = model.generate_content(
                [prompt, img],
                request_options=request_options
            )
            # --- END FIX ---

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

        # Add specific handling for the timeout error
        except google_exceptions.DeadlineExceeded:
            logger.error("Gemini API call timed out after 120 seconds.")
            raise HTTPException(
                status_code=504,
                detail="The request to the AI model timed out. Please try again."
            )
        except Exception as e:
            logger.exception("An unexpected error occurred communicating with Gemini API.")
            raise HTTPException(
                status_code=500,
                detail=f"An error occurred with the vision model: {str(e)}"
            )