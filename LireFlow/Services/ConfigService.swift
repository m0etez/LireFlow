import Foundation

/// Configuration service that saves app settings to a JSON file
/// instead of using UserDefaults for better portability
class ConfigService: ObservableObject {
    static let shared = ConfigService()
    
    @Published var config: AppConfig {
        didSet {
            save()
        }
    }
    
    private var configURL: URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let appFolder = appSupport.appendingPathComponent("LireFlow", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)

        return appFolder.appendingPathComponent("config.json")
    }
    
    private init() {
        self.config = AppConfig()
        load()
    }
    
    func load() {
        guard let configURL = configURL,
              FileManager.default.fileExists(atPath: configURL.path) else { return }

        do {
            let data = try Data(contentsOf: configURL)
            config = try JSONDecoder().decode(AppConfig.self, from: data)
        } catch {
            print("Failed to load config: \(error)")
        }
    }
    
    func save() {
        guard let configURL = configURL else { return }
        do {
            let data = try JSONEncoder().encode(config)
            try data.write(to: configURL, options: .atomic)
        } catch {
            print("Failed to save config: \(error)")
        }
    }
    
    /// Get the config file path (for user reference)
    var configFilePath: String {
        configURL?.path ?? "Unable to determine config path"
    }
}

/// App configuration stored in JSON file
struct AppConfig: Codable {
    var isDarkMode: Bool = false
    var refreshIntervalMinutes: Int = 30
    var showUnreadCount: Bool = true
    var defaultFeedCategory: String = "Tech"
    var articleFontSize: Int = 16
    var markAsReadOnScroll: Bool = true

    // Weather settings
    var showWeather: Bool = true
    var weatherLocation: String? = nil  // nil = auto-detect

    // UI preferences
    var sidebarWidth: Double = 240
    var articleListWidth: Double = 320

    // Performance settings
    var loadImages: Bool = true
    var maxArticlesPerFeed: Int = 500
    var cleanupOldArticlesDays: Int = 30
    var backgroundRefreshEnabled: Bool = true
}
