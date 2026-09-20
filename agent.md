# agent.md

This repository is a Swift macOS app for sedentary reminders. Follow the project conventions in this file when making changes.

## Project goals

- Remind the user to stand up and move during configured active hours
- Support custom intervals, custom time points, and lunch exclusion
- Preserve local settings and allow auto-launch on login

## Workflow

- Keep edits small and relevant.
- Prefer editing the existing Swift files over adding new abstractions.
- Validate with `swift test` when reminder behavior or scheduling changes.

## Important files

- `Package.swift`
- `Sources/QingXing/QingXingApp.swift`
- `Sources/QingXingCore/ReminderPlanner.swift`
- `Sources/QingXing/NotificationManager.swift`
- `Tests/QingXingTests/ReminderPlannerTests.swift`

## Commands

```bash
swift build
swift test
./scripts/build.sh
./scripts/package.sh
```
