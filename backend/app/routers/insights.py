from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.security import get_current_user
from app.core.cycle_math import build_cycle_summary
from app.database import get_db
from app.models.checkin import DailyCheckin
from app.models.period import Period
from app.models.profile import Profile
from app.models.symptom import Symptom
from app.models.user import User


router = APIRouter(
    prefix="/api/insights",
    tags=["Insights"],
)


@router.get("")
def get_insights(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    profile = db.scalar(
        select(Profile).where(Profile.user_id == current_user.id)
    )

    periods = list(
        db.scalars(
            select(Period)
            .where(Period.user_id == current_user.id)
            .order_by(Period.start_date.desc())
        ).all()
    )

    symptoms = list(
        db.scalars(
            select(Symptom)
            .where(Symptom.user_id == current_user.id)
            .order_by(Symptom.recorded_on.desc())
        ).all()
    )

    checkins = list(
        db.scalars(
            select(DailyCheckin)
            .where(DailyCheckin.user_id == current_user.id)
            .order_by(DailyCheckin.recorded_on.desc())
        ).all()
    )

    return {
        "lifecycle": build_lifecycle_insight(profile),
        "cycle": calculate_cycle_insight(periods),
        "symptoms": analyze_symptoms(symptoms),
        "mood": analyze_mood(checkins),
        "safety_note": (
            "These insights describe patterns in your recorded data "
            "and are not medical diagnoses."
        ),
    }


def build_lifecycle_insight(profile: Profile | None):
    if profile is None:
        return {
            "stage": None,
            "message": "Complete your profile to personalize insights.",
        }

    return {
        "stage": profile.lifecycle_stage,
        "message": (
            f"Your current lifecycle stage is "
            f"{profile.lifecycle_stage}."
        ),
    }


def calculate_cycle_insight(periods: list[Period]):
    summary = build_cycle_summary(periods)
    cycles = summary["cycles"]

    # Old keys are kept so the current Flutter screens don't break.
    # cycle_lengths stays newest first, as before.
    lengths_newest_first = [c["length"] for c in reversed(cycles)]

    if summary["average_cycle_length"] is None:
        message = "Record at least two periods to identify cycle patterns."
    else:
        message = (
            f"Your recorded cycles average "
            f"{summary['average_cycle_length']} days."
        )

    return {
        "average_cycle_length": summary["average_cycle_length"],
        "cycle_lengths": lengths_newest_first,
        "cycles_recorded": summary["cycles_recorded"],
        "message": message,
        "summary": summary,
    }

def analyze_symptoms(symptoms: list[Symptom]):
    if not symptoms:
        return {
            "top_symptoms": [],
            "message": "No symptoms recorded yet.",
        }

    counts = {}

    for symptom in symptoms:
        name = symptom.name.strip()

        if name:
            counts[name] = counts.get(name, 0) + 1

    sorted_symptoms = sorted(
        counts.items(),
        key=lambda item: item[1],
        reverse=True,
    )

    top_symptoms = [
        {
            "name": name,
            "count": count,
        }
        for name, count in sorted_symptoms[:5]
    ]

    return {
        "top_symptoms": top_symptoms,
        "message": (
            f"You have recorded {len(symptoms)} symptom entries."
        ),
    }


def analyze_mood(checkins: list[DailyCheckin]):
    if not checkins:
        return {
            "recent_mood": None,
            "average_energy": None,
            "message": "Complete daily check-ins to see mood patterns.",
        }

    recent_mood = checkins[0].mood

    energy_values = [
        checkin.energy
        for checkin in checkins
        if checkin.energy is not None
    ]

    average_energy = None

    if energy_values:
        average_energy = round(
            sum(energy_values) / len(energy_values),
            1,
        )

    return {
        "recent_mood": recent_mood,
        "average_energy": average_energy,
        "checkins_recorded": len(checkins),
        "message": "Your recent check-in data has been analyzed.",
    }