import SwiftUI
import UniformTypeIdentifiers

// Structs are value types, so they are implicitly 'Sendable'
struct CSVDocument: FileDocument {
  // 1. Tell iOS this handles comma-separated text
  static var readableContentTypes: [UTType] { [.commaSeparatedText] }
  
  var text: String
  
  // 2. Initialize with default text (The CSV Headers)
  init(initialText: String = LogEntry.csvHeader + "\n") {
    self.text = initialText
  }
  
  // 3. Read from an existing file
  init(configuration: ReadConfiguration) throws {
    if let data = configuration.file.regularFileContents {
      text = String(decoding: data, as: UTF8.self)
    } else {
      text = ""
    }
  }
  
  // 4. Prepare data to save to disk
  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    let data = text.data(using: .utf8) ?? Data()
    return FileWrapper(regularFileWithContents: data)
  }
}
