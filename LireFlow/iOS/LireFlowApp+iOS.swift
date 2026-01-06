#if os(iOS)
import SwiftUI
import SwiftData

@main
struct LireFlowApp: App {
    @StateObject private var storeService = StoreService.shared
    @StateObject private var configService = ConfigService.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(storeService)
                .tint(.blue)
                .environment(\.colorScheme, configService.config.selectedTheme.colorScheme ?? .light)
        }
        .modelContainer(LireFlowAppCore.sharedModelContainer)
    }
}
#endif
