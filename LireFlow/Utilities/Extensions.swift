import Foundation

// MARK: - String Extensions

extension String {
    /// Remove HTML tags from string
    var strippingHTML: String {
        replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Decode HTML entities like &#8217; to proper characters
    var decodingHTMLEntities: String {
        guard let data = self.data(using: .utf8) else { return self }
        
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        guard let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            return self
        }
        
        return attributedString.string
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
