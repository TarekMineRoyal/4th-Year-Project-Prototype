from abc import ABC, abstractmethod

class StorageService(ABC):
    """
    Abstract base class (interface) for a file storage service.
    It defines the contract for saving files.
    """
    @abstractmethod
    def save_image(
        self,
        image_bytes: bytes,
        original_filename: str,
        prefix: str
    ) -> str:
        """
        Saves image bytes to a persistent storage.

        Args:
            image_bytes: The binary content of the image.
            original_filename: The original name of the uploaded file.
            prefix: A prefix (e.g., 'vqa', 'ocr') for the saved filename.

        Returns:
            The path to the saved file.
        """
        pass