"""The one place where life-stage names are defined.

Do not type a stage name as a string anywhere else. Import from here.
"""

from __future__ import annotations

ADOLESCENCE = "Adolescence"
MENSTRUATION = "Menstruation"
PREGNANCY = "Pregnancy"
POSTPARTUM = "Postpartum"
PERIMENOPAUSE = "Perimenopause"
MENOPAUSE = "Menopause"

ALL_STAGES: tuple[str, ...] = (
    ADOLESCENCE,
    MENSTRUATION,
    PREGNANCY,
    POSTPARTUM,
    PERIMENOPAUSE,
    MENOPAUSE,
)

# Old spellings that may still exist in saved data.
_LEGACY_ALIASES = {
    "reproductive health": MENSTRUATION,
    "reproductive years": MENSTRUATION,
    "conception": MENSTRUATION,
    "menstruating": MENSTRUATION,
}

STAGE_MESSAGES: dict[str, str] = {
    ADOLESCENCE: "Your body is going through important developmental changes.",
    MENSTRUATION: "Your cycle can be tracked to understand your personal patterns.",
    PREGNANCY: "Pregnancy-related changes can be tracked and monitored.",
    POSTPARTUM: "Your body is recovering and adapting after pregnancy.",
    PERIMENOPAUSE: "Hormonal and cycle patterns may become more variable.",
    MENOPAUSE: "Changes after menopause can be tracked over time.",
}

DEFAULT_MESSAGE = "Track your health regularly to understand your patterns."


def normalize_stage(value: str | None) -> str | None:
    """Return the canonical stage name, or None if it is unknown."""
    if value is None:
        return None
    cleaned = value.strip().lower()
    if not cleaned:
        return None
    for stage in ALL_STAGES:
        if stage.lower() == cleaned:
            return stage
    return _LEGACY_ALIASES.get(cleaned)