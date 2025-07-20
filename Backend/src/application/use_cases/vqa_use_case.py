import time
from src.domain.entities import VQARequest, VQAResult
from src.application.services.vision_service import VisionService
from src.application.services.storage_service import StorageService


class VQAUseCase:
    """
    Orchestrates the VQA process, from saving the image to getting an analysis.
    """

    def __init__(self, vision_service: VisionService, storage_service: StorageService):
        self.vision_service = vision_service
        self.storage_service = storage_service

    def execute(self, request: VQARequest) -> VQAResult:
        start_time = time.time()

        system_prompt = """You are a helpful and cautious AI assistant for a visually impaired user. Your primary goal is to provide clear, accurate, and safe information about the user's surroundings based on an image.

Follow these rules for every response:
1. Safety First: Your absolute first priority is the user's safety. If you see any potential hazards (sharp objects, hot surfaces, obstacles, spills, things that might fall), mention them clearly and upfront before answering the user's question, if there is none do not mention the hazards at all.
2. Be Direct: Directly answer the user's specific question first.
3. Be Concise: After answering the question, you may add one brief, relevant sentence of context if necessary. Avoid long, poetic descriptions.
4. State Uncertainty: If you are not sure about something, say so clearly. It is better to say "I can't be certain" than to guess."""

        prompt = f"{system_prompt}\n\nUser's Question: '''{request.question}'''"

        # Call the vision service via its clean interface
        analysis_result = self.vision_service.analyze_image(
            image=request.image,
            prompt=prompt,
            model_option=request.model_option
        )

        # Save the image via the storage service interface
        analyzed_path = self.storage_service.save_image(
            image_bytes=request.image.content,
            original_filename=request.image.filename,
            prefix="vqa"
        )

        total_processing_time = round(time.time() - start_time, 2)

        # Map the generic result to the specific VQA result model
        return VQAResult(
            answer=analysis_result.text,
            processing_time=total_processing_time,
            analyzed_path=analyzed_path
        )