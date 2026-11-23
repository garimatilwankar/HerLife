from datetime import date
from types import SimpleNamespace

from app.core.cycle_math import build_cycle_summary


def period(start, end=None):
    return SimpleNamespace(start_date=start, end_date=end)


def test_two_cycles_like_the_screenshots():
    periods = [
        period(date(2026, 10, 9), date(2026, 10, 13)),
        period(date(2026, 11, 3)),
        period(date(2026, 11, 21)),
    ]
    s = build_cycle_summary(periods, today=date(2026, 11, 22))

    assert s["cycle_day"] == 2
    assert s["cycles_recorded"] == 2
    assert s["average_cycle_length"] == 21.5
    assert s["shortest_cycle"] == 18
    assert s["longest_cycle"] == 25
    assert s["next_period_start"] == "2026-12-13"
    assert s["days_until_next"] == 21
    assert s["consistency"]["level"] == "not_enough_data"
    assert len(s["predicted_days"]) > 0


def test_no_data_uses_default_and_does_not_crash():
    s = build_cycle_summary([], today=date(2026, 11, 22))
    assert s["status"] == "no_data"
    assert s["cycle_length_used"] == 28
    assert s["predicted_days"] == []