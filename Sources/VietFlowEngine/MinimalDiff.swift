//
//  MinimalDiff.swift
//  VietFlowEngine
//
//  Longest Common Prefix (LCP) Minimal Diff algorithm operating on Precomposed NFC strings.
//

import Foundation

public enum MinimalDiff {
    
    /// Calculates the Longest Common Prefix (LCP) and minimal replacement delta
    /// between two strings, ensuring precomposed NFC normalization.
    ///
    /// - Parameters:
    ///   - previous: The string currently displayed in the target application.
    ///   - next: The desired target string after processing the key.
    /// - Returns: A `TextDelta` containing minimal backspaces and suffix to insert.
    public static func calculate(previous: String, next: String) -> TextDelta {
        // Step 1: Precomposed NFC canonical normalization
        let normPrev = previous.precomposedStringWithCanonicalMapping
        let normNext = next.precomposedStringWithCanonicalMapping

        // Fast path 1: Identical strings
        if normPrev == normNext {
            return TextDelta(backspaces: 0, insertText: "")
        }

        // Fast path 2: Empty previous (fresh syllable)
        if normPrev.isEmpty {
            return TextDelta(backspaces: 0, insertText: normNext)
        }

        // Fast path 3: Pure append (typing without diacritic mutations)
        if normNext.hasPrefix(normPrev) {
            let suffix = String(normNext.dropFirst(normPrev.count))
            return TextDelta(backspaces: 0, insertText: suffix)
        }

        // Fast path 4: Empty target (full deletion)
        if normNext.isEmpty {
            return TextDelta(backspaces: normPrev.count, insertText: "")
        }

        // Step 2: Extended Grapheme Cluster arrays
        let prevChars = Array(normPrev)
        let nextChars = Array(normNext)

        var lcpLen = 0
        let minLen = min(prevChars.count, nextChars.count)

        while lcpLen < minLen && prevChars[lcpLen] == nextChars[lcpLen] {
            lcpLen += 1
        }

        // Step 3: Compute backspaces and suffix
        let backspaces = prevChars.count - lcpLen
        let suffix = String(nextChars[lcpLen..<nextChars.count])

        return TextDelta(backspaces: backspaces, insertText: suffix)
    }
}
