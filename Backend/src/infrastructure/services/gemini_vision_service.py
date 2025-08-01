import time
import structlog
import io
from PIL import Image
from fastapi import HTTPException
import google.generativeai as genai
from google.api_core import exceptions as google_exceptions
from src.application.services.vision_service import VisionService
from src.domain.entities import AnalysisResult
from src.domain.entities import VideoFile, ImageFile

logger = structlog.get_logger(__name__)

class GeminiVisionService(VisionService):
    """
    A concrete implementation of the VisionService that uses the Google Gemini API.
    """

    def __init__(self, timeout: int):
        """
        Initializes the Gemini Vision Service.
        Configures the genai library with an API key if provided.
        """
        #if api_key:
        #    genai.configure(api_key=api_key)
        self.timeout = timeout
        logger.info("GeminiVisionService initialized.", timeout=self.timeout)

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

        try:
            img = Image.open(io.BytesIO(image.content))

            start_time = time.time()
            logger.debug("Sending request to Gemini API.")

            model = genai.GenerativeModel(model_option)

            request_options = {"timeout": 120}

            # Pass the request_options to the generate_content call
            response = model.generate_content(
                [prompt, img],
                request_options=request_options
            )

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

    def analyze_video(
            self,
            video: VideoFile,
            prompt: str,
            model_option: str
    ) -> AnalysisResult:
        """
        Analyzes a video from a file path by uploading it to the Gemini API's file service.
        This method no longer needs to handle temporary files.
        """
        logger.info("Attempting to analyze video with Gemini.", model_option=model_option)

        #video_file_api_obj = None
        try:
            start_time = time.time()

            # 1. Upload the video file
            client = genai.Client()
            video_file = client.files.upload(file=video / video.filename)

            # 3. Make the generation request using the processed video file
            model = genai.GenerativeModel(model_option)
            request_options = {"timeout": self.timeout}
            response = model.generate_content([prompt, video_file], request_options=request_options)

            processing_time = round(time.time() - start_time, 2)
            logger.info("Video analysis successful.", processing_time=processing_time)
            return AnalysisResult(text=response.text, processing_time=processing_time)

        except google_exceptions.DeadlineExceeded:
            logger.error("Gemini API call for video analysis timed out.", timeout=self.timeout)
            raise HTTPException(status_code=504, detail="The request to the AI model for video analysis timed out.")
        except Exception as e:
            logger.exception("An unexpected error occurred during video analysis with Gemini API.")
            raise HTTPException(status_code=500, detail=f"An error occurred with the vision model: {str(e)}")

    def analyze_text(
            self,
            prompt: str,
            model_option: str
    ) -> AnalysisResult:
        """
        Analyzes a text-only prompt using the specified Gemini model.
        """
        logger.info("Attempting to analyze text with Gemini.", model_option=model_option)
        try:
            start_time = time.time()
            model = genai.GenerativeModel(model_option)
            request_options = {"timeout": self.timeout}
            response = model.generate_content(prompt, request_options=request_options)
            processing_time = round(time.time() - start_time, 2)
            logger.info("Text analysis successful.", processing_time=processing_time)
            return AnalysisResult(text=response.text, processing_time=processing_time)
        except google_exceptions.DeadlineExceeded:
            logger.error("Gemini API call for text analysis timed out.", timeout=self.timeout)
            raise HTTPException(status_code=504, detail="The request to the AI model for text analysis timed out.")
        except Exception as e:
            logger.exception("An unexpected error occurred during text analysis with Gemini API.")
            raise HTTPException(status_code=500, detail=f"An error occurred with the language model: {str(e)}")
