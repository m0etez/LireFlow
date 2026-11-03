// Self-check for the feed parser and config decoding. Run: scripts/selfcheck.sh
import Foundation

func check(_ condition: Bool, _ message: String) {
    if !condition {
        print("FAIL: \(message)")
        exit(1)
    }
}

// MARK: - AppConfig: an older config.json must keep its values, not reset everything

let oldConfig = #"{"refreshIntervalMinutes": 45, "showUnreadCount": false, "showWeather": true, "selectedTheme": "no-longer-exists"}"#
let config = try JSONDecoder().decode(AppConfig.self, from: Data(oldConfig.utf8))
check(config.refreshIntervalMinutes == 45, "saved value kept")
check(config.showUnreadCount == false, "saved bool kept")
check(config.hasCompletedOnboarding == false && config.loadImages, "missing keys use defaults")
check(config.selectedTheme == .system, "unknown theme falls back to default")
let roundTrip = try JSONDecoder().decode(AppConfig.self, from: JSONEncoder().encode(config))
check(roundTrip.refreshIntervalMinutes == 45, "encode/decode round trip")

// MARK: - DefaultFeeds: moved catalog URLs must point at a current entry, never at a removed one

let catalogURLs = Set(DefaultFeeds.feeds.map(\.url))
check(catalogURLs.count == DefaultFeeds.feeds.count, "no duplicate catalog URLs")
for (old, new) in DefaultFeeds.movedURLs {
    check(catalogURLs.contains(new), "moved URL target \(new) is in the catalog")
    check(!catalogURLs.contains(old), "old URL \(old) was replaced in the catalog")
}

// MARK: - FeedParser

let atom = """
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Atom Feed</title>
  <link href="https://example.com/"/>
  <author><name>Feed Owner</name></author>
  <entry>
    <title>First</title>
    <link rel="alternate" href="https://example.com/1"/>
    <author><name>Jane Doe</name></author>
    <updated>2026-01-02T10:00:00Z</updated>
    <content type="xhtml"><div xmlns="http://www.w3.org/1999/xhtml"><p>Hello <b>world</b> &amp; more</p><p>Second</p></div></content>
  </entry>
</feed>
"""

let rss = """
<?xml version="1.0"?>
<rss version="2.0"><channel>
  <title>RSS Feed</title><link>https://example.org</link>
  <item>
    <title>Item</title><link>https://example.org/a</link>
    <author>john@example.org (John)</author>
    <description><![CDATA[<p>Summary</p>]]></description>
    <pubDate>Mon, 05 Jan 2026 08:00:00 +0000</pubDate>
  </item>
</channel></rss>
"""

// Article extraction: real pages put teaser <article> cards before the story, nest divs
// inside the body, and use relative + lazy-loaded image URLs.
let page = """
<html><head><title>T</title><script>var x = "<p>not this</p>";</script></head><body>
<nav><a href="/">Home</a></nav>
<script>document.write("<div>" + "</div>"); var tpl = '</p><p>';</script>
<article class="card"><a href="/other">Other story</a><p>A teaser for some other story that is long enough to count as a paragraph.</p></article>
<div id="content" class="layout b-right-rail__ad-wrapper"><div class="post-content">
  <div class="share-buttons"><a href="/share">Share</a></div>
  <h1>The story</h1>
  <p>First paragraph of the real story, which is long enough to be a real paragraph of text.</p>
  <div class="inline-ad">Advertisement</div>
  <figure><img src="data:image/gif;base64,R0lGOD" data-src="/img/photo.jpg" alt="Photo"></figure>
  <p>Second paragraph comes after a nested div, and the extractor must not stop at that div.</p>
  <p>Last paragraph, with a <a href="/related">relative link</a> that should<br>still work later on.</p>
</div></div>
<aside><p>Sidebar text that is long enough to look like a paragraph but is not the article.</p></aside>
</body></html>
"""
// Story split into sibling blocks with ads between them (Engadget-style)
let splitPage = """
<html><body><div class="article">
<div class="news-article"><div class="columns-holder"><p>Chunk one opens the story with a sentence long enough to count.</p></div></div>
<div class="ad-slot"></div>
<div class="news-article"><div class="columns-holder"><p>Chunk two is the longest part of the story, with plenty of text in it.</p><p>It carries on here with a second paragraph that is also quite long indeed.</p><p>And a third paragraph, so this block clearly scores the highest of them all.</p></div></div>
<div class="news-article"><div class="columns-holder"><p>Chunk three closes the story with a final sentence that is long enough.</p></div></div>
</div></body></html>
"""

// The extractor runs WebKit, which needs the main run loop running (not a blocked semaphore)
Task { @MainActor in
    do {
        let atomFeed = try await FeedParser().parse(data: Data(atom.utf8))
        check(atomFeed.title == "Atom Feed", "atom feed title")
        check(atomFeed.articles.count == 1, "atom entry count")
        let entry = atomFeed.articles[0]
        check(entry.author == "Jane Doe", "atom <author><name> → author, got \(entry.author ?? "nil")")
        check(entry.url == "https://example.com/1", "atom link")
        check(entry.content.contains("<p>Hello <b>world</b> &amp; more</p><p>Second</p>"),
              "xhtml content kept as markup, got \(entry.content)")

        let rssFeed = try await FeedParser().parse(data: Data(rss.utf8))
        let item = rssFeed.articles[0]
        check(item.author == "john@example.org (John)", "rss author")
        check(item.summary == "<p>Summary</p>", "rss CDATA description")
        check(Calendar(identifier: .gregorian).component(.year, from: item.publishedDate) == 2026, "rss date")

        ArticleExtractor.readabilityURL = URL(fileURLWithPath: "LireFlow/Resources/Readability.js")
        let extracted = try await ArticleExtractor.extractMainContent(from: page, baseURL: URL(string: "https://example.com/news/story")!)
        check(extracted.contains("First paragraph"), "extractor keeps the story start")
        check(extracted.contains("Last paragraph"), "extractor doesn't stop at a nested </div>, got \(extracted)")
        check(!extracted.contains("teaser"), "extractor skips the teaser card")
        check(!extracted.contains("Sidebar"), "extractor skips the sidebar")
        check(!extracted.contains("not this") && !extracted.contains("document.write"), "extractor drops scripts")
        check(!extracted.contains("Share"), "extractor drops share bars inside the story")
        check(extracted.contains("https://example.com/img/photo.jpg"), "lazy, relative image resolved, got \(extracted)")
        check(extracted.contains("https://example.com/related"), "relative link resolved")
        check(!extracted.contains("</br>") && !extracted.contains("</img>"), "no stray void closing tags (double line breaks)")

        let split = try await ArticleExtractor.extractMainContent(from: splitPage, baseURL: URL(string: "https://example.com/a")!)
        check(split.contains("Chunk one") && split.contains("Chunk two") && split.contains("Chunk three"),
              "extractor joins a story split across sibling blocks, got \(split)")

        print("selfcheck OK")
        exit(0)
    } catch {
        print("FAIL: \(error)")
        exit(1)
    }
}
RunLoop.main.run()
