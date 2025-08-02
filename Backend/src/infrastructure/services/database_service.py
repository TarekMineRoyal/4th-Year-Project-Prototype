# src/infrastructure/services/database_service.py

import motor.motor_asyncio
from beanie import init_beanie
from src.infrastructure.config import get_settings
from src.domain.entities.documents import RequestLog # Import our new document

async def init_db():
    settings = get_settings()
    client = motor.motor_asyncio.AsyncIOMotorClient(settings.mongodb_uri)
    db = client[settings.mongodb_db_name]

    await init_beanie(
        database=db,
        document_models=[RequestLog] # Register our document
    )