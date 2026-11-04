//
//  AdaptiveLearner.swift
//  VietFlowEngine
//
//  Backspace Error Logger and Self-Learning Adaptive Correction System.
//  Detects Backspace-driven typing corrections, persists error patterns to
//  ~/Library/Application Support/VietFlow/typing_error_log.json, and adapts typing
//  once a pattern repeats 3 or more times (count >= 3) with zero hot-path latency regression.
//

import Foundation
import os
#if canImport(Carbon)
import Carbon
#endif

public enum CorrectionCategory: String, Codable, Sendable {
    case imeFriction = "imeFriction"
    case personalTypo = "personalTypo"
}

public struct TypingErrorEntry: Codable, Identifiable, Sendable {
    public var id: String
    public var rawKeysBeforeBackspace: String
    public var displayedBeforeBackspace: String
    public var finalCommittedText: String
    public var category: CorrectionCategory
    public var count: Int
    public var timestamps: [Date]
    public var firstSeen: Date
    public var lastSeen: Date
    public var isEnabled: Bool

    public init(
        id: String,
        rawKeysBeforeBackspace: String,
        displayedBeforeBackspace: String,
        finalCommittedText: String,
        category: CorrectionCategory,
        count: Int = 1,
        timestamps: [Date] = [Date()],
        firstSeen: Date = Date(),
        lastSeen: Date = Date(),
        isEnabled: Bool = true
    ) {
        self.id = id
        self.rawKeysBeforeBackspace = rawKeysBeforeBackspace
        self.displayedBeforeBackspace = displayedBeforeBackspace
        self.finalCommittedText = finalCommittedText
        self.category = category
        self.count = count
        self.timestamps = timestamps
        self.firstSeen = firstSeen
        self.lastSeen = lastSeen
        self.isEnabled = isEnabled
    }
}

public struct LearnedRule: Codable, Identifiable, Sendable {
    public var id: String
    public var trigger: String
    public var replacement: String
    public var category: CorrectionCategory
    public var count: Int
    public var isBypassTransform: Bool
    public var isPreserveVietnamese: Bool
    public var isEnabled: Bool
    public var lastApplied: Date?

    public init(
        id: String,
        trigger: String,
        replacement: String,
        category: CorrectionCategory,
        count: Int,
        isBypassTransform: Bool = false,
        isPreserveVietnamese: Bool = false,
        isEnabled: Bool = true,
        lastApplied: Date? = nil
    ) {
        self.id = id
        self.trigger = trigger
        self.replacement = replacement
        self.category = category
        self.count = count
        self.isBypassTransform = isBypassTransform
        self.isPreserveVietnamese = isPreserveVietnamese
        self.isEnabled = isEnabled
        self.lastApplied = lastApplied
    }
}

public struct TypingErrorLogFile: Codable, Sendable {
    public var version: Int
    public var entries: [TypingErrorEntry]
    public var learnedRules: [LearnedRule]

    public init(version: Int = 1, entries: [TypingErrorEntry] = [], learnedRules: [LearnedRule] = []) {
        self.version = version
        self.entries = entries
        self.learnedRules = learnedRules
    }
}

public final class AdaptiveLearningManager: @unchecked Sendable {
    public static let shared = AdaptiveLearningManager()

    private let lock: OSAllocatedUnfairLock<Void>
    public var fileURL: URL
    public var isEnabled: Bool = true
    public var isSecureEventInputActive: @Sendable () -> Bool

    // In-memory data store
    private var entries: [String: TypingErrorEntry] = [:]
    private var rules: [String: LearnedRule] = [:]

    // High-performance in-memory cache for O(1) hot-path lookups
    public private(set) var hasActiveBypassRules: Bool = false
    public private(set) var hasActivePreserveRules: Bool = false
    public private(set) var hasActiveTypoRules: Bool = false
    private var activeImeBypassWords: Set<String> = []
    private var activeImePreserveWords: Set<String> = []
    private var activePersonalTypos: [String: String] = [:]

    // Background persistence queue
    private let ioQueue = DispatchQueue(label: "com.nhanqv.VietFlow.adaptiveLearning.io", qos: .utility)
    private var pendingSaveWorkItem: DispatchWorkItem? = nil

