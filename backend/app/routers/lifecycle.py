from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.security import get_current_user
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

    return {
        "lifecycle_stage": profile.lifecycle_stage,
        "message": get_lifecycle_message(profile.lifecycle_stage),
    }


def get_lifecycle_message(stage: str | None) -> str:
    messages = {
        "Adolescence": "Your body is going through important developmental changes.",
        "Reproductive Years": "Your cycle and reproductive health can be tracked for patterns.",
        "Pregnancy": "Pregnancy-related changes can be tracked and monitored.",
        "Postpartum": "Your body is recovering and adapting after pregnancy.",
        "Perimenopause": "Hormonal and cycle patterns may become more variable.",
        "Menopause": "Changes after menopause can be tracked over time.",
    }

    return messages.get(
        stage,
        "Track your health regularly to understand your patterns.",
    )