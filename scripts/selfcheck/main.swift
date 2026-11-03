// Self-check for the feed parser and config decoding. Run: scripts/selfcheck.sh
import Foundation

func check(_ condition: Bool, _ message: String) {
    if !condition {
        print("FAIL: \(message)")
        exit(1)
    }
}

// MARK: - AppConfig: an older config.json must keep its values, not reset everything

let oldConfig = #"{"refreshIntervalMinutes": 45, "showWeather": false, "selectedTheme": "no-longer-exists"}"#
let config = try JSONDecoder().decode(AppConfig.self, from: Data(oldConfig.utf8))
check(config.refreshIntervalMinutes == 45, "saved value kept")
check(config.showWeather == false, "saved bool kept")
check(config.hasCompletedOnboarding == false && config.loadImages, "missing keys use defaults")
check(config.selectedTheme == .system, "unknown theme falls back to default")
let roundTrip = try JSONDecoder().decode(AppConfig.self, from: JSONEncoder().encode(config))
check(roundTrip.refreshIntervalMinutes == 45, "encode/decode round trip")

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

let semaphore = DispatchSemaphore(value: 0)
Task {
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

        print("selfcheck OK")
        exit(0)
    } catch {
        print("FAIL: \(error)")
        exit(1)
    }
}
semaphore.wait()
