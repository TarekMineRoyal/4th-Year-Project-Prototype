import os
import logging
from dotenv import load_dotenv
import google.generativeai as genai

def load_settings():
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