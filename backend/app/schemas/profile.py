from datetime import date

from pydantic import BaseModel


class ProfileUpdate(BaseModel):
    date_of_birth: date | None = None
    biological_assignment: str | None = None
    lifecycle_stage: str | None = None


class ProfileResponse(ProfileUpdate):
    id: int
    user_id: int

    model_config = {"from_attributes": True}