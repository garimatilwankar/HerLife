from datetime import datetime

from pydantic import BaseModel


class EducationResponse(BaseModel):
    id: int
    title: str
    summary: str | None = None
    content: str
    category: str
    lifecycle_stage: str | None = None
    source_name: str | None = None
    source_url: str | None = None
    created_at: datetime

    model_config = {"from_attributes": True}
