import yaml
from jinja2 import Environment, FileSystemLoader
import os


class PromptLoader:
    """
    A class to load, manage, and format prompts from a YAML file using Jinja2 for templating.
    """
    _instance = None

    def __new__(cls, *args, **kwargs):
        if not cls._instance:
            cls._instance = super(PromptLoader, cls).__new__(cls)
        return cls._instance

    def __init__(self, prompts_file_path: str = None):
        """
        Initializes the PromptLoader. It's a singleton to ensure prompts are loaded only once.

        Args:
            prompts_file_path (str, optional): The path to the prompts YAML file.
                                               Defaults to a path relative to this file.
        """
        # To avoid re-initialization in the singleton pattern
        if hasattr(self, 'initialized'):
            return

        if prompts_file_path is None:
            # Assumes prompts.yaml is in a 'configs' directory at the project root
            base_dir = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
            self.prompts_file_path = os.path.join(base_dir, 'configs', 'prompts.yaml')
        else:
            self.prompts_file_path = prompts_file_path

        self.prompts = self._load_prompts()

        # Set up Jinja2 environment
        config_dir = os.path.dirname(self.prompts_file_path)
        self.jinja_env = Environment(loader=FileSystemLoader(config_dir))
        self.initialized = True

    def _load_prompts(self) -> dict:
        """Loads prompts from the YAML file."""
        try:
            with open(self.prompts_file_path, 'r') as f:
                return yaml.safe_load(f)
        except FileNotFoundError:
            # Handle case where file doesn't exist
            return {}
        except yaml.YAMLError:
            # Handle error in YAML parsing
            return {}

    def get(self, key: str, **kwargs) -> str:
        """
        Gets a prompt by its key, formats it with the given variables,
        and returns the final string.

        Args:
            key (str): The key of the prompt, using dot notation (e.g., 'vqa.system_persona').
            **kwargs: The variables to substitute into the prompt template.

        Returns:
            str: The formatted prompt.
        """
        try:
            # Retrieve the raw prompt template from the loaded dictionary
            keys = key.split('.')
            prompt_template_str = self.prompts
            for k in keys:
                prompt_template_str = prompt_template_str[k]

            # Use Jinja2 to render the prompt with variables
            template = self.jinja_env.from_string(prompt_template_str)
            return template.render(**kwargs)

        except (KeyError, TypeError):
            return f"Prompt key '{key}' not found or invalid."
        except Exception:
            return "An error occurred during prompt formatting."


# Singleton instance for easy access throughout the application
prompt_loader = PromptLoader()
