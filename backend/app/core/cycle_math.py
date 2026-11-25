"""Single source of truth for all cycle numbers.

Every screen must read its cycle length, next period, cycle day and
consistency from build_cycle_summary(). Do not recompute these elsewhere.

The thresholds below are placeholders and need clinical review.
"""

from __future__ import annotations

from datetime import date, timedelta
from typing import Any, Iterable

DEFAULT_CYCLE_LENGTH = 28
DEFAULT_PERIOD_LENGTH = 5
MIN_PLAUSIBLE_CYCLE = 10      # shorter gaps are probably duplicate entries
MAX_PLAUSIBLE_CYCLE = 120     # longer gaps are probably missed logging
RECENT_CYCLES_USED = 6        # prediction uses the most recent cycles
MIN_CYCLES_FOR_PATTERN = 3    # needed before calling cycles regular or not
PREDICTED_CYCLES_AHEAD = 3
MAX_PERIOD_LENGTH = 14


def _typical_period_length(periods: Iterable[Any]) -> int:
    durations = []
    for p in periods:
        if p.end_date is not None and p.end_date >= p.start_date:
            days = (p.end_date - p.start_date).days + 1
            if days <= MAX_PERIOD_LENGTH:
                durations.append(days)
    if not durations:
        return DEFAULT_PERIOD_LENGTH
    return round(sum(durations) / len(durations))


def _phase(cycle_day: int, cycle_length: int, period_length: int) -> str | None:
    """Rough estimate for regular cycles only. Not shown for other stages."""
    if cycle_day < 1 or cycle_day > cycle_length:
        return None
    if cycle_day <= period_length:
        return "menstrual"
    if cycle_day < cycle_length - 13:
        return "follicular"
    return "luteal"


def _consistency(recent_lengths: list[int], total_cycles: int) -> dict[str, Any]:
    if total_cycles < MIN_CYCLES_FOR_PATTERN:
        return {
            "level": "not_enough_data",
            "spread_days": None,
            "message": (
                "Log at least 3 full cycles to see how regular "
                "your cycles are."
            ),
        }

    spread = max(recent_lengths) - min(recent_lengths)

    if spread <= 7:
        level = "regular"
        message = f"Your recent cycles vary by {spread} days, which is fairly regular."
    elif spread <= 14:
        level = "variable"
        message = f"Your recent cycles vary by {spread} days."
    else:
        level = "irregular"
        message = (
            f"Your recent cycles vary by {spread} days. "
            "Consider discussing this with a doctor."
        )

    return {"level": level, "spread_days": spread, "message": message}


def build_cycle_summary(periods: Iterable[Any], today: date | None = None) -> dict[str, Any]:
    """periods: objects with .start_date and .end_date (end may be None)."""
    periods = list(periods)
    today = today or date.today()

    starts = sorted({p.start_date for p in periods})

    cycles: list[dict[str, Any]] = []
    for previous, current in zip(starts, starts[1:]):
        days = (current - previous).days
        if MIN_PLAUSIBLE_CYCLE <= days <= MAX_PLAUSIBLE_CYCLE:
            cycles.append({"start": previous.isoformat(), "length": days})

    lengths = [c["length"] for c in cycles]
    recent = lengths[-RECENT_CYCLES_USED:]
    period_length = _typical_period_length(periods)

    if lengths:
        average: float | None = round(sum(lengths) / len(lengths), 1)
        shortest: int | None = min(lengths)
        longest: int | None = max(lengths)
        cycle_length_used = round(sum(recent) / len(recent))
        basis = "your_history"
    else:
        average = shortest = longest = None
        cycle_length_used = DEFAULT_CYCLE_LENGTH
        basis = "default"

    summary: dict[str, Any] = {
        "periods_logged": len(starts),
        "cycles_recorded": len(lengths),
        "average_cycle_length": average,
        "shortest_cycle": shortest,
        "longest_cycle": longest,
        "cycle_length_used": cycle_length_used,
        "prediction_basis": basis,
        "typical_period_length": period_length,
        "cycles": cycles[-12:],
        "consistency": _consistency(recent, len(lengths)),
        "last_period_start": None,
        "cycle_day": None,
        "phase": None,
        "next_period_start": None,
        "next_period_earliest": None,
        "next_period_latest": None,
        "days_until_next": None,
        "days_late": 0,
        "status": "no_data",
        "predicted_days": [],
    }

    if not starts:
        return summary

    last_start = starts[-1]
    summary["last_period_start"] = last_start.isoformat()

    cycle_day = (today - last_start).days + 1 if today >= last_start else None
    summary["cycle_day"] = cycle_day
    if cycle_day is not None:
        summary["phase"] = _phase(cycle_day, cycle_length_used, period_length)

    next_start = last_start + timedelta(days=cycle_length_used)
    summary["next_period_start"] = next_start.isoformat()

    if len(lengths) >= MIN_CYCLES_FOR_PATTERN:
        earliest = last_start + timedelta(days=min(recent))
        latest = last_start + timedelta(days=max(recent))
    else:
        earliest = next_start - timedelta(days=2)
        latest = next_start + timedelta(days=2)
    summary["next_period_earliest"] = earliest.isoformat()
    summary["next_period_latest"] = latest.isoformat()

    if today > next_start:
        summary["status"] = "late"
        summary["days_late"] = (today - next_start).days
        summary["days_until_next"] = 0
    else:
        summary["status"] = "on_track"
        summary["days_until_next"] = (next_start - today).days

    predicted: list[str] = []
    for i in range(PREDICTED_CYCLES_AHEAD):
        start = next_start + timedelta(days=i * cycle_length_used)
        for offset in range(period_length):
            day = start + timedelta(days=offset)
            if day >= today:
                predicted.append(day.isoformat())
    summary["predicted_days"] = predicted

    return summary