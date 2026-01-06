import Foundation

/// Pre-configured default feeds
/// Feeds marked with europresseSupported can be read via Europresse integration
struct DefaultFeeds {
    
    struct FeedInfo {
        let title: String
        let url: String
        let category: String
        let europresseSupported: Bool
        
        init(title: String, url: String, category: String, europresseSupported: Bool = false) {
            self.title = title
            self.url = url
            self.category = category
            self.europresseSupported = europresseSupported
        }
    }
    
    // MARK: - France (Combined National & Regional)
    static let franceNews: [FeedInfo] = [
        FeedInfo(title: "Le Monde", url: "https://www.lemonde.fr/rss/une.xml", category: "News (France)", europresseSupported: true),
        FeedInfo(title: "Le Figaro", url: "https://www.lefigaro.fr/rss/figaro_actualites.xml", category: "News (France)", europresseSupported: true),
        FeedInfo(title: "Libération", url: "https://www.liberation.fr/arc/outboundfeeds/rss/?outputType=xml", category: "News (France)", europresseSupported: true),
        FeedInfo(title: "Ouest-France", url: "https://www.ouest-france.fr/rss/une", category: "News (France)", europresseSupported: true),
        FeedInfo(title: "France Info", url: "https://www.francetvinfo.fr/titres.rss", category: "News (France)"),
        FeedInfo(title: "20 Minutes", url: "https://www.20minutes.fr/feeds/rss-une.xml", category: "News (France)"),
    ]

    // MARK: - United States
    static let usNews: [FeedInfo] = [
        FeedInfo(title: "The New York Times", url: "https://rss.nytimes.com/services/xml/rss/nyt/HomePage.xml", category: "News (USA)", europresseSupported: true),
        FeedInfo(title: "CNN", url: "http://rss.cnn.com/rss/cnn_topstories.rss", category: "News (USA)"),
        FeedInfo(title: "The Washington Post", url: "https://feeds.washingtonpost.com/rss/world", category: "News (USA)", europresseSupported: true),
        FeedInfo(title: "Fox News", url: "http://feeds.foxnews.com/foxnews/latest", category: "News (USA)"),
        FeedInfo(title: "NPR", url: "https://feeds.npr.org/1001/rss.xml", category: "News (USA)"),
    ]

    // MARK: - United Kingdom
    static let ukNews: [FeedInfo] = [
        FeedInfo(title: "BBC News", url: "http://feeds.bbci.co.uk/news/rss.xml", category: "News (UK)", europresseSupported: true),
        FeedInfo(title: "The Guardian", url: "https://www.theguardian.com/world/rss", category: "News (UK)", europresseSupported: true),
        FeedInfo(title: "Sky News", url: "https://feeds.skynews.com/feeds/rss/home.xml", category: "News (UK)"),
        FeedInfo(title: "The Independent", url: "https://www.independent.co.uk/news/rss", category: "News (UK)", europresseSupported: true),
        FeedInfo(title: "Financial Times", url: "https://www.ft.com/rss/home", category: "News (UK)", europresseSupported: true),
    ]

    // MARK: - Germany
    static let germanyNews: [FeedInfo] = [
        FeedInfo(title: "Tagesschau", url: "https://www.tagesschau.de/xml/rss2/", category: "News (Germany)"),
        FeedInfo(title: "Der Spiegel", url: "https://www.spiegel.de/schlagzeilen/rss/index.xml", category: "News (Germany)", europresseSupported: true),
        FeedInfo(title: "FAZ", url: "https://www.faz.net/rss/aktuell/", category: "News (Germany)", europresseSupported: true),
        FeedInfo(title: "Süddeutsche Zeitung", url: "https://rss.sueddeutsche.de/rss/Topthemen", category: "News (Germany)", europresseSupported: true),
    ]

    // MARK: - Belgium
    static let belgiumNews: [FeedInfo] = [
        FeedInfo(title: "La Libre", url: "https://www.lalibre.be/rss.xml", category: "News (Belgium)", europresseSupported: true),
        FeedInfo(title: "HLN", url: "https://www.hln.be/rss.xml", category: "News (Belgium)", europresseSupported: true),
        FeedInfo(title: "VRT NWS", url: "https://www.vrt.be/vrtnws/nl.rss.articles.xml", category: "News (Belgium)"),
    ]

    // MARK: - Spain
    static let spainNews: [FeedInfo] = [
        FeedInfo(title: "El País", url: "https://feeds.elpais.com/mrss-s/pages/ep/site/elpais.com/portada", category: "News (Spain)", europresseSupported: true),
        FeedInfo(title: "El Mundo", url: "https://e00-elmundo.uecdn.es/elmundo/rss/portada.xml", category: "News (Spain)", europresseSupported: true),
        FeedInfo(title: "La Vanguardia", url: "https://www.lavanguardia.com/rss/home.xml", category: "News (Spain)", europresseSupported: true),
        FeedInfo(title: "20minutos", url: "https://www.20minutos.es/rss/", category: "News (Spain)"),
    ]

