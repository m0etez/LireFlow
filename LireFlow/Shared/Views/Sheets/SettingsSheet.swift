import SwiftUI
import SwiftData

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var folders: [Folder]
    @Query private var feeds: [Feed]
    @Query private var readingLists: [ReadingList]
    @Query(sort: \Article.publishedDate, order: .reverse) private var articles: [Article]

    @ObservedObject var configService = ConfigService.shared
    @StateObject private var storeService = StoreService.shared

    @StateObject private var exportService = ExportService()
    @StateObject private var importService = ImportService()

    @State private var selectedTab: SettingsTab = .about
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var showingSuccessAlert = false
    @State private var successMessage = ""
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var showingCleanupAlert = false
    @State private var cleanupMessage = ""
    @State private var showingUpgrade = false

    enum SettingsTab: String, CaseIterable, Identifiable {
        case general = "General"
        case backup = "Backup"
        case about = "About"

        var id: String { rawValue }
        
        var localizedName: String {
            NSLocalizedString(rawValue, comment: "")
        }
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
                    Text(tab.localizedName).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            // Tab content
            ScrollView {
                switch selectedTab {
                case .general:
                    generalSettings
                case .backup:
                    backupSettings
                case .about:
                    aboutSettings
                }
            }
        }
        .frame(width: 650, height: 550)
        .background(Color(nsColor: .windowBackgroundColor))
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
        .alert("Cleanup Complete", isPresented: $showingCleanupAlert) { // Added for GeneralSettingsView
            Button("OK") { showingCleanupAlert = false }
        } message: {
            Text(cleanupMessage)
        }
        .sheet(isPresented: $showingUpgrade) { // Added for GeneralSettingsView
            UpgradeSheet()
        }
    }

    // MARK: - Backup Settings View

    private var backupSettings: some View {
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

                        Text("Back up your feeds, folders, and reading lists to a file")
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
                    .help("Export a complete library backup (recommended)")

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

                        Text("Restore feeds from a JSON or OPML file. Duplicates will be ignored.")
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
                    .help("Import a LireFlow backup file")

                    Button {
                        Task { await importOPML() }
                    } label: {
                        Label("Import from OPML", systemImage: "doc.text")
                    }
                    .disabled(isImporting)
                    .help("Import feeds from an OPML file")
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
                            Text("Standard RSS format. Exports feeds and folders only. Use this to migrate to other RSS readers.")
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

    // MARK: - General Settings View

    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 24) {
            // MARK: - LireFlow Pro Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "star.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.linearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("LireFlow Pro")
                            .font(.headline)

                        Text(storeService.isPro ? "All features unlocked" : "Unlock premium features")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if storeService.isPro {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Unlocked")
                                .fontWeight(.medium)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.green)
                    }
                }

                if !storeService.isPro {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 16) {
                            proFeatureItem(icon: "infinity", text: "Unlimited Feeds")
                            proFeatureItem(icon: "list.bullet.rectangle", text: "Unlimited Reading Lists")
                        }
                        HStack(spacing: 16) {
                            proFeatureItem(icon: "paintpalette", text: "Premium Themes")
                        }
                    }
                    .padding(.vertical, 8)

                    HStack {
                        Button {
                            showingUpgrade = true
                        } label: {
                            HStack {
                                Image(systemName: "star.fill")
                                Text("Upgrade to Pro – \(storeService.formattedPrice)")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                    }
                }

                // Restore purchases
                Button {
                    Task {
                        await storeService.restorePurchases()
                    }
                } label: {
                    Text("Restore Purchases")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(storeService.isPro ? Color.green.opacity(0.05) : Color.orange.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(storeService.isPro ? Color.green.opacity(0.2) : Color.orange.opacity(0.2), lineWidth: 1)
            )

            // MARK: - Appearance Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "paintbrush")
                        .font(.title2)
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Appearance")
                            .font(.headline)

                        Text("Customize LireFlow's appearance")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Theme picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Theme")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 10) {
                        ForEach(AppTheme.allCases) { theme in
                            themeButton(theme)
                        }
                    }
                }

                Toggle("Show Unread Count", isOn: $configService.config.showUnreadCount)
                    .help("Show the number of unread articles in the sidebar")
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

                        Text("Configure weather display in the sidebar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Toggle("Show Weather Widget", isOn: $configService.config.showWeather)
                    .help("Show weather information in the sidebar")

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

            // Europresse Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "newspaper")
                        .font(.title2)
                        .foregroundStyle(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Europresse Integration")
                            .font(.headline)

                        Text("Access news articles via your university or library")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Select your institution:")
                        .font(.subheadline)

                    Picker("Institution", selection: Binding(
                        get: { configService.config.europressePortal },
                        set: { configService.config.europressePortal = $0 }
                    )) {
                        Text("None (Disabled)").tag(nil as EuropressePortal?)

                        Divider()

                        ForEach(EuropressePortal.availablePortals) { portal in
                            Text(portal.name).tag(portal as EuropressePortal?)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let portal = configService.config.europressePortal {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Connected to \(portal.name)")
                                .font(.caption)
                                .fontWeight(.medium)
                        }

                        Text("A \"Read on Europresse\" button will appear on articles.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)
                        Text("About Europresse")
                            .font(.caption)
                            .fontWeight(.medium)
                    }

                    Text("Europresse is a news archive service available through many European universities and libraries. If your institution has a subscription, you can read full articles from major newspapers.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Your institution not listed? Check with your library if they offer Europresse access.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Performance Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "gauge.high")
                        .font(.title2)
                        .foregroundStyle(.purple)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Performance")
                            .font(.headline)

                        Text("Optimize app performance and storage")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Toggle("Load Images in Articles", isOn: $configService.config.loadImages)
                    .help("Disable to save bandwidth and improve performance")

                Toggle("Background Refresh", isOn: $configService.config.backgroundRefreshEnabled)
                    .help("Allow feeds to refresh in the background")

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Max Articles per Feed:")
                        Spacer()
                        Text("\(configService.config.maxArticlesPerFeed)")
                            .foregroundStyle(.secondary)
                    }

                    Slider(value: Binding(
                        get: { Double(configService.config.maxArticlesPerFeed) },
                        set: { configService.config.maxArticlesPerFeed = Int($0) }
                    ), in: 100...1000, step: 50)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Clean up articles older than:")
                        Spacer()
                        Text("\(configService.config.cleanupOldArticlesDays) days")
                            .foregroundStyle(.secondary)
                    }

                    Slider(value: Binding(
                        get: { Double(configService.config.cleanupOldArticlesDays) },
                        set: { configService.config.cleanupOldArticlesDays = Int($0) }
                    ), in: 7...90, step: 7)
                }

                Button {
                    cleanupOldArticles()
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clean up old articles now")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Advanced Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "doc.text")
                        .font(.title2)
                        .foregroundStyle(.orange)

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

    private func applyAppearance() {
        configService.config.selectedTheme.apply()
    }

    private func cleanupOldArticles() {
        let cutoffDate = Calendar.current.date(
            byAdding: .day,
            value: -configService.config.cleanupOldArticlesDays,
            to: Date()
        ) ?? Date()

        // Filter articles to delete: older than cutoff, not starred, not archived
        let articlesToDelete = articles.filter { article in
            article.publishedDate < cutoffDate &&
            !article.isStarred &&
            !article.isArchived
        }

        let deleteCount = articlesToDelete.count

        // Delete articles
        for article in articlesToDelete {
            modelContext.delete(article)
        }

        // Save context
        do {
            try modelContext.save()
            cleanupMessage = "Successfully deleted \(deleteCount) old articles."
            showingCleanupAlert = true
        } catch {
            cleanupMessage = "Error cleaning up articles: \(error.localizedDescription)"
            showingCleanupAlert = true
        }
    }

    // MARK: - Helper Views

    private func themeButton(_ theme: AppTheme) -> some View {
        Button {
            if theme.isPremium && !storeService.isPro {
                showingUpgrade = true
            } else {
                configService.config.selectedTheme = theme
                applyAppearance()
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: theme.icon)
                    .font(.title2)
                    .frame(height: 28)

                Text(theme.displayName)
                    .font(.caption)

                if theme.isPremium && !storeService.isPro {
                    Text("Pro")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(configService.config.selectedTheme == theme ? Color.accentColor.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(configService.config.selectedTheme == theme ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func proFeatureItem(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(.orange)
                .font(.caption)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - About Settings View

    private var aboutSettings: some View {
        VStack(spacing: 20) {
            Image(systemName: "newspaper.fill") // Assuming asset exists
                .font(.system(size: 72))
                .foregroundStyle(.blue)

            VStack(spacing: 8) {
                Text("LireFlow")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text("Modern RSS Reader for macOS")
                    .foregroundStyle(.primary.opacity(0.7))

                Text("Version 1.2.1")
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.5))
                    .padding(.top, 8)
            }

            Divider()
                .padding(.horizontal, 80)

            VStack(alignment: .leading, spacing: 12) {
                Label("Native SwiftUI & SwiftData", systemImage: "swift")
                Label("Dark & Light Mode Support", systemImage: "moon.stars")
                Label("Weather Widget Integration", systemImage: "cloud.sun")
                Label("Reading Lists & Starred Articles", systemImage: "star")
            }
            .font(.callout)
            .foregroundStyle(.primary.opacity(0.8))

            Spacer()
                .frame(height: 20)

            // Links Section
            VStack(spacing: 10) {
                Button {
                    if let url = URL(string: "https://github.com/m0etez/LireFlow") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Label("View on GitHub", systemImage: "globe")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    if let url = URL(string: "https://twitter.com/mo_saadani") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Label("Follow on Twitter", systemImage: "at")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: 300)

            Spacer()
                .frame(height: 10)

            // Built with Claude
            HStack(spacing: 4) {
                Text("Built with")
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.5))
                Link("Claude", destination: URL(string: "https://claude.ai")!)
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    SettingsSheet()
}
