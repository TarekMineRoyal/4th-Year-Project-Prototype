import json
import time
import asyncio
import structlog
import io
import os
import tempfile
from PIL import Image
from fastapi import HTTPException
import google.generativeai as genai
from google.api_core import exceptions as google_exceptions
from src.application.services.vision_service import VisionService
from src.domain.entities import AnalysisResult
from src.domain.entities import VideoFile, ImageFile
from src.presentation.api.endpoints.config import ACTIVE_MODELS_CONFIG

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
        Uploads and then analyzes a video using the specified Gemini model.
        """
        logger.info(
            "Attempting to analyze video with Gemini.",
            model_option=model_option,
            filename=video.filename
        )

        # The SDK's upload_file method requires a file path.
        # We write the in-memory bytes to a temporary file first.
        temp_file = None
        uploaded_file = None
        try:
            with tempfile.NamedTemporaryFile(
                    delete=False, suffix=os.path.splitext(video.filename)[1]
            ) as temp_file:
                temp_file.write(video.content)
                temp_file_path = temp_file.name

            start_time = time.time()
            logger.debug("Uploading video file to Gemini API.", path=temp_file_path)

            # 1. Upload the file to the Gemini API
            uploaded_file = genai.upload_file(
                path=temp_file_path,
                display_name=video.filename,
                mime_type=video.content_type,
            )
            logger.info("Video file uploaded.", file_name=uploaded_file.name)

            # 2. Poll for the video's state to become 'ACTIVE'
            # The model cannot use the file until it has been processed.
            logger.debug("Polling for video processing status.")
            while uploaded_file.state.name == "PROCESSING":
                time.sleep(5)  # Wait 5 seconds between checks
                uploaded_file = genai.get_file(name=uploaded_file.name)

            if uploaded_file.state.name == "FAILED":
                logger.error("Video processing failed on Google's server.")
                raise Exception("Video processing failed.")

            logger.info("Video is active and ready for analysis.")

            # 3. Generate content using the uploaded file
            model = genai.GenerativeModel(model_option)
            # Consider a longer timeout for video analysis
            request_options = {"timeout": 300}

            response = model.generate_content(
                [prompt, uploaded_file],
                request_options=request_options
            )

            processing_time = round(time.time() - start_time, 2)
            logger.info(
                "Received video analysis from Gemini successfully.",
                processing_time=processing_time,
                response_length=len(response.text)
            )

            return AnalysisResult(
                text=response.text,
                processing_time=processing_time
            )

        except google_exceptions.DeadlineExceeded:
            logger.error("Gemini API call timed out after 300 seconds.")
            raise HTTPException(
                status_code=504,
                detail="The request to the AI model timed out. Please try again."
            )
        except Exception as e:
            logger.exception("An unexpected error occurred communicating with Gemini API.")
            raise HTTPException(
                status_code=500,
                detail=f"An error occurred with the video model: {str(e)}"
            )
        finally:
            # 4. Clean up by deleting the temporary local file and the uploaded remote file
            if temp_file:
                os.remove(temp_file_path)
                logger.debug("Deleted temporary local file.", path=temp_file_path)
            if uploaded_file:
                genai.delete_file(name=uploaded_file.name)
                logger.debug("Deleted file from Gemini.", file_name=uploaded_file.name)

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

    async def get_object_list(self, image: ImageFile) -> list[str]:
        """
        Analyzes an image and returns a list of objects, tailored for the blind.
        """
        prompt = (
            "Analyze the provided image. Identify all distinct objects. "
            "Return a JSON list of strings. Each string should be a simple, "
            "clear description of one object. For example: "
            '["a red coffee mug", "a silver laptop", "a pair of black glasses"]. '
            "Ensure the output is only the JSON list and nothing else."
        )
        try:
            img = Image.open(io.BytesIO(image.content))
            logger.debug("Sending request to Gemini API to analyze objects.")

            model = genai.GenerativeModel(ACTIVE_MODELS_CONFIG.objects_extractor)

            # Pass the request_options to the generate_content call
            response = model.generate_content(
                [prompt, img],
            )
            # Basic parsing to find the JSON list in the response text
            json_str = response.text[response.text.find('['):response.text.rfind(']') + 1]
            return json.loads(json_str)
        except (json.JSONDecodeError, ValueError, IndexError) as e:
            # Handle cases where the model doesn't return a perfect list
            logger.error(f"Could not parse object list from Gemini: {e}")
            logger.error(f"Gemini raw response for object list: {response.text}")
            return []  # Return an empty list on failure