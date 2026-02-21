import SwiftUI
import UniformTypeIdentifiers

struct StorageSetupView: View {
    // 1. Access the Global Storage Manager (Passed from ContentView)
    @EnvironmentObject var storage: StorageManager
    
    @State private var viewModel = StorageSetupVM()
    
    var body: some View {
        VStack(spacing: 30) {
            
            // Header
            VStack(spacing: 10) {
                Image(systemName: "car.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.blue)
                
                Text("GigLog")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            .padding(.top, 50)
            
            Spacer()
            
            // STATE SWITCHING
            // We check the Global Storage Manager to see if we have a file
            if let url = storage.fileURL {
                SuccessView(filename: url.lastPathComponent)
            } else {
                EmptyStateView {
                    viewModel.showExporter = true
                }
            }
            
            Spacer()
            
            // Global Error Handling
            if let error = storage.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding()
            }
        }
        // FILE EXPORTER MODIFIER
        .fileExporter(
            isPresented: $viewModel.showExporter,
            document: viewModel.document,
            contentType: .commaSeparatedText,
            defaultFilename: "RideshareLog"
        ) { result in
            // Pass the result to VM, and inject the Storage Manager so it can save
            viewModel.handleExporterResult(result, storageManager: storage)
        }
    }
}

// MARK: - Subviews (Keeps the main body clean)

private struct SuccessView: View {
    let filename: String
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            
            Text("Log File Active")
                .font(.headline)
            
            Text(filename)
                .font(.caption)
                .padding(10)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text("Your data is being saved to this file.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

private struct EmptyStateView: View {
    var onCreateTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            Text("No Log File Found")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("Create a file in your iPhone's Files app (iCloud or Local) to start tracking.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: onCreateTapped) {
                Label("Create Log File", systemImage: "doc.badge.plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)
        }
    }
}

#Preview {
    // Mock the environment object for preview
    StorageSetupView()
        .environmentObject(StorageManager())
}
