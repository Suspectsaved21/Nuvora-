//
//  String+Extensions.swift
//  Nuvora
//
//  String extensions for validation and utility functions
//

import Foundation

extension String {
    /// Checks if the string contains only numeric characters
    var isNumeric: Bool {
        return !isEmpty && allSatisfy { $0.isNumber }
    }
    
    /// Filters the string to contain only numeric characters
    var numericOnly: String {
        return filter { $0.isNumber }
    }
    
    /// Formats a phone number string to E164 format
    func toE164Format() -> String {
        let cleaned = numericOnly
        if cleaned.hasPrefix("1") && cleaned.count == 11 {
            return "+\(cleaned)"
        } else if cleaned.count == 10 {
            return "+1\(cleaned)"
        }
        return "+\(cleaned)"
    }
}

extension Character {
    /// Checks if the character is a number (0-9)
    var isNumber: Bool {
        return "0123456789".contains(self)
    }
}
