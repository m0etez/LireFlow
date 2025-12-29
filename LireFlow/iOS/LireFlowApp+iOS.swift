#if os(iOS)
import SwiftUI
import SwiftData

@main
struct LireFlowApp: App {
    @StateObject private var storeService = StoreService.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(storeService)
        }
        .modelContainer(LireFlowAppCore.sharedModelContainer)
    }
}
#endif
