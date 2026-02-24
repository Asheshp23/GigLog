import SwiftUI

private enum WorkspaceSection {
  case dashboard
  case mileage
  case expense
}

struct LogWorkspaceView: View {
  @EnvironmentObject var storage: StorageManager

  let filename: String

  @State private var formVM = LogEntryFormVM()
  @State private var recentEntries: [LogEntry] = []
  @State private var section: WorkspaceSection = .dashboard
  @State private var showPreferences = false

  @AppStorage("preferredMileageUnit") private var preferredMileageUnitRaw = MileageUnit.miles.rawValue
  @AppStorage("preferredCurrencyCode") private var preferredCurrencyCode = CurrencyOption.usd.rawValue

  private var preferredMileageUnit: MileageUnit {
    MileageUnit(rawValue: preferredMileageUnitRaw) ?? .miles
  }

  private var selectedCurrency: CurrencyOption {
    CurrencyOption(rawValue: preferredCurrencyCode) ?? .usd
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        header
        quickActions

        if let draft = storage.pendingTripDraft {
          pendingShiftBanner(draft: draft)
        }

        switch section {
        case .dashboard:
          EmptyView()
        case .mileage:
          mileageSection
            .transition(.move(edge: .bottom).combined(with: .opacity))
        case .expense:
          expenseSection
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }

        if let error = formVM.errorMessage {
          Text(error)
            .font(.footnote)
            .foregroundStyle(.red)
            .padding(.horizontal, 4)
        }

        recentEntriesSection
      }
      .padding(20)
    }
    .background(Color(.systemGroupedBackground))
    .onAppear(perform: loadEntries)
    .animation(.snappy(duration: 0.25), value: section)
    .sheet(isPresented: $showPreferences) {
      preferencesSheet
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("GigLog")
            .font(.system(.title2, design: .rounded, weight: .bold))
          Text("Shift-ready trip and expense tracker")
            .font(.footnote)
            .foregroundStyle(.white.opacity(0.9))
        }

        Spacer()

        Button {
          showPreferences = true
        } label: {
          Image(systemName: "slider.horizontal.3")
            .font(.headline)
            .frame(width: 40, height: 40)
            .background(.white.opacity(0.24), in: Circle())
        }
        .buttonStyle(.plain)
      }

      HStack(spacing: 8) {
        preferenceChip(icon: "ruler", text: preferredMileageUnit.title)
        preferenceChip(icon: "dollarsign.circle", text: selectedCurrency.rawValue)
      }

      Text(filename)
        .font(.caption)
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.white.opacity(0.2), in: Capsule())
    }
    .foregroundStyle(.white)
    .padding(16)
    .background(
      LinearGradient(
        colors: [Color.blue, Color.indigo],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    )
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    .shadow(color: .blue.opacity(0.18), radius: 14, y: 10)
  }

  private func preferenceChip(icon: String, text: String) -> some View {
    HStack(spacing: 6) {
      Image(systemName: icon)
      Text(text)
    }
    .font(.caption)
    .padding(.horizontal, 10)
    .padding(.vertical, 5)
    .background(.white.opacity(0.2), in: Capsule())
  }

  private var preferencesSheet: some View {
    NavigationStack {
      Form {
        Section("Mileage Unit") {
          Picker("Unit", selection: $preferredMileageUnitRaw) {
            ForEach(MileageUnit.allCases) { unit in
              Text(unit.title).tag(unit.rawValue)
            }
          }
          .pickerStyle(.inline)
        }

        Section("Currency") {
          Picker("Currency", selection: $preferredCurrencyCode) {
            ForEach(CurrencyOption.allCases) { currency in
              Text(currency.title).tag(currency.rawValue)
            }
          }
          .pickerStyle(.inline)
        }
      }
      .navigationTitle("Preferences")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            showPreferences = false
          }
        }
      }
    }
  }

  private var quickActions: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Quick Actions")
        .font(.title3)
        .fontWeight(.semibold)

      HStack(spacing: 12) {
        actionCard(
          title: "Mileage",
          subtitle: storage.pendingTripDraft == nil ? "Start shift" : "Finish shift",
          icon: "car.fill",
          accent: .blue
        ) {
          formVM.errorMessage = nil
          withAnimation { section = .mileage }
        }

        actionCard(
          title: "Expense",
          subtitle: "Fuel, service, wash",
          icon: "creditcard.fill",
          accent: .orange
        ) {
          formVM.errorMessage = nil
          withAnimation { section = .expense }
        }
      }

      summaryStrip
    }
  }

  private func actionCard(
    title: String,
    subtitle: String,
    icon: String,
    accent: Color,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 10) {
        HStack {
          Image(systemName: icon)
            .font(.headline)
            .foregroundStyle(accent)
            .frame(width: 34, height: 34)
            .background(accent.opacity(0.14), in: Circle())

          Spacer()

          Image(systemName: "arrow.right")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Text(title)
          .font(.headline)
          .foregroundStyle(.primary)

        Text(subtitle)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
      .padding(14)
      .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    .buttonStyle(.plain)
  }

  private var summaryStrip: some View {
    let mileage = recentEntries.filter { $0.kind == .trip }.compactMap(\.total).reduce(0, +)
    let expense = recentEntries.filter { $0.kind == .expense }.compactMap(\.cost).reduce(0, +)

    return HStack {
      VStack(alignment: .leading, spacing: 2) {
        Text("Total Mileage")
          .font(.caption)
          .foregroundStyle(.secondary)
        Text(String(format: "%.2f %@", mileage, preferredMileageUnit.shortLabel))
          .font(.headline)
      }

      Spacer()

      VStack(alignment: .trailing, spacing: 2) {
        Text("Total Expense")
          .font(.caption)
          .foregroundStyle(.secondary)
        Text(currencyString(expense))
          .font(.headline)
      }
    }
    .padding(12)
    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
  }

  private func pendingShiftBanner(draft: PendingTripDraft) -> some View {
    HStack(alignment: .top, spacing: 10) {
      Image(systemName: "clock.badge.fill")
        .foregroundStyle(.blue)

      VStack(alignment: .leading, spacing: 3) {
        Text("Shift In Progress")
          .font(.subheadline)
          .fontWeight(.semibold)

        Text("\(draft.platformName) started at \(String(format: "%.2f", draft.startOdometer)) \(preferredMileageUnit.shortLabel)")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()

      Button("End") {
        withAnimation { section = .mileage }
      }
      .font(.caption.weight(.semibold))
    }
    .padding(12)
    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
  }

  private var mileageSection: some View {
    VStack(alignment: .leading, spacing: 14) {
      sectionTitle("Mileage Log")

      if let draft = storage.pendingTripDraft {
        mileageStepHeader(currentStep: 2)
        endMileageStep(draft: draft)
      } else {
        mileageStepHeader(currentStep: 1)
        startMileageStep
      }

      backButton
    }
  }

  private func mileageStepHeader(currentStep: Int) -> some View {
    HStack(spacing: 10) {
      stepBubble("1", isActive: currentStep == 1)
      Rectangle()
        .fill(Color.secondary.opacity(0.3))
        .frame(height: 2)
      stepBubble("2", isActive: currentStep == 2)
      Spacer()
      Text(currentStep == 1 ? "Start Shift" : "End Shift")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }

  private func stepBubble(_ title: String, isActive: Bool) -> some View {
    Text(title)
      .font(.caption.weight(.bold))
      .frame(width: 24, height: 24)
      .foregroundStyle(isActive ? .white : .secondary)
      .background(isActive ? Color.blue : Color.secondary.opacity(0.15), in: Circle())
  }

  private var startMileageStep: some View {
    VStack(alignment: .leading, spacing: 12) {
      DatePicker("Date", selection: $formVM.mileageDate, displayedComponents: .date)

      Picker("Rideshare App", selection: $formVM.tripPlatform) {
        ForEach(TripPlatform.allCases) { platform in
          Text(platform.rawValue).tag(platform)
        }
      }
      .pickerStyle(.menu)

      if formVM.tripPlatform == .other {
        TextField("Enter app name", text: $formVM.otherTripPlatformName)
          .textFieldStyle(.roundedBorder)
      }

      TextField("Start \(preferredMileageUnit.odometerLabel)", text: $formVM.startOdometer)
        .keyboardType(.decimalPad)
        .textFieldStyle(.roundedBorder)

      TextField("Start notes (optional)", text: $formVM.mileageStartNotes)
        .textFieldStyle(.roundedBorder)

      primaryButton(title: "Save Start Odometer", icon: "flag.fill", color: .blue, action: saveStartOdometer)
    }
    .cardStyle()
  }

  private func endMileageStep(draft: PendingTripDraft) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Started with \(draft.platformName) at \(String(format: "%.2f", draft.startOdometer)) \(preferredMileageUnit.shortLabel)")
        .font(.footnote)
        .foregroundStyle(.secondary)

      TextField("End \(preferredMileageUnit.odometerLabel)", text: $formVM.endOdometer)
        .keyboardType(.decimalPad)
        .textFieldStyle(.roundedBorder)

      TextField("End notes (optional)", text: $formVM.mileageEndNotes)
        .textFieldStyle(.roundedBorder)

      primaryButton(title: "Save Mileage Entry", icon: "checkmark.circle.fill", color: .green) {
        saveCompletedMileage(from: draft)
      }

      Button(role: .destructive) {
        storage.clearPendingTripDraft()
      } label: {
        Text("Discard Start Step")
          .font(.footnote)
      }
    }
    .cardStyle()
  }

  private var expenseSection: some View {
    VStack(alignment: .leading, spacing: 14) {
      sectionTitle("Expense Log")

      VStack(alignment: .leading, spacing: 12) {
        DatePicker("Date", selection: $formVM.expenseDate, displayedComponents: .date)

        Picker("Expense Type", selection: $formVM.expenseCategory) {
          ForEach(ExpenseCategory.allCases) { category in
            Text(category.rawValue).tag(category)
          }
        }
        .pickerStyle(.menu)

        if formVM.expenseCategory == .other {
          TextField("Enter expense type", text: $formVM.otherExpenseCategoryName)
            .textFieldStyle(.roundedBorder)
        }

        TextField("Cost (\(selectedCurrency.rawValue))", text: $formVM.expenseCost)
          .keyboardType(.decimalPad)
          .textFieldStyle(.roundedBorder)

        TextField("Expense notes (optional)", text: $formVM.expenseNotes)
          .textFieldStyle(.roundedBorder)

        primaryButton(title: "Save Expense", icon: "plus.circle.fill", color: .orange, action: saveExpense)
      }
      .cardStyle()

      backButton
    }
  }

  private func primaryButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Label(title, systemImage: icon)
        .font(.headline)
        .frame(maxWidth: .infinity)
        .padding()
        .background(color, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .foregroundStyle(.white)
    }
  }

  private var backButton: some View {
    Button {
      formVM.errorMessage = nil
      withAnimation { section = .dashboard }
    } label: {
      Label("Back to Dashboard", systemImage: "arrow.left")
        .font(.footnote)
    }
  }

  private var recentEntriesSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Recent Entries")
        .font(.headline)

      if recentEntries.isEmpty {
        VStack(spacing: 8) {
          Image(systemName: "tray")
            .foregroundStyle(.secondary)
          Text("No entries yet")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
      } else {
        ForEach(recentEntries) { entry in
          HStack(alignment: .top, spacing: 10) {
            Image(systemName: entry.kind == .trip ? "car.fill" : "wrench.and.screwdriver.fill")
              .foregroundStyle(entry.kind == .trip ? .blue : .orange)
              .font(.footnote)
              .frame(width: 24, height: 24)
              .background((entry.kind == .trip ? Color.blue : Color.orange).opacity(0.13), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
              HStack {
                Text(entry.kind.rawValue)
                  .font(.subheadline)
                  .fontWeight(.semibold)

                Spacer()

                Text(Self.displayDate(entry.date))
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }

              Text(entry.details)
                .font(.footnote)

              Text(summaryText(for: entry))
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
          .padding(10)
          .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
      }
    }
  }

  private func sectionTitle(_ text: String) -> some View {
    Text(text)
      .font(.title3)
      .fontWeight(.semibold)
  }

  private func saveStartOdometer() {
    do {
      let draft = try formVM.makeTripDraft()
      storage.savePendingTripDraft(draft)
      formVM.clearStartStepFieldsAfterSave()
      section = .dashboard
      loadEntries()
    } catch let validationError as LogEntryValidationError {
      formVM.errorMessage = validationError.errorDescription
    } catch {
      formVM.errorMessage = "Unable to save start step: \(error.localizedDescription)"
    }
  }

  private func saveCompletedMileage(from draft: PendingTripDraft) {
    do {
      let entry = try formVM.makeTripEntry(from: draft)
      storage.append(entry)
      storage.clearPendingTripDraft()
      formVM.clearEndStepFieldsAfterSave()
      section = .dashboard
      loadEntries()
    } catch let validationError as LogEntryValidationError {
      formVM.errorMessage = validationError.errorDescription
    } catch {
      formVM.errorMessage = "Unable to save mileage entry: \(error.localizedDescription)"
    }
  }

  private func saveExpense() {
    do {
      let entry = try formVM.makeExpenseEntry()
      storage.append(entry)
      formVM.clearExpenseFieldsAfterSave()
      section = .dashboard
      loadEntries()
    } catch let validationError as LogEntryValidationError {
      formVM.errorMessage = validationError.errorDescription
    } catch {
      formVM.errorMessage = "Unable to save expense entry: \(error.localizedDescription)"
    }
  }

  private func loadEntries() {
    recentEntries = storage.readEntries(limit: 25)
  }

  private func summaryText(for entry: LogEntry) -> String {
    switch entry.kind {
    case .trip:
      let start = entry.startOdometer ?? 0
      let end = entry.endOdometer ?? 0
      let total = entry.total ?? max(0, end - start)
      return String(format: "%.2f -> %.2f (%.2f %@)", start, end, total, preferredMileageUnit.shortLabel)
    case .expense:
      return currencyString(entry.cost ?? 0)
    }
  }

  private func currencyString(_ amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = selectedCurrency.rawValue
    formatter.maximumFractionDigits = 2
    return formatter.string(from: NSNumber(value: amount)) ?? String(format: "%@ %.2f", selectedCurrency.rawValue, amount)
  }

  private static func displayDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: date)
  }
}

private extension View {
  func cardStyle() -> some View {
    self
      .padding(14)
      .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
  }
}

#Preview {
  LogWorkspaceView(filename: "RideshareLog.csv")
    .environmentObject(StorageManager())
}
