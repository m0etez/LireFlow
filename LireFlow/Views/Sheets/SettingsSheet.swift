import SwiftUI
import SwiftData

/// The app's Settings window (⌘,), using the standard macOS layout: toolbar tabs and grouped forms.
struct SettingsView: View {
    private enum Tab: Hashable {
        case general, reading, library, about
    }

    @State private var selectedTab: Tab = .general

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsTab()
                .tabItem { Label("General", systemImage: "gearshape") }
                .tag(Tab.general)
            ReadingSettingsTab()
                .tabItem { Label("Reading", systemImage: "textformat.size") }
                .tag(Tab.reading)
            LibrarySettingsTab()
                .tabItem { Label("Library", systemImage: "books.vertical") }
                .tag(Tab.library)
            AboutSettingsTab()
                .tabItem { Label("About", systemImage: "info.circle") }
                .tag(Tab.about)
        }
        .frame(width: 520)
    }
}

// MARK: - General

private struct GeneralSettingsTab: View {
    @ObservedObject private var configService = ConfigService.shared
    @ObservedObject private var storeService = StoreService.shared
    @State private var showingUpgrade = false

    /// Locked themes stay listed; choosing one offers the upgrade instead of applying it
    private var themeSelection: Binding<AppTheme> {
        Binding(
            get: { configService.config.selectedTheme },
            set: { theme in
                if theme.isPremium && !storeService.isPro {
                    showingUpgrade = true
                } else {
                    configService.config.selectedTheme = theme
                }
            }
        )
    }

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: themeSelection) {
                    ForEach(AppTheme.allCases) { theme in
                        (Text(LocalizedStringKey(theme.displayName))
                         + Text(verbatim: theme.isPremium && !storeService.isPro ? " (Pro)" : ""))
                            .tag(theme)
                    }
                }
                Toggle("Show unread count in sidebar", isOn: $configService.config.showUnreadCount)
            }

            Section("Feeds") {
                Toggle("Refresh feeds automatically", isOn: $configService.config.backgroundRefreshEnabled)
                Stepper(value: $configService.config.refreshIntervalMinutes, in: 5...120, step: 5) {
                    Text("Every \(configService.config.refreshIntervalMinutes) minutes")
                }
                .disabled(!configService.config.backgroundRefreshEnabled)
            }

            Section {
                Picker("Institution", selection: $configService.config.europressePortal) {
                    Text("None").tag(nil as EuropressePortal?)
                    Divider()
                    ForEach(EuropressePortal.availablePortals) { portal in
                        Text(portal.name).tag(portal as EuropressePortal?)
                    }
                }
            } header: {
                Text("Europresse")
            } footer: {
                Text("If your university or library subscribes to Europresse, articles from supported newspapers get a “Search on Europresse” button.")
                    .foregroundStyle(.secondary)
            }

            Section("LireFlow Pro") {
                if storeService.isPro {
                    LabeledContent("Status", value: String(localized: "Unlocked"))
                } else {
                    LabeledContent {
                        Button("Upgrade – \(storeService.formattedPrice)") {
                            showingUpgrade = true
                        }
                    } label: {
                        Text("Unlimited feeds and reading lists, plus premium themes")
                    }
                }
                Button("Restore Purchases") {
                    Task { await storeService.restorePurchases() }
                }
            }
        }
        .formStyle(.grouped)
        .frame(height: 470)
        .sheet(isPresented: $showingUpgrade) {
            UpgradeSheet()
        }
    }
}

// MARK: - Reading

private struct ReadingSettingsTab: View {
    @ObservedObject private var configService = ConfigService.shared

    var body: some View {
        Form {
            Section("Article List") {
                Picker("Layout", selection: $configService.config.articleLayout) {
                    ForEach(ArticleLayout.allCases, id: \.self) { layout in
                        Text(LocalizedStringKey(layout.displayName)).tag(layout)
                    }
                }
            }

            Section("Articles") {
                Stepper(value: $configService.config.articleFontSize, in: 12...24) {
                    Text("Text size: \(configService.config.articleFontSize) pt")
                }
                Toggle("Load images", isOn: $configService.config.loadImages)
            }
        }
        .formStyle(.grouped)
        .frame(height: 260)
    }
}

// MARK: - Library

