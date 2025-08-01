import os
import uuid
import structlog
from datetime import datetime
from pathlib import Path
from fastapi import HTTPException
from src.infrastructure.config import Settings

from src.application.services.storage_service import StorageService

# Get a logger instance for this module
logger = structlog.get_logger(__name__)


class LocalStorageService(StorageService):
    """
    A concrete implementation of the StorageService that saves files locally,
    organizing them into subdirectories based on the use case prefix.
    """

    def __init__(self, base_storage_dir: str):
        """
        Initializes the service with a base directory for all stored files.
        """
        self.base_storage_dir = Path(base_storage_dir)
        logger.info("LocalStorageService initialized.", base_dir=str(self.base_storage_dir))

    def save_file(
            self,
            file_bytes: bytes,
            original_filename: str,
            prefix: str
    ) -> str:
        """
        Saves a file's binary content to a specific subdirectory named after the prefix.
        For example, a prefix of 'vqa' will save the file in '{base_storage_dir}/vqa/'.
        """
        logger.info(
            "Attempting to save file to local storage.",
            original_filename=original_filename,
            prefix=prefix,
            size_bytes=len(file_bytes)
        )
        try:
            # --- 1. Determine the target subdirectory from the prefix ---
            # This is where the organization happens. e.g., 'storage/vqa'
            target_dir = self.base_storage_dir / prefix

            # --- 2. Ensure the subdirectory exists ---
            # The `parents=True` flag will create the base 'storage' directory
            # as well, if it doesn't already exist.
            target_dir.mkdir(parents=True, exist_ok=True)

            # --- 3. Create a unique and safe filename ---
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            # Add a short UUID to guarantee uniqueness even if two files are
            # processed in the same second.
            unique_id = uuid.uuid4().hex[:8]
            safe_original_filename = Path(original_filename).name
            file_ext = os.path.splitext(safe_original_filename)[1]

            save_filename = f"{prefix}_{timestamp}_{unique_id}{file_ext}"
            save_path = target_dir / save_filename

            # --- 4. Write the file to the determined path ---
            with open(save_path, "wb") as buffer:
                buffer.write(file_bytes)

            logger.info("File saved successfully.", path=str(save_path))
            # Return the path as a string, as required by the interface
            return str(save_path)

        except Exception as e:
            logger.exception("Error saving file to local storage.")
            raise HTTPException(status_code=500, detail="Failed to save file.")
