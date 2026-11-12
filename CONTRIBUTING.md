# Contributing to Life Wizard

Thank you for your interest in contributing to **Life Wizard**! Every contribution—whether it's a bug fix, UI polish, AI prompt improvement, new test, or documentation update—helps make Life Wizard a better open-source personal operating system.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Architecture Overview](#architecture-overview)
- [Development Workflow](#development-workflow)
- [Coding & Architecture Standards](#coding--architecture-standards)
- [Testing & Verification](#testing--verification)
- [Pull Request Process](#pull-request-process)
- [Security & API Keys](#security--api-keys)
- [License](#license)

---

## Code of Conduct

Be respectful, constructive, and empathetic in all issues, pull requests, and discussions. Focus feedback on code and user impact, welcome newcomers, and assume good intent. Harassment or exclusionary behavior is not tolerated.

---

## Getting Started

### Prerequisites

- **Flutter SDK** (`Dart SDK >=3.7.2 <4.0.0`, see `pubspec.yaml`)
- **Git**
- Platform toolchain for your target (Android Studio / Xcode / Visual Studio Desktop C++ / Linux GTK)
- Optional: a [Google AI Studio](https://aistudio.google.com/) Gemini API key to test live AI chat features

### Local Setup

```bash
# 1. Fork the repository on GitHub, then clone your fork
git clone https://github.com/<your-username>/Life-Wizard.git
cd Life-Wizard

# 2. Add upstream remote
git remote add upstream https://github.com/Majidi-star/Life-Wizard.git

# 3. Install dependencies
flutter pub get

# 4. Run static analysis and tests to verify your baseline
flutter analyze
flutter test

# 5. Launch the app
flutter run
```

> **Note:** On desktop targets (Windows, Linux, macOS), `main.dart` automatically initializes `sqflite_common_ffi` so SQLite works out of the box without extra database setup.

---

## Architecture Overview

Life Wizard follows a **feature-first BLoC + Repository** architecture backed by local **SQLite** (`life_wizard.db` in `lib/database_initializer.dart`) and a **Gemini AI function-calling pipeline**:

```text
lib/
├── main.dart                     # App bootstrap, global BLoCs, theme & routes
├── database_initializer.dart     # SQLite schema (v2) & migrations
├── utils/                        # Alarms/TTS, notifications, Stoic quotes, themes
├── widgets/                      # Shared UI (AppDrawer, LoadingScreen)
└── features/
    ├── ai_chat/                  # AIChatBloc, GeminiChatService, chat UI & models
    ├── ai_prompting/             # SystemPrompt, MessageFormatter, AIFunctions, FunctionExecutor
    ├── goals/                    # Goals, roadmaps, formulas & progress comparisons
    ├── habits/                   # Habit tracking, streaks & timelines
    ├── mood_data/                # Mood check-in Q&A & prompt context injection
    ├── pro_clock/                # Dual-mode timer (Schedule + Pomodoro), alarms & TTS
    ├── progress_dashboard/       # PointsService & RewardRepository (points, badges, cookie jar)
    ├── schedule/                 # Timeboxed daily blocks, challenge tags & productivity heatmaps
    ├── settings/                 # Theme, language, notifications, guidelines & secure API key
    └── todo/                     # Prioritized tasks
```

---

## Development Workflow

1. **Sync with `upstream/main`** before starting new work:
   ```bash
   git fetch upstream
   git checkout -b feat/your-feature-name upstream/main
   ```
2. **Keep changes focused**: Prefer small, cohesive PRs over sweeping unrelated edits.
3. **Update tests & docs**: Add unit/widget tests for bug fixes or new logic, and update documentation if behavior or setup changes.

### Commit Message Convention

Use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat(scope): add ...` — New user-facing feature
- `fix(scope): resolve ...` — Bug fix
- `refactor(scope): ...` — Code restructuring without behavior change
- `test(scope): ...` — Adding or updating tests
- `docs(scope): ...` — Documentation updates
- `chore(scope): ...` — Dependencies, build tooling, CI, maintenance

Examples:
- `feat(pro_clock): add custom Pomodoro break presets`
- `fix(schedule): normalize YYYY-MM-DD date queries across timezones`

---

## Coding & Architecture Standards

- **Linting & Formatting**: Follow `analysis_options.yaml` (`package:flutter_lints/flutter.yaml`). Format all Dart files before committing:
  ```bash
  dart format lib test
  ```
- **BLoC Pattern**:
  - Keep business logic inside `*_bloc.dart` and persistence inside `*_repository.dart`, not inside UI widgets.
  - Extend `Equatable` on events and states so rebuilds remain predictable.
  - Use `bloc_concurrency` transformers where rapid/duplicate events could race.
- **Database & Dates**:
  - Always access SQLite via `DatabaseInitializer.database` and normalize dates with `DatabaseInitializer.normalizeDateString` / `formatDateOnly` (`YYYY-MM-DD`).
  - Use parameterized SQL queries (`?` placeholders) and escape `LIKE` patterns (`_escapeLikePattern` in `AI_functions.dart`).
  - Bump `openDatabase(version: ...)` and add deterministic `onUpgrade` logic whenever altering SQLite tables or indexes.
- **AI Function Calling**:
  - Register new AI tools cleanly across `sys_prompt.dart`, `AI_functions.dart`, and `function_executor.dart`, and refresh affected BLoCs after DB mutations so the UI stays in sync.
  - Keep destructive operations guarded with user confirmation (`confirmDeleteHandler`).
- **Platform Guardrails**:
  - Guard `Platform.*` checks with `!kIsWeb` and keep mobile-only notification plugins safely gated for desktop/web builds.

---

## Testing & Verification

Before opening a pull request, run:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

If you use AI coding assistants (**Claude Code** or **Antigravity**), project-specific rules and skills are already configured in `CLAUDE.md`, `GEMINI.md`, `AGENTS.md`, and `.agents/`.

---

## Pull Request Process

1. Ensure `flutter analyze` reports **no new issues** and `flutter test` passes.
2. Include a clear summary in your PR description:
   - **What** changed and **why**
   - **Screenshots or recordings** for any UI/UX changes
   - **Verification steps** you ran (target platform, tests, manual checks)
3. Keep unrelated build outputs (`build/`, `android/build/`, `.dart_tool/`) out of your commits.

---

## Security & API Keys

- **Never commit** API keys, tokens, keystores, or personal `.db` files.
- Gemini API keys are stored on-device using `flutter_secure_storage` and must remain sanitized from logs and error messages (see `GeminiChatService.sanitizeErrorText`).
- If you discover a security issue, please avoid posting exploit details in public issues—contact the repository maintainer privately via GitHub.

---

## License

By contributing to Life Wizard, you agree that your contributions will be licensed under the **Apache License 2.0**. See [LICENSE](LICENSE) for full details.
