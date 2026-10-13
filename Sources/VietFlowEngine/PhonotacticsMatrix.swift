//
//  PhonotacticsMatrix.swift
//  VietFlowEngine
//
//  Formal Vietnamese Phonotactics and CVC Matrix Validator based on Bamboo Engine.
//

import Foundation

/// Formal Vietnamese Phonotactics and CVC Matrix Validator based on Bamboo Engine.
public enum PhonotacticsMatrix {
    
    // MARK: - Consonant & Vowel Inventories
    
    public static let firstConsonantSeqs: [[String]] = [
        // Row 0
        ["b", "d", "đ", "g", "gh", "m", "n", "nh", "p", "ph", "r", "s", "t", "tr", "v", "z"],
        // Row 1
        ["c", "h", "k", "kh", "qu", "th"],
        // Row 2
        ["ch", "gi", "l", "ng", "ngh", "x"],
        // Row 3 (place names: Đắk Lắk)
        ["đ", "l"],
        // Row 4 (onomatopoeia: hic)
        ["h"]
    ]
    
    public static let vowelSeqs: [[String]] = [
        // Row 0
        ["ê", "i", "ua", "uê", "uy", "y"],
        // Row 1
        ["a", "iê", "oa", "uyê", "yê"],
        // Row 2
        ["â", "ă", "e", "o", "oo", "ô", "ơ", "oe", "u", "ư", "uâ", "uô", "ươ"],
        // Row 3
        ["oă"],
        // Row 4
        ["uơ"],
        // Row 5: Diphthongs & Triphthongs with off-glides (cannot take codas)
        [
            "ai", "ao", "au", "âu", "ay", "ây", "eo", "êu", "ia", "iêu", "iu",
            "oai", "oao", "oay", "oeo", "oi", "ôi", "ơi", "ưa", "uây", "ui",
            "ưi", "uôi", "ươi", "ươu", "ưu", "uya", "uyu", "yêu"
        ],
        // Row 6 (place name vowels)
        ["ă"],
        // Row 7 (loan / onomatopoeia vowels)
        ["i"]
    ]
    
    public static let lastConsonantSeqs: [[String]] = [
        // Row 0: Palatals
        ["ch", "nh"],
        // Row 1: Velars
        ["c", "ng"],
        // Row 2: Labials & Alveolars
        ["m", "n", "p", "t"],
        // Row 3: Loan/place stop
        ["k"],
        // Row 4: Onomatopoeia stop
        ["c"]
    ]
    
    // MARK: - Compatibility Matrices
    
    /// CV Matrix: Maps FC row index to allowed VO row indices
    public static let cvMatrix: [[Int]] = [
        [0, 1, 2, 5],          // FC 0
        [0, 1, 2, 3, 4, 5],    // FC 1
        [0, 1, 2, 3, 5],       // FC 2
        [6],                   // FC 3
        [7]                    // FC 4
    ]
    
    /// VC Matrix: Maps VO row index to allowed LC row indices
    public static let vcMatrix: [[Int]] = [
        [0, 2],       // VO 0 -> ch/nh, m/n/p/t
        [0, 1, 2],    // VO 1 -> ch/nh, c/ng, m/n/p/t
        [1, 2],       // VO 2 -> c/ng, m/n/p/t
        [1, 2],       // VO 3 -> c/ng, m/n/p/t
        [],           // VO 4 -> open only
        [],           // VO 5 -> open only (offglides forbid codas)
        [3],          // VO 6 -> k
        [4]           // VO 7 -> c
    ]
    
    // MARK: - Fast Lookup Sets
    
    public static let stopCodas: Set<String> = ["c", "ch", "p", "t", "k"]
    public static let frontVowelOnsets: Set<String> = ["k", "gh", "ngh"]
    public static let backVowelOnsets: Set<String> = ["c", "g", "ng"]
    
    public static let vowelsSet: Set<Character> = Set(
        "aàáảãạăằắẳẵặâầấẩẫậeèéẻẽẹêềếểễệiìíỉĩịoòóỏõọôồốổỗộơờớởỡợuùúủũụưừứửữựyỳýỷỹỵ"
    )

    public static func isVowelChar(_ char: Character) -> Bool {
        return vowelsSet.contains(Character(char.lowercased()))
    }

    // MARK: - Stop Coda Tone Validation
    
    /// Verifies if a given coda and tone satisfy the Stop Coda Restriction Rule.
    /// Codas in ['c', 'ch', 'p', 't', 'k'] can ONLY accept Sắc (.acute), Nặng (.dot), or None (.none).
    public static func isValidStopCodaTone(coda: String, tone: Tone) -> Bool {
        let lowerCoda = coda.lowercased()
        guard stopCodas.contains(lowerCoda) else {
            return true
        }
        return tone.isStopCompatible
    }

    // MARK: - Orthographic Rule Validation
    
