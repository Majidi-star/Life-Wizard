# CLAUDE.md

Project guidance for **Claude Code** working in **Life Wizard** (cross-platform Flutter life-management OS powered by local SQLite, BLoC, and Gemini AI function calling).

## Commands

```bash
flutter pub get                                              # Install dependencies
flutter analyze                                              # Static analysis (package:flutter_lints)
flutter test                                                 # Run unit & widget tests
dart format --output=none --set-exit-if-changed lib test     # Verify formatting
flutter run                                                  # Launch app on connected target
```

If `graphify-out/GRAPH_REPORT.md` exists, prefer querying the local AST graph before broad searches:
```bash
graphify query "<topic>" --terse
graphify explain "<symbol_or_path>"
```

## Architecture

- **Entry & Navigation**: `lib/main.dart` initializes desktop SQLite (`sqflite_common_ffi` when `!kIsWeb` on Windows/Linux/macOS), opens `DatabaseInitializer.database`, constructs global singleton BLoCs (`settingsBloc`, `moodDataBloc`, `todoBloc`, `habitsBloc`, `goalsBloc`, `proClockBloc`, `scheduleBloc`, `aiChatBloc`), and registers named routes (`/`, `/settings`, `/todo`, `/goals`, `/habits`, `/schedule`, `/pro_clock`, `/mood`).
- **Database**: `lib/database_initializer.dart` manages `life_wizard.db` (currently schema v2) with tables: `settings`, `todo`, `schedule`, `moodData`, `habits`, `goals`, `logs`, `rewards`.
  - Always normalize schedule dates to `YYYY-MM-DD` via `DatabaseInitializer.normalizeDateString` / `formatDateOnly`.
  - Bump DB `version` and implement `onUpgrade` for any schema or index change.
- **State Management**: Feature-first `flutter_bloc` + `Equatable` + `bloc_concurrency`, organized under `lib/features/`:
  - `ai_chat/`: `AIChatBloc`, `GeminiChatService` (`kDefaultGeminiModel = 'gemini-2.5-flash'`), chat UI & structured cards.
  - `ai_prompting/`: `SystemPrompt`, `MessageFormatter`, `AIFunctions`, `FunctionExecutor`, `ai_message_service.dart`, `respones_handler.dart`.
  - `goals/`, `habits/`, `todo/`, `schedule/`, `mood_data/`, `pro_clock/`, `progress_dashboard/`, `settings/`.
- **AI Function Calling**:
  - Models emit `<function_call>{ "name": ..., "parameters": ... }</function_call>` blocks parsed by `FunctionExecutor.executeFunction`.
  - Mutations run through `AIFunctions` against SQLite and dispatch BLoC refresh events so UI stays consistent.
  - Destructive AI actions must go through `AIFunctions.confirmDeleteHandler` / `_confirmDeletion`.

## Critical Guardrails

- **Secrets & Logs**: Gemini API keys are stored via `flutter_secure_storage`. Never log API keys or raw URLs containing `?key=`; always sanitize via `GeminiChatService.sanitizeErrorText`.
- **SQL Safety**: Use parameterized `?` queries and escape `LIKE` wildcards.
- **Platform Safety**: Guard `Platform.*` calls with `!kIsWeb`; keep mobile notification setup (`NotificationUtils`) gated off unsupported targets.
- **Testing**: Keep `flutter analyze` clean and run `flutter test` after changes. See `.claude/rules/flutter-architecture.md` for detailed conventions.
