import time
import structlog
from src.domain.entities import OCRRequest, OCRResult
from src.application.services.vision_service import VisionService
from src.application.services.storage_service import StorageService
from src.infrastructure.prompt_loader import prompt_loader

logger = structlog.get_logger(__name__)

class OCRUseCase:
    """
    Orchestrates the OCR process. FIX: Now saves the image first.
    """
    def __init__(self, vision_service: VisionService, storage_service: StorageService):
        self.vision_service = vision_service
        self.storage_service = storage_service

    def execute(self, request: OCRRequest) -> OCRResult:
        logger.info("OCRUseCase started.")
        start_time = time.time()

        try:
            analyzed_path = self.storage_service.save_file(
                file_bytes=request.image.content,
                original_filename=request.image.filename,
                prefix="ocr"
            )
            logger.info("OCR image saved to storage.", path=analyzed_path)

            prompt = prompt_loader.get('ocr.text_extraction')

            logger.info("Calling ocr service for OCR analysis.", model_option=request.model_option)

            analysis_result = self.vision_service.analyze_image(
                image=request.image,
                prompt=prompt,
                model_option=request.model_option
            )
            logger.info("Successfully received analysis from vision service.")

            total_processing_time = round(time.time() - start_time, 2)

            result = OCRResult(
                text=analysis_result.text,
                processing_time=total_processing_time,
                analyzed_path=analyzed_path
            )

            logger.info("OCRUseCase finished successfully.", processing_time=total_processing_time)
            return result

        except Exception as e:
            logger.exception("An error occurred during OCRUseCase execution.")
            raise
