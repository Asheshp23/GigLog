import Foundation

enum LogEntryKind: String, CaseIterable, Identifiable {
  case trip = "Trip"
  case expense = "Expense"

  var id: Self { self }
}

struct LogEntry: Identifiable {
  let id = UUID()
  let date: Date
  let kind: LogEntryKind
  let details: String
  let startOdometer: Double?
  let endOdometer: Double?
  let total: Double?
  let cost: Double?

  static let csvHeader = "Date,Type,Details,Start_Odo,End_Odo,Total,Cost"

  private static let csvDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone.current
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }()

  var csvLine: String {
    let columns: [String] = [
      Self.csvDateFormatter.string(from: date),
      kind.rawValue,
      details,
      Self.format(startOdometer),
      Self.format(endOdometer),
      Self.format(total),
      Self.format(cost)
    ]

    return columns.map(Self.escapeCSV).joined(separator: ",")
  }

  init(
    date: Date,
    kind: LogEntryKind,
    details: String,
    startOdometer: Double?,
    endOdometer: Double?,
    total: Double?,
    cost: Double?
  ) {
    self.date = date
    self.kind = kind
    self.details = details
    self.startOdometer = startOdometer
    self.endOdometer = endOdometer
    self.total = total
    self.cost = cost
  }

  init?(csvLine: String) {
    let columns = Self.parseCSVLine(csvLine)
    guard columns.count == 7 else { return nil }

    guard let date = Self.csvDateFormatter.date(from: columns[0]) else { return nil }
    guard let kind = LogEntryKind(rawValue: columns[1]) else { return nil }

    self.date = date
    self.kind = kind
    self.details = columns[2]
    self.startOdometer = Self.parseDouble(columns[3])
    self.endOdometer = Self.parseDouble(columns[4])
    self.total = Self.parseDouble(columns[5])
    self.cost = Self.parseDouble(columns[6])
  }

  private static func escapeCSV(_ value: String) -> String {
    if value.contains(",") || value.contains("\"") || value.contains("\n") {
      return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    return value
  }

  private static func format(_ value: Double?) -> String {
    guard let value else { return "" }

    // Keep values concise while preserving precision for fractional mileage.
    return String(format: "%.2f", value)
  }

  private static func parseDouble(_ value: String) -> Double? {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    return Double(trimmed)
  }

  private static func parseCSVLine(_ line: String) -> [String] {
    var columns: [String] = []
    var current = ""
    var inQuotes = false
    var iterator = line.makeIterator()

    while let char = iterator.next() {
      if char == "\"" {
        if inQuotes {
          if let next = iterator.next() {
            if next == "\"" {
              current.append("\"")
            } else {
              inQuotes = false
              if next == "," {
                columns.append(current)
                current = ""
              } else {
                current.append(next)
              }
            }
          } else {
            inQuotes = false
          }
        } else {
          inQuotes = true
        }
      } else if char == "," && !inQuotes {
        columns.append(current)
        current = ""
      } else {
        current.append(char)
      }
    }

    columns.append(current)
    return columns
  }
}

struct PendingTripDraft: Codable {
  let date: Date
  let platformName: String
  let startOdometer: Double
  let startNotes: String
}
