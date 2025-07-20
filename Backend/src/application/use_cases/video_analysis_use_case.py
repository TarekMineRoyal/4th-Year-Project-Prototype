import time
import structlog
from src.domain.entities import VideoAnalysisRequest, VideoAnalysisResult
from src.application.services.vision_service import VisionService
from src.application.services.storage_service import StorageService

# Get a logger instance for this module
logger = structlog.get_logger(__name__)


class VideoAnalysisUseCase:
    """
    Orchestrates the Video Analysis process.
    """

    def __init__(self, vision_service: VisionService, storage_service: StorageService):
        self.vision_service = vision_service
        self.storage_service = storage_service

    def execute(self, request: VideoAnalysisRequest) -> VideoAnalysisResult:
        logger.info("VideoAnalysisUseCase started.")
        start_time = time.time()

        try:
            prompt = f"""You are describing a video feed for a visually impaired user.
The previous description was: '{request.previous_scene_description}'.
Based on the new frame, describe only what is new or what has changed in the scene.
Be very concise. If nothing significant has changed, respond with only the word 'NONE'."""

            # Log before calling the vision service
            logger.info(
                "Calling vision service for video frame analysis.",
                model_option="gemini-2.5-flash-preview-05-20"
            )
            # Call the vision service via its clean interface
            analysis_result = self.vision_service.analyze_image(
                image=request.image,
                prompt=prompt,
                model_option="gemini-2.5-flash-preview-05-20"  # Use a fast model
            )
            logger.info("Successfully received analysis from vision service.")

            description = analysis_result.text.strip()
            has_changed = not (description.upper() == 'NONE' or description == "")

            logger.debug("Scene change analysis complete.", has_changed=has_changed, description=description)

            analyzed_path = None
            if has_changed:
                logger.info("Significant change detected in scene, saving image.")
                # Save the image via the storage service interface
                analyzed_path = self.storage_service.save_image(
                    image_bytes=request.image.content,
                    original_filename=request.image.filename,
                    prefix="video"
                )
                logger.info("Successfully saved image to storage.", path=analyzed_path)
            else:
                logger.info("No significant change detected in scene.")

            total_processing_time = round(time.time() - start_time, 2)

            # Map the generic result to the specific Video Analysis result model
            result = VideoAnalysisResult(
                description_of_change=description if has_changed else "",
                has_changed=has_changed,
                processing_time=total_processing_time,
                analyzed_path=analyzed_path
            )

            logger.info(
                "VideoAnalysisUseCase finished successfully.",
                processing_time=total_processing_time,
                change_detected=has_changed
            )
            return result

        except Exception as e:
            logger.exception("An error occurred during VideoAnalysisUseCase execution.")
            # Re-raise the exception to be handled by the presentation layer
            raise