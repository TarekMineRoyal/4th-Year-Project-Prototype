from abc import ABC, abstractmethod

class StorageService(ABC):
    """
    Abstract base class (interface) for a file storage service.
    It defines a generic contract for saving files.
    """
    @abstractmethod
    def save_file(
        self,
        file_bytes: bytes,
        original_filename: str,
        prefix: str
    ) -> str:
        """
        Saves a file's binary content to a persistent storage.

        Args:
            file_bytes: The binary content of the file (image, video, etc.).
            original_filename: The original name of the uploaded file, used to get the extension.
            prefix: A prefix (e.g., 'vqa', 'session_clip') for the saved filename.

        Returns:
            The path to the saved file.
        """
        pass
