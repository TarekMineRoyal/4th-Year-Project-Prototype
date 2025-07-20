import os
import shutil
from datetime import datetime
from pathlib import Path
from fastapi import HTTPException

from src.application.services.storage_service import StorageService

class LocalStorageService(StorageService):
    """
    A concrete implementation of the StorageService that saves files locally.
    """
    def __init__(self, upload_dir: str = "uploads", analyzed_dir: str = "analyzed"):
        self.upload_dir = upload_dir
        self.analyzed_dir = analyzed_dir
        # Ensure directories exist
        Path(self.upload_dir).mkdir(exist_ok=True)
        Path(self.analyzed_dir).mkdir(exist_ok=True)

    def save_image(
        self,
        image_bytes: bytes,
        original_filename: str,
        prefix: str
    ) -> str:
        """
        Saves image bytes to the 'analyzed' directory with a timestamp and prefix.
        """
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

            return save_path
        except Exception as e:
            # In a real application, you'd have more robust logging here
            print(f"Error saving file: {e}")
            raise HTTPException(status_code=500, detail="Failed to save image file.")