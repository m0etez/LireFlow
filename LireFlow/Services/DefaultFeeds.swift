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
    
    // MARK: - Europresse-Compatible French National Press
    static let europresseFranceNational: [FeedInfo] = [
        FeedInfo(title: "Le Monde - La Une", url: "https://www.lemonde.fr/rss/une.xml", category: "News", europresseSupported: true),
        FeedInfo(title: "Le Figaro - Actualité", url: "https://www.lefigaro.fr/rss/figaro_actualites.xml", category: "News", europresseSupported: true),
        FeedInfo(title: "Libération", url: "https://www.liberation.fr/arc/outboundfeeds/rss/?outputType=xml", category: "News", europresseSupported: true),
        FeedInfo(title: "L'Express", url: "https://www.lexpress.fr/arc/outboundfeeds/rss/alaune.xml", category: "News", europresseSupported: true),
        FeedInfo(title: "Le Point", url: "https://www.lepoint.fr/rss.xml", category: "News", europresseSupported: true),
        FeedInfo(title: "L'Obs", url: "https://www.nouvelobs.com/rss.xml", category: "News", europresseSupported: true),
        FeedInfo(title: "Les Échos", url: "https://www.lesechos.fr/rss/rss_une.xml", category: "News", europresseSupported: true),
        FeedInfo(title: "La Croix", url: "https://www.la-croix.com/RSS/UNIVERS", category: "News", europresseSupported: true),
        FeedInfo(title: "L'Humanité", url: "https://www.humanite.fr/rss.xml", category: "News", europresseSupported: true),
        FeedInfo(title: "Le Monde Diplomatique", url: "https://www.monde-diplomatique.fr/recents.xml", category: "News", europresseSupported: true),
        FeedInfo(title: "Courrier International", url: "https://www.courrierinternational.com/feed/all/rss.xml", category: "News", europresseSupported: true),
        FeedInfo(title: "La Tribune", url: "https://www.latribune.fr/rss/rubriques/economie.html", category: "News", europresseSupported: true),
        FeedInfo(title: "L'Opinion", url: "https://www.lopinion.fr/rss.xml", category: "News", europresseSupported: true),
        FeedInfo(title: "Challenges", url: "https://www.challenges.fr/rss.xml", category: "News", europresseSupported: true),
        FeedInfo(title: "Mediapart", url: "https://www.mediapart.fr/articles/feed", category: "News", europresseSupported: true),
        FeedInfo(title: "Arrêt sur Images", url: "https://www.arretsurimages.net/feed", category: "News", europresseSupported: true),
        FeedInfo(title: "L'Usine Nouvelle", url: "https://www.usinenouvelle.com/rss/", category: "News", europresseSupported: true),
        FeedInfo(title: "Télérama", url: "https://www.telerama.fr/rss/actualite.xml", category: "News", europresseSupported: true),
    ]
    
    // MARK: - Europresse-Compatible French Regional Press
    static let europresseFranceRegional: [FeedInfo] = [
        FeedInfo(title: "Le Parisien", url: "https://www.leparisien.fr/arc/outboundfeeds/rss/", category: "Regional News", europresseSupported: true),
        FeedInfo(title: "Ouest-France", url: "https://www.ouest-france.fr/rss/une", category: "Regional News", europresseSupported: true),
        FeedInfo(title: "Sud Ouest", url: "https://www.sudouest.fr/rss.xml", category: "Regional News", europresseSupported: true),
        FeedInfo(title: "La Dépêche du Midi", url: "https://www.ladepeche.fr/rss.xml", category: "Regional News", europresseSupported: true),
        FeedInfo(title: "La Voix du Nord", url: "https://www.lavoixdunord.fr/rss", category: "Regional News", europresseSupported: true),
        FeedInfo(title: "La Provence", url: "https://www.laprovence.com/rss/rss-une.xml", category: "Regional News", europresseSupported: true),
        FeedInfo(title: "Nice-Matin", url: "https://www.nicematin.com/rss", category: "Regional News", europresseSupported: true),
        FeedInfo(title: "Corse Matin", url: "https://www.corsematin.com/rss", category: "Regional News", europresseSupported: true),
        FeedInfo(title: "L'Est Républicain", url: "https://www.estrepublicain.fr/rss", category: "Regional News", europresseSupported: true),
        FeedInfo(title: "Le Télégramme", url: "https://www.letelegramme.fr/rss.xml", category: "Regional News", europresseSupported: true),
        FeedInfo(title: "Le Progrès", url: "https://www.leprogres.fr/rss", category: "Regional News", europresseSupported: true),
        FeedInfo(title: "La Montagne", url: "https://www.lamontagne.fr/rss.xml", category: "Regional News", europresseSupported: true),
        FeedInfo(title: "Le Berry Républicain", url: "https://www.leberry.fr/rss.xml", category: "Regional News", europresseSupported: true),
        FeedInfo(title: "La Nouvelle République", url: "https://www.lanouvellerepublique.fr/rss", category: "Regional News", europresseSupported: true),
        FeedInfo(title: "La République des Pyrénées", url: "https://www.larepubliquedespyrenees.fr/rss.xml", category: "Regional News", europresseSupported: true),
        FeedInfo(title: "Courrier des Maires", url: "https://www.courrierdesmaires.fr/feed/", category: "Regional News", europresseSupported: true),
    ]
    
    // MARK: - Europresse-Compatible French Science & Tech
    static let europresseFranceScience: [FeedInfo] = [
        FeedInfo(title: "Sciences et Avenir", url: "https://www.sciencesetavenir.fr/rss.xml", category: "Science", europresseSupported: true),
        FeedInfo(title: "La Recherche", url: "https://www.larecherche.fr/rss.xml", category: "Science", europresseSupported: true),
        FeedInfo(title: "Science et Vie", url: "https://www.science-et-vie.com/feed", category: "Science", europresseSupported: true),
        FeedInfo(title: "Journal du Net", url: "https://www.journaldunet.com/rss/", category: "Tech", europresseSupported: true),
        FeedInfo(title: "LSA Conso", url: "https://www.lsa-conso.fr/rss", category: "Business", europresseSupported: true),
    ]
    
    // MARK: - Europresse-Compatible Belgium
    static let europresseBelgium: [FeedInfo] = [
        FeedInfo(title: "Le Soir (Belgium)", url: "https://www.lesoir.be/rss/cible_principale_droite.xml", category: "Belgium News", europresseSupported: true),
        FeedInfo(title: "La Libre Belgique", url: "https://www.lalibre.be/rss/section/actu.xml", category: "Belgium News", europresseSupported: true),
        FeedInfo(title: "L'Avenir (Belgium)", url: "https://www.lavenir.net/rss", category: "Belgium News", europresseSupported: true),
        FeedInfo(title: "La DH (Belgium)", url: "https://www.dhnet.be/rss/section/actu.xml", category: "Belgium News", europresseSupported: true),
        FeedInfo(title: "Sudinfo (Belgium)", url: "https://www.sudinfo.be/rss", category: "Belgium News", europresseSupported: true),
        FeedInfo(title: "Le Vif (Belgium)", url: "https://www.levif.be/rss.xml", category: "Belgium News", europresseSupported: true),
        FeedInfo(title: "Trends-Tendances", url: "https://trends.levif.be/rss.xml", category: "Belgium Business", europresseSupported: true),
        FeedInfo(title: "Knack (Belgium)", url: "https://www.knack.be/rss.xml", category: "Belgium News", europresseSupported: true),
        FeedInfo(title: "De Morgen (Belgium)", url: "https://www.demorgen.be/rss.xml", category: "Belgium News", europresseSupported: true),
        FeedInfo(title: "De Standaard (Belgium)", url: "https://www.standaard.be/rss/section/1f2838d4-99ea-49f0-9102-138784c7ea7c", category: "Belgium News", europresseSupported: true),
        FeedInfo(title: "Het Laatste Nieuws", url: "https://www.hln.be/rss.xml", category: "Belgium News", europresseSupported: true),
        FeedInfo(title: "Het Nieuwsblad", url: "https://www.nieuwsblad.be/rss/section/1f2838d4-99ea-49f0-9102-138784c7ea7c", category: "Belgium News", europresseSupported: true),
        FeedInfo(title: "Gazet van Antwerpen", url: "https://www.gva.be/rss/section/1f2838d4-99ea-49f0-9102-138784c7ea7c", category: "Belgium News", europresseSupported: true),
    ]
    
    // MARK: - Europresse-Compatible Switzerland & Luxembourg
    static let europresseSwissLux: [FeedInfo] = [
        FeedInfo(title: "Le Temps (Switzerland)", url: "https://www.letemps.ch/rss", category: "Switzerland News", europresseSupported: true),
    ]
    
    // MARK: - Europresse-Compatible International
    static let europresseInternational: [FeedInfo] = [
        FeedInfo(title: "Financial Times", url: "https://www.ft.com/rss/home", category: "International News", europresseSupported: true),
        FeedInfo(title: "The Economist", url: "https://www.economist.com/rss", category: "International News", europresseSupported: true),
        FeedInfo(title: "L'Orient-Le Jour (Lebanon)", url: "https://www.lorientlejour.com/rss", category: "International News", europresseSupported: true),
        FeedInfo(title: "Jeune Afrique", url: "https://www.jeuneafrique.com/feed/", category: "International News", europresseSupported: true),
        FeedInfo(title: "El País (Spain)", url: "https://feeds.elpais.com/mrss-s/pages/ep/site/elpais.com/portada", category: "International News", europresseSupported: true),
    ]
    
    // MARK: - Other French Sources (Not Europresse)
    static let franceTech: [FeedInfo] = [
        FeedInfo(title: "Numerama", url: "https://www.numerama.com/feed/", category: "France Tech"),
        FeedInfo(title: "MacGeneration", url: "https://www.macg.co/rss.xml", category: "France Tech"),
        FeedInfo(title: "01net", url: "https://www.01net.com/rss/info/", category: "France Tech"),
        FeedInfo(title: "Clubic", url: "https://www.clubic.com/feed/", category: "France Tech"),
        FeedInfo(title: "Frandroid", url: "https://www.frandroid.com/feed", category: "France Tech"),
        FeedInfo(title: "Journal du Geek", url: "https://www.journaldugeek.com/feed/", category: "France Tech"),
        FeedInfo(title: "Les Numériques", url: "https://www.lesnumeriques.com/rss.xml", category: "France Tech"),
        FeedInfo(title: "NextINpact", url: "https://www.nextinpact.com/rss/news.xml", category: "France Tech"),
        FeedInfo(title: "Silicon.fr", url: "https://www.silicon.fr/feed", category: "France Tech"),
        FeedInfo(title: "BDM", url: "https://www.blogdumoderateur.com/feed/", category: "France Tech"),
        FeedInfo(title: "Korben", url: "https://korben.info/feed", category: "France Tech"),
    ]
    
    static let franceOther: [FeedInfo] = [
        FeedInfo(title: "France Info", url: "https://www.francetvinfo.fr/titres.rss", category: "France News"),
        FeedInfo(title: "20 Minutes", url: "https://www.20minutes.fr/feeds/rss-une.xml", category: "France News"),
        FeedInfo(title: "France 24", url: "https://www.france24.com/fr/rss", category: "France News"),
        FeedInfo(title: "RFI", url: "https://www.rfi.fr/fr/rss", category: "France News"),
        FeedInfo(title: "Futura Sciences", url: "https://www.futura-sciences.com/rss/actualites.xml", category: "France Science"),
        FeedInfo(title: "L'Équipe", url: "https://www.lequipe.fr/rss/actu_rss.xml", category: "France Sports"),
    ]
    
    // MARK: - Tech
    static let tech: [FeedInfo] = [
        FeedInfo(title: "Hacker News", url: "https://hnrss.org/frontpage", category: "Tech"),
        FeedInfo(title: "The Verge", url: "https://www.theverge.com/rss/index.xml", category: "Tech"),
        FeedInfo(title: "Ars Technica", url: "https://feeds.arstechnica.com/arstechnica/index", category: "Tech"),
        FeedInfo(title: "TechCrunch", url: "https://techcrunch.com/feed/", category: "Tech"),
        FeedInfo(title: "Wired", url: "https://www.wired.com/feed/rss", category: "Tech"),
        FeedInfo(title: "Engadget", url: "https://www.engadget.com/rss.xml", category: "Tech"),
        FeedInfo(title: "GitHub Blog", url: "https://github.blog/feed/", category: "Tech"),
        FeedInfo(title: "MIT Technology Review", url: "https://www.technologyreview.com/feed/", category: "Tech"),
    ]
    
    // MARK: - News International
    static let newsInternational: [FeedInfo] = [
        FeedInfo(title: "BBC News", url: "https://feeds.bbci.co.uk/news/rss.xml", category: "News"),
        FeedInfo(title: "Reuters", url: "https://www.reutersagency.com/feed/", category: "News"),
        FeedInfo(title: "NPR News", url: "https://feeds.npr.org/1001/rss.xml", category: "News"),
        FeedInfo(title: "The Guardian", url: "https://www.theguardian.com/world/rss", category: "News"),
        FeedInfo(title: "Al Jazeera", url: "https://www.aljazeera.com/xml/rss/all.xml", category: "News"),
    ]
    
    // MARK: - Apple & Development
    static let appleDev: [FeedInfo] = [
        FeedInfo(title: "Daring Fireball", url: "https://daringfireball.net/feeds/main", category: "Apple"),
        FeedInfo(title: "Six Colors", url: "https://feedpress.me/sixcolors", category: "Apple"),
        FeedInfo(title: "MacStories", url: "https://www.macstories.net/feed/", category: "Apple"),
        FeedInfo(title: "9to5Mac", url: "https://9to5mac.com/feed/", category: "Apple"),
        FeedInfo(title: "MacRumors", url: "https://feeds.macrumors.com/MacRumors-All", category: "Apple"),
        FeedInfo(title: "Swift by Sundell", url: "https://www.swiftbysundell.com/rss", category: "Development"),
        FeedInfo(title: "Hacking with Swift", url: "https://www.hackingwithswift.com/articles/rss", category: "Development"),
    ]
    
    // MARK: - Other categories
    static let other: [FeedInfo] = [
        // Science
        FeedInfo(title: "Nature", url: "https://www.nature.com/nature.rss", category: "Science"),
        FeedInfo(title: "Science Daily", url: "https://www.sciencedaily.com/rss/all.xml", category: "Science"),
        
        // AI
        FeedInfo(title: "OpenAI Blog", url: "https://openai.com/blog/rss/", category: "AI"),
        FeedInfo(title: "Anthropic News", url: "https://www.anthropic.com/news/rss.xml", category: "AI"),
        
        // Security
        FeedInfo(title: "Krebs on Security", url: "https://krebsonsecurity.com/feed/", category: "Security"),
        FeedInfo(title: "Schneier on Security", url: "https://www.schneier.com/feed/atom/", category: "Security"),
        
        // Space
        FeedInfo(title: "NASA Breaking News", url: "https://www.nasa.gov/rss/dyn/breaking_news.rss", category: "Space"),
        FeedInfo(title: "ESA", url: "https://www.esa.int/rssfeed/Our_Activities/Space_News", category: "Space"),
        
        // Reddit
        FeedInfo(title: "r/worldnews", url: "https://www.reddit.com/r/worldnews/.rss", category: "Reddit"),
        FeedInfo(title: "r/technology", url: "https://www.reddit.com/r/technology/.rss", category: "Reddit"),
        FeedInfo(title: "r/programming", url: "https://www.reddit.com/r/programming/.rss", category: "Reddit"),
    ]
    
    // MARK: - All feeds combined
    static let feeds: [FeedInfo] = {
        var all: [FeedInfo] = []
        // Europresse-compatible feeds first (highlighted)
        all.append(contentsOf: europresseFranceNational)
        all.append(contentsOf: europresseFranceRegional)
        all.append(contentsOf: europresseFranceScience)
        all.append(contentsOf: europresseBelgium)
        all.append(contentsOf: europresseSwissLux)
        all.append(contentsOf: europresseInternational)
        // Other feeds
        all.append(contentsOf: franceTech)
        all.append(contentsOf: franceOther)
        all.append(contentsOf: tech)
        all.append(contentsOf: newsInternational)
        all.append(contentsOf: appleDev)
        all.append(contentsOf: other)
        return all
    }()
    
    static var categories: [String] {
        Array(Set(feeds.map { $0.category })).sorted()
    }
    
    static func feeds(for category: String) -> [FeedInfo] {
        feeds.filter { $0.category == category }
    }
    
    // MARK: - Europresse Domain Detection
    
    /// Domains of news sources available on Europresse (from Ophirofox)
    static let europresseDomains: Set<String> = [
        // France - National
        "lemonde.fr",
        "lefigaro.fr",
        "liberation.fr",
        "lexpress.fr",
        "lepoint.fr",
        "nouvelobs.com",
        "lesechos.fr",
        "la-croix.com",
        "humanite.fr",
        "monde-diplomatique.fr",
        "courrierinternational.com",
        "latribune.fr",
        "lopinion.fr",
        "challenges.fr",
        "mediapart.fr",
        "arretsurimages.net",
        "usinenouvelle.com",
        "telerama.fr",
        
        // France - Regional
        "leparisien.fr",
        "ouest-france.fr",
        "sudouest.fr",
        "ladepeche.fr",
        "lavoixdunord.fr",
        "laprovence.com",
        "nicematin.com",
        "corsematin.com",
        "estrepublicain.fr",
        "letelegramme.fr",
        "leprogres.fr",
        "lamontagne.fr",
        "leberry.fr",
        "lanouvellerepublique.fr",
        "larepubliquedespyrenees.fr",
        "courrierdesmaires.fr",
        
        // France - Science
        "sciencesetavenir.fr",
        "larecherche.fr",
        "science-et-vie.com",
        "journaldunet.com",
        "lsa-conso.fr",
        
        // Belgium
        "lesoir.be",
        "lalibre.be",
        "lavenir.net",
        "dhnet.be",
        "sudinfo.be",
        "levif.be",
        "trends.levif.be",
        "knack.be",
        "demorgen.be",
        "standaard.be",
        "hln.be",
        "nieuwsblad.be",
        "gva.be",
        
        // Switzerland
        "letemps.ch",
        
        // International
        "ft.com",
        "economist.com",
        "lorientlejour.com",
        "jeuneafrique.com",
        "elpais.com",
        
        // Other French sources on Europresse
        "acteurspublics.fr",
        "investir.lesechos.fr",
        "pressreader.com",
        "lettreaudiovisuel.com",
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
