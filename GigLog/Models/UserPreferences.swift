import Foundation

enum MileageUnit: String, CaseIterable, Identifiable {
  case miles = "miles"
  case kilometers = "kilometers"

  var id: Self { self }

  var title: String {
    switch self {
    case .miles:
      return "Miles"
    case .kilometers:
      return "Kilometers"
    }
  }

  var shortLabel: String {
    switch self {
    case .miles:
      return "mi"
    case .kilometers:
      return "km"
    }
  }

  var odometerLabel: String {
    "Odometer (\(shortLabel))"
  }
}

enum CurrencyOption: String, CaseIterable, Identifiable {
  case usd = "USD"
  case eur = "EUR"
  case gbp = "GBP"
  case cad = "CAD"
  case inr = "INR"

  var id: Self { self }

  var title: String {
    switch self {
    case .usd:
      return "US Dollar (USD)"
    case .eur:
      return "Euro (EUR)"
    case .gbp:
      return "British Pound (GBP)"
    case .cad:
      return "Canadian Dollar (CAD)"
    case .inr:
      return "Indian Rupee (INR)"
    }
  }
}
