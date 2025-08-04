from fastapi import Depends
from src.application.services.dataset_service import DatasetService
from src.application.services.storage_service import StorageService
from src.application.services.vision_service import VisionService
from src.application.services.prompt_service import PromptService
from src.application.use_cases.vqa_use_case import VQAUseCase
from src.application.use_cases.ocr_use_case import OCRUseCase
from src.application.use_cases.live_session_use_case import LiveSessionUseCase
from src.infrastructure.config import get_settings, Settings
from src.infrastructure.services.gemini_vision_service import GeminiVisionService
from src.infrastructure.services.local_storage_service import LocalStorageService
from src.infrastructure.services.mongo_dataset_service import MongoDatasetService
from src.infrastructure.services.prompt_loader_service import PromptLoaderService
from src.presentation.api.dependencies import get_models_config

# --- Service Providers ---

def get_vision_service(settings: Settings = Depends(get_settings), models_config: dict = Depends(get_models_config)) -> VisionService:
    return GeminiVisionService(timeout=settings.model_timeout_seconds, models_config=models_config)

def get_storage_service(settings: Settings = Depends(get_settings)) -> StorageService:
    return LocalStorageService(settings.storage_dir)

def get_dataset_service() -> DatasetService:
    """Provides an instance of the MongoDatasetService."""
    return MongoDatasetService()

def get_prompt_service() -> PromptService:
    """Provides an instance of the PromptLoaderService."""
    return PromptLoaderService()

# --- Use Case Providers ---

def get_vqa_use_case(
    vision_service: VisionService = Depends(get_vision_service),
    storage_service: StorageService = Depends(get_storage_service),
    dataset_service: DatasetService = Depends(get_dataset_service),
    prompt_service: PromptService = Depends(get_prompt_service),
) -> VQAUseCase:
    """Constructs the VQAUseCase with all its required dependencies."""
    return VQAUseCase(
        vision_service=vision_service,
        storage_service=storage_service,
        dataset_service=dataset_service,
        prompt_service=prompt_service
    )

def get_ocr_use_case(
    vision_service: VisionService = Depends(get_vision_service),
    storage_service: StorageService = Depends(get_storage_service),
    prompt_service: PromptService = Depends(get_prompt_service),
) -> OCRUseCase:
    """Constructs the OCRUseCase with its required dependencies."""
    return OCRUseCase(
        vision_service=vision_service,
        storage_service=storage_service,
        prompt_service=prompt_service
    )

def get_live_session_use_case(
    vision_service: VisionService = Depends(get_vision_service),
    storage_service: StorageService = Depends(get_storage_service),
    prompt_service: PromptService = Depends(get_prompt_service),
) -> LiveSessionUseCase:
    """Constructs the LiveSessionUseCase with its required dependencies."""
    return LiveSessionUseCase(
        vision_service=vision_service,
        storage_service=storage_service,
        prompt_service=prompt_service
    )