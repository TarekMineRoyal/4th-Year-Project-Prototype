from fastapi import Header, HTTPException
from typing import Optional
import yaml
from functools import lru_cache
from pathlib import Path
from fastapi import HTTPException

async def get_user_id(x_user_id: Optional[str] = Header(None, alias="X-User-ID")) -> str:
    """
    Retrieves and validates the X-User-ID from the request headers.
    """
    if not x_user_id:
        raise HTTPException(status_code=400, detail="X-User-ID header is missing.")
    return x_user_id


# Define the path to the models.yaml file
CONFIG_PATH = Path(__file__).resolve().parent.parent.parent.parent / "configs" / "models.yaml"

@lru_cache()
def get_models_config():
    """Loads and parses the models.yaml file, caching the result."""
    try:
        with open(CONFIG_PATH, 'r') as f:
            return yaml.safe_load(f)
    except FileNotFoundError:
        # On startup, if the file is missing, the app should not be able to serve requests.
        raise RuntimeError("FATAL: Models configuration file not found at " + str(CONFIG_PATH))
    except yaml.YAMLError as e:
        raise RuntimeError(f"FATAL: Error parsing models configuration file: {e}")
