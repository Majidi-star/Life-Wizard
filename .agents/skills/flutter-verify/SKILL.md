---
name: flutter-verify
description: Runs Dart formatting check, Flutter static analysis, and Flutter test suite with clean filtered output for Life Wizard.
---

# Flutter Verification Workflow

Run the standard Life Wizard verification pipeline before committing or concluding a task:

```bash
dart format --output=none --set-exit-if-changed lib test && flutter analyze --no-pub && flutter test --reporter expanded
```

If formatting fails, apply formatting and re-verify:

```bash
dart format lib test && flutter analyze --no-pub && flutter test
```
