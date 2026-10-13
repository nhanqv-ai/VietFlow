//
//  TonePlacement.swift
//  VietFlowEngine
//
//  Phonological Tone Placement Engine supporting Modern and Traditional styles
//  with precomposed Unicode NFC normalization.
//

import Foundation

public struct VowelDeconstruction: Equatable, Sendable {
    public let baseVowel: Character
    public let tone: Tone
    
    public init(baseVowel: Character, tone: Tone) {
        self.baseVowel = baseVowel
        self.tone = tone
    }
}

public struct TonePlacementEngine {
    
    // MARK: - Precomposed NFC Vowel Tables (144 Characters)
    
    public static let lowercaseVowelTable: [Character: [Tone: Character]] = [
        "a": [.none: "a", .grave: "à", .acute: "á", .hook: "ả", .tilde: "ã", .dot: "ạ"],
        "ă": [.none: "ă", .grave: "ằ", .acute: "ắ", .hook: "ẳ", .tilde: "ẵ", .dot: "ặ"],
        "â": [.none: "â", .grave: "ầ", .acute: "ấ", .hook: "ẩ", .tilde: "ẫ", .dot: "ậ"],
        "e": [.none: "e", .grave: "è", .acute: "é", .hook: "ẻ", .tilde: "ẽ", .dot: "ẹ"],
        "ê": [.none: "ê", .grave: "ề", .acute: "ế", .hook: "ể", .tilde: "ễ", .dot: "ệ"],
        "i": [.none: "i", .grave: "ì", .acute: "í", .hook: "ỉ", .tilde: "ĩ", .dot: "ị"],
        "o": [.none: "o", .grave: "ò", .acute: "ó", .hook: "ỏ", .tilde: "õ", .dot: "ọ"],
        "ô": [.none: "ô", .grave: "ồ", .acute: "ố", .hook: "ổ", .tilde: "ỗ", .dot: "ộ"],
        "ơ": [.none: "ơ", .grave: "ờ", .acute: "ớ", .hook: "ở", .tilde: "ỡ", .dot: "ợ"],
        "u": [.none: "u", .grave: "ù", .acute: "ú", .hook: "ủ", .tilde: "ũ", .dot: "ụ"],
        "ư": [.none: "ư", .grave: "ừ", .acute: "ứ", .hook: "ử", .tilde: "ữ", .dot: "ự"],
        "y": [.none: "y", .grave: "ỳ", .acute: "ý", .hook: "ỷ", .tilde: "ỹ", .dot: "ỵ"],
    ]

    public static let uppercaseVowelTable: [Character: [Tone: Character]] = [
        "A": [.none: "A", .grave: "À", .acute: "Á", .hook: "Ả", .tilde: "Ã", .dot: "Ạ"],
        "Ă": [.none: "Ă", .grave: "Ằ", .acute: "Ắ", .hook: "Ẳ", .tilde: "Ẵ", .dot: "Ặ"],
        "Â": [.none: "Â", .grave: "Ầ", .acute: "Ấ", .hook: "Ẩ", .tilde: "Ẫ", .dot: "Ậ"],
        "E": [.none: "E", .grave: "È", .acute: "É", .hook: "Ẻ", .tilde: "Ẽ", .dot: "Ẹ"],
        "Ê": [.none: "Ê", .grave: "Ề", .acute: "Ế", .hook: "Ể", .tilde: "Ễ", .dot: "Ệ"],
        "I": [.none: "I", .grave: "Ì", .acute: "Í", .hook: "Ỉ", .tilde: "Ĩ", .dot: "Ị"],
        "O": [.none: "O", .grave: "Ò", .acute: "Ó", .hook: "Ỏ", .tilde: "Õ", .dot: "Ọ"],
        "Ô": [.none: "Ô", .grave: "Ồ", .acute: "Ố", .hook: "Ổ", .tilde: "Ỗ", .dot: "Ộ"],
        "Ơ": [.none: "Ơ", .grave: "Ờ", .acute: "Ớ", .hook: "Ở", .tilde: "Ỡ", .dot: "Ợ"],
        "U": [.none: "U", .grave: "Ù", .acute: "Ú", .hook: "Ủ", .tilde: "Ũ", .dot: "Ụ"],
        "Ư": [.none: "Ư", .grave: "Ừ", .acute: "Ứ", .hook: "Ử", .tilde: "Ữ", .dot: "Ự"],
        "Y": [.none: "Y", .grave: "Ỳ", .acute: "Ý", .hook: "Ỷ", .tilde: "Ỹ", .dot: "Ỵ"],
    ]

