//
//  EnglishRestore.swift
//  VietFlowEngine
//
//  Automatic English word restoration, phonotactic validation, and bypass latching.
//

import Foundation

public struct EnglishRestoreState: Equatable, Sendable {
    /// True if the current word is bypassed (raw English mode until next delimiter).
    public var isBypassed: Bool
    /// Buffer of raw keystrokes typed for the current active token.
    public var rawKeystrokes: [Character]

    public init(isBypassed: Bool = false, rawKeystrokes: [Character] = []) {
        self.isBypassed = isBypassed
        self.rawKeystrokes = rawKeystrokes
    }

    public mutating func appendKey(_ char: Character) {
        rawKeystrokes.append(char)
    }

    public mutating func popKey() -> Character? {
        guard !rawKeystrokes.isEmpty else { return nil }
        return rawKeystrokes.removeLast()
    }

    public mutating func reset() {
        isBypassed = false
        rawKeystrokes.removeAll(keepingCapacity: true)
    }

    public var rawString: String {
        String(rawKeystrokes)
    }
}

public enum EnglishKeywords {
    public static let commonKeywords: Set<String> = [
        // Developer keywords & system commands
        "code", "post", "view", "format", "string", "struct", "print", "while",
        "class", "filter", "clear", "create", "system", "window", "document",
        "switch", "case", "break", "return", "import", "export", "false", "true",
        "commit", "branch", "merge", "push", "pull", "fetch", "clone", "status", "diff",
        "text", "test", "cost", "most", "fast", "broadcast", "terminal",
        "command", "buffer", "buff", "apple", "google", "microsoft", "github", "docker",
        "rust", "golang", "swift", "python", "java", "ruby", "node", "npm", "yarn",
        "make", "build", "debug", "release", "const", "var", "let", "func", "function",
        "public", "private", "fileprivate", "internal", "open", "static", "final",
        "class", "enum", "protocol", "extension", "typealias", "associatedtype",
        "async", "await", "actor", "sendable", "init", "deinit", "subscript", "self",
        "super", "nil", "null", "none", "some", "any", "where", "for", "in", "repeat",
        "guard", "else", "defer", "catch", "throw", "throws", "try",
        "operator", "precedencegroup", "mutating", "nonmutating",
        "override", "convenience", "required", "dynamic", "optional", "lazy",
        "weak", "unowned", "isolated", "nonisolated", "viewing", "viewer", "views",
        "mkdir", "curl", "tar", "ssh", "user", "cargo", "origin", "nano", "wifi", "water", "cat", "macos",
        "word", "warning", "report", "localhost",
        "pattern", "letter", "button", "better", "common", "matter",
        "swim", "swing", "sweet", "swap", "fix",
        "server", "service", "version", "person",
        "surf", "turf", "toward", "towards", "coward"
    ]
}

public enum EnglishRestoreDetector {
    
    /// Delimiter characters that terminate a word and reset English bypass.
    public static let wordDelimiters: Set<Character> = [
        " ", "\t", "\n", "\r",
        ".", ",", "!", "?", ":", ";", "/", "\\",
        "-", "_", "(", ")", "[", "]", "{", "}",
        "\"", "'", "`", "@", "#", "$", "%", "^",
        "&", "*", "+", "=", "<", ">", "|", "~"
    ]

    /// Invalid onset consonant clusters in Vietnamese (English-only clusters).
    public static let invalidOnsetClusters: Set<String> = [
        "br", "cr", "dr", "fr", "gr", "pr", "str",
        "sc", "sk", "sl", "sm", "sn", "sp", "st", "sw",
        "fl", "gl", "cl", "bl", "pl", "kn", "gn", "wr", "wh"
    ]

    /// Invalid coda consonant clusters in Vietnamese (English-only codas).
    public static let invalidCodaClusters: Set<String> = [
        "st", "nd", "nt", "rt", "rd", "ld", "rk", "rm", "rn",
        "lp", "lt", "mp", "ct", "ft", "ck", "ll",
        "bb", "gg"
    ]

