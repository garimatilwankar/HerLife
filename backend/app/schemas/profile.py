from datetime import date

from pydantic import BaseModel, Field, field_validator

from app.core.stages import ALL_STAGES, normalize_stage

PCOS_VALUES = ("yes", "no", "not_sure")


class ProfileUpdate(BaseModel):
    date_of_birth: date | None = None
    biological_assignment: str | None = None
    lifecycle_stage: str | None = None

    pcos_status: str | None = None
    last_period_date: date | None = None
    cycle_length: int | None = Field(default=None, ge=15, le=90)
    period_length: int | None = Field(default=None, ge=1, le=15)
    main_concerns: str | None = Field(default=None, max_length=500)
    onboarding_completed: bool | None = None
    tutorial_seen: bool | None = None

    @field_validator("lifecycle_stage", mode="before")
    @classmethod
    def _check_stage(cls, value):
        if value is None:
            return None
        stage = normalize_stage(value)
        if stage is None:
            raise ValueError(
                "Unknown lifecycle stage. Use one of: "
                + ", ".join(ALL_STAGES)
                + "."
            )
        return stage

    @field_validator("pcos_status")
    @classmethod
    def _check_pcos(cls, value):
        if value is None:
            return None
        cleaned = value.strip().lower()
        if cleaned not in PCOS_VALUES:
            raise ValueError("pcos_status must be yes, no or not_sure.")
        return cleaned

    @field_validator("last_period_date")
    @classmethod
    def _not_future(cls, value):
        if value is not None and value > date.today():
            raise ValueError("Last period date cannot be in the future.")
        return value


class ProfileResponse(ProfileUpdate):
    id: int
    user_id: int

    model_config = {"from_attributes": True}