    /// Checks distribution rules for k/gh/ngh vs c/g/ng
    public static func isValidOrthographicPairing(onset: String, nucleus: String) -> Bool {
        guard !onset.isEmpty, !nucleus.isEmpty else { return true }
        let lowerOnset = onset.lowercased()
        let lowerNucleus = nucleus.lowercased()
        
        let isFrontVowel = lowerNucleus.hasPrefix("i") ||
                           lowerNucleus.hasPrefix("e") ||
                           lowerNucleus.hasPrefix("ê") ||
                           lowerNucleus.hasPrefix("y")
        
        // k, gh, ngh can only precede front vowels
        if frontVowelOnsets.contains(lowerOnset) {
            return isFrontVowel
        }
        
        // c, g, ng cannot precede front vowels (except through 'qu' or 'gi')
        if backVowelOnsets.contains(lowerOnset) {
            return !isFrontVowel
        }
        
        return true
    }

    /// Checks palatal coda (ch, nh) vs velar coda (c, ng) constraints
    public static func isValidCodaPairing(nucleus: String, coda: String) -> Bool {
        guard !nucleus.isEmpty, !coda.isEmpty else { return true }
        let lowerNucleus = nucleus.lowercased()
        let lowerCoda = coda.lowercased()
        
        // ch, nh only follow front vowels: i, ê, a, uy
        if lowerCoda == "ch" || lowerCoda == "nh" {
            let validPalatalNuclei: Set<String> = ["i", "ê", "a", "uy"]
            return validPalatalNuclei.contains(lowerNucleus)
        }
        
        return true
    }

    // MARK: - Matrix Row Lookups
    
    public static func lookupFC(_ onset: String, isComplete: Bool = true) -> [Int] {
        guard !onset.isEmpty else { return [] }
        var matches: [Int] = []
        for (rowIdx, row) in firstConsonantSeqs.enumerated() {
            if row.contains(onset) {
                matches.append(rowIdx)
            }
        }
        return matches
    }

    public static func lookupVO(_ nucleus: String, isComplete: Bool = true) -> [Int] {
        guard !nucleus.isEmpty else { return [] }
        var matches: [Int] = []
        for (rowIdx, row) in vowelSeqs.enumerated() {
            if row.contains(nucleus) {
                matches.append(rowIdx)
            }
        }
        return matches
    }

    public static func lookupLC(_ coda: String, isComplete: Bool = true) -> [Int] {
        guard !coda.isEmpty else { return [] }
        var matches: [Int] = []
        for (rowIdx, row) in lastConsonantSeqs.enumerated() {
            if row.contains(coda) {
                matches.append(rowIdx)
            }
        }
        return matches
    }

    public static func isValidCoda(_ coda: String) -> Bool {
        return !lookupLC(coda.lowercased()).isEmpty
    }

    // MARK: - Comprehensive Syllable Validation
    
    /// Validates an entire syllable according to Bamboo CVC matrices,
    /// stop-coda restrictions, and Vietnamese orthography.
    public static func isValidSyllable(
        onset: String,
        nucleus: String,
        coda: String,
        tone: Tone = .none,
        isComplete: Bool = true
    ) -> Bool {
        let o = onset.lowercased()
        let n = nucleus.lowercased()
        let c = coda.lowercased()
        
        // 1. Check Stop Coda Tone Rule
        if !isValidStopCodaTone(coda: c, tone: tone) {
            return false
        }
        
        // 2. Single consonant typing (transient valid)
        if n.isEmpty && c.isEmpty {
            return o.isEmpty || !lookupFC(o, isComplete: false).isEmpty
        }
        
        // 3. Short vowel open-syllable rule: 'ă' and 'â' cannot be open syllables when complete
        if (n == "ă" || n == "â") && c.isEmpty && isComplete {
            return false
        }
        
        // 4. Check Orthographic Onset Rules
        if !isValidOrthographicPairing(onset: o, nucleus: n) {
            return false
        }
        
        // 5. Check Coda Pairings
        if !isValidCodaPairing(nucleus: n, coda: c) {
            return false
        }
        
        // 6. Look up row indices
        let fcIndices = lookupFC(o, isComplete: isComplete)
        let voIndices = lookupVO(n, isComplete: isComplete)
        let lcIndices = lookupLC(c, isComplete: isComplete)
        
        // Invalid individual parts
        if !o.isEmpty && fcIndices.isEmpty { return false }
        if !n.isEmpty && voIndices.isEmpty { return false }
        if !c.isEmpty && lcIndices.isEmpty { return false }
        
        // 7. Validate CV compatibility (if onset exists)
        if !o.isEmpty && !n.isEmpty {
            var cvValid = false
            for fc in fcIndices {
                for allowedVO in cvMatrix[fc] {
                    if voIndices.contains(allowedVO) {
                        cvValid = true
                        break
                    }
                }
                if cvValid { break }
            }
            if !cvValid { return false }
        }
        
        // 8. Validate VC compatibility (if coda exists)
        if !c.isEmpty && !n.isEmpty {
            var vcValid = false
            for vo in voIndices {
                for allowedLC in vcMatrix[vo] {
                    if lcIndices.contains(allowedLC) {
                        vcValid = true
                        break
                    }
                }
                if vcValid { break }
            }
            if !vcValid { return false }
        } else if c.isEmpty && !n.isEmpty {
            // Open syllable: check if nucleus allows open syllables
            // VO Row 3 (oă) requires coda
            if voIndices.contains(3) && voIndices.count == 1 && isComplete {
                return false
            }
        }
        
        return true
    }
}
