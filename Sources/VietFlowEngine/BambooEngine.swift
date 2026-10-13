//
//  BambooEngine.swift
//  VietFlowEngine
//
//  Thread-safe Vietnamese Input Method Engine implementing VietnameseEngineProtocol.
//  Coordinates CVC phonotactics, Telex/VNI keystroke maps, dual tone placement,
//  undo mechanics, English restoration, and minimal diff calculation.
//

import Foundation
import os

public final class BambooEngine: VietnameseEngineProtocol, @unchecked Sendable {
    
    // MARK: - Synchronization
    private let lock: OSAllocatedUnfairLock<Void>

    // MARK: - Transformation State
    private struct SyllableTransformState {
        var isStandaloneW: Bool = false
        var lastToneKey: Character? = nil
        var lastDiacriticKey: Character? = nil
        var isBypassed: Bool = false
    }

    // MARK: - State Properties (Protected by lock)
    private var _config: EngineConfig
    private var committedPrefix: String
    private var activePreedit: String
    private var activeRawKeys: [Character]
    private var wordRawKeys: [Character]
    private var isBypassed: Bool
    private var didBackspace: Bool
    private var transformState: SyllableTransformState
    private var lastCompletedWord: String
    
    // MARK: - Initialization
    public init(config: EngineConfig = EngineConfig()) {
        self.lock = OSAllocatedUnfairLock()
        self._config = config
        self.committedPrefix = ""
        self.activePreedit = ""
        self.activeRawKeys = []
        self.wordRawKeys = []
        self.isBypassed = false
        self.didBackspace = false
        self.transformState = SyllableTransformState()
        self.lastCompletedWord = ""
    }

    // MARK: - VietnameseEngineProtocol Properties
    public var config: EngineConfig {
        get {
            lock.withLock { _config }
        }
        set {
            lock.withLock { _config = newValue }
        }
    }

    public var currentSyllable: String {
        lock.withLock { committedPrefix + activePreedit }
    }

    // MARK: - Core Keystroke Processing
    public func processKey(_ character: Character) -> TextDelta? {
        lock.withLock {
            internalProcessKey(character)
        }
    }

