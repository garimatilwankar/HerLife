from fastapi import FastAPI

from app.database import Base, engine
from app.models.user import User
from app.routers.auth import router as auth_router

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="HerLife API",
    description="Backend API for the HerLife women's health platform.",
    version="1.0.0",
)

app.include_router(auth_router)


@app.get("/")
def root():
    return {
        "message": "HerLife API is running"
    }


@app.get("/health")
def health():
    return {
        "status": "healthy"
    }