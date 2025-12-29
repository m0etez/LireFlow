import SwiftUI
import WebKit

struct ArticleDetailView: View {
    @Bindable var article: Article
    var onClose: (() -> Void)?
    @ObservedObject private var configService = ConfigService.shared
    @State private var webViewHeight: CGFloat = 400
    @State private var isFetchingFullArticle = false
    @State private var fetchError: String?

    // Export state
    @StateObject private var exportService = ExportService()
    @State private var isExporting = false
    @State private var showingExportSuccess = false
    @State private var exportSuccessMessage = ""
    @State private var showingExportError = false
    @State private var exportErrorMessage = ""
    
    private var currentTheme: AppTheme {
        configService.config.selectedTheme
    }

    // Use content if available, otherwise fall back to summary
    private var displayContent: String {
        if !article.content.isEmpty {
            return article.content
        } else if !article.summary.isEmpty {
            return article.summary
        } else {
            return "<p><em>Aucun contenu disponible. Cliquez sur 'Récupérer l'article complet' pour charger le contenu.</em></p>"
        }
    }
    
    // Check if we only have summary (not full content)
    private var hasOnlySummary: Bool {
        article.content.isEmpty || article.content == article.summary || article.content.count < 500
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Close button
                HStack {
                    Spacer()
                    
                    if let onClose = onClose {
                        Button {
                            withAnimation(.easeOut(duration: 0.2)) {
                                onClose()
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.secondary)
                                .frame(width: 28, height: 28)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                        }
                        .buttonStyle(.plain)
                        .help("Fermer l'article")
                    }
                }
                
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    // Feed and date
                    HStack {
                        if let feed = article.feed {
                            HStack(spacing: 6) {
                                FeedIcon(url: feed.iconURL, feedURL: feed.url, websiteURL: feed.websiteURL)
                                    .frame(width: 16, height: 16)
                                
                                Text(feed.title)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Text(article.publishedDate, style: .date)
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                    
                    // Title
                    Text(article.title)
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                    
                    // Author
                    if let author = article.author, !author.isEmpty {
                        Text("by \(author)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                }
                .padding(.bottom, 8)
                
                // Fetch full article button (if we only have summary)
                if hasOnlySummary {
                    Button {
                        Task { await fetchFullArticle() }
                    } label: {
                        HStack {
                            if isFetchingFullArticle {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Fetching article...")
                            } else {
                                Image(systemName: "doc.text.magnifyingglass")
                                Text("Fetch full article")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .disabled(isFetchingFullArticle)
                }
                
                // Error message
                if let error = fetchError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.caption)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Divider()
                
                // Content - using WebView with dynamic height
                ArticleContentView(html: displayContent, height: $webViewHeight)
                    .frame(height: webViewHeight)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Action buttons
                if let articleURL = URL(string: article.url) {
                    Divider()
                    
                    VStack(spacing: 12) {
                        // Open in browser
                        Link(destination: articleURL) {
                            HStack {
                                Image(systemName: "globe")
                                Text("Open in browser")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.accentColor.opacity(0.1))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        
                        // Europresse - Press archives via university (only if configured AND source is supported)
                        if let portal = ConfigService.shared.config.europressePortal,
                           !portal.authURL.isEmpty,
                           DefaultFeeds.isEuropresseSupported(url: article.url) {
                            EuropresseButton(article: article, portal: portal)
                        }
                    }
                }
            }
            .padding(32)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .background(currentTheme.backgroundColor)
        .foregroundStyle(currentTheme.textColor)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                        article.isStarred.toggle()
                    }
                } label: {
                    Image(systemName: article.isStarred ? "star.fill" : "star")
                        .foregroundStyle(article.isStarred ? .yellow : .primary)
                        .scaleEffect(article.isStarred ? 1.15 : 1.0)
                }
                .help(article.isStarred ? "Remove from favorites" : "Add to favorites")
                
                Button {
                    article.isRead.toggle()
                } label: {
                    Image(systemName: article.isRead ? "circle" : "circle.fill")
                }
                .help(article.isRead ? "Mark as unread" : "Mark as read")

                Divider()

                Menu {
                    Button {
                        Task { await exportToPDF() }
                    } label: {
                        Label("Export to PDF", systemImage: "doc.richtext")
                    }
                    .disabled(isExporting)

                    Button {
                        Task { await exportToMarkdown() }
                    } label: {
                        Label("Export to Markdown", systemImage: "doc.text")
                    }
                    .disabled(isExporting)
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .help("Export article")
                .disabled(isExporting)

                if let url = URL(string: article.url) {
                    ShareLink(item: url) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .help("Share article")
                }
            }
        }
        .alert("Export successful", isPresented: $showingExportSuccess) {
            Button("OK") { showingExportSuccess = false }
        } message: {
            Text(exportSuccessMessage)
        }
        .alert("Export failed", isPresented: $showingExportError) {
            Button("OK") { showingExportError = false }
        } message: {
            Text(exportErrorMessage)
        }
        .onAppear {
            article.isRead = true
        }
    }
    
    // MARK: - Fetch Full Article
    
    private func fetchFullArticle() async {
        isFetchingFullArticle = true
        fetchError = nil
        
        do {
            let fullContent = try await ArticleExtractor.extractContent(from: article.articleURL)
            
            if fullContent.count > article.content.count {
                article.content = fullContent
                // Reset webview height to recalculate
                webViewHeight = 400
            } else if fullContent.isEmpty {
                fetchError = "Could not extract article content. Try opening in Safari."
            } else {
                fetchError = "No additional content found."
            }
        } catch {
            fetchError = error.localizedDescription
        }
        
        isFetchingFullArticle = false
    }

    // MARK: - Export Article

    private func exportToPDF() async {
        isExporting = true
        defer { isExporting = false }

        do {
            let url = try await exportService.exportArticleToPDF(article: article)
            exportSuccessMessage = "Successfully exported to:\n\(url.lastPathComponent)"
            showingExportSuccess = true
        } catch ExportService.ExportError.userCancelled {
            // Silent - user cancelled
        } catch {
            exportErrorMessage = error.localizedDescription
            showingExportError = true
        }
    }

    private func exportToMarkdown() async {
        isExporting = true
        defer { isExporting = false }

        do {
            let url = try await exportService.exportArticleToMarkdown(article: article)
            exportSuccessMessage = "Successfully exported to:\n\(url.lastPathComponent)"
            showingExportSuccess = true
        } catch ExportService.ExportError.userCancelled {
            // Silent - user cancelled
        } catch {
            exportErrorMessage = error.localizedDescription
            showingExportError = true
        }
    }
}

// Custom WKWebView that passes scroll events to parent (macOS only)
#if os(macOS)
class NonScrollableWebView: WKWebView {
    override func scrollWheel(with event: NSEvent) {
        // Pass scroll events to the next responder (parent ScrollView)
        self.nextResponder?.scrollWheel(with: event)
    }
}
#endif

#if os(macOS)
struct ArticleContentView: NSViewRepresentable {
    let html: String
    @Binding var height: CGFloat

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.isElementFullscreenEnabled = false

        let webView = NonScrollableWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")

        // Disable internal scrolling - let parent ScrollView handle it
        if let scrollView = webView.enclosingScrollView {
            scrollView.hasVerticalScroller = false
            scrollView.hasHorizontalScroller = false
            scrollView.verticalScrollElasticity = .none
            scrollView.horizontalScrollElasticity = .none
        }

        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
        let styledHTML = wrapWithStyles(html)
        webView.loadHTMLString(styledHTML, baseURL: nil)
    }
#else
struct ArticleContentView: UIViewRepresentable {
    let html: String
    @Binding var height: CGFloat

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.isElementFullscreenEnabled = false

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false

        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
        let styledHTML = wrapWithStyles(html)
        webView.loadHTMLString(styledHTML, baseURL: nil)
    }
#endif
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    private func wrapWithStyles(_ content: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                :root {
                    color-scheme: light dark;
                }
                
                * {
                    box-sizing: border-box;
                }
                
                html, body {
                    overflow: hidden;
                }
                
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', system-ui, sans-serif;
                    font-size: 16px;
                    line-height: 1.7;
                    color: #1d1d1f;
                    background: transparent;
                    margin: 0;
                    padding: 0;
                    -webkit-font-smoothing: antialiased;
                }
                
                @media (prefers-color-scheme: dark) {
                    body {
                        color: #f5f5f7;
                    }
                    
                    a {
                        color: #6eb6ff;
                    }
                    
                    img {
                        opacity: 0.9;
                    }
                }
                
                p {
                    margin: 0 0 1.2em 0;
                }
                
                a {
                    color: #0066cc;
                    text-decoration: none;
                }
                
                a:hover {
                    text-decoration: underline;
                }
                
                img {
                    max-width: 100%;
                    height: auto;
                    border-radius: 8px;
                    margin: 16px 0;
                }
                
                figure {
                    margin: 24px 0;
                }
                
                figcaption {
                    font-size: 14px;
                    color: #86868b;
                    text-align: center;
                    margin-top: 8px;
                }
                
                blockquote {
                    margin: 24px 0;
                    padding: 16px 24px;
                    border-left: 4px solid #0066cc;
                    background: rgba(0, 102, 204, 0.05);
                    border-radius: 0 8px 8px 0;
                    font-style: italic;
                }
                
                pre, code {
                    font-family: 'SF Mono', Menlo, Monaco, monospace;
                    font-size: 14px;
                    background: rgba(128, 128, 128, 0.1);
                    border-radius: 4px;
                }
                
                code {
                    padding: 2px 6px;
                }
                
                pre {
                    padding: 16px;
                    overflow-x: auto;
                }
                
                pre code {
                    padding: 0;
                    background: transparent;
                }
                
                h1, h2, h3, h4, h5, h6 {
                    font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', system-ui, sans-serif;
                    font-weight: 600;
                    line-height: 1.3;
                    margin: 1.5em 0 0.5em 0;
                }
                
                h1 { font-size: 28px; }
                h2 { font-size: 24px; }
                h3 { font-size: 20px; }
                
                ul, ol {
                    padding-left: 24px;
                    margin: 16px 0;
                }
                
                li {
                    margin: 8px 0;
                }
                
                hr {
                    border: none;
                    border-top: 1px solid rgba(128, 128, 128, 0.2);
                    margin: 32px 0;
                }
                
                table {
                    width: 100%;
                    border-collapse: collapse;
                    margin: 24px 0;
                }
                
                th, td {
                    padding: 12px;
                    text-align: left;
                    border-bottom: 1px solid rgba(128, 128, 128, 0.2);
                }
                
                th {
                    font-weight: 600;
                }
                
                iframe {
                    max-width: 100%;
                    margin: 16px 0;
                    border-radius: 8px;
                }
            </style>
        </head>
        <body>
            \(content)
            <script>
                // Send height to Swift after load
                function sendHeight() {
                    const height = document.body.scrollHeight;
                    window.webkit.messageHandlers.heightHandler.postMessage(height);
                }
                window.onload = sendHeight;
                setTimeout(sendHeight, 100);
                setTimeout(sendHeight, 500);
            </script>
        </body>
        </html>
        """
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: ArticleContentView
        
        init(parent: ArticleContentView) {
            self.parent = parent
            super.init()
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Get content height after load
            webView.evaluateJavaScript("document.body.scrollHeight") { [weak self] result, error in
                if let height = result as? CGFloat, height > 0 {
                    DispatchQueue.main.async {
                        self?.parent.height = max(height + 20, 100)
                    }
                }
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url {
                PlatformApplication.openURL(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if let height = message.body as? CGFloat {
                DispatchQueue.main.async {
                    self.parent.height = max(height + 20, 100)
                }
            }
        }
    }
}

// MARK: - Europresse Button

struct EuropresseButton: View {
    let article: Article
    let portal: EuropressePortal
    
    @State private var showCopiedFeedback = false
    
    var body: some View {
        VStack(spacing: 8) {
            Button {
                openEuropresse()
            } label: {
                HStack {
                    Image(systemName: "newspaper")
                        .font(.system(size: 16))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Search on Europresse")
                            .font(.subheadline)
                        Text("via \(portal.name)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if showCopiedFeedback {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Image(systemName: "arrow.up.forward.square")
                            .font(.caption)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(Color.orange.opacity(0.1))
                .foregroundStyle(.orange)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .help("Opens Europresse - paste the search query from clipboard")
            
            // Instructions
            VStack(alignment: .leading, spacing: 4) {
                if showCopiedFeedback {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Search query copied!")
                            .fontWeight(.medium)
                    }
                    .font(.caption)
                }
                
                Text("After logging in, paste (⌘V) in the search bar")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
    
    private func openEuropresse() {
        // Copy search query to clipboard
        let searchQuery = "TIT_HEAD=\"\(article.title)\""
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(searchQuery, forType: .string)
        
        // Show feedback
        withAnimation {
            showCopiedFeedback = true
        }
        
        // Open Europresse via configured portal
        if let europresseURL = URL(string: portal.authURL) {
            PlatformApplication.openURL(europresseURL)
        }
        
        // Reset feedback after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showCopiedFeedback = false
            }
        }
    }
}

#Preview {
    ArticleDetailView(
        article: Article(
            title: "Sample Article Title That Is Quite Long",
            summary: "This is a sample article summary.",
            content: "<p>This is the full article content with <strong>rich formatting</strong>.</p><p>Here is another paragraph with more text to test the layout and see how it renders in the WebView component.</p>",
            url: "https://example.com",
            author: "John Doe",
            publishedDate: Date()
        )
    )
}



