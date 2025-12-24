import Foundation

/// Pre-configured default feeds
struct DefaultFeeds {
    
    struct FeedInfo {
        let title: String
        let url: String
        let category: String
    }
    
    static let feeds: [FeedInfo] = [
        // Tech
        FeedInfo(title: "Hacker News", url: "https://hnrss.org/frontpage", category: "Tech"),
        FeedInfo(title: "The Verge", url: "https://www.theverge.com/rss/index.xml", category: "Tech"),
        FeedInfo(title: "Ars Technica", url: "https://feeds.arstechnica.com/arstechnica/index", category: "Tech"),
        FeedInfo(title: "TechCrunch", url: "https://techcrunch.com/feed/", category: "Tech"),
        FeedInfo(title: "Wired", url: "https://www.wired.com/feed/rss", category: "Tech"),
        FeedInfo(title: "Engadget", url: "https://www.engadget.com/rss.xml", category: "Tech"),
        
        // News - International
        FeedInfo(title: "BBC News", url: "https://feeds.bbci.co.uk/news/rss.xml", category: "News"),
        FeedInfo(title: "Reuters", url: "https://www.reutersagency.com/feed/", category: "News"),
        FeedInfo(title: "NPR News", url: "https://feeds.npr.org/1001/rss.xml", category: "News"),
        FeedInfo(title: "The Guardian", url: "https://www.theguardian.com/world/rss", category: "News"),
        FeedInfo(title: "Al Jazeera", url: "https://www.aljazeera.com/xml/rss/all.xml", category: "News"),
        FeedInfo(title: "Associated Press", url: "https://apnews.com/index.rss", category: "News"),
        FeedInfo(title: "CNN", url: "http://rss.cnn.com/rss/edition.rss", category: "News"),
        
        // News - France
        FeedInfo(title: "Le Monde", url: "https://www.lemonde.fr/rss/une.xml", category: "France"),
        FeedInfo(title: "Le Figaro", url: "https://www.lefigaro.fr/rss/figaro_actualites.xml", category: "France"),
        FeedInfo(title: "Libération", url: "https://www.liberation.fr/arc/outboundfeeds/rss/?outputType=xml", category: "France"),
        FeedInfo(title: "France Info", url: "https://www.francetvinfo.fr/titres.rss", category: "France"),
        FeedInfo(title: "20 Minutes", url: "https://www.20minutes.fr/feeds/rss-une.xml", category: "France"),
        
        // Science
        FeedInfo(title: "Nature", url: "https://www.nature.com/nature.rss", category: "Science"),
        FeedInfo(title: "Science Daily", url: "https://www.sciencedaily.com/rss/all.xml", category: "Science"),
        FeedInfo(title: "Phys.org", url: "https://phys.org/rss-feed/", category: "Science"),
        FeedInfo(title: "New Scientist", url: "https://www.newscientist.com/feed/home/", category: "Science"),
        
        // Design & Apple
        FeedInfo(title: "Daring Fireball", url: "https://daringfireball.net/feeds/main", category: "Apple"),
        FeedInfo(title: "Six Colors", url: "https://feedpress.me/sixcolors", category: "Apple"),
        FeedInfo(title: "MacStories", url: "https://www.macstories.net/feed/", category: "Apple"),
        FeedInfo(title: "9to5Mac", url: "https://9to5mac.com/feed/", category: "Apple"),
        FeedInfo(title: "MacRumors", url: "https://feeds.macrumors.com/MacRumors-All", category: "Apple"),
        
        // Development
        FeedInfo(title: "Swift by Sundell", url: "https://www.swiftbysundell.com/rss", category: "Development"),
        FeedInfo(title: "NSHipster", url: "https://nshipster.com/feed.xml", category: "Development"),
        FeedInfo(title: "Hacking with Swift", url: "https://www.hackingwithswift.com/articles/rss", category: "Development"),
        FeedInfo(title: "iOS Dev Weekly", url: "https://iosdevweekly.com/issues.rss", category: "Development"),
        
        // Business
        FeedInfo(title: "Financial Times", url: "https://www.ft.com/rss/home", category: "Business"),
        FeedInfo(title: "Bloomberg", url: "https://feeds.bloomberg.com/markets/news.rss", category: "Business"),
        FeedInfo(title: "The Economist", url: "https://www.economist.com/feeds/print-sections/all/all.xml", category: "Business"),
        
        // Reddit
        FeedInfo(title: "r/worldnews", url: "https://www.reddit.com/r/worldnews/.rss", category: "Reddit"),
        FeedInfo(title: "r/technology", url: "https://www.reddit.com/r/technology/.rss", category: "Reddit"),
        FeedInfo(title: "r/programming", url: "https://www.reddit.com/r/programming/.rss", category: "Reddit"),
        FeedInfo(title: "r/apple", url: "https://www.reddit.com/r/apple/.rss", category: "Reddit"),
        FeedInfo(title: "r/science", url: "https://www.reddit.com/r/science/.rss", category: "Reddit"),
        
        // Mastodon
        FeedInfo(title: "Mastodon (Trending)", url: "https://mastodon.social/explore.rss", category: "Mastodon"),
        FeedInfo(title: "#technology", url: "https://mastodon.social/tags/technology.rss", category: "Mastodon"),
        FeedInfo(title: "#opensource", url: "https://mastodon.social/tags/opensource.rss", category: "Mastodon"),
        
        // Lemmy
        FeedInfo(title: "Lemmy World", url: "https://lemmy.world/feeds/all.xml", category: "Lemmy"),
        FeedInfo(title: "c/technology", url: "https://lemmy.world/feeds/c/technology.xml", category: "Lemmy"),
        FeedInfo(title: "c/programming", url: "https://lemmy.world/feeds/c/programming.xml", category: "Lemmy")
    ]
    
    static var categories: [String] {
        Array(Set(feeds.map { $0.category })).sorted()
    }
    
    static func feeds(for category: String) -> [FeedInfo] {
        feeds.filter { $0.category == category }
    }
}
