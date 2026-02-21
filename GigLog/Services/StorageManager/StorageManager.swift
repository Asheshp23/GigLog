import Foundation
internal import Combine

@MainActor // <--- Swift 6 Requirement: Isolates this class to the Main Thread
class StorageManager: ObservableObject {
  @Published var fileURL: URL?
  @Published var errorMessage: String?
  
  private let bookmarkKey = "LogFileBookmark"
  
  init() {
    // Attempt to restore access immediately upon app launch
    restoreAccess()
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
}
