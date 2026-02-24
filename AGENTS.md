# AGENTS.md

## Project Context
- App name: GigLog
- Platform: iOS
- Primary stack: SwiftUI, Swift 6
- Architecture style: MVVM
- Persistence model: user-owned CSV file with security-scoped bookmark access

## Execution Rules
- Prefer SwiftUI-native patterns and small composable views.
- Keep business logic in view models/services, not in view body blocks.
- Preserve existing CSV schema unless explicitly changed:
  - `Date,Type,Details,Start_Odo,End_Odo,Total,Cost`
- Keep date output stable (`yyyy-MM-dd`) for spreadsheet compatibility.
- Keep data local-first; do not add network dependencies unless requested.
- Use `@MainActor` for UI-facing observable state.
- Validate user input before writing CSV rows.

## Code Style
- Use clear, predictable naming (`LogEntry`, `StorageManager`, `...VM`).
- Keep files focused by responsibility (Models, ViewModels, Services, Views).
- Add comments only when logic is non-obvious.
- Avoid introducing third-party dependencies for core flows.

## Workflow Rules
- Update `PROJECT_STATUS.md` whenever a meaningful feature is completed.
- Prefer incremental vertical slices (model -> service -> UI -> validation).
- If changing storage format or schema, document migration impact in `PROJECT_STATUS.md`.

## Current Priorities
- Reliable trip/expense capture.
- Recent entries visibility.
- Data integrity in CSV writes and reads.