    private func internalProcessKey(_ character: Character) -> TextDelta? {
        let prevDisplay = committedPrefix + activePreedit

        // 1. Delimiter / Boundary Check
        if EnglishRestoreDetector.isWordDelimiter(character) {
            if !prevDisplay.isEmpty {
                lastCompletedWord = prevDisplay.lowercased()
            }
            internalReset()
            return nil
        }

        // 2. English Bypass Latch Check
        if isBypassed {
            wordRawKeys.append(character)
            activeRawKeys.append(character)
            activePreedit.append(character)
            return nil
        }

        // 3. Known English Keyword Check for Full Word (e.g. window, origin)
        let rawWordString = String(wordRawKeys) + String(character)
        let candidateWord = rawWordString.lowercased()
        if _config.autoCorrectEnglish && EnglishRestoreDetector.isEnglishKeyword(candidateWord) {
            isBypassed = true
            wordRawKeys.append(character)
            committedPrefix = ""
            activePreedit = rawWordString
            activeRawKeys = Array(rawWordString)
            transformState = SyllableTransformState()
            return MinimalDiff.calculate(previous: prevDisplay, next: rawWordString)
        }

        // 4. Syllable Splitting Check for Compound Words (e.g. HAIR + PHOFNG -> HẢI + PHÒNG)
        if shouldSplitSyllable(currentDisplay: activePreedit, nextChar: character) {
            committedPrefix += activePreedit
            activePreedit = ""
            activeRawKeys.removeAll(keepingCapacity: true)
            transformState = SyllableTransformState()
        }

        let candidateRaw = String(activeRawKeys) + String(character)
        let lowerCandidateRaw = candidateRaw.lowercased()
        let fullCandidateRaw = (committedPrefix + candidateRaw).lowercased()

        // 5. Known English Keyword Check (Zero-Flicker Pre-Validation)
        if _config.autoCorrectEnglish && (EnglishRestoreDetector.isEnglishKeyword(candidateRaw) || EnglishRestoreDetector.isEnglishKeyword(fullCandidateRaw)) {
            isBypassed = true
            wordRawKeys.append(character)
            activeRawKeys.append(character)
            activePreedit = candidateRaw
            let newDisplay = committedPrefix + activePreedit
            return MinimalDiff.calculate(previous: prevDisplay, next: newDisplay)
        }

        // 6. Invalid Foreign Consonant Cluster Check (Onset check only on raw)
        if _config.autoCorrectEnglish {
            var hasInvalidCluster = false
            for cluster in EnglishRestoreDetector.invalidOnsetClusters {
                if lowerCandidateRaw.hasPrefix(cluster) {
                    hasInvalidCluster = true
                    break
                }
            }
            if hasInvalidCluster {
                isBypassed = true
                wordRawKeys.append(character)
                activeRawKeys.append(character)
                activePreedit = candidateRaw
                let newDisplay = committedPrefix + activePreedit
                return MinimalDiff.calculate(previous: prevDisplay, next: newDisplay)
            }
        }

        // 7. Input Method Rule Processing via Candidate Evaluation or Incremental Transform
        let candidateKeys = activeRawKeys + [character]
        var tempState = transformState
        let (stepTransformed, _) = transformStep(
            inputChar: character,
            previousDisplay: activePreedit,
            rawHistory: activeRawKeys,
            state: &tempState
        )

        let targetActive: String
        let candidateState: SyllableTransformState
        if didBackspace {
            didBackspace = false
            let (candidateTransformed, rawState) = evaluateRaw(keys: candidateKeys)
            let candidateVowels = candidateTransformed.filter { PhonotacticsMatrix.isVowelChar($0) }.count
            let stepVowels = stepTransformed.filter { PhonotacticsMatrix.isVowelChar($0) }.count
            if candidateVowels > stepVowels {
                targetActive = candidateTransformed
                candidateState = rawState
            } else {
                targetActive = stepTransformed
                candidateState = tempState
            }
        } else {
            targetActive = stepTransformed
            candidateState = tempState
        }

        // 8. Stop Coda Tone & Invalid Coda Cluster Validation on Result
        if _config.autoCorrectEnglish {
            if let parsed = Syllable.parse(from: targetActive) {
                if !PhonotacticsMatrix.isValidStopCodaTone(coda: parsed.coda, tone: parsed.tone)
                    || EnglishRestoreDetector.hasInvalidCodaCluster(parsed.coda) {
                    // Violation
                    isBypassed = true
                    wordRawKeys.append(character)
                    activeRawKeys.append(character)
                    activePreedit = candidateRaw
                    let newDisplay = committedPrefix + activePreedit
                    return MinimalDiff.calculate(previous: prevDisplay, next: newDisplay)
                }
            }
        }

        // 9. Commit Transformation
        wordRawKeys.append(character)
        activeRawKeys.append(character)
        activePreedit = targetActive
        transformState = candidateState
        if candidateState.isBypassed {
            isBypassed = true
        }
        let newDisplay = committedPrefix + activePreedit

        // Fast-path: Pure single-character append matching native typing returns nil for zero overhead
        if newDisplay == prevDisplay + String(character) {
            return nil
        }

        return MinimalDiff.calculate(previous: prevDisplay, next: newDisplay)
    }

    // MARK: - Backspace Handling
    public func handleBackspace() -> Bool {
        lock.withLock {
            let prevDisplay = committedPrefix + activePreedit
            guard !prevDisplay.isEmpty || !activeRawKeys.isEmpty else {
                return false
            }

            let wasBypassed = isBypassed
            isBypassed = false
            didBackspace = true

            if !wordRawKeys.isEmpty {
                wordRawKeys.removeLast()
            }
            if !activeRawKeys.isEmpty {
                activeRawKeys.removeLast()
            }
            if !activePreedit.isEmpty {
                activePreedit.removeLast()
            } else if !committedPrefix.isEmpty {
                committedPrefix.removeLast()
            }

            // Check if remaining word should retain bypass (e.g. English keywords or foreign clusters)
            if wasBypassed && !wordRawKeys.isEmpty {
                let remainingWord = String(wordRawKeys).lowercased()
                if EnglishRestoreDetector.isEnglishKeyword(remainingWord) {
                    isBypassed = true
                    activePreedit = String(activeRawKeys)
                } else {
                    for cluster in EnglishRestoreDetector.invalidOnsetClusters {
                        if remainingWord.hasPrefix(cluster) {
                            isBypassed = true
                            activePreedit = String(activeRawKeys)
                            break
                        }
                    }
                }
            }

            // Recompute transform state for remaining active keys if not bypassed
            if !isBypassed && !activeRawKeys.isEmpty {
                let (reconstructed, state) = evaluateRaw(keys: activeRawKeys)
                transformState = state
                if activePreedit.count > reconstructed.count {
                    activePreedit = reconstructed
                }
            } else if isBypassed {
                transformState = SyllableTransformState()
            } else {
                transformState = SyllableTransformState()
            }

            if activeRawKeys.isEmpty && activePreedit.isEmpty && committedPrefix.isEmpty {
                internalReset()
                return true
            }

            return true
        }
    }

