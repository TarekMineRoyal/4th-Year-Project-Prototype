import time
import structlog
from fastapi import BackgroundTasks
from src.application.services.dataset_service import DatasetService
from src.domain.entities import VQARequest, VQAResult
from src.application.services.vision_service import VisionService
from src.application.services.storage_service import StorageService

logger = structlog.get_logger(__name__)

class VQAUseCase:
    """
    Orchestrates the VQA process.
    """
    def __init__(self, vision_service: VisionService, storage_service: StorageService, dataset_service: DatasetService):
        self.vision_service = vision_service
        self.storage_service = storage_service
        self.dataset_service = dataset_service

    async def execute(self, request: VQARequest, background_tasks: BackgroundTasks) -> VQAResult:
        logger.info("VQAUseCase started.")
        start_time = time.time()

        try:
            analyzed_path = self.storage_service.save_file(
                file_bytes=request.image.content,
                original_filename=request.image.filename,
                prefix="vqa"
            )
            logger.info("VQA image saved to storage.", path=analyzed_path)

            system_prompt = """You are a helpful and cautious AI assistant for a visually impaired user.
            Your primary goal is to provide clear, accurate, and safe information about the user's surroundings based on an image.
            Follow these rules for every response:
            1. Safety First: Your absolute first priority is the user's safety. If you see any potential hazards (sharp objects, hot surfaces, obstacles, spills, things that might fall), mention them clearly and upfront before answering the user's question, if there is none do not mention the hazards at all.
            2. Be Direct: Directly answer the user's specific question first.
            3. Be Concise: After answering the question, you may add one brief, relevant sentence of context if necessary. Avoid long, poetic descriptions.
            4. State Uncertainty: If you are not sure about something, say so clearly. It is better to say "I can't be certain" than to guess."""

            prompt = f"{system_prompt}\n\nUser's Question: '''{request.question}'''"

            logger.info("Calling vision service for VQA analysis.", model_option=request.model_option)

            analysis_result = self.vision_service.analyze_image(
                image=request.image,
                prompt=prompt,
                model_option=request.model_option
            )
            logger.info("Successfully received analysis from vision service.")

            total_processing_time = round(time.time() - start_time, 2)

            result = VQAResult(
                answer=analysis_result.text,
                processing_time=total_processing_time,
                analyzed_path=analyzed_path
            )

            logger.info("VQAUseCase finished successfully.", processing_time=total_processing_time)

            logger.info("Saving the record to the dataset.")
            background_tasks.add_task(
                self.dataset_service.log_request_for_dataset,
                user_id=request.user_id,
                file_path=analyzed_path,
                image=request.image,
                vision_service=self.vision_service,
                question=request.question,
                answer=result.answer,
                model_name=request.model_option,
                mode=request.mode

            )
            logger.info("Record saved!")

            return result

        except Exception as e:
            logger.exception("An error occurred during VQAUseCase execution.")
            raise