private struct LibrarySettingsTab: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var configService = ConfigService.shared
    @StateObject private var backup = BackupController()

    @Query private var feeds: [Feed]
    @Query private var folders: [Folder]
    @Query private var readingLists: [ReadingList]
    @Query private var articles: [Article]

    @State private var cleanupMessage: String?

    var body: some View {
        Form {
            Section {
                LabeledContent("Back up") {
                    HStack {
                        Button("Export JSON…") { run(.exportJSON) }
                        Button("Export OPML…") { run(.exportOPML) }
                    }
                    .disabled(feeds.isEmpty)
                }
                LabeledContent("Restore") {
                    HStack {
                        Button("Import JSON…") { run(.importJSON) }
                        Button("Import OPML…") { run(.importOPML) }
                    }
                }
            } header: {
                Text("Backup")
            } footer: {
                Text("JSON is a full backup: \(feeds.count) feeds, \(folders.count) folders, \(readingLists.count) reading lists. OPML holds feeds only and works with other RSS readers. Feeds you already have are never duplicated.")
                    .foregroundStyle(.secondary)
            }
            .disabled(backup.isWorking)

            Section {
                Stepper(value: $configService.config.maxArticlesPerFeed, in: 100...1000, step: 50) {
                    Text("Keep up to \(configService.config.maxArticlesPerFeed) articles per feed")
                }
                Stepper(value: $configService.config.cleanupOldArticlesDays, in: 7...90, step: 7) {
                    Text("Keep articles for \(configService.config.cleanupOldArticlesDays) days")
                }
                Button("Clean Up Now", action: cleanupOldArticles)
            } header: {
                Text("Storage")
            } footer: {
                Text("Starred, archived and saved articles are always kept.")
                    .foregroundStyle(.secondary)
            }

            Section("Advanced") {
                LabeledContent("Settings file") {
                    Button("Show in Finder") {
                        NSWorkspace.shared.selectFile(configService.configFilePath, inFileViewerRootedAtPath: "")
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(height: 470)
        .backupAlert(backup)
        .alert("Cleanup", isPresented: Binding(
            get: { cleanupMessage != nil },
            set: { if !$0 { cleanupMessage = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(cleanupMessage ?? "")
        }
    }

    private func run(_ action: BackupAction) {
        Task { await backup.run(action, in: modelContext) }
    }

    private func cleanupOldArticles() {
        let cutoffDate = Calendar.current.date(
            byAdding: .day,
            value: -configService.config.cleanupOldArticlesDays,
            to: Date()
        ) ?? Date()

        // Older than cutoff and not kept by the user (starred, archived, in a reading list).
        // Refresh skips items older than the same cutoff, so these don't come back as unread.
        let articlesToDelete = articles.filter { $0.publishedDate < cutoffDate && !$0.isKeptByUser }
        articlesToDelete.forEach(modelContext.delete)

        do {
            try modelContext.save()
            cleanupMessage = String(localized: "Removed \(articlesToDelete.count) old articles.")
        } catch {
            cleanupMessage = error.localizedDescription
        }
    }
}

// MARK: - About

private struct AboutSettingsTab: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)

            Text("LireFlow")
                .font(.title.bold())
            Text("Version \(version)")
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Link("GitHub", destination: URL(string: "https://github.com/m0etez/LireFlow")!)
                Link("Twitter", destination: URL(string: "https://twitter.com/mo_saadani")!)
                Link("Privacy Policy", destination: URL(string: "https://m0etez.github.io/LireFlow/privacy.html")!)
            }
            .padding(.top, 8)

            HStack(spacing: 4) {
                Text("Built with")
                Link("Claude", destination: URL(string: "https://claude.ai")!)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
    }
}

// MARK: - Backup (shared by Settings and the File menu)

enum BackupAction {
    case exportJSON, exportOPML, importJSON, importOPML
}

@MainActor
final class BackupController: ObservableObject {
    struct Outcome {
        let isError: Bool
        let message: String
    }

    @Published var isWorking = false
    @Published var outcome: Outcome?

    private let exportService = ExportService()
    private let importService = ImportService()

    func run(_ action: BackupAction, in context: ModelContext) async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }

        do {
            switch action {
            case .exportJSON:
                let url = try await exportService.exportToJSON(
                    folders: try context.fetch(FetchDescriptor<Folder>()),
                    feeds: try context.fetch(FetchDescriptor<Feed>()),
                    readingLists: try context.fetch(FetchDescriptor<ReadingList>())
                )
                outcome = Outcome(isError: false, message: String(localized: "Saved as \(url.lastPathComponent)."))
            case .exportOPML:
                let url = try await exportService.exportToOPML(
                    folders: try context.fetch(FetchDescriptor<Folder>()),
                    feeds: try context.fetch(FetchDescriptor<Feed>())
                )
                outcome = Outcome(isError: false, message: String(localized: "Saved as \(url.lastPathComponent)."))
            case .importJSON:
                finishImport(try await importService.importFromJSON(in: context))
            case .importOPML:
                finishImport(try await importService.importFromOPML(in: context))
            }
        } catch ExportService.ExportError.userCancelled {
            // Cancelled in the save panel
        } catch ImportService.ImportError.userCancelled {
            // Cancelled in the open panel
        } catch {
            outcome = Outcome(isError: true, message: error.localizedDescription)
        }
    }

    /// Imported feeds have no articles yet: fetch them, and say what was skipped
    private func finishImport(_ result: ImportService.ImportResult) {
        var lines = [String(localized: "Imported \(result.feedsImported) feeds, \(result.foldersImported) folders and \(result.readingListsImported) reading lists.")]
        if result.duplicatesSkipped > 0 {
            lines.append(String(localized: "Already in your library: \(result.duplicatesSkipped)."))
        }
        if result.limitSkipped > 0 {
            lines.append(String(localized: "Not imported (free plan limit): \(result.limitSkipped). Upgrade to Pro to import everything."))
        }
        outcome = Outcome(isError: false, message: lines.joined(separator: "\n\n"))

        if result.feedsImported > 0 {
            NotificationCenter.default.post(name: .refreshAllFeeds, object: nil)
        }
    }
}

extension View {
    /// Shows the result of an import or export
    func backupAlert(_ controller: BackupController) -> some View {
        alert(
            controller.outcome?.isError == true ? Text("Couldn’t Complete") : Text("Done"),
            isPresented: Binding(
                get: { controller.outcome != nil },
                set: { if !$0 { controller.outcome = nil } }
            )
        ) {
            Button("OK") {}
        } message: {
            Text(controller.outcome?.message ?? "")
        }
    }
}

#Preview {
    SettingsView()
}
