#if os(iOS)
import SwiftUI
import SwiftData

@main
struct LireFlowApp: App {
    @StateObject private var storeService = StoreService.shared
    @ObservedObject private var configService = ConfigService.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(storeService)
                .tint(configService.config.selectedTheme.accentColor)
                .preferredColorScheme(configService.config.selectedTheme.colorScheme)
        }
        .modelContainer(LireFlowAppCore.sharedModelContainer)
    }
}
#endif
