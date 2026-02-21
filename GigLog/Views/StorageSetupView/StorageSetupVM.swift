import Foundation

@MainActor
@Observable
class StorageSetupVM {
  var showExporter = false
  var document = CSVDocument()
  var error: String?
  
  // Logic to handle the result from the file picker
  func handleExporterResult(_ result: Result<URL, Error>, storageManager: StorageManager) {
    switch result {
    case .success(let url):
      // We delegate the "Saving" logic to the StorageManager
      storageManager.saveBookmark(for: url)
    case .failure(let error):
      self.error = "Export failed: \(error.localizedDescription)"
    }
  }
}
