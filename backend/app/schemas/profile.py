from datetime import date

from pydantic import BaseModel, field_validator

from app.core.stages import ALL_STAGES, normalize_stage


class ProfileUpdate(BaseModel):
    date_of_birth: date | None = None
    biological_assignment: str | None = None
    lifecycle_stage: str | None = None

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


class ProfileResponse(ProfileUpdate):
    id: int
    user_id: int

    model_config = {"from_attributes": True}