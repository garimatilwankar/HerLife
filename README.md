# HerLife

A stage-aware women's health companion for Android. It gives information and
pattern awareness, not medical advice or diagnosis.

Stack: Flutter (app), FastAPI + SQLAlchemy (backend), PostgreSQL, JWT login.

## Life stages

Defined once in `backend/app/core/stages.py` and `lib/core/stages.dart`.
Never type a stage name anywhere else.
Adolescence, Menstruation, Pregnancy, Postpartum, Perimenopause, Menopause.

## App layout

Five tabs: Home, Track (logging + patterns together), Wellness, Learn, Settings.
Every tab uses the shared header in `lib/widgets/herlife_header.dart`
(logo, name, life stage, Ask button at top right).
Home has one top card: calendar shortcut to Track, period day or next period
date, small cycle ring, and a daily fact (`lib/core/health_facts.dart`).

## Run it

Backend (from `backend`, venv active):

    python -m uvicorn app.main:app --host 0.0.0.0 --port 8000

App (from the repo root): `flutter run`

On a real phone, set the server URL in the app to `http://<your-PC-IP>:8000`
(same Wi-Fi). On the Android emulator use `http://10.0.2.2:8000`.

Tests (from `backend`): `python -m pytest tests -q`
After pulling the onboarding branch, run once: `python add_profile_columns.py`

## Branches

Each branch is stacked on the one above it, so merge them in this order.

| Order | Branch | What it does |
|---|---|---|
| 1 | fix/cycle-math | One shared cycle calculation |
| 2 | fix/stage-names | Six stages defined in one place, validated by the backend |
| 3 | feature/app-shell | 5 tabs, shared header with stage name, merged Track tab |
| 4 | feature/onboarding | New profile fields for onboarding answers and PCOS/PCOD flag (no screens yet) |
| 5 | feature/home-card | Home top card with daily fact and calendar shortcut |

If something breaks, find the branch that last touched the file.

## Not started or on hold

PCOS/PCOD settings, sign-up questionnaire, tutorial cards, Wellness tab, Learn by stage.