    public static let reverseVowelMap: [Character: VowelDeconstruction] = {
        var map = [Character: VowelDeconstruction]()
        for (base, toneDict) in lowercaseVowelTable {
            for (tone, char) in toneDict {
                map[char] = VowelDeconstruction(baseVowel: base, tone: tone)
            }
        }
        for (base, toneDict) in uppercaseVowelTable {
            for (tone, char) in toneDict {
                map[char] = VowelDeconstruction(baseVowel: base, tone: tone)
            }
        }
        return map
    }()

    // MARK: - Tone Placement Algorithm
    
    /// Calculates the 0-based index within `vowels` that must carry the tone mark.
    public static func targetVowelIndex(
        vowels: [Character],
        onset: String,
        coda: String,
        style: TonePlacementStyle
    ) -> Int {
        guard !vowels.isEmpty else { return 0 }
        if vowels.count == 1 { return 0 }
        
        let lowerOnset = onset.lowercased()
        let lowerCoda = coda.lowercased()
        let vowelString = String(vowels).lowercased()
        
        // Rule 1: Onset "qu" handling
        // In "qu", 'u' is part of the onset labial glide /kw/. The vowel nucleus starts at index 1.
        if lowerOnset == "qu" || (lowerOnset == "q" && vowelString.hasPrefix("u") && vowels.count > 1) {
            if vowelString.hasPrefix("u") && vowels.count > 1 {
                let subVowels = Array(vowels.dropFirst())
                let subIndex = targetVowelIndex(
                    vowels: subVowels,
                    onset: "",
                    coda: coda,
                    style: style
                )
                return subIndex + 1
            }
        }
        
        // Rule 2: Onset "gi" handling
        // In "gi", 'i' is part of the onset glide /z/ when followed by another vowel (e.g. gia, gio, giu, giữa)
        // Exception: "giêng" has onset 'g', nucleus 'iê', coda 'ng' -> handled by standard rules
        if (lowerOnset == "gi" || (lowerOnset == "g" && vowelString.hasPrefix("i") && vowels.count > 1))
            && !vowelString.hasPrefix("iê") {
            if vowelString.hasPrefix("i") && vowels.count > 1 {
                let subVowels = Array(vowels.dropFirst())
                let subIndex = targetVowelIndex(
                    vowels: subVowels,
                    onset: "",
                    coda: coda,
                    style: style
                )
                return subIndex + 1
            }
        }
        
        // Rule 3: Syllable with Final Consonant (Coda is present)
        if !lowerCoda.isEmpty {
            // Marked vowel (ê, ô, ơ, â, ă) takes highest priority
            for (index, char) in vowelString.enumerated() {
                if "êôơâă".contains(char) {
                    return index
                }
            }
            // Multi-vowel before coda without marked vowels (oan, uan, uyn, oen) -> second vowel
            return vowels.count >= 2 ? 1 : 0
        }
        
        // Rule 4: Open Syllable (No coda)
        
        // Check for marked vowels
        let markedIndices = vowelString.enumerated().compactMap { index, char in
            "êôơâă".contains(char) ? index : nil
        }
        
        if markedIndices.count == 1 {
            return markedIndices[0]
        } else if markedIndices.count > 1 {
            // For ươ clusters (in ươi, ươu), 'ơ' always carries the tone mark
            if let oIndex = vowelString.firstIndex(of: "ơ") {
                return vowelString.distance(from: vowelString.startIndex, to: oIndex)
            }
            return markedIndices.last ?? 0
        }
        
        // Triphthong in open syllable without marked vowels (oai, oao, oay, oeo, uyu, uya)
        if vowels.count == 3 {
            return 1 // Always middle vowel (e.g. ngoài, xoay, ngoẹo, khuỷu, khuya)
        }
        
        // Diphthong in open syllable (count == 2)
        if vowels.count == 2 {
            // Divergent Diphthong Pairs: oa, oe, uy, ue
            if ["oa", "oe", "uy", "ue"].contains(vowelString) {
                switch style {
                case .modern:
                    return 0 // First vowel: hòa, khỏe, thúy, thúe, tùy, hòe
                case .traditional:
                    return 1 // Second vowel: hoà, khoẻ, thuý, thué, tuỳ, hoè
                }
            }
            
            // Centering diphthongs: ia, ua, ưa
            if ["ia", "ua", "ưa"].contains(vowelString) {
                return 0 // tone on first vowel: mía, múa, mứa
            }
            
            // Diphthongs ending in off-glides: ai, ao, au, ay, eo, oi, ui, ưi
            if ["ai", "ao", "au", "ay", "eo", "oi", "ui", "ưi"].contains(vowelString) {
                return 0 // tone on first vowel: mái, báo, sáu, máy, khéo, nói, túi, ngửi
            }
        }
        
        return 0
    }
}

