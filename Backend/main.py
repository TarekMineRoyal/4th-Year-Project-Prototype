import logging
from fastapi import FastAPI
from src.presentation.logging_middleware import LoggingMiddleware
from logging_config import setup_logging
from fastapi.middleware.cors import CORSMiddleware
from src.infrastructure.config import load_settings
from src.presentation.api import api_router

# Load settings and configure external services at startup
load_settings()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 1. Call the setup function at the start of your application
setup_logging()

# Create FastAPI app
app = FastAPI(
    title="AI Visual Assistant API",
    description="API for the AI Visual Assistant for BLV Users project.",
    version="1.0.0"
)

# 2. Add the middleware to your app
app.add_middleware(LoggingMiddleware)

# Add CORS middleware to allow all origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include the main API router
app.include_router(api_router, prefix="/api/v1")

@app.get("/", tags=["Health Check"])
def read_root():
    """A simple health check endpoint."""
    return {"status": "ok", "message": "Welcome to the AI Visual Assistant API!"}

# To run the app: uvicorn main:app --reload
# or uvicorn main:app --reload --host 0.0.0.0