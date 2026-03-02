import SwiftUI
import UniformTypeIdentifiers

struct StorageSetupView: View {
  @EnvironmentObject var storage: StorageManager

  @State private var viewModel = StorageSetupVM()

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [Color(.systemGroupedBackground), Color(.secondarySystemGroupedBackground)],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      VStack(spacing: 24) {
        header

        if let url = storage.fileURL {
          LogWorkspaceView(filename: url.lastPathComponent)
        } else {
          EmptyStateView {
            viewModel.showExporter = true
          }
        }

        if let error = storage.errorMessage {
          Text(error)
            .font(.caption)
            .foregroundStyle(.red)
            .padding(.horizontal)
        }
      }
      .padding(.top, 8)
    }
    .fileExporter(
      isPresented: $viewModel.showExporter,
      document: viewModel.document,
      contentType: .commaSeparatedText,
      defaultFilename: "RideshareLog"
    ) { result in
      viewModel.handleExporterResult(result, storageManager: storage)
    }
  }

  private var header: some View {
    VStack(spacing: 8) {
      Image(systemName: "car.circle.fill")
        .resizable()
        .scaledToFit()
        .frame(width: 64, height: 64)
        .foregroundStyle(
          LinearGradient(
            colors: [.blue, .cyan],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )

      Text("GigLog")
        .font(.largeTitle)
        .fontWeight(.bold)
    }
    .padding(.top, 12)
  }
}

private struct EmptyStateView: View {
  var onCreateTapped: () -> Void

  var body: some View {
    VStack(spacing: 16) {
      VStack(alignment: .leading, spacing: 8) {
        Text("Create Your Log File")
          .font(.title3)
          .fontWeight(.semibold)

        Text("GigLog stores data in your own CSV file. Pick a location in Files (iCloud or local) to get started.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      VStack(alignment: .leading, spacing: 6) {
        Label("Choose location in Files app", systemImage: "folder")
        Label("GigLog creates `RideshareLog.csv`", systemImage: "doc.text")
        Label("Your data remains private and portable", systemImage: "lock.shield")
      }
      .font(.footnote)
      .foregroundStyle(.secondary)
      .frame(maxWidth: .infinity, alignment: .leading)

      Button(action: onCreateTapped) {
        Label("Create Log File", systemImage: "doc.badge.plus")
          .font(.headline)
          .frame(maxWidth: .infinity)
          .padding()
          .background(
            LinearGradient(
              colors: [.blue, .indigo],
              startPoint: .leading,
              endPoint: .trailing
            )
          )
          .foregroundStyle(.white)
          .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
      }
    }
    .padding(18)
    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    .padding(.horizontal, 20)
  }
}

#Preview {
  StorageSetupView()
    .environmentObject(StorageManager())
}
