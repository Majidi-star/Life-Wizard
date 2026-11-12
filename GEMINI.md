# GEMINI.md

Workspace instructions for **Antigravity / Gemini** in **Life Wizard** (`d:\Life-Wizard`).

## Context & Token Efficiency

- Check `graphify-out/GRAPH_REPORT.md` first for architectural mapping, god nodes, and communities.
- Use `graphify query "<topic>" --terse` and `graphify explain "<entity>"` before reading files; prefer bounded reads (`StartLine`/`EndLine`).
- Workspace rules in `.agents/rules/` and skills in `.agents/skills/` apply automatically.

## Tech Stack & Entry Points

- **Framework**: Flutter (`Dart SDK >=3.7.2 <4.0.0`, `flutter_lints ^6.0.0` in `analysis_options.yaml`).
- **State**: `flutter_bloc` + `equatable` + `bloc_concurrency`, wired as global singletons in `lib/main.dart`.
- **Persistence**: Local SQLite (`life_wizard.db`, version 2) in `lib/database_initializer.dart`, with `sqflite_common_ffi` initialized for Windows/Linux/macOS.
- **AI Pipeline**:
  - Transport: `lib/features/ai_chat/gemini_chat_service.dart` (`kDefaultGeminiModel = 'gemini-2.5-flash'`).
  - Prompting & Tools: `lib/features/ai_prompting/sys_prompt.dart`, `message_formatter.dart`, `AI_functions.dart`, `function_executor.dart`.
- **Key Subsystems**:
  - `pro_clock/`: Dual-mode timer (`TimerMode.schedule` and Pomodoro phases), audio alarm + TTS (`lib/utils/alarm_utils.dart`).
  - `schedule/`: Timeboxed daily blocks, challenge tags, productivity heatmap scores, synced daily habits.
  - `goals/` & `habits/` & `todo/`: Core life-tracking modules.
  - `mood_data/`: Q&A mood tracking injected into `{MOOD_DATA_PLACEHOLDER}` via `MessageFormatter.buildSystemInstruction`.
  - `progress_dashboard/`: `PointsService` and `RewardRepository` (`points`, `badges`, `cookie_jar`, `hours_worked`).

## Verification

Before concluding any code change, run:
```bash
flutter analyze
flutter test
```
Keep commits free of build artifacts (`build/`, `android/build/`, `.dart_tool/`).
