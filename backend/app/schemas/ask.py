from pydantic import BaseModel, Field


class AskRequest(BaseModel):
    question: str = Field(..., min_length=1)


class AskSourceSchema(BaseModel):
    id: int
    title: str
    summary: str | None = None
    category: str
    lifecycle_stage: str | None = None
    source_name: str | None = None
    source_url: str | None = None

    model_config = {"from_attributes": True}


class AskResponse(BaseModel):
    question: str
    intent: str = "GENERAL_INFORMATION"
    safety_level: str = "INFORMATIONAL"
    answer: str
    sources: list[AskSourceSchema]
    disclaimer: str