    /// English medial double-consonant + vowel sequences that never occur in valid Vietnamese words.
    public static let invalidMedialDoubleConsonants: [String] = [
        "tta", "tte", "tti", "tto", "ttu", "tty",
        "lla", "lle", "lli", "llo", "llu", "lly",
        "ppa", "ppe", "ppi", "ppo", "ppu", "ppy",
        "bba", "bbe", "bbi", "bbo", "bbu", "bby",
        "ffa", "ffe", "ffi", "ffo", "ffu", "ffy",
        "mma", "mme", "mmi", "mmo", "mmu", "mmy",
        "rra", "rre", "rri", "rro", "rru", "rry",
        "ssa", "sse", "ssi", "sso", "ssu", "ssy"
    ]

    /// English 'sw-' prefixes that are not valid Vietnamese 'sư-' syllables in Telex.
    public static let invalidTelexSwPrefixes: [String] = [
        "swi", "swe", "swap", "swan", "swat", "swam", "swag"
    ]

    /// Voiceless stop codas that can ONLY take Acute (sắc) or Dot (nặng) tones.
    public static let stopCodas: Set<String> = ["c", "ch", "p", "t", "k"]

    public static func isWordDelimiter(_ char: Character) -> Bool {
        wordDelimiters.contains(char)
    }

    public static func hasInvalidOnsetCluster(_ onset: String) -> Bool {
        let lower = onset.lowercased()
        for cluster in invalidOnsetClusters {
            if lower.hasPrefix(cluster) { return true }
        }
        return false
    }

    public static func hasInvalidCodaCluster(_ coda: String) -> Bool {
        let lower = coda.lowercased()
        for cluster in invalidCodaClusters {
            if lower.hasSuffix(cluster) || lower == cluster { return true }
        }
        return false
    }

    public static func hasInvalidMedialDoubleConsonant(_ rawWord: String) -> Bool {
        let lower = rawWord.lowercased()
        guard lower.count >= 4 else { return false }
        for pattern in invalidMedialDoubleConsonants {
            if lower.contains(pattern) { return true }
        }
        return false
    }

    public static func hasInvalidTelexSwPrefix(_ rawWord: String) -> Bool {
        let lower = rawWord.lowercased()
        for prefix in invalidTelexSwPrefixes {
            if lower.hasPrefix(prefix) { return true }
        }
        return false
    }

    public static func violatesStopCodaRestriction(coda: String, tone: Tone) -> Bool {
        let lower = coda.lowercased()
        guard stopCodas.contains(lower) else { return false }
        switch tone {
        case .grave, .hook, .tilde:
            return true
        case .none, .acute, .dot:
            return false
        }
    }

    public static func isEnglishKeyword(_ word: String) -> Bool {
        EnglishKeywords.commonKeywords.contains(word.lowercased())
    }

    /// Evaluates whether composition should be broken and restored to raw English.
    public static func shouldBreakComposition(
        rawWord: String,
        onset: String,
        coda: String,
        tone: Tone,
        isCvcValid: Bool,
        autoCorrectEnabled: Bool
    ) -> Bool {
        guard autoCorrectEnabled else { return false }

        // Rule 1: Known English keyword match
        if isEnglishKeyword(rawWord) || hasInvalidMedialDoubleConsonant(rawWord) {
            return true
        }

        // Rule 2: Invalid onset or coda consonant clusters
        if hasInvalidOnsetCluster(onset) || hasInvalidCodaCluster(coda) {
            return true
        }
        
        // Check if rawWord starts with or ends with invalid clusters
        let lowerRaw = rawWord.lowercased()
        for cluster in invalidOnsetClusters {
            if lowerRaw.hasPrefix(cluster) { return true }
        }
        for cluster in invalidCodaClusters {
            if lowerRaw.hasSuffix(cluster) { return true }
        }

        // Rule 3: Stop coda tone violation
        if violatesStopCodaRestriction(coda: coda, tone: tone) {
            return true
        }

        // Rule 4: Formal CVC phonotactic matrix failure
        if !isCvcValid {
            return true
        }

        return false
    }
}
