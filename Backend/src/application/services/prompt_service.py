from abc import ABC, abstractmethod

class PromptService(ABC):
    """
    Abstract base class for a prompt loading and formatting service.
    """
    @abstractmethod
    def get(self, key: str, **kwargs) -> str:
        """
        Gets a prompt by its key and formats it with the given variables.
        """
        pass