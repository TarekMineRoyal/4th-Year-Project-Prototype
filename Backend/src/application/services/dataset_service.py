# src/application/services/dataset_service.py
from abc import ABC, abstractmethod

import structlog
from src.domain.entities.documents import RequestLog
from src.application.services.vision_service import VisionService
from src.domain.entities import ImageFile
from src.domain.entities.documents import AnalysisMode

logger = structlog.get_logger(__name__)

class DatasetService(ABC):
    """
        Abstract base class (interface) for a dataset service.
        It defines the contract that any dataset service must adhere to.
    """
    @abstractmethod
    async def log_request_for_dataset(
            self,
            user_id: str,
            file_path: str,
            image: ImageFile,
            vision_service: VisionService,
            question: str,
            answer: str,
            model_name: str,
            mode: AnalysisMode
    ):
        """
        This function runs in the background to log a VQA request for the dataset.
        """
        pass