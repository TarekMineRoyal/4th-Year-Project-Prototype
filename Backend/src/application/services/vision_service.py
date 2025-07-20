from abc import ABC, abstractmethod
from src.domain.entities import ImageFile, AnalysisResult

class VisionService(ABC):
    """
    Abstract base class (interface) for a vision AI service.
    It defines the contract that any vision service must adhere to.
    """
    @abstractmethod
    def analyze_image(
        self,
        image: ImageFile,
        prompt: str,
        model_option: str
    ) -> AnalysisResult:
        """
        Analyzes an image based on a given prompt and model.

        Args:
            image: The ImageFile object to analyze.
            prompt: The text prompt to guide the analysis.
            model_option: The specific model identifier to use.

        Returns:
            An AnalysisResult object containing the raw text and processing time.
        """
        pass