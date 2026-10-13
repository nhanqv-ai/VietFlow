//
//  Syllable.swift
//  VietFlowEngine
//
//  Linguistically complete CVC syllable model for Vietnamese Bamboo Engine.
//

import Foundation

/// The six phonemic tones of standard Vietnamese.
public enum Tone: Int, CaseIterable, Codable, Sendable, Comparable {
    case none  = 0 // Ngang (Level / Không dấu) - e.g. "ba"
    case grave = 1 // Huyền (Grave / Dấu huyền) - e.g. "bà"
    case acute = 2 // Sắc (Acute / Dấu sắc)     - e.g. "bá"
    case hook  = 3 // Hỏi (Hook Above / Dấu hỏi)- e.g. "bả"
    case tilde = 4 // Ngã (Tilde / Dấu ngã)     - e.g. "bã"
    case dot   = 5 // Nặng (Dot Below / Dấu nặng)- e.g. "bạ"

    public var name: String {
        switch self {
        case .none:  return "Ngang"
        case .grave: return "Huyền"
        case .acute: return "Sắc"
        case .hook:  return "Hỏi"
        case .tilde: return "Ngã"
        case .dot:   return "Nặng"
        }
    }

    /// Stop codas (c, ch, p, t, k) can only take none, acute, or dot.
    public var isStopCompatible: Bool {
        return self == .none || self == .acute || self == .dot
    }

    public static func < (lhs: Tone, rhs: Tone) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

/// Diacritic vowel and consonant modification marks.
public enum DiacriticMark: Int, CaseIterable, Codable, Sendable {
    case none       = 0
    case circumflex = 1 // Mũ (â, ê, ô)
    case breve      = 2 // Trăng (ă)
    case horn       = 3 // Móc (ơ, ư)
    case bar        = 4 // Gạch ngang (đ)
}

/// Case style of a syllable.
public enum SyllableCasing: Equatable, Sendable {
    case lowercase       // "việt"
    case capitalized     // "Việt"
    case uppercase       // "VIỆT"
    case mixed([Bool])   // per-character uppercase flag
}

/// Structural model of a single Vietnamese syllable according to CVC formula:
/// Syllable = [C1] + V + [C2] + Tone.
public struct Syllable: Equatable, Sendable {
    
    // MARK: - Core Components
    
    /// Initial consonant / Onset (e.g. "ngh", "tr", "b", "qu", "gi", or "" for zero onset).
    public var onset: String
    
    /// Toneless vowel nucleus (e.g. "a", "iê", "oa", "ươ", "uyê").
    public var nucleus: String
    
    /// Final consonant / Coda (e.g. "m", "n", "ng", "nh", "p", "t", "c", "ch", or "" for zero coda).
    public var coda: String
    
    /// Active tone mark.
    public var tone: Tone
    
    /// 0-based index within `nucleus` where tone mark resides.
    public var toneTargetIndex: Int
    
    /// Verbatim keystrokes typed by the user to produce this syllable.
    public var rawBuffer: String
    
    /// Casing style of the represented characters.
    public var casing: SyllableCasing
    
    // MARK: - Initializers
    
    public init(
        onset: String = "",
        nucleus: String = "",
        coda: String = "",
        tone: Tone = .none,
        toneTargetIndex: Int = 0,
        rawBuffer: String = "",
        casing: SyllableCasing = .lowercase
    ) {
        self.onset = onset
        self.nucleus = nucleus
        self.coda = coda
        self.tone = tone
        self.toneTargetIndex = toneTargetIndex
        self.rawBuffer = rawBuffer
        self.casing = casing
    }

    public static let empty = Syllable()

    public var isEmpty: Bool {
        return onset.isEmpty && nucleus.isEmpty && coda.isEmpty && rawBuffer.isEmpty
    }

    public mutating func reset() {
        onset = ""
        nucleus = ""
        coda = ""
        tone = .none
        toneTargetIndex = 0
        rawBuffer = ""
        casing = .lowercase
    }

    // MARK: - Precomposed NFC Unicode Output
    
    /// Composes the syllable into a precomposed NFC Unicode string.
    public func composedText(toneStyle: TonePlacementStyle = .modern) -> String {
        guard !isEmpty else { return "" }
        
        // If there is no nucleus, return onset + coda or rawBuffer
        if nucleus.isEmpty {
            return applyCasing(onset + coda)
        }
        
        let composed = TonePlacement.composeSyllable(
            vowels: Array(nucleus),
            onset: onset,
            coda: coda,
            tone: tone,
            style: toneStyle
        )
        
        let result = applyCasing(composed)
        return result.precomposedStringWithCanonicalMapping
    }

