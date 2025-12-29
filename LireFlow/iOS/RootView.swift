#if os(iOS)
import SwiftUI

/// Root view for iOS that adapts between iPhone (TabView) and iPad (NavigationSplitView)
struct RootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        if horizontalSizeClass == .regular {
            // iPad: Use full NavigationSplitView like macOS
            ContentView()
        } else {
            // iPhone: Use TabView
            TabView {
                ContentView()
                    .tabItem {
                        Label("Feeds", systemImage: "newspaper")
                    }
                
                SettingsSheet()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Feed.self, Article.self, Folder.self], inMemory: true)
}
#endif