    // MARK: - Reset
    public func reset() {
        lock.withLock {
            internalReset()
        }
    }

    private func internalReset() {
        committedPrefix = ""
        activePreedit = ""
        activeRawKeys.removeAll(keepingCapacity: true)
        wordRawKeys.removeAll(keepingCapacity: true)
        isBypassed = false
        didBackspace = false
        transformState = SyllableTransformState()
    }

    // MARK: - Syllable Splitting Detection
    private func shouldSplitSyllable(currentDisplay: String, nextChar: Character) -> Bool {
        guard !currentDisplay.isEmpty else { return false }
        guard !PhonotacticsMatrix.isVowelChar(nextChar) else { return false }
        guard let parsed = Syllable.parse(from: currentDisplay), !parsed.nucleus.isEmpty else {
            return false
        }

        let method = _config.inputMethod
        if method == .telex || method == .simpleTelex {
            let isTone = InputMethodDefinitions.isToneOrClearKey(nextChar, method: method)
            let lower = Character(nextChar.lowercased())
            let isDiac = "aweod".contains(lower)
            if isTone || isDiac {
                return false
            }
        } else if method == .vni {
            if nextChar.isNumber { return false }
        }

        let lowerNext = Character(nextChar.lowercased())
        if (lowerNext == "n" && parsed.coda.lowercased().hasSuffix("n"))
            || (lowerNext == "c" && parsed.coda.lowercased().hasSuffix("c")) {
            return false
        }

        // Case 1: Nucleus is an off-glide (cannot take any coda)
        let offGlides: Set<String> = [
            "ai", "ao", "au", "âu", "ay", "ây", "eo", "êu", "ia", "iêu", "iu",
            "oai", "oao", "oay", "oeo", "oi", "ôi", "ơi", "ưa", "uây", "ui",
            "ưi", "uôi", "ươi", "ươu", "ưu", "uya", "uyu", "yêu"
        ]
        let lowerNuc = parsed.nucleus.lowercased()
        if offGlides.contains(lowerNuc) {
            return true
        }

        // Case 2: Syllable already has a valid coda, and nextChar is a valid onset that cannot extend the coda
        if !parsed.coda.isEmpty && PhonotacticsMatrix.isValidCoda(parsed.coda) {
            let candidateCoda = parsed.coda + String(nextChar)
            if !PhonotacticsMatrix.isValidCoda(candidateCoda) && !PhonotacticsMatrix.lookupFC(String(nextChar)).isEmpty {
                return true
            }
        }

        return false
    }

    // MARK: - Raw Keystroke Evaluation
    private func evaluateRaw(
        keys: [Character]
    ) -> (result: String, state: SyllableTransformState) {
        var current = ""
        var history: [Character] = []
        var state = SyllableTransformState()

        for k in keys {
            if state.isBypassed {
                current.append(k)
                history.append(k)
                continue
            }
            let (target, _) = transformStep(
                inputChar: k,
                previousDisplay: current,
                rawHistory: history,
                state: &state
            )
            history.append(k)
            current = target
        }
        return (current, state)
    }

    // MARK: - Keystroke Transformation Engine
    
