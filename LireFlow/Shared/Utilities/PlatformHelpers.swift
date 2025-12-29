import SwiftUI

#if os(macOS)
import AppKit
typealias PlatformColor = NSColor
typealias PlatformApplication = NSApplication
#else
import UIKit
typealias PlatformColor = UIColor
typealias PlatformApplication = UIApplication
#endif

// MARK: - Color Extension

extension Color {
    /// Creates a Color from platform-specific color
    init(platformColor: PlatformColor) {
        #if os(macOS)
        self.init(nsColor: platformColor)
        #else
        self.init(uiColor: platformColor)
        #endif
    }
}

// MARK: - Badge Management

extension PlatformApplication {
    /// Sets the app badge count in a platform-agnostic way
    static func setBadgeCount(_ count: Int) {
        #if os(macOS)
        if count > 0 {
            NSApp.dockTile.badgeLabel = "\(count)"
        } else {
            NSApp.dockTile.badgeLabel = nil
        }
        #else
        Task { @MainActor in
            UNUserNotificationCenter.current().setBadgeCount(count)
        }
        #endif
    }
}

// MARK: - URL Opening

extension PlatformApplication {
    /// Opens a URL in a platform-agnostic way
    static func openURL(_ url: URL) {
        #if os(macOS)
        NSWorkspace.shared.open(url)
        #else
        UIApplication.shared.open(url)
        #endif
    }
}

// MARK: - Pasteboard/Clipboard

struct PlatformPasteboard {
    /// Copies text to clipboard in a platform-agnostic way
    static func copyToClipboard(_ string: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
        #else
        UIPasteboard.general.string = string
        #endif
    }
    
    /// Gets string from clipboard in a platform-agnostic way
    static func getFromClipboard() -> String? {
        #if os(macOS)
        return NSPasteboard.general.string(forType: .string)
        #else
        return UIPasteboard.general.string
        #endif
    }
}

// MARK: - Platform-Specific Colors

extension Color {
    static var platformBackground: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(uiColor: .systemBackground)
        #endif
    }
    
    static var platformSecondaryBackground: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(uiColor: .secondarySystemBackground)
        #endif
    }
    
    static var platformTertiaryBackground: Color {
        #if os(macOS)
        Color(nsColor: .textBackgroundColor)
        #else
        Color(uiColor: .tertiarySystemBackground)
        #endif
    }
    
    static var platformLabel: Color {
        #if os(macOS)
        Color(nsColor: .textColor)
        #else
        Color(uiColor: .label)
        #endif
    }
    
    static var platformSecondaryLabel: Color {
        #if os(macOS)
        Color(nsColor: .secondaryLabelColor)
        #else
        Color(uiColor: .secondaryLabel)
        #endif
    }
}
