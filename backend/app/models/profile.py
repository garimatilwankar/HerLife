from datetime import date, datetime

from sqlalchemy import JSON, Date, DateTime, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class Profile(Base):
    __tablename__ = "profiles"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
        index=True,
    )

    date_of_birth: Mapped[date | None] = mapped_column(Date, nullable=True)
    biological_assignment: Mapped[str | None] = mapped_column(
        String(50),
        nullable=True,
    )
    lifecycle_stage: Mapped[str | None] = mapped_column(
        String(50),
        nullable=True,
    )

    # Additive Lifecycle Personalization Fields
    primary_stage: Mapped[str | None] = mapped_column(
        String(50),
        nullable=True,
    )
    stage_start_date: Mapped[date | None] = mapped_column(
        Date,
        nullable=True,
    )
    goal: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )
    contexts: Mapped[list[str] | None] = mapped_column(
        JSON,
        nullable=True,
        default=list,
    )
    due_date: Mapped[date | None] = mapped_column(
        Date,
        nullable=True,
    )
    delivery_date: Mapped[date | None] = mapped_column(
        Date,
        nullable=True,
    )


    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
        nullable=False,
    )