    private func transformStep(
        inputChar: Character,
        previousDisplay: String,
        rawHistory: [Character],
        state: inout SyllableTransformState
    ) -> (result: String, isTransformation: Bool) {
        let method = _config.inputMethod
        let toneStyle = _config.tonePlacement
        let escape = _config.escapeByDoubleKey

        // MARK: Full Telex Standalone 'w'
        if method == .telex && previousDisplay.isEmpty {
            if inputChar == "w" || inputChar == "W" {
                state.isStandaloneW = true
                state.lastDiacriticKey = inputChar
                let target = inputChar.isUppercase ? "Ư" : "ư"
                return (target, true)
            }
        }

        // Standalone 'w' double-press undo: "w" + "w" -> "w"
        if state.isStandaloneW && (inputChar == "w" || inputChar == "W") && escape {
            state.isStandaloneW = false
            state.lastDiacriticKey = nil
            let target = inputChar.isUppercase ? "W" : "w"
            return (target, true)
        }

        // MARK: VNI Numeric Pass-Through
        if method == .vni && inputChar.isNumber {
            let hasVowels = previousDisplay.contains { PhonotacticsMatrix.isVowelChar($0) }
            let hasD = previousDisplay.lowercased().contains("d")

            // If no vowel and no 'd', number passes through literally
            if !hasVowels && !(hasD && inputChar == "9") {
                return (previousDisplay + String(inputChar), false)
            }
            // If has tone 0 (clear tone) but no tone to clear: pass through
            if inputChar == "0" && !hasTone(in: previousDisplay) {
                return (previousDisplay + String(inputChar), false)
            }
        }

        // MARK: Explicit Tone Clearing ('z' in Telex, '0' in VNI)
        let toneRes = InputMethodDefinitions.resolveToneKey(inputChar, method: method)
        if toneRes.isClearTone {
            if hasTone(in: previousDisplay) {
                let stripped = TonePlacement.stripTone(from: previousDisplay)
                state.lastToneKey = nil
                return (stripped, true)
            } else {
                // No tone to clear: treat as literal character
                return (previousDisplay + String(inputChar), false)
            }
        }

        // MARK: Double-Press Tone Undo (e.g. 'bá' + 's' -> 'bas', 'mẹ' + 'j' -> 'mej')
        if let _ = toneRes.tone, escape, state.lastToneKey == inputChar {
            state.lastToneKey = nil
            state.isBypassed = true
            return (String(rawHistory), true)
        }

        // MARK: Non-Vowel Tone Key Override (e.g. nugr + f -> nugf)
        if method == .telex, let _ = toneRes.tone {
            if previousDisplay.contains(where: { PhonotacticsMatrix.isVowelChar($0) }) {
                if let last = previousDisplay.last, "sfrxjSFRXJ".contains(last) {
                    var modified = previousDisplay
                    modified.removeLast()
                    modified.append(inputChar)
                    return (modified, true)
                }
            }
        }

        // MARK: Ignore duplicate consonant coda to prevent invalid clusters (e.g. truon + n -> truon)
        if (previousDisplay.lowercased().hasSuffix("n") && inputChar.lowercased() == "n")
            || (previousDisplay.lowercased().hasSuffix("c") && inputChar.lowercased() == "c") {
            return (previousDisplay, true)
        }

        // MARK: Delayed Horn / Breve across Codas (e.g. nuoc + w -> nước, som + w -> sớm)
        if (method == .telex || method == .simpleTelex) && (inputChar == "w" || inputChar == "W") {
            if let parsed = Syllable.parse(from: previousDisplay), !parsed.coda.isEmpty {
                let lowerNuc = parsed.nucleus.lowercased()
                var newNucleus: String? = nil
                if lowerNuc == "uo" || lowerNuc == "ưo" {
                    newNucleus = parsed.nucleus.allSatisfy { $0.isUppercase } ? "ƯƠ" : "ươ"
                } else if lowerNuc == "o" {
                    newNucleus = parsed.nucleus.allSatisfy { $0.isUppercase } ? "Ơ" : "ơ"
                } else if lowerNuc == "u" {
                    newNucleus = parsed.nucleus.allSatisfy { $0.isUppercase } ? "Ư" : "ư"
                }
                if let nn = newNucleus {
                    var modifiedParsed = parsed
                    modifiedParsed.nucleus = nn
                    let recomposed = TonePlacement.composeSyllable(
                        vowels: Array(modifiedParsed.nucleus),
                        onset: modifiedParsed.onset,
                        coda: modifiedParsed.coda,
                        tone: modifiedParsed.tone,
                        style: toneStyle
                    )
                    return (modifiedParsed.applyCasing(recomposed), true)
                }
            }
        }

        // MARK: Delayed Circumflex across Codas (e.g. dong + o -> đông, toi + o -> tôi)
        if (method == .telex || method == .simpleTelex) {
            let lowerInput = inputChar.lowercased()
            if let parsed = Syllable.parse(from: previousDisplay), !parsed.coda.isEmpty {
                let lowerNuc = parsed.nucleus.lowercased()
                var newNucleus: String? = nil
                if lowerInput == "o" && (lowerNuc == "o" || lowerNuc == "oi") {
                    newNucleus = (lowerNuc == "oi") ? (parsed.nucleus.allSatisfy { $0.isUppercase } ? "ÔI" : "ôi")
                                                    : (parsed.nucleus.allSatisfy { $0.isUppercase } ? "Ô" : "ô")
                } else if lowerInput == "e" && lowerNuc == "e" {
                    newNucleus = parsed.nucleus.allSatisfy { $0.isUppercase } ? "Ê" : "ê"
                } else if lowerInput == "a" && lowerNuc == "a" {
                    newNucleus = parsed.nucleus.allSatisfy { $0.isUppercase } ? "Â" : "â"
                }
                if let nn = newNucleus {
                    var modifiedParsed = parsed
                    modifiedParsed.nucleus = nn
                    let recomposed = TonePlacement.composeSyllable(
                        vowels: Array(modifiedParsed.nucleus),
                        onset: modifiedParsed.onset,
                        coda: modifiedParsed.coda,
                        tone: modifiedParsed.tone,
                        style: toneStyle
                    )
                    return (modifiedParsed.applyCasing(recomposed), true)
                }
            }
        }


        // MARK: Tone Application & Overriding ("Last Tone Wins")
        if let tone = toneRes.tone {
            if let parsed = Syllable.parse(from: previousDisplay), !parsed.nucleus.isEmpty {
                let isCodaValid = parsed.coda.isEmpty || PhonotacticsMatrix.isValidCoda(parsed.coda)
                if isCodaValid {
                    state.lastToneKey = inputChar
                    let tuned = applyTone(tone, to: previousDisplay, style: toneStyle)
                    return (tuned, true)
                }
            }
        }

        // MARK: Double-Press Diacritic Undo (e.g. 'â' + 'a' -> 'aa', 'đ' + 'd' -> 'dd')
        if escape, state.lastDiacriticKey == inputChar {
            if let undone = tryUndoDiacritic(lastChar: previousDisplay.last, trigger: inputChar, method: method) {
                state.lastDiacriticKey = nil
                var modified = previousDisplay
                modified.removeLast()
                modified.append(contentsOf: undone)
                return (modified, true)
            }
        }

        // MARK: Dual Horn Shortcut ('uow' / 'uwow' -> 'ươ') & 'w' on 'uô' absorption
        if (method == .telex || method == .simpleTelex) && (inputChar == "w" || inputChar == "W") {
            let lower = previousDisplay.lowercased()
            if lower.hasSuffix("uo") || lower.hasSuffix("ưo") {
                let isUpper = previousDisplay.allSatisfy { !$0.isLetter || $0.isUppercase }
                var modified = String(previousDisplay.dropLast(2))
                modified.append(isUpper ? "ƯƠ" : "ươ")
                state.lastDiacriticKey = inputChar
                return (modified, true)
            }
            if lower.hasSuffix("uô") || lower.contains("ô") {
                return (previousDisplay, true)
            }
        }

        if method == .vni && inputChar == "7" {
            let lower = previousDisplay.lowercased()
            if lower.hasSuffix("uo") {
                let isUpper = previousDisplay.allSatisfy { !$0.isLetter || $0.isUppercase }
                var modified = String(previousDisplay.dropLast(2))
                modified.append(isUpper ? "ƯƠ" : "ươ")
                state.lastDiacriticKey = inputChar
                return (modified, true)
            }
        }

        // MARK: Diacritic Application to Previous Letter
        if let lastChar = previousDisplay.last {
            if let modified = InputMethodDefinitions.applyDiacritic(to: lastChar, modifier: inputChar, method: method) {
                state.lastDiacriticKey = inputChar
                var result = String(previousDisplay.dropLast())
                result.append(modified)
                return (result, true)
            }
        }

        // MARK: Coda Consonant Tone Re-alignment (e.g. toa1 -> tóa, then n -> toán)
        if hasTone(in: previousDisplay) {
            let candidateDisplay = previousDisplay + String(inputChar)
            if let parsed = Syllable.parse(from: candidateDisplay),
               PhonotacticsMatrix.isValidCoda(parsed.coda),
               parsed.tone != .none {
                var modifiedParsed = parsed
                let lowerNuc = parsed.nucleus.lowercased()
                if lowerNuc == "ie" {
                    let isUpperNuc = parsed.nucleus.allSatisfy { $0.isUppercase }
                    modifiedParsed.nucleus = isUpperNuc ? "IÊ" : "iê"
                } else if lowerNuc == "uye" {
                    let isUpperNuc = parsed.nucleus.allSatisfy { $0.isUppercase }
                    modifiedParsed.nucleus = isUpperNuc ? "UYÊ" : "uyê"
                }
                let recomposed = TonePlacement.composeSyllable(
                    vowels: Array(modifiedParsed.nucleus),
                    onset: modifiedParsed.onset,
                    coda: modifiedParsed.coda,
                    tone: modifiedParsed.tone,
                    style: toneStyle
                )
                let finalStr = modifiedParsed.applyCasing(recomposed)
                return (finalStr, true)
            }
        }

        // MARK: Default Literal Character Append
        state.lastDiacriticKey = nil
        state.isStandaloneW = false
        return (previousDisplay + String(inputChar), false)
    }

