import pytest
from pydantic import ValidationError

from app.core.stages import ALL_STAGES, normalize_stage
from app.schemas.profile import ProfileUpdate


def test_six_stages_one_word_each():
    assert len(ALL_STAGES) == 6
    assert all(" " not in s for s in ALL_STAGES)
    assert "Conception" not in ALL_STAGES


def test_normalize_known_and_legacy():
    assert normalize_stage("menopause") == "Menopause"
    assert normalize_stage(" Reproductive Health ") == "Menstruation"
    assert normalize_stage("Reproductive Years") == "Menstruation"
    assert normalize_stage("Conception") == "Menstruation"
    assert normalize_stage("nonsense") is None
    assert normalize_stage(None) is None


def test_profile_rejects_typo_and_accepts_legacy():
    assert (
        ProfileUpdate(lifecycle_stage="Reproductive Health").lifecycle_stage
        == "Menstruation"
    )
    with pytest.raises(ValidationError):
        ProfileUpdate(lifecycle_stage="Perimenopau se")

def test_onboarding_fields_validate():
    ok = ProfileUpdate(pcos_status="Not_Sure", cycle_length=28, period_length=5)
    assert ok.pcos_status == "not_sure"
    with pytest.raises(ValidationError):
        ProfileUpdate(pcos_status="maybe")
    with pytest.raises(ValidationError):
        ProfileUpdate(cycle_length=5)