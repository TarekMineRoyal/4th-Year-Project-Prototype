from src.application.services.prompt_service import PromptService
from src.infrastructure.prompt_loader import prompt_loader

class PromptLoaderService(PromptService):
    """
    A concrete implementation of the PromptService that uses the existing
    PromptLoader to load and format prompts from a YAML file.
    """
    def get(self, key: str, **kwargs) -> str:
        """
        Gets a prompt by its key using the prompt_loader.
        """
        return prompt_loader.get(key, **kwargs)