    // MARK: - Linguistic Helpers
    
    private func hasTone(in string: String) -> Bool {
        for char in string {
            let (_, tone) = TonePlacement.removeTone(from: char)
            if tone != .none {
                return true
            }
        }
        return false
    }

    private func applyTone(_ tone: Tone, to string: String, style: TonePlacementStyle) -> String {
        // Parse into CVC syllable structure
        if var parsed = Syllable.parse(from: string) {
            let lowerNuc = parsed.nucleus.lowercased()
            if !parsed.coda.isEmpty && lowerNuc == "ie" {
                let isUpperNuc = parsed.nucleus.allSatisfy { $0.isUppercase }
                parsed.nucleus = isUpperNuc ? "IÊ" : "iê"
            }
            if !parsed.coda.isEmpty && lowerNuc == "uye" {
                let isUpperNuc = parsed.nucleus.allSatisfy { $0.isUppercase }
                parsed.nucleus = isUpperNuc ? "UYÊ" : "uyê"
            }
            let composed = TonePlacement.composeSyllable(
                vowels: Array(parsed.nucleus),
                onset: parsed.onset,
                coda: parsed.coda,
                tone: tone,
                style: style
            )
            return parsed.applyCasing(composed)
        }
        return string
    }

    private func tryUndoDiacritic(lastChar: Character?, trigger: Character, method: InputMethod) -> String? {
        guard let lc = lastChar else { return nil }
        // Check toneless version if lastChar has a tone
        let (baseChar, tone) = TonePlacement.removeTone(from: lc)
        if let pair = InputMethodDefinitions.undoDiacritic(character: baseChar, triggerKey: trigger, method: method) {
            if tone != .none {
                // Re-apply tone to first character of pair if possible
                let tuned = TonePlacementEngine.composeSyllableWithTone(pair, tone: tone)
                return tuned
            }
            return pair
        }
        return nil
    }
}

extension TonePlacementEngine {
    static func composeSyllableWithTone(_ string: String, tone: Tone) -> String {
        guard let first = string.first else { return string }
        let isUpper = first.isUppercase
        let lower = Character(first.lowercased())
        let table = isUpper ? uppercaseVowelTable : lowercaseVowelTable
        if let toneRow = table[lower], let tuned = toneRow[tone] {
            return String(tuned) + string.dropFirst()
        }
        return string
    }
}
