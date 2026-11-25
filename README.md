# HerLife

A stage-aware women's health companion for Android. It gives information and pattern awareness, not medical advice or diagnosis.

Stack: Flutter (app), FastAPI + SQLAlchemy (backend), PostgreSQL, JWT login.

--------------------------------------------------

## Current features

### Shared header (lib/widgets/herlife_header.dart)
- One line on every tab: HL logo, title, life stage chip, Ask button (top right)
- Home shows "Hi, <name>". Every other tab shows its own name (Track, Wellness, Learn, Settings)
- The stage chip never wraps. Long titles shorten with "..."
- Name and stage load from the profile. Add 1 to `HerLifeHeader.reload` to refresh every header

### Home
- Hero card with a soft gradient: phase chip, period day or next period date, animated cycle ring, daily health fact
- Quick actions: Log period, Check-in, Calm, Calendar
- Today's check-in card
- Your week: Monday to Sunday strip with period days, predicted range and today
- Today's tip with Move, Eat and Calm switcher and an "Ask about this" button
- Your pattern: unlocks after 3 cycles, with a progress bar and a "Why am I seeing this?" panel
- "Feeling off?" shortcut (opens Ask for now)
- Summary tiles: last period, cycles, average
- Loading placeholders and an error card with Retry, so a server failure never looks like "no data"

### Track (logging and patterns together)
- Summary tiles: cycle day, next period, average cycle length
- Month calendar: logged period days and predicted days in different tints, with a Today marker
- History list of periods with length, and an Add end action for ongoing periods
- Your patterns: average, shortest, longest cycle, cycle length chart
- Symptoms and latest mood chips
- Floating Log period button
- All numbers come from one shared cycle calculation, so Home and Track always agree

### Wellness
- Move: workout routines with duration, filter chips and external video links
- Eat: diet questionnaire (food preference and allergies), then matching recipes
- Calm: guided breathing (calm, box, 4-7-8) with an animated circle

### Learn
- Searchable article list with category filters

### Settings
- Server URL and app preferences

### Onboarding questions (built, not yet wired into sign up)
- 14 personalisation questions, one per page, all skippable, with a progress bar
- Covers life stage, cycles, known conditions, hormonal medication, cycle and period length, symptoms, last period, activity, sleep, stress and goals
- Cycle questions are hidden when periods have stopped or never started
- Answers are saved on the device for now (lib/core/onboarding_store.dart). Syncing to the backend profile is not done yet
- Question wording lives in lib/core/onboarding_questions.dart

### Tutorial guide (built, not yet wired into sign up)
- Six swipeable cards after onboarding: Home, Track, Wellness, Learn, Ask (top right), Settings
- The Learn card tells new users where to read about their stage or a problem
- Shown once. Skippable

--------------------------------------------------

## Design rules

- Colours and sizes come from lib/screens/tabs/ui.dart (kWine, kBlush, kBg) and lib/core/design_tokens.dart (HL). Point the first at the second so there is one source
- Shared pieces in lib/widgets/her_components.dart and lib/widgets/home_cards.dart are for new screens. Older screens still use AppCard and Pill

--------------------------------------------------

## Life stages

Defined once in backend/app/core/stages.py and lib/core/stages.dart. Never type a stage name anywhere else.

Current stages: Adolescence, Menstruation, Pregnancy, Postpartum, Perimenopause, Menopause.

The onboarding question about life stage uses wider wording (for example Postmenopause, "I'm not sure"). Mapping those answers to the six stages is still to be decided.

--------------------------------------------------

## App layout

Five tabs: Home, Track, Wellness, Learn, Settings.
Every tab starts with the shared header. Daily facts live in lib/core/health_facts.dart.

--------------------------------------------------

## Run it

Backend (from backend, venv active):

    python -m uvicorn app.main:app --host 0.0.0.0 --port 8000

App (from the repo root):

    flutter run

- Real phone: set the server URL in the app to http://<your-PC-IP>:8000 (same Wi-Fi)
- Android emulator: use http://10.0.2.2:8000

Tests (from backend):

    python -m pytest tests -q

After pulling the onboarding branch, run once: python add_profile_columns.py

Check the app code before committing: flutter analyze

--------------------------------------------------

## Branches

Each branch is stacked on the one above it, so merge in this order. Make a branch for each feature so a bug is easy to trace. Do not make extra branches for tiny fixes.

### Developed

| Order | Branch | What it does |
|---|---|---|
| 1 | fix/cycle-math | One shared cycle calculation |
| 2 | fix/stage-names | Six stages defined in one place, validated by the backend |
| 3 | feature/app-shell | 5 tabs, shared header, merged Track tab |
| 4 | feature/onboarding | New profile fields for onboarding answers and PCOS/PCOD flag (no screens) |
| 5 | feature/home-card | Home top card with daily fact and calendar shortcut |
| 6 | feature/wellness-tab | Wellness tab: workout links, diet questionnaire with recipes, breathing |
| 7 | feature/design-system | Single-line header with tab titles, design tokens, shared components, redesigned Home |
| 8 | feature/onboarding-screens | 14-question onboarding and 6-card tutorial screens |

### Planned

| Branch | What it will do |
|---|---|
| feature/auth-flow | Wire onboarding and tutorial into sign up, splash, welcome, stage picker |
| feature/pcos-pcod | PCOS/PCOD settings and content |
| feature/stage-resolver | Server tells the app which cards and content apply per stage |
| feature/symptom-guide | "Feeling off?" guide and red-flag system |
| feature/insights | Deeper analysis and doctor report PDF |
| feature/ask-v2 | AI chat with safety layer (Med-Gemini) |
| release/hardening | Cleartext traffic removal, signing, privacy and deletion |

### Conventions

- Branch names: fix/<thing>, feature/<thing>, release/<thing>
- Commit messages: type(scope): what changed, for example fix(cycle): handle period with no end date
- Never commit directly to main
- Before merging, run the backend tests, run flutter analyze, and open every tab once on the emulator

### Finding a bug

1. Note which screen or number is wrong
2. Find the branch that last touched the file: git log --oneline -- path/to/file
3. Check out the commit before it and see if the bug is gone
4. If it is gone, the bug came from that branch

--------------------------------------------------

## Not started or on hold

Wiring onboarding and tutorial into sign up, syncing answers to the backend, PCOS/PCOD settings, Learn by stage, widgets, Wellness videos by stage, Insights, Ask v2, Hindi/Hinglish, discreet mode and app lock.

--------------------------------------------------

## Rules every feature follows

- One cycle calculation feeds every screen
- Information, not diagnosis
- No calorie counting, weight targets or body-shape goals
- Every screen handles loading, empty, error and content states
- Health content is reviewed by a doctor before launch