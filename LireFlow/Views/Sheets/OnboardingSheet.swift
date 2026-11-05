import SwiftUI
import SwiftData

/// First launch: a short welcome, then pick a few feeds so the app doesn't open empty.
/// Europresse and Pro live in Settings; they're not first-run decisions.
struct OnboardingSheet: View {
    private enum Step {
        case welcome, feeds
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var configService = ConfigService.shared
    @StateObject private var feedService = FeedService()

    @State private var step: Step = .welcome
    @State private var selectedFeeds: Set<String> = []
    @State private var isAdding = false
    @State private var result: FeedService.BulkAddResult?

    var body: some View {
        VStack(spacing: 0) {
            switch step {
            case .welcome:
                welcomeStep
            case .feeds:
                feedsStep
            }

            Divider()

            HStack {
                if step == .feeds {
                    Button("Back") { step = .welcome }
                }

                Spacer()

                if isAdding {
                    ProgressView()
                        .controlSize(.small)
                }

                switch step {
                case .welcome:
                    Button("Continue") { step = .feeds }
                        .keyboardShortcut(.defaultAction)
                case .feeds:
                    Button("Skip") { complete() }
                        .keyboardShortcut(.cancelAction)
                        .disabled(isAdding)
                    Button(selectedFeeds.isEmpty ? "Get Started" : "Add \(selectedFeeds.count) Feeds") {
                        Task { await addFeedsAndFinish() }
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(selectedFeeds.isEmpty || isAdding)
                }
            }
            .padding(20)
        }
        .frame(width: 520, height: 560)
        .interactiveDismissDisabled()
        .alert("Some feeds weren’t added", isPresented: Binding(
            get: { result?.report != nil },
            set: { if !$0 { result = nil } }
        ), presenting: result) { _ in
            Button("OK") { complete() }
        } message: { result in
            Text(result.report ?? "")
        }
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 16) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 64, height: 64)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome to LireFlow")
                        .font(.largeTitle.bold())
                    Text("Your news and blogs, in one quiet place.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 16) {
                featureRow(icon: "dot.radiowaves.up.forward",
                           title: "Follow any site with a feed",
                           detail: "Add feeds from news sites and blogs, and sort them into folders.")
                featureRow(icon: "keyboard",
                           title: "Read from the keyboard",
                           detail: "J and K move between articles, M marks read, S stars, V opens in your browser.")
                featureRow(icon: "lock",
                           title: "Stays on your Mac",
                           detail: "No account, no tracking. Your library is stored locally.")
            }

            Spacer(minLength: 0)
        }
        .padding(32)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var feedsStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Pick a few feeds to start")
                    .font(.title2.bold())
                Text("You can add your own sites any time with ⌘N.")
                    .foregroundStyle(.secondary)
            }
            .padding(20)

            FeedCatalogList(selection: $selectedFeeds)
        }
    }

    private func featureRow(icon: String, title: LocalizedStringKey, detail: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.tint)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Actions

    private func addFeedsAndFinish() async {
        isAdding = true
        defer { isAdding = false }

        let outcome = await feedService.addFeeds(urls: selectedFeeds.sorted(), in: modelContext)
        if outcome.report == nil {
            complete()
        } else {
            result = outcome  // the alert's OK completes onboarding
        }
    }

    private func complete() {
        configService.config.hasCompletedOnboarding = true
        dismiss()
    }
}

#Preview {
    OnboardingSheet()
        .modelContainer(for: [Feed.self, Article.self, Folder.self, ReadingList.self], inMemory: true)
}
