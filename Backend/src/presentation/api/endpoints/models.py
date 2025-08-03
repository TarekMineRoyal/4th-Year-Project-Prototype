import yaml
from fastapi import APIRouter, HTTPException
from pathlib import Path

# Create a new router for this endpoint
router = APIRouter()

# Define the path to the models.yaml file
# This assumes the config directory is at the root of the project
CONFIG_PATH = Path(__file__).resolve().parent.parent.parent.parent.parent / "configs" / "models.yaml"

def load_models_config():
    """Loads and parses the models.yaml file."""
    try:
        with open(CONFIG_PATH, 'r') as f:
            return yaml.safe_load(f)
    except FileNotFoundError:
        # This provides a clear error if the config file is missing
        raise HTTPException(status_code=500, detail="Models configuration file not found.")
    except yaml.YAMLError:
        # This handles cases of malformed YAML
        raise HTTPException(status_code=500, detail="Error parsing models configuration file.")

@router.get("/")
def get_selectable_models():
    """
    Returns a list of all models that are user-selectable,
    grouped by feature.
    """
    all_models = load_models_config()
    selectable_models = {}

    for feature, config in all_models.items():
        if config.get('selectable', False):
            if isinstance(config.get('models'), list):
                # --- THIS IS THE FIX ---
                # Convert the feature key to uppercase before adding it to the response.
                selectable_models[feature.upper()] = config.get('models')

    if not selectable_models:
        raise HTTPException(status_code=404, detail="No selectable models found in configuration.")

    return selectable_models