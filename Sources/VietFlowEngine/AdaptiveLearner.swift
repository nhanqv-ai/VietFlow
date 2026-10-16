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
        let lower = word.lowercased()
        return lock.withLock {
            activeImeBypassWords.contains(lower)
        }
    }

    @inline(__always)
    public func shouldPreserveVietnameseForImeFriction(word: String) -> Bool {
        guard isEnabled && hasActivePreserveRules else { return false }
        let lower = word.lowercased()
        return lock.withLock {
            activeImePreserveWords.contains(lower)
        }
    }

    @inline(__always)
    public func replacementForPersonalTypo(word: String) -> String? {
        guard isEnabled && hasActiveTypoRules else { return nil }
        let lower = word.lowercased()
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
        let beforeDisplay = displayedBeforeBackspace.trimmingCharacters(in: .whitespacesAndNewlines)
        let beforeRaw = rawKeysBeforeBackspace.trimmingCharacters(in: .whitespacesAndNewlines)
        let committed = finalCommittedText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !beforeDisplay.isEmpty && !committed.isEmpty else { return nil }
        guard beforeDisplay != committed else { return nil }

        let s1 = beforeDisplay.lowercased()
        let s2 = committed.lowercased()
        let r1 = beforeRaw.lowercased()

        let u1 = stripDiacritics(s1)
        let u2 = stripDiacritics(s2)

        let distDirect = damerauLevenshtein(s1, s2)
        let distRaw = damerauLevenshtein(r1, s2)
        let distUnaccented = damerauLevenshtein(u1, u2)
        let minDist = min(distDirect, distRaw, distUnaccented)
        let maxLen = max(s1.count, s2.count)

        let similarity = 1.0 - (Double(minDist) / Double(max(1, maxLen)))

        // Filter out ordinary word replacements where strings are completely unrelated (e.g. "banana" -> "computer", "car" -> "man", "an" -> "to")
        guard similarity >= 0.35 else {
            return nil
        }
        if maxLen <= 3 && minDist > 1 {
            return nil
        }

        let hadDiacritics = hasVietnameseDiacritics(s1)
        let hasDiacriticsNow = hasVietnameseDiacritics(s2)

        // Case 1: IME Friction - User backspaces a Vietnamese-transformed word to force raw English/Romaji
        if hadDiacritics && !hasDiacriticsNow && (u1 == u2 || distRaw <= 1 || distUnaccented <= 1) {
            return (
                category: .imeFriction,
                trigger: s2,
                replacement: committed,
                isBypass: true,
                isPreserve: false
            )
        }

        // Case 2: IME Friction - Engine auto-restored English, user backspaced to force Vietnamese diacritics
        if !hadDiacritics && hasDiacriticsNow && (wasBypassedBeforeBackspace || EnglishRestoreDetector.isEnglishKeyword(s1) || EnglishRestoreDetector.hasInvalidMedialDoubleConsonant(s1) || JapaneseRomajiDetector.shouldRestoreRomaji(candidateWord: s1)) {
            return (
                category: .imeFriction,
                trigger: s1,
                replacement: committed,
                isBypass: false,
                isPreserve: true
            )
        }

        // Case 3: Recurring Personal Typo (e.g. "teh" -> "the", or habitual Vietnamese typo)
        let normalizedReplacement: String
        let firstBefore = beforeDisplay.first
        let firstCommitted = committed.first
        if let fb = firstBefore, let fc = firstCommitted, fb.isUppercase && fc.isUppercase {
            // Both before and after were capitalized (e.g. at sentence start: "Teh" -> "The")
            // Preserve proper nouns with internal capital letters (e.g. "Việt Nam", "iPhone")
            if committed.dropFirst().contains(where: { $0.isUppercase }) {
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
            guard var rule = rules[ruleId] else { return false }

            rule.count = max(0, rule.count - 1)
            if rule.count < 3 {
                rule.isEnabled = false
            }
            rules[ruleId] = rule

            // Demote corresponding entry
            for (key, var entry) in entries {
                if entry.category == category && (key.hasPrefix("\(category.rawValue):\(lower)->") || key == "\(category.rawValue):\(lower)") {
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
                    preserve.insert(rule.replacement.lowercased())
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

                entries.removeAll(keepingCapacity: true)
                for entry in logFile.entries {
                    entries[entry.id] = entry
                }

                rules.removeAll(keepingCapacity: true)
                for rule in logFile.learnedRules {
                    rules[rule.id] = rule
                }

                rebuildLookupTablesLocked()
            } catch {
                NSLog("VietFlow AdaptiveLearner: Failed to load typing_error_log.json: \(error.localizedDescription)")
                entries.removeAll(keepingCapacity: true)
                rules.removeAll(keepingCapacity: true)
                rebuildLookupTablesLocked()
            }
        }
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
