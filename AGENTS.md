# AGENTS.md

Shared instructions for AI coding agents (**Claude Code**, **Antigravity**, **Codex**, and compatible tools) working on **Life Wizard**.

## Project Snapshot

**Life Wizard** is a cross-platform Flutter life-management application (Android, iOS, Windows, macOS, Linux, Web) combining:
- Agentic **Gemini AI** coaching with structured `<function_call>` tool execution against local SQLite
- **Goals** (formulas, scores, milestones, roadmaps), **Habits** (streaks & timelines), **Todos**, and **Timeboxed Schedules**
- **Pro Clock** focus engine (Schedule-synced timer + Pomodoro mode, alarms, TTS via `flutter_tts`)
- **Mood Check-ins**, **Gamified Rewards** (`points`, `badges`, `cookie_jar`, `hours_worked`), **Stoic Quotes**, and **Local Notifications**

## Repository Map

- `lib/main.dart` — Desktop `sqflite_common_ffi` init, DB initialization, global BLoC singletons, theme & routes
- `lib/database_initializer.dart` — SQLite schema (`life_wizard.db`, v2), date normalization helpers (`YYYY-MM-DD`)
- `lib/features/` — Feature modules (`ai_chat`, `ai_prompting`, `goals`, `habits`, `mood_data`, `pro_clock`, `progress_dashboard`, `schedule`, `settings`, `todo`)
- `lib/utils/` — `alarm_utils.dart`, `notification_utils.dart`, `stoic_quotes.dart`, `theme_utils.dart`
- `lib/widgets/` — `app_drawer.dart`, `loading_screen.dart`
- `test/` — Unit & widget tests (`test/widget_test.dart`)

## Engineering Rules

1. **BLoC & Repository Separation**: Keep SQLite/HTTP I/O in `*_repository.dart` or services, state transitions in `*_bloc.dart`, and UI declarative in `*_screen.dart` / `*_widgets.dart`.
2. **Date Consistency**: Store and query `schedule.date` in `YYYY-MM-DD` via `DatabaseInitializer.normalizeDateString` / `formatDateOnly`.
3. **AI Tool Synchronization**: Whenever `AIFunctions` mutates DB state, notify the corresponding BLoC(s) so active screens stay up to date.
4. **Security**: Never expose or log Gemini API keys; preserve `GeminiChatService.sanitizeErrorText` and `flutter_secure_storage` usage.
5. **Cross-Platform Guards**: Gate `dart:io` `Platform.*` checks behind `!kIsWeb`, and keep mobile-only plugins safe on desktop/web.
6. **Verification**: Run `flutter analyze` and `flutter test` after every code edit.
