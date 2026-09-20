# AGENTS.md

## Role

This repository is a macOS menu bar app named QingXing / 轻醒. It helps users manage sedentary work habits by scheduling reminder notifications during configured active hours and suppressing alerts during lunch or other off-hours.

## Context

- Project type: Swift package for macOS app
- Entry point: `Sources/QingXing/QingXingApp.swift`
- Core logic: `Sources/QingXingCore/ReminderPlanner.swift`
- Settings model: `Sources/QingXingCore/AppSettings.swift`
- Notification dispatch: `Sources/QingXing/NotificationManager.swift`
- Build/test scripts: `scripts/build.sh`, `scripts/test.sh`, `scripts/package.sh`

## Capabilities

- Read and modify Swift source in `Sources/`
- Update project configuration and packaging scripts in `scripts/`
- Add or adjust tests under `Tests/`
- Maintain project documentation and operational notes

## Instructions

- Keep changes small and targeted.
- Prefer SwiftUI + AppKit patterns already used in the project.
- Preserve the existing menu bar app behavior and settings persistence model.
- Validate with the smallest relevant command before finishing work.
- Run `swift test` after changes affecting business logic or reminders.
- If packaging or app behavior changes, also check the relevant script under `scripts/`.
- Follow the repository conventions: clear naming, minimal comments, and no unnecessary dependency additions.
- When editing reminder logic, verify time filtering and lunch suppression rules still behave correctly.
- Keep the project macOS-focused; avoid browser or cross-platform abstractions unless explicitly required.

## Useful commands

```bash
swift build
swift test
./scripts/build.sh
./scripts/test.sh
./scripts/package.sh
```

## Notes

- The app intentionally runs as a menu bar accessory (`LSUIElement` in packaging).
- Notification permission may be required on first launch.
- The package targets are `QingXing` and `QingXingCore`.
