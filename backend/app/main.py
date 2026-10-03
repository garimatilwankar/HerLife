from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import Base, engine
from app.models import User, Profile, Period, Symptom, DailyCheckin, EducationArticle

from app.routers.auth import router as auth_router
from app.routers.profile import router as profile_router
from app.routers.tracking import router as tracking_router
from app.routers.lifecycle import router as lifecycle_router
from app.routers.insights import router as insights_router
from app.routers.education import router as education_router
from app.routers.ask import router as ask_router


Base.metadata.create_all(bind=engine)


app = FastAPI(
    title="HerLife API",
    description="Backend API for the HerLife women's health platform.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


app.include_router(auth_router)
app.include_router(profile_router)
app.include_router(tracking_router)
app.include_router(lifecycle_router)
app.include_router(insights_router)
app.include_router(education_router)
app.include_router(ask_router)


@app.get("/")
def root():
    return {"message": "HerLife API is running"}


@app.get("/health")
def health():
    return {"status": "healthy"}