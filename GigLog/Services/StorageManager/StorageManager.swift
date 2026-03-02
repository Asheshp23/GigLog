import Foundation
internal import Combine

@MainActor // <--- Swift 6 Requirement: Isolates this class to the Main Thread
class StorageManager: ObservableObject {
  @Published var fileURL: URL?
  @Published var errorMessage: String?
  @Published var pendingTripDraft: PendingTripDraft?
  
  private let bookmarkKey = "LogFileBookmark"
  private let pendingTripKey = "PendingTripDraft"
  
  init() {
    // Attempt to restore access immediately upon app launch
    restoreAccess()
    restorePendingTripDraft()
  }

  // MARK: - Entry Persistence
  func append(_ entry: LogEntry) {
    guard let fileURL else {
      errorMessage = "No log file selected."
      return
    }

    guard fileURL.startAccessingSecurityScopedResource() else {
      errorMessage = "Could not access the selected log file."
      return
    }
    defer { fileURL.stopAccessingSecurityScopedResource() }

    do {
      var line = entry.csvLine
      if !line.hasSuffix("\n") {
        line += "\n"
      }

      let handle = try FileHandle(forWritingTo: fileURL)
      defer { try? handle.close() }

      try handle.seekToEnd()
      if let data = line.data(using: .utf8) {
        try handle.write(contentsOf: data)
        errorMessage = nil
      }
    } catch {
      errorMessage = "Failed to save entry: \(error.localizedDescription)"
    }
  }

  func readEntries(limit: Int) -> [LogEntry] {
    guard let fileURL else { return [] }

    guard fileURL.startAccessingSecurityScopedResource() else {
      errorMessage = "Could not access the selected log file."
      return []
    }
    defer { fileURL.stopAccessingSecurityScopedResource() }

    do {
      let data = try Data(contentsOf: fileURL)
      let content = String(decoding: data, as: UTF8.self)
      let lines = content.split(whereSeparator: \.isNewline).map(String.init)
      let entries = lines
        .dropFirst()
        .compactMap(LogEntry.init(csvLine:))

      errorMessage = nil
      return Array(entries.suffix(limit).reversed())
    } catch {
      errorMessage = "Failed to read entries: \(error.localizedDescription)"
      return []
    }
  }

  func savePendingTripDraft(_ draft: PendingTripDraft) {
    do {
      let encoded = try JSONEncoder().encode(draft)
      UserDefaults.standard.set(encoded, forKey: pendingTripKey)
      pendingTripDraft = draft
      errorMessage = nil
    } catch {
      errorMessage = "Failed to save start odometer: \(error.localizedDescription)"
    }
  }

  func clearPendingTripDraft() {
    UserDefaults.standard.removeObject(forKey: pendingTripKey)
    pendingTripDraft = nil
  }
  
  // MARK: - Save Permission
  func saveBookmark(for url: URL) {
    do {
      // 1. Tell the security scope we want to use this resource
      guard url.startAccessingSecurityScopedResource() else {
        errorMessage = "Could not access the security scoped resource."
        return
      }
      
      // 2. Create the bookmark data (The permanent permission slip)
      let bookmarkData = try url.bookmarkData(
        options: .minimalBookmark,
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )
      
      // 3. Save to UserDefaults
      UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)

      ensureCSVHeaderExists(at: url)

      // 4. Update State
      self.fileURL = url
      print("✅ Permission saved for: \(url.lastPathComponent)")
      
      // 5. Cleanup
      url.stopAccessingSecurityScopedResource()
      
    } catch {
      errorMessage = "Failed to save bookmark: \(error.localizedDescription)"
      print("❌ \(errorMessage ?? "")")
    }
  }
  
  // MARK: - Restore Permission
  func restoreAccess() {
    guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else { return }
    
    var isStale = false
    
    do {
      // Resolve the URL from the bookmark data
      let url = try URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isStale)
      
      if isStale {
        print("⚠️ Bookmark is stale. User needs to re-select file.")
        // In a full app, you might prompt the user here.
        return
      }
      
      if url.startAccessingSecurityScopedResource() {
        self.fileURL = url
        print("✅ Access restored to: \(url.lastPathComponent)")
        
        // We stop accessing here because we only need to verify we CAN access it.
        // We will open it again when we actually write data later.
        url.stopAccessingSecurityScopedResource()
      }
      
    } catch {
      print("❌ Failed to restore access: \(error.localizedDescription)")
    }
  }

  private func ensureCSVHeaderExists(at url: URL) {
    do {
      let existingData = try? Data(contentsOf: url)
      let existingText = existingData.map { String(decoding: $0, as: UTF8.self) } ?? ""

      if existingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        let header = LogEntry.csvHeader + "\n"
        try header.write(to: url, atomically: true, encoding: .utf8)
      }
    } catch {
      errorMessage = "Failed to initialize CSV header: \(error.localizedDescription)"
    }
  }

  private func restorePendingTripDraft() {
    guard let data = UserDefaults.standard.data(forKey: pendingTripKey) else { return }

    do {
      pendingTripDraft = try JSONDecoder().decode(PendingTripDraft.self, from: data)
    } catch {
      UserDefaults.standard.removeObject(forKey: pendingTripKey)
      pendingTripDraft = nil
    }
  }
}
