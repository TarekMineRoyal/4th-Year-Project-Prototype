import uvicorn
from fastapi import FastAPI
from src.presentation.logging_middleware import LoggingMiddleware
from logging_config import setup_logging
from fastapi.middleware.cors import CORSMiddleware
from src.infrastructure.config import load_env_settings
from src.presentation.api import api_router

# The call to load_settings() is removed, as configuration is now
# handled on-demand by the dependency injection system.

# Configure logging at startup
setup_logging()

# Load environment settings
load_env_settings()

# Create FastAPI app
app = FastAPI(
    title="AI Visual Assistant API",
    description="API for the AI Visual Assistant for BLV Users project.",
    version="1.0.0"
)

# Add the middleware to the app
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
