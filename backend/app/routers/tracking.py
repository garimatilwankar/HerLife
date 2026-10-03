from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.security import get_current_user
from app.database import get_db
from app.models.checkin import DailyCheckin
from app.models.period import Period
from app.models.symptom import Symptom
from app.models.user import User
from app.schemas.tracking import (
    CheckinCreate,
    CheckinResponse,
    PeriodCreate,
    PeriodResponse,
    SymptomCreate,
    SymptomResponse,
)


router = APIRouter(tags=["Health Tracking"])


# -------------------- PERIODS --------------------

@router.post(
    "/api/periods",
    response_model=PeriodResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_period(
    data: PeriodCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if data.end_date and data.end_date < data.start_date:
        raise HTTPException(
            status_code=400,
            detail="End date cannot be before start date.",
        )

    period = Period(
        user_id=current_user.id,
        **data.model_dump(),
    )

    db.add(period)
    db.commit()
    db.refresh(period)

    return period


@router.get("/api/periods", response_model=list[PeriodResponse])
def get_periods(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return list(
        db.scalars(
            select(Period)
            .where(Period.user_id == current_user.id)
            .order_by(Period.start_date.desc())
        ).all()
    )


@router.patch(
    "/api/periods/{period_id}",
    response_model=PeriodResponse,
)
def update_period(
    period_id: int,
    data: PeriodCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    period = db.scalar(
        select(Period).where(
            Period.id == period_id,
            Period.user_id == current_user.id,
        )
    )

    if period is None:
        raise HTTPException(status_code=404, detail="Period not found.")

    if data.end_date and data.end_date < data.start_date:
        raise HTTPException(
            status_code=400,
            detail="End date cannot be before start date.",
        )

    period.start_date = data.start_date
    period.end_date = data.end_date

    db.commit()
    db.refresh(period)

    return period


# -------------------- SYMPTOMS --------------------

@router.post(
    "/api/symptoms",
    response_model=SymptomResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_symptom(
    data: SymptomCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    symptom = Symptom(
        user_id=current_user.id,
        **data.model_dump(),
    )

    db.add(symptom)
    db.commit()
    db.refresh(symptom)

    return symptom


@router.get("/api/symptoms", response_model=list[SymptomResponse])
def get_symptoms(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return list(
        db.scalars(
            select(Symptom)
            .where(Symptom.user_id == current_user.id)
            .order_by(Symptom.recorded_on.desc())
        ).all()
    )


@router.delete("/api/symptoms/{symptom_id}")
def delete_symptom(
    symptom_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    symptom = db.scalar(
        select(Symptom).where(
            Symptom.id == symptom_id,
            Symptom.user_id == current_user.id,
        )
    )

    if symptom is None:
        raise HTTPException(status_code=404, detail="Symptom not found.")

    db.delete(symptom)
    db.commit()

    return {"message": "Symptom deleted successfully."}


# -------------------- DAILY CHECK-INS --------------------

@router.post(
    "/api/checkins",
    response_model=CheckinResponse,
)
def create_or_update_checkin(
    data: CheckinCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    checkin = db.scalar(
        select(DailyCheckin).where(
            DailyCheckin.user_id == current_user.id,
            DailyCheckin.recorded_on == data.recorded_on,
        )
    )

    if checkin is None:
        checkin = DailyCheckin(
            user_id=current_user.id,
            **data.model_dump(),
        )
        db.add(checkin)
    else:
        checkin.mood = data.mood
        checkin.energy = data.energy
        checkin.notes = data.notes

    db.commit()
    db.refresh(checkin)

    return checkin


@router.get("/api/checkins", response_model=list[CheckinResponse])
def get_checkins(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return list(
        db.scalars(
            select(DailyCheckin)
            .where(DailyCheckin.user_id == current_user.id)
            .order_by(DailyCheckin.recorded_on.desc())
        ).all()
    )