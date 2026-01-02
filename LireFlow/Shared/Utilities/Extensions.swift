import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - String Extensions

extension String {
    /// Remove HTML tags from string
    var strippingHTML: String {
        replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Decode HTML entities like &amp;#8217; to proper characters
    /// Uses pure string manipulation to avoid WebKit (which crashes on iOS during view layout)
    var decodingHTMLEntities: String {
        var result = self
        
        // Common named entities
        let namedEntities: [String: String] = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&apos;": "'",
            "&nbsp;": " ",
            "&ndash;": "–",
            "&mdash;": "—",
            "&lsquo;": "'",
            "&rsquo;": "'",
            "&ldquo;": "\u{201C}",
            "&rdquo;": "\u{201D}",
            "&hellip;": "…",
            "&copy;": "©",
            "&reg;": "®",
            "&trade;": "™",
            "&euro;": "€",
            "&pound;": "£",
            "&yen;": "¥",
            "&cent;": "¢",
            "&deg;": "°",
            "&times;": "×",
            "&divide;": "÷",
            "&plusmn;": "±",
            "&frac12;": "½",
            "&frac14;": "¼",
            "&frac34;": "¾"
        ]
        
        for (entity, character) in namedEntities {
            result = result.replacingOccurrences(of: entity, with: character)
        }
        
        // Numeric entities (&#8217; or &#x2019;)
        // Decimal: &#123;
        let decimalPattern = "&#(\\d+);"
        if let decimalRegex = try? NSRegularExpression(pattern: decimalPattern) {
            let range = NSRange(result.startIndex..., in: result)
            let matches = decimalRegex.matches(in: result, range: range)
            for match in matches.reversed() {
                if let numberRange = Range(match.range(at: 1), in: result),
                   let number = Int(result[numberRange]),
                   let scalar = Unicode.Scalar(number) {
                    let matchRange = Range(match.range, in: result)!
                    result.replaceSubrange(matchRange, with: String(Character(scalar)))
                }
            }
        }
        
        // Hexadecimal: &#x1F4A9;
        let hexPattern = "&#[xX]([0-9a-fA-F]+);"
        if let hexRegex = try? NSRegularExpression(pattern: hexPattern) {
            let range = NSRange(result.startIndex..., in: result)
            let matches = hexRegex.matches(in: result, range: range)
            for match in matches.reversed() {
                if let hexRange = Range(match.range(at: 1), in: result),
                   let number = Int(result[hexRange], radix: 16),
                   let scalar = Unicode.Scalar(number) {
                    let matchRange = Range(match.range, in: result)!
                    result.replaceSubrange(matchRange, with: String(Character(scalar)))
                }
            }
        }
        
        return result
    }
    
    /// Strip HTML and decode entities
    var cleanText: String {
        strippingHTML.decodingHTMLEntities
    }
    
    /// Truncate string to specified length
    func truncated(to length: Int, trailing: String = "…") -> String {
        if count > length {
            return String(prefix(length)) + trailing
        }
        return self
    }
}

// MARK: - Date Extensions

extension Date {
    /// Format date as relative time string
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Format date as readable string
    var readableString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - URL Extensions

extension URL {
    /// Extract domain from URL
    var domain: String? {
        host?.replacingOccurrences(of: "www.", with: "")
    }
    
    /// Get favicon URL for this domain
    var faviconURL: URL? {
        guard let scheme = scheme, let host = host else { return nil }
        return URL(string: "\(scheme)://\(host)/favicon.ico")
    }
}

// MARK: - Color Extensions

extension Color {
    /// Initialize with Hex string (e.g. "#FF0000" or "FF0000")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Convert to Hex string
    func toHex() -> String? {
        #if os(iOS)
        let uic = UIColor(self)
        #elseif os(macOS)
        let uic = NSColor(self)
        #endif
        
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)

        if components.count >= 4 {
            a = Float(components[3])
        }

        if a != Float(1.0) {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}
