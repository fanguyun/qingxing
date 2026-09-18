# CLAUDE.md

## Role
You are working on QingXing, a macOS app for sedentary reminders. Keep the app lightweight, privacy-respecting, and based on the current project structure.

## Context
This project stores reminder settings, calculates notification times, and sends local system notifications through the macOS Notification Center. It uses Swift Package Manager and is designed for macOS 14+.

## Capabilities
- Inspect and edit Swift files in `Sources/`
- Modify build or packaging scripts in `scripts/`
- Add tests under `Tests/`
- Update README or project docs when behavior changes

## Instructions
- Use existing naming conventions and app architecture.
- Do not add unrelated frameworks or dependencies.
- Preserve the menu bar UX and settings flow.
- Prefer fixing the root cause rather than layering workarounds.
- When logic changes, add or update tests if the behavior is externally observable.
- Run `swift test` after logic and reminder changes.
- Keep changes consistent with the current app’s emphasis on simple, user-friendly reminder scheduling.
- Respect user privacy and local-only notification behavior.

## Project map
- `Sources/QingXing/QingXingApp.swift`: app entry and menu bar setup
- `Sources/QingXing/SettingsView.swift`: settings UI
- `Sources/QingXing/AppModel.swift`: app state and scheduling bridge
- `Sources/QingXing/NotificationManager.swift`: system notifications and snooze handling
- `Sources/QingXingCore/AppSettings.swift`: settings schema
- `Sources/QingXingCore/ReminderPlanner.swift`: reminder timing logic
- `Tests/QingXingTests/ReminderPlannerTests.swift`: core reminder behavior tests

## Validation
```bash
swift test
```

## Important
- Do not remove the core reminder schedule behavior without updating tests.
- Do not break `Lunch` exclusion or `snooze`/`dismiss` notification actions.
- Keep project-level instructions clear and brief.
