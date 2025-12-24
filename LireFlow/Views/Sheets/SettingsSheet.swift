import SwiftUI
import SwiftData

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var folders: [Folder]
    @Query private var feeds: [Feed]
    @Query private var readingLists: [ReadingList]

    @StateObject private var exportService = ExportService()
    @StateObject private var importService = ImportService()

    @State private var selectedTab: SettingsTab = .backup
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var showingSuccessAlert = false
    @State private var successMessage = ""
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""

    enum SettingsTab: String, CaseIterable, Identifiable {
        case general = "General"
        case backup = "Backup & Import"
        case about = "About"

        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close")
            }
            .padding()

            Divider()

            // Tab picker
            Picker("", selection: $selectedTab) {
                ForEach(SettingsTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            // Tab content
            switch selectedTab {
            case .general:
                GeneralSettingsView()
            case .backup:
                BackupSettingsView(
                    exportService: exportService,
                    importService: importService,
                    modelContext: modelContext,
                    folders: folders,
                    feeds: feeds,
                    readingLists: readingLists,
                    isExporting: $isExporting,
                    isImporting: $isImporting,
                    showingSuccessAlert: $showingSuccessAlert,
                    successMessage: $successMessage,
                    showingErrorAlert: $showingErrorAlert,
                    errorMessage: $errorMessage
                )
            case .about:
                AboutSettingsView()
            }

            Spacer()
        }
        .frame(width: 650, height: 550)
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("OK") { showingSuccessAlert = false }
        } message: {
            Text(successMessage)
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { showingErrorAlert = false }
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - Backup Settings View

struct BackupSettingsView: View {
    @ObservedObject var exportService: ExportService
    @ObservedObject var importService: ImportService
    let modelContext: ModelContext

    let folders: [Folder]
    let feeds: [Feed]
    let readingLists: [ReadingList]

    @Binding var isExporting: Bool
    @Binding var isImporting: Bool
    @Binding var showingSuccessAlert: Bool
    @Binding var successMessage: String
    @Binding var showingErrorAlert: Bool
    @Binding var errorMessage: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Export Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Export Library")
                                .font(.headline)

                            Text("Save your feeds, folders, and reading lists to a file")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack(spacing: 12) {
                        Button {
                            Task { await exportJSON() }
                        } label: {
                            Label("Export to JSON", systemImage: "doc.text")
                        }
                        .disabled(isExporting || feeds.isEmpty)
                        .help("Export complete library backup (recommended)")

                        Button {
                            Task { await exportOPML() }
                        } label: {
                            Label("Export to OPML", systemImage: "doc.text")
                        }
                        .disabled(isExporting || feeds.isEmpty)
                        .help("Export feeds only (compatible with other RSS readers)")
                    }

                    if isExporting {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Exporting...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack(spacing: 16) {
                        Label("\(feeds.count)", systemImage: "newspaper")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .help("Feeds")

                        Label("\(folders.count)", systemImage: "folder")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .help("Folders")

                        Label("\(readingLists.count)", systemImage: "list.bullet")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .help("Reading Lists")
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // Import Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .font(.title2)
                            .foregroundStyle(.green)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Import Library")
                                .font(.headline)

                            Text("Restore feeds from a JSON or OPML file. Duplicates will be skipped.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack(spacing: 12) {
                        Button {
                            Task { await importJSON() }
                        } label: {
                            Label("Import from JSON", systemImage: "doc.text")
                        }
                        .disabled(isImporting)
                        .help("Import LireFlow backup file")

                        Button {
                            Task { await importOPML() }
                        } label: {
                            Label("Import from OPML", systemImage: "doc.text")
                        }
                        .disabled(isImporting)
                        .help("Import feeds from OPML file")
                    }

                    if isImporting {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Importing...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text("Note: Existing feeds with the same URL will not be duplicated.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 4)
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // Info Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)
                        Text("About Export Formats")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            VStack(alignment: .leading, spacing: 2) {
                                Text("JSON")
                                    .fontWeight(.medium)
                                Text("Complete backup including feeds, folders, and reading lists. Use this for full backups.")
                            }
                            .font(.caption)
                        }

                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            VStack(alignment: .leading, spacing: 2) {
                                Text("OPML")
                                    .fontWeight(.medium)
                                Text("Standard RSS format. Only exports feeds and folders. Use this to migrate to other RSS readers.")
                            }
                            .font(.caption)
                        }
                    }
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding()
        }
    }

    // MARK: - Export Actions

    private func exportJSON() async {
        isExporting = true
        defer { isExporting = false }

        do {
            let url = try await exportService.exportToJSON(
                folders: folders,
                feeds: feeds,
                readingLists: readingLists
            )
            successMessage = "Successfully exported to:\n\(url.lastPathComponent)"
            showingSuccessAlert = true
        } catch ExportService.ExportError.userCancelled {
            // Silent - user cancelled
        } catch {
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
    }

    private func exportOPML() async {
        isExporting = true
        defer { isExporting = false }

        do {
            let url = try await exportService.exportToOPML(
                folders: folders,
                feeds: feeds
            )
            successMessage = "Successfully exported to:\n\(url.lastPathComponent)"
            showingSuccessAlert = true
        } catch ExportService.ExportError.userCancelled {
            // Silent - user cancelled
        } catch {
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
    }

    // MARK: - Import Actions

    private func importJSON() async {
        isImporting = true
        defer { isImporting = false }

        do {
            let result = try await importService.importFromJSON(in: modelContext)
            successMessage = """
            Import complete!

            Imported:
            • \(result.foldersImported) folders
            • \(result.feedsImported) feeds
            • \(result.readingListsImported) reading lists

            Duplicates skipped: \(result.duplicatesSkipped)
            """
            showingSuccessAlert = true
        } catch ImportService.ImportError.userCancelled {
            // Silent - user cancelled
        } catch {
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
    }

    private func importOPML() async {
        isImporting = true
        defer { isImporting = false }

        do {
            let result = try await importService.importFromOPML(in: modelContext)
            successMessage = """
            Import complete!

            Imported:
            • \(result.foldersImported) folders
            • \(result.feedsImported) feeds

            Duplicates skipped: \(result.duplicatesSkipped)
            """
            showingSuccessAlert = true
        } catch ImportService.ImportError.userCancelled {
            // Silent - user cancelled
        } catch {
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
    }
}

// MARK: - General Settings View

struct GeneralSettingsView: View {
    @ObservedObject var configService = ConfigService.shared

    private func applyAppearance() {
        let appearance = configService.config.isDarkMode ? NSAppearance(named: .darkAqua) : NSAppearance(named: .aqua)
        NSApp.appearance = appearance
        for window in NSApplication.shared.windows {
            window.appearance = appearance
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Appearance Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "paintbrush")
                            .font(.title2)
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Appearance")
                                .font(.headline)

                            Text("Customize the look and feel of LireFlow")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Toggle("Dark Mode", isOn: Binding(
                        get: { configService.config.isDarkMode },
                        set: { newValue in
                            configService.config.isDarkMode = newValue
                            applyAppearance()
                        }
                    ))
                    .help("Switch between light and dark appearance")

                    Toggle("Show Unread Count", isOn: $configService.config.showUnreadCount)
                        .help("Display unread article counts in sidebar")
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // Reading Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "book")
                            .font(.title2)
                            .foregroundStyle(.green)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reading")
                                .font(.headline)

                            Text("Configure article reading preferences")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Article Font Size:")
                            Spacer()
                            Text("\(configService.config.articleFontSize)pt")
                                .foregroundStyle(.secondary)
                        }

                        Slider(value: Binding(
                            get: { Double(configService.config.articleFontSize) },
                            set: { configService.config.articleFontSize = Int($0) }
                        ), in: 12...24, step: 1)
                    }

                    Toggle("Mark as Read on Scroll", isOn: $configService.config.markAsReadOnScroll)
                        .help("Automatically mark articles as read when scrolling past them")
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // Feeds Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                            .foregroundStyle(.orange)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Feeds")
                                .font(.headline)

                            Text("Feed refresh and organization settings")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Refresh Interval:")
                            Spacer()
                            Text("\(configService.config.refreshIntervalMinutes) minutes")
                                .foregroundStyle(.secondary)
                        }

                        Slider(value: Binding(
                            get: { Double(configService.config.refreshIntervalMinutes) },
                            set: { configService.config.refreshIntervalMinutes = Int($0) }
                        ), in: 5...120, step: 5)
                    }

                    HStack {
                        Text("Default Feed Category:")
                        Spacer()
                        TextField("Category", text: $configService.config.defaultFeedCategory)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 200)
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // Weather Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "cloud.sun")
                            .font(.title2)
                            .foregroundStyle(.cyan)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Weather Widget")
                                .font(.headline)

                            Text("Configure weather display in sidebar")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Toggle("Show Weather Widget", isOn: $configService.config.showWeather)
                        .help("Display weather information in the sidebar")

                    HStack {
                        Text("Location:")
                        Spacer()
                        TextField("Auto-detect", text: Binding(
                            get: { configService.config.weatherLocation ?? "" },
                            set: { configService.config.weatherLocation = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 200)
                    }
                    .disabled(!configService.config.showWeather)

                    Text("Leave empty to auto-detect your location")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // Advanced Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "doc.text")
                            .font(.title2)
                            .foregroundStyle(.purple)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Advanced")
                                .font(.headline)

                            Text("Configuration file and advanced options")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Configuration File:")
                                .font(.subheadline)
                            Text(configService.configFilePath)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }

                        Spacer()

                        Button("Reveal in Finder") {
                            if let url = URL(string: "file://" + configService.configFilePath) {
                                NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding()
        }
    }
}

// MARK: - About Settings View

struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "newspaper.fill")
                .font(.system(size: 72))
                .foregroundStyle(.blue)

            VStack(spacing: 8) {
                Text("LireFlow")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Modern RSS reader for macOS")
                    .foregroundStyle(.secondary)

                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 8)
            }

            Divider()
                .padding(.horizontal, 80)

            VStack(alignment: .leading, spacing: 12) {
                Label("Native SwiftUI & SwiftData", systemImage: "swift")
                Label("Dark & Light mode support", systemImage: "moon.stars")
                Label("Weather widget integration", systemImage: "cloud.sun")
                Label("Reading lists & starred articles", systemImage: "star")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    SettingsSheet()
}