    public func formattedPrecomposedNFC(toneStyle: TonePlacementStyle = .modern) -> String {
        return composedText(toneStyle: toneStyle)
    }

    // MARK: - Casing Helpers
    
    public func applyCasing(_ string: String) -> String {
        switch casing {
        case .lowercase:
            return string.lowercased()
        case .uppercase:
            return string.uppercased()
        case .capitalized:
            guard let first = string.first else { return "" }
            return String(first).uppercased() + string.dropFirst().lowercased()
        case .mixed(let mask):
            var output = ""
            for (idx, char) in string.enumerated() {
                if idx < mask.count && mask[idx] {
                    output.append(char.uppercased())
                } else {
                    output.append(char.lowercased())
                }
            }
            return output
        }
    }

    // MARK: - CVC Matrix Validation
    
    public func isValidCVC(isComplete: Bool = true) -> Bool {
        return PhonotacticsMatrix.isValidSyllable(
            onset: onset,
            nucleus: nucleus,
            coda: coda,
            tone: tone,
            isComplete: isComplete
        )
    }

    // MARK: - Bidirectional Parsing
    
    /// Parses an existing Vietnamese word string into a structured Syllable.
    public static func parse(from string: String) -> Syllable? {
        guard !string.isEmpty else { return nil }
        
        let lower = string.lowercased()
        var extractedTone: Tone = .none
        var tonelessChars: [Character] = []
        var detectedToneIndexInNucleus = 0
        
        // Decompose vowels and extract tone
        for char in lower {
            let (base, tone) = TonePlacement.removeTone(from: char)
            tonelessChars.append(base)
            if tone != .none {
                extractedTone = tone
            }
        }
        
        let tonelessString = String(tonelessChars)
        let (onsetPart, nucleusPart, codaPart) = partitionCVC(tonelessString)
        
        // Locate tone index in nucleus
        var nIdx = 0
        for char in lower {
            let (_, tone) = TonePlacement.removeTone(from: char)
            if tone == extractedTone && tone != .none {
                detectedToneIndexInNucleus = nIdx
                break
            }
            if PhonotacticsMatrix.isVowelChar(char) {
                nIdx += 1
            }
        }
        
        // Determine casing
        let casing: SyllableCasing
        let isAllUpper = string.allSatisfy { !$0.isLetter || $0.isUppercase }
        let isAllLower = string.allSatisfy { !$0.isLetter || $0.isLowercase }
        let isCap = (string.first?.isUppercase ?? false) && string.dropFirst().allSatisfy { !$0.isLetter || $0.isLowercase }
        
        if isAllUpper {
            casing = .uppercase
        } else if isCap {
            casing = .capitalized
        } else if isAllLower {
            casing = .lowercase
        } else {
            casing = .mixed(string.map { $0.isUppercase })
        }
        
        return Syllable(
            onset: onsetPart,
            nucleus: nucleusPart,
            coda: codaPart,
            tone: extractedTone,
            toneTargetIndex: max(0, min(detectedToneIndexInNucleus, max(0, nucleusPart.count - 1))),
            rawBuffer: string,
            casing: casing
        )
    }

    /// Partitions a toneless lowercase string into (onset, nucleus, coda).
    public static func partitionCVC(_ string: String) -> (onset: String, nucleus: String, coda: String) {
        guard !string.isEmpty else { return ("", "", "") }
        
        let chars = Array(string)
        var vowelStart = -1
        var vowelEnd = -1
        
        for (idx, ch) in chars.enumerated() {
            if PhonotacticsMatrix.isVowelChar(ch) {
                if vowelStart == -1 {
                    vowelStart = idx
                }
                vowelEnd = idx
            }
        }
        
        // No vowels found: entire string is onset
        if vowelStart == -1 {
            return (string, "", "")
        }
        
        var onset = String(chars[0..<vowelStart])
        var nucleus = String(chars[vowelStart...vowelEnd])
        let coda = String(chars[(vowelEnd + 1)..<chars.count])
        
        // Handle orthographic onset clusters 'qu' and 'gi'
        if onset == "q" && nucleus.hasPrefix("u") && nucleus.count > 1 {
            onset = "qu"
            nucleus.removeFirst()
        } else if onset == "g" && nucleus.hasPrefix("i") && nucleus.count > 1 && !nucleus.hasPrefix("iê") {
            onset = "gi"
            nucleus.removeFirst()
        }
        
        return (onset, nucleus, coda)
    }
}
