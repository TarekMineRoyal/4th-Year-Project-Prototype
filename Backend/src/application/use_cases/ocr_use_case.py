import time
import structlog
from src.domain.entities import OCRRequest, OCRResult
from src.application.services.vision_service import VisionService
from src.application.services.storage_service import StorageService

# Get a logger instance for this module
logger = structlog.get_logger(__name__)


class OCRUseCase:
    """
    Orchestrates the OCR process.
    """

    def __init__(self, vision_service: VisionService, storage_service: StorageService):
        self.vision_service = vision_service
        self.storage_service = storage_service

    def execute(self, request: OCRRequest) -> OCRResult:
        logger.info("OCRUseCase started.")
        start_time = time.time()

        try:
            prompt = "Extract all text from this image exactly as it appears. If there is no text, say so."

            # Log before calling the vision service
            logger.info(
                "Calling vision service for OCR analysis.",
                model_option=request.model_option
            )

            # Call the vision service via its clean interface
            analysis_result = self.vision_service.analyze_image(
                image=request.image,
                prompt=prompt,
                model_option=request.model_option
            )
            logger.info("Successfully received analysis from vision service.")

            # Log before saving the image
            logger.info(
                "Calling storage service to save image.",
                filename=request.image.filename
            )
            # Save the image via the storage service interface
            analyzed_path = self.storage_service.save_image(
                image_bytes=request.image.content,
                original_filename=request.image.filename,
                prefix="ocr"
            )
            logger.info("Successfully saved image to storage.", path=analyzed_path)

            total_processing_time = round(time.time() - start_time, 2)

            # Map the generic result to the specific OCR result model
            result = OCRResult(
                text=analysis_result.text,
                processing_time=total_processing_time,
                analyzed_path=analyzed_path
            )

            logger.info(
                "OCRUseCase finished successfully.",
                processing_time=total_processing_time
            )
            return result

        except Exception as e:
            logger.exception("An error occurred during OCRUseCase execution.")
            # Re-raise the exception to be handled by the presentation layer
            raise