from src.application.use_cases.vqa_use_case import VQAUseCase
from src.application.use_cases.ocr_use_case import OCRUseCase
from src.application.use_cases.video_analysis_use_case import VideoAnalysisUseCase
from src.infrastructure.services.gemini_vision_service import GeminiVisionService
from src.infrastructure.services.local_storage_service import LocalStorageService

# Create singleton instances of our services
# This means the same instance is reused for all requests, which is efficient.
vision_service = GeminiVisionService()
storage_service = LocalStorageService()

# --- Use Case Dependencies ---

def get_vqa_use_case() -> VQAUseCase:
    """Provides the VQAUseCase with its dependencies."""
    return VQAUseCase(vision_service, storage_service)

def get_ocr_use_case() -> OCRUseCase:
    """Provides the OCRUseCase with its dependencies."""
    return OCRUseCase(vision_service, storage_service)

def get_video_analysis_use_case() -> VideoAnalysisUseCase:
    """Provides the VideoAnalysisUseCase with its dependencies."""
    return VideoAnalysisUseCase(vision_service, storage_service)