public struct TonePlacement {
    
    /// Applies the specified Tone to a pre-segmented syllable string.
    public static func composeSyllable(
        vowels: [Character],
        onset: String,
        coda: String,
        tone: Tone,
        style: TonePlacementStyle
    ) -> String {
        guard !vowels.isEmpty else { return (onset + coda).precomposedStringWithCanonicalMapping }
        
        // 1. Strip any existing tones from vowels to obtain pure base vowels
        var baseVowels = [Character]()
        for v in vowels {
            if let decomp = TonePlacementEngine.reverseVowelMap[v] {
                baseVowels.append(decomp.baseVowel)
            } else {
                baseVowels.append(v)
            }
        }
        
        // If tone is none, return unaccented syllable
        if tone == .none {
            let combined = onset + String(baseVowels) + coda
            return combined.precomposedStringWithCanonicalMapping
        }
        
        // 2. Determine target vowel index
        let targetIdx = TonePlacementEngine.targetVowelIndex(
            vowels: baseVowels,
            onset: onset,
            coda: coda,
            style: style
        )
        
        // 3. Apply precomposed NFC character
        let targetChar = baseVowels[targetIdx]
        let isUpper = targetChar.isUppercase
        let lookupTable = isUpper ? TonePlacementEngine.uppercaseVowelTable : TonePlacementEngine.lowercaseVowelTable
        
        var transformedVowels = baseVowels
        if let toneRow = lookupTable[targetChar], let markedChar = toneRow[tone] {
            transformedVowels[targetIdx] = markedChar
        }
        
        let combined = onset + String(transformedVowels) + coda
        return combined.precomposedStringWithCanonicalMapping
    }
    
    /// Removes tone from any accented Vietnamese character.
    public static func removeTone(from char: Character) -> (base: Character, tone: Tone) {
        if let decomp = TonePlacementEngine.reverseVowelMap[char] {
            return (decomp.baseVowel, decomp.tone)
        }
        return (char, .none)
    }
    
    /// Strips all tone marks from a syllable string, preserving diacritics.
    public static func stripTone(from syllable: String) -> String {
        var result = ""
        for char in syllable {
            if let decomp = TonePlacementEngine.reverseVowelMap[char] {
                result.append(decomp.baseVowel)
            } else {
                result.append(char)
            }
        }
        return result.precomposedStringWithCanonicalMapping
    }
}
