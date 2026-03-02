# GigLog Project Status

## Updated
- 2026-03-02

## Completed
- Bootstrapped iOS SwiftUI project and app entrypoint.
- Implemented storage setup screen with file exporter flow.
- Added security-scoped bookmark save/restore in `StorageManager`.
- Added `CSVDocument` with default CSV header.
- Implemented core logging vertical slice:
  - `LogEntry` domain model and CSV serialization/parsing.
  - `LogEntryFormVM` validation for trip and expense entries.
  - `StorageManager.append(_:)` to persist entries.
  - `StorageManager.readEntries(limit:)` for recent history.
  - `LogWorkspaceView` with save form + recent entries list.
  - Wired active-file state from setup screen to logging workspace.
- Improved log form UX:
  - Trip app selector: Uber, Lyft, Hopp, Other (manual name).
  - Expense type selector: Gas, Oil Change, Tire Change, Maintenance, Accessory, Car Wash, Other (manual name).
  - Optional notes fields for both trip and expense.
  - Structured details persisted to CSV while preserving existing schema.
- Added dashboard + step-based mileage flow:
  - Dashboard cards for `Mileage` and `Expense`.
  - Mileage supports Start Shift first (without end odometer), then End Shift later.
  - Start step is persisted locally as pending draft and survives app restarts.
  - End step completes trip and writes final CSV row.
- Added configurable units + currency and refined UI:
  - Preferences sheet for mileage unit (`Miles`/`Kilometers`) and currency (`USD`, `EUR`, `GBP`, `CAD`, `INR`).
  - Dashboard summary and history now render with selected unit/currency formatting.
  - Upgraded top-level visual design (hero header, action cards, cleaner grouped sections).
- Performed UX polish pass across onboarding and workspace:
  - Added clearer hierarchy, stronger card styling, and improved spacing rhythm.
  - Added animated section transitions and mileage step indicators.
  - Added pending-shift banner with quick jump to end-step flow.
  - Improved recent-entry list readability with icons and metadata emphasis.
- Completed full app UI consistency pass:
  - Unified gradients, cards, spacing, and typography across onboarding and workspace.
  - Refined dashboard structure with clearer action hierarchy and totals card.
  - Preserved step-based mileage flow and preferences while removing unstable experimental chart/earnings UI paths.
  - Restored strict CSV schema compatibility (`Date,Type,Details,Start_Odo,End_Odo,Total,Cost`).

## In Progress
- End-to-end validation on simulator/device (manual QA).

## Next Up
- Add "shift start/end" reminders (manual trigger + local notifications).
- Add setup guide for iOS Shortcuts app-open/app-close automations (Uber/Lyft/Hopp -> open GigLog).
- Add edit/delete entry support.
- Add totals dashboard (daily/weekly mileage and expenses).
- Add CSV import resiliency for malformed rows.
- Add unit tests for validation and CSV parsing.

## Notes
- Data remains local in user-selected CSV file.
- App stack: SwiftUI + Swift 6 + MVVM.
