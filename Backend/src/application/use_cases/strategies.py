from abc import ABC, abstractmethod
import structlog

from src.domain.entities import MediaType, VideoFile, ImageFile
from src.application.services.vision_service import VisionService

# Get a logger instance for this module
logger = structlog.get_logger(__name__)


class SceneExtractorStrategy(ABC):
    """
    Abstract base class (interface) for a scene extraction strategy.
    It defines the contract for how to extract a text description from a media type.
    """

    @abstractmethod
    def extract_scene(self, media: MediaType, prompt: str, model: str) -> str:
        """
        Extracts a scene description from the given media.

        Args:
            media: The media file (ImageFile or VideoFile) to analyze.
            prompt: The text prompt to guide the analysis.
            model: The specific model identifier to use.

        Returns:
            A string containing the scene description.
        """
        pass


class VideoSceneExtractor(SceneExtractorStrategy):
    """
    A concrete strategy for extracting a scene description from a video file.
    """

    def __init__(self, vision_service: VisionService):
        self.vision_service = vision_service
        logger.info("VideoSceneExtractor strategy initialized.")

    def extract_scene(self, media: VideoFile, prompt: str, model: str) -> str:
        """
        Calls the vision service's analyze_video method.
        """
        logger.info("Executing VideoSceneExtractor strategy.", model=model)
        # Type checking to ensure the correct media type is passed
        if not isinstance(media, VideoFile):
            raise TypeError("VideoSceneExtractor can only process VideoFile objects.")

        return self.vision_service.analyze_video(
            video=media,
            prompt=prompt,
            model_option=model
        ).text


class FrameSceneExtractor(SceneExtractorStrategy):
    """
    A concrete strategy for extracting a scene description from a single image file.
    """

    def __init__(self, vision_service: VisionService):
        self.vision_service = vision_service
        logger.info("FrameSceneExtractor strategy initialized.")

    def extract_scene(self, media: ImageFile, prompt: str, model: str) -> str:
        """
        Calls the vision service's analyze_image method.
        """
        logger.info("Executing FrameSceneExtractor strategy.", model=model)
        # Type checking to ensure the correct media type is passed
        if not isinstance(media, ImageFile):
            raise TypeError("FrameSceneExtractor can only process ImageFile objects.")

        return self.vision_service.analyze_image(
            image=media,
            prompt=prompt,
            model_option=model
        ).text
