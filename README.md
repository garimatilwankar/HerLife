# HerLife

A stage-aware women's health companion for Android. It gives information and
pattern awareness, not medical advice or diagnosis.

Stack: Flutter (app), FastAPI + SQLAlchemy (backend), PostgreSQL, JWT login.

## Life stages

Defined once in `backend/app/core/stages.py` and `lib/core/stages.dart`.
Never type a stage name anywhere else.

Adolescence, Menstruation, Pregnancy, Postpartum, Perimenopause, Menopause.

PCOS/PCOD is a condition flag on the profile (`pcos_status`), not a stage.

## App layout

Five bottom tabs: Home, Track (logging + patterns together), Wellness, Learn, Settings.
Every tab uses the shared header in `lib/widgets/herlife_header.dart`
(logo, name, life stage, and the Ask button at the top right).

## Run it

Backend (from the `backend` folder, venv active):

    python -m uvicorn app.main:app --host 0.0.0.0 --port 8000

App (from the repo root):

    flutter run

On a real phone, set the server URL in the app to `http://<your-PC-IP>:8000`
(phone and PC on the same Wi-Fi). On the Android emulator it is `http://10.0.2.2:8000`.

Tests (from the `backend` folder): `python -m pytest tests -q`

After adding profile columns, run once: `python add_profile_columns.py`

## Branch log

One branch per feature. If something breaks, find the branch that last touched it.

| Branch | What it did | Status |
|---|---|---|
| fix/cycle-math | One shared cycle calculation | not merged yet |
| fix/stage-names | Six stages defined in one place, validated by the backend | not merged yet |
| feature/app-shell | 5 tabs, shared header with stage name, merged Track tab | done |
| feature/onboarding | Profile fields for onboarding answers and PCOS/PCOD flag (screens not built yet) | on hold |
| feature/home-polish | Home top card: calendar shortcut, period day or next period date, small ring, daily fact (stored in app) | in progress |

## On hold

Sign-up questionnaire, first-time tutorial cards, Wellness tab (videos, diet questionnaire, calm sounds).

## Planned

PCOS/PCOD content across tabs, Learn tab by stage, widgets, Med-Gemini/MedGemma in Ask
(with the safety rules layer kept in front of it).