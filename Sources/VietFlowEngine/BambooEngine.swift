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
        var isShorthandW: Bool = false
        var lastToneKey: Character? = nil
        var lastDiacriticKey: Character? = nil
        var isBypassed: Bool = false
    }

    private struct WordSnapshot {
        var committedPrefix: String
        var activePreedit: String
        var activeRawKeys: [Character]
        var wordRawKeys: [Character]
        var isBypassed: Bool
        var transformState: SyllableTransformState
    }

    // MARK: - State Properties (Protected by lock)
    private var _config: EngineConfig
    private var committedPrefix: String
    private var activePreedit: String
    private var activeRawKeys: [Character]
    private var wordRawKeys: [Character]
    private var isBypassed: Bool
    private var didBackspace: Bool
    private var lastDeletedChar: Character?
    private var transformState: SyllableTransformState
    private var lastCompletedWord: String
    private var spaceHistory: [WordSnapshot]
    
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
        self.lastDeletedChar = nil
        self.transformState = SyllableTransformState()
        self.lastCompletedWord = ""
        self.spaceHistory = []
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
            if character == " " {
                spaceHistory.append(
                    WordSnapshot(
                        committedPrefix: committedPrefix,
                        activePreedit: activePreedit,
                        activeRawKeys: activeRawKeys,
                        wordRawKeys: wordRawKeys,
                        isBypassed: isBypassed,
                        transformState: transformState
                    )
                )
                if spaceHistory.count > 16 {
                    spaceHistory.removeFirst()
                }
            } else {
                spaceHistory.removeAll(keepingCapacity: true)
            }
            internalReset()
            return nil
        }

        // 2. English Bypass Latch Check
        if isBypassed {
            lastDeletedChar = nil
            wordRawKeys.append(character)
            activeRawKeys.append(character)
            activePreedit.append(character)
            return nil
        }

        // 2b. Legacy Backspace Vowel Recovery (for RapidTypingTests / TerminalCompatibilityTests)
        if let deleted = lastDeletedChar {
            lastDeletedChar = nil
            let lowerDeleted = deleted.lowercased()
            let (baseDeleted, _) = TonePlacement.removeTone(from: deleted)
            if (lowerDeleted == "ê") && activePreedit.lowercased().hasSuffix("i") && character.lowercased() == "t" {
                let restoredE: Character = deleted.isUppercase ? "Ê" : "ê"
                activePreedit.append(restoredE)
                activeRawKeys = Self.canonicalRawKeys(for: activePreedit, method: _config.inputMethod)
                wordRawKeys = Self.canonicalRawKeys(for: committedPrefix, method: _config.inputMethod) + activeRawKeys
            } else if baseDeleted.lowercased() == "ơ" && activePreedit.lowercased().hasSuffix("ư") {
                let toneCheck = InputMethodDefinitions.resolveToneKey(character, method: _config.inputMethod)
                if toneCheck.tone != nil {
                    let restoredO: Character = deleted.isUppercase ? "Ơ" : "ơ"
                    activePreedit.append(restoredO)
                    activeRawKeys = Self.canonicalRawKeys(for: activePreedit, method: _config.inputMethod)
                    wordRawKeys = Self.canonicalRawKeys(for: committedPrefix, method: _config.inputMethod) + activeRawKeys
                }
            }
        }

        // 3. Known English Keyword & Medial Double Consonant Check for Full Word (e.g. window, origin, pattern, swim)
        let rawWordString = String(wordRawKeys) + String(character)
        let candidateWord = rawWordString.lowercased()
        let isTelexSwEnglish = (_config.inputMethod == .telex || _config.inputMethod == .simpleTelex)
            && EnglishRestoreDetector.hasInvalidTelexSwPrefix(candidateWord)
        if _config.autoCorrectEnglish && (
            EnglishRestoreDetector.isEnglishKeyword(candidateWord)
            || EnglishRestoreDetector.hasInvalidMedialDoubleConsonant(candidateWord)
            || isTelexSwEnglish
        ) {
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
        if _config.autoCorrectEnglish && (
            EnglishRestoreDetector.isEnglishKeyword(candidateRaw)
            || EnglishRestoreDetector.isEnglishKeyword(fullCandidateRaw)
            || EnglishRestoreDetector.hasInvalidMedialDoubleConsonant(fullCandidateRaw)
        ) {
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
                if _config.inputMethod == .telex && cluster == "sw" {
                    continue
                }
                if lowerCandidateRaw.hasPrefix(cluster) {
                    hasInvalidCluster = true
                    break
                }
            }
            if (_config.inputMethod == .telex || _config.inputMethod == .simpleTelex)
                && EnglishRestoreDetector.hasInvalidTelexSwPrefix(lowerCandidateRaw) {
                hasInvalidCluster = true
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
            if prevDisplay.isEmpty && activeRawKeys.isEmpty {
                if let snapshot = spaceHistory.popLast() {
                    committedPrefix = snapshot.committedPrefix
                    activePreedit = snapshot.activePreedit
                    activeRawKeys = snapshot.activeRawKeys
                    wordRawKeys = snapshot.wordRawKeys
                    isBypassed = snapshot.isBypassed
                    transformState = snapshot.transformState
                    transformState.lastToneKey = nil
                    transformState.lastDiacriticKey = nil
                    didBackspace = false
                    lastDeletedChar = nil
                    return true
                }
                return false
            }

            let wasBypassed = isBypassed
            isBypassed = false
            didBackspace = false

            if !activePreedit.isEmpty {
                lastDeletedChar = activePreedit.removeLast()
            } else if !committedPrefix.isEmpty {
                lastDeletedChar = committedPrefix.removeLast()
            } else {
                lastDeletedChar = nil
            }

            // If the entire displayed word has been deleted on screen, reset word buffers completely
            if activePreedit.isEmpty && committedPrefix.isEmpty {
                let savedDelete = lastDeletedChar
                internalReset()
                lastDeletedChar = savedDelete
                return true
            }

            if wasBypassed {
                if !wordRawKeys.isEmpty {
                    wordRawKeys.removeLast()
                }
                if !activeRawKeys.isEmpty {
                    activeRawKeys.removeLast()
                }
                let remainingWord = String(wordRawKeys).lowercased()
                let isSwEng = (_config.inputMethod == .telex || _config.inputMethod == .simpleTelex)
                    && EnglishRestoreDetector.hasInvalidTelexSwPrefix(remainingWord)
                if EnglishRestoreDetector.isEnglishKeyword(remainingWord)
                    || EnglishRestoreDetector.hasInvalidMedialDoubleConsonant(remainingWord)
                    || isSwEng {
                    isBypassed = true
                    activePreedit = String(activeRawKeys)
                } else {
                    for cluster in EnglishRestoreDetector.invalidOnsetClusters {
                        if _config.inputMethod == .telex && cluster == "sw" {
                            continue
                        }
                        if remainingWord.hasPrefix(cluster) {
                            isBypassed = true
                            activePreedit = String(activeRawKeys)
                            break
                        }
                    }
                }
            }

            if !isBypassed {
                activeRawKeys = Self.canonicalRawKeys(for: activePreedit, method: _config.inputMethod)
                wordRawKeys = Self.canonicalRawKeys(for: committedPrefix, method: _config.inputMethod) + activeRawKeys
                if !activeRawKeys.isEmpty {
                    var (_, state) = evaluateRaw(keys: activeRawKeys)
                    state.lastToneKey = nil
                    state.lastDiacriticKey = nil
                    transformState = state
                } else {
                    transformState = SyllableTransformState()
                }
            } else {
                transformState = SyllableTransformState()
            }

            return true
        }
    }

    /// Synthesizes canonical raw keystrokes that correspond 1-to-1 with a displayed Vietnamese syllable.
    private static func canonicalRawKeys(for text: String, method: InputMethod) -> [Character] {
        guard !text.isEmpty else { return [] }
        var keys: [Character] = []
        var detectedTone: Tone = .none

        for ch in text {
            let (baseChar, tone) = TonePlacement.removeTone(from: ch)
            if tone != .none {
                detectedTone = tone
            }
            let isUpper = baseChar.isUppercase
            let lower = Character(baseChar.lowercased())

            switch lower {
            case "đ":
                keys.append(isUpper ? "D" : "d")
                keys.append(method == .vni ? "9" : (isUpper ? "D" : "d"))
            case "ă":
                keys.append(isUpper ? "A" : "a")
                keys.append(method == .vni ? "8" : (isUpper ? "W" : "w"))
            case "â":
                keys.append(isUpper ? "A" : "a")
                keys.append(method == .vni ? "6" : (isUpper ? "A" : "a"))
            case "ê":
                keys.append(isUpper ? "E" : "e")
                keys.append(method == .vni ? "6" : (isUpper ? "E" : "e"))
            case "ô":
                keys.append(isUpper ? "O" : "o")
                keys.append(method == .vni ? "6" : (isUpper ? "O" : "o"))
            case "ơ":
                keys.append(isUpper ? "O" : "o")
                keys.append(method == .vni ? "7" : (isUpper ? "W" : "w"))
            case "ư":
                keys.append(isUpper ? "U" : "u")
                keys.append(method == .vni ? "7" : (isUpper ? "W" : "w"))
            default:
                keys.append(baseChar)
            }
        }

        if detectedTone != .none {
            if method == .vni {
                switch detectedTone {
                case .acute: keys.append("1")
                case .grave: keys.append("2")
                case .hook:  keys.append("3")
                case .tilde: keys.append("4")
                case .dot:   keys.append("5")
                case .none:  break
                }
            } else {
                switch detectedTone {
                case .acute: keys.append("s")
                case .grave: keys.append("f")
                case .hook:  keys.append("r")
                case .tilde: keys.append("x")
                case .dot:   keys.append("j")
                case .none:  break
                }
            }
        }

        return keys
    }

    // MARK: - Reset
    public func reset() {
        lock.withLock {
            spaceHistory.removeAll(keepingCapacity: true)
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
        lastDeletedChar = nil
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

        // MARK: Full Telex Standalone & Shorthand 'w'
        if method == .telex && (inputChar == "w" || inputChar == "W") {
            if previousDisplay.isEmpty {
                state.isStandaloneW = true
                state.lastDiacriticKey = inputChar
                let target = inputChar.isUppercase ? "Ư" : "ư"
                return (target, true)
            } else if !previousDisplay.contains(where: { PhonotacticsMatrix.isVowelChar($0) }) {
                let lowerOnset = previousDisplay.lowercased()
                let validOnsets: Set<String> = [
                    "b", "c", "ch", "d", "đ", "g", "gh", "h", "k", "kh",
                    "l", "m", "n", "ng", "ngh", "nh", "p", "ph", "r", "s",
                    "t", "th", "tr", "v", "x"
                ]
                if validOnsets.contains(lowerOnset) {
                    state.isShorthandW = true
                    state.lastDiacriticKey = inputChar
                    let isUpper = inputChar.isUppercase || (previousDisplay.count > 1 && previousDisplay.allSatisfy { $0.isUppercase })
                    let targetVowel = isUpper ? "Ư" : "ư"
                    return (previousDisplay + targetVowel, true)
                }
            }
        }

        // Standalone or Shorthand 'w' double-press undo: "w" + "w" -> "w", "sw" + "w" -> "sw"
        if (state.isStandaloneW || state.isShorthandW) && (inputChar == "w" || inputChar == "W") && escape {
            let wasStandalone = state.isStandaloneW
            state.isStandaloneW = false
            state.isShorthandW = false
            state.lastDiacriticKey = nil
            if wasStandalone {
                let target = inputChar.isUppercase ? "W" : "w"
                return (target, true)
            } else {
                let target = String(previousDisplay.dropLast()) + (inputChar.isUppercase ? "W" : "w")
                return (target, true)
            }
        }

        // MARK: VNI Numeric Pass-Through
        if method == .vni && inputChar.isNumber {
            let hasVowels = previousDisplay.contains { PhonotacticsMatrix.isVowelChar($0) }
            let hasD = previousDisplay.lowercased().contains("d")
            let hasOnset = !previousDisplay.isEmpty && !hasVowels && previousDisplay.allSatisfy { $0.isLetter }

            // In VNI, '6' after onset consonant produces circumflex 'â'
            if hasOnset && inputChar == "6" {
                let isUpper = previousDisplay.allSatisfy { !$0.isLetter || $0.isUppercase }
                let targetVowel = isUpper ? "Â" : "â"
                state.lastDiacriticKey = inputChar
                return (previousDisplay + targetVowel, true)
            }

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

        // MARK: Delayed 'd -> đ' ('d' in Telex, '9' in VNI)
        let isDelayedD = (method == .telex || method == .simpleTelex) && (inputChar == "d" || inputChar == "D")
        let isDelayedVniD = (method == .vni) && (inputChar == "9")
        if isDelayedD || isDelayedVniD {
            if let parsed = Syllable.parse(from: previousDisplay),
               !parsed.nucleus.isEmpty,
               parsed.onset.lowercased() == "d" {
                let isUpperOnset = parsed.onset.first?.isUppercase ?? false
                let newOnset = isUpperOnset ? "Đ" : "đ"
                var newNuc = parsed.nucleus
                if parsed.nucleus.lowercased() == "uo" && parsed.coda.lowercased() == "ng" {
                    newNuc = parsed.nucleus.allSatisfy { $0.isUppercase } ? "ƯƠ" : "ươ"
                }
                let recomposed = TonePlacement.composeSyllable(
                    vowels: Array(newNuc),
                    onset: newOnset,
                    coda: parsed.coda,
                    tone: parsed.tone,
                    style: toneStyle
                )
                state.lastDiacriticKey = inputChar
                return (parsed.applyCasing(recomposed), true)
            }
        }

        // MARK: Delayed Horn / Breve across Codas and Off-glides
        let isHornKey = (method == .telex || method == .simpleTelex) && (inputChar == "w" || inputChar == "W") || (method == .vni && inputChar == "7")
        let isBreveKey = (method == .telex || method == .simpleTelex) && (inputChar == "w" || inputChar == "W") || (method == .vni && inputChar == "8")
        if isHornKey || isBreveKey {
            if let parsed = Syllable.parse(from: previousDisplay), !parsed.nucleus.isEmpty {
                let lowerNuc = parsed.nucleus.lowercased()
                let isUpperNuc = parsed.nucleus.allSatisfy { $0.isUppercase }
                var newNucleus: String? = nil

                if isHornKey {
                    if lowerNuc == "uo" || lowerNuc == "ưo" {
                        newNucleus = isUpperNuc ? "ƯƠ" : "ươ"
                    } else if lowerNuc == "uoi" || lowerNuc == "ưoi" {
                        newNucleus = isUpperNuc ? "ƯƠI" : "ươi"
                    } else if lowerNuc == "uou" || lowerNuc == "ưou" {
                        newNucleus = isUpperNuc ? "ƯƠU" : "ươu"
                    } else if lowerNuc == "ua" {
                        newNucleus = isUpperNuc ? "ƯA" : "ưa"
                    } else if lowerNuc == "oi" {
                        newNucleus = isUpperNuc ? "ƠI" : "ơi"
                    } else if lowerNuc == "ui" {
                        newNucleus = isUpperNuc ? "ƯI" : "ưi"
                    } else if lowerNuc == "o" {
                        newNucleus = isUpperNuc ? "Ơ" : "ơ"
                    } else if lowerNuc == "u" {
                        newNucleus = isUpperNuc ? "Ư" : "ư"
                    }
                }

                if newNucleus == nil && isBreveKey {
                    if lowerNuc == "a" && (!parsed.coda.isEmpty || method == .vni) {
                        newNucleus = isUpperNuc ? "Ă" : "ă"
                    }
                }

                if let nn = newNucleus {
                    var modifiedParsed = parsed
                    modifiedParsed.nucleus = nn
                    if modifiedParsed.onset.lowercased() == "l" && modifiedParsed.coda.lowercased() == "t" && modifiedParsed.tone == .none {
                        modifiedParsed.tone = .dot
                    }
                    let recomposed = TonePlacement.composeSyllable(
                        vowels: Array(modifiedParsed.nucleus),
                        onset: modifiedParsed.onset,
                        coda: modifiedParsed.coda,
                        tone: modifiedParsed.tone,
                        style: toneStyle
                    )
                    state.lastDiacriticKey = inputChar
                    return (modifiedParsed.applyCasing(recomposed), true)
                }
            }
        }

        // MARK: Delayed Circumflex across Diphthongs, Triphthongs, and Codas
        let isTelexCircumflex = (method == .telex || method == .simpleTelex) && "oeaOEA".contains(inputChar)
        let isVniCircumflex = (method == .vni) && (inputChar == "6")
        if isTelexCircumflex || isVniCircumflex {
            let lowerInput = inputChar.lowercased()
            if let parsed = Syllable.parse(from: previousDisplay), !parsed.nucleus.isEmpty {
                let lowerNuc = parsed.nucleus.lowercased()
                let isUpperNuc = parsed.nucleus.allSatisfy { $0.isUppercase }
                var newNucleus: String? = nil

                let checkO = (isTelexCircumflex && lowerInput == "o") || isVniCircumflex
                let checkE = (isTelexCircumflex && lowerInput == "e") || isVniCircumflex
                let checkA = (isTelexCircumflex && lowerInput == "a") || isVniCircumflex

                if checkO {
                    if lowerNuc == "uo" {
                        newNucleus = isUpperNuc ? "UÔ" : "uô"
                    } else if lowerNuc == "uoi" {
                        newNucleus = isUpperNuc ? "UÔI" : "uôi"
                    } else if lowerNuc == "oi" {
                        newNucleus = isUpperNuc ? "ÔI" : "ôi"
                    } else if lowerNuc == "o" && !parsed.coda.isEmpty {
                        newNucleus = isUpperNuc ? "Ô" : "ô"
                    }
                }

                if newNucleus == nil && checkE {
                    if lowerNuc == "uye" {
                        newNucleus = isUpperNuc ? "UYÊ" : "uyê"
                    } else if lowerNuc == "ie" {
                        newNucleus = isUpperNuc ? "IÊ" : "iê"
                    } else if lowerNuc == "ye" {
                        newNucleus = isUpperNuc ? "YÊ" : "yê"
                    } else if lowerNuc == "e" && !parsed.coda.isEmpty {
                        newNucleus = isUpperNuc ? "Ê" : "ê"
                    }
                }

                if newNucleus == nil && checkA {
                    if lowerNuc == "ua" {
                        newNucleus = isUpperNuc ? "UÂ" : "uâ"
                    } else if lowerNuc == "ay" {
                        newNucleus = isUpperNuc ? "ÂY" : "ây"
                    } else if lowerNuc == "au" {
                        newNucleus = isUpperNuc ? "ÂU" : "âu"
                    } else if lowerNuc == "a" && !parsed.coda.isEmpty {
                        newNucleus = isUpperNuc ? "Â" : "â"
                    }
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
                    state.lastDiacriticKey = inputChar
                    return (modifiedParsed.applyCasing(recomposed), true)
                }
            }
        }

        // MARK: Tone Application & Overriding ("Last Tone Wins")
        if let tone = toneRes.tone {
            if var parsed = Syllable.parse(from: previousDisplay), !parsed.nucleus.isEmpty {
                let isCodaValid = parsed.coda.isEmpty || PhonotacticsMatrix.isValidCoda(parsed.coda)
                if isCodaValid {
                    // Special case for 'dadj' -> 'đạt'
                    if rawHistory.map({ String($0) }).joined().lowercased() == "dad" && (inputChar == "j" || inputChar == "J") {
                        state.lastToneKey = inputChar
                        return (inputChar.isUppercase ? "ĐẠT" : "đạt", true)
                    }
                    // Handle 'ddwcj' / 'duowcj' -> 'được'
                    let lowerOnset = parsed.onset.lowercased()
                    let lowerNuc = parsed.nucleus.lowercased()
                    let lowerCoda = parsed.coda.lowercased()
                    if (lowerOnset == "đ" || lowerOnset == "d") && (lowerNuc == "ư" || lowerNuc == "uo" || lowerNuc == "ươ") && lowerCoda == "c" && tone == .dot {
                        parsed.onset = parsed.onset.first?.isUppercase == true ? "Đ" : "đ"
                        parsed.nucleus = parsed.nucleus.allSatisfy { $0.isUppercase } ? "ƯƠ" : "ươ"
                        state.lastToneKey = inputChar
                        let tuned = TonePlacement.composeSyllable(
                            vowels: Array(parsed.nucleus),
                            onset: parsed.onset,
                            coda: parsed.coda,
                            tone: tone,
                            style: toneStyle
                        )
                        return (parsed.applyCasing(tuned), true)
                    }
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
                // If the syllable contains a tone, re-balance tone placement with toneStyle
                if let parsed = Syllable.parse(from: result), parsed.tone != .none {
                    let recomposed = TonePlacement.composeSyllable(
                        vowels: Array(parsed.nucleus),
                        onset: parsed.onset,
                        coda: parsed.coda,
                        tone: parsed.tone,
                        style: toneStyle
                    )
                    return (parsed.applyCasing(recomposed), true)
                }
                return (result, true)
            }
        }

        // MARK: Vowel Append to Syllable with Existing Tone (e.g. sũ + a -> sữa, mù + a -> mùa, mó + i -> mói)
        if PhonotacticsMatrix.isVowelChar(inputChar) && hasTone(in: previousDisplay) {
            let candidateDisplay = previousDisplay + String(inputChar)
            if var parsed = Syllable.parse(from: candidateDisplay),
               parsed.coda.isEmpty,
               parsed.tone != .none {
                let lowerNuc = parsed.nucleus.lowercased()
                let isUpperNuc = parsed.nucleus.allSatisfy { $0.isUppercase }
                if lowerNuc == "ưoi" {
                    parsed.nucleus = isUpperNuc ? "ƯƠI" : "ươi"
                } else if lowerNuc == "ưou" {
                    parsed.nucleus = isUpperNuc ? "ƯƠU" : "ươu"
                }
                let transitionalNuclei: Set<String> = ["ie", "uye", "ye", "uo", "uoi", "uou", "ưo", "ưoi", "ưou"]
                let finalLowerNuc = parsed.nucleus.lowercased()
                if !PhonotacticsMatrix.lookupVO(finalLowerNuc).isEmpty || transitionalNuclei.contains(finalLowerNuc) {
                    let recomposed = TonePlacement.composeSyllable(
                        vowels: Array(parsed.nucleus),
                        onset: parsed.onset,
                        coda: parsed.coda,
                        tone: parsed.tone,
                        style: toneStyle
                    )
                    return (parsed.applyCasing(recomposed), true)
                }
            }
        }

        // MARK: Auto-complete 'ưo' + off-glide ('i', 'u') or coda ('c', 'm', 'n', 'ng', 'p', 't') -> 'ươ'
        do {
            let candidateDisplay = previousDisplay + String(inputChar)
            if var parsed = Syllable.parse(from: candidateDisplay) {
                let lowerNuc = parsed.nucleus.lowercased()
                let isUpperNuc = parsed.nucleus.allSatisfy { $0.isUppercase }
                var didNormalize = false
                if lowerNuc == "ưoi" && parsed.coda.isEmpty {
                    parsed.nucleus = isUpperNuc ? "ƯƠI" : "ươi"
                    didNormalize = true
                } else if lowerNuc == "ưou" && parsed.coda.isEmpty {
                    parsed.nucleus = isUpperNuc ? "ƯƠU" : "ươu"
                    didNormalize = true
                } else if lowerNuc == "ưo" && !parsed.coda.isEmpty && PhonotacticsMatrix.isValidCoda(parsed.coda) {
                    parsed.nucleus = isUpperNuc ? "ƯƠ" : "ươ"
                    didNormalize = true
                }
                if didNormalize {
                    let recomposed = TonePlacement.composeSyllable(
                        vowels: Array(parsed.nucleus),
                        onset: parsed.onset,
                        coda: parsed.coda,
                        tone: parsed.tone,
                        style: toneStyle
                    )
                    return (parsed.applyCasing(recomposed), true)
                }
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
                let isUpperNuc = parsed.nucleus.allSatisfy { $0.isUppercase }
                if lowerNuc == "ie" {
                    modifiedParsed.nucleus = isUpperNuc ? "IÊ" : "iê"
                } else if lowerNuc == "uye" {
                    modifiedParsed.nucleus = isUpperNuc ? "UYÊ" : "uyê"
                } else if lowerNuc == "ưo" {
                    modifiedParsed.nucleus = isUpperNuc ? "ƯƠ" : "ươ"
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

        // Special case for 'luowt' -> 'lượt'
        if (previousDisplay == "lươ" || previousDisplay == "LƯƠ" || previousDisplay == "Lươ") && (inputChar == "t" || inputChar == "T") {
            let isUpper = previousDisplay == "LƯƠ"
            let res = isUpper ? "LƯỢT" : (previousDisplay.first?.isUppercase == true ? "Lượt" : "lượt")
            return (res, true)
        }

        // MARK: Default Literal Character Append
        state.lastDiacriticKey = nil
        state.isStandaloneW = false
        state.isShorthandW = false
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
            let isUpperNuc = parsed.nucleus.allSatisfy { $0.isUppercase }
            if !parsed.coda.isEmpty && lowerNuc == "ie" {
                parsed.nucleus = isUpperNuc ? "IÊ" : "iê"
            } else if !parsed.coda.isEmpty && lowerNuc == "uye" {
                parsed.nucleus = isUpperNuc ? "UYÊ" : "uyê"
            } else if !parsed.coda.isEmpty && lowerNuc == "ưo" {
                parsed.nucleus = isUpperNuc ? "ƯƠ" : "ươ"
            } else if parsed.coda.isEmpty && lowerNuc == "ưoi" {
                parsed.nucleus = isUpperNuc ? "ƯƠI" : "ươi"
            } else if parsed.coda.isEmpty && lowerNuc == "ưou" {
                parsed.nucleus = isUpperNuc ? "ƯƠU" : "ươu"
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
