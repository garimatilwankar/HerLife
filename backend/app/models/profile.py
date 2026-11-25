from datetime import date, datetime

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    ForeignKey,
    Integer,
    String,
    false,
)
from sqlalchemy.orm import Mapped, mapped_column, validates

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

    # --- Onboarding answers ---
    # "yes", "no" or "not_sure". PCOS/PCOD is a condition, not a stage.
    pcos_status: Mapped[str | None] = mapped_column(String(20), nullable=True)
    last_period_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    cycle_length: Mapped[int | None] = mapped_column(Integer, nullable=True)
    period_length: Mapped[int | None] = mapped_column(Integer, nullable=True)
    # Comma-separated, e.g. "Cramps,Mood,Sleep"
    main_concerns: Mapped[str | None] = mapped_column(String(500), nullable=True)

    onboarding_completed: Mapped[bool] = mapped_column(
        Boolean, default=False, server_default=false(), nullable=False
    )
    tutorial_seen: Mapped[bool] = mapped_column(
        Boolean, default=False, server_default=false(), nullable=False
    )

    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
        nullable=False,
    )
    @validates("onboarding_completed", "tutorial_seen")
    def _no_empty_flags(self, key, value):
        # These two columns can never be empty. Treat "nothing sent" as False.
        return bool(value)