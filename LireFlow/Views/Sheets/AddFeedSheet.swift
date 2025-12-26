import SwiftUI
import SwiftData

struct AddFeedSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let folders: [Folder]
    
    @StateObject private var feedService = FeedService()
    
    @State private var urlString = ""
    @State private var selectedFolder: Folder?
    @State private var isLoading = false
    @State private var previewFeed: ParsedFeed?
    @State private var error: Error?
    @State private var showingDefaultFeeds = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header - Clean liquid glass style
            HStack {
                Text("Add Feed")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // URL Input - Refined styling
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Feed URL")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 12) {
                            TextField("https://example.com/feed.xml", text: $urlString)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.ultraThinMaterial)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(.quaternary, lineWidth: 1)
                                )
                                .onSubmit {
                                    Task { await fetchPreview() }
                                }
                            
                            Button {
                                Task { await fetchPreview() }
                            } label: {
                                Group {
                                    if isLoading {
                                        ProgressView()
                                            .controlSize(.small)
                                    } else {
                                        Text("Fetch")
                                            .fontWeight(.medium)
                                    }
                                }
                                .frame(width: 60)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            .disabled(urlString.isEmpty || isLoading)
                        }
                    }
                    
                    // Error display - Subtle styling
                    if let error = error {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(error.localizedDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.orange.opacity(0.08))
                        )
                    }
                    
                    // Preview - Liquid glass card
                    if let feed = previewFeed {
                        FeedPreviewCard(feed: feed)
                    }
                    
                    // Folder selection - Cleaner design
                    if !folders.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Add to Folder")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                            
                            Picker("", selection: $selectedFolder) {
                                Text("None").tag(nil as Folder?)
                                ForEach(folders) { folder in
                                    Text(folder.name).tag(folder as Folder?)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
            
            Spacer()
            
            // Browse default feeds - Subtle link style
            Button {
                showingDefaultFeeds = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.caption)
                    Text("Browse Default Feeds")
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 16)
            
            // Footer - Clean button row
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                
                Spacer()
                
                Button {
                    Task { await addFeed() }
                } label: {
                    Text("Add Feed")
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .keyboardShortcut(.return)
                .disabled(previewFeed == nil || isLoading)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .frame(width: 480, height: 500)
        .background(.ultraThinMaterial)
        .sheet(isPresented: $showingDefaultFeeds) {
            DefaultFeedsSheet(folders: folders) {
                // Feeds added, dismiss this sheet too
                dismiss()
            }
        }
        .onAppear {
            checkClipboardForURL()
        }
    }
    
    private func fetchPreview() async {
        guard !urlString.isEmpty else { return }

        // Normalize and validate URL
        var urlStr = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

        // Add https:// if no scheme is present
        if !urlStr.hasPrefix("http://") && !urlStr.hasPrefix("https://") {
            urlStr = "https://" + urlStr
        }

        // Validate URL and ensure safe scheme
        guard let url = URL(string: urlStr),
              let scheme = url.scheme?.lowercased(),
              (scheme == "http" || scheme == "https"),
              url.host != nil else {
            self.error = NSError(
                domain: "AddFeedSheet",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL. Please enter a valid http:// or https:// URL."]
            )
            return
        }

        urlString = urlStr

        isLoading = true
        error = nil
        previewFeed = nil

        do {
            previewFeed = try await feedService.fetchFeed(from: urlStr)
        } catch {
            self.error = error
        }

        isLoading = false
    }
    
    private func addFeed() async {
        guard previewFeed != nil else { return }

        isLoading = true

        do {
            _ = try await feedService.addFeed(url: urlString, to: selectedFolder, in: modelContext)
            dismiss()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    private func checkClipboardForURL() {
        guard urlString.isEmpty else { return }  // Don't override if user already typed something

        if let clipboardString = NSPasteboard.general.string(forType: .string) {
            let trimmed = clipboardString.trimmingCharacters(in: .whitespacesAndNewlines)

            // Validate clipboard content is a safe URL
            guard trimmed.count < 500 else { return }  // Length check

            var urlStr = trimmed
            if !urlStr.hasPrefix("http://") && !urlStr.hasPrefix("https://") {
                // Only auto-prepend https if it looks like a domain
                if urlStr.contains(".") && !urlStr.contains(" ") {
                    urlStr = "https://" + urlStr
                } else {
                    return  // Not a valid URL pattern
                }
            }

            // Validate it's a proper URL with safe scheme
            if let url = URL(string: urlStr),
               let scheme = url.scheme?.lowercased(),
               (scheme == "http" || scheme == "https"),
               url.host != nil {
                urlString = trimmed

                // Auto-trigger preview fetch
                Task {
                    await fetchPreview()
                }
            }
        }
    }
}

// MARK: - Feed Preview Card

struct FeedPreviewCard: View {
    let feed: ParsedFeed
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.body)
                
                Text("Feed Found")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.green)
            }
            
            Text(feed.title)
                .font(.headline)
                .foregroundStyle(.primary)
            
            if !feed.description.isEmpty {
                Text(feed.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                Image(systemName: "doc.text")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text("\(feed.articles.count) articles")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.green.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.green.opacity(0.15), lineWidth: 1)
        )
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
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Browse Feeds")
                    .font(.headline)
                
                Spacer()
                
                if !selectedFeeds.isEmpty {
                    Text("\(selectedFeeds.count) selected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            List {
                ForEach(DefaultFeeds.categories, id: \.self) { category in
                    Section(category) {
                        ForEach(DefaultFeeds.feeds(for: category), id: \.url) { feedInfo in
                            HStack {
                                Toggle("", isOn: Binding(
                                    get: { selectedFeeds.contains(feedInfo.url) },
                                    set: { isSelected in
                                        if isSelected {
                                            selectedFeeds.insert(feedInfo.url)
                                        } else {
                                            selectedFeeds.remove(feedInfo.url)
                                        }
                                    }
                                ))
                                .toggleStyle(.checkbox)
                                
                                VStack(alignment: .leading) {
                                    Text(feedInfo.title)
                                        .foregroundStyle(.primary)
                                    
                                    Text(feedInfo.url)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            // Footer
            VStack(spacing: 12) {
                if !folders.isEmpty {
                    Picker("Add to Folder", selection: $selectedFolder) {
                        Text("None").tag(nil as Folder?)
                        ForEach(folders) { folder in
                            Text(folder.name).tag(folder as Folder?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .keyboardShortcut(.escape)
                    
                    Spacer()
                    
                    Button {
                        Task { await addSelectedFeeds() }
                    } label: {
                        if isAdding {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("Add \(selectedFeeds.count) Feed\(selectedFeeds.count == 1 ? "" : "s")")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedFeeds.isEmpty || isAdding)
                }
            }
            .padding()
        }
        .frame(width: 500, height: 600)
    }
    
    private func addSelectedFeeds() async {
        isAdding = true
        defer { 
            isAdding = false 
        }
        
        for feedURL in selectedFeeds {
            do {
                _ = try await feedService.addFeed(url: feedURL, to: selectedFolder, in: modelContext)
            } catch {
                // Continue adding other feeds even if one fails
                print("Failed to add feed \(feedURL): \(error)")
            }
        }
        
        await MainActor.run {
            onComplete()
            dismiss()
        }
    }
}

#Preview {
    AddFeedSheet(folders: [])
        .modelContainer(for: [Feed.self, Article.self, Folder.self], inMemory: true)
}
