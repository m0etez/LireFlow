import SwiftUI
import SwiftData

struct AddFeedSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let folders: [Folder]

    @Query private var allFeeds: [Feed]
    @StateObject private var feedService = FeedService()
    @ObservedObject private var storeService = StoreService.shared

    @State private var urlString = ""
    /// The normalized URL the preview was fetched from (urlString stays as typed)
    @State private var previewURL: String?
    @State private var selectedFolder: Folder?
    @State private var isLoading = false
    @State private var previewFeed: ParsedFeed?
    @State private var error: Error?
    @State private var showingDefaultFeeds = false
    @State private var showingUpgrade = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Feed")
                .font(.headline)

            TextField("Feed URL", text: $urlString, prompt: Text("https://example.com/feed.xml"))
                .textFieldStyle(.roundedBorder)

            // Preview status: looked up automatically as you type or paste
            Group {
                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Looking for a feed…")
                            .foregroundStyle(.secondary)
                    }
                } else if let error {
                    Label(error.localizedDescription, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.secondary)
                } else if let previewFeed {
                    FeedPreviewCard(feed: previewFeed)
                }
            }
            .font(.callout)
            .frame(minHeight: 24, alignment: .topLeading)

            if !folders.isEmpty {
                Picker("Folder", selection: $selectedFolder) {
                    Text("None").tag(nil as Folder?)
                    ForEach(folders) { folder in
                        Text(folder.name).tag(folder as Folder?)
                    }
                }
            }

            Spacer(minLength: 0)

            HStack {
                Button("Browse Suggestions…") {
                    showingDefaultFeeds = true
                }

                Spacer()

                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Add Feed") {
                    Task { await addFeed() }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(previewFeed == nil || isLoading)
            }
        }
        .padding(20)
        .frame(width: 460, height: 300)
        .task(id: urlString) {
            // Debounced preview: waits for typing to pause, cancelled by the next keystroke
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await fetchPreview()
        }
        .sheet(isPresented: $showingDefaultFeeds) {
            DefaultFeedsSheet(folders: folders) {
                // Feeds added, dismiss this sheet too
                dismiss()
            }
        }
        .sheet(isPresented: $showingUpgrade) {
            UpgradeSheet()
        }
        .onAppear {
            checkClipboardForURL()
        }
    }

    /// Accepts "example.com/feed" as well as full http(s) URLs
    private static func normalizedURL(_ input: String) -> String? {
        var urlStr = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !urlStr.isEmpty, !urlStr.contains(" ") else { return nil }
        if !urlStr.lowercased().hasPrefix("http://") && !urlStr.lowercased().hasPrefix("https://") {
            urlStr = "https://" + urlStr
        }
        guard let url = URL(string: urlStr),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = url.host, host.contains(".") else {
            return nil
        }
        return urlStr
    }

    private func fetchPreview() async {
        previewFeed = nil
        previewURL = nil
        error = nil

        guard !urlString.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        guard let urlStr = Self.normalizedURL(urlString) else {
            error = FeedServiceError.invalidURL
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let feed = try await feedService.fetchFeed(from: urlStr)
            guard !Task.isCancelled else { return }
            previewFeed = feed
            previewURL = urlStr
        } catch {
            guard !Task.isCancelled else { return }  // superseded by newer typing
            self.error = error
        }
    }

    private func addFeed() async {
        guard let previewURL else { return }

        if allFeeds.contains(where: { $0.url == previewURL }) {
            error = FeedServiceError.alreadySubscribed
            previewFeed = nil
            return
        }

        // Check freemium limit
        if !storeService.canAddFeed(currentCount: allFeeds.count) {
            showingUpgrade = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await feedService.addFeed(url: previewURL, to: selectedFolder, in: modelContext)
            dismiss()
        } catch {
            self.error = error
        }
    }

    /// Prefills the field when the clipboard holds a URL; the preview task picks it up
    private func checkClipboardForURL() {
        guard urlString.isEmpty,
              let clipboard = NSPasteboard.general.string(forType: .string),
              clipboard.count < 500,
              Self.normalizedURL(clipboard) != nil else { return }
        urlString = clipboard.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Feed Preview Card

struct FeedPreviewCard: View {
    let feed: ParsedFeed

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(feed.title)
                .font(.headline)

            if !feed.description.isEmpty {
                Text(feed.description)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Text("\(feed.articles.count) articles")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Feed Catalog

/// The suggested feeds, by category, with a checkbox each. Used by Browse Suggestions and onboarding.
struct FeedCatalogList: View {
    @Binding var selection: Set<String>  // feed URLs

    var body: some View {
        List {
            ForEach(DefaultFeeds.categories, id: \.self) { category in
                Section(LocalizedStringKey(category)) {
                    ForEach(DefaultFeeds.feeds(for: category), id: \.url) { feedInfo in
                        Toggle(isOn: Binding(
                            get: { selection.contains(feedInfo.url) },
                            set: { isOn in
                                if isOn {
                                    selection.insert(feedInfo.url)
                                } else {
                                    selection.remove(feedInfo.url)
                                }
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(feedInfo.title)
                                Text(URL(string: feedInfo.url)?.host ?? feedInfo.url)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .toggleStyle(.checkbox)
                    }
                }
            }
        }
    }
}

extension FeedService.BulkAddResult {
    /// Alert text for feeds that weren't added, or nil when everything was
    var report: String? {
        var lines: [String] = []
        if !failedURLs.isEmpty {
            let titles = Dictionary(
                DefaultFeeds.feeds.map { ($0.url, $0.title) },
                uniquingKeysWith: { first, _ in first }
            )
            let names = failedURLs.map { titles[$0] ?? $0 }
            lines.append(String(localized: "Couldn’t load: \(names.joined(separator: ", "))"))
        }
        if limitSkipped > 0 {
            lines.append(String(localized: "Free plan limit reached: \(limitSkipped) feeds not added."))
        }
        return lines.isEmpty ? nil : lines.joined(separator: "\n\n")
    }
}

// MARK: - Default Feeds Sheet

struct DefaultFeedsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let folders: [Folder]
    let onComplete: () -> Void

    @State private var selectedFeeds: Set<String> = []  // URLs of selected feeds
    @State private var selectedFolder: Folder?
    @State private var isAdding = false
    @StateObject private var feedService = FeedService()

    // Outcome of a bulk add that didn't fully succeed
    @State private var result: FeedService.BulkAddResult?
    @State private var showingUpgrade = false

    var body: some View {
        VStack(spacing: 0) {
            Text("Suggested Feeds")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()

            FeedCatalogList(selection: $selectedFeeds)

            HStack {
                if !folders.isEmpty {
                    Picker("Folder", selection: $selectedFolder) {
                        Text("None").tag(nil as Folder?)
                        ForEach(folders) { folder in
                            Text(folder.name).tag(folder as Folder?)
                        }
                    }
                    .fixedSize()
                }

                Spacer()

                if isAdding {
                    ProgressView()
                        .controlSize(.small)
                }

                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button(selectedFeeds.isEmpty ? "Add Feeds" : "Add \(selectedFeeds.count) Feeds") {
                    Task { await addSelectedFeeds() }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedFeeds.isEmpty || isAdding)
            }
            .padding()
        }
        .frame(width: 500, height: 600)
        .alert("Some feeds weren’t added", isPresented: Binding(
            get: { result?.report != nil },
            set: { if !$0 { result = nil } }
        ), presenting: result) { result in
            if result.limitSkipped > 0 {
                Button("Upgrade to Pro") { showingUpgrade = true }
            }
            Button("OK") { finish() }
        } message: { result in
            Text(result.report ?? "")
        }
        .sheet(isPresented: $showingUpgrade, onDismiss: finish) {
            UpgradeSheet()
        }
    }

    private func finish() {
        onComplete()
        dismiss()
    }

    private func addSelectedFeeds() async {
        isAdding = true
        defer { isAdding = false }

        let outcome = await feedService.addFeeds(urls: selectedFeeds.sorted(), to: selectedFolder, in: modelContext)
        if outcome.report == nil {
            finish()
        } else {
            result = outcome
        }
    }
}

#Preview {
    AddFeedSheet(folders: [])
        .modelContainer(for: [Feed.self, Article.self, Folder.self], inMemory: true)
}