    // MARK: - Italy
    static let italyNews: [FeedInfo] = [
        FeedInfo(title: "La Repubblica", url: "https://www.repubblica.it/rss/homepage/rss2.0.xml", category: "News (Italy)", europresseSupported: true),
        FeedInfo(title: "Corriere della Sera", url: "https://www.corriere.it/rss/homepage.xml", category: "News (Italy)", europresseSupported: true),
        FeedInfo(title: "ANSA", url: "https://www.ansa.it/sito/ansait_rss.xml", category: "News (Italy)"),
        FeedInfo(title: "Il Sole 24 Ore", url: "https://www.ilsole24ore.com/rss/italia.xml", category: "News (Italy)", europresseSupported: true),
    ]

    // MARK: - Switzerland
    static let switzerlandNews: [FeedInfo] = [
        FeedInfo(title: "Le Temps", url: "https://www.letemps.ch/rss", category: "News (Switzerland)", europresseSupported: true),
        FeedInfo(title: "NZZ", url: "https://www.nzz.ch/recent.rss", category: "News (Switzerland)", europresseSupported: true),
        FeedInfo(title: "Tages-Anzeiger", url: "https://partner-feeds.publishing.tamedia.ch/rss/tagesanzeiger/schweiz", category: "News (Switzerland)", europresseSupported: true),
    ]

    // MARK: - Canada
    static let canadaNews: [FeedInfo] = [
        FeedInfo(title: "CBC News", url: "https://www.cbc.ca/webfeed/rss/rss-topstories", category: "News (Canada)"),
    ]

    // MARK: - Tech & Science
    static let techScience: [FeedInfo] = [
        FeedInfo(title: "The Verge", url: "https://www.theverge.com/rss/index.xml", category: "Tech"),
        FeedInfo(title: "Ars Technica", url: "https://feeds.arstechnica.com/arstechnica/index", category: "Tech"),
        FeedInfo(title: "Hacker News", url: "https://hnrss.org/frontpage", category: "Tech"),
        FeedInfo(title: "TechCrunch", url: "https://techcrunch.com/feed/", category: "Tech"),
        FeedInfo(title: "Numerama", url: "https://www.numerama.com/feed/", category: "Tech"),
        FeedInfo(title: "Frandroid", url: "https://www.frandroid.com/feed", category: "Tech"),
        FeedInfo(title: "MacGeneration", url: "http://rss.macg.co", category: "Apple"),
        FeedInfo(title: "9to5Mac", url: "https://9to5mac.com/feed/", category: "Apple"),
        FeedInfo(title: "MacRumors", url: "https://feeds.macrumors.com/MacRumors-All", category: "Apple"),
        FeedInfo(title: "Science & Vie", url: "https://www.science-et-vie.com/feed", category: "Science", europresseSupported: true),
    ]
    
    // MARK: - Arts & Design
    static let artsDesign: [FeedInfo] = [
        FeedInfo(title: "Colossal", url: "https://www.thisiscolossal.com/feed/", category: "Arts & Design"),
        FeedInfo(title: "Hyperallergic", url: "https://hyperallergic.com/feed/", category: "Arts & Design"),
        FeedInfo(title: "Dezeen", url: "https://www.dezeen.com/feed/", category: "Arts & Design"),
        FeedInfo(title: "Designboom", url: "https://www.designboom.com/feed/", category: "Arts & Design"),
        FeedInfo(title: "Booooooom", url: "https://www.booooooom.com/feed/", category: "Arts & Design"),
        FeedInfo(title: "Juxtapoz", url: "https://www.juxtapoz.com/feed/", category: "Arts & Design"),
        FeedInfo(title: "Artsy", url: "https://www.artsy.net/rss/news", category: "Arts & Design"),
        FeedInfo(title: "My Modern Met", url: "https://mymodernmet.com/feed/", category: "Arts & Design"),
        FeedInfo(title: "Creative Bloq", url: "https://www.creativebloq.com/feeds.xml", category: "Arts & Design"),
    ]
    
    // MARK: - Fashion
    static let fashion: [FeedInfo] = [
        FeedInfo(title: "Vogue", url: "https://www.vogue.com/feed/rss", category: "Fashion"),
        FeedInfo(title: "W Magazine", url: "https://www.wmagazine.com/rss", category: "Fashion"),
        FeedInfo(title: "Elle Fashion", url: "https://www.elle.com/rss/fashion.xml", category: "Fashion"),
    ]
    
