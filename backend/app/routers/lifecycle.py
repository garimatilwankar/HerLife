from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.security import get_current_user
from app.core.stages import DEFAULT_MESSAGE, STAGE_MESSAGES, normalize_stage
from app.database import get_db
from app.models.profile import Profile
from app.models.user import User


router = APIRouter(
    prefix="/api/lifecycle",
    tags=["Lifecycle"],
)


@router.get("/me")
def get_lifecycle(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    profile = db.scalar(
        select(Profile).where(Profile.user_id == current_user.id)
    )

    if profile is None:
        return {
            "lifecycle_stage": None,
            "message": "Complete your profile to determine your lifecycle stage.",
        }

    stage = normalize_stage(profile.lifecycle_stage)

    return {
        "lifecycle_stage": stage,
        "message": get_lifecycle_message(stage),
    }


def get_lifecycle_message(stage: str | None) -> str:
    return STAGE_MESSAGES.get(stage or "", DEFAULT_MESSAGE)