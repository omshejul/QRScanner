import Foundation

/// A utility class for detecting and validating URLs in text
public class URLDetectorUtility {
    
    /// Shared instance for convenience
    public static let shared = URLDetectorUtility()
    
    /// The NSDataDetector instance used for URL detection
    private lazy var linkDetector: NSDataDetector? = {
        do {
            return try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        } catch {
            print("Error creating NSDataDetector: \(error)")
            return nil
        }
    }()
    
    private init() {}
    
    /// Checks if the provided text contains a valid HTTP or HTTPS URL
    /// - Parameter text: The text to check for URLs
    /// - Returns: Boolean indicating if the text contains a valid web URL
    public func isValidWebLink(_ text: String) -> Bool {
        // Check if it's a standard URL with scheme
        if let url = URL(string: text), url.scheme != nil {
            return url.scheme?.lowercased() == "http" || url.scheme?.lowercased() == "https"
        }
        
        // Check with NSDataDetector for links
        if let detector = linkDetector {
            let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
            if let match = matches.first, let url = match.url, url.scheme != nil {
                return url.scheme?.lowercased() == "http" || url.scheme?.lowercased() == "https"
            }
        }
        
        // Check for domain-like patterns
        let patterns = [
            "^([a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,}(/.*)?$",
            "^www\\.[a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?\\.([a-zA-Z]{2,})(/.*)?$"
        ]
        
        for pattern in patterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                let range = NSRange(location: 0, length: text.utf16.count)
                if regex.firstMatch(in: text, options: [], range: range) != nil {
                    return true
                }
            } catch {
                print("Error with regex pattern: \(error)")
            }
        }
        
        return false
    }
    
    /// Extracts all URLs from the provided text
    /// - Parameter text: The text to extract URLs from
    /// - Returns: Array of URLs found in the text
    public func extractURLs(from text: String) -> [URL] {
        guard let detector = linkDetector else { return [] }
        
        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        return matches.compactMap { $0.url }
    }
    
    /// Formats a URL string to ensure it has a proper scheme
    /// - Parameter urlString: The URL string to format
    /// - Returns: A properly formatted URL string
    public func formatURLString(_ urlString: String) -> String {
        // If it already has a scheme, return as is
        if let url = URL(string: urlString), url.scheme != nil {
            return urlString
        }
        
        // Check if it's a domain-like string
        let domainPatterns = [
            "^([a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,}(/.*)?$",
            "^www\\.[a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?\\.([a-zA-Z]{2,})(/.*)?$"
        ]
        
        for pattern in domainPatterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                let range = NSRange(location: 0, length: urlString.utf16.count)
                if regex.firstMatch(in: urlString, options: [], range: range) != nil {
                    // If it starts with www, add https://
                    if urlString.lowercased().hasPrefix("www.") {
                        return "https://" + urlString
                    } else {
                        return "https://" + urlString
                    }
                }
            } catch {
                print("Error with regex pattern: \(error)")
            }
        }
        
        return urlString
    }
} 