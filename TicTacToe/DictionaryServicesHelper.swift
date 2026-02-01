import Foundation
import CoreServices

/// Helper class for accessing Apple's Dictionary Services API.
///
/// Provides offline word definition lookup using the system dictionary.
/// Extracts concise, clean definitions by removing examples, pronunciation guides,
/// and technical details from the full dictionary entries.
///
/// ## Example Usage
/// ```swift
/// if let definition = DictionaryServicesHelper.getCleanDefinition(for: "ephemeral") {
///     print(definition) // "lasting for a very short time"
/// }
/// ```
///
/// - Note: Dictionary Services is only available on macOS. On iOS, this returns nil.
class DictionaryServicesHelper {
    
    /// Extracts a clean, concise definition from the system dictionary.
    ///
    /// This method queries Apple's Dictionary Services and parses the result to extract
    /// just the first definition sentence. It removes:
    /// - Pronunciation guides (| ˈhapē |)
    /// - Comparative forms (happier, happiest)
    /// - Examples after colons
    /// - Technical notes in brackets
    /// - Multiple numbered definitions
    ///
    /// ## Process
    /// 1. Query Dictionary Services for full definition
    /// 2. Locate part of speech marker (adjective, noun, verb, etc.)
    /// 3. Extract text after part of speech
    /// 4. Remove comparative forms in parentheses
    /// 5. Skip numbering (1, 2, 3...)
    /// 6. Extract first sentence until period
    /// 7. Remove examples after colon
    /// 8. Return cleaned definition
    ///
    /// - Parameter word: The word to look up in the dictionary
    /// - Returns: A concise definition string, or nil if not found or unavailable
    ///
    /// - Note: Returns nil on iOS as Dictionary Services is macOS-only
    static func getCleanDefinition(for word: String) -> String? {
        #if os(macOS)
        // Query Dictionary Services for the word
        guard let definitionRef = DCSCopyTextDefinition(
            nil,  // Use default dictionary
            word as CFString,
            CFRangeMake(0, CFStringGetLength(word as CFString))
        ) else {
            return nil
        }
        
        // Convert Unmanaged<CFString> to Swift String
        let fullDefinition = definitionRef.takeRetainedValue() as String
        
        // List of part of speech markers to search for
        let partsOfSpeech = [
            "adjective",
            "noun",
            "verb",
            "adverb",
            "pronoun",
            "preposition",
            "conjunction",
            "exclamation"
        ]
        
        // Find the part of speech in the definition
        for pos in partsOfSpeech {
            if let posRange = fullDefinition.range(of: pos, options: .caseInsensitive) {
                // Extract everything after the part of speech
                var afterPOS = String(fullDefinition[posRange.upperBound...])
                
                // Skip ALL parentheses with comparative forms and conjugations
                while let firstParen = afterPOS.firstIndex(of: "("),
                      let closeParen = afterPOS.firstIndex(of: ")"),
                      firstParen < closeParen {
                    afterPOS = String(afterPOS[afterPOS.index(after: closeParen)...])
                }
                
                // Skip leading numbers, whitespace, commas, and vertical bars
                afterPOS = afterPOS.trimmingCharacters(in: CharacterSet(charactersIn: "0123456789 ,|"))
                
                // Skip any remaining pronunciation or formatting
                while afterPOS.hasPrefix("|") || afterPOS.hasPrefix(" ") {
                    afterPOS = String(afterPOS.dropFirst())
                }
                
                // Look for the first letter to start the actual definition
                if let firstLetterIndex = afterPOS.firstIndex(where: { $0.isLetter }) {
                    afterPOS = String(afterPOS[firstLetterIndex...])
                }
                
                // Extract until first period (end of first definition)
                if let periodIndex = afterPOS.firstIndex(of: ".") {
                    var definition = String(afterPOS[..<periodIndex])
                    
                    // Remove examples after colon (e.g., ": Melissa came in looking happy")
                    if let colonIndex = definition.firstIndex(of: ":") {
                        definition = String(definition[..<colonIndex])
                    }
                    
                    // Clean and validate
                    let cleaned = definition.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Ensure minimum length (avoid fragments)
                    if cleaned.count > 10 {
                        return cleaned
                    }
                }
            }
        }
        #endif
        
        // Return nil if not on macOS or definition not found
        return nil
    }
}
