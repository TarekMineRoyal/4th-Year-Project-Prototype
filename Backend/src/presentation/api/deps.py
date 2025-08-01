# Dependency Injection Hub
from src.application.use_cases.vqa_use_case import VQAUseCase
from src.application.use_cases.ocr_use_case import OCRUseCase
from src.application.use_cases.live_session_use_case import LiveSessionUseCase
from src.infrastructure.services.gemini_vision_service import GeminiVisionService
from src.infrastructure.services.local_storage_service import LocalStorageService
from src.infrastructure.config import get_settings

# Create singleton instances of our services
# This means the same instance is reused for all requests, which is efficient.
settings= get_settings()
vision_service = GeminiVisionService(settings.model_timeout_seconds)
storage_service = LocalStorageService(settings.storage_dir)

# --- Use Case Dependencies ---

def get_vqa_use_case() -> VQAUseCase:
    """Provides the VQAUseCase with its dependencies."""
    return VQAUseCase(vision_service, storage_service)

def get_ocr_use_case() -> OCRUseCase:
    """Provides the OCRUseCase with its dependencies."""
    return OCRUseCase(vision_service, storage_service)

def get_live_session_use_case() -> LiveSessionUseCase:
    """Provides the LiveSessionUseCase with its dependencies."""
    return LiveSessionUseCase(vision_service,storage_service)
