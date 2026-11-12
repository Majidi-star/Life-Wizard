# Life Wizard Architecture & Coding Conventions

1. **BLoC & State**:
   - All events and states must extend `Equatable` and accurately implement `props`.
   - Global BLoCs in `lib/main.dart` (`settingsBloc`, `moodDataBloc`, `todoBloc`, `habitsBloc`, `goalsBloc`, `proClockBloc`, `scheduleBloc`, `aiChatBloc`) act as the single source of truth across routes.
   - Dispose timers and subscriptions cleanly in `Bloc.close()` and `State.dispose()`.

2. **SQLite & Persistence (`lib/database_initializer.dart`)**:
   - Always obtain the handle via `DatabaseInitializer.database`.
   - Normalize date strings to `YYYY-MM-DD` using `DatabaseInitializer.normalizeDateString` or `DatabaseInitializer.formatDateOnly`.
   - Parameterize every query (`?` placeholders) and escape `LIKE` patterns before querying.
   - Increment the SQLite `version` and write an idempotent `onUpgrade` migration when altering tables or indexes.

3. **AI Prompting & Function Calling (`lib/features/ai_prompting/`)**:
   - Keep `SystemPrompt`, `MessageFormatter`, `AIFunctions`, and `FunctionExecutor` synchronized whenever adding, renaming, or removing an AI tool.
   - Destructive actions (deletions) must respect `AIFunctions.confirmDeleteHandler` so both runtime UI confirmations and tests remain reliable.
   - Sanitize any error surfaced from Gemini HTTP calls with `GeminiChatService.sanitizeErrorText`.

4. **Platform & Asset Safety**:
   - Guard `Platform.is*` checks with `!kIsWeb`.
   - Keep `flutter_local_notifications` and timezone setup safe when running on desktop/web (`NotificationUtils`).
   - Run `flutter analyze` and `flutter test` before committing.
