import time
from src.domain.entities import OCRRequest, OCRResult
from src.application.services.vision_service import VisionService
from src.application.services.storage_service import StorageService


class OCRUseCase:
    """
    Orchestrates the OCR process.
    """

    def __init__(self, vision_service: VisionService, storage_service: StorageService):
        self.vision_service = vision_service
        self.storage_service = storage_service

    def execute(self, request: OCRRequest) -> OCRResult:
        start_time = time.time()

        prompt = "Extract all text from this image exactly as it appears. If there is no text, say so."

        # Call the vision service via its clean interface
        analysis_result = self.vision_service.analyze_image(
            image=request.image,
            prompt=prompt,
            model_option="gemini-2.5-flash-preview-05-20"  # Specific model for OCR
        )

        # Save the image via the storage service interface
        analyzed_path = self.storage_service.save_image(
            image_bytes=request.image.content,
            original_filename=request.image.filename,
            prefix="ocr"
        )

        total_processing_time = round(time.time() - start_time, 2)

        # Map the generic result to the specific OCR result model
        return OCRResult(
            text=analysis_result.text,
            processing_time=total_processing_time,
            analyzed_path=analyzed_path
        )