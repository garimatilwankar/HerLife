# HerLife

A stage-aware women's health companion for Android. It gives information and pattern awareness, not medical advice or diagnosis.

Stack: Flutter (app), FastAPI + SQLAlchemy (backend), PostgreSQL, JWT login.

--------------------------------------------------

## Current features

### Sign up and first launch
- Flow: Welcome, Sign up or Log in, then onboarding questions, then the 6-card tutorial, then the stage picker (only if no stage was set), then the app
- The decision is made in AppGate (lib/main.dart)
- Existing users see the questions once. Every question is skippable
- The "onboarding done" flag is stored on the server profile and on the device. It is cleared on log out, so a second person on the same phone gets the questions

### Onboarding questions (lib/screens/onboarding, lib/core/onboarding_questions.dart)
- 14 personalisation questions, one per page, all skippable, with a progress bar
- Cycle questions are hidden when periods have stopped or never started
- All answers are saved on the device (lib/core/onboarding_store.dart)
- Synced to the backend profile: life stage, PCOS/PCOD status, last period, cycle length, period length, goals (as main concerns). Mapping lives in lib/services/profile_service.dart
- Not synced yet: symptoms, activity, sleep, stress, hormonal medication, focus
- Life stage answers map to the six stages: Reproductive years becomes Menstruation, Postmenopause becomes Menopause, "I'm not sure" opens the stage picker

### Tutorial guide (lib/screens/onboarding/tutorial_screen.dart)
- Six swipeable cards: Home, Track, Wellness, Learn, Ask (top right), Settings
- The Learn card tells new users where to read about their stage or a problem
- Shown once. Skippable

### Shared header (lib/widgets/herlife_header.dart)
- One line on every tab: HL logo, title, life stage chip, Ask button (top right)
- Home shows "Hi, <name>". Every other tab shows its own name (Track, Wellness, Learn, Settings)
- The stage chip never wraps. Long titles shorten with "..."
- Add 1 to `HerLifeHeader.reload` to refresh every header

### Home
- Hero card with a soft gradient: phase chip, period day or next period date, animated cycle ring, daily health fact
- Quick actions: Log period, Check-in, Calm, Calendar
- Today's check-in card
- Your week: Monday to Sunday strip with period days, predicted range and today
- Today's tip with Move, Eat and Calm switcher and an "Ask about this" button
- Your pattern: unlocks after 3 cycles, with a progress bar and a "Why am I seeing this?" panel
- PCOS / PCOD card (lib/widgets/pcos_card.dart): shown only when PCOS status is Yes (Move, Eat, Calm, Track tips) or Not sure (a gentle "talk to a doctor" card)
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
- Edit Profile: name, email, date of birth, biological assignment, life stage, PCOS / PCOD status

### Profile saving
- The profile is saved with PUT /api/profile/me. Only fields that are sent get changed (the backend uses `exclude_unset`, the app leaves out empty values), so saving one screen never wipes another screen's data

--------------------------------------------------

## Design rules

- Colours and sizes come from lib/screens/tabs/ui.dart (kWine, kBlush, kBg) and lib/core/design_tokens.dart (HL). Point the first at the second so there is one source
- Shared pieces in lib/widgets/her_components.dart and lib/widgets/home_cards.dart are for new screens. Older screens still use AppCard and Pill

--------------------------------------------------

## Life stages

Defined once in backend/app/core/stages.py and lib/core/stages.dart. Never type a stage name anywhere else.

Current stages: Adolescence, Menstruation, Pregnancy, Postpartum, Perimenopause, Menopause.

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
| 8 | feature/onboarding-screens | 14-question onboarding and 6-card tutorial, wired into sign up, profile sync, profile-wipe fix |
| 9 | feature/pcos-pcod | PCOS/PCOD Home card and Edit Profile setting |

### Planned

| Branch | What it will do |
|---|---|
| feature/onboarding-sync | Database columns so every onboarding answer syncs to the backend |
| feature/pcos-content | PCOS/PCOD content in Wellness (workouts, food) and Learn (articles) |
| feature/stage-resolver | Server tells the app which cards and content apply per stage |
| feature/symptom-guide | "Feeling off?" guide and red-flag system |
| feature/insights | Deeper analysis and doctor report PDF |
| feature/ask-v2 | AI chat with safety layer (Med-Gemini) |
| release/hardening | Cleartext traffic removal, signing, privacy and deletion, consent wording |

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

Syncing the remaining onboarding answers, PCOS/PCOD content in Wellness and Learn, Learn by stage, widgets, Wellness videos by stage, Insights, Ask v2, Hindi/Hinglish, discreet mode and app lock, consent wording update (data now goes to the server, not only the device).

--------------------------------------------------

## Rules every feature follows

- One cycle calculation feeds every screen
- Information, not diagnosis
- No calorie counting, weight targets or body-shape goals
- Every screen handles loading, empty, error and content states
- Health content is reviewed by a doctor before launch