# Flutter, BLoC & SQLite Conventions

- **Feature Isolation**: Place new UI, BLoC, repository, and model files inside `lib/features/<feature>/`.
- **Single Source of Truth**: Reuse the global BLoCs exposed from `lib/main.dart` rather than instantiating duplicate feature BLoCs in screens.
- **SQLite Safety**:
  - Access the DB only through `DatabaseInitializer.database`.
  - Use `DatabaseInitializer.normalizeDateString` / `formatDateOnly` for `schedule` dates (`YYYY-MM-DD`).
  - Always use parameterized SQL queries; never interpolate user or AI strings into SQL.
- **AI Security & Observability**:
  - Keep `GeminiChatService.debugMode` tied to `kDebugMode`.
  - Always mask secrets with `GeminiChatService.sanitizeErrorText` before surfacing errors to UI or logs.
- **Lint & Test Gate**: Every code change must pass `flutter analyze` and `flutter test`.
