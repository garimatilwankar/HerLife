from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.security import get_current_user
from app.database import get_db
from app.models.profile import Profile
from app.models.user import User
from app.schemas.profile import ProfileResponse, ProfileUpdate


router = APIRouter(
    prefix="/api/profile",
    tags=["Profile"],
)


@router.get("/me", response_model=ProfileResponse | None)
def get_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return db.scalar(
        select(Profile).where(Profile.user_id == current_user.id)
    )


@router.put("/me", response_model=ProfileResponse)
def update_profile(
    data: ProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    profile = db.scalar(
        select(Profile).where(Profile.user_id == current_user.id)
    )

    if profile is None:
        profile = Profile(
            user_id=current_user.id,
            **data.model_dump(),
        )
        db.add(profile)
    else:
        for field, value in data.model_dump().items():
            setattr(profile, field, value)

    db.commit()
    db.refresh(profile)

    return profile