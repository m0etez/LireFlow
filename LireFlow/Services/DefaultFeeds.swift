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
        FeedInfo(title: "GitHub Blog", url: "https://github.blog/feed/", category: "Tech"),
        FeedInfo(title: "MIT Technology Review", url: "https://www.technologyreview.com/feed/", category: "Tech"),
        FeedInfo(title: "The Next Web", url: "https://thenextweb.com/feed/", category: "Tech"),
        FeedInfo(title: "VentureBeat", url: "https://venturebeat.com/feed/", category: "Tech"),
        FeedInfo(title: "Slashdot", url: "http://rss.slashdot.org/Slashdot/slashdotMain", category: "Tech"),
        
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
        FeedInfo(title: "L'Express", url: "https://www.lexpress.fr/arc/outboundfeeds/rss/alaune.xml", category: "France"),
        FeedInfo(title: "Le Point", url: "https://www.lepoint.fr/feed/", category: "France"),
        FeedInfo(title: "L'Obs", url: "https://www.nouvelobs.com/rss.xml", category: "France"),
        FeedInfo(title: "Marianne", url: "https://www.marianne.net/rss.xml", category: "France"),
        FeedInfo(title: "Les Échos", url: "https://www.lesechos.fr/rss/all.xml", category: "France"),
        FeedInfo(title: "Mediapart", url: "https://www.mediapart.fr/articles/feed", category: "France"),
        FeedInfo(title: "Courrier International", url: "https://www.courrierinternational.com/feed/all/rss.xml", category: "France"),
        FeedInfo(title: "Rue89", url: "https://www.nouvelobs.com/rue89/rss.xml", category: "France"),
        FeedInfo(title: "France 24", url: "https://www.france24.com/fr/rss", category: "France"),
        FeedInfo(title: "RFI", url: "https://www.rfi.fr/fr/rss", category: "France"),
        FeedInfo(title: "L'Humanité", url: "https://www.humanite.fr/rss.xml", category: "France"),
        FeedInfo(title: "La Croix", url: "https://www.la-croix.com/RSS/UNIVERS", category: "France"),

        // France - Tech
        FeedInfo(title: "Numerama", url: "https://www.numerama.com/feed/", category: "France Tech"),
        FeedInfo(title: "01net", url: "https://www.01net.com/rss/info/", category: "France Tech"),
        FeedInfo(title: "Clubic", url: "https://www.clubic.com/feed/", category: "France Tech"),
        FeedInfo(title: "Frandroid", url: "https://www.frandroid.com/feed", category: "France Tech"),
        FeedInfo(title: "Journal du Geek", url: "https://www.journaldugeek.com/feed/", category: "France Tech"),
        FeedInfo(title: "Les Numériques", url: "https://www.lesnumeriques.com/rss.xml", category: "France Tech"),
        FeedInfo(title: "NextINpact", url: "https://www.nextinpact.com/rss/news.xml", category: "France Tech"),
        FeedInfo(title: "Silicon.fr", url: "https://www.silicon.fr/feed", category: "France Tech"),
        FeedInfo(title: "BDM", url: "https://www.blogdumoderateur.com/feed/", category: "France Tech"),
        FeedInfo(title: "Korben", url: "https://korben.info/feed", category: "France Tech"),

        // France - Culture & Lifestyle
        FeedInfo(title: "Télérama", url: "https://www.telerama.fr/rss.xml", category: "France Culture"),
        FeedInfo(title: "Les Inrockuptibles", url: "https://www.lesinrocks.com/feed/", category: "France Culture"),
        FeedInfo(title: "Première", url: "https://www.premiere.fr/rss", category: "France Culture"),
        FeedInfo(title: "Allociné", url: "https://rss.allocine.fr/ac/cine/cine", category: "France Culture"),
        FeedInfo(title: "Madmoizelle", url: "https://www.madmoizelle.com/feed/", category: "France Culture"),

        // France - Science
        FeedInfo(title: "Futura Sciences", url: "https://www.futura-sciences.com/rss/actualites.xml", category: "France Science"),
        FeedInfo(title: "Sciences et Avenir", url: "https://www.sciencesetavenir.fr/rss.xml", category: "France Science"),
        FeedInfo(title: "Pour la Science", url: "https://www.pourlascience.fr/rss/actualites.xml", category: "France Science"),
        FeedInfo(title: "La Recherche", url: "https://www.larecherche.fr/feed", category: "France Science"),

        // France - Sports
        FeedInfo(title: "L'Équipe", url: "https://www.lequipe.fr/rss/actu_rss.xml", category: "France Sports"),
        FeedInfo(title: "So Foot", url: "https://www.sofoot.com/rss.xml", category: "France Sports"),
        FeedInfo(title: "Le 10 Sport", url: "https://le10sport.com/rss", category: "France Sports"),
        
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
        FeedInfo(title: "c/programming", url: "https://lemmy.world/feeds/c/programming.xml", category: "Lemmy"),

        // Security & Privacy
        FeedInfo(title: "Krebs on Security", url: "https://krebsonsecurity.com/feed/", category: "Security"),
        FeedInfo(title: "Schneier on Security", url: "https://www.schneier.com/feed/atom/", category: "Security"),
        FeedInfo(title: "Threatpost", url: "https://threatpost.com/feed/", category: "Security"),
        FeedInfo(title: "Bleeping Computer", url: "https://www.bleepingcomputer.com/feed/", category: "Security"),
        FeedInfo(title: "The Hacker News", url: "https://feeds.feedburner.com/TheHackersNews", category: "Security"),

        // AI & Machine Learning
        FeedInfo(title: "OpenAI Blog", url: "https://openai.com/blog/rss/", category: "AI"),
        FeedInfo(title: "DeepMind Blog", url: "https://deepmind.google/blog/rss.xml", category: "AI"),
        FeedInfo(title: "Anthropic News", url: "https://www.anthropic.com/news/rss.xml", category: "AI"),
        FeedInfo(title: "Papers with Code", url: "https://paperswithcode.com/feed.xml", category: "AI"),
        FeedInfo(title: "Towards Data Science", url: "https://towardsdatascience.com/feed", category: "AI"),

        // Design
        FeedInfo(title: "Smashing Magazine", url: "https://www.smashingmagazine.com/feed/", category: "Design"),
        FeedInfo(title: "A List Apart", url: "https://alistapart.com/main/feed/", category: "Design"),
        FeedInfo(title: "CSS-Tricks", url: "https://css-tricks.com/feed/", category: "Design"),
        FeedInfo(title: "Codrops", url: "https://tympanus.net/codrops/feed/", category: "Design"),
        FeedInfo(title: "Dribbble", url: "https://dribbble.com/shots.rss", category: "Design"),

        // Gaming
        FeedInfo(title: "IGN", url: "https://feeds.ign.com/ign/all", category: "Gaming"),
        FeedInfo(title: "GameSpot", url: "https://www.gamespot.com/feeds/mashup/", category: "Gaming"),
        FeedInfo(title: "Polygon", url: "https://www.polygon.com/rss/index.xml", category: "Gaming"),
        FeedInfo(title: "Kotaku", url: "https://kotaku.com/rss", category: "Gaming"),
        FeedInfo(title: "PC Gamer", url: "https://www.pcgamer.com/rss/", category: "Gaming"),

        // Crypto & Web3
        FeedInfo(title: "CoinDesk", url: "https://www.coindesk.com/arc/outboundfeeds/rss/", category: "Crypto"),
        FeedInfo(title: "Cointelegraph", url: "https://cointelegraph.com/rss", category: "Crypto"),
        FeedInfo(title: "Decrypt", url: "https://decrypt.co/feed", category: "Crypto"),
        FeedInfo(title: "The Block", url: "https://www.theblockcrypto.com/rss.xml", category: "Crypto"),

        // Productivity & Lifehacks
        FeedInfo(title: "Lifehacker", url: "https://lifehacker.com/rss", category: "Productivity"),
        FeedInfo(title: "Zen Habits", url: "https://zenhabits.net/feed/", category: "Productivity"),
        FeedInfo(title: "Getting Things Done", url: "https://gettingthingsdone.com/feed/", category: "Productivity"),
        FeedInfo(title: "James Clear", url: "https://jamesclear.com/feed", category: "Productivity"),

        // Entertainment & Culture
        FeedInfo(title: "The Atlantic", url: "https://www.theatlantic.com/feed/all/", category: "Culture"),
        FeedInfo(title: "The New Yorker", url: "https://www.newyorker.com/feed/everything", category: "Culture"),
        FeedInfo(title: "Pitchfork", url: "https://pitchfork.com/rss/reviews/albums/", category: "Culture"),
        FeedInfo(title: "Rolling Stone", url: "https://www.rollingstone.com/feed/", category: "Culture"),
        FeedInfo(title: "Variety", url: "https://variety.com/feed/", category: "Culture"),

        // Podcasts
        FeedInfo(title: "The Daily (NYT)", url: "https://feeds.simplecast.com/54nAGcIl", category: "Podcasts"),
        FeedInfo(title: "99% Invisible", url: "https://feeds.99percentinvisible.org/99percentinvisible", category: "Podcasts"),
        FeedInfo(title: "Radiolab", url: "https://feeds.feedburner.com/radiolab", category: "Podcasts"),
        FeedInfo(title: "Planet Money", url: "https://feeds.npr.org/510289/podcast.xml", category: "Podcasts"),

        // Space & Astronomy
        FeedInfo(title: "NASA", url: "https://www.nasa.gov/rss/dyn/breaking_news.rss", category: "Space"),
        FeedInfo(title: "Space.com", url: "https://www.space.com/feeds/all", category: "Space"),
        FeedInfo(title: "Universe Today", url: "https://www.universetoday.com/feed/", category: "Space"),
        FeedInfo(title: "ESA", url: "https://www.esa.int/rssfeed/Our_Activities/Space_News", category: "Space"),

        // Sports
        FeedInfo(title: "ESPN", url: "https://www.espn.com/espn/rss/news", category: "Sports"),
        FeedInfo(title: "The Athletic", url: "https://theathletic.com/feeds/rss/news/", category: "Sports"),
        FeedInfo(title: "Bleacher Report", url: "https://bleacherreport.com/articles/feed", category: "Sports"),

        // Photography
        FeedInfo(title: "PetaPixel", url: "https://petapixel.com/feed/", category: "Photography"),
        FeedInfo(title: "DPReview", url: "https://www.dpreview.com/feeds/news.xml", category: "Photography"),
        FeedInfo(title: "Fstoppers", url: "https://fstoppers.com/rss.xml", category: "Photography")
    ]
    
    static var categories: [String] {
        Array(Set(feeds.map { $0.category })).sorted()
    }
    
    static func feeds(for category: String) -> [FeedInfo] {
        feeds.filter { $0.category == category }
    }
}
