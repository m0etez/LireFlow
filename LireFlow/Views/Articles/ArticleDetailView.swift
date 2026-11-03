import SwiftUI
import WebKit

struct ArticleDetailView: View {
    @Bindable var article: Article
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
            return "<p><em>" + String(localized: "No content available. Click \u{201C}Fetch full article\u{201D} to load it.") + "</em></p>"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        if let feed = article.feed {
                            Label {
                                Text(feed.title)
                            } icon: {
                                FeedIcon(url: feed.iconURL, feedURL: feed.url, websiteURL: feed.websiteURL)
                                    .frame(width: 16, height: 16)
                            }
                        }
                        Spacer()
                        Text(article.publishedDate, style: .date)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    Text(article.title)
                        .font(.largeTitle.bold())
                        .textSelection(.enabled)

                    if let author = article.author, !author.isEmpty {
                        Text("by \(author)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Always offered: feeds often carry a summary, and a page can be re-fetched
                    HStack(spacing: 8) {
                        Button {
                            Task { await fetchFullArticle() }
                        } label: {
                            Label("Fetch Full Article", systemImage: "doc.text.magnifyingglass")
                        }
                        .controlSize(.small)
                        .disabled(isFetchingFullArticle)

                        if isFetchingFullArticle {
                            ProgressView()
                                .controlSize(.small)
                        } else if let error = fetchError {
                            Label(error, systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 4)
                }

                Divider()

                ArticleContentView(
                    html: displayContent,
                    fontSize: configService.config.articleFontSize,
                    loadImages: configService.config.loadImages,
                    theme: currentTheme,
                    height: $webViewHeight
                )
                    .frame(height: webViewHeight)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Europresse: only if configured and the source is supported
                if let portal = configService.config.europressePortal,
                   !portal.authURL.isEmpty,
                   DefaultFeeds.isEuropresseSupported(url: article.url) {
                    Divider()
                    EuropresseButton(article: article, portal: portal)
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
                    article.isStarred.toggle()
                } label: {
                    Label(article.isStarred ? "Unstar" : "Star",
                          systemImage: article.isStarred ? "star.fill" : "star")
                }
                .help(article.isStarred ? "Remove star (S)" : "Star (S)")

                Button {
                    article.isRead.toggle()
                } label: {
                    Label(article.isRead ? "Mark as Unread" : "Mark as Read",
                          systemImage: article.isRead ? "circle" : "circle.fill")
                }
                .help(article.isRead ? "Mark as unread (M)" : "Mark as read (M)")

                if let url = URL(string: article.url) {
                    Link(destination: url) {
                        Label("Open in Browser", systemImage: "safari")
                    }
                    .help("Open in browser (V)")
                }

                Menu {
                    Button("Export as PDF…") { Task { await exportToPDF() } }
                    Button("Export as Markdown…") { Task { await exportToMarkdown() } }
                } label: {
                    Label("Export", systemImage: "square.and.arrow.down")
                }
                .help("Export article")
                .disabled(isExporting)

                if let url = URL(string: article.url) {
                    ShareLink(item: url)
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
        .onChange(of: article.id, initial: true) {
            article.isRead = true
            fetchError = nil
        }
    }

    // MARK: - Fetch Full Article
    
    private func fetchFullArticle() async {
        isFetchingFullArticle = true
        fetchError = nil
        
        do {
            let fullContent = try await ArticleExtractor.extractContent(from: article.articleURL)
            
            // Compare text, not markup: only replace what's shown when the page has more to read
            let shownText = (article.content.isEmpty ? article.summary : article.content).strippingHTML
            if fullContent.strippingHTML.count > shownText.count {
                article.content = fullContent
                // Reset webview height to recalculate
                webViewHeight = 400
            } else if fullContent.isEmpty {
                fetchError = String(localized: "Couldn’t find the article text. Open it in your browser instead.")
            } else {
                fetchError = String(localized: "The page has no more text than the feed.")
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
            exportSuccessMessage = String(localized: "Saved as \(url.lastPathComponent).")
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
            exportSuccessMessage = String(localized: "Saved as \(url.lastPathComponent).")
            showingExportSuccess = true
        } catch ExportService.ExportError.userCancelled {
            // Silent - user cancelled
        } catch {
            exportErrorMessage = error.localizedDescription
            showingExportError = true
        }
    }
}

// Custom WKWebView that passes scroll events to parent
class NonScrollableWebView: WKWebView {
    override func scrollWheel(with event: NSEvent) {
        // Pass scroll events to the next responder (parent ScrollView)
        self.nextResponder?.scrollWheel(with: event)
    }
}

struct ArticleContentView: NSViewRepresentable {
    let html: String
    var fontSize: Int = 16
    var loadImages: Bool = true
    var theme: AppTheme = .system
    @Binding var height: CGFloat

    /// Reports the content height. Runs in an isolated script world, so it works even though
    /// the article's own scripts are disabled, and keeps reporting as images load.
    private static let heightScript = """
    (() => {
        const send = () => window.webkit.messageHandlers.heightHandler.postMessage(document.body.scrollHeight);
        new ResizeObserver(send).observe(document.body);
        send();
    })();
    """

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.isElementFullscreenEnabled = false
        // Feed HTML is untrusted: its scripts never run (no tracking, no redirects, no fake pages).
        config.defaultWebpagePreferences.allowsContentJavaScript = false
        config.userContentController.add(context.coordinator, contentWorld: .defaultClient, name: "heightHandler")
        config.userContentController.addUserScript(
            WKUserScript(source: Self.heightScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true, in: .defaultClient)
        )

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
        // Every SwiftUI update (star, read, height change…) lands here: reload only on real changes.
        guard styledHTML != context.coordinator.loadedHTML else { return }
        context.coordinator.loadedHTML = styledHTML
        webView.loadHTMLString(styledHTML, baseURL: nil)
    }

    static func dismantleNSView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.userContentController.removeAllScriptMessageHandlers()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    /// Fixed themes paint the page themselves; System keeps the light/dark defaults above
    private var themeCSS: String {
        guard theme != .system else { return "" }
        return """
        body { color: \(Self.css(theme.textColor)); }
        a { color: \(Self.css(theme.accentColor)); }
        blockquote { border-left-color: \(Self.css(theme.accentColor)); background: transparent; }
        figcaption { color: \(Self.css(theme.secondaryTextColor)); }
        """
    }

    private static func css(_ color: Color) -> String {
        guard let rgb = NSColor(color).usingColorSpace(.sRGB) else { return "inherit" }
        return "rgb(\(Int(rgb.redComponent * 255)), \(Int(rgb.greenComponent * 255)), \(Int(rgb.blueComponent * 255)))"
    }

    private func wrapWithStyles(_ content: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            \(loadImages ? "" : #"<meta http-equiv="Content-Security-Policy" content="img-src 'none'">"#)
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
                    font-size: \(fontSize)px;
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
                \(loadImages ? "" : "img, picture { display: none !important; }")
                \(themeCSS)
            </style>
        </head>
        <body>
            \(content)
        </body>
        </html>
        """
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: ArticleContentView
        var loadedHTML: String?

        init(parent: ArticleContentView) {
            self.parent = parent
            super.init()
        }

        private func setHeight(_ contentHeight: CGFloat) {
            let newHeight = max(contentHeight + 20, 100)
            DispatchQueue.main.async {
                if abs(self.parent.height - newHeight) > 1 {
                    self.parent.height = newHeight
                }
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Fallback in case the observer script hasn't reported yet
            webView.evaluateJavaScript("document.body.scrollHeight", in: nil, in: .defaultClient) { [weak self] result in
                if case .success(let value) = result, let number = value as? NSNumber {
                    self?.setHeight(CGFloat(number.doubleValue))
                }
            }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }

            // Clicked links open in the default browser (web and mail links only)
            if navigationAction.navigationType == .linkActivated {
                if ["http", "https", "mailto"].contains(url.scheme?.lowercased() ?? "") {
                    NSWorkspace.shared.open(url)
                }
                decisionHandler(.cancel)
                return
            }

            // Allow our own loadHTMLString (about:blank) and embedded frames (videos);
            // block anything else replacing the article (redirects, meta refresh).
            let isMainFrame = navigationAction.targetFrame?.isMainFrame ?? true
            decisionHandler(!isMainFrame || url.absoluteString == "about:blank" ? .allow : .cancel)
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if let number = message.body as? NSNumber {
                setHeight(CGFloat(number.doubleValue))
            }
        }
    }
}

// MARK: - Europresse Button

struct EuropresseButton: View {
    let article: Article
    let portal: EuropressePortal

    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: openEuropresse) {
                Label("Search on Europresse", systemImage: "newspaper")
            }
            .help("Copies the title as a search and opens Europresse")

            Text(copied
                 ? "Search copied. After signing in, paste it (⌘V) in Europresse’s search field."
                 : "Via \(portal.name). Copies the title as a search query, then opens Europresse.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func openEuropresse() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("TIT_HEAD=\"\(article.title)\"", forType: .string)
        copied = true

        if let europresseURL = URL(string: portal.authURL) {
            NSWorkspace.shared.open(europresseURL)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            copied = false
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



