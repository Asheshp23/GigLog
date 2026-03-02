import Foundation
import Observation

enum TripPlatform: String, CaseIterable, Identifiable {
  case uber = "Uber"
  case lyft = "Lyft"
  case hopp = "Hopp"
  case other = "Other"

  var id: Self { self }
}

enum ExpenseCategory: String, CaseIterable, Identifiable {
  case gas = "Gas"
  case oilChange = "Oil Change"
  case tireChange = "Tire Change"
  case maintenance = "Maintenance"
  case accessory = "Accessory"
  case carWash = "Car Wash"
  case other = "Other"

  var id: Self { self }
}

enum LogEntryValidationError: LocalizedError {
  case missingTripPlatformOtherName
  case invalidStartOdometer
  case invalidEndOdometer
  case endBeforeStart
  case missingExpenseCategoryOtherName
  case invalidCost

  var errorDescription: String? {
    switch self {
    case .missingTripPlatformOtherName:
      return "Enter the app name when platform is Other."
    case .invalidStartOdometer:
      return "Enter a valid start odometer."
    case .invalidEndOdometer:
      return "Enter a valid end odometer."
    case .endBeforeStart:
      return "End odometer must be greater than or equal to start odometer."
    case .missingExpenseCategoryOtherName:
      return "Enter the expense type when category is Other."
    case .invalidCost:
      return "Enter a valid expense amount."
    }
  }
}

@MainActor
@Observable
final class LogEntryFormVM {
  var mileageDate = Date()
  var tripPlatform: TripPlatform = .uber
  var otherTripPlatformName = ""
  var startOdometer = ""
  var endOdometer = ""
  var mileageStartNotes = ""
  var mileageEndNotes = ""

  var expenseDate = Date()
  var expenseCategory: ExpenseCategory = .gas
  var otherExpenseCategoryName = ""
  var expenseCost = ""
  var expenseNotes = ""

  var errorMessage: String?

  func makeTripDraft() throws -> PendingTripDraft {
    guard let startValue = Double(startOdometer), startValue >= 0 else {
      throw LogEntryValidationError.invalidStartOdometer
    }

    return PendingTripDraft(
      date: mileageDate,
      platformName: try resolvedTripPlatformName(),
      startOdometer: startValue,
      startNotes: mileageStartNotes.trimmingCharacters(in: .whitespacesAndNewlines)
    )
  }

  func makeTripEntry(from draft: PendingTripDraft) throws -> LogEntry {
    guard let endValue = Double(endOdometer), endValue >= 0 else {
      throw LogEntryValidationError.invalidEndOdometer
    }
    guard endValue >= draft.startOdometer else {
      throw LogEntryValidationError.endBeforeStart
    }

    let endNotes = mileageEndNotes.trimmingCharacters(in: .whitespacesAndNewlines)
    let mergedNotes = mergeNotes(startNotes: draft.startNotes, endNotes: endNotes)

    return LogEntry(
      date: draft.date,
      kind: .trip,
      details: formattedDetails(
        primaryLabel: "App",
        primaryValue: draft.platformName,
        notes: mergedNotes
      ),
      startOdometer: draft.startOdometer,
      endOdometer: endValue,
      total: endValue - draft.startOdometer,
      cost: nil
    )
  }

  func makeExpenseEntry() throws -> LogEntry {
    guard let costValue = Double(expenseCost), costValue >= 0 else {
      throw LogEntryValidationError.invalidCost
    }

    return LogEntry(
      date: expenseDate,
      kind: .expense,
      details: formattedDetails(
        primaryLabel: "Category",
        primaryValue: try resolvedExpenseCategoryName(),
        notes: expenseNotes.trimmingCharacters(in: .whitespacesAndNewlines)
      ),
      startOdometer: nil,
      endOdometer: nil,
      total: nil,
      cost: costValue
    )
  }

  func clearStartStepFieldsAfterSave() {
    startOdometer = ""
    mileageStartNotes = ""
    errorMessage = nil
  }

  func clearEndStepFieldsAfterSave() {
    endOdometer = ""
    mileageEndNotes = ""
    errorMessage = nil
  }

  func clearExpenseFieldsAfterSave() {
    otherExpenseCategoryName = ""
    expenseCost = ""
    expenseNotes = ""
    errorMessage = nil
  }

  private func resolvedTripPlatformName() throws -> String {
    if tripPlatform == .other {
      let value = otherTripPlatformName.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !value.isEmpty else {
        throw LogEntryValidationError.missingTripPlatformOtherName
      }
      return value
    }

    return tripPlatform.rawValue
  }

  private func resolvedExpenseCategoryName() throws -> String {
    if expenseCategory == .other {
      let value = otherExpenseCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !value.isEmpty else {
        throw LogEntryValidationError.missingExpenseCategoryOtherName
      }
      return value
    }

    return expenseCategory.rawValue
  }

  private func mergeNotes(startNotes: String, endNotes: String) -> String {
    if startNotes.isEmpty { return endNotes }
    if endNotes.isEmpty { return startNotes }
    return "Start: \(startNotes) | End: \(endNotes)"
  }

  private func formattedDetails(primaryLabel: String, primaryValue: String, notes: String) -> String {
    if notes.isEmpty {
      return "\(primaryLabel): \(primaryValue)"
    }

    return "\(primaryLabel): \(primaryValue) | Notes: \(notes)"
  }
}
