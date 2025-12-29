import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// App theme definitions for LireFlow
/// Uses platform semantic colors for system compliance
enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    case sepia = "sepia"      // Pro
    case nord = "nord"        // Pro
    case ocean = "ocean"      // Pro
    case forest = "forest"    // Pro
    
    var id: String { rawValue }
    
    // MARK: - Display Properties
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        case .sepia: return "Sepia"
        case .nord: return "Nord"
        case .ocean: return "Ocean"
        case .forest: return "Forest"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon.fill"
        case .sepia: return "book.fill"
        case .nord: return "snowflake"
        case .ocean: return "water.waves"
        case .forest: return "leaf.fill"
        }
    }
    
    /// Whether this theme requires Pro
    var isPremium: Bool {
        switch self {
        case .system, .light, .dark:
            return false
        case .sepia, .nord, .ocean, .forest:
            return true
        }
    }
    
    // MARK: - Color Definitions
    
    /// Primary background color
    var backgroundColor: Color {
        switch self {
        case .system:
            #if os(macOS)
            return Color(nsColor: .windowBackgroundColor)
            #else
            return Color(uiColor: .systemBackground)
            #endif
        case .light:
            #if os(macOS)
            return Color(nsColor: .windowBackgroundColor)
            #else
            return Color(uiColor: .systemBackground)
            #endif
        case .dark:
            return Color(red: 0.11, green: 0.11, blue: 0.12)
        case .sepia:
            return Color(red: 0.97, green: 0.96, blue: 0.90) // Warm Cream
        case .nord:
            return Color(red: 0.18, green: 0.20, blue: 0.25) // Nord Polar Night
        case .ocean:
            return Color(red: 0.02, green: 0.18, blue: 0.22) // Deep Teal
        case .forest:
            return Color(red: 0.09, green: 0.16, blue: 0.11) // Deep Forest Green
        }
    }
    
    /// Secondary/card background color
    var secondaryBackground: Color {
        switch self {
        case .system:
            #if os(macOS)
            return Color(nsColor: .controlBackgroundColor)
            #else
            return Color(uiColor: .secondarySystemBackground)
            #endif
        case .light:
            #if os(macOS)
            return Color(nsColor: .controlBackgroundColor)
            #else
            return Color(uiColor: .secondarySystemBackground)
            #endif
        case .dark:
            return Color(red: 0.16, green: 0.16, blue: 0.18)
        case .sepia:
            return Color(red: 0.94, green: 0.92, blue: 0.84) // Darker Cream
        case .nord:
            return Color(red: 0.23, green: 0.26, blue: 0.32) // Nord Polar Night Lighter
        case .ocean:
            return Color(red: 0.04, green: 0.22, blue: 0.28) // Lighter Teal
        case .forest:
            return Color(red: 0.13, green: 0.22, blue: 0.15) // Lighter Green
        }
    }
    
    /// Primary text color
    var textColor: Color {
        switch self {
        case .system:
            #if os(macOS)
            return Color(nsColor: .textColor)
            #else
            return Color(uiColor: .label)
            #endif
        case .light:
            return Color(red: 0.10, green: 0.10, blue: 0.10)
        case .dark:
            return Color(red: 0.93, green: 0.93, blue: 0.94)
        case .sepia:
            return Color(red: 0.26, green: 0.20, blue: 0.13) // Dark Brown
        case .nord:
            return Color(red: 0.85, green: 0.87, blue: 0.91) // Nord Snow Storm
        case .ocean:
            return Color(red: 0.94, green: 0.96, blue: 1.00) // Crisp White
        case .forest:
            return Color(red: 0.91, green: 0.94, blue: 0.91) // Mist / Off-White
        }
    }
    
    /// Secondary text color
    var secondaryTextColor: Color {
        switch self {
        case .system:
            #if os(macOS)
            return Color(nsColor: .secondaryLabelColor)
            #else
            return Color(uiColor: .secondaryLabel)
            #endif
        case .light:
            return Color(red: 0.45, green: 0.45, blue: 0.47)
        case .dark:
            return Color(red: 0.60, green: 0.60, blue: 0.65)
        case .sepia:
            return Color(red: 0.41, green: 0.36, blue: 0.32) // Medium Brown
        case .nord:
            return Color(red: 0.90, green: 0.91, blue: 0.94) // Nord Snow Storm Lighter
        case .ocean:
            return Color(red: 0.45, green: 0.65, blue: 0.70) // Soft Teal
        case .forest:
            return Color(red: 0.60, green: 0.70, blue: 0.62) // Sage
        }
    }
    
    /// Accent color
    var accentColor: Color {
        switch self {
        case .system:
            return Color.accentColor
        case .light:
            return Color.blue
        case .dark:
            return Color(red: 0.35, green: 0.55, blue: 0.95)
        case .sepia:
            return Color(red: 0.75, green: 0.61, blue: 0.19) // Gold/Ochre
        case .nord:
            return Color(red: 0.53, green: 0.75, blue: 0.82) // Nord Frost
        case .ocean:
            return Color(red: 0.00, green: 0.85, blue: 0.80) // Bright Turquoise
        case .forest:
            return Color(red: 0.42, green: 0.76, blue: 0.44) // Bright Green
        }
    }
    
    /// Selection/Hover color (low opacity accent)
    var selectionColor: Color {
        accentColor.opacity(0.15)
    }
    
    #if os(macOS)
    // MARK: - NSAppearance (macOS only)
    
    /// Returns the NSAppearance to apply for this theme
    var nsAppearance: NSAppearance? {
        switch self {
        case .system:
            return nil  // Follow system
        case .light, .sepia:
            return NSAppearance(named: .aqua)
        case .dark, .nord, .ocean, .forest:
            return NSAppearance(named: .darkAqua)
        }
    }
    
    // MARK: - Application
    
    /// Apply this theme to the app (macOS only)
    func apply() {
        NSApp.appearance = nsAppearance
        for window in NSApplication.shared.windows {
            window.appearance = nsAppearance
        }
    }
    #else
    // MARK: - Application (iOS)
    
    /// Apply this theme to the app (iOS - no-op, use preferredColorScheme instead)
    func apply() {
        // On iOS, themes are applied via SwiftUI's preferredColorScheme modifier
        // This method is kept for API compatibility
    }
    #endif
    
    // MARK: - All Themes
    
    /// Free themes
    static var freeThemes: [AppTheme] {
        allCases.filter { !$0.isPremium }
    }
    
    /// Pro themes
    static var premiumThemes: [AppTheme] {
        allCases.filter { $0.isPremium }
    }
}

// MARK: - Environment Key

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .system
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

// MARK: - View Modifier

extension View {
    /// Apply the current theme's background color
    func themedBackground(_ theme: AppTheme) -> some View {
        self.background(theme.backgroundColor)
    }
    
    /// Apply the current theme to this view
    func applyTheme(_ theme: AppTheme) -> some View {
        self
            .environment(\.appTheme, theme)
            .background(theme.backgroundColor)
            .foregroundStyle(theme.textColor)
    }
}