    // MARK: - Crafts & DIY
    static let crafts: [FeedInfo] = [
        FeedInfo(title: "CraftGossip", url: "https://craftgossip.com/feed", category: "Crafts & DIY"),
    ]
    
    // MARK: - Sports
    static let sports: [FeedInfo] = [
        FeedInfo(title: "Sport.fr", url: "https://www.sport.fr/rss", category: "Sports"),
    ]

    // MARK: - All feeds combined
    static let feeds: [FeedInfo] = {
        var all: [FeedInfo] = []
        all.append(contentsOf: franceNews)
        all.append(contentsOf: usNews)
        all.append(contentsOf: ukNews)
        all.append(contentsOf: germanyNews)
        all.append(contentsOf: belgiumNews)
        all.append(contentsOf: spainNews)
        all.append(contentsOf: italyNews)
        all.append(contentsOf: switzerlandNews)
        all.append(contentsOf: canadaNews)
        all.append(contentsOf: techScience)
        all.append(contentsOf: artsDesign)
        all.append(contentsOf: fashion)
        all.append(contentsOf: crafts)
        all.append(contentsOf: sports)
        return all
    }()
    
    // Custom sort order for categories
    static var categories: [String] {
        let order: [String] = [
            "News (France)",
            "News (Belgium)",
            "News (Switzerland)",
            "News (Canada)",
            "News (USA)",
            "News (UK)",
            "News (Germany)",
            "News (Spain)",
            "News (Italy)",
            "Tech",
            "Apple",
            "Science",
            "Arts & Design",
            "Fashion",
            "Crafts & DIY",
            "Sports"
        ]
        
        // Get all unique categories present in feeds
        let available = Set(feeds.map { $0.category })
        
        // Return ordered categories that exist, followed by any others sorted alphabetically
        let knownSorted = order.filter { available.contains($0) }
        let others = available.filter { !order.contains($0) }.sorted()
        
        return knownSorted + others
    }
    
    static func feeds(for category: String) -> [FeedInfo] {
        feeds.filter { $0.category == category }
    }
    
    // MARK: - Europresse Domain Detection
    
    /// Domains of news sources available on Europresse
    static let europresseDomains: Set<String> = [
        // France
        "lemonde.fr", "lefigaro.fr", "liberation.fr", "lexpress.fr", "lepoint.fr", "nouvelobs.com",
        "lesechos.fr", "la-croix.com", "humanite.fr", "monde-diplomatique.fr", "courrierinternational.com",
        "latribune.fr", "lopinion.fr", "challenges.fr", "mediapart.fr", "arretsurimages.net",
        "usinenouvelle.com", "telerama.fr", "leparisien.fr", "ouest-france.fr", "sudouest.fr",
        "ladepeche.fr", "lavoixdunord.fr", "laprovence.com", "nicematin.com", "corsematin.com",
        "estrepublicain.fr", "letelegramme.fr", "leprogres.fr", "lamontagne.fr", "leberry.fr",
        "lanouvellerepublique.fr", "larepubliquedespyrenees.fr", "courrierdesmaires.fr",
        "sciencesetavenir.fr", "larecherche.fr", "science-et-vie.com", "journaldunet.com", "lsa-conso.fr",
        
        // Belgium
        "lesoir.be", "lalibre.be", "lavenir.net", "dhnet.be", "sudinfo.be", "levif.be",
        "trends.levif.be", "knack.be", "demorgen.be", "standaard.be", "hln.be", "nieuwsblad.be", "gva.be",
        
        // Switzerland
        "letemps.ch", "nzz.ch", "tagesanzeiger.ch",
        
        // UK/US/International
        "ft.com", "economist.com", "nytimes.com", "washingtonpost.com", "theguardian.com", "independent.co.uk",
        
        // Spain/Italy
        "elpais.com", "elmundo.es", "abc.es", "lavanguardia.com",
        "repubblica.it", "corriere.it", "lastampa.it", "ilsole24ore.com",
        "nationalpost.com", "theglobeandmail.com", "thestar.com"
    ]
    
    /// Check if an article URL is from an Europresse-supported source
    static func isEuropresseSupported(url: String) -> Bool {
        guard let urlObj = URL(string: url),
              let host = urlObj.host?.lowercased() else {
            return false
        }
        
        // Remove www. prefix if present
        let cleanHost = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        
        // Check if domain or parent domain is in the list
        return europresseDomains.contains(cleanHost) ||
               europresseDomains.contains(where: { cleanHost.hasSuffix(".\($0)") || cleanHost == $0 })
    }
}