    public static var defaultLogFileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("VietFlow", isDirectory: true)
        return dir.appendingPathComponent("typing_error_log.json")
    }

    public init(
        fileURL: URL? = nil,
        isSecureEventInputActive: @escaping @Sendable () -> Bool = {
            #if canImport(Carbon)
            return IsSecureEventInputEnabled()
            #else
            return false
            #endif
        }
    ) {
        self.lock = OSAllocatedUnfairLock()
        self.fileURL = fileURL ?? Self.defaultLogFileURL
        self.isSecureEventInputActive = isSecureEventInputActive
        loadFromFile()
    }

    // MARK: - Live Counts
    public var loggedPatternsCount: Int {
        lock.withLock { entries.count }
    }

    public var activeRulesCount: Int {
        lock.withLock {
            rules.values.filter { $0.isEnabled && $0.count >= 3 }.count
        }
    }

    public var allEntries: [TypingErrorEntry] {
        lock.withLock { Array(entries.values) }
    }

    public var allRules: [LearnedRule] {
        lock.withLock { Array(rules.values) }
    }

    // MARK: - Hot-Path O(1) Query Methods
    @inline(__always)
    public func shouldBypassForImeFriction(word: String) -> Bool {
        guard isEnabled && hasActiveBypassRules else { return false }
        let lower = word.utf8.contains(where: { ($0 >= 65 && $0 <= 90) || $0 >= 128 }) ? word.lowercased() : word
        return lock.withLock {
            activeImeBypassWords.contains(lower)
        }
    }

    @inline(__always)
    public func shouldPreserveVietnameseForImeFriction(word: String) -> Bool {
        guard isEnabled && hasActivePreserveRules else { return false }
        let lower = word.utf8.contains(where: { ($0 >= 65 && $0 <= 90) || $0 >= 128 }) ? word.lowercased() : word
        return lock.withLock {
            activeImePreserveWords.contains(lower)
        }
    }

    @inline(__always)
    public func replacementForPersonalTypo(word: String) -> String? {
        guard isEnabled && hasActiveTypoRules else { return nil }
        let lower = word.utf8.contains(where: { ($0 >= 65 && $0 <= 90) || $0 >= 128 }) ? word.lowercased() : word
        return lock.withLock {
            activePersonalTypos[lower]
        }
    }

    // MARK: - Classification Logic
    public static func classifyCorrection(
        rawKeysBeforeBackspace: String,
        displayedBeforeBackspace: String,
        finalCommittedText: String,
        wasBypassedBeforeBackspace: Bool = false
    ) -> (category: CorrectionCategory, trigger: String, replacement: String, isBypass: Bool, isPreserve: Bool)? {
        let beforeDisplay = displayedBeforeBackspace
            .precomposedStringWithCanonicalMapping
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let beforeRaw = rawKeysBeforeBackspace
            .precomposedStringWithCanonicalMapping
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let committed = finalCommittedText
            .precomposedStringWithCanonicalMapping
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !beforeDisplay.isEmpty && !committed.isEmpty else { return nil }
        guard beforeDisplay != committed else { return nil }
        guard !beforeDisplay.contains("¥") && !committed.contains("¥") && !beforeRaw.contains("¥") else {
            return nil
        }

        let s1 = beforeDisplay.lowercased()
        let s2 = committed.lowercased()
        let r1 = beforeRaw.lowercased()

        // Check for proper nouns with internal capital letters (e.g. "Việt Nam", "iPhone", "MacBook")
        let hasInternalMixedCase = committed.contains(where: { $0.isUppercase })
            && committed.contains(where: { $0.isLowercase })
            && (!committed.first!.isUppercase || (committed.dropFirst().contains(where: { $0.isUppercase }) && committed.dropFirst().contains(where: { $0.isLowercase })))

        // Ignore pure case-only changes (e.g. "m" -> "M", "TÔI" -> "tôi") unless fixing internal mixed-case ("iphone" -> "iPhone")
        if s1 == s2 && !hasInternalMixedCase {
            return nil
        }

        let u1 = stripDiacritics(s1)
        let u2 = stripDiacritics(s2)

        let hadDiacritics = hasVietnameseDiacritics(s1)
        let hasDiacriticsNow = hasVietnameseDiacritics(s2)

        let trig = r1.isEmpty ? s1 : r1
        let telexEval = BambooEngine.evaluatePureTelex(trig).precomposedStringWithCanonicalMapping.lowercased()
        let uTelex = stripDiacritics(telexEval)
        let uCollapsedTelex = hasDiacriticsNow ? collapseUnconsumedTelex(uTelex) : uTelex

        let distDirect = damerauLevenshtein(s1, s2)
        let distRaw = damerauLevenshtein(r1, s2)
        let distUnaccented = damerauLevenshtein(u1, u2)
        let distTelex = damerauLevenshtein(telexEval, s2)
        let distTelexUnaccented = damerauLevenshtein(uTelex, u2)
        let distCollapsedTelex = damerauLevenshtein(uCollapsedTelex, u2)
        let minDist = min(distDirect, distRaw, distUnaccented, distTelex, distTelexUnaccented, distCollapsedTelex)
        let maxLen = max(s1.count, s2.count)

        let similarity = 1.0 - (Double(minDist) / Double(max(1, maxLen)))

        // Filter out ordinary word replacements where strings are unrelated (e.g. "banana" -> "computer", "car" -> "man", "an" -> "to")
        guard similarity >= 0.50 && minDist <= 2 else {
            return nil
        }
        if maxLen <= 3 && minDist > 1 {
            return nil
        }

        // Case 1: IME Friction - User backspaces a Vietnamese-transformed word to force raw English/Romaji.
        // Require the committed unaccented text to match the raw keys typed before backspace (or the stripped display
        // only when raw keys are empty) so accidental tone deletions ("dánh" from "danhs" -> "danh"), key transpositions
        // ("áo" from "aso" -> "sao"), and word rewrites ("trường" -> "trong") are not misclassified.
        let matchesRawBypass = r1.isEmpty ? (u1 == s2) : (r1 == s2)
        if hadDiacritics && !hasDiacriticsNow && matchesRawBypass && s2.count >= 2 {
            return (
                category: .imeFriction,
                trigger: s2,
                replacement: committed,
                isBypass: true,
                isPreserve: false
            )
        }

        // Case 2: IME Friction - Engine auto-restored English/Romaji, user backspaced to force Vietnamese diacritics.
        // Only classify as imeFriction (isPreserve: true) if the raw keys before backspace actually evaluate
        // to the committed Vietnamese word under Telex (or the known "view" -> "viêu" shorthand).
        // Otherwise (e.g. "kohong" -> "không", "thya" -> "thay", "cahan" -> "chân"), fall through to personalTypo.
        let isKnownBypassWord = EnglishRestoreDetector.isEnglishKeyword(s1)
            || JapaneseRomajiDetector.shouldRestoreRomaji(candidateWord: s1)
        let matchesTelexEval = (telexEval == s2) || (isKnownBypassWord && s1 == "view" && s2 == "viêu")

        if !hadDiacritics && hasDiacriticsNow && matchesTelexEval
            && (wasBypassedBeforeBackspace
                || isKnownBypassWord
                || EnglishRestoreDetector.hasInvalidMedialDoubleConsonant(s1)) {
            return (
                category: .imeFriction,
                trigger: trig,
                replacement: committed,
                isBypass: false,
                isPreserve: true
            )
        }

        // Case 3: Recurring Personal Typo (e.g. "teh" -> "the", "kohong" -> "không", "thya" -> "thay")
        // Noise filtering for personalTypo:
        // 1. Reject single-character tokens, trailing technical separators (e.g. "cp/" -> "cpu"), or large length disparities
        let effectiveLen1 = hasDiacriticsNow ? min(s1.count, uCollapsedTelex.count) : s1.count
        if s1.count < 2 || s2.count < 2 || abs(effectiveLen1 - s2.count) > 2 {
            return nil
        }
        if s1.contains("/") || s2.contains("/") {
            return nil
        }
        if let last1 = s1.last, EnglishRestoreDetector.isTechnicalSeparator(last1) {
            return nil
        }
        if let last2 = s2.last, EnglishRestoreDetector.isTechnicalSeparator(last2) {
            return nil
        }
        // 2. For 2-character tokens, only allow pure 2-letter ASCII -> 2-letter ASCII typos (e.g. "im" -> "in"),
        //    excluding ALL-CAPS acronym rewrites (e.g. "AP" -> "AI").
        if s1.count == 2 || s2.count == 2 {
            let isBothAllCaps = beforeDisplay.allSatisfy({ $0.isUppercase }) && committed.allSatisfy({ $0.isUppercase })
            let isTwoLetterAsciiTypo = s1.count == 2 && s2.count == 2
                && !hadDiacritics && !hasDiacriticsNow
                && !isBothAllCaps
                && s1.allSatisfy({ $0.isLetter && $0.isASCII })
                && s2.allSatisfy({ $0.isLetter && $0.isASCII })
            if !isTwoLetterAsciiTypo {
                return nil
            }
        }
        // 3. Reject suffix truncations (e.g. "ecosysr" -> "eco", "playvid" -> "play", "places" -> "place")
        if (s1.hasPrefix(s2) || u1.hasPrefix(u2)) && s1.count > s2.count {
            return nil
        }
        // 4. Reject prefix extensions and mid-word backspace continuations (e.g. "wings" -> "wingspan",
        //    "devo" -> "devtools", "chi" -> "chip", "vie" -> "video", "overwar" -> "overwater",
        //    "minibeass" -> "minibeasts", "djaa" -> "dấu", "Tah" -> "Tạo"),
        //    except when completing a bound Vietnamese syllable that cannot stand alone (e.g. "việ" -> "việt").
        let isCompletingBoundVietnamese = hadDiacritics && hasDiacriticsNow && isBoundIncompleteVietnameseSyllable(s1)
        if !isCompletingBoundVietnamese {
            if (s2.hasPrefix(s1) || u2.hasPrefix(u1)) && s2.count > s1.count {
                return nil
            }
            if !hadDiacritics && hasDiacriticsNow && u2.hasPrefix(uCollapsedTelex) && u2.count > uCollapsedTelex.count {
                return nil
            }
            if !hadDiacritics && hasDiacriticsNow,
               let lastU2 = u2.last,
               !u1.contains(lastU2) && !r1.contains(lastU2) && distCollapsedTelex >= 2 {
                return nil
            }
            if !hadDiacritics && hasDiacriticsNow && maxLen <= 3 && distDirect > 1 && distTelex > 1 {
                return nil
            }
            if s2.count >= s1.count + 2 {
                return nil
            }
            if s2.count == s1.count + 1 {
                let isMidWordMistype = u1.last != u2.last
                    || (s2.hasPrefix(s1.dropLast()) && s1.count >= 2 && s1.last == s1.dropLast().last)
                if isMidWordMistype {
                    return nil
                }
            }
        }
        // 5. Reject when the deleted token is already a known English keyword or Romaji word (unless fixing internal mixed-case like "iphone" -> "iPhone")
        if isKnownBypassWord && s1 != s2 {
            return nil
        }
        // 6. Reject when deleting a valid complete Vietnamese word to write a different word
        //    (e.g. "tiếng" -> "đang", "tiếp" -> "giúp", "trên" -> "trong", "thông" -> "tên", "đề" -> "vẽ", "tha" -> "the", "chit" -> "chia"),
        //    or when merely adding a forgotten tone mark to an unaccented syllable ("chon" -> "chọn").
        if (hadDiacritics || s1.count >= 3) && s1 != s2 && isValidCompleteVietnameseSyllable(s1) {
            return nil
        }
        if !hadDiacritics && hasDiacriticsNow && (s1 == u2 || (isValidCompleteVietnameseSyllable(telexEval) && stripDiacritics(telexEval) == u2)) && !s2.contains(" ") {
            return nil
        }
        if !hadDiacritics && hasDiacriticsNow && isValidCompleteVietnameseSyllable(s1) && distUnaccented >= 2 {
            return nil
        }

        let normalizedReplacement: String
        let isCommittedAllUpper = committed.allSatisfy { $0.isUppercase }
        let isCommittedTitle = committed.first?.isUppercase == true && committed.dropFirst().allSatisfy { $0.isLowercase }

        if isCommittedAllUpper || isCommittedTitle {
            if hasInternalMixedCase {
                normalizedReplacement = committed
            } else {
                normalizedReplacement = committed.lowercased()
            }
        } else {
            normalizedReplacement = committed
        }

        return (
            category: .personalTypo,
            trigger: s1,
            replacement: normalizedReplacement,
            isBypass: false,
            isPreserve: false
        )
    }

    private static func collapseUnconsumedTelex(_ str: String) -> String {
        var result = str
        if result.count >= 3, let last = result.last, ["s", "f", "r", "x", "j"].contains(last) {
            result.removeLast()
        }
        let telexDigraphs: [(String, String)] = [
            ("aa", "a"), ("ee", "e"), ("oo", "o"),
            ("aw", "a"), ("ow", "o"), ("uw", "u"), ("dd", "d")
        ]
        for (pattern, replacement) in telexDigraphs {
            result = result.replacingOccurrences(of: pattern, with: replacement)
        }
        return result
    }

    private static let boundVietnameseNuclei: Set<String> = ["ă", "â", "iê", "yê", "uyê", "uô", "ươ"]
    private static let offGlidesForbiddingCoda: Set<String> = [
        "ai", "ao", "au", "âu", "ay", "ây", "eo", "êu", "ia", "iêu", "iu",
        "oai", "oao", "oay", "oeo", "oi", "ôi", "ơi", "ưa", "uây", "ui",
        "ưi", "uôi", "ươi", "ươu", "ưu", "uya", "uyu", "yêu"
    ]

    public static func isBoundIncompleteVietnameseSyllable(_ word: String) -> Bool {
        let lower = word.precomposedStringWithCanonicalMapping.lowercased()
        guard !lower.contains(" "), lower.allSatisfy({ $0.isLetter }),
              let parsed = Syllable.parse(from: lower),
              parsed.coda.isEmpty,
              parsed.nucleus.allSatisfy({ PhonotacticsMatrix.isVowelChar($0) }) else {
            return false
        }
        return boundVietnameseNuclei.contains(parsed.nucleus.lowercased())
    }

    public static func isValidCompleteVietnameseSyllable(_ word: String) -> Bool {
        let lower = word.precomposedStringWithCanonicalMapping.lowercased()
        guard !lower.contains(" "), lower.allSatisfy({ $0.isLetter }),
              let parsed = Syllable.parse(from: lower),
              parsed.nucleus.allSatisfy({ PhonotacticsMatrix.isVowelChar($0) }) else {
            return false
        }
        let lowerOnset = parsed.onset.lowercased()
        let lowerNuc = parsed.nucleus.lowercased()
        let lowerCoda = parsed.coda.lowercased()

        if !lowerOnset.isEmpty {
            guard !["z", "w", "f", "j"].contains(lowerOnset),
                  !PhonotacticsMatrix.lookupFC(lowerOnset, isComplete: true).isEmpty else {
                return false
            }
            if let firstNuc = lowerNuc.first {
                if lowerOnset == "k" && !"ieêy".contains(firstNuc) { return false }
                if lowerOnset == "c" && "ieêy".contains(firstNuc) { return false }
                if (lowerOnset == "g" || lowerOnset == "ng") && "eê".contains(firstNuc) { return false }
                if (lowerOnset == "gh" || lowerOnset == "ngh") && !"eêi".contains(firstNuc) { return false }
            }
            if lowerOnset == "q" { return false }
        }

        guard !PhonotacticsMatrix.lookupVO(lowerNuc).isEmpty else {
            return false
        }
        if lowerCoda.isEmpty && boundVietnameseNuclei.contains(lowerNuc) {
            return false
        }

        if !lowerCoda.isEmpty {
            guard PhonotacticsMatrix.isValidCoda(lowerCoda) && lowerCoda != "k",
                  PhonotacticsMatrix.isValidStopCodaTone(coda: lowerCoda, tone: parsed.tone),
                  !offGlidesForbiddingCoda.contains(lowerNuc) else {
                return false
            }
        }
        return true
    }

    // MARK: - Record Correction
    @discardableResult
    public func recordCorrection(
        rawKeysBeforeBackspace: String,
        displayedBeforeBackspace: String,
        finalCommittedText: String,
        wasBypassedBeforeBackspace: Bool = false
    ) -> TypingErrorEntry? {
        guard isEnabled else { return nil }
        guard !isSecureEventInputActive() else { return nil }

        guard let classification = Self.classifyCorrection(
            rawKeysBeforeBackspace: rawKeysBeforeBackspace,
            displayedBeforeBackspace: displayedBeforeBackspace,
            finalCommittedText: finalCommittedText,
            wasBypassedBeforeBackspace: wasBypassedBeforeBackspace
        ) else {
            return nil
        }

        return lock.withLock {
            let entryId = "\(classification.category.rawValue):\(classification.trigger)->\(classification.replacement.lowercased())"
            let now = Date()

            var entry: TypingErrorEntry
            if let existing = entries[entryId] {
                entry = existing
                entry.count += 1
                entry.lastSeen = now
                entry.timestamps.append(now)
                entry.isEnabled = true
            } else {
                entry = TypingErrorEntry(
                    id: entryId,
                    rawKeysBeforeBackspace: rawKeysBeforeBackspace,
                    displayedBeforeBackspace: displayedBeforeBackspace,
                    finalCommittedText: finalCommittedText,
                    category: classification.category,
                    count: 1,
                    timestamps: [now],
                    firstSeen: now,
                    lastSeen: now,
                    isEnabled: true
                )
            }
            entries[entryId] = entry

            // Update or create rule
            let ruleId = "rule:\(classification.category.rawValue):\(classification.trigger)"
            var rule = rules[ruleId] ?? LearnedRule(
                id: ruleId,
                trigger: classification.trigger,
                replacement: classification.replacement,
                category: classification.category,
                count: entry.count,
                isBypassTransform: classification.isBypass,
                isPreserveVietnamese: classification.isPreserve,
                isEnabled: (entry.count >= 3)
            )
            rule.count = entry.count
            rule.replacement = classification.replacement
            rule.isBypassTransform = classification.isBypass
            rule.isPreserveVietnamese = classification.isPreserve
            rule.isEnabled = (entry.count >= 3)
            rules[ruleId] = rule

            rebuildLookupTablesLocked()
            scheduleSaveLocked()

            return entry
        }
    }

    // MARK: - Self-Healing Demotion
    @discardableResult
    public func demoteRule(trigger: String, category: CorrectionCategory) -> Bool {
        return lock.withLock {
            let lower = trigger.lowercased()
            let ruleId = "rule:\(category.rawValue):\(lower)"
            var targetRule: LearnedRule? = rules[ruleId]
            if targetRule == nil {
                for (_, r) in rules where r.category == category {
                    if r.trigger.lowercased() == lower
                        || r.replacement.lowercased() == lower
                        || Self.stripDiacritics(r.replacement.lowercased()) == lower {
                        targetRule = r
                        break
                    }
                }
            }
            guard var rule = targetRule else { return false }

            rule.count = max(0, rule.count - 1)
            if rule.count < 3 {
                rule.isEnabled = false
            }
            rules[rule.id] = rule

            // Demote corresponding entry
            for (key, var entry) in entries {
                if entry.category == category && (
                    key.hasPrefix("\(category.rawValue):\(rule.trigger.lowercased())->")
                    || key == "\(category.rawValue):\(rule.trigger.lowercased())"
                    || entry.finalCommittedText.lowercased() == rule.replacement.lowercased()
                    || Self.stripDiacritics(entry.finalCommittedText.lowercased()) == rule.replacement.lowercased()
                ) {
                    entry.count = max(0, entry.count - 1)
                    if entry.count < 3 {
                        entry.isEnabled = false
                    }
                    entries[key] = entry
                }
            }

            rebuildLookupTablesLocked()
            scheduleSaveLocked()
            return true
        }
    }

    // MARK: - Cache Rebuilding
    private func rebuildLookupTablesLocked() {
        var bypass: Set<String> = []
        var preserve: Set<String> = []
        var typos: [String: String] = [:]

        for rule in rules.values where rule.isEnabled && rule.count >= 3 {
            let trig = rule.trigger.lowercased()
            switch rule.category {
            case .imeFriction:
                if rule.isBypassTransform {
                    bypass.insert(trig)
                }
                if rule.isPreserveVietnamese {
                    preserve.insert(trig)
                    let repLower = rule.replacement.lowercased()
                    preserve.insert(repLower)
                    preserve.insert(Self.stripDiacritics(repLower))
                }
            case .personalTypo:
                typos[trig] = rule.replacement
            }
        }

        self.activeImeBypassWords = bypass
        self.activeImePreserveWords = preserve
        self.activePersonalTypos = typos
        self.hasActiveBypassRules = !bypass.isEmpty
        self.hasActivePreserveRules = !preserve.isEmpty
        self.hasActiveTypoRules = !typos.isEmpty
    }

    // MARK: - Persistence & Serialization
    public func loadFromFile() {
        lock.withLock {
            pendingSaveWorkItem?.cancel()
            pendingSaveWorkItem = nil

            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                entries.removeAll()
                rules.removeAll()
                rebuildLookupTablesLocked()
                return
            }

            do {
                let data = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let logFile = try decoder.decode(TypingErrorLogFile.self, from: data)

                let originalEntriesCount = logFile.entries.count
                let originalRulesCount = logFile.learnedRules.count
                let originalEntryIds = logFile.entries.map(\.id)

                entries.removeAll(keepingCapacity: true)
                for entry in logFile.entries {
                    entries[entry.id] = entry
                }

                rules.removeAll(keepingCapacity: true)
                for rule in logFile.learnedRules {
                    rules[rule.id] = rule
                }

                sanitizeAndMigrateLocked()
                rebuildLookupTablesLocked()

                let sanitizedEntryIds = entries.keys.sorted()
                if entries.count != originalEntriesCount
                    || rules.count != originalRulesCount
                    || sanitizedEntryIds != originalEntryIds {
                    saveToFileSyncLocked()
                }
            } catch {
                NSLog("VietFlow AdaptiveLearner: Failed to load typing_error_log.json: \(error.localizedDescription)")
                entries.removeAll(keepingCapacity: true)
                rules.removeAll(keepingCapacity: true)
                rebuildLookupTablesLocked()
            }
        }
    }

    private static let nativelyResolvedEngineTriggers: Set<String> = [
        "air", "barn", "boro", "daasu", "rofo", "twucs", "twu",
        "arre", "inssects", "ussage", "ussag", "mall", "item", "fli", "googe", "outlie", "airport", "nag"
    ]

    /// Re-evaluates all loaded entries against current classification and noise-filtering rules,
    /// removing noise/obsolete entries and reclassifying misclassified entries.
    public func sanitizeAndMigrateEntries() {
        lock.withLock {
            sanitizeAndMigrateLocked()
            rebuildLookupTablesLocked()
            saveToFileSyncLocked()
        }
    }

    private func sanitizeAndMigrateLocked() {
        var cleanedEntries: [String: TypingErrorEntry] = [:]
        var cleanedRules: [String: LearnedRule] = [:]

        let sortedOriginalEntries = entries.values.sorted(by: { $0.id < $1.id })
        for entry in sortedOriginalEntries {
            guard entry.count > 0 else { continue }
            let rawLower = entry.rawKeysBeforeBackspace
                .precomposedStringWithCanonicalMapping
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            let dispLower = entry.displayedBeforeBackspace
                .precomposedStringWithCanonicalMapping
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            if Self.nativelyResolvedEngineTriggers.contains(rawLower) || Self.nativelyResolvedEngineTriggers.contains(dispLower) {
                continue
            }

            guard let classification = Self.classifyCorrection(
                rawKeysBeforeBackspace: entry.rawKeysBeforeBackspace,
                displayedBeforeBackspace: entry.displayedBeforeBackspace,
                finalCommittedText: entry.finalCommittedText,
                wasBypassedBeforeBackspace: (entry.category == .imeFriction)
            ) else {
                continue
            }

            let newEntryId = "\(classification.category.rawValue):\(classification.trigger)->\(classification.replacement.lowercased())"
            if var existing = cleanedEntries[newEntryId] {
                existing.count += entry.count
                existing.timestamps.append(contentsOf: entry.timestamps)
                existing.timestamps.sort()
                if entry.firstSeen < existing.firstSeen {
                    existing.firstSeen = entry.firstSeen
                }
                if entry.lastSeen > existing.lastSeen {
                    existing.lastSeen = entry.lastSeen
                }
                existing.isEnabled = existing.isEnabled || entry.isEnabled
                cleanedEntries[newEntryId] = existing
            } else {
                var migrated = TypingErrorEntry(
                    id: newEntryId,
                    rawKeysBeforeBackspace: entry.rawKeysBeforeBackspace.precomposedStringWithCanonicalMapping,
                    displayedBeforeBackspace: entry.displayedBeforeBackspace.precomposedStringWithCanonicalMapping,
                    finalCommittedText: entry.finalCommittedText.precomposedStringWithCanonicalMapping,
                    category: classification.category,
                    count: entry.count,
                    timestamps: entry.timestamps,
                    firstSeen: entry.firstSeen,
                    lastSeen: entry.lastSeen,
                    isEnabled: entry.isEnabled
                )
                migrated.timestamps.sort()
                cleanedEntries[newEntryId] = migrated
            }

            let mergedEntry = cleanedEntries[newEntryId]!
            let ruleId = "rule:\(classification.category.rawValue):\(classification.trigger)"
            let priorRule = rules[ruleId]
            let isRuleEnabled: Bool
            if let prior = priorRule, prior.count >= 3 && !prior.isEnabled {
                isRuleEnabled = false
            } else {
                isRuleEnabled = (mergedEntry.count >= 3) && mergedEntry.isEnabled
            }

            cleanedRules[ruleId] = LearnedRule(
                id: ruleId,
                trigger: classification.trigger,
                replacement: classification.replacement,
                category: classification.category,
                count: mergedEntry.count,
                isBypassTransform: classification.isBypass,
                isPreserveVietnamese: classification.isPreserve,
                isEnabled: isRuleEnabled
            )
        }

        entries = cleanedEntries
        rules = cleanedRules
    }

    public func saveToFileSync() {
        lock.withLock {
            saveToFileSyncLocked()
        }
    }

    private func saveToFileSyncLocked() {
        let logFile = TypingErrorLogFile(
            version: 1,
            entries: Array(entries.values).sorted(by: { $0.id < $1.id }),
            learnedRules: Array(rules.values).sorted(by: { $0.id < $1.id })
        )

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(logFile)

            let parentDir = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            NSLog("VietFlow AdaptiveLearner: Failed to save typing_error_log.json: \(error.localizedDescription)")
        }
    }

    private func scheduleSaveLocked() {
        pendingSaveWorkItem?.cancel()
        let logFile = TypingErrorLogFile(
            version: 1,
            entries: Array(entries.values).sorted(by: { $0.id < $1.id }),
            learnedRules: Array(rules.values).sorted(by: { $0.id < $1.id })
        )
        let targetURL = self.fileURL

        var workItem: DispatchWorkItem!
        workItem = DispatchWorkItem {
            guard !workItem.isCancelled else { return }
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(logFile)

                guard !workItem.isCancelled else { return }
                let parentDir = targetURL.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
                guard !workItem.isCancelled else { return }
                try data.write(to: targetURL, options: .atomic)
            } catch {
                NSLog("VietFlow AdaptiveLearner: Background save failed: \(error.localizedDescription)")
            }
        }

        self.pendingSaveWorkItem = workItem
        ioQueue.asyncAfter(deadline: .now() + 0.1, execute: workItem)
    }

    public func flushSync() {
        lock.withLock {
            pendingSaveWorkItem?.cancel()
            pendingSaveWorkItem = nil
            saveToFileSyncLocked()
        }
    }

    public func clearData() {
        lock.withLock {
            pendingSaveWorkItem?.cancel()
            pendingSaveWorkItem = nil
            entries.removeAll()
            rules.removeAll()
            rebuildLookupTablesLocked()
            saveToFileSyncLocked()
        }
    }

    // MARK: - String Utilities
    public static func hasVietnameseDiacritics(_ str: String) -> Bool {
        let vietnameseChars = Set("àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđÀÁẢÃẠĂẰẮẲẴẶÂẦẤẨẪẬÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴĐ")
        return str.contains(where: { vietnameseChars.contains($0) })
    }

    public static func stripDiacritics(_ str: String) -> String {
        return str.folding(options: .diacriticInsensitive, locale: Locale(identifier: "vi"))
            .replacingOccurrences(of: "đ", with: "d")
            .replacingOccurrences(of: "Đ", with: "D")
    }

    public static func damerauLevenshtein(_ a: String, _ b: String) -> Int {
        let s1 = Array(a)
        let s2 = Array(b)
        let len1 = s1.count
        let len2 = s2.count

        if len1 == 0 { return len2 }
        if len2 == 0 { return len1 }

        var d = Array(repeating: Array(repeating: 0, count: len2 + 1), count: len1 + 1)

        for i in 0...len1 { d[i][0] = i }
        for j in 0...len2 { d[0][j] = j }

        for i in 1...len1 {
            for j in 1...len2 {
                let cost = (s1[i - 1] == s2[j - 1]) ? 0 : 1
                d[i][j] = min(
                    d[i - 1][j] + 1,       // deletion
                    d[i][j - 1] + 1,       // insertion
                    d[i - 1][j - 1] + cost // substitution
                )
                // Transposition
                if i > 1 && j > 1 && s1[i - 1] == s2[j - 2] && s1[i - 2] == s2[j - 1] {
                    d[i][j] = min(d[i][j], d[i - 2][j - 2] + 1)
                }
            }
        }
        return d[len1][len2]
    }
}
