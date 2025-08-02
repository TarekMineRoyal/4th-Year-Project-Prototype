import os
from dotenv import load_dotenv
import structlog
from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache
import logging
import google.generativeai as genai

# Get a logger instance for this module
logger = structlog.get_logger(__name__)

def load_env_settings():
    """
    Loads environment variables and configures external services.
    """
    # Load environment variables from .env file
    load_dotenv()

    # Configure the Gemini API client
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        logging.warning("GEMINI_API_KEY not found in environment variables. Gemini models will be unavailable.")
        return

    try:
        genai.configure(api_key=api_key)
        logging.info("Gemini API configured successfully.")
    except Exception as e:
        logging.error(f"Failed to configure Gemini API: {e}")

class Settings(BaseSettings):
    """
    Defines the application's configuration settings.
    Pydantic automatically reads these from environment variables or a .env file.
    The variable names are case-insensitive.
    """
    # --- Gemini API Settings ---
    # This is read from the GOOGLE_API_KEY environment variable.
    #google_api_key: str = os.getenv("GEMINI_API_KEY")

    # --- Model Settings ---
    # The timeout in seconds for API calls to the vision model.
    model_timeout_seconds: int = 120

    # --- Storage Settings ---
    # The base directory where all media files will be stored.
    storage_dir: str = "storage"


    # --- NEW: MongoDB Settings ---
    mongodb_uri: str = "mongodb://localhost:27017"
    mongodb_db_name: str = "auralens_dataset_db"


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    """
    Loads the settings, creates a singleton Settings object, and returns it.
    The lru_cache decorator ensures this function is only run once, and the
    same settings object is returned for all subsequent calls, which is efficient.
    """
    logger.info("Loading application settings...")
    try:
        settings = Settings()
        logger.info("Application settings loaded successfully.")
        return settings
    except Exception as e:
        logger.exception("Failed to load application settings. Check your .env file and environment variables.")
        # Re-raise the exception to prevent the application from starting with invalid config.
        raise e

