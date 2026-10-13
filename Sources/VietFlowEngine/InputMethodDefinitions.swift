//
//  InputMethodDefinitions.swift
//  VietFlowEngine
//
//  Keystroke definitions and transformations for Telex, Simple Telex, and VNI.
//

import Foundation

public struct InputMethodDefinitions {
    
    // MARK: - Tone Key Resolvers
    
    public static func resolveToneKey(
        _ char: Character,
        method: InputMethod
    ) -> (tone: Tone?, isClearTone: Bool) {
        let lower = Character(char.lowercased())
        switch method {
        case .telex, .simpleTelex:
            switch lower {
            case "s": return (.acute, false)
            case "f": return (.grave, false)
            case "r": return (.hook, false)
            case "x": return (.tilde, false)
            case "j": return (.dot, false)
            case "z": return (nil, true)
            default: return (nil, false)
            }
        case .vni:
            switch lower {
            case "1": return (.acute, false)
            case "2": return (.grave, false)
            case "3": return (.hook, false)
            case "4": return (.tilde, false)
            case "5": return (.dot, false)
            case "0": return (nil, true)
            default: return (nil, false)
            }
        }
    }
    
    public static func isToneOrClearKey(_ char: Character, method: InputMethod) -> Bool {
        let res = resolveToneKey(char, method: method)
        return res.tone != nil || res.isClearTone
    }

    // MARK: - Tone & Base Vowel Extraction
    
    public static func stripToneAndExtractBase(from char: Character) -> (base: Character, tone: Tone) {
        return TonePlacement.removeTone(from: char)
    }

    // MARK: - Diacritic Transformations
    
    public static func applyDiacritic(
        to base: Character,
        modifier: Character,
        method: InputMethod
    ) -> Character? {
        let isUpper = base.isUppercase || modifier.isUppercase
        let (baseToneless, tone) = TonePlacement.removeTone(from: base)
        let b = Character(baseToneless.lowercased())
        let m = Character(modifier.lowercased())
        
        var result: Character? = nil
        
        switch method {
        case .telex, .simpleTelex:
            switch (b, m) {
            case ("a", "a"): result = "â"
            case ("a", "w"): result = "ă"
            case ("e", "e"): result = "ê"
            case ("o", "o"): result = "ô"
            case ("o", "w"): result = "ơ"
            case ("u", "w"): result = "ư"
            case ("d", "d"): result = "đ"
            default: result = nil
            }
        case .vni:
            switch (b, m) {
            case ("a", "6"): result = "â"
            case ("e", "6"): result = "ê"
            case ("o", "6"): result = "ô"
            case ("o", "7"): result = "ơ"
            case ("u", "7"): result = "ư"
            case ("a", "8"): result = "ă"
            case ("d", "9"): result = "đ"
            default: result = nil
            }
        }
        
        guard let res = result else { return nil }
        
        if tone != .none {
            let lookupBase = Character(res.lowercased())
            if let toneRow = TonePlacementEngine.lowercaseVowelTable[lookupBase], let tuned = toneRow[tone] {
                return isUpper ? Character(tuned.uppercased()) : tuned
            }
        }
        
        return isUpper ? Character(res.uppercased()) : res
    }
    
    // MARK: - Diacritic Reversal (Double-press undo)
    
    public static func undoDiacritic(
        character: Character,
        triggerKey: Character,
        method: InputMethod
    ) -> String? {
        let isUpper = character.isUppercase
        let c = Character(character.lowercased())
        let t = Character(triggerKey.lowercased())
        
        var pair: String? = nil
        
        switch method {
        case .telex, .simpleTelex:
            switch (c, t) {
            case ("â", "a"): pair = "aa"
            case ("ă", "w"): pair = "aw"
            case ("ê", "e"): pair = "ee"
            case ("ô", "o"): pair = "oo"
            case ("ơ", "w"): pair = "ow"
            case ("ư", "w"): pair = "uw"
            case ("đ", "d"): pair = "dd"
            default: pair = nil
            }
        case .vni:
            switch (c, t) {
            case ("â", "6"): pair = "a6"
            case ("ê", "6"): pair = "e6"
            case ("ô", "6"): pair = "o6"
            case ("ơ", "7"): pair = "o7"
            case ("ư", "7"): pair = "u7"
            case ("ă", "8"): pair = "a8"
            case ("đ", "9"): pair = "d9"
            default: pair = nil
            }
        }
        
        guard let p = pair else { return nil }
        return isUpper ? p.uppercased() : p
    }
}
