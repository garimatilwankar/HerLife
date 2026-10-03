from datetime import date

from pydantic import BaseModel, Field


class PeriodCreate(BaseModel):
    start_date: date
    end_date: date | None = None


class PeriodResponse(PeriodCreate):
    id: int

    model_config = {"from_attributes": True}


class SymptomCreate(BaseModel):
    recorded_on: date
    name: str = Field(min_length=1, max_length=100)
    severity: int | None = Field(default=None, ge=1, le=5)


class SymptomResponse(SymptomCreate):
    id: int

    model_config = {"from_attributes": True}


class CheckinCreate(BaseModel):
    recorded_on: date
    mood: str = Field(min_length=1, max_length=50)
    energy: int | None = Field(default=None, ge=1, le=5)
    notes: str | None = None


class CheckinResponse(CheckinCreate):
    id: int

    model_config = {"from_attributes": True}