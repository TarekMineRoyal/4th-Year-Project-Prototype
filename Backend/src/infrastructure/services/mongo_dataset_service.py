import structlog
from src.application.services.dataset_service import DatasetService
from src.application.services.vision_service import VisionService
from src.domain.entities.documents import RequestLog, AnalysisMode
from src.domain.entities.image import ImageFile

logger = structlog.get_logger(__name__)


class MongoDatasetService(DatasetService):
    """
    The concrete implementation of the DatasetService that logs data to MongoDB.
    """

    def __init__(self,):
        logger.info("MongoDatasetService initialized.")

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
        try:
            logger.info("Background dataset task started.", user_id=user_id)

            # 1. Get the list of objects using the injected vision service
            object_list = await vision_service.get_object_list(image)

            # 2. Create the log entry
            log_entry = RequestLog(
                user_id=user_id,
                model_name=model_name,
                mode=mode,
                file_path=file_path,
                question=question,
                answer=answer,
                list_of_objects=object_list
            )

            # 3. Save it to MongoDB
            await log_entry.insert()
            logger.info("Background task finished. Request log saved.", user_id=user_id)

        except Exception as e:
            logger.error("Error in background dataset logging task.", error=e, exc_info=True)