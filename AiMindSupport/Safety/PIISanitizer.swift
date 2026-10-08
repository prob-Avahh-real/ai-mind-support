import Foundation

// MARK: - PII Sanitizer

class PIISanitizer {
    private let emailPattern = #"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"#
    private let phonePattern = #"\d{3}[-.\s]?\d{3}[-.\s]?\d{4}"#
    private let chinesePhonePattern = #"(?:\+?86)?1[3-9]\d{9}"#
    private let ssnPattern = #"\d{3}-\d{2}-\d{4}"#
    
    func sanitize(_ text: String) -> String {
        var sanitized = text
        
        // Sanitize email addresses
        sanitized = replacePattern(in: sanitized, pattern: emailPattern, replacement: "[EMAIL]")
        
        // Sanitize phone numbers (US format)
        sanitized = replacePattern(in: sanitized, pattern: phonePattern, replacement: "[PHONE]")
        
        // Sanitize Chinese phone numbers
        sanitized = replacePattern(in: sanitized, pattern: chinesePhonePattern, replacement: "[PHONE]")
        
        // Sanitize SSN
        sanitized = replacePattern(in: sanitized, pattern: ssnPattern, replacement: "[SSN]")
        
        return sanitized
    }
    
    private func replacePattern(in text: String, pattern: String, replacement: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return text
        }
        
        let range = NSRange(location: 0, length: text.utf16.count)
        let sanitized = regex.stringByReplacingMatches(
            in: text,
            options: [],
            range: range,
            withTemplate: replacement
        )
        
        return sanitized
    }
}