import os
import shutil
import structlog
from datetime import datetime
from pathlib import Path
from fastapi import HTTPException

from src.application.services.storage_service import StorageService

# Get a logger instance for this module
logger = structlog.get_logger(__name__)


class LocalStorageService(StorageService):
    """
    A concrete implementation of the StorageService that saves files locally.
    """

    def __init__(self, upload_dir: str = "uploads", analyzed_dir: str = "analyzed"):
        self.upload_dir = upload_dir
        self.analyzed_dir = analyzed_dir

        try:
            # Ensure directories exist
            Path(self.upload_dir).mkdir(exist_ok=True)
            Path(self.analyzed_dir).mkdir(exist_ok=True)
            logger.info("Storage directories ensured.", upload_dir=upload_dir, analyzed_dir=analyzed_dir)
        except Exception as e:
            logger.exception("Failed to create storage directories.")
            # This could be a permissions error, so we raise it.
            raise

    def save_image(
            self,
            image_bytes: bytes,
            original_filename: str,
            prefix: str
    ) -> str:
        """
        Saves image bytes to the 'analyzed' directory with a timestamp and prefix.
        """
        logger.info(
            "Attempting to save image to local storage.",
            original_filename=original_filename,
            prefix=prefix,
            size_bytes=len(image_bytes)
        )
        try:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            # Sanitize the original filename to prevent directory traversal issues
            safe_original_filename = Path(original_filename).name
            file_ext = os.path.splitext(safe_original_filename)[1]

            # We save directly to the analyzed directory now
            save_filename = f"{prefix}_{timestamp}{file_ext}"
            save_path = os.path.join(self.analyzed_dir, save_filename)

            with open(save_path, "wb") as buffer:
                buffer.write(image_bytes)

            logger.info("Image saved successfully.", path=save_path)
            return save_path

        except Exception as e:
            logger.exception("Error saving file to local storage.")
            raise HTTPException(status_code=500, detail="Failed to save image file.")