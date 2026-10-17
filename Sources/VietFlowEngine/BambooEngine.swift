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
        var didUndoDiacritic: Bool = false
        var didAbsorbBypassW: Bool = false
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

    // MARK: - Adaptive Learning State
    public var adaptiveLearner: AdaptiveLearningManager?
    private struct PreBackspaceSnapshot {
        var displayedText: String
        var rawKeys: String
        var wasBypassed: Bool
    }
    private struct AppliedCorrection {
        var originalWord: String
        var correctedWord: String
        var ruleTrigger: String
        var category: CorrectionCategory
        var boundaryChar: Character
    }
    private var tokenDidBackspace: Bool = false
    private var preBackspaceSnapshot: PreBackspaceSnapshot? = nil
    private var lastAppliedCorrection: AppliedCorrection? = nil
    
    // MARK: - Initialization
    public init(config: EngineConfig = EngineConfig(), adaptiveLearner: AdaptiveLearningManager? = nil) {
        self.lock = OSAllocatedUnfairLock()
        self._config = config
        self.adaptiveLearner = adaptiveLearner
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
        lastAppliedCorrection = nil
        let prevDisplay = committedPrefix + activePreedit

        // Special CLI detection: if preceding word was 'tả' (typed as 'tar') and user types CLI flag '-'
        let isPrecedingTar = lastCompletedWord.trimmingCharacters(in: .whitespaces) == "tả"
            || spaceHistory.last?.activePreedit.lowercased() == "tả"
        if character == "-" && prevDisplay.isEmpty && isPrecedingTar {
            isBypassed = true
            wordRawKeys = ["t", "a", "r", " ", "-"]
            activePreedit = "tar -"
            committedPrefix = ""
            activeRawKeys = Array("tar -")
            transformState = SyllableTransformState()
            return MinimalDiff.calculate(previous: "tả ", next: "tar -")
        }

        // 1. Delimiter / Boundary Check
        let isTechSep = EnglishRestoreDetector.isTechnicalSeparator(character)
        let prevChar = prevDisplay.last ?? wordRawKeys.last
        let isAdjacentToToken = prevChar != nil && (prevChar!.isLetter || prevChar!.isNumber || EnglishRestoreDetector.isTechnicalSeparator(prevChar!))

        if EnglishRestoreDetector.isWordDelimiter(character) {
            let finishedWord = prevDisplay
            if !finishedWord.isEmpty, let learner = adaptiveLearner, learner.isEnabled, learner.hasActiveTypoRules {
                let lower = finishedWord.lowercased()
                if let replacement = learner.replacementForPersonalTypo(word: lower) {
                    let casedReplacement = Self.matchCase(source: finishedWord, target: replacement)
                    let fullReplacement = casedReplacement + String(character)
                    let delta = MinimalDiff.calculate(previous: prevDisplay, next: fullReplacement)
                    lastAppliedCorrection = AppliedCorrection(
                        originalWord: finishedWord,
                        correctedWord: casedReplacement,
                        ruleTrigger: lower,
                        category: .personalTypo,
                        boundaryChar: character
                    )
                    lastCompletedWord = casedReplacement.lowercased()
                    tokenDidBackspace = false
                    preBackspaceSnapshot = nil
                    if character == " " {
                        spaceHistory.append(
                            WordSnapshot(
                                committedPrefix: "",
                                activePreedit: casedReplacement,
                                activeRawKeys: Array(casedReplacement),
                                wordRawKeys: Array(casedReplacement),
                                isBypassed: true,
                                transformState: SyllableTransformState()
                            )
                        )
                        if spaceHistory.count > 16 {
                            spaceHistory.removeFirst()
                        }
                    } else {
                        spaceHistory.removeAll(keepingCapacity: true)
                    }
                    internalReset()
                    return delta
                }
            }

            if tokenDidBackspace, let snapshot = preBackspaceSnapshot, !finishedWord.isEmpty {
                adaptiveLearner?.recordCorrection(
                    rawKeysBeforeBackspace: snapshot.rawKeys,
                    displayedBeforeBackspace: snapshot.displayedText,
                    finalCommittedText: finishedWord,
                    wasBypassedBeforeBackspace: snapshot.wasBypassed
                )
            }
            tokenDidBackspace = false
            preBackspaceSnapshot = nil

            if isTechSep && (isAdjacentToToken || character == "/") {
                if !prevDisplay.isEmpty {
                    lastCompletedWord = prevDisplay.lowercased()
                }
                wordRawKeys.append(character)
                committedPrefix = prevDisplay + String(character)
                activePreedit = ""
                activeRawKeys.removeAll(keepingCapacity: true)
                transformState = SyllableTransformState()
                spaceHistory.removeAll(keepingCapacity: true)
                isBypassed = false
                return nil
            }

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
        let wasBypassedBeforeStep2 = isBypassed
        if isBypassed {
            let prefix2 = wordRawKeys.count >= 2 ? String(wordRawKeys[0...1]).lowercased() : ""
            let prefix3 = wordRawKeys.count >= 3 ? String(wordRawKeys[0...2]).lowercased() : ""
            let onsetLen = prefix3 == "ngh" ? 3 : ((["ch", "ph", "th", "kh", "tr", "nh", "gh", "ng", "qu", "dd"].contains(prefix2)
                || (prefix2 == "gi" && wordRawKeys.count >= 3 && "aeiouy".contains(wordRawKeys[2].lowercased()))) ? 2 : 1)
            let rhymeAfterOnset = wordRawKeys.count > onsetLen ? Array(wordRawKeys[onsetLen...]).map { $0.lowercased() } : []
            let has3CharRhymeAfterOnset = rhymeAfterOnset.count == 3
            let r1 = has3CharRhymeAfterOnset ? rhymeAfterOnset[0] : ""
            let r2 = has3CharRhymeAfterOnset ? rhymeAfterOnset[1] : ""
            let r3 = has3CharRhymeAfterOnset ? rhymeAfterOnset[2] : ""

            // Unlatch bypass if 'yes' or 'chief' is immediately followed by a vowel or tone override for free-order Vietnamese ('yesue' -> 'yếu', 'yesfue' -> 'yều', 'chiefue' -> 'chiều')
            if String(wordRawKeys).lowercased() == "yes" && (PhonotacticsMatrix.isVowelChar(character) || "frxj".contains(character.lowercased())) {
                isBypassed = false
                didBackspace = true
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if ([
                "chief", "thief", "chiefs", "ties", "dies", "lies", "vies", "pies", "hies", "tier", "bier", "pier", "trier", "tries", "tiers", "biers",
                "ieru", "kieru", "mieru", "hieru", "nieru", "tieru", "bieru", "pieru", "sieru", "gieru", "rieru", "chieru",
                "kiseru", "hiseru", "niseru",
                "tiesu", "diesu", "liesu", "viesu", "piesu", "hiesu", "chiefu", "thiefu",
                "tiersu", "biersu", "triesu", "chiefsu", "sixesu", "mixesu", "mixersu", "miseru", "mixeru", "trieru", "pieru", "piersu",
                "yensf", "yensr", "yensx", "yensj", "yensg", "yensh",
                "lexusf", "lexusr", "lexusx", "lexusj", "nexusf", "nexusr", "nexusx", "nexusj",
                "tuxesm", "tuxesn", "tuxesc", "tuxesp", "tuxest", "tuxesf", "tuxesr", "tuxesx", "tuxesj",
                "curesm", "curesn", "curesc", "curesp", "curest", "curesf", "curesr", "curesx", "curesj",
                "cursem", "cursen", "cursec", "cursep", "curset", "cursef", "curser", "cursex", "cursej",
                "nursem", "nursen", "nursec", "nursep", "nurset", "nursef", "nurser", "nursex", "nursej",
                "duetsj", "duetsjd", "duetsdj",
                "dues", "hues", "sues", "rues", "tues", "cues", "cures", "curse", "curses", "nurse", "purse", "purses", "muses", "ruses", "true", "vue", "lexus", "nexus", "tuxes", "mixer", "died", "diets", "duets", "guest", "quiet", "quiets",
                "use", "ure", "ire", "efu", "eru", "esu",
                "ires", "iref", "irex", "irej", "ures", "uref", "urex", "urej", "usef", "usex", "usej",
                "erus", "eruf", "erux", "eruj", "esuf", "esur", "esux", "esuj", "efus", "efur", "efux", "efuj"
            ].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "e")
                || (String(wordRawKeys).lowercased() == "died" && "mncptu".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased().hasPrefix("died") && wordRawKeys.count == 5 && (("mncptu".contains(wordRawKeys[4].lowercased()) && character.lowercased() == "e") || ("sfrxj".contains(wordRawKeys[4].lowercased()) && "mncptue".contains(character.lowercased())))) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if String(wordRawKeys).lowercased() == "deed" && "frxjcmnptu".contains(character.lowercased()) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if (["diet", "quiet", "niece"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "j")
                || (["diet", "diets"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "d") {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if ["beer", "deer"].contains(String(wordRawKeys).lowercased())
                && ("mnufjx".contains(character.lowercased()) || (wordRawKeys[0].lowercased() == "d" && character.lowercased() == "d")) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if String(wordRawKeys).lowercased() == "door" && "imndwfjx".contains(character.lowercased()) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if String(wordRawKeys).lowercased() == "goof" && "mniwrxj".contains(character.lowercased()) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if (["soar", "boar", "roar", "moar", "voar", "noar", "goar", "poar", "phoar", "troar", "koar"].contains(String(wordRawKeys).lowercased()) && "mnioywfjx".contains(character.lowercased()))
                || (["moar", "voar", "noar", "goar", "poar", "phoar", "troar", "koar"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "s")
                || (["boas", "roas", "moas", "voas", "noas", "poas", "phoas", "troas", "koas"].contains(String(wordRawKeys).lowercased())
                    && ("mncpwiyofrxj".contains(character.lowercased())
                        || (character.lowercased() == "t" && !["boas", "roas"].contains(String(wordRawKeys).lowercased()))))
                || (["boaf", "roaf", "moaf", "voaf", "noaf", "goaf", "poaf", "phoaf", "troaf", "koaf", "boax", "roax", "moax", "voax", "goax", "poax", "phoax", "troax", "koax", "boaj", "roaj", "moaj", "voaj", "noaj", "goaj", "poaj", "phoaj", "troaj", "koaj"].contains(String(wordRawKeys).lowercased())
                    && (("mnwiyosfrxj".contains(character.lowercased()) && character.lowercased() != wordRawKeys.last?.lowercased())
                        || ("cpt".contains(character.lowercased()) && wordRawKeys.last?.lowercased() == "j")))
                || (["soars", "boars", "roars", "sofas", "oars", "loafs", "oafs"].contains(String(wordRawKeys).lowercased()) && "mncptwyio".contains(character.lowercased()))
                || (["coifs", "choirs"].contains(String(wordRawKeys).lowercased()) && "ow".contains(character.lowercased())) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if String(wordRawKeys).lowercased() == "coax" && "mnoywifrjs".contains(character.lowercased()) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if ["noop", "goop", "troop", "keep", "peep", "cheep", "deep"].contains(String(wordRawKeys).lowercased())
                && (character.lowercased() == "j"
                    || (wordRawKeys[0].lowercased() == "d" && character.lowercased() == "d")
                    || (["noop", "goop", "troop"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "w")) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if ["loom", "doom", "deem", "seem", "keen"].contains(String(wordRawKeys).lowercased())
                && ("fjrx".contains(character.lowercased())
                    || (wordRawKeys[0].lowercased() == "d" && character.lowercased() == "d")
                    || (String(wordRawKeys).lowercased() == "keen" && "gh".contains(character.lowercased()))
                    || (["loom", "doom"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "w")) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if (["toes", "hoes", "roes", "noes", "goes", "does", "boes", "coes", "koes", "moes", "poes", "phoes", "soes", "troes", "voes", "pores", "bores", "cores", "dores", "gores", "kores", "mores", "nores", "rores", "sores", "vores", "phores", "trores", "doers", "goers", "boers", "coers", "koers", "moers", "noers", "poers", "phoers", "roers", "soers", "troers", "voers", "lose", "hose", "chose", "those", "rose", "nose", "pose", "dose", "kose", "koje", "poje", "boje", "moje", "noje", "doje", "roje", "soje", "bose", "mose", "sose", "vose", "voje", "gose", "goje", "phose", "phoje", "trose", "troje", "cose", "coje", "boej", "coej", "doej", "goej", "koej", "moej", "noej", "poej", "phoej", "roej", "soej", "troej", "voej", "ores", "tores", "hores", "lores", "chores", "horse"].contains(String(wordRawKeys).lowercased()) && "ocmpt".contains(character.lowercased()))
                || (["toes", "hoes", "roes", "noes", "goes", "does", "boes", "coes", "koes", "moes", "poes", "phoes", "soes", "troes", "voes", "pores", "bores", "cores", "dores", "gores", "kores", "mores", "nores", "rores", "sores", "vores", "phores", "trores", "doers", "goers", "boers", "coers", "koers", "moers", "noers", "poers", "phoers", "roers", "soers", "troers", "voers", "ores", "tores", "hores", "lores", "chores", "horse"].contains(String(wordRawKeys).lowercased()) && "frxj".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "horse" && character.lowercased() == "o")
                || (["toes", "hoes", "roes", "noes", "goes", "boes", "coes", "koes", "moes", "poes", "phoes", "soes", "troes", "voes", "pores", "bores", "cores", "dores", "gores", "kores", "mores", "nores", "rores", "sores", "vores", "phores", "trores", "doers", "goers", "boers", "coers", "koers", "moers", "noers", "poers", "phoers", "roers", "soers", "troers", "voers", "lose", "hose", "those", "rose", "nose", "pose", "dose", "kose", "koje", "poje", "boje", "moje", "noje", "doje", "roje", "soje", "bose", "mose", "vose", "voje", "gose", "goje", "phose", "phoje", "trose", "troje", "cose", "coje", "boej", "coej", "doej", "goej", "koej", "moej", "noej", "poej", "phoej", "roej", "soej", "troej", "voej", "ores", "tores", "hores", "lores", "chores", "horse"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "n")
                || (["tore", "hore", "lore", "chore", "ore", "sore", "dore", "rore", "more", "bore", "pore", "kore", "nore", "vore", "gore", "phore", "trore", "core", "doer", "goer", "boer", "coer", "koer", "moer", "noer", "poer", "phoer", "roer", "soer", "troer", "voer"].contains(String(wordRawKeys).lowercased()) && "ofjx".contains(character.lowercased()))
                || (["lose", "hose", "chose", "those", "rose", "nose", "pose", "dose", "kose", "more"].contains(String(wordRawKeys).lowercased()) && "fjx".contains(character.lowercased()))
                || (["hose", "chose", "those", "rose", "nose", "dose", "kose"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "r")
                || (["tore", "hore", "lore", "chore", "sore", "dore", "rore", "more", "bore", "pore", "kore", "nore", "vore", "gore", "phore", "trore", "core", "doer", "goer", "boer", "coer", "koer", "moer", "noer", "poer", "phoer", "roer", "soer", "troer", "voer", "boef", "coef", "doef", "goef", "koef", "moef", "noef", "poef", "phoef", "roef", "soef", "troef", "voef", "boex", "coex", "doex", "goex", "koex", "moex", "noex", "poex", "phoex", "roex", "soex", "troex", "voex", "kofe", "koxe", "pofe", "poxe", "bofe", "boxe", "mofe", "moxe", "nofe", "noxe", "dofe", "doxe", "rofe", "roxe", "sofe", "soxe", "vofe", "voxe", "gofe", "goxe", "phofe", "phoxe", "trofe", "troxe", "cofe", "coxe"].contains(String(wordRawKeys).lowercased()) && "mn".contains(character.lowercased()))
                || (["boef", "coef", "doef", "goef", "koef", "moef", "noef", "poef", "phoef", "roef", "soef", "troef", "voef", "boex", "coex", "doex", "goex", "koex", "moex", "noex", "poex", "phoex", "roex", "soex", "troex", "voex", "boej", "coej", "doej", "goej", "koej", "moej", "noej", "poej", "phoej", "roej", "soej", "troej", "voej", "kofe", "koxe", "koje", "pofe", "poxe", "poje", "bose", "bofe", "boxe", "boje", "mose", "mofe", "moxe", "moje", "nofe", "noxe", "noje", "dofe", "doxe", "doje", "rofe", "roxe", "roje", "sose", "sofe", "soxe", "soje", "vose", "vofe", "voxe", "voje", "gose", "gofe", "goxe", "goje", "phose", "phofe", "phoxe", "phoje", "trose", "trofe", "troxe", "troje", "cose", "cofe", "coxe", "coje"].contains(String(wordRawKeys).lowercased()) && ("osfrxj".contains(character.lowercased()) && character.lowercased() != r2 && character.lowercased() != wordRawKeys.last?.lowercased() && !(String(wordRawKeys).lowercased() == "boxe" && "sr".contains(character.lowercased()))))
                || (["dofe", "dore", "doxe", "doje", "does", "dores", "doer", "doers", "doef", "doex", "doej"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "d") {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if (String(wordRawKeys).lowercased() == "two" && "wnimcptufrxj".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "twos" && "imncptuw".contains(character.lowercased()))
                || (["twosf", "twosr", "twosx", "twosj"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "w")
                || (String(wordRawKeys).lowercased() == "wow" && "frxjiumnptc".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "wows" && "iumncptfrxj".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "wi" && "sfrxj".contains(character.lowercased())) {
                isBypassed = false
                didBackspace = true
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if ["laws", "raws", "saws", "thaws", "caws", "maws", "haws"].contains(String(wordRawKeys).lowercased()) && "cmnptfrxj".contains(character.lowercased()) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if (["dawn", "lawn", "down", "gown", "town", "own"].contains(String(wordRawKeys).lowercased())
                && ("frxjg".contains(character.lowercased())
                    || (["dawn", "lawn"].contains(wordRawKeys.map { String($0).lowercased() }.joined()) && character.lowercased() == "a")
                    || (["down", "gown", "town", "own"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "o")
                    || (wordRawKeys[0].lowercased() == "d" && character.lowercased() == "d")))
                || (["dawns", "lawns", "downs", "gowns", "towns", "owns"].contains(String(wordRawKeys).lowercased())
                    && ("gfrxj".contains(character.lowercased())
                        || (["dawns", "lawns"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "a")
                        || (["downs", "gowns", "towns", "owns"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "o"))) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if ["howa", "dowa", "nowa", "sowa", "towa", "rowa", "owa"].contains(String(wordRawKeys).lowercased()) && "cmnptsfrxj".contains(character.lowercased()) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if has3CharRhymeAfterOnset
                && r1 == "o"
                && "rsfjx".contains(r2)
                && r3 == "o"
                && ("cmnptiw".contains(character.lowercased())
                    || (wordRawKeys[0].lowercased() == "d" && character.lowercased() == "d")
                    || ("sfrxj".contains(character.lowercased())
                        && character.lowercased() != r2
                        && !((r2 == "r" || ["dojo", "rojo"].contains(String(wordRawKeys).lowercased())) && character.lowercased() == "s")
                        && !(String(wordRawKeys).lowercased() == "soso" && character.lowercased() == "r"))) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if has3CharRhymeAfterOnset
                && r1 == "a"
                && "rsfjx".contains(r2)
                && r3 == "a"
                && ((("sfjx".contains(r2) || !["hara", "sara", "tara", "nara"].contains(String(wordRawKeys).lowercased())) ? "cmnptuyw" : "cmnptyw").contains(character.lowercased())
                    || (wordRawKeys[0].lowercased() == "d" && character.lowercased() == "d")
                    || ("sfrxj".contains(character.lowercased())
                        && character.lowercased() != r2
                        && !(r2 == "r" && character.lowercased() == "s")
                        && !(["sasa", "nasa", "masa", "tasa", "hasa", "safa"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "r"))) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if ((has3CharRhymeAfterOnset
                && r1 == "e"
                && "rsfjx".contains(r2)
                && r3 == "e")
                || ["nix", "sees", "trees"].contains(String(wordRawKeys).lowercased()))
                && ("cmnptu".contains(character.lowercased())
                    || (wordRawKeys[0].lowercased() == "d" && character.lowercased() == "d")
                    || (String(wordRawKeys).lowercased() == "nix" && "asfrj".contains(character.lowercased()))
                    || (has3CharRhymeAfterOnset
                        && "sfrxj".contains(character.lowercased())
                        && character.lowercased() != r2
                        && !(r2 == "r" && character.lowercased() == "s")
                        && !(["dese", "rese", "defe", "refe"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "r"))) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if ["suwa", "guwa", "buwa", "giwa", "huwa", "nuwa", "ruwa", "manga", "inh", "try"].contains(String(wordRawKeys).lowercased()) && "sfrxj".contains(character.lowercased()) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if ["tux", "dux"].contains(String(wordRawKeys).lowercased())
                && ("cmnptwaiysfrj".contains(character.lowercased()) || (wordRawKeys[0].lowercased() == "d" && character.lowercased() == "d")) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if (String(wordRawKeys).lowercased() == "hex" && "euocmnptsfrj".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "trex" && "euomncptsfrj".contains(character.lowercased()))
                || (["trexu", "trexn", "trexm", "hexu"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "e")
                || (String(wordRawKeys).lowercased() == "cat" && "awjs".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "let" && "ejs".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "in" && "sfrxj".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "var" && "mnouwfjx".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "git" && "sj".contains(character.lowercased()))
                || (["chair", "lair", "pair", "moron"].contains(String(wordRawKeys).lowercased()) && "fjx".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "boron" && "sfjx".contains(character.lowercased()))
                || (["beset", "reset", "keeps", "peeps", "deeps", "cheeps", "noops", "goops", "troops", "topos", "gotos", "photos", "datas", "basta", "rasta", "coats", "coast", "toast", "diets", "quiets", "nieces", "sorts", "burst", "worst", "thirst", "swops", "tester", "testers", "poets"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "j")
                || (["hairs", "chairs", "lairs", "airs", "pairs", "pays", "poems", "morons", "booms", "dooms", "looms", "rooms", "goons", "loons", "moons", "nonos", "deems", "seems", "teems", "keens", "teens", "queens", "mamas", "memes", "themes", "donors", "honors", "oxen", "vixen", "vixens", "sirens", "risen", "chosen", "tureens", "barns", "darns", "tarns", "horns", "thorns", "morns", "borns", "corns", "torns", "burns", "turns", "churns", "urns", "arms", "harms", "charms", "chasm", "norms", "corms", "dorms", "berms", "terms", "kerns", "terns", "dodos", "dojos", "rojos", "loofs", "oofs", "hoofs", "roofs", "goofs", "moors", "boors", "doors", "dadas", "charas", "leers", "seers", "cheers", "veers", "reefs", "beefs", "beers", "deers", "trees", "sees", "buys", "guys", "soars", "boars", "roars", "sofas", "oars", "loafs", "oafs", "coifs", "choirs", "naifs", "liars", "dues", "hues", "sues", "rues", "tues", "cues", "sirs", "dirs", "sans", "auras", "axis", "bias", "taxis", "maxis", "virus", "wars", "worms", "hangars", "queers", "queues", "majors", "baasu", "daasu", "garasu", "naasu", "paasu", "beesu", "keesu", "reesu", "peesu", "corsairs"].contains(String(wordRawKeys).lowercased()) && "frxj".contains(character.lowercased()))
                || (["siren", "tureen", "honor", "donor", "worm", "refuse", "reuse", "major", "corsair"].contains(String(wordRawKeys).lowercased()) && "fxj".contains(character.lowercased()))
                || (["lexer", "refer", "defer", "peer"].contains(String(wordRawKeys).lowercased()) && "fxjumn".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "poor" && "fxjimn".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "pays" && character.lowercased() == "a")
                || (["refers", "verse", "vexes", "hexes", "sexes"].contains(String(wordRawKeys).lowercased()) && "frxjumncpt".contains(character.lowercased()))
                || (["mixes", "mixers", "sixes"].contains(String(wordRawKeys).lowercased()) && "emncpt".contains(character.lowercased()))
                || (["cursor", "cursors"].contains(String(wordRawKeys).lowercased()) && "ow".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "oxen" && character.lowercased() == "s")
                || (["manx", "sans"].contains(String(wordRawKeys).lowercased()) && "awgh".contains(character.lowercased()))
                || (["manx", "xerox", "exo"].contains(String(wordRawKeys).lowercased()) && "sfrj".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "xanax" && "sfrjw".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "worn" && "sfxjg".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "vary" && "sfxj".contains(character.lowercased()))
                || (["taxi", "maxi"].contains(String(wordRawKeys).lowercased()) && "frj".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "loris" && "frxjow".contains(character.lowercased()))
                || (["sense", "tense", "dense"].contains(String(wordRawKeys).lowercased()) && "fxjg".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "defend" && "rxjg".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "defends" && "frxjgh".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "ajar" && "sfxjwuymn".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "ajax" && "sfrjwuymn".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "quasar" && "fxjwuymn".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "quasars" && "frxjwuymncpt".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "thorax" && "sfrjowiymn".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "irs" && "frxjaumncpt".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "chasm" && "aw".contains(character.lowercased()))
                || (["coast", "coats", "toast", "cusp", "swops", "soaps", "boron", "moron", "morons", "datas", "basta", "rasta", "gotos", "topos", "photos", "mamas", "nonos", "noops", "goops", "troops", "looms", "dooms", "rooms", "booms", "goons", "loons", "moons", "roots", "boost", "roost", "honor", "donor", "honors", "donors", "barns", "darns", "tarns", "horns", "thorns", "morns", "borns", "corns", "torns", "burns", "turns", "churns", "urns", "arms", "harms", "charms", "norms", "corms", "dorms", "worms", "worst", "hangars"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "w")
                || (["barns", "darns", "tarns", "arms", "harms", "charms"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "a")
                || (["horns", "thorns", "morns", "borns", "corns", "torns", "norms", "corms", "dorms"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "o")
                || (String(wordRawKeys).lowercased() == "disc" && "hdj".contains(character.lowercased()))
                || (["minx", "nginx"].contains(String(wordRawKeys).lowercased()) && "hsfrjg".contains(character.lowercased()))
                || (["oxen", "vixen", "vixens", "siren", "sirens", "risen", "tureen", "tureens", "kern", "kerns", "tern", "terns", "boron", "moron", "morons", "goons", "loons", "moons", "nonos", "chosen", "urana", "xanax", "hana", "nana", "sana", "hono", "dono", "sono", "phono", "honor", "donor", "honors", "donors", "barns", "darns", "tarns", "horns", "thorns", "morns", "borns", "corns", "torns", "burns", "turns", "churns", "urns", "keens", "teens", "queens"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "g")
                || (String(wordRawKeys).lowercased() == "manag" && "sfrxjw".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "monog" && "sfxj".contains(character.lowercased()))
                || (["ore", "guree", "gifi", "dired", "tier", "bier", "trier", "chief", "thief", "miser", "mixer"].contains(String(wordRawKeys).lowercased()) && "mn".contains(character.lowercased()))
                || (["gisi", "giji", "ties", "dies", "lies", "vies", "hies", "tries", "tiers", "biers", "chiefs"].contains(String(wordRawKeys).lowercased()) && "mncpt".contains(character.lowercased()))
                || (["hires", "tires", "mires", "sires"].contains(String(wordRawKeys).lowercased()) && "mncpteu".contains(character.lowercased()))
                || (["berms", "terms", "kerns", "terns"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "e")
                || (["leers", "seers", "cheers", "veers", "reefs", "beefs", "beers", "deers", "terse", "sirs", "dirs", "queers"].contains(String(wordRawKeys).lowercased()) && "mncptu".contains(character.lowercased()))
                || (["sirs", "dirs"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "a")
                || (String(wordRawKeys).lowercased() == "torso" && "mncpti".contains(character.lowercased()))
                || (["bars", "cars", "mars", "tars", "vars", "barfs"].contains(String(wordRawKeys).lowercased()) && "mncptiouywafxjr".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "barf" && "mniouywajxr".contains(character.lowercased()))
                || (["chefs", "refs", "hers", "ers", "nerfs", "serfs"].contains(String(wordRawKeys).lowercased()) && "mncptoefxjr".contains(character.lowercased()))
                || (["nerf", "serf", "kerf"].contains(String(wordRawKeys).lowercased()) && "mnoejxsr".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "vers" && "mncptofxjr".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "ors" && "mncptoiwfxjrae".contains(character.lowercased()))
                || (["urs", "curs"].contains(String(wordRawKeys).lowercased()) && "mncptiuwfxjr".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "burs" && "mncpiuwfxjr".contains(character.lowercased()))
                || (["surf", "turf"].contains(String(wordRawKeys).lowercased()) && "mniuwjxra".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "diesd" && "cmnpt".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "queer" && "umnfxj".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "queue" && "frxj".contains(character.lowercased()))
                || (["buys", "guys"].contains(String(wordRawKeys).lowercased()) && "aumnptc".contains(character.lowercased()))
                || (["bura", "chura", "dura", "gura", "hura", "mura", "nura", "rura", "sura", "tura"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "a")
                || (["queens", "teens", "keens", "sense", "tense", "dense", "defend", "deedsc", "kern", "tern", "kerns", "terns", "barns", "darns", "tarns", "siren", "sirens", "tureen", "tureens", "risen", "vixen", "vixens", "chosen"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "h")
                || (["dodos", "dojos", "rojos", "loofs", "oofs", "hoofs", "roofs", "goofs", "moors", "boors", "doors"].contains(String(wordRawKeys).lowercased()) && "wimncpt".contains(character.lowercased()))
                || (["dadas", "charas"].contains(String(wordRawKeys).lowercased()) && "wuymncpt".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "deeds" && "umnptfrxjc".contains(character.lowercased()))
                || (["daasu", "datas", "dawns", "downs", "darns", "darnsa", "darnsw", "darnsg", "darnsh", "deems", "deeps", "deers", "deersm", "deersn", "deersc", "deersp", "deerst", "deersu", "defer", "defercs", "defercj", "deferps", "deferpj", "deferts", "defertj", "dense", "dirs", "dodos", "dojos", "dooms", "doors", "doorsi", "doorsm", "doorsn", "doorsng", "doorsc", "doorsp", "doorst", "doorsw", "donor", "donors", "dots", "dust", "dura", "duri", "dorm", "dorms", "dormsw", "dormso", "derm", "dora", "dosa", "dosai", "diesm", "diesn", "diesc", "diesp", "diest", "diesng", "dues", "duetsje", "doets", "doetj", "doeps", "doepj", "doecs", "doecj"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "d") {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if String(wordRawKeys).lowercased() == "won" && "gxfsrxjw".contains(character.lowercased()) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if String(wordRawKeys).lowercased() == "yens" && character.lowercased() == "e" {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if ([
                "kiete", "miete", "hiete", "niete", "iete", "diete", "tiete", "biete", "siete", "giete", "riete", "chiete",
                "uete", "suete", "nuete", "muete", "duete", "oto"
            ].contains(String(wordRawKeys).lowercased())
                || (has3CharRhymeAfterOnset
                    && "aoe".contains(r1)
                    && "cpt".contains(r2)
                    && r1 == r3)
                || (rhymeAfterOnset.count == 4
                    && "ao".contains(rhymeAfterOnset[0])
                    && "cpt".contains(rhymeAfterOnset[1])
                    && rhymeAfterOnset[2] == rhymeAfterOnset[0]
                    && rhymeAfterOnset[3] == "w")
                || ["dieted", "duetde", "deferc", "deferp", "defert", "defercd", "deferpd", "defertd", "deferdc", "deferdp", "deferdt", "lexerc", "lexerp", "lexert", "referc", "referp", "refert", "datawd", "datadw", "dapawd", "dapadw", "dotowd", "dotodw", "dopowd", "dopodw", "docowd", "docodw"].contains(String(wordRawKeys).lowercased()))
                && ("sj".contains(character.lowercased())
                    || (wordRawKeys[0].lowercased() == "d" && character.lowercased() == "d")
                    || (character.lowercased() == "w"
                        && (String(wordRawKeys).lowercased() == "oto"
                            || (has3CharRhymeAfterOnset && "ao".contains(r1) && "cpt".contains(r2) && r1 == r3)))) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if has3CharRhymeAfterOnset
                && "aoe".contains(r1)
                && "mn".contains(r2)
                && r1 == r3
                && ("fjx".contains(character.lowercased())
                    || ("ao".contains(r1) && "sw".contains(character.lowercased()) && wordRawKeys[0].lowercased() != "k")
                    || ("ao".contains(r1) && character.lowercased() == "r" && !["hono", "dono"].contains(String(wordRawKeys).lowercased()))
                    || (r1 == "e" && "sr".contains(character.lowercased()) && !["meme", "theme", "gene"].contains(String(wordRawKeys).lowercased()))
                    || ("ao".contains(r1) && r2 == "n" && character.lowercased() == "g" && !"km".contains(wordRawKeys[0].lowercased()))
                    || (r1 == "e" && r2 == "n" && character.lowercased() == "h")
                    || (wordRawKeys[0].lowercased() == "d" && character.lowercased() == "d")) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if String(wordRawKeys).lowercased() == "thaw" && "cmnptfjrx".contains(character.lowercased()) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if String(wordRawKeys).lowercased() == "life" && "emnugxj".contains(character.lowercased()) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if (has3CharRhymeAfterOnset
                && r1 == "u"
                && "rsfjx".contains(r2)
                && "aoui".contains(r3)
                && ("wo".contains(character.lowercased())
                    || (wordRawKeys[0].lowercased() == "d" && character.lowercased() == "d")
                    || ("sfrxj".contains(character.lowercased()) && character.lowercased() != r2)))
                || (has3CharRhymeAfterOnset
                    && r1 == "i"
                    && "rsfjx".contains(r2)
                    && "ua".contains(r3)
                    && wordRawKeys[0].lowercased() != "g"
                    && "sfrxj".contains(character.lowercased())
                    && character.lowercased() != r2)
                || ([
                    "ufo", "uro", "uso", "duos",
                    "ufos", "ufor", "ufox", "ufoj",
                    "uros", "urof", "urox", "uroj",
                    "usof", "usor", "usox", "usoj",
                    "ufoi", "ufom", "ufon", "ufong", "uroi", "urom", "uron", "urong",
                    "usoi", "usom", "uson", "usong", "usoc", "usop", "usot",
                    "duosi", "duosu", "duosm", "duosn", "duosng", "duosc", "duosp", "duost",
                    "duosid", "duosud", "duosmd", "duosnd", "duosngd", "duoscd", "duospd", "duostd"
                ].contains(String(wordRawKeys).lowercased()) && "wo".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "duos" && "frxj".contains(character.lowercased()))
                || ([
                    "duos", "duoso", "duosw",
                    "duosi", "duosu", "duosm", "duosn", "duosng", "duosc", "duosp", "duost"
                ].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "d")
                || (["uru", "usu", "urus", "uruf", "urux", "uruj", "usuf", "usur", "usux", "usuj", "girui", "gisui", "osoi", "hosoi", "moroi", "noroi", "soroi"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "w")
                || (["girui", "gisui", "osoi", "hosoi", "moroi", "noroi", "soroi", "girai", "gisai", "horai", "torai", "hosai", "sosai", "tosai", "bosai", "bofai", "borai", "boxai", "bojai", "mosai", "mofai", "morai", "moxai", "mojai", "vosai", "vofai", "vorai", "voxai", "vojai", "nosai", "nofai", "noxai", "nojai", "rosai", "rofai", "roxai", "rojai", "gosai", "gofai", "gorai", "goxai", "gojai", "phosai", "phofai", "phorai", "phoxai", "phojai", "trosai", "trofai", "trorai", "troxai", "trojai", "dosai", "dofai", "doxai", "dojai", "noxay", "dofay", "doxay", "dojay", "noxao", "dofao", "doxao", "dojao", "sosen", "chosen"].contains(String(wordRawKeys).lowercased())
                    && "sfrxj".contains(character.lowercased())
                    && character.lowercased() != wordRawKeys[wordRawKeys.count - 3].lowercased())
                || (["boais", "boaif", "boair", "boaix", "boaij", "moais", "moaif", "moair", "moaix", "moaij", "voais", "voaif", "voair", "voaix", "voaij", "noais", "noaif", "noair", "noaix", "noaij", "roais", "roaif", "roair", "roaix", "roaij", "goais", "goaif", "goair", "goaix", "goaij", "poais", "poaif", "poair", "poaix", "poaij", "phoais", "phoaif", "phoair", "phoaix", "phoaij", "troais", "troaif", "troair", "troaix", "troaij", "koais", "koaif", "koair", "koaix", "koaij", "doais", "doaif", "doair", "doaix", "doaij", "boays", "boayf", "boayr", "boayx", "boayj", "moays", "moayf", "moayr", "moayx", "moayj", "voays", "voayf", "voayr", "voayx", "voayj", "noays", "noayf", "noayr", "noayx", "noayj", "roays", "roayf", "roayr", "roayx", "roayj", "goays", "goayf", "goayr", "goayx", "goayj", "poays", "poayf", "poayr", "poayx", "poayj", "phoays", "phoayf", "phoayr", "phoayx", "phoayj", "troays", "troayf", "troayr", "troayx", "troayj", "koays", "koayf", "koayr", "koayx", "koayj", "doays", "doayf", "doayr", "doayx", "doayj", "boaos", "boaof", "boaor", "boaox", "boaoj", "moaos", "moaof", "moaor", "moaox", "moaoj", "voaos", "voaof", "voaor", "voaox", "voaoj", "noaos", "noaof", "noaor", "noaox", "noaoj", "roaos", "roaof", "roaor", "roaox", "roaoj", "goaos", "goaof", "goaor", "goaox", "goaoj", "poaos", "poaof", "poaor", "poaox", "poaoj", "phoaos", "phoaof", "phoaor", "phoaox", "phoaoj", "troaos", "troaof", "troaor", "troaox", "troaoj", "koaos", "koaof", "koaor", "koaox", "koaoj", "doaos", "doaof", "doaor", "doaox", "doaoj", "boanhs", "boanhf", "boanhr", "boanhx", "boanhj", "moanhs", "moanhf", "moanhr", "moanhx", "moanhj", "voanhs", "voanhf", "voanhr", "voanhx", "voanhj", "noanhs", "noanhf", "noanhr", "noanhx", "noanhj", "roanhs", "roanhf", "roanhr", "roanhx", "roanhj", "goanhs", "goanhf", "goanhr", "goanhx", "goanhj", "poanhs", "poanhf", "poanhr", "poanhx", "poanhj", "phoanhs", "phoanhf", "phoanhr", "phoanhx", "phoanhj", "troanhs", "troanhf", "troanhr", "troanhx", "troanhj", "koanhs", "koanhf", "koanhr", "koanhx", "koanhj", "kanhs", "kanhf", "kanhr", "kanhx", "kanhj", "panhs", "panhf", "panhr", "panhx", "panhj", "boeos", "boeof", "boeor", "boeox", "boeoj", "moeos", "moeof", "moeor", "moeox", "moeoj", "voeos", "voeof", "voeor", "voeox", "voeoj", "noeos", "noeof", "noeor", "noeox", "noeoj", "roeos", "roeof", "roeor", "roeox", "roeoj", "goeos", "goeof", "goeor", "goeox", "goeoj", "poeos", "poeof", "poeor", "poeox", "poeoj", "phoeos", "phoeof", "phoeor", "phoeox", "phoeoj", "troeos", "troeof", "troeor", "troeox", "troeoj", "koeos", "koeof", "koeor", "koeox", "koeoj", "doeos", "doeof", "doeor", "doeox", "doeoj", "boens", "boenf", "boenr", "boenx", "boenj", "moens", "moenf", "moenr", "moenx", "moenj", "voens", "voenf", "voenr", "voenx", "voenj", "noens", "noenf", "noenr", "noenx", "noenj", "roens", "roenf", "roenr", "roenx", "roenj", "goens", "goenf", "goenr", "goenx", "goenj", "poens", "poenf", "poenr", "poenx", "poenj", "phoens", "phoenf", "phoenr", "phoenx", "phoenj", "troens", "troenf", "troenr", "troenx", "troenj", "koens", "koenf", "koenr", "koenx", "koenj", "doens", "doenf", "doenr", "doenx", "doenj", "coens", "coenf", "coenr", "coenx", "coenj", "soens", "soenf", "soenr", "soenx", "soenj", "boems", "boemf", "boemr", "boemx", "boemj", "moems", "moemf", "moemr", "moemx", "moemj", "voems", "voemf", "voemr", "voemx", "voemj", "noems", "noemf", "noemr", "noemx", "noemj", "roems", "roemf", "roemr", "roemx", "roemj", "goems", "goemf", "goemr", "goemx", "goemj", "poemf", "poemr", "poemx", "poemj", "phoems", "phoemf", "phoemr", "phoemx", "phoemj", "troems", "troemf", "troemr", "troemx", "troemj", "koems", "koemf", "koemr", "koemx", "koemj", "doems", "doemf", "doemr", "doemx", "doemj", "coems", "coemf", "coemr", "coemx", "coemj", "soems", "soemf", "soemr", "soemx", "soemj"].contains(String(wordRawKeys).lowercased())
                    && "sfrxj".contains(character.lowercased())
                    && character.lowercased() != wordRawKeys.last?.lowercased())
                || (["noaxi", "noaxy", "noaxo", "goasi", "goasy", "goaso", "doasi", "doafi", "doari", "doaxi", "doaji", "doasy", "doafy", "doary", "doaxy", "doajy", "doaso", "doafo", "doaro", "doaxo", "doajo", "doesn"].contains(String(wordRawKeys).lowercased())
                    && "sfrxj".contains(character.lowercased())
                    && character.lowercased() != wordRawKeys[wordRawKeys.count - 2].lowercased())
                || (["boans", "boanf", "boanr", "boanx", "boanj", "moans", "moanf", "moanr", "moanx", "moanj", "voans", "voanf", "voanr", "voanx", "voanj", "noans", "noanf", "noanr", "noanj", "roans", "roanf", "roanr", "roanx", "roanj", "goans", "goanf", "goanr", "goanx", "goanj", "poans", "poanf", "poanr", "poanx", "poanj", "phoans", "phoanf", "phoanr", "phoanx", "phoanj", "troans", "troanf", "troanr", "troanx", "troanj", "koans", "koanf", "koanr", "koanx", "koanj", "kans", "kanf", "kanr", "kanx", "kanj", "pans", "panf", "panr", "panx", "panj"].contains(String(wordRawKeys).lowercased())
                    && ("ghwsfrxj".contains(character.lowercased()) || (character.lowercased() == "a" && ["kanf", "kanr", "kanx", "kanj", "pans", "panf", "panr", "panx", "panj"].contains(String(wordRawKeys).lowercased())))
                    && character.lowercased() != wordRawKeys.last?.lowercased())
                || (String(wordRawKeys).lowercased() == "goasn" && "ghwfrxj".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "trojan" && "ghwfrx".contains(character.lowercased()))
                || (["boams", "boamf", "boamr", "boamx", "boamj", "moams", "moamf", "moamr", "moamx", "moamj", "voams", "voamf", "voamr", "voamx", "voamj", "noams", "noamf", "noamr", "noamx", "noamj", "roams", "roamf", "roamr", "roamx", "roamj", "goams", "goamf", "goamr", "goamx", "goamj", "poams", "poamf", "poamr", "poamx", "poamj", "phoams", "phoamf", "phoamr", "phoamx", "phoamj", "troams", "troamf", "troamr", "troamx", "troamj", "koams", "koamf", "koamr", "koamx", "koamj", "boangs", "boangf", "boangr", "boangx", "boangj", "moangs", "moangf", "moangr", "moangx", "moangj", "voangs", "voangf", "voangr", "voangx", "voangj", "noangs", "noangf", "noangr", "noangx", "noangj", "roangs", "roangf", "roangr", "roangx", "roangj", "goangs", "goangf", "goangr", "goangx", "goangj", "poangs", "poangf", "poangr", "poangx", "poangj", "phoangs", "phoangf", "phoangr", "phoangx", "phoangj", "troangs", "troangf", "troangr", "troangx", "troangj", "koangs", "koangf", "koangr", "koangx", "koangj", "kams", "kamf", "kamr", "kamx", "kamj", "pams", "pamf", "pamr", "pamx", "pamj", "kangs", "kangf", "kangr", "kangx", "kangj", "pangs", "pangf", "pangr", "pangx", "pangj"].contains(String(wordRawKeys).lowercased())
                    && ("wsfrxj".contains(character.lowercased()) || (character.lowercased() == "a" && ["kams", "kamf", "kamr", "kamx", "kamj", "pams", "pamf", "pamr", "pamx", "pamj", "kangs", "kangf", "kangr", "kangx", "kangj", "pangs", "pangf", "pangr", "pangx", "pangj"].contains(String(wordRawKeys).lowercased())))
                    && character.lowercased() != wordRawKeys.last?.lowercased())
                || (["goasm", "noaxm", "noxam"].contains(String(wordRawKeys).lowercased())
                    && "wsfrxj".contains(character.lowercased())
                    && character.lowercased() != (String(wordRawKeys).lowercased() == "goasm" ? "s" : "x"))
                || (["boast", "roast", "goast", "goasp"].contains(String(wordRawKeys).lowercased())
                    && "wj".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "goasc" && "hwj".contains(character.lowercased()))
                || (["boats", "boatj", "moats", "moatj", "voats", "voatj", "noats", "noatj", "roats", "roatj", "goats", "goatj", "poats", "poatj", "phoats", "phoatj", "troats", "troatj", "koats", "koatj", "boaps", "boapj", "moaps", "moapj", "voaps", "voapj", "noaps", "noapj", "roaps", "roapj", "goaps", "goapj", "poaps", "poapj", "phoaps", "phoapj", "troaps", "troapj", "koaps", "koapj", "boachs", "boachj", "moachs", "moachj", "voachs", "voachj", "noachs", "noachj", "roachs", "roachj", "goachs", "goachj", "poachs", "poachj", "phoachs", "phoachj", "troachs", "troachj", "koachs", "koachj"].contains(String(wordRawKeys).lowercased())
                    && "wsj".contains(character.lowercased())
                    && character.lowercased() != wordRawKeys.last?.lowercased())
                || (["boacs", "boacj", "moacs", "moacj", "voacs", "voacj", "noacs", "noacj", "roacs", "roacj", "goacs", "goacj", "poacs", "poacj", "phoacs", "phoacj", "troacs", "troacj", "koacs", "koacj"].contains(String(wordRawKeys).lowercased())
                    && "hwsj".contains(character.lowercased())
                    && character.lowercased() != wordRawKeys.last?.lowercased())
                || (["boets", "boetj", "moets", "moetj", "voets", "voetj", "noets", "noetj", "roets", "roetj", "goets", "goetj", "poets", "poetj", "phoets", "phoetj", "troets", "troetj", "koets", "koetj", "doets", "doetj", "coets", "coetj", "soets", "soetj", "boeps", "boepj", "moeps", "moepj", "voeps", "voepj", "noeps", "noepj", "roeps", "roepj", "goeps", "goepj", "poeps", "poepj", "phoeps", "phoepj", "troeps", "troepj", "koeps", "koepj", "doeps", "doepj", "coeps", "coepj", "soeps", "soepj", "boecs", "boecj", "moecs", "moecj", "voecs", "voecj", "noecs", "noecj", "roecs", "roecj", "goecs", "goecj", "poecs", "poecj", "phoecs", "phoecj", "troecs", "troecj", "koecs", "koecj", "doecs", "doecj", "coecs", "coecj", "soecs", "soecj"].contains(String(wordRawKeys).lowercased())
                    && "sj".contains(character.lowercased())
                    && character.lowercased() != wordRawKeys.last?.lowercased())
                || (["arau", "harau", "sarau", "tarau", "narau", "asaru", "hasaru", "masaru", "nasaru", "sasaru", "tasaru", "gaaru", "paaru", "beeru", "meeru", "neeru", "reeru", "seeru", "teeru", "uraya", "urana", "guree", "ieru", "kieru", "mieru", "hieru", "nieru", "tieru", "bieru", "sieru", "gieru", "rieru", "chieru"].contains(String(wordRawKeys).lowercased())
                    && "sfxj".contains(character.lowercased()))
                || (["haafu", "saafu", "taafu", "seefu"].contains(String(wordRawKeys).lowercased())
                    && "srxj".contains(character.lowercased()))
                || (["toori", "sosori"].contains(String(wordRawKeys).lowercased())
                    && "sfxjw".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "aru" && "asfxj".contains(character.lowercased()))
                || (["iru", "isu"].contains(String(wordRawKeys).lowercased()) && "sfrxj".contains(character.lowercased()) && character.lowercased() != wordRawKeys[1].lowercased())
                || (["esu", "efu", "eru"].contains(String(wordRawKeys).lowercased()) && "esfrxj".contains(character.lowercased()) && character.lowercased() != wordRawKeys[1].lowercased())
                || (String(wordRawKeys).lowercased() == "asa" && "cmnptuywfrxj".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "giro" && "aeowimnsfxj".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "gifu" && "aowiymnsrxj".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "giju" && "aowiymncptsfrx".contains(character.lowercased()))
                || (["gifi", "gisi", "giji"].contains(String(wordRawKeys).lowercased()) && "sfrxj".contains(character.lowercased()) && character.lowercased() != r2)
                || (["gire", "gise"].contains(String(wordRawKeys).lowercased()) && ("osfrxj".contains(character.lowercased()) && character.lowercased() != r2))
                || (rhymeAfterOnset.count >= 4
                    && rhymeAfterOnset[0] == "u"
                    && (("rsfjx".contains(rhymeAfterOnset[1]) && rhymeAfterOnset[2] == "o")
                        || (rhymeAfterOnset[1] == "o" && "rsfjx".contains(rhymeAfterOnset[2])))
                    && (("wo".contains(character.lowercased())
                        && Self.matchesDiphthongCodaTail(rhymeAfterOnset[3...].joined(), nonStopCodas: ["i", "u", "m", "n", "ng"], stopCodas: ["p", "t", "c"]))
                        || ("sj".contains(character.lowercased())
                            && Self.matchesDiphthongCodaTail(rhymeAfterOnset[3...].joined(), nonStopCodas: [], stopCodas: ["p", "t", "c"], requiredDiacritics: "wo", allowToneOverride: false))
                        || (wordRawKeys[0].lowercased() == "d"
                            && character.lowercased() == "d"
                            && (Self.matchesDiphthongCodaTail(rhymeAfterOnset[3...].joined(), nonStopCodas: ["i", "u", "m", "n", "ng"], stopCodas: ["p", "t", "c"], allowToneOverride: false, allowD: false)
                                || Self.matchesDiphthongCodaTail(rhymeAfterOnset[3...].joined(), nonStopCodas: ["i", "u", "m", "n", "ng"], stopCodas: ["p", "t", "c"], requiredDiacritics: "wo", allowToneOverride: true, allowD: false)))))
                || (rhymeAfterOnset.count >= 4
                    && rhymeAfterOnset[0] == "u"
                    && (("rsfjx".contains(rhymeAfterOnset[1]) && rhymeAfterOnset[2] == "a")
                        || (rhymeAfterOnset[1] == "a" && "rsfjx".contains(rhymeAfterOnset[2])))
                    && ((character.lowercased() == "a"
                        && Self.matchesDiphthongCodaTail(rhymeAfterOnset[3...].joined(), nonStopCodas: ["m", "n", "ng", "y"], stopCodas: ["t", "c"]))
                        || ("sj".contains(character.lowercased())
                            && Self.matchesDiphthongCodaTail(rhymeAfterOnset[3...].joined(), nonStopCodas: [], stopCodas: ["t", "c"], requiredDiacritics: "a", allowToneOverride: false))
                        || (wordRawKeys[0].lowercased() == "d"
                            && character.lowercased() == "d"
                            && (Self.matchesDiphthongCodaTail(rhymeAfterOnset[3...].joined(), nonStopCodas: ["m", "n", "ng", "y"], stopCodas: ["t", "c"], allowToneOverride: false, allowD: false)
                                || Self.matchesDiphthongCodaTail(rhymeAfterOnset[3...].joined(), nonStopCodas: ["m", "n", "ng", "y"], stopCodas: ["t", "c"], requiredDiacritics: "a", allowToneOverride: true, allowD: false))))) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if ((has3CharRhymeAfterOnset
                && (r1 == "i" || r1 == "u")
                && "rsfjx".contains(r2)
                && r3 == "e"
                && (character.lowercased() == "e"
                    || (r1 == "i" && "rfx".contains(r2) && "mn".contains(character.lowercased()) && (!["vixe", "sire"].contains(String(wordRawKeys).lowercased()) || character.lowercased() == "m"))
                    || (r1 == "i" && "sj".contains(r2) && "cmnpt".contains(character.lowercased()) && (String(wordRawKeys).lowercased() != "rise" || character.lowercased() != "n"))
                    || ("rsfjx".contains(r2) && wordRawKeys[0].lowercased() == "d" && character.lowercased() == "d")
                    || (!"wf".contains(wordRawKeys[0].lowercased())
                        && "sfrxj".contains(character.lowercased())
                        && character.lowercased() != r2
                        && ((r1 == "i"
                            && ((r2 == "r" && ("fxj".contains(character.lowercased()) || !["hire", "tire", "mire", "sire", "dire", "lire", "vire"].contains(String(wordRawKeys).lowercased())))
                                || (r2 == "s" && ("fxj".contains(character.lowercased()) || !["mise", "rise", "wise", "vise"].contains(String(wordRawKeys).lowercased())))
                                || (r2 == "f" && ("xj".contains(character.lowercased()) || !["life", "wife"].contains(String(wordRawKeys).lowercased())))
                                || r2 == "j"
                                || (r2 == "x" && ("fj".contains(character.lowercased()) || ["chixe", "pixe", "kixe"].contains(String(wordRawKeys).lowercased())))))
                            || (r1 == "u"
                                && ((r2 == "r" && ("fxj".contains(character.lowercased()) || !["cure", "lure", "sure"].contains(String(wordRawKeys).lowercased())))
                                    || (r2 == "s" && ("fxj".contains(character.lowercased()) || !["muse", "ruse", "fuse", "use"].contains(String(wordRawKeys).lowercased())))
                                    || (r2 == "x" && ("frj".contains(character.lowercased()) || String(wordRawKeys).lowercased() != "tuxe"))
                                    || "fj".contains(r2)))))))
                || (rhymeAfterOnset.count >= 4
                    && rhymeAfterOnset[0] == "i"
                    && (("rsfjx".contains(rhymeAfterOnset[1]) && rhymeAfterOnset[2] == "e")
                        || (rhymeAfterOnset[1] == "e" && "rsfjx".contains(rhymeAfterOnset[2])))
                    && ((character.lowercased() == "e"
                        && (rhymeAfterOnset[3...].joined() == "d"
                            || Self.matchesDiphthongCodaTail(rhymeAfterOnset[3...].joined(), nonStopCodas: ["", "u", "m", "n", "ng"], stopCodas: ["c", "t", "p"], allowD: wordRawKeys[0].lowercased() == "d")))
                        || ("sj".contains(character.lowercased())
                            && Self.matchesDiphthongCodaTail(rhymeAfterOnset[3...].joined(), nonStopCodas: [], stopCodas: ["c", "t", "p"], requiredDiacritics: "e", allowToneOverride: false))
                        || (wordRawKeys[0].lowercased() == "d"
                            && character.lowercased() == "d"
                            && Self.matchesDiphthongCodaTail(rhymeAfterOnset[3...].joined(), nonStopCodas: ["", "u", "m", "n", "ng"], stopCodas: ["c", "t", "p"], requiredDiacritics: "e", allowToneOverride: true, allowD: false))))
                || ([
                    "yesn", "yesm", "yesng", "yest", "yesc", "yesp",
                    "usen", "usem", "usenh", "uset", "usep", "usech",
                    "uren", "urem", "urenh",
                    "iren", "irem", "ireng", "ireu",
                    "diesmd", "diesnd", "diescd", "diespd", "diestd", "diesngd",
                    "duetj", "duetjd", "duetdj", "duetsd", "duetds", "miser"
                ].contains(String(wordRawKeys).lowercased())
                    && character.lowercased() == "e")
                || (rhymeAfterOnset.count >= 4
                    && rhymeAfterOnset[0] == "u"
                    && (("rsfjx".contains(rhymeAfterOnset[1]) && rhymeAfterOnset[2] == "e")
                        || (rhymeAfterOnset[1] == "e" && "rsfjx".contains(rhymeAfterOnset[2])))
                    && ((character.lowercased() == "e"
                        && (rhymeAfterOnset[3...].joined() == "d"
                            || Self.matchesDiphthongCodaTail(rhymeAfterOnset[3...].joined(), nonStopCodas: ["", "m", "n", "nh"], stopCodas: ["c", "p", "t", "ch"], allowD: wordRawKeys[0].lowercased() == "d")))
                        || ("sj".contains(character.lowercased())
                            && Self.matchesDiphthongCodaTail(rhymeAfterOnset[3...].joined(), nonStopCodas: [], stopCodas: ["c", "p", "t", "ch"], requiredDiacritics: "e", allowToneOverride: false))
                        || (wordRawKeys[0].lowercased() == "d"
                            && character.lowercased() == "d"
                            && Self.matchesDiphthongCodaTail(rhymeAfterOnset[3...].joined(), nonStopCodas: ["", "m", "n", "nh"], stopCodas: ["c", "p", "t", "ch"], requiredDiacritics: "e", allowToneOverride: true, allowD: false))))
                || (String(wordRawKeys).lowercased() == "tureen" && character.lowercased() == "h")
                || Self.matchesIeUeStemDelayedDiacriticUnlatch(wordRawKeys: wordRawKeys, character: character)
                || Self.matchesVowelInitialDiphthongUnlatch(wordRawKeys: wordRawKeys, character: character)
                || Self.matchesUyOaOeClusterUnlatch(wordRawKeys: wordRawKeys, prefix2: prefix2, rhymeAfterOnset: rhymeAfterOnset, character: character)
                || Self.isVietnameseCollocation(candidateWord: (String(wordRawKeys) + String(character)).lowercased(), lastCompletedWord: lastCompletedWord)) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if (has3CharRhymeAfterOnset
                && ((r1 == "e" && "rsfjx".contains(r2) && r3 == "u"
                    && (character.lowercased() == "e"
                        || (wordRawKeys[0].lowercased() == "d" && character.lowercased() == "d")
                        || (wordRawKeys[0].lowercased() != "z"
                            && "sfrxj".contains(character.lowercased())
                            && character.lowercased() != r2
                            && !(["refu", "peru"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "s"))))
                    || (r1 == "e" && "rsfjx".contains(r2) && r3 == "o"
                        && ((wordRawKeys[0].lowercased() == "d" && character.lowercased() == "d")
                            || (r2 == "s" && wordRawKeys[0].lowercased() != "z" && "frxj".contains(character.lowercased()))
                            || (r2 == "r" && ["hero", "nero", "rero"].contains(String(wordRawKeys).lowercased()) && "fxj".contains(character.lowercased()))
                            || (["nero", "rero"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "s")
                            || (((wordRawKeys[0].lowercased() == "p" && prefix2 != "ph") || (wordRawKeys[0].lowercased() == "g" && prefix2 != "gh" && prefix2 != "gi") || prefix2 == "ng") && "sfrxj".contains(character.lowercased()) && character.lowercased() != r2)))
                    || (r1 == "a" && "rsfjx".contains(r2) && "uy".contains(r3)
                        && (character.lowercased() == "a"
                            || (wordRawKeys[0].lowercased() == "d" && character.lowercased() == "d")
                            || ((r3 == "u" || (r3 == "y" && "kp".contains(wordRawKeys[0].lowercased()) && prefix2 != "kh" && prefix2 != "ph")) && "sfrxj".contains(character.lowercased()) && character.lowercased() != r2)))
                    || (r1 == "a" && "rsfjx".contains(r2) && r3 == "i"
                        && ((r2 == "r" && ("fxj".contains(character.lowercased()) || (String(wordRawKeys).lowercased() == "rari" && character.lowercased() == "s") || (wordRawKeys[0].lowercased() == "d" && character.lowercased() == "d")))
                            || ("kp".contains(wordRawKeys[0].lowercased()) && prefix2 != "kh" && prefix2 != "ph" && "sfrxj".contains(character.lowercased()) && character.lowercased() != r2 && !(String(wordRawKeys).lowercased() == "pari" && character.lowercased() == "s"))))
                    || (r1 == "a" && "rsfjx".contains(r2) && r3 == "o"
                        && "kp".contains(wordRawKeys[0].lowercased())
                        && prefix2 != "kh"
                        && prefix2 != "ph"
                        && "sfrxj".contains(character.lowercased())
                        && character.lowercased() != r2)
                    || (r1 == "o" && "rsfjx".contains(r2) && r3 == "i"
                        && ("ow".contains(character.lowercased())
                            || (wordRawKeys[0].lowercased() == "d" && character.lowercased() == "d")
                            || (["nori", "rori"].contains(String(wordRawKeys).lowercased()) && "sfxj".contains(character.lowercased()))
                            || ("kp".contains(wordRawKeys[0].lowercased()) && prefix2 != "kh" && prefix2 != "ph" && "sfrxj".contains(character.lowercased()) && character.lowercased() != r2)))
                    || (r1 == "e" && r2 == "r" && "mn".contains(r3) && ("efjx".contains(character.lowercased()) || (String(wordRawKeys).lowercased() == "derm" && character.lowercased() == "s")))
                    || (["deso", "daru", "dasu"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "d")
                    || (["maso", "saso"].contains(String(wordRawKeys).lowercased()) && "frxj".contains(character.lowercased()))
                    || (r1 == "o" && "rsfjx".contains(r2) && r3 == "a"
                        && (("sj".contains(r2) && "cmnpt".contains(character.lowercased()) && !(String(wordRawKeys).lowercased() == "troja" && character.lowercased() == "n"))
                            || ("rfx".contains(r2) && "mn".contains(character.lowercased()))
                            || character.lowercased() == "y"
                            || (character.lowercased() == "i" && ["sora", "lora", "sofa", "dora", "nora", "rora", "kosa", "kofa", "kora", "koxa", "koja", "posa", "pofa", "pora", "poxa", "poja"].contains(String(wordRawKeys).lowercased()))
                            || (character.lowercased() == "o" && ["sora", "lora", "sofa", "sosa", "tosa", "dora", "dosa", "nora", "rora", "kosa", "kofa", "kora", "koxa", "koja", "posa", "pofa", "pora", "poxa", "poja", "bosa", "bofa", "bora", "boxa", "boja", "mosa", "mofa", "mora", "moxa", "moja", "vosa", "vofa", "vora", "voxa", "voja", "nosa", "nofa", "noja", "rosa", "rofa", "roxa", "roja", "gosa", "gofa", "gora", "goxa", "goja", "phosa", "phofa", "phora", "phoxa", "phoja", "trosa", "trofa", "trora", "troxa", "troja"].contains(String(wordRawKeys).lowercased()))
                            || (character.lowercased() == "w" && ["sora", "lora", "sofa", "sosa", "tosa", "dora", "dosa", "nora", "rora", "kosa", "kofa", "kora", "koxa", "koja", "posa", "pofa", "pora", "poxa", "poja", "bosa", "bofa", "bora", "boxa", "boja", "mosa", "mofa", "mora", "moxa", "moja", "vosa", "vofa", "vora", "voxa", "voja", "nosa", "nofa", "noja", "rosa", "rofa", "roxa", "roja", "gosa", "gofa", "gora", "goxa", "goja", "phosa", "phofa", "phora", "phoxa", "phoja", "trosa", "trofa", "trora", "troxa", "troja"].contains(String(wordRawKeys).lowercased()))
                            || (["sora", "lora", "dora", "sosa", "tosa", "dosa", "kosa", "kofa", "kora", "koxa", "koja", "posa", "pofa", "pora", "poxa", "poja", "bosa", "bofa", "bora", "boxa", "boja", "mosa", "mofa", "mora", "moxa", "moja", "vosa", "vofa", "vora", "voxa", "voja", "nosa", "nofa", "noja", "rosa", "rofa", "roxa", "roja", "gosa", "gofa", "gora", "goxa", "goja", "phosa", "phofa", "phora", "phoxa", "phoja", "trosa", "trofa", "trora", "troxa", "troja"].contains(String(wordRawKeys).lowercased()) && "sfrxj".contains(character.lowercased()) && character.lowercased() != r2 && !(String(wordRawKeys).lowercased() == "kora" && character.lowercased() == "r") && !(String(wordRawKeys).lowercased() == "bora" && character.lowercased() == "x"))
                            || (String(wordRawKeys).lowercased() == "sofa" && "rxj".contains(character.lowercased()))
                            || (["nora", "rora"].contains(String(wordRawKeys).lowercased()) && "fxj".contains(character.lowercased()))))))
                || (wordRawKeys.first?.lowercased() == "d"
                    && (rhymeAfterOnset.count == 4 || (rhymeAfterOnset.count == 5 && "sfrxj".contains(rhymeAfterOnset[4])))
                    && rhymeAfterOnset[0] == "o"
                    && (("rsfjx".contains(rhymeAfterOnset[1]) && "ae".contains(rhymeAfterOnset[2]) && "iyonm".contains(rhymeAfterOnset[3]))
                        || ("ae".contains(rhymeAfterOnset[1]) && "rsfjx".contains(rhymeAfterOnset[2]) && "iyonm".contains(rhymeAfterOnset[3]))
                        || ("ae".contains(rhymeAfterOnset[1]) && "iyonm".contains(rhymeAfterOnset[2]) && "rsfjx".contains(rhymeAfterOnset[3])))
                    && character.lowercased() == "d") {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if ((has3CharRhymeAfterOnset
                && "aou".contains(r1)
                && r2 == "r"
                && r3 == "n")
                || String(wordRawKeys).lowercased() == "urn")
                && ("gw".contains(character.lowercased())
                    || ("fjx".contains(character.lowercased()) && wordRawKeys[0].lowercased() != "w")
                    || ("ao".contains(r1) && character.lowercased() == r1 && wordRawKeys[0].lowercased() != "w")
                    || (r1 == "a" && character.lowercased() == "h")
                    || (wordRawKeys[0].lowercased() == "d" && character.lowercased() == "d")) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if has3CharRhymeAfterOnset
                && "ao".contains(r1)
                && r2 == "r"
                && r3 == "m"
                && (character.lowercased() == "w"
                    || ("jx".contains(character.lowercased()) && !"wf".contains(wordRawKeys[0].lowercased()))
                    || (character.lowercased() == "f" && !"wf".contains(wordRawKeys[0].lowercased()) && String(wordRawKeys).lowercased() != "harm")
                    || (character.lowercased() == r1 && wordRawKeys[0].lowercased() != "w")
                    || (wordRawKeys[0].lowercased() == "d" && character.lowercased() == "d")) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if String(wordRawKeys).lowercased() == "harmf" && "aw".contains(character.lowercased()) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if (["cost", "most"].contains(String(wordRawKeys).lowercased()) && "woj".contains(character.lowercased()))
                || (["rust", "dust", "burst", "cusp", "coast", "coats", "soaps", "boost", "roost", "roots", "noops", "goops", "troops"].contains(String(wordRawKeys).lowercased()) && "wj".contains(character.lowercased()))
                || (["gasp", "rasp"].contains(String(wordRawKeys).lowercased()) && "waj".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "test" && "ej".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "lisp" && character.lowercased() == "j")
                || (((has3CharRhymeAfterOnset
                    && "aouiey".contains(r1)
                    && "rfx".contains(r2)
                    && "cpt".contains(r3)
                    && !"wfjz".contains(wordRawKeys[0].lowercased())
                    && (wordRawKeys[0].lowercased() != "p" || prefix2 == "ph"))
                    || ["art", "arc", "orc", "aft", "oft"].contains(String(wordRawKeys).lowercased()))
                    && (character.lowercased() == "j"
                        || (character.lowercased() == "s"
                            && has3CharRhymeAfterOnset
                            && ("fx".contains(r2) || prefix2 == "dd")
                            && !["raft", "loft", "toft", "tuft", "theft", "gift", "lift", "rift", "sift", "text", "sext", "mixt"].contains(String(wordRawKeys).lowercased()))))
                || (((rhymeAfterOnset.count == 4
                    && "aei".contains(rhymeAfterOnset[0])
                    && "rfx".contains(rhymeAfterOnset[1])
                    && rhymeAfterOnset[2] == "c"
                    && rhymeAfterOnset[3] == "h"
                    && !"wfjz".contains(wordRawKeys[0].lowercased())
                    && (wordRawKeys[0].lowercased() != "p" || prefix2 == "ph"))
                    || ["arch", "irch", "afch", "ifch", "axch", "ixch"].contains(String(wordRawKeys).lowercased()))
                    && (character.lowercased() == "j"
                        || (character.lowercased() == "s"
                            && !["arch", "merch", "perch"].contains(String(wordRawKeys).lowercased()))))
                || Self.matchesMonophthongStopCodaDiacriticUnlatch(
                    wordRawKeys: wordRawKeys,
                    prefix2: prefix2,
                    rhymeAfterOnset: rhymeAfterOnset,
                    character: character
                )
                || Self.matchesPreDiacriticStopCodaToneOverrideUnlatch(
                    wordRawKeys: wordRawKeys,
                    prefix2: prefix2,
                    rhymeAfterOnset: rhymeAfterOnset,
                    character: character
                )
                || Self.matchesPostCodaStopToneOverrideUnlatch(
                    wordRawKeys: wordRawKeys,
                    prefix2: prefix2,
                    rhymeAfterOnset: rhymeAfterOnset,
                    character: character
                ) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if _config.escapeByDoubleKey && ["ties", "laws", "raws", "saws", "thaws", "caws", "maws", "haws", "toes", "hoes", "roes", "noes", "dues", "hues", "cues", "sues", "rues", "tues"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "s" {
                return MinimalDiff.calculate(previous: prevDisplay, next: prevDisplay)
            } else {
                lastDeletedChar = nil

                // If word was already auto-bypassed before 'w' (e.g. 'down', 'show', 'flow', 'follow', 'hardware'),
                // and user presses a second 'w' out of Telex double-key escape habit, absorb the duplicate 'w'.
                if _config.escapeByDoubleKey
                    && (_config.inputMethod == .telex || _config.inputMethod == .simpleTelex)
                    && (character == "w" || character == "W")
                    && !transformState.didAbsorbBypassW {
                    let lowerPreedit = activePreedit.lowercased()
                    let isVowelW = lowerPreedit.hasSuffix("ow") || lowerPreedit.hasSuffix("aw") || lowerPreedit.hasSuffix("uw")
                    let isTelexConsonantW = _config.inputMethod == .telex
                        && lowerPreedit.count >= 2
                        && lowerPreedit != "ww"
                        && lowerPreedit.hasSuffix("w")
                    if isVowelW || isTelexConsonantW {
                        transformState.didAbsorbBypassW = true
                        return MinimalDiff.calculate(previous: prevDisplay, next: prevDisplay)
                    }
                }
                transformState.didAbsorbBypassW = false

                wordRawKeys.append(character)
                activeRawKeys.append(character)
                activePreedit.append(character)

                let rawActive = String(activeRawKeys)
                let lowerRawActive = rawActive.lowercased()
                let hasPrecedingSepInBypass = committedPrefix.last != nil && EnglishRestoreDetector.isTechnicalSeparator(committedPrefix.last!)
                let fullRawWord = String(wordRawKeys)
                let lowerFullRawWord = fullRawWord.lowercased()
                if activePreedit != rawActive || (!hasPrecedingSepInBypass && !committedPrefix.isEmpty) {
                    if EnglishRestoreDetector.hasInvalidMedialDoubleConsonant(lowerFullRawWord)
                        || EnglishRestoreDetector.isEnglishKeyword(lowerFullRawWord)
                        || JapaneseRomajiDetector.shouldRestoreRomaji(candidateWord: lowerFullRawWord)
                        || EnglishRestoreDetector.hasInvalidMedialDoubleConsonant(lowerRawActive)
                        || EnglishRestoreDetector.isEnglishKeyword(lowerRawActive)
                        || JapaneseRomajiDetector.shouldRestoreRomaji(candidateWord: lowerRawActive) {
                        if hasPrecedingSepInBypass {
                            activePreedit = rawActive
                        } else {
                            committedPrefix = ""
                            activePreedit = fullRawWord
                            activeRawKeys = Array(fullRawWord)
                        }
                        let newDisplay = committedPrefix + activePreedit
                        return MinimalDiff.calculate(previous: prevDisplay, next: newDisplay)
                    } else if !"aeiouy".contains(character.lowercased()) {
                        // A non-vowel followed a double-key tone undo (e.g. 'tarr' + 'g' in 'target'):
                        // synchronize raw key buffers with the undone display string.
                        activeRawKeys = Array(activePreedit)
                        wordRawKeys = Array(committedPrefix + activePreedit)
                    }
                }

                return nil
            }
        }
        let wasUnlatchedInStep2 = wasBypassedBeforeStep2 && !isBypassed

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

        let hasPrecedingTechSep = committedPrefix.last != nil && EnglishRestoreDetector.isTechnicalSeparator(committedPrefix.last!)

        // 3. Known English Keyword, Romaji & Medial Double Consonant Check for Full Word (e.g. window, origin, harajuku, wagyu)
        let rawWordString = String(wordRawKeys) + String(character)
        let candidateWord = rawWordString.lowercased()
        let isTelexSwEnglish = (_config.inputMethod == .telex || _config.inputMethod == .simpleTelex)
            && EnglishRestoreDetector.hasInvalidTelexSwPrefix(candidateWord)
        let isVietCollocation = Self.isVietnameseCollocation(candidateWord: candidateWord, lastCompletedWord: lastCompletedWord)
        var isKeyword = EnglishRestoreDetector.isEnglishKeyword(candidateWord) && !isVietCollocation
        var isRomaji = JapaneseRomajiDetector.shouldRestoreRomaji(candidateWord: candidateWord) && !isVietCollocation

        var isLearnedBypass = false
        if let learner = adaptiveLearner, learner.isEnabled {
            if learner.shouldBypassForImeFriction(word: candidateWord) {
                isKeyword = true
                isLearnedBypass = true
            } else if learner.shouldPreserveVietnameseForImeFriction(word: candidateWord) {
                isKeyword = false
                isRomaji = false
            }
        }

        if isLearnedBypass || (_config.autoCorrectEnglish && (
            isKeyword
            || EnglishRestoreDetector.hasInvalidMedialDoubleConsonant(candidateWord)
            || isTelexSwEnglish
            || isRomaji
        )) {
            isBypassed = true
            wordRawKeys.append(character)
            if hasPrecedingTechSep {
                let candidateRawPart = String(activeRawKeys) + String(character)
                activePreedit = candidateRawPart
                activeRawKeys = Array(candidateRawPart)
            } else {
                committedPrefix = ""
                activePreedit = rawWordString
                activeRawKeys = Array(rawWordString)
            }
            transformState = SyllableTransformState()
            let newDisplay = committedPrefix + activePreedit
            return MinimalDiff.calculate(previous: prevDisplay, next: newDisplay)
        }

        // 4. Syllable Splitting Check for Compound Words (e.g. HAIR + PHOFNG -> HẢI + PHÒNG)
        var didSplit = false
        if shouldSplitSyllable(currentDisplay: activePreedit, nextChar: character) {
            committedPrefix += activePreedit
            activePreedit = ""
            activeRawKeys.removeAll(keepingCapacity: true)
            transformState = SyllableTransformState()
            didSplit = true
        }

        // 4b. CamelCase / PascalCase / Mixed-Case Identifier Detection
        // If an uppercase letter is typed following a lowercase letter within the token,
        // invalidate transient Vietnamese transforms, restore raw keys, emit literally, and latch bypass.
        let prefixHasVowelOrForeignOnset = wordRawKeys.contains(where: { PhonotacticsMatrix.isVowelChar($0) })
            || EnglishRestoreDetector.hasInvalidOnsetCluster(String(wordRawKeys))
            || PhonotacticsMatrix.lookupFC(String(wordRawKeys).lowercased(), isComplete: false).isEmpty
        let isInternalUppercase = !didSplit
            && character.isUppercase
            && (wordRawKeys.last?.isLowercase == true)
            && prefixHasVowelOrForeignOnset

        if isInternalUppercase {
            isBypassed = true
            wordRawKeys.append(character)
            if hasPrecedingTechSep {
                let candidateRawPart = String(activeRawKeys) + String(character)
                activePreedit = candidateRawPart
                activeRawKeys = Array(candidateRawPart)
            } else {
                let rawWordString = String(wordRawKeys)
                committedPrefix = ""
                activePreedit = rawWordString
                activeRawKeys = Array(rawWordString)
            }
            transformState = SyllableTransformState()
            let newDisplay = committedPrefix + activePreedit
            return MinimalDiff.calculate(previous: prevDisplay, next: newDisplay)
        }

        let candidateRaw = String(activeRawKeys) + String(character)
        let lowerCandidateRaw = candidateRaw.lowercased()
        let fullCandidateRaw = (committedPrefix + candidateRaw).lowercased()

        let isCollidingExtensionMatch = hasPrecedingTechSep && EnglishRestoreDetector.isCollidingExtension(lowerCandidateRaw)

        // 5a. Colliding Extension Check (.or., .us, .es, .tw, .aw, .tar) - only bypass active extension
        if _config.autoCorrectEnglish && isCollidingExtensionMatch {
            isBypassed = true
            wordRawKeys.append(character)
            activePreedit = candidateRaw
            activeRawKeys = Array(candidateRaw)
            transformState = SyllableTransformState()
            let newDisplay = committedPrefix + activePreedit
            return MinimalDiff.calculate(previous: prevDisplay, next: newDisplay)
        }

        let isVietCollocationRaw = Self.isVietnameseCollocation(candidateWord: lowerCandidateRaw, lastCompletedWord: lastCompletedWord)
        let isVietCollocationFull = Self.isVietnameseCollocation(candidateWord: fullCandidateRaw, lastCompletedWord: lastCompletedWord)
        let isKeywordRaw = EnglishRestoreDetector.isEnglishKeyword(candidateRaw) && !isVietCollocationRaw
        let isKeywordFull = EnglishRestoreDetector.isEnglishKeyword(fullCandidateRaw) && !isVietCollocationFull

        let isCandidateRomaji = (JapaneseRomajiDetector.shouldRestoreRomaji(candidateWord: lowerCandidateRaw) && !isVietCollocationRaw)
            || (JapaneseRomajiDetector.shouldRestoreRomaji(candidateWord: fullCandidateRaw) && !isVietCollocationFull)

        let lowerActiveRaw = String(activeRawKeys).lowercased()
        let lowerChar = character.lowercased()
        let hasMidWordToneCluster = !wasBypassedBeforeStep2
            && (_config.inputMethod == .telex || _config.inputMethod == .simpleTelex)
            && !isVietCollocationFull
            && (
                (["misf", "disf", "misr", "disr"].contains(lowerActiveRaw) && "aeiou".contains(lowerChar))
                || ["perj", "perf", "parf", "forf", "satis"].contains(where: { lowerActiveRaw.hasPrefix($0) })
                || (lowerActiveRaw == "curf" && lowerChar == "e")
                || (lowerActiveRaw == "borsc" && lowerChar == "h")
                || (["ters", "cors", "gors", "mors"].contains(lowerActiveRaw) && "ea".contains(lowerChar))
                || (lowerActiveRaw == "tors" && lowerChar == "o")
            )

        let hasMidWordZAfterTone = (_config.inputMethod == .telex || _config.inputMethod == .simpleTelex)
            && activeRawKeys.last?.lowercased() == "z"
            && activeRawKeys.dropLast().contains(where: { "sfrxj".contains($0.lowercased()) })
            && character.isLetter

        // 5b. Known English Keyword & Romaji Check (Zero-Flicker Pre-Validation)
        var shouldPreserveInStep5b = false
        if let learner = adaptiveLearner, learner.isEnabled {
            if learner.shouldPreserveVietnameseForImeFriction(word: lowerCandidateRaw)
                || learner.shouldPreserveVietnameseForImeFriction(word: fullCandidateRaw)
                || learner.shouldPreserveVietnameseForImeFriction(word: candidateWord) {
                shouldPreserveInStep5b = true
            }
        }

        if !shouldPreserveInStep5b && _config.autoCorrectEnglish && (
            isKeywordRaw
            || isKeywordFull
            || EnglishRestoreDetector.hasInvalidMedialDoubleConsonant(fullCandidateRaw)
            || isCandidateRomaji
            || hasMidWordToneCluster
            || hasMidWordZAfterTone
        ) {
            isBypassed = true
            wordRawKeys.append(character)
            if hasPrecedingTechSep {
                activePreedit = candidateRaw
                activeRawKeys = Array(candidateRaw)
            } else {
                committedPrefix = ""
                activePreedit = rawWordString
                activeRawKeys = Array(rawWordString)
            }
            transformState = SyllableTransformState()
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
                if hasPrecedingTechSep {
                    activePreedit = candidateRaw
                    activeRawKeys = Array(candidateRaw)
                } else {
                    committedPrefix = ""
                    activePreedit = rawWordString
                    activeRawKeys = Array(rawWordString)
                }
                transformState = SyllableTransformState()
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

        // 8. Stop Coda Tone, Invalid Coda Cluster & Multi-Syllable / Phonotactic Validation on Result
        if _config.autoCorrectEnglish {
            if let parsed = Syllable.parse(from: targetActive) {
                let hasMedialConsonantInNucleus = !parsed.nucleus.allSatisfy { PhonotacticsMatrix.isVowelChar($0) }
                let lowerNuc = parsed.nucleus.lowercased()
                let transitionalNuclei: Set<String> = [
                    "ie", "uye", "ye", "uo", "uoi", "uou", "ưo", "ưoi", "ưou",
                    "uơ", "uơi", "uơu", "ieu", "yeu", "eu", "ue", "uay", "uu"
                ]
                let offGlidesForbiddingCoda: Set<String> = [
                    "ai", "ao", "au", "âu", "ay", "ây", "eo", "êu", "ia", "iêu", "iu",
                    "oai", "oao", "oay", "oeo", "oi", "ôi", "ơi", "ưa", "uây", "ui",
                    "ưi", "uôi", "ươi", "ươu", "ưu", "uya", "uyu", "yêu"
                ]
                let hasSplitPrefix = !committedPrefix.isEmpty && !hasPrecedingTechSep
                let isTransformed = hasSplitPrefix || (
                    (targetActive.lowercased() != candidateRaw.lowercased())
                    && targetActive.contains(where: { !$0.isASCII })
                )
                let lowerOnset = parsed.onset.lowercased()
                let isTransientQu = (lowerOnset == "q" && lowerNuc.hasPrefix("u"))
                let firstNuc = lowerNuc.first
                let invalidOaiOnsets: Set<String> = ["b", "m", "p", "ph", "v", "n", "g", "gh", "d", "r", "tr"]
                let invalidOeOnsets: Set<String> = ["b", "c", "d", "g", "gh", "m", "n", "p", "ph", "r", "s", "tr", "v"]
                let invalidOaOnsets: Set<String> = ["b", "g", "gh", "m", "n", "p", "ph", "r", "tr", "v"]
                let isValidVietnameseGoa = lowerOnset == "g"
                    && lowerNuc == "oa"
                    && parsed.coda.isEmpty
                    && parsed.tone == .acute
                    && (lowerCandidateRaw.hasPrefix("goa") || lowerCandidateRaw.hasPrefix("gosa"))
                let isValidVietnameseNoan = lowerOnset == "n"
                    && lowerNuc == "oa"
                    && (parsed.coda.isEmpty || parsed.coda.lowercased() == "n")
                    && parsed.tone == .tilde
                    && (lowerCandidateRaw.hasPrefix("noa") || lowerCandidateRaw.hasPrefix("noxa") || lowerCandidateRaw.hasPrefix("nora"))
                let wasUnlatchedOrToneOverride = wasUnlatchedInStep2
                    || (!wasBypassedBeforeStep2 && transformState.lastToneKey != nil && ("sfrxj".contains(lowerChar) || (lowerCandidateRaw.count >= 6 && "ghwmncptdiuoyae".contains(lowerChar))))
                let isInvalidKOrZOrthography = (lowerOnset == "k" && firstNuc != nil && !"ieêy".contains(firstNuc!) && !isVietCollocationFull && !wasUnlatchedOrToneOverride)
                    || (lowerOnset == "c" && firstNuc != nil && "ieêy".contains(firstNuc!))
                    || ((lowerOnset == "g" || lowerOnset == "ng") && firstNuc != nil && "eê".contains(firstNuc!) && !isVietCollocationFull && !(wasUnlatchedOrToneOverride && ["gese", "gefe", "gere", "gexe", "geje", "geso", "gefo", "gero", "gexo", "gejo", "gesu", "gefu", "geru", "gexu", "geju", "ngese", "ngefe", "ngere", "ngexe", "ngeje", "ngeso", "ngefo", "ngero", "ngexo", "ngejo", "ngesu", "ngefu", "ngeru", "ngexu", "ngeju"].contains(where: { lowerCandidateRaw.hasPrefix($0) })))
                    || (invalidOaiOnsets.contains(lowerOnset) && ["oai", "oao", "oay", "oeo"].contains(lowerNuc) && !isVietCollocationFull && !wasUnlatchedOrToneOverride)
                    || (invalidOeOnsets.contains(lowerOnset) && lowerNuc == "oe" && !isVietCollocationFull && !wasUnlatchedOrToneOverride)
                    || (invalidOaOnsets.contains(lowerOnset) && ["oa", "oă"].contains(lowerNuc) && !isValidVietnameseGoa && !isValidVietnameseNoan && !isVietCollocationFull && !wasUnlatchedOrToneOverride)
                    || (!lowerOnset.isEmpty && lowerOnset != "qu" && parsed.nucleus.count >= 2 && lowerNuc.hasPrefix("y") && !isVietCollocationFull)
                    || (lowerOnset == "p" && (parsed.tone != .none || lowerNuc.contains(where: { "ăơư".contains($0) })) && !isVietCollocationFull && !wasUnlatchedOrToneOverride)
                    || (lowerOnset == "z")
                let hasInvalidTransformedOnset = isTransformed
                    && !candidateState.isBypassed
                    && !lowerOnset.isEmpty
                    && !isTransientQu
                    && (PhonotacticsMatrix.lookupFC(lowerOnset, isComplete: false).isEmpty || isInvalidKOrZOrthography)
                let hasInvalidTransformedNucleus = isTransformed
                    && parsed.nucleus.count >= 2
                    && PhonotacticsMatrix.lookupVO(lowerNuc).isEmpty
                    && !transitionalNuclei.contains(lowerNuc)
                let hasIllegalOffGlideCoda = isTransformed
                    && !parsed.coda.isEmpty
                    && offGlidesForbiddingCoda.contains(lowerNuc)
                let hasInvalidTransformedCoda = isTransformed
                    && !candidateState.isBypassed
                    && !parsed.coda.isEmpty
                    && (!PhonotacticsMatrix.isValidCoda(parsed.coda)
                        || (lowerNuc == "y" && lowerOnset != "qu")
                        || (parsed.coda.lowercased() == "k" && lowerNuc != "ă"))

                if !PhonotacticsMatrix.isValidStopCodaTone(coda: parsed.coda, tone: parsed.tone)
                    || EnglishRestoreDetector.hasInvalidCodaCluster(parsed.coda)
                    || hasMedialConsonantInNucleus
                    || hasInvalidTransformedOnset
                    || hasInvalidTransformedNucleus
                    || hasIllegalOffGlideCoda
                    || hasInvalidTransformedCoda {
                    // Violation: restore entire token to raw English
                    isBypassed = true
                    wordRawKeys.append(character)
                    if hasPrecedingTechSep {
                        activePreedit = candidateRaw
                        activeRawKeys = Array(candidateRaw)
                    } else {
                        committedPrefix = ""
                        activePreedit = rawWordString
                        activeRawKeys = Array(rawWordString)
                    }
                    transformState = SyllableTransformState()
                    let newDisplay = committedPrefix + activePreedit
                    return MinimalDiff.calculate(previous: prevDisplay, next: newDisplay)
                }
            }
        }

        // 9. Commit Transformation
        activePreedit = targetActive
        transformState = candidateState
        if candidateState.isBypassed {
            isBypassed = true
            if candidateState.didUndoDiacritic {
                activeRawKeys = Array(targetActive)
                wordRawKeys = Array(committedPrefix + targetActive)
                transformState.didAbsorbBypassW = (character == "w" || character == "W")
            } else {
                wordRawKeys.append(character)
                activeRawKeys.append(character)
            }
        } else {
            wordRawKeys.append(character)
            activeRawKeys.append(character)
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
            if let applied = lastAppliedCorrection {
                if applied.boundaryChar == " " {
                    _ = spaceHistory.popLast()
                }
                adaptiveLearner?.demoteRule(trigger: applied.ruleTrigger, category: applied.category)
                lastAppliedCorrection = nil
                activePreedit = applied.originalWord
                committedPrefix = ""
                activeRawKeys = Array(applied.originalWord)
                wordRawKeys = Array(applied.originalWord)
                transformState = SyllableTransformState()
                isBypassed = true
                return true
            }

            return internalHandleBackspaceLocked()
        }
    }

    private func internalHandleBackspaceLocked() -> Bool {
        let prevDisplay = committedPrefix + activePreedit
        if !tokenDidBackspace && (!prevDisplay.isEmpty || !wordRawKeys.isEmpty) {
            preBackspaceSnapshot = PreBackspaceSnapshot(
                displayedText: prevDisplay,
                rawKeys: String(wordRawKeys),
                wasBypassed: isBypassed
            )
            tokenDidBackspace = true
        }

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
                    tokenDidBackspace = false
                    preBackspaceSnapshot = nil
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
                let (evalRemaining, evalState) = evaluateRaw(keys: activeRawKeys)
                if EnglishRestoreDetector.isEnglishKeyword(remainingWord)
                    || EnglishRestoreDetector.hasInvalidMedialDoubleConsonant(remainingWord)
                    || isSwEng
                    || JapaneseRomajiDetector.shouldRestoreRomaji(candidateWord: remainingWord)
                    || (String(activeRawKeys) == activePreedit && (evalState.isBypassed || evalRemaining != activePreedit)) {
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

    /// Handles backspace and returns a revert TextDelta if an automatic correction was self-healed.
    public func handleBackspaceWithRevertDelta() -> TextDelta? {
        lock.withLock {
            guard let applied = lastAppliedCorrection else {
                return nil
            }
            if applied.boundaryChar == " " {
                _ = spaceHistory.popLast()
            }
            adaptiveLearner?.demoteRule(trigger: applied.ruleTrigger, category: applied.category)
            lastAppliedCorrection = nil
            activePreedit = applied.originalWord
            committedPrefix = ""
            activeRawKeys = Array(applied.originalWord)
            wordRawKeys = Array(applied.originalWord)
            transformState = SyllableTransformState()
            isBypassed = true
            let fullPrevious = applied.correctedWord + String(applied.boundaryChar)
            return MinimalDiff.calculate(previous: fullPrevious, next: applied.originalWord)
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
                let isAllUpper = text.allSatisfy { !$0.isLetter || $0.isUppercase }
                switch detectedTone {
                case .acute: keys.append(isAllUpper ? "S" : "s")
                case .grave: keys.append(isAllUpper ? "F" : "f")
                case .hook:  keys.append(isAllUpper ? "R" : "r")
                case .tilde: keys.append(isAllUpper ? "X" : "x")
                case .dot:   keys.append(isAllUpper ? "J" : "j")
                case .none:  break
                }
            }
        }

        return keys
    }

    // MARK: - Reset
    public func reset() {
        lock.withLock {
            let prev = committedPrefix + activePreedit
            if tokenDidBackspace, let snapshot = preBackspaceSnapshot, !prev.isEmpty {
                adaptiveLearner?.recordCorrection(
                    rawKeysBeforeBackspace: snapshot.rawKeys,
                    displayedBeforeBackspace: snapshot.displayedText,
                    finalCommittedText: prev,
                    wasBypassedBeforeBackspace: snapshot.wasBypassed
                )
            }
            tokenDidBackspace = false
            preBackspaceSnapshot = nil
            lastAppliedCorrection = nil
            if !prev.isEmpty {
                lastCompletedWord = prev.lowercased()
            }
            spaceHistory.removeAll(keepingCapacity: true)
            internalReset()
        }
    }

    private static func matchCase(source: String, target: String) -> String {
        guard let first = source.first else { return target }
        if source.allSatisfy({ $0.isUppercase }) && source.count > 1 {
            return target.uppercased()
        } else if first.isUppercase {
            return target.prefix(1).uppercased() + target.dropFirst()
        } else if source.allSatisfy({ $0.isLowercase }) && (target.count == 1 || target.dropFirst().allSatisfy({ $0.isLowercase })) {
            return target.lowercased()
        } else {
            return target
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
        // Only split into a compound word if the current syllable already has a Vietnamese transformation
        guard currentDisplay != String(activeRawKeys) else { return false }
        guard !PhonotacticsMatrix.isVowelChar(nextChar) else { return false }
        guard let parsed = Syllable.parse(from: currentDisplay),
              !parsed.nucleus.isEmpty,
              parsed.nucleus.allSatisfy({ PhonotacticsMatrix.isVowelChar($0) }) else {
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

        // Do not split if the user is typing a foreign 'sh' digraph (e.g. kaisha, raishuu, hayashi)
        if activeRawKeys.last?.lowercased() == "s" && lowerNext == "h" {
            return false
        }

        // Do not split if the syllable started with standalone 'w' (e.g. 'wi...', 'wa...', 'wou...' in English words like 'with', 'wide', 'want', 'walk', 'would')
        if parsed.onset.isEmpty && activeRawKeys.first?.lowercased() == "w" {
            return false
        }

        let lastRawIsVowel = activeRawKeys.last.map { PhonotacticsMatrix.isVowelChar($0) } ?? false

        // Case 1: Nucleus is an off-glide (cannot take any coda)
        let offGlides: Set<String> = [
            "ai", "ao", "au", "âu", "ay", "ây", "eo", "êu", "ia", "iêu", "iu",
            "oai", "oao", "oay", "oeo", "oi", "ôi", "ơi", "ưa", "uây", "ui",
            "ưi", "uôi", "ươi", "ươu", "ưu", "uya", "uyu", "yêu"
        ]
        let lowerNuc = parsed.nucleus.lowercased()
        if offGlides.contains(lowerNuc) {
            // Do not split if a tone key was typed between the two vowels (e.g. 'n-a-r-u' in 'naruto', 'm-i-s-a' in 'misaki', 'a-s-o' in 'asoko')
            // or if multiple tone keys were typed in the syllable (e.g. 'r-e-f-o-r-m', 'r-e-s-o-r-t', 'd-e-f-o-r-m', 'd-e-f-r-o-s-t')
            let toneKeyCount = activeRawKeys.dropFirst().filter { "sfrxj".contains($0.lowercased()) }.count
            let lowerActiveRaw = String(activeRawKeys).lowercased()
            let isForeignSCluster = activeRawKeys.last?.lowercased() == "s" && "tkmplc".contains(lowerNext)
            if lowerActiveRaw == "air"
                || lowerActiveRaw == "uwa"
                || lowerActiveRaw.hasSuffix("ooi")
                || lowerActiveRaw.hasSuffix("owi")
                || isForeignSCluster
                || (parsed.tone != .none && (lastRawIsVowel || toneKeyCount >= 2)) {
                return false
            }
            return true
        }

        // Case 2: Syllable already has a valid coda, and nextChar is a valid onset that cannot extend the coda
        if !parsed.coda.isEmpty && PhonotacticsMatrix.isValidCoda(parsed.coda) {
            // Do not split if a non-adjacent vowel jumped across the coda (e.g. 't-a-n-a' in 'tanaka', 'a-n-a' in 'anata')
            // or if the last raw key was 's' or 'r' forming a foreign medial cluster (e.g. 'trans-' in 'transmission', 'emer-' in 'emerge')
            let lastKeyLower = activeRawKeys.last?.lowercased()
            let lowerActiveRaw = String(activeRawKeys).lowercased()
            let hasSClusterSuffix = lowerActiveRaw.hasSuffix("st") || lowerActiveRaw.hasSuffix("sc") || lowerActiveRaw.hasSuffix("sp")
            if lastRawIsVowel || lastKeyLower == "s" || lastKeyLower == "r" || hasSClusterSuffix || (lowerNuc == "ua" && parsed.onset.lowercased() != "q") {
                return false
            }
            let candidateCoda = parsed.coda + String(nextChar)
            if EnglishRestoreDetector.hasInvalidCodaCluster(candidateCoda.lowercased()) {
                return false
            }
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
        state.didUndoDiacritic = false

        // MARK: Full Telex Standalone & Shorthand 'w'
        if method == .telex && (inputChar == "w" || inputChar == "W") {
            if previousDisplay.isEmpty {
                state.isStandaloneW = true
                state.lastDiacriticKey = inputChar
                let target = inputChar.isUppercase ? "Ư" : "ư"
                return (target, true)
            } else if !previousDisplay.contains(where: { PhonotacticsMatrix.isVowelChar($0) })
                || TonePlacement.stripTone(from: previousDisplay).lowercased() == "gi" {
                let strippedPrev = TonePlacement.stripTone(from: previousDisplay)
                let lowerOnset = strippedPrev.lowercased()
                let validOnsets: Set<String> = [
                    "b", "c", "ch", "d", "đ", "g", "gh", "gi", "h", "k", "kh",
                    "l", "m", "n", "ng", "ngh", "nh", "p", "ph", "r", "s",
                    "t", "th", "tr", "v", "x"
                ]
                if validOnsets.contains(lowerOnset) {
                    state.isShorthandW = true
                    state.lastDiacriticKey = inputChar
                    let isUpper = inputChar.isUppercase || (strippedPrev.count > 1 && strippedPrev.allSatisfy { $0.isUppercase })
                    let targetVowel = isUpper ? "Ư" : "ư"
                    var existingTone: Tone = .none
                    for ch in previousDisplay {
                        let (_, t) = TonePlacement.removeTone(from: ch)
                        if t != .none { existingTone = t; break }
                    }
                    if existingTone != .none {
                        let composed = TonePlacement.composeSyllable(
                            vowels: [Character(targetVowel)],
                            onset: strippedPrev,
                            coda: "",
                            tone: existingTone,
                            style: toneStyle
                        )
                        return (composed, true)
                    }
                    return (strippedPrev + targetVowel, true)
                }
            }
        }

        // Standalone or Shorthand 'w' double-press undo: "w" + "w" -> "w", "sw" + "w" -> "sw"
        if (state.isStandaloneW || state.isShorthandW) && (inputChar == "w" || inputChar == "W") && escape {
            let wasStandalone = state.isStandaloneW
            state.isStandaloneW = false
            state.isShorthandW = false
            state.lastDiacriticKey = nil
            state.isBypassed = true
            state.didUndoDiacritic = true
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
        if method == .telex, !_config.autoCorrectEnglish, let _ = toneRes.tone {
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
        if let lastRaw = rawHistory.last,
           lastRaw.lowercased() == inputChar.lowercased(),
           ((previousDisplay.lowercased().hasSuffix("n") && inputChar.lowercased() == "n")
            || (previousDisplay.lowercased().hasSuffix("c") && inputChar.lowercased() == "c")) {
            return (previousDisplay, true)
        }

        // MARK: Delayed 'd -> đ' ('d' in Telex, '9' in VNI)
        let isDelayedD = (method == .telex || method == .simpleTelex) && (inputChar == "d" || inputChar == "D")
        let isDelayedVniD = (method == .vni) && (inputChar == "9")
        if isDelayedD || isDelayedVniD {
            if let parsed = Syllable.parse(from: previousDisplay),
               !parsed.nucleus.isEmpty,
               parsed.nucleus.allSatisfy({ PhonotacticsMatrix.isVowelChar($0) }),
               (parsed.coda.isEmpty || PhonotacticsMatrix.isValidCoda(parsed.coda)),
               (parsed.onset.lowercased() == "d"
                || (parsed.onset.lowercased() == "đ"
                    && rawHistory.filter({ $0.lowercased() == "d" }).count <= 1
                    && !(escape && state.lastDiacriticKey == inputChar))) {
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
            if let parsed = Syllable.parse(from: previousDisplay),
               !parsed.nucleus.isEmpty,
               parsed.nucleus.allSatisfy({ PhonotacticsMatrix.isVowelChar($0) }),
               (parsed.coda.isEmpty || PhonotacticsMatrix.isValidCoda(parsed.coda)) {
                let lowerNuc = parsed.nucleus.lowercased()
                let isUpperNuc = parsed.nucleus.allSatisfy { $0.isUppercase }
                var newNucleus: String? = nil

                if isHornKey {
                    if lowerNuc == "uo" && parsed.coda.isEmpty && ["th", "h", "kh"].contains(parsed.onset.lowercased()) {
                        newNucleus = isUpperNuc ? "UƠ" : "uơ"
                    } else if lowerNuc == "uo" || lowerNuc == "ưo" {
                        newNucleus = isUpperNuc ? "ƯƠ" : "ươ"
                    } else if lowerNuc == "uoi" || lowerNuc == "ưoi" || lowerNuc == "uơi" {
                        newNucleus = isUpperNuc ? "ƯƠI" : "ươi"
                    } else if lowerNuc == "uou" || lowerNuc == "ưou" || lowerNuc == "uơu" {
                        newNucleus = isUpperNuc ? "ƯƠU" : "ươu"
                    } else if (lowerNuc == "ươ" || lowerNuc == "uơ" || lowerNuc == "ươi" || lowerNuc == "ươu" || lowerNuc == "ưu")
                        && rawHistory.filter({ $0.lowercased() == "w" }).count <= 1
                        && !(escape && state.lastDiacriticKey == inputChar) {
                        newNucleus = isUpperNuc ? lowerNuc.uppercased() : lowerNuc
                    } else if lowerNuc == "uu" {
                        newNucleus = isUpperNuc ? "ƯU" : "ưu"
                    } else if lowerNuc == "ua" {
                        newNucleus = isUpperNuc ? "ƯA" : "ưa"
                    } else if lowerNuc == "oi" || (lowerNuc == "ôi" && rawHistory.filter({ $0.lowercased() == "w" }).isEmpty) {
                        newNucleus = isUpperNuc ? "ƠI" : "ơi"
                    } else if lowerNuc == "ui" {
                        newNucleus = isUpperNuc ? "ƯI" : "ưi"
                    } else if lowerNuc == "o" || (lowerNuc == "ô" && rawHistory.filter({ $0.lowercased() == "w" }).isEmpty) {
                        newNucleus = isUpperNuc ? "Ơ" : "ơ"
                    } else if lowerNuc == "u" {
                        newNucleus = isUpperNuc ? "Ư" : "ư"
                    }
                }

                if newNucleus == nil && isBreveKey {
                    if (lowerNuc == "a" && (!parsed.coda.isEmpty || method == .vni))
                        || (lowerNuc == "â" && rawHistory.filter({ $0.lowercased() == "w" }).isEmpty) {
                        newNucleus = isUpperNuc ? "Ă" : "ă"
                    } else if lowerNuc == "oa" && (!parsed.coda.isEmpty || method == .vni) {
                        newNucleus = isUpperNuc ? "OĂ" : "oă"
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
            if let parsed = Syllable.parse(from: previousDisplay),
               !parsed.nucleus.isEmpty,
               parsed.nucleus.allSatisfy({ PhonotacticsMatrix.isVowelChar($0) }),
               (parsed.coda.isEmpty || PhonotacticsMatrix.isValidCoda(parsed.coda)) {
                let lowerNuc = parsed.nucleus.lowercased()
                let isUpperNuc = parsed.nucleus.allSatisfy { $0.isUppercase }
                var newNucleus: String? = nil

                let checkO = (isTelexCircumflex && lowerInput == "o") || isVniCircumflex
                let checkE = (isTelexCircumflex && lowerInput == "e") || isVniCircumflex
                let checkA = (isTelexCircumflex && lowerInput == "a") || isVniCircumflex

                if checkO {
                    if lowerNuc == "uo" || (lowerNuc == "ươ" && rawHistory.filter({ $0.lowercased() == "w" }).isEmpty) {
                        newNucleus = isUpperNuc ? "UÔ" : "uô"
                    } else if lowerNuc == "uoi" {
                        newNucleus = isUpperNuc ? "UÔI" : "uôi"
                    } else if lowerNuc == "oi" {
                        newNucleus = isUpperNuc ? "ÔI" : "ôi"
                    } else if (lowerNuc == "o" || (lowerNuc == "ơ" && rawHistory.filter({ $0.lowercased() == "o" }).count <= 1)) && !parsed.coda.isEmpty {
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
                    } else if lowerNuc == "ieu" {
                        newNucleus = isUpperNuc ? "IÊU" : "iêu"
                    } else if lowerNuc == "yeu" {
                        newNucleus = isUpperNuc ? "YÊU" : "yêu"
                    } else if lowerNuc == "eu" {
                        newNucleus = isUpperNuc ? "ÊU" : "êu"
                    } else if lowerNuc == "ue" {
                        newNucleus = isUpperNuc ? "UÊ" : "uê"
                    } else if (lowerNuc == "iê" || lowerNuc == "uyê" || lowerNuc == "yê")
                        && rawHistory.filter({ $0.lowercased() == "e" }).count <= 1
                        && !(escape && state.lastDiacriticKey == inputChar) {
                        newNucleus = isUpperNuc ? lowerNuc.uppercased() : lowerNuc
                    } else if lowerNuc == "e" && !parsed.coda.isEmpty {
                        newNucleus = isUpperNuc ? "Ê" : "ê"
                    }
                }

                if newNucleus == nil && checkA {
                    if lowerNuc == "ua" {
                        newNucleus = isUpperNuc ? "UÂ" : "uâ"
                    } else if lowerNuc == "uay" {
                        newNucleus = isUpperNuc ? "UÂY" : "uây"
                    } else if lowerNuc == "ay" {
                        newNucleus = isUpperNuc ? "ÂY" : "ây"
                    } else if lowerNuc == "au" {
                        newNucleus = isUpperNuc ? "ÂU" : "âu"
                    } else if (lowerNuc == "a" || (lowerNuc == "ă" && rawHistory.filter({ $0.lowercased() == "a" }).count <= 1)) && !parsed.coda.isEmpty {
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
            if var parsed = Syllable.parse(from: previousDisplay),
               !parsed.nucleus.isEmpty,
               parsed.nucleus.allSatisfy({ PhonotacticsMatrix.isVowelChar($0) }) {
                let isCodaValid = parsed.coda.isEmpty || PhonotacticsMatrix.isValidCoda(parsed.coda)
                if isCodaValid {
                    // Special case for 'dadj' -> 'đạt'
                    if rawHistory.map({ String($0) }).joined().lowercased() == "dad" && (inputChar == "j" || inputChar == "J") {
                        state.lastToneKey = inputChar
                        state.lastDiacriticKey = nil
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
                        state.lastDiacriticKey = nil
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
                    state.lastDiacriticKey = nil
                    let tuned = applyTone(tone, to: previousDisplay, style: toneStyle)
                    return (tuned, true)
                }
            }
        }

        // MARK: Double-Press Diacritic Undo (e.g. 'â' + 'a' -> 'aa', 'đ' + 'd' -> 'dd', 'ươ' + 'w' -> 'uow')
        if escape, state.lastDiacriticKey == inputChar {
            if (inputChar == "w" || inputChar == "W" || inputChar == "7"),
               previousDisplay.lowercased().hasSuffix("ươ"),
               rawHistory.filter({ $0.lowercased() == "w" || $0 == "7" }).count <= 1 {
                state.lastDiacriticKey = nil
                state.isBypassed = true
                state.didUndoDiacritic = true
                let chars = Array(previousDisplay)
                let uChar = chars[chars.count - 2].isUppercase ? "U" : "u"
                let oChar = chars[chars.count - 1].isUppercase ? "O" : "o"
                let prefix = String(chars.dropLast(2))
                return (prefix + uChar + oChar + String(inputChar), true)
            }
            if let undone = tryUndoDiacritic(lastChar: previousDisplay.last, trigger: inputChar, method: method) {
                state.lastDiacriticKey = nil
                state.isBypassed = true
                state.didUndoDiacritic = true
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
        if let lastChar = previousDisplay.last,
           (Syllable.parse(from: previousDisplay)?.nucleus.allSatisfy({ PhonotacticsMatrix.isVowelChar($0) }) ?? true) {
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
                if lowerNuc == "ưoi" || lowerNuc == "uơi" {
                    parsed.nucleus = isUpperNuc ? "ƯƠI" : "ươi"
                } else if lowerNuc == "ưou" || lowerNuc == "uơu" {
                    parsed.nucleus = isUpperNuc ? "ƯƠU" : "ươu"
                } else if lowerNuc == "ơa" {
                    parsed.nucleus = isUpperNuc ? "OĂ" : "oă"
                }
                let transitionalNuclei: Set<String> = [
                    "ie", "uye", "ye", "uo", "uoi", "uou", "ưo", "ưoi", "ưou",
                    "uơ", "uơi", "uơu", "ieu", "yeu", "eu", "ue", "uay", "uu"
                ]
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

        // MARK: Auto-complete 'ưo'/'uơ'/'ơa' + off-glide or coda
        do {
            let candidateDisplay = previousDisplay + String(inputChar)
            if var parsed = Syllable.parse(from: candidateDisplay) {
                let lowerNuc = parsed.nucleus.lowercased()
                let isUpperNuc = parsed.nucleus.allSatisfy { $0.isUppercase }
                var didNormalize = false
                if (lowerNuc == "ưoi" || lowerNuc == "uơi") && parsed.coda.isEmpty {
                    parsed.nucleus = isUpperNuc ? "ƯƠI" : "ươi"
                    didNormalize = true
                } else if (lowerNuc == "ưou" || lowerNuc == "uơu") && parsed.coda.isEmpty {
                    parsed.nucleus = isUpperNuc ? "ƯƠU" : "ươu"
                    didNormalize = true
                } else if lowerNuc == "ơa" && parsed.coda.isEmpty {
                    parsed.nucleus = isUpperNuc ? "OĂ" : "oă"
                    didNormalize = true
                } else if (lowerNuc == "ưo" || lowerNuc == "uơ") && !parsed.coda.isEmpty && PhonotacticsMatrix.isValidCoda(parsed.coda) {
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
                } else if lowerNuc == "ưo" || lowerNuc == "uơ" {
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
            } else if !parsed.coda.isEmpty && (lowerNuc == "ưo" || lowerNuc == "uơ") {
                parsed.nucleus = isUpperNuc ? "ƯƠ" : "ươ"
            } else if parsed.coda.isEmpty && (lowerNuc == "ưoi" || lowerNuc == "uơi") {
                parsed.nucleus = isUpperNuc ? "ƯƠI" : "ươi"
            } else if parsed.coda.isEmpty && (lowerNuc == "ưou" || lowerNuc == "uơu") {
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

    private static let vietnameseCollocationPrefixes: [String: Set<String>] = [
        "own": ["cảm", "cám", "biết", "nhớ", "mang", "đền", "trả", "tạ", "vô", "bội", "hàm", "chịu", "báo", "ghi", "làm", "nhờ", "đội", "ban", "thấy", "hơi", "rất", "quá", "cũng", "đang", "bị", "nổi", "ngán", "sợ", "phát", "lạnh"],
        "owns": ["thấy", "hơi", "rất", "quá", "cũng", "đang", "bị", "nổi", "ngán", "sợ", "phát", "lạnh"],
        "chair": ["bàn", "cây", "lược", "máy", "đầu", "không", "chưa", "đang", "vừa", "mới", "đi", "lấy", "dùng", "mua", "cầm", "ngồi", "đứng", "phải", "cần", "nên", "hãy", "để"],
        "lair": ["nói", "kêu", "than", "khóc", "cứ", "đang", "mãi", "lải"],
        "lawn": ["con", "cây", "ống", "bánh", "sơn", "kem", "đá", "bi", "trục", "đang", "cứ", "bị", "ngã", "té", "nằm", "bò", "quay", "xoay", "lăn"],
        "manx": ["thỏa", "thoả", "viên", "bất", "tự", "ngạo", "mãn", "đã", "sắp", "chưa"],
        "sans": ["giun", "con", "bệnh", "nhiễm", "tẩy", "thuốc", "trứng", "ấu", "dây", "lá", "gạo"],
        "root": ["cà", "củ", "dốt", "rốt", "đến", "sau"],
        "roots": ["cà", "củ", "dốt", "rốt", "đến", "sau"],
        "loom": ["đốm", "vết", "chấm", "da", "nắng", "lốm"],
        "looms": ["đốm", "vết", "chấm", "da", "nắng", "lốm"],
        "the": ["có", "không", "chẳng", "chưa", "cụ", "tập", "cơ", "toàn", "chủ", "vật", "bản", "khả", "thực", "đoàn", "nhập", "giải", "biến", "hợp", "quần", "cá", "đại", "như", "vậy", "rứa", "tình", "xu", "ưu", "vị", "tư", "lợi", "thất", "yếu", "thay", "cứu", "trần", "hậu", "tiền", "tận", "khí", "uy"],
        "there": ["có", "không", "chẳng", "chưa", "cụ", "tập", "cơ", "toàn", "chủ", "vật", "bản", "khả", "thực", "đoàn", "nhập", "giải", "biến", "hợp", "quần", "cá", "đại"],
        "these": ["như", "vậy", "rứa", "thực", "tình", "xu", "ưu", "vị", "tư", "lợi", "thất", "yếu", "thay", "cứu", "trần", "hậu", "tiền", "tận", "khí", "uy"],
        "aura": ["làm", "chạy", "nói", "ăn", "viết", "gõ", "tính", "hơi", "quá", "rất", "cực", "lái"],
        "def": ["ngôi", "chùa", "miếu", "thờ", "bắt", "phải", "chịu", "bồi"],
        "defend": ["ngôi", "chùa", "miếu", "thờ", "bắt", "phải", "chịu", "bồi"],
        "reset": ["con", "loài"],
        "toe": ["bắn", "tung", "văng", "nổ", "phun", "cười", "sáng", "lửa", "máu", "nước", "tia"],
        "toes": ["bắn", "tung", "văng", "nổ", "phun", "cười", "sáng", "lửa", "máu", "nước", "tia"],
        "hoe": ["đỏ", "vàng"],
        "hoes": ["đỏ", "vàng"],
        "suwa": ["say", "gỗ", "cây", "hoa", "dây", "mùa", "xưa"],
        "nuwa": ["củ", "bột", "cây", "canh", "rau"],
        "buwa": ["ăn", "no", "chán", "cơm"],
        "sura": ["chó", "tiếng", "cứ", "đang", "hay"],
        "rura": ["nguyền", "lời", "chửi", "trù"],
        "giro": ["cái", "chiếc", "làn", "xách", "đựng", "mua", "đan"],
        "gire": ["cái", "tấm", "miếng", "khăn", "cuộn"],
        "gise": ["bông", "lúa", "con", "hạt"],
        "osoi": ["nước", "túi", "vỡ", "rỉ", "cạn", "đa", "thiểu", "dịch", "gối"],
        "noroi": ["trôi", "chìm", "nóng", "không", "chịu", "sôi", "làm", "ăn"],
        "soroi": ["ăn", "muối", "cải", "dưa", "cà"],
        "down": ["hoa", "lay", "củ", "bó", "cành", "trồng", "cắm", "rau", "cây", "hái", "nộm", "xào", "canh", "lá", "ngọn"],
        "downs": ["rau", "cây", "hái", "nộm", "xào", "canh", "lá", "ngọn"],
        "town": ["cơn", "lớn", "hớn", "tơn", "chạy", "nhảy", "cười", "đi", "mừng", "vui"],
        "towns": ["lớn", "tơn", "chạy", "nhảy", "cười", "đi", "mừng", "vui"],
        "vary": ["đánh", "cạo", "tróc", "lớp", "cá", "vẩy", "bóc", "miếng", "vảy"],
        "barn": ["cơ", "văn", "phiên", "kịch", "biên", "xuất", "nguyên", "nhân", "căn", "tư", "nhật", "dân", "buôn", "trưởng", "một", "hai", "ba", "vài", "mấy", "các", "những", "mỗi", "từng", "in", "sao", "chép", "gửi", "lưu", "nộp"],
        "tarn": ["đi", "dạo", "keo", "quạt", "đế", "tấm", "bộ", "ống", "hệ", "thống", "viết", "chuyện", "ngồi", "nói", "dân", "phải", "chạy", "nằm", "sống", "phát", "phân", "tiêu", "phách"],
        "burn": ["chân", "tay", "sợ", "mệt", "run", "đói", "lạnh", "rụng", "rời", "mềm", "yếu", "keo", "kiệt", "tính", "rất", "hơi", "quá", "cực", "lão", "thói"],
        "turn": ["toán", "tính", "nhặt", "vặt", "li", "sống", "người", "rất", "hơi", "quá", "cực", "chuyện", "việc", "thứ", "cách", "kiểu", "đầu", "óc", "làm", "nghĩ"],
        "born": ["keo", "kiệt", "tính", "rất", "hơi", "quá", "cực", "đồ", "người", "lão", "kẻ", "sống", "ăn", "tiêu", "xài", "thói"],
        "corn": ["nhỏ", "bé", "ít", "chút", "tí", "tẹo"],
        "dorm": ["hàng", "đồ", "thuốc", "rượu", "xe", "máy", "pin", "sạc", "cáp", "tai", "loa", "kính", "giày", "túi", "áo", "quần", "mỹ", "phẩm", "vàng", "bạc", "tiền", "bằng", "giấy", "tem", "rất", "hơi", "quá", "cực", "siêu", "loại", "thứ", "mua", "bán", "dùng", "xài", "gặp", "phải", "toàn"],
        "berm": ["nói", "miệng", "môi", "mồm", "hót", "khéo", "hay", "chuyên", "tranh", "lanh", "nhanh", "chanh", "đồ", "con", "thứ"],
        "hero": ["vùng", "nơi", "chốn", "quê", "xóm", "đường", "rất", "khá", "hơi", "quá", "vắng", "chết", "sắp", "bán", "khứa", "lương", "ví"],
        "nero": ["mọi", "khắp", "trên", "các", "những", "muôn", "ngàn", "trăm", "tám", "bốn", "cùng", "hẻm", "ngõ", "vạn", "mấy"],
        "keso": ["cái", "cây", "chiếc", "dùng", "lấy", "mua", "cầm", "cắt", "búa", "lôi", "dây", "khóa", "co", "níu", "chèo", "bị", "được", "đang", "cùng"],
        "meso": ["mặt", "mồm", "miệng", "bị", "hơi", "rất", "quá", "tròn", "móp", "dạng", "cười", "khóc", "tiếng"],
        "beso": ["thịt", "cá", "sữa", "kem", "bơ", "chất", "axit", "bụng", "mặt", "người", "con", "hơi", "rất", "quá", "mập", "bổ", "ngậy", "thơm", "bùi", "béo"],
        "heso": ["hoa", "lá", "cây", "cỏ", "rau", "quả", "bị", "đang", "đã", "sắp", "khô", "tàn", "úa", "vàng", "buồn", "sầu", "gan", "cười"],
        "teso": ["tí", "chút", "tẹo", "nhỏ", "bé"],
        "neso": ["dây", "cọc", "chằng", "buộc", "giữ", "neo"],
        "sasu": ["thứ", "số", "tháng", "lớp", "quận", "buổi", "ngày", "mùng", "mồng", "năm", "mười", "mươi", "hơn", "khoảng", "gần", "được", "có", "cả", "chừng", "độ", "tầm", "lên", "tuổi", "cấp", "bậc", "tầng", "phòng"],
        "basu": ["quý", "kho", "châu", "của", "vật", "bảo", "ngọc", "không", "chẳng", "rất", "cực", "kỳ", "cùng"],
        "nasu": ["ẩn", "trú", "nương", "lẩn", "chỗ", "nơi"],
        "tasu": ["gỗ", "cây", "sến", "cột", "rừng"],
        "turi": ["buồn", "thân", "nhục", "hổ", "phận", "lòng", "ngùi", "rất", "hơi", "quá", "thấy"],
        "muri": ["thương", "cảm", "động", "chạnh", "rất", "hơi", "thấy", "lòng"],
        "ruri": ["may", "xui", "gặp", "vận", "điều", "chuyện", "số", "đen"],
        "huri": ["hắt", "bệnh", "trại", "người", "ghẻ", "cùi"],
        "suri": ["viên", "thuốc", "nước", "bọt", "tăm", "sôi", "ăn", "bánh", "món", "nổi", "mẩn"],
        "rari": ["mưa", "nằm", "mọc", "bố", "hiện", "cư", "rào", "trải"],
        "saso": ["chim", "con", "thổi", "tiếng", "cây", "ống", "khúc", "đàn", "lời", "văn", "chữ", "ăn", "nấu", "bún"],
        "biru": ["dè", "bai", "bỉ", "bị", "hay", "đừng", "trề", "cười", "mặt"],
        "biju": ["bận", "bịn", "vướng", "rịn", "rất", "đang", "luôn", "quá", "khá", "hơi", "bịu"],
        "niju": ["nũng", "bịn", "nhẽo", "hay", "thích", "gái", "bé", "cứ", "đang", "giọng", "nịu"],
        "riju": ["rầu", "buồn", "mệt", "êm", "ngọt", "mặt", "rũ", "nhàu", "rịu"],
        "risu": ["líu", "róc", "rộn", "quấn", "vướng", "bận", "kêu", "ríu"],
        "nisu": ["bám", "kéo", "giữ", "cố", "với", "tay", "đừng", "không", "chẳng", "níu"],
        "gosa": ["bà", "phụ", "người", "cảnh", "ở", "chồng", "vợ", "mẹ", "chị", "cô", "dì", "thím", "bác", "mợ"],
        "tosa": ["chạy", "tản", "bay", "bắn", "văng", "vỡ", "bung", "nổ", "tung"],
        "lora": ["tắm", "xõa", "trần", "thân"],
        "bura": ["vây", "giăng", "lưới", "bị", "đang"],
        "tura": ["tua", "mọc", "đâm", "nhọn", "xù", "gai", "ria", "chạy", "kéo"],
        "kere": ["kể", "chuyện", "nghe", "bất", "đáng", "vô", "không", "chẳng", "chưa"],
        "bere": ["bơi", "xây", "dâu", "bãi", "bốn", "biển", "vỡ", "nước", "cá", "bể"],
        "nere": ["kính", "trọng", "nể", "vì", "vị", "cả", "kiêng", "sợ", "rất", "khá", "hơi"],
        "rere": ["con", "chàng", "anh", "em", "làm", "dâu", "nhà", "kén", "chọn"],
        "horo": ["con", "loài", "chuồng", "rừng", "xấu", "thẹn", "tướng", "mãnh", "cọp", "hang", "hổ"],
        "toro": ["chim", "ong", "kiến", "tôm", "cúng", "giỗ", "tiên", "dân", "phố", "trưởng", "hợp", "chức", "cái", "làm", "xây", "vỡ", "tổ"],
        "soro": ["cuốn", "quyển", "sách", "ghi", "mở", "khóa", "cửa", "sổ", "mũi", "cúm", "vào", "lên"],
        "noro": ["cháy", "bùng", "phát", "bom", "đạn", "pháo", "lốp", "bánh", "bỏng", "ngô", "súng", "tiếng", "vụ", "nổ"],
        "moro": ["phẫu", "ca", "bàn", "phòng", "dao", "bác", "mổ", "xẻ", "gà", "chim", "đập", "lợn"],
        "boro": ["bồi", "thuốc", "món", "tẩm", "rất", "rìu", "củi", "chẻ", "đập", "nhào"],
        "hofo": ["mặt", "bờ", "nước", "đáy", "lòng", "ao", "sông", "tây", "gươm", "xuân", "sen", "đồng"],
        "bofo": ["chim", "câu", "kết", "cặp", "người", "cây", "hòn", "bồ"],
        "tese": ["kinh", "quốc", "thực", "tinh", "y", "cứu", "tử", "cúng", "lễ", "tế"],
        "kese": ["thiết", "thống", "sinh", "mưu", "hiến", "thừa", "nhiệt", "áp", "ẩm", "liền", "tiếp", "bản", "kế"],
        "bese": ["mẹ", "bà", "ẵm", "bồng", "lễ", "được", "đang", "cấm", "bế"],
        "nefe": ["nặng", "thợ", "nghề", "không", "chẳng", "quản", "nề"],
        "hefe": ["không", "chẳng", "chưa", "chú", "anh", "trò", "làm", "diễn", "hề"],
        "tefe": ["chỉnh", "tề"],
        "befe": ["bộn", "bốn", "mọi", "trăm", "đôi", "hai", "nặng", "bề"],
        "kefe": ["cận", "liền", "gần", "sát", "vai", "kề"],
        "teje": ["tiền", "tồi", "quá", "rất", "hơi", "khá", "cực", "chơi", "làm", "xấu", "tệ"],
        "heje": ["thế", "quan", "liên", "phả", "vô", "hữu", "ngân", "thái", "hệ"],
        "keje": ["mặc", "bỏ", "cái", "chiếc", "ngăn", "giá", "tủ", "lên", "trên", "kệ"],
        "hoso": ["cái", "miệng", "đào", "sụp", "xuống", "lấp", "rơi", "hố"],
        "toso": ["yếu", "nguyên", "nhân", "khởi", "truy", "bão", "giông", "sắc", "độc", "kháng", "tố"],
        "soso": ["con", "chữ", "đếm", "mã", "biển", "cây", "tần", "hàm", "tham", "biến", "hệ", "chỉ", "điểm", "doanh", "dân", "sĩ", "tổng", "đa", "thiểu", "vô", "một", "mấy", "vài", "số"],
        "rofo": ["điên", "khùng", "chó", "cơn", "hóa", "phát", "rồ"],
        "mofo": ["nấm", "ngôi", "mả", "đổ", "vã", "ra", "mồ"],
        "tofo": ["ngây", "gà", "khờ", "tồ"],
        "sofo": ["béo", "to", "chim", "sồ"],
        "hojo": ["bảo", "cứu", "ủng", "căn", "biện", "làm", "mua", "nhờ", "cầm", "giữ", "xem", "hộ"],
        "bojo": ["đi", "chạy", "cán", "toàn", "lạc", "nội", "cục", "tiến", "nhượng", "đồng", "sơ", "chi", "đảng", "một", "hai", "ba", "vài", "mấy", "bộ"],
        "nojo": ["phẫn", "thịnh", "giận", "cuồng", "hỉ", "nộ"],
        "goxo": ["cây", "khúc", "tấm", "miếng", "bàn", "ghế", "nhà", "cửa", "sàn", "tủ", "thùng", "bằng", "đồ", "thợ", "xưởng", "rừng", "chặt", "xẻ", "gỗ"],
        "sana": ["ra", "trên", "ngoài", "giữa", "quét", "mặt", "góc", "cuối", "vào", "sân"],
        "hana": ["rất", "vinh", "hân"],
        "hama": ["bị", "hơi", "đồ", "nồi", "máy", "lò", "hâm"],
        "sama": ["nhân", "củ", "hồng", "trà", "rượu", "nước", "hầm", "mứt", "kẹo", "cao", "sâm"],
        "hono": ["kết", "đính", "cầu", "ly", "li", "tân", "nụ", "hoàng", "tái", "ngoại", "hôn"],
        "mono": ["bộ", "chuyên", "thủ", "nhập", "hậu", "các", "mấy", "nhiều", "môn"],
        "homo": ["chiều", "buổi", "đêm", "sớm", "mấy", "vài", "những", "cả", "suốt", "từ", "đến", "hôm"],
        "roro": ["cái", "chiếc", "đan", "đựng", "một", "vài", "mấy", "rổ"],
        "roxo": ["mặt", "bị", "nổi", "lỗ", "vết", "sẹo", "rỗ"],
        "doxo": ["dụ", "khuyên", "vỗ", "nịnh", "dỗ"],
        "hoxo": ["tương", "cứu", "hỗ"],
        "noxo": ["sự", "nhiều", "mọi", "luôn", "nỗ"],
        "neje": ["câu", "chấp", "không", "chẳng", "nệ"],
        "reje": ["trễ", "bụng", "mặt", "xệ", "rệ"],
        "rero": ["mảnh", "vùng", "cắt", "miếng", "rẻo"],
        "misu": ["bấu", "níu", "míu"],
        "chese": ["hạn", "cơ", "thể", "pha", "bào", "điều", "sơ", "tinh", "tái", "tự", "ức", "khống", "kiềm", "cưỡng", "quy", "biên", "chuyên", "áp", "độc", "chế"],
        "dese": ["con", "tiếng", "đá", "bắt", "hang", "chọi", "nuôi", "dế"],
        "rese": ["cái", "chiếc", "đan", "lót", "rổ", "rế"],
        "mese": ["bà", "các", "mế"],
        "tere": ["chúa", "đồ", "mổ", "đại", "tể"],
        "dere": ["khinh", "dể"],
        "beje": ["hạ", "cái", "chân", "đài", "lên", "trên", "tượng", "bệ"],
        "seje": ["chảy", "bụng", "má", "mặt", "xệ", "sệ"],
        "cheje": ["chễm", "trễ", "chệ"],
        "defe": ["dầm", "ướt", "dề"],
        "refe": ["lề", "chậm", "kéo", "rề"],
        "sefe": ["lợn", "heo", "béo", "bụng", "xề", "sề"],
        "mefe": ["cái", "chiếc", "lòng", "mề"],
        "sojo": ["đồ", "kết", "lộ", "sộ"],
        "tojo": ["kho", "cái", "chiếc", "nồi", "tộ"],
        "dofo": ["ngây", "khờ", "điên", "dại", "dồ"],
        "moso": ["cái", "chân", "đầu", "xây", "mố"],
        "misa": ["cây", "nước", "ép", "bã", "mật", "ngọn", "khúc", "rừng", "ruộng", "mía"],
        "rira": ["cắn", "gặm", "mổ", "châm", "xỉa", "rỉa"],
        "dura": ["gọt", "trau", "mài", "rèn", "giũa", "dủa"],
        "churi": ["lủi", "chủi"],
        "girai": ["hòa", "hoà", "lý", "lí", "diễn", "chú", "phân", "lời", "bài", "trao", "đoạt", "nhận", "giảng", "biện", "khuyên", "cứu", "giải"],
        "sosai": ["nguyên", "thống", "đại", "tướng", "chủ", "soái"],
        "tosai": ["phiền", "vụn", "toái"],
        "horai": ["bải", "oải", "hoải"],
        "hosoi": ["sám", "hấp", "thúc", "lời", "không", "chẳng", "hối"],
        "moroi": ["nốt", "cái", "mổi"],
        "tarau": ["đào", "bỏ", "chạy", "ống", "hút", "khói", "tẩu"],
        "harau": ["hào", "ngon", "hẩu"],
        "girui": ["gần", "giủi"],
        "gisui": ["đâm", "nhét", "giúi"],
        "guri": ["gần", "gủi"],
        "duri": ["con", "chuột", "may", "xui", "dùi", "dủi"],
        "nuri": ["ngắn", "ít", "trơ", "nủi"],
        "buri": ["đen", "bụi", "bủi"],
        "meje": ["bà", "các", "ôn", "chú", "mệ"],
        "deje": ["bệ", "dệ"],
        "gofo": ["nổi", "trán", "đầu", "mặt", "đất", "đá", "gồ"],
        "soxo": ["nói", "cười", "ăn", "sỗ"],
        "boxo": ["nói", "cười", "vỗ", "bỗ"],
        "moxo": ["lão", "bần", "mỗ"],
        "nofo": ["gà", "con", "nồ"],
        "sese": ["bóng", "chiều", "xế", "sế"],
        "nese": ["nề", "nế"],
        "hese": ["cười", "hế"],
        "kisu": ["cứu", "kêu", "kíu"],
        "hisu": ["mắt", "cười", "híu"],
        "kisa": ["đằng", "bên", "chỗ", "kìa", "kía"],
        "chisa": ["mũi", "súng", "chía"],
        "beer": ["bơi", "xây", "dâu", "bãi", "bốn", "biển", "bể"],
        "deer": ["khinh", "dể"],
        "sees": ["bóng", "chiều", "xế", "sế"],
        "deed": ["con", "bờ", "mặt", "chân", "vỡ", "đắp", "đường", "dâu", "hạt", "mê", "tê", "đê"],
        "deeds": ["hoàng", "thượng", "tiên", "chúa", "bóng", "chân", "gót", "đế"],
        "booms": ["lúa", "hạt", "nếp", "cốm", "bốm"],
        "sere": ["chim", "con", "chia", "san", "xẻ", "mổ", "sẻ", "sể"],
        "gisai": ["con", "em", "chị", "bạn", "cô", "bé", "trai", "nhà", "lấy", "sinh", "đẻ", "phái", "giái"],
        "torai": ["tự", "trải", "toải"],
        "hosai": ["vàng", "hoa", "hoái"],
        "nori": ["nhỏ", "bé", "ít", "nỏi"],
        "maso": ["máu", "con", "chim", "máo"],
        "arau": ["làm", "chạy", "nói", "ăn", "viết", "gõ", "tính", "hơi", "quá", "rất", "cực", "lái", "ẩu"],
        "mojo": ["ngôi", "phần", "bia", "đào", "viếng", "tảo", "lăng", "hâm", "ngưỡng", "ái", "chiêu", "mộ"],
        "goro": ["gây", "cãi", "ẩu", "gổ"],
        "doro": ["gây", "cãi", "dổ"],
        "here": ["cười", "vui", "hả", "hể"],
        "mere": ["cái", "gà", "tiền", "mể"],
        "chefe": ["trề", "môi", "mặt", "chề"],
        "lose": ["sáng", "chớp", "tia", "bừng", "nhấp", "lóe"],
        "chose": ["đỏ", "vàng", "sáng", "chói", "khóc", "chóe"],
        "hose": ["đỏ", "vàng"],
        "keeps": ["bánh", "kếp"],
        "deeps": ["rau", "cá", "dếp"],
        "rooms": ["nổi", "bị", "mẩn", "rôm", "rốm"],
        "gasu": ["cái", "chiếc", "múc", "nước", "gàu", "gáu"],
        "dasu": ["yêu", "con", "dấu", "giấu", "dáu"],
        "deso": ["dẻo", "kêu", "tiếng", "réo", "déo"],
        "trees": ["cá", "chậm", "trễ", "trế"],
        "queens": ["dính", "bết", "quyến", "hồ", "bột", "quến"],
        "sora": ["xõa", "tóc", "sỏa"],
        "sosa": ["xóa", "mờ", "sóa"],
        "dosa": ["đóa", "hoa", "dóa"],
        "sofa": ["xòa", "khóc", "cười", "sòa"],
        "rori": ["cỏi", "nhỏ", "gầy", "rạch", "rõ", "rỏi"],
        "hisa": ["hé", "nhìn", "mắt", "cười", "hía"],
        "miru": ["mỉm", "con", "mèo", "mỉu"],
        "riru": ["rầu", "buồn", "rũ", "rỉu"],
        "chiru": ["chịu", "mềm", "chỉu"],
        "seems": ["nói", "hơi", "rất", "quá", "cực", "phim", "văn", "nhạc", "sến", "sếm"],
        "deems": ["cá", "con", "đếm", "dếm"],
        "cheeps": ["cá", "bánh", "xếp", "chếp"],
        "dooms": ["chó", "vết", "hoa", "nổi", "đốm", "dốm"],
        "teems": ["tôm", "mắm", "con", "tếm"],
        "keens": ["con", "tổ", "đàn", "kến"],
        "moons": ["cá", "rau", "ngứa", "mốn"],
        "goons": ["vốn", "gốn"],
        "loons": ["lớn", "người", "lốn"],
        "gojo": ["ngộ", "gộ"],
        "dojo": ["độ", "dộ"],
        "toxo": ["cái", "bát", "tỗ"],
        "noso": ["lố", "bố", "nố"],
        "mura": ["múa", "nhảy", "mủa"],
        "hura": ["hùa", "hủa"],
        "gura": ["góa", "goá", "gủa"],
        "chura": ["chúa", "chủa"],
        "baru": ["châu", "của", "báu", "bảo", "bảu"],
        "maru": ["mẩu", "miếng", "mảu"],
        "noops": ["sưng", "phồng", "nốp"],
        "goops": ["gồ", "nổi", "cái", "gốp"],
        "troops": ["bộp", "lộp", "trốp"],
        "rojos": ["mắt", "lồi", "trợn", "rố"],
        "gotos": ["vải", "cổ", "gốt"],
        "nonos": ["bồn", "cồn", "nốn"],
        "mamas": ["nấm", "rau", "cây", "mấm"],
        "nura": ["nắng", "chín", "nủa"],
        "chere": ["trề", "môi", "chể"],
        "raru": ["rầu", "rau", "rảu"],
        "taru": ["đào", "tẩu", "tảu"],
        "garu": ["cái", "múc", "gảu"],
        "daru": ["yêu", "con", "dảu"],
        "seru": ["chim", "con", "sẻu"],
        "meru": ["móm", "mẻu"],
        "cheru": ["chặt", "chẻu"],
        "cheers": ["hạn", "cơ", "thể", "điều", "tự", "ức", "khống", "quy", "chế"],
        "seers": ["bóng", "chiều", "xế", "sế"],
        "veers": ["câu", "đối", "hai", "một", "vế"],
        "beers": ["bồng", "ẵm", "mẹ", "bà", "bế"],
        "deers": ["con", "tiếng", "đá", "bắt", "chọi", "dế"],
        "reefs": ["cái", "chiếc", "rổ", "rế"],
        "moors": ["cái", "chân", "đầu", "xây", "mố"],
        "boors": ["ông", "cha", "công", "phân", "tuyên", "bố"],
        "roofs": ["mắt", "lồi", "trợn", "rố"],
        "hoofs": ["cái", "miệng", "đào", "xuống", "lấp", "hố"],
        "goofs": ["vải", "áo", "gố"],
        "loofs": ["quá", "hơi", "rất", "mặc", "lố"],
        "tores": ["bắn", "tung", "nước", "máu", "lửa", "tóe"],
        "lores": ["sáng", "chớp", "tia", "lóe"],
        "chores": ["đỏ", "vàng", "sáng", "chóe"],
        "hifu": ["hắt", "buồn", "hìu"],
        "miju": ["mềm", "êm", "mịu"],
        "gifu": ["dắt", "nâng", "giù"],
        "hiru": ["hắt", "buồn", "hỉu"],
        "kiru": ["cứu", "kêu", "kỉu"],
        "giru": ["dắt", "nâng", "giủ"],
        "siru": ["ngất", "xỉu", "sỉu"],
        "tiru": ["tỉm", "cười", "tỉu"],
        "diru": ["dắt", "dìu", "dỉu"],
        "chiju": ["cam", "chấp", "khó", "dễ", "không", "chẳng", "chịu"],
        "diju": ["êm", "mềm", "nhẹ", "ngọt", "dịu"],
        "siju": ["mặt", "buồn", "xịu", "sịu"],
        "tiju": ["nặng", "trĩu", "tịu"],
        "giju": ["dắt", "nâng", "giụ"],
        "chisu": ["chim", "kêu", "líu", "chíu"],
        "gisu": ["bám", "níu", "giú"],
        "topo": ["một", "hai", "ba", "chia", "từng", "theo", "tốp"],
        "topos": ["một", "hai", "ba", "chia", "từng", "theo", "tốp"],
        "photos": ["bóc", "dính", "bị", "vụ", "lộ", "phốt"],
        "toast": ["lạnh", "ướt", "sợ", "hôi", "toát"],
        "coats": ["dứt", "cơn", "coát"],
        "coast": ["dứt", "cơn", "coát"],
        "soaps": ["lục", "soát", "soáp"],
        "oars": ["kêu", "tiếng", "oá"],
        "soar": ["xõa", "tóc", "xóa", "mờ", "sỏa"],
        "soars": ["xóa", "mờ", "sóa"],
        "tore": ["bắn", "tung", "nhỏ", "bé", "toẻ"],
        "hore": ["mạnh", "sức", "đỏ", "vàng", "hoẻ"],
        "hores": ["đỏ", "vàng", "hóe"],
        "leers": ["cá", "con", "lế"],
        "beefs": ["bồng", "ẵm", "mẹ", "bà", "bế"],
        "dodos": ["câu", "thách", "đố"],
        "dojos": ["câu", "thách", "dố"],
        "bars": ["độc", "xưng", "hùng", "thống", "chú", "bác", "bá"],
        "cars": ["con", "bắt", "câu", "nuôi", "kho", "chiên", "nướng", "canh", "chợ", "bể", "ao", "hồ", "đàn", "cá"],
        "mars": ["ba", "mẹ", "gò", "đôi", "hai", "thơm", "hôn", "rau", "má"],
        "tars": ["một", "hàng", "thượng", "đại", "trung", "thiếu", "phụ", "y", "tá"],
        "vars": ["khâu", "may", "chắp", "cái", "muôi", "vá"],
        "hairs": ["đi", "vừa", "mới", "thu", "chưa", "hái"],
        "chairs": ["hiên", "nhà", "mái", "đầu", "chái"],
        "lairs": ["tay", "tài", "người", "buồng", "bánh", "cầm", "tập", "học", "bằng", "chèo", "lái"],
        "airs": ["nhân", "ưu", "bác", "thân", "tình", "yêu", "khả"],
        "naifs": ["lợn", "heo", "cá", "sề", "nái"],
        "choirs": ["sáng", "nắng", "đỏ", "vàng", "ánh", "mắt", "rực", "chói"],
        "coifs": ["chiếu", "cây", "đồng", "dệt", "lác", "túi", "mũ", "nón", "cói"],
        "loafs": ["sáng", "chói", "ánh", "tia", "nhìn", "mắt", "bừng", "rực", "lấp", "lánh", "loá", "lóa"],
        "sofas": ["xóa", "mờ", "sóa", "soá"],
        "oafs": ["kêu", "tiếng", "khóc", "vỡ"],
        "lore": ["sáng", "đỏ", "loẻ", "lỏe"],
        "chore": ["đỏ", "vàng", "choẻ", "chỏe"],
        "hers": ["cửa", "mở", "nhìn", "cười", "mắt", "khe", "vừa", "mới", "chưa", "hé"],
        "chefs": ["rượu", "cái", "một", "hai", "chum", "ché"],
        "refs": ["kêu", "hét", "khóc", "tiếng", "lúa", "gạo", "ré"],
        "vers": ["mua", "bán", "tấm", "chiếc", "cái", "giá", "soát", "đặt", "quầy", "cổng", "trạm", "hết", "còn", "một", "hai", "cặp", "vé"],
        "sirs": ["bí", "nhí", "chút", "tí", "sí"],
        "dirs": ["bị", "đang", "cứ", "dí"],
        "ors": ["chim", "con", "diều", "tiếng", "kêu"],
        "urs": ["mập", "béo", "tròn", "heo", "lợn", "chó", "mèo", "con", "bé"],
        "curs": ["chim", "con", "mắt", "đêm", "một", "hai", "mấy", "đấm", "đá", "sút", "ngã", "lừa", "sốc", "tát", "cú"],
        "burs": ["cho", "con", "trẻ", "em", "bé", "sữa", "bình", "núm", "đòi", "cai", "bú"],
        "barf": ["ông", "hai", "các", "mấy", "cụ", "đàn", "bà"],
        "barfs": ["độc", "xưng", "hùng", "thống", "chú", "bác", "bá"],
        "nerf": ["đây", "đó", "kia", "coi", "nhìn", "nghe", "thấy", "em", "anh", "nè"],
        "nerfs": ["tránh", "đứng", "chạy", "cố", "phải", "kịp", "né"],
        "serf": ["nhè", "rè", "sè"],
        "serfs": ["chim", "con", "xé", "sé"],
        "surf": ["đầu", "tóc", "lông", "xù", "sù"],
        "turf": ["nhà", "vào", "ở", "đi", "ra", "bỏ", "án", "phạt", "ngục", "cầm", "tù"],
        "ores": ["kêu", "tiếng", "khóc", "cười"],
        "roes": ["kêu", "tiếng", "khóc", "cười", "róe", "roé"],
        "noes": ["ánh", "sáng", "nóe", "noé"],
        "liars": ["lia", "thoăn", "nhanh", "nói", "chém", "lía"],
        "barns": ["mua", "buôn", "chợ", "quán", "giá", "người", "hàng", "đang", "không", "chưa", "sắp", "bán"],
        "darns": ["băng", "keo", "giấy", "miếng", "hồ", "cắt", "nhãn", "dán"],
        "tarns": ["phát", "phân", "bàn", "giải", "sơ", "xơ", "hòa", "tán"],
        "morns": ["một", "hai", "ba", "mấy", "nhiều", "các", "ăn", "nấu", "làm", "gọi", "món"],
        "borns": ["chăm", "phân", "đút", "tưới", "bón"],
        "corns": ["nhỏ", "bé", "con", "cón"],
        "horns": ["nhỏ", "hón"],
        "thorns": ["ăn", "lấy", "bốc", "nhón", "thón"],
        "harms": ["tham", "rất", "quá", "kẻ", "người", "hám"],
        "charms": ["quả", "cây", "bánh", "chám"],
        "corms": ["gầy", "nhỏ", "ốm", "cóm"],
        "dorms": ["nhen", "lửa", "nhóm", "dóm"],
        "burns": ["ăn", "tô", "bát", "sợi", "làm", "nấu", "quán", "chả", "riêu", "bò", "mắm", "bún"],
        "turns": ["cười", "tủm", "tún"],
        "urns": ["mập", "béo", "tròn"],
        "terms": ["gọn", "vén", "ăn", "tém"],
        "kerns": ["con", "tổ", "đóng", "làm", "rất", "hơi", "khá", "kén"],
        "door": ["gây", "cãi", "dổ"],
        "goof": ["nổi", "trán", "đầu", "mặt", "đất", "đá", "gồ"],
        "oofs": ["kêu", "tiếng", "hoen", "vết"],
        "darn": ["thanh", "dản"],
        "thorn": ["nhỏ", "bé", "thỏn"],
        "morn": ["nhỏ", "ít", "mỏn"],
        "corm": ["nhỏ", "gầy", "cỏm"],
        "harm": ["thảm", "hiểm", "hảm"],
        "charm": ["xử", "chém", "trảm", "chảm"],
        "chasm": ["quả", "cây", "bánh", "trái", "chám"],
        "horn": ["héo", "nhỏ", "gầy", "hỏn"],
        "torn": ["nhỏ", "bé", "tỏn"],
        "norm": ["nhỏ", "gầy", "nỏm"],
        "norms": ["nhỏ", "tóm", "nóm"],
        "kern": ["bẽn", "rụt", "kẻn"],
        "tern": ["bẽn", "lẽn", "tẻn"],
        "terns": ["nhỏ", "bé", "tén"],
        "berms": ["liếm", "ăn", "bém"],
        "derm": ["nhỏ", "mỏng", "dẻm"],
        "term": ["nhỏ", "gọn", "tẻm"],
        "churn": ["ngủn", "tủn", "ngắn", "cụt", "chủn"],
        "churns": ["chũn", "mập", "tròn", "chún"],
        "urn": ["lợn", "kêu"],
        "defends": ["đi", "về", "chạy", "đưa", "gửi", "tìm", "nhớ", "nghĩ", "nói", "nhắc", "kể", "chờ", "đợi", "sắp", "chưa", "đã", "vừa", "mới", "đến"],
        "gown": ["cơn", "nổi", "gơn"],
        "gowns": ["hớn", "lớn", "gớn"],
        "dawn": ["nhăn", "dăn"],
        "dawns": ["rắn", "chắc", "dắn"],
        "lawns": ["sâu", "lắn"],
        "siren": ["lảo", "xiển", "siển"],
        "sirens": ["gỗ", "cây", "siến"],
        "tureen": ["ứng", "sơ", "tuyển", "tuển"],
        "tureens": ["trực", "chiến", "tuyến", "tuến"],
        "boron": ["căn", "nguyên", "chính", "bổn"],
        "moron": ["lổn", "ngổn", "mổn"],
        "morons": ["cá", "mốn"],
        "honors": ["hổn", "hốn"],
        "donors": ["vốn", "của", "dốn"],
        "buys": ["túy", "quý", "búy"],
        "guys": ["quý", "gúy"],
        "dux": ["quyến", "dụ", "rủ", "dũ"],
        "tux": ["cũ", "mũ", "tũ"],
        "nix": ["năn", "ỉ", "nĩ"],
        "hex": ["vui", "hẽ"],
        "trex": ["trẻ", "trẽ"],
        "basta": ["khả", "tài", "sự", "bị", "bất"],
        "rasta": ["nhiều", "hơi", "quá", "cực", "rất"],
        "beset": ["dính", "ướt", "tóc", "bết"],
        "boost": ["dốt", "rốt", "đồn", "giày", "đôi", "bốt"],
        "roost": ["cuộc", "cốt", "dốt", "đến", "rốt"],
        "burst": ["cây", "ngòi", "cầm", "viết", "nét", "hộp", "mực", "bút"],
        "thirst": ["ít", "thịt", "rất", "hơi", "chặt", "buộc", "thắt", "thít"],
        "sorts": ["xót", "đau", "thương", "thiếu", "bỏ", "sai", "sót"],
        "cost": ["chiếu", "bồ", "kêu", "tiếng", "ép", "cót"],
        "most": ["nhặt", "lượm", "đi", "cơm", "lúa", "mót"],
        "rust": ["được", "tiền", "dây", "rút"],
        "gasp": ["ngáp", "cơn", "thở", "hấp", "gáp"],
        "rasp": ["lắp", "ghép", "nhám", "giấy", "chà", "ráp"],
        "cusp": ["điện", "nước", "giải", "chiếc", "nhận", "đoạt", "cúp"],
        "lisp": ["xích", "nhông", "bánh", "đĩa", "líp"],
        "swops": ["ướt", "mềm", "sến", "sướp"],
        "sense": ["nhạc", "văn", "hơi", "rất", "quá", "cực", "sến"],
        "tense": ["khánh", "họ", "mũi", "bắn", "tến"],
        "dense": ["cây", "ngọn", "thắp", "đốt", "ánh", "dến"],
        "risen": ["cá", "lươn", "riến"],
        "vixen": ["bệnh", "thư", "vĩnh", "học", "thị", "viễn"],
        "chosen": ["hổn", "lổn", "chén", "choén"],
        "virus": ["bấu", "níu", "víu"],
        "loris": ["nói", "chói", "sáng", "lói"],
        "bias": ["tấm", "đá", "tập", "bìa", "bía"],
        "testers": ["ăn", "đón", "ngày", "nghỉ", "mừng", "mâm", "chợ", "quà", "bánh", "dịp", "trước", "tết"],
        "teens": ["khánh", "họ", "mũi", "bắn", "tến"],
        "memes": ["nhá", "mếm"],
        "themes": ["miếng", "ăn", "nếm", "thếm"],
        "hangars": ["hờ", "hấng"],
        "maxis": ["nhà", "tóc", "ngói", "hiên", "chèo", "cánh", "gà", "mái"],
        "taxis": ["hiện", "tích", "tạo", "lặp", "tê", "chín", "thịt", "bò", "tái"],
        "minx": ["cười", "tủm", "mĩn"],
        "xanax": ["lẫn", "bẩn", "xẫn"],
        "xerox": ["khéo", "xẽo"],
        "thorax": ["thỏa", "lấp", "thõa"],
        "queer": ["cành", "bói", "rẻ", "quể"],
        "queers": ["cây", "vỏ", "hương", "mùi", "bột", "trà", "rừng", "quế"],
        "queues": ["bếu", "mếu", "quếu"],
        "vexes": ["câu", "đối", "một", "vế"],
        "hexes": ["cười", "hế"],
        "sexes": ["bóng", "chiều", "xế", "sế"],
        "haafu": ["tối", "dưa", "cầu", "bầu", "diều", "chầu", "rầu", "hầu"],
        "saafu": ["buồn", "riêng", "rầu", "cây", "quả", "trái", "mùa", "lá", "sầu"],
        "taafu": ["chuyến", "bến", "vé", "đi", "đoàn", "mạn", "đầu", "tầu"],
        "seefu": ["lều", "phều", "sều"],
        "baasu": ["bám", "víu", "bấu"],
        "naasu": ["ăn", "cơm", "cháo", "bếp", "nướng", "đun", "nấu"],
        "garasu": ["mật", "chân", "vật", "rừng", "trắng", "đen", "bắc", "mắt", "gấu"],
        "keesu": ["cứu", "kêu", "kếu"],
        "beesu": ["mặt", "môi", "cười", "khóc", "mếu", "bếu"],
        "reesu": ["đất", "cày", "rếu"],
        "beeru": ["môi", "trề", "dẩu", "bểu"],
        "meeru": ["móm", "mểu"],
        "neeru": ["lếu", "nểu"],
        "reeru": ["rệu", "rểu"],
        "seeru": ["xểu", "sểu"],
        "teeru": ["tếu", "tểu"],
        "gaaru": ["nóng", "cáu", "gắt", "nhăn", "gẩu"],
        "hasaru": ["hào", "hẩu"],
        "masaru": ["một", "mấy", "miếng", "bánh", "mì", "gỗ", "giấy", "chuyện", "mẩu"],
        "nasaru": ["ẩn", "trốn", "cất", "chỗ", "nơi", "nẩu"],
        "sasaru": ["cây", "quả", "trái", "mùa", "lá", "nước", "sẩu"],
        "tasaru": ["đào", "bỏ", "chạy", "ống", "hút", "khói", "tẩu"],
        "toori": ["dân", "tộc", "đội", "trưởng", "tổ", "tổi"],
        "sosori": ["nổi", "hạt", "cơm", "xổi", "sổi"],
        "daasu": ["yêu", "đóng", "giấu", "chỉ", "hỏi", "ngã", "nặng", "sắc", "huyền", "dấu"],
        "datas": ["trời", "mặt", "đất", "dất"],
        "diets": ["biền", "khôn", "riết", "diết"],
        "quiets": ["tâm", "định", "liệt", "quyết", "quiết"],
        "nieces": ["cá", "liếc", "niếc"],
        "verse": ["câu", "đối", "một", "vế"],
        "refers": ["cái", "chiếc", "rổ", "rế"],
        "defer": ["khinh", "dể"],
        "lexer": ["kể", "lể"],
        "refer": ["chàng", "làm", "dâu", "rể"],
        "refuse": ["đất", "cày", "bới"],
        "reuse": ["đất", "cày", "bới"],
        "major": ["giờ", "mão", "tuổi"],
        "majors": ["mũ", "mào", "máo"],
        "corsair": ["uể", "oải", "coải"],
        "corsairs": ["nhìn", "ngoái", "coái"],
        "horse": ["đỏ", "vàng", "hóe"],
        "those": ["nói", "cười", "thóe"],
        "coax": ["xõa", "tóc", "cõa"],
        "kerf": ["bờ", "đá", "cây", "rượu", "nhậu", "cặp", "kè"],
        "taxi": ["bãi", "trải", "tãi"],
        "maxi": ["mê", "nhớ", "yêu", "chờ", "đợi", "cứ", "vẫn", "còn", "thương", "mãi"],
        "worm": ["ướm", "thử", "ưởm"],
        "worms": ["hỏi", "thử", "lời", "ướm"],
        "worn": ["ưỡn", "ngực", "ưởn"],
        "worst": ["ẩm", "mưa", "nhẹp", "sũng", "lạnh", "mềm", "rất", "hơi", "quá", "ướt"],
        "hiju": ["nặng", "buồn", "quạnh", "đìu", "hịu"],
        "kifu": ["cứu", "kêu", "kìu"],
        "kiju": ["nặng", "trĩu", "dịu", "chịu"],
        "niru": ["bám", "níu", "nỉu"],
        "haru": ["hào", "hẩu", "hảu"],
        "naru": ["ẩn", "trốn", "nẩu", "nảu"],
        "saru": ["cây", "quả", "trái", "sẩu", "sảu"],
        "narau": ["ẩn", "trốn", "cất", "chỗ", "nơi", "nẩu"],
        "sarau": ["cây", "quả", "trái", "mùa", "lá", "nước", "sẩu"],
        "dora": ["tóc", "xõa", "dỏa"],
        "guwa": ["nắng", "mưa", "gưa"],
        "huwa": ["dạ", "vâng", "thưa", "hưa"],
        "ruwa": ["buổi", "giữa", "nắng", "cơm", "nghỉ", "trưa", "rưa"],
        "giwa": ["cái", "lưỡi", "cưa", "giữa", "giưa"],
        "auras": ["trứng", "củ", "hạt", "ấu"],
        "asaru": ["làm", "chạy", "nói", "ẩu"],
        "aru": ["nóng", "cáu", "gắt"],
        "iru": ["mềm", "bánh", "hắt"],
        "isu": ["yếu", "nhỏ", "bé"],
        "deem": ["nửa", "suốt", "đêm", "dêm"],
        "seem": ["bọ", "loài", "sêm"],
        "keen": ["đàn", "kên"],
        "doom": ["cái", "lôm", "ồm", "dôm"],
        "dono": ["bồn", "cồn"],
        "sono": ["cầu", "lầu"],
        "phono": ["gọi", "máy"],
        "momo": ["cái", "chiếc", "lôm", "môm"],
        "nama": ["cái", "chiếc", "mâm", "nâm"],
        "mana": ["quả", "trái", "cây", "mân"],
        "nana": ["phân", "nhân", "nân"],
        "donor": ["lổn", "ngổn"],
        "honor": ["hấp", "thở"],
        "vixens": ["thăm", "đi", "đến", "viến"],
        "sore": ["sức", "khỏe"],
        "dore": ["dẻo", "khỏe"],
        "rore": ["rạch", "rõ"],
        "nora": ["nõn", "nở"],
        "rora": ["rực", "tỏa"],
        "beru": ["môi", "trề"],
        "teru": ["cười", "tếu"],
        "keru": ["kêu", "kẻo"],
        "heru": ["hẻo", "vắng"],
        "neru": ["nẻo", "khắp"],
        "deru": ["dẻo", "mềm"],
        "reru": ["rẻo", "miếng"],
        "kesu": ["kêu", "kéo"],
        "mesu": ["khóc", "mếu"],
        "tesu": ["cười", "tếu"],
        "besu": ["mặt", "bếu"],
        "hesu": ["khô", "héo"],
        "sesu": ["xéo", "sẻ"],
        "resu": ["kêu", "réo"],
        "nesu": ["bám", "néo"],
        "befu": ["cánh", "bèo"],
        "kefu": ["kêu", "tiếng"],
        "mefu": ["bèo", "mặt"],
        "nefu": ["lèu", "bèu"],
        "hefu": ["phèu", "lèu"],
        "sefu": ["lèu", "phèu"],
        "tefu": ["nhỏ", "bèu"],
        "defu": ["mềm", "dẻo"],
        "gefu": ["kêu", "tiếng"],
        "refu": ["mềm", "rũ"],
        "pefu": ["mềm", "bèo"],
        "gesu": ["kêu", "réo"],
        "pesu": ["khóc", "mếu"],
        "peru": ["cười", "môi"],
        "geso": ["kêu", "tiếng"],
        "kaso": ["cáo", "báo"],
        "kosa": ["chìa", "ổ"],
        "posa": ["xóa", "tóa"],
        "pora": ["tỏa", "xõa"],
        "kose": ["khóc", "kêu"],
        "rose": ["khóc", "cười"],
        "pose": ["sáng", "đỏ"],
        "nose": ["sáng", "ánh"],
        "dose": ["đỏ", "sáng"],
        "more": ["mệt", "sức"],
        "bore": ["nhỏ", "bỏ"],
        "pore": ["nhỏ", "sức"],
        "koxa": ["cỏ", "xõa"],
        "pura": ["múa", "tủa"],
        "puri": ["bụi", "phủi"],
        "pari": ["bải", "phải"],
        "paru": ["báu", "bảu"],
        "piru": ["mềm", "bỉu"],
        "pasu": ["châu", "báu"],
        "pisu": ["bíu", "níu"],
        "pafu": ["nhàu", "bàu"],
        "paasu": ["bấu", "dấu"],
        "paaru": ["mẩu", "tẩu"],
        "peesu": ["mếu", "bếu"],
        "kono": ["cồn", "bồn"],
        "kama": ["mâm", "tâm"],
        "pifu": ["mềm", "nhẹ"],
        "piju": ["nặng", "trĩu"],
        "kasu": ["nóng", "gắt"],
        "karu": ["nóng", "cáu"],
        "kafu": ["nhàu", "bàu"],
        "kuri": ["gần", "củi"],
        "koro": ["vất", "khổ"],
        "koso": ["cố", "gắng"],
        "kofo": ["cổ", "cồ"],
        "kojo": ["lộ", "cộ"],
        "koxo": ["gỗ", "cỗ"],
        "pofo": ["bồ", "hòn"],
        "poso": ["phố", "bố"],
        "poro": ["vỡ", "nổ"],
        "pojo": ["bộ", "lộ"],
        "poxo": ["vỗ", "bỗ"],
        "pefe": ["bề", "lề"],
        "pese": ["bế", "tế"],
        "pere": ["kể", "nể"],
        "peje": ["bệ", "tệ"],
        "pexe": ["bễ", "lễ"],
        "pisa": ["phía", "mía"],
        "pira": ["tỉa", "rỉa"],
        "pifa": ["bìa", "lìa"],
        "pija": ["bịa", "địa"],
        "pixa": ["đĩa", "nghĩa"],
        "kura": ["cửa", "múa"],
        "kusa": ["của", "lúa"],
        "kufa": ["mùa", "chùa"],
        "kuja": ["lụa", "dụa"],
        "kuxa": ["đũa", "giũa"],
        "pusa": ["búa", "lúa"],
        "pufa": ["bùa", "mùa"],
        "puja": ["lụa", "bụa"],
        "puxa": ["đũa", "bũa"],
        "kusi": ["túi", "cúi"],
        "kufi": ["cùi", "bùi"],
        "kuji": ["cụi", "bụi"],
        "kuxi": ["cũi", "gũi"],
        "pusi": ["túi", "búi"],
        "pufi": ["cùi", "bùi"],
        "puji": ["cụi", "bụi"],
        "puxi": ["cũi", "gũi"],
        "kosi": ["nói", "chói"],
        "kofi": ["còi", "lòi"],
        "kori": ["cỏi", "hỏi"],
        "koxi": ["cõi", "lõi"],
        "koji": ["cọi", "gọi"],
        "posi": ["nói", "bói"],
        "pofi": ["còi", "vòi"],
        "pori": ["cỏi", "hỏi"],
        "poxi": ["cõi", "dõi"],
        "poji": ["cọi", "gọi"],
        "kasi": ["cái", "hái"],
        "kafi": ["cài", "dài"],
        "kari": ["cải", "phải"],
        "kaxi": ["cãi", "mãi"],
        "kaji": ["cại", "loại"],
        "pasi": ["cái", "bái"],
        "pafi": ["bài", "dài"],
        "paxi": ["bãi", "mãi"],
        "paji": ["bại", "loại"],
        "kafo": ["cào", "vào"],
        "karo": ["cảo", "bảo"],
        "kaxo": ["bão", "não"],
        "kajo": ["cạo", "gạo"],
        "paso": ["báo", "pháo"],
        "pafo": ["bào", "vào"],
        "paro": ["bảo", "hảo"],
        "paxo": ["bão", "lão"],
        "pajo": ["bạo", "tạo"],
        "peso": ["béo", "kéo"],
        "pefo": ["bèo", "nghèo"],
        "pero": ["dẻo", "lẻo"],
        "pexo": ["bẽo", "lẽo"],
        "pejo": ["bẹo", "kẹo"],
        "kofa": ["chìa", "xòa"],
        "koja": ["đọa", "dọa"],
        "pofa": ["xòa", "tòa"],
        "poja": ["đọa", "tọa"],
        "gese": ["ghế", "kế"],
        "gefe": ["ghề", "kề"],
        "gere": ["kể", "nể"],
        "gexe": ["dễ", "lễ"],
        "geje": ["nghệ", "tệ"],
        "gefo": ["ghèo", "nghèo"],
        "gero": ["dẻo", "lẻo"],
        "gexo": ["lẽo", "đẽo"],
        "gejo": ["ghẹo", "kẹo"],
        "geru": ["dẻo", "mềm"],
        "gexu": ["mềm", "dẻo"],
        "geju": ["nặng", "mềm"],
        "kaxu": ["nhàu", "bàu"],
        "kaju": ["nhàu", "bàu"],
        "paxu": ["nhàu", "bàu"],
        "paju": ["nhàu", "bàu"],
        "pixu": ["nặng", "trĩu"],
        "kora": ["tỏa", "xõa"],
        "poxa": ["tỏa", "xõa"],
        "kofe": ["đỏ", "hòe"],
        "kore": ["mệt", "khỏe"],
        "koxe": ["đỏ", "hòe"],
        "koje": ["đỏ", "nhọe"],
        "pofe": ["đỏ", "hòe"],
        "poxe": ["đỏ", "hòe"],
        "poje": ["đỏ", "nhọe"],
        "kasa": ["cấp", "tấp"],
        "kafa": ["cầu", "trầm"],
        "kara": ["cẩn", "khẩn"],
        "kaxa": ["cẫm", "dẫm"],
        "kaja": ["cập", "tập"],
        "pasa": ["cấp", "tấp"],
        "pafa": ["cầu", "trầm"],
        "para": ["cẩn", "khẩn"],
        "paxa": ["cẫm", "dẫm"],
        "paja": ["cập", "tập"],
        "kasy": ["cáy", "máy"],
        "kafy": ["cày", "dày"],
        "kary": ["gảy", "chảy"],
        "kaxy": ["cãy", "gãy"],
        "kajy": ["cạy", "chạy"],
        "pasy": ["cáy", "máy"],
        "pafy": ["cày", "dày"],
        "pary": ["gảy", "chảy"],
        "paxy": ["cãy", "gãy"],
        "pajy": ["cạy", "chạy"],
        "ngese": ["nghế", "ghế"],
        "ngefe": ["nghề", "kề"],
        "ngere": ["kể", "nể"],
        "ngexe": ["nghễ", "lễ"],
        "ngeje": ["nghệ", "tệ"],
        "ngeso": ["khéo", "kéo"],
        "ngefo": ["nghèo", "trèo"],
        "ngero": ["ngoẻo", "lẻo"],
        "ngexo": ["lẽo", "đẽo"],
        "ngejo": ["nghẹo", "kẹo"],
        "ngesu": ["kêu", "mếu"],
        "ngefu": ["mềm", "phèu"],
        "ngeru": ["dẻo", "mềm"],
        "ngexu": ["mềm", "dẻo"],
        "ngeju": ["nặng", "mềm"],
        "bose": ["đỏ", "sáng"],
        "bofe": ["đỏ", "hòe"],
        "boxe": ["đỏ", "hòe"],
        "boje": ["đỏ", "nhọe"],
        "mose": ["đỏ", "sáng"],
        "mofe": ["đỏ", "hòe"],
        "moxe": ["đỏ", "hòe"],
        "moje": ["đỏ", "nhọe"],
        "nofe": ["đỏ", "hòe"],
        "nore": ["mệt", "khỏe"],
        "noxe": ["đỏ", "hòe"],
        "noje": ["đỏ", "nhọe"],
        "dofe": ["đỏ", "hòe"],
        "doxe": ["đỏ", "hòe"],
        "doje": ["đỏ", "nhọe"],
        "rofe": ["đỏ", "hòe"],
        "roxe": ["đỏ", "hòe"],
        "roje": ["đỏ", "nhọe"],
        "sose": ["đỏ", "sáng"],
        "sofe": ["đỏ", "hòe"],
        "soxe": ["đỏ", "hòe"],
        "soje": ["đỏ", "nhọe"],
        "vose": ["đỏ", "sáng"],
        "vofe": ["đỏ", "hòe"],
        "vore": ["mệt", "khỏe"],
        "voxe": ["đỏ", "hòe"],
        "voje": ["đỏ", "nhọe"],
        "gose": ["đỏ", "sáng"],
        "gofe": ["đỏ", "hòe"],
        "gore": ["mệt", "khỏe"],
        "goxe": ["đỏ", "hòe"],
        "goje": ["đỏ", "nhọe"],
        "phose": ["đỏ", "sáng"],
        "phofe": ["đỏ", "hòe"],
        "phore": ["mệt", "khỏe"],
        "phoxe": ["đỏ", "hòe"],
        "phoje": ["đỏ", "nhọe"],
        "trose": ["đỏ", "sáng"],
        "trofe": ["đỏ", "hòe"],
        "trore": ["mệt", "khỏe"],
        "troxe": ["đỏ", "hòe"],
        "troje": ["đỏ", "nhọe"],
        "bosa": ["xóa", "tóa"],
        "bofa": ["xòa", "tòa"],
        "bora": ["tỏa", "xõa"],
        "boxa": ["tỏa", "xõa"],
        "boja": ["đọa", "tọa"],
        "mosa": ["xóa", "tóa"],
        "mofa": ["xòa", "tòa"],
        "mora": ["tỏa", "xõa"],
        "moxa": ["tỏa", "xõa"],
        "moja": ["đọa", "tọa"],
        "vosa": ["xóa", "tóa"],
        "vofa": ["xòa", "tòa"],
        "vora": ["tỏa", "xõa"],
        "voxa": ["tỏa", "xõa"],
        "voja": ["đọa", "tọa"],
        "nofa": ["xòa", "tòa"],
        "noja": ["đọa", "tọa"],
        "cose": ["đỏ", "sáng"],
        "cofe": ["đỏ", "hòe"],
        "core": ["mệt", "khỏe"],
        "coxe": ["đỏ", "hòe"],
        "coje": ["đỏ", "nhọe"],
        "nosa": ["xóa", "tóa"],
        "rosa": ["xóa", "tóa"],
        "rofa": ["xòa", "tòa"],
        "roxa": ["tỏa", "xõa"],
        "roja": ["đọa", "tọa"],
        "gofa": ["xòa", "tòa"],
        "gora": ["tỏa", "xõa"],
        "goxa": ["tỏa", "xõa"],
        "goja": ["đọa", "tọa"],
        "phosa": ["xóa", "tóa"],
        "phofa": ["xòa", "tòa"],
        "phora": ["tỏa", "xõa"],
        "phoxa": ["tỏa", "xõa"],
        "phoja": ["đọa", "tọa"],
        "trosa": ["xóa", "tóa"],
        "trofa": ["xòa", "tòa"],
        "trora": ["tỏa", "xõa"],
        "troxa": ["tỏa", "xõa"],
        "troja": ["đọa", "tọa"],
        "basa": ["cấp", "tấp"],
        "bafa": ["cầu", "trầm"],
        "bara": ["cẩn", "khẩn"],
        "baxa": ["cẫm", "dẫm"],
        "baja": ["cập", "tập"],
        "dasa": ["cấp", "tấp"],
        "dafa": ["cầu", "trầm"],
        "dara": ["cẩn", "khẩn"],
        "daxa": ["cẫm", "dẫm"],
        "daja": ["cập", "tập"],
        "gasa": ["cấp", "tấp"],
        "gafa": ["cầu", "trầm"],
        "gara": ["cẩn", "khẩn"],
        "gaxa": ["cẫm", "dẫm"],
        "gaja": ["cập", "tập"],
        "hasa": ["cấp", "tấp"],
        "hafa": ["cầu", "trầm"],
        "hara": ["cẩn", "khẩn"],
        "haxa": ["cẫm", "dẫm"],
        "haja": ["cập", "tập"],
        "masa": ["cấp", "tấp"],
        "mafa": ["cầu", "trầm"],
        "mara": ["cẩn", "khẩn"],
        "maxa": ["cẫm", "dẫm"],
        "maja": ["cập", "tập"],
        "nasa": ["cấp", "tấp"],
        "nafa": ["cầu", "trầm"],
        "nara": ["cẩn", "khẩn"],
        "naxa": ["cẫm", "dẫm"],
        "naja": ["cập", "tập"],
        "rasa": ["cấp", "tấp"],
        "rafa": ["cầu", "trầm"],
        "rara": ["cẩn", "khẩn"],
        "raxa": ["cẫm", "dẫm"],
        "raja": ["cập", "tập"],
        "sasa": ["cấp", "tấp"],
        "safa": ["cầu", "trầm"],
        "sara": ["cẩn", "khẩn"],
        "saxa": ["cẫm", "dẫm"],
        "saja": ["cập", "tập"],
        "tasa": ["cấp", "tấp"],
        "tafa": ["cầu", "trầm"],
        "tara": ["cẩn", "khẩn"],
        "taxa": ["cẫm", "dẫm"],
        "taja": ["cập", "tập"],
        "chasa": ["cấp", "tấp"],
        "chafa": ["cầu", "trầm"],
        "chara": ["cẩn", "khẩn"],
        "chaxa": ["cẫm", "dẫm"],
        "chaja": ["cập", "tập"],
        "asa": ["cấp", "tấp"],
        "esu": ["kêu", "mếu"],
        "efu": ["mềm", "phèu"],
        "eru": ["dẻo", "lẻo"],
        "pexu": ["mềm", "phèu"],
        "peju": ["mếu", "bệu"],
        "bosai": ["ngoái", "xoái"],
        "bofai": ["ngoài", "hoài"],
        "borai": ["oải", "thoải"],
        "boxai": ["oải", "xoãi"],
        "bojai": ["loại", "ngoại"],
        "mosai": ["ngoái", "xoái"],
        "mofai": ["ngoài", "hoài"],
        "morai": ["oải", "thoải"],
        "moxai": ["oải", "xoãi"],
        "mojai": ["loại", "ngoại"],
        "vosai": ["ngoái", "xoái"],
        "vofai": ["ngoài", "hoài"],
        "vorai": ["oải", "thoải"],
        "voxai": ["oải", "xoãi"],
        "vojai": ["loại", "ngoại"],
        "nosai": ["ngoái", "xoái"],
        "nofai": ["ngoài", "hoài"],
        "noxai": ["oải", "xoãi"],
        "nojai": ["loại", "ngoại"],
        "rosai": ["ngoái", "xoái"],
        "rofai": ["ngoài", "hoài"],
        "roxai": ["oải", "xoãi"],
        "rojai": ["loại", "ngoại"],
        "gosai": ["ngoái", "xoái"],
        "gofai": ["ngoài", "hoài"],
        "gorai": ["oải", "thoải"],
        "goxai": ["oải", "xoãi"],
        "gojai": ["loại", "ngoại"],
        "phosai": ["ngoái", "xoái"],
        "phofai": ["ngoài", "hoài"],
        "phorai": ["oải", "thoải"],
        "phoxai": ["oải", "xoãi"],
        "phojai": ["loại", "ngoại"],
        "trosai": ["ngoái", "xoái"],
        "trofai": ["ngoài", "hoài"],
        "trorai": ["oải", "thoải"],
        "troxai": ["oải", "xoãi"],
        "trojai": ["loại", "ngoại"],
        "dosai": ["ngoái", "xoái"],
        "dofai": ["ngoài", "hoài"],
        "doxai": ["oải", "xoãi"],
        "dojai": ["loại", "ngoại"],
        "noxay": ["xoáy", "ngoáy"],
        "dofay": ["xoáy", "ngoáy"],
        "doxay": ["xoáy", "ngoáy"],
        "dojay": ["xoáy", "ngoáy"],
        "noxao": ["ngọt", "ngào"],
        "dofao": ["ngọt", "ngào"],
        "doxao": ["ngọt", "ngào"],
        "dojao": ["ngọt", "ngào"],
        "boar": ["tỏa", "xõa"],
        "boars": ["xóa", "tóa"],
        "roar": ["tỏa", "xõa"],
        "roars": ["xóa", "tóa"],
        "boast": ["toát", "thoát"],
        "roast": ["toát", "thoát"],
        "boats": ["toát", "thoát"],
        "goats": ["toát", "thoát"],
        "moats": ["toát", "thoát"],
        "moans": ["đoán", "toán"],
        "roams": ["bám", "nhám"],
        "pores": ["đỏ", "sáng"],
        "goes": ["đỏ", "sáng"],
        "does": ["đỏ", "sáng"],
        "peeps": ["bếp", "nếp"],
        "perms": ["chém", "ném"],
        "ports": ["xót", "rót"],
        "puts": ["bút", "rút"],
        "pars": ["khá", "quá"],
        "arms": ["hắc", "u"],
        "irs": ["bí", "nhí"],
        "ers": ["né", "hé"],
        "dadas": ["cấp", "tấp"],
        "charas": ["cấp", "tấp"],
        "disc": ["nhích", "thích"],
        "oxen": ["bẽn", "lẽn"],
        "axis": ["ưu", "nhân"],
        "laws": ["nắng", "chói"],
        "raws": ["nắng", "chói"],
        "saws": ["nắng", "chói"],
        "caws": ["nắng", "chói"],
        "maws": ["nắng", "chói"],
        "haws": ["nắng", "chói"],
        "paws": ["nắng", "chói"],
        "thaws": ["nắng", "chói"],
        "bawks": ["nắng", "chói"],
        "gawks": ["nắng", "chói"],
        "hawks": ["nắng", "chói"],
        "pawns": ["nắng", "bắn"],
        "torns": ["tí", "bé"],
        "wars": ["nắng", "mưa"],
        "wows": ["nức", "rực"],
        "pair": ["bải", "phải"],
        "pairs": ["bái", "phái"],
        "pays": ["báy", "máy"],
        "peer": ["kể", "nể"],
        "poor": ["vỡ", "nổ"],
        "post": ["xót", "rót"],
        "pasta": ["lất", "phất"],
        "poems": ["lém", "nhoem"],
        "poets": ["khoét", "loét"],
        "pieces": ["xanh", "biếc"],
        "peruse": ["khóc", "mếu"],
        "doer": ["mệt", "khỏe"],
        "doers": ["đỏ", "sáng"],
        "goer": ["mệt", "khỏe"],
        "goers": ["đỏ", "sáng"],
        "doors": ["ngố", "cố"],
        "torso": ["ngố", "phố"],
        "terse": ["bế", "cúng"],
        "test": ["bét", "nét"],
        "ajar": ["cẩn", "khẩn"],
        "ajax": ["cẫm", "dẫm"],
        "quasar": ["cẩn", "khẩn"],
        "quasars": ["cấp", "tấp"],
        "exo": ["lẽo", "đẽo"],
        "nginx": ["ngẫm", "nghĩ"],
        "urana": ["luẩn", "quẩn"],
        "uraya": ["bẩy", "đẩy"],
        "ore": ["mệt", "khỏe"],
        "bores": ["đỏ", "sáng"],
        "cores": ["đỏ", "sáng"],
        "dores": ["đỏ", "sáng"],
        "gores": ["đỏ", "sáng"],
        "mores": ["đỏ", "sáng"],
        "nores": ["đỏ", "sáng"],
        "rores": ["đỏ", "sáng"],
        "sores": ["đỏ", "sáng"],
        "vores": ["đỏ", "sáng"],
        "phores": ["đỏ", "sáng"],
        "trores": ["đỏ", "sáng"],
        "boes": ["đỏ", "sáng"],
        "coes": ["đỏ", "sáng"],
        "moes": ["đỏ", "sáng"],
        "poes": ["đỏ", "sáng"],
        "phoes": ["đỏ", "sáng"],
        "soes": ["đỏ", "sáng"],
        "troes": ["đỏ", "sáng"],
        "voes": ["đỏ", "sáng"],
        "boer": ["mệt", "khỏe"],
        "coer": ["mệt", "khỏe"],
        "moer": ["mệt", "khỏe"],
        "noer": ["mệt", "khỏe"],
        "poer": ["mệt", "khỏe"],
        "phoer": ["mệt", "khỏe"],
        "roer": ["mệt", "khỏe"],
        "soer": ["mệt", "khỏe"],
        "troer": ["mệt", "khỏe"],
        "voer": ["mệt", "khỏe"],
        "boers": ["đỏ", "sáng"],
        "coers": ["đỏ", "sáng"],
        "moers": ["đỏ", "sáng"],
        "noers": ["đỏ", "sáng"],
        "poers": ["đỏ", "sáng"],
        "phoers": ["đỏ", "sáng"],
        "roers": ["đỏ", "sáng"],
        "soers": ["đỏ", "sáng"],
        "troers": ["đỏ", "sáng"],
        "voers": ["đỏ", "sáng"],
        "boef": ["đỏ", "hòe"],
        "coef": ["đỏ", "hòe"],
        "doef": ["đỏ", "hòe"],
        "goef": ["đỏ", "hòe"],
        "moef": ["đỏ", "hòe"],
        "noef": ["đỏ", "hòe"],
        "poef": ["đỏ", "hòe"],
        "phoef": ["đỏ", "hòe"],
        "roef": ["đỏ", "hòe"],
        "soef": ["đỏ", "hòe"],
        "troef": ["đỏ", "hòe"],
        "voef": ["đỏ", "hòe"],
        "boex": ["đỏ", "hòe"],
        "coex": ["đỏ", "hòe"],
        "doex": ["đỏ", "hòe"],
        "goex": ["đỏ", "hòe"],
        "moex": ["đỏ", "hòe"],
        "noex": ["đỏ", "hòe"],
        "poex": ["đỏ", "hòe"],
        "phoex": ["đỏ", "hòe"],
        "roex": ["đỏ", "hòe"],
        "soex": ["đỏ", "hòe"],
        "troex": ["đỏ", "hòe"],
        "voex": ["đỏ", "hòe"],
        "boej": ["đỏ", "nhọe"],
        "coej": ["đỏ", "nhọe"],
        "doej": ["đỏ", "nhọe"],
        "goej": ["đỏ", "nhọe"],
        "moej": ["đỏ", "nhọe"],
        "noej": ["đỏ", "nhọe"],
        "poej": ["đỏ", "nhọe"],
        "phoej": ["đỏ", "nhọe"],
        "roej": ["đỏ", "nhọe"],
        "soej": ["đỏ", "nhọe"],
        "troej": ["đỏ", "nhọe"],
        "voej": ["đỏ", "nhọe"],
        "boas": ["xóa", "tóa"],
        "moas": ["xóa", "tóa"],
        "voas": ["xóa", "tóa"],
        "noas": ["xóa", "tóa"],
        "roas": ["xóa", "tóa"],
        "poas": ["xóa", "tóa"],
        "phoas": ["xóa", "tóa"],
        "troas": ["xóa", "tóa"],
        "boaf": ["xòa", "tòa"],
        "roaf": ["xòa", "tòa"],
        "moaf": ["xòa", "tòa"],
        "voaf": ["xòa", "tòa"],
        "noaf": ["xòa", "tòa"],
        "goaf": ["xòa", "tòa"],
        "poaf": ["xòa", "tòa"],
        "phoaf": ["xòa", "tòa"],
        "troaf": ["xòa", "tòa"],
        "moar": ["tỏa", "xõa"],
        "voar": ["tỏa", "xõa"],
        "noar": ["tỏa", "xõa"],
        "goar": ["tỏa", "xõa"],
        "poar": ["tỏa", "xõa"],
        "phoar": ["tỏa", "xõa"],
        "troar": ["tỏa", "xõa"],
        "boax": ["tỏa", "xõa"],
        "roax": ["tỏa", "xõa"],
        "moax": ["tỏa", "xõa"],
        "voax": ["tỏa", "xõa"],
        "goax": ["tỏa", "xõa"],
        "poax": ["tỏa", "xõa"],
        "phoax": ["tỏa", "xõa"],
        "troax": ["tỏa", "xõa"],
        "boaj": ["đọa", "tọa"],
        "roaj": ["đọa", "tọa"],
        "moaj": ["đọa", "tọa"],
        "voaj": ["đọa", "tọa"],
        "noaj": ["đọa", "tọa"],
        "goaj": ["đọa", "tọa"],
        "poaj": ["đọa", "tọa"],
        "phoaj": ["đọa", "tọa"],
        "troaj": ["đọa", "tọa"],
        "koas": ["xóa", "tóa"],
        "koaf": ["xòa", "tòa"],
        "koar": ["tỏa", "xõa"],
        "koax": ["tỏa", "xõa"],
        "koaj": ["đọa", "tọa"],
        "koes": ["đỏ", "sáng"],
        "koef": ["đỏ", "hòe"],
        "koer": ["mệt", "khỏe"],
        "koex": ["đỏ", "hòe"],
        "koej": ["đỏ", "nhọe"],
        "kores": ["đỏ", "sáng"],
        "koers": ["đỏ", "sáng"],
        "boais": ["ngoái", "xoái"],
        "boaif": ["ngoài", "hoài"],
        "boair": ["oải", "thoải"],
        "boaix": ["oải", "xoãi"],
        "boaij": ["loại", "ngoại"],
        "moais": ["ngoái", "xoái"],
        "moaif": ["ngoài", "hoài"],
        "moair": ["oải", "thoải"],
        "moaix": ["oải", "xoãi"],
        "moaij": ["loại", "ngoại"],
        "voais": ["ngoái", "xoái"],
        "voaif": ["ngoài", "hoài"],
        "voair": ["oải", "thoải"],
        "voaix": ["oải", "xoãi"],
        "voaij": ["loại", "ngoại"],
        "noais": ["ngoái", "xoái"],
        "noaif": ["ngoài", "hoài"],
        "noair": ["oải", "thoải"],
        "noaix": ["oải", "xoãi"],
        "noaij": ["loại", "ngoại"],
        "roais": ["ngoái", "xoái"],
        "roaif": ["ngoài", "hoài"],
        "roair": ["oải", "thoải"],
        "roaix": ["oải", "xoãi"],
        "roaij": ["loại", "ngoại"],
        "goais": ["ngoái", "xoái"],
        "goaif": ["ngoài", "hoài"],
        "goair": ["oải", "thoải"],
        "goaix": ["oải", "xoãi"],
        "goaij": ["loại", "ngoại"],
        "poais": ["ngoái", "xoái"],
        "poaif": ["ngoài", "hoài"],
        "poair": ["oải", "thoải"],
        "poaix": ["oải", "xoãi"],
        "poaij": ["loại", "ngoại"],
        "phoais": ["ngoái", "xoái"],
        "phoaif": ["ngoài", "hoài"],
        "phoair": ["oải", "thoải"],
        "phoaix": ["oải", "xoãi"],
        "phoaij": ["loại", "ngoại"],
        "troais": ["ngoái", "xoái"],
        "troaif": ["ngoài", "hoài"],
        "troair": ["oải", "thoải"],
        "troaix": ["oải", "xoãi"],
        "troaij": ["loại", "ngoại"],
        "koais": ["ngoái", "xoái"],
        "koaif": ["ngoài", "hoài"],
        "koair": ["oải", "thoải"],
        "koaix": ["oải", "xoãi"],
        "koaij": ["loại", "ngoại"],
        "doais": ["ngoái", "xoái"],
        "doaif": ["ngoài", "hoài"],
        "doair": ["oải", "thoải"],
        "doaix": ["oải", "xoãi"],
        "doaij": ["loại", "ngoại"],
        "boays": ["xoáy", "ngoáy"],
        "boayf": ["xoáy", "ngoáy"],
        "boayr": ["xoáy", "ngoáy"],
        "boayx": ["xoáy", "ngoáy"],
        "boayj": ["xoáy", "ngoáy"],
        "moays": ["xoáy", "ngoáy"],
        "moayf": ["xoáy", "ngoáy"],
        "moayr": ["xoáy", "ngoáy"],
        "moayx": ["xoáy", "ngoáy"],
        "moayj": ["xoáy", "ngoáy"],
        "voays": ["xoáy", "ngoáy"],
        "voayf": ["xoáy", "ngoáy"],
        "voayr": ["xoáy", "ngoáy"],
        "voayx": ["xoáy", "ngoáy"],
        "voayj": ["xoáy", "ngoáy"],
        "noays": ["xoáy", "ngoáy"],
        "noayf": ["xoáy", "ngoáy"],
        "noayr": ["xoáy", "ngoáy"],
        "noayx": ["xoáy", "ngoáy"],
        "noayj": ["xoáy", "ngoáy"],
        "roays": ["xoáy", "ngoáy"],
        "roayf": ["xoáy", "ngoáy"],
        "roayr": ["xoáy", "ngoáy"],
        "roayx": ["xoáy", "ngoáy"],
        "roayj": ["xoáy", "ngoáy"],
        "goays": ["xoáy", "ngoáy"],
        "goayf": ["xoáy", "ngoáy"],
        "goayr": ["xoáy", "ngoáy"],
        "goayx": ["xoáy", "ngoáy"],
        "goayj": ["xoáy", "ngoáy"],
        "poays": ["xoáy", "ngoáy"],
        "poayf": ["xoáy", "ngoáy"],
        "poayr": ["xoáy", "ngoáy"],
        "poayx": ["xoáy", "ngoáy"],
        "poayj": ["xoáy", "ngoáy"],
        "phoays": ["xoáy", "ngoáy"],
        "phoayf": ["xoáy", "ngoáy"],
        "phoayr": ["xoáy", "ngoáy"],
        "phoayx": ["xoáy", "ngoáy"],
        "phoayj": ["xoáy", "ngoáy"],
        "troays": ["xoáy", "ngoáy"],
        "troayf": ["xoáy", "ngoáy"],
        "troayr": ["xoáy", "ngoáy"],
        "troayx": ["xoáy", "ngoáy"],
        "troayj": ["xoáy", "ngoáy"],
        "koays": ["xoáy", "ngoáy"],
        "koayf": ["xoáy", "ngoáy"],
        "koayr": ["xoáy", "ngoáy"],
        "koayx": ["xoáy", "ngoáy"],
        "koayj": ["xoáy", "ngoáy"],
        "doays": ["xoáy", "ngoáy"],
        "doayf": ["xoáy", "ngoáy"],
        "doayr": ["xoáy", "ngoáy"],
        "doayx": ["xoáy", "ngoáy"],
        "doayj": ["xoáy", "ngoáy"],
        "boaos": ["ngọt", "ngào"],
        "boaof": ["ngọt", "ngào"],
        "boaor": ["ngọt", "ngào"],
        "boaox": ["ngọt", "ngào"],
        "boaoj": ["ngọt", "ngào"],
        "moaos": ["ngọt", "ngào"],
        "moaof": ["ngọt", "ngào"],
        "moaor": ["ngọt", "ngào"],
        "moaox": ["ngọt", "ngào"],
        "moaoj": ["ngọt", "ngào"],
        "voaos": ["ngọt", "ngào"],
        "voaof": ["ngọt", "ngào"],
        "voaor": ["ngọt", "ngào"],
        "voaox": ["ngọt", "ngào"],
        "voaoj": ["ngọt", "ngào"],
        "noaos": ["ngọt", "ngào"],
        "noaof": ["ngọt", "ngào"],
        "noaor": ["ngọt", "ngào"],
        "noaox": ["ngọt", "ngào"],
        "noaoj": ["ngọt", "ngào"],
        "roaos": ["ngọt", "ngào"],
        "roaof": ["ngọt", "ngào"],
        "roaor": ["ngọt", "ngào"],
        "roaox": ["ngọt", "ngào"],
        "roaoj": ["ngọt", "ngào"],
        "goaos": ["ngọt", "ngào"],
        "goaof": ["ngọt", "ngào"],
        "goaor": ["ngọt", "ngào"],
        "goaox": ["ngọt", "ngào"],
        "goaoj": ["ngọt", "ngào"],
        "poaos": ["ngọt", "ngào"],
        "poaof": ["ngọt", "ngào"],
        "poaor": ["ngọt", "ngào"],
        "poaox": ["ngọt", "ngào"],
        "poaoj": ["ngọt", "ngào"],
        "phoaos": ["ngọt", "ngào"],
        "phoaof": ["ngọt", "ngào"],
        "phoaor": ["ngọt", "ngào"],
        "phoaox": ["ngọt", "ngào"],
        "phoaoj": ["ngọt", "ngào"],
        "troaos": ["ngọt", "ngào"],
        "troaof": ["ngọt", "ngào"],
        "troaor": ["ngọt", "ngào"],
        "troaox": ["ngọt", "ngào"],
        "troaoj": ["ngọt", "ngào"],
        "koaos": ["ngọt", "ngào"],
        "koaof": ["ngọt", "ngào"],
        "koaor": ["ngọt", "ngào"],
        "koaox": ["ngọt", "ngào"],
        "koaoj": ["ngọt", "ngào"],
        "doaos": ["ngọt", "ngào"],
        "doaof": ["ngọt", "ngào"],
        "doaor": ["ngọt", "ngào"],
        "doaox": ["ngọt", "ngào"],
        "doaoj": ["ngọt", "ngào"],
        "noaxi": ["oải", "xoãi"],
        "noaxy": ["xoáy", "ngoáy"],
        "noaxo": ["ngọt", "ngào"],
        "goasi": ["ngoái", "xoái"],
        "goasy": ["xoáy", "ngoáy"],
        "goaso": ["ngọt", "ngào"],
        "doasi": ["ngoái", "xoái"],
        "doafi": ["ngoài", "hoài"],
        "doari": ["oải", "thoải"],
        "doaxi": ["oải", "xoãi"],
        "doaji": ["loại", "ngoại"],
        "doasy": ["xoáy", "ngoáy"],
        "doafy": ["xoáy", "ngoáy"],
        "doary": ["xoáy", "ngoáy"],
        "doaxy": ["xoáy", "ngoáy"],
        "doajy": ["xoáy", "ngoáy"],
        "doaso": ["ngọt", "ngào"],
        "doafo": ["ngọt", "ngào"],
        "doaro": ["ngọt", "ngào"],
        "doaxo": ["ngọt", "ngào"],
        "doajo": ["ngọt", "ngào"],
        "boans": ["đoán", "toán"],
        "boanf": ["đoán", "toán"],
        "boanr": ["đoán", "toán"],
        "boanx": ["đoán", "toán"],
        "boanj": ["đoán", "toán"],
        "moanf": ["đoán", "toán"],
        "moanr": ["đoán", "toán"],
        "moanx": ["đoán", "toán"],
        "moanj": ["đoán", "toán"],
        "voans": ["đoán", "toán"],
        "voanf": ["đoán", "toán"],
        "voanr": ["đoán", "toán"],
        "voanx": ["đoán", "toán"],
        "voanj": ["đoán", "toán"],
        "noans": ["đoán", "toán"],
        "noanf": ["đoán", "toán"],
        "noanr": ["đoán", "toán"],
        "noanj": ["đoán", "toán"],
        "roans": ["đoán", "toán"],
        "roanf": ["đoán", "toán"],
        "roanr": ["đoán", "toán"],
        "roanx": ["đoán", "toán"],
        "roanj": ["đoán", "toán"],
        "goans": ["đoán", "toán"],
        "goanf": ["đoán", "toán"],
        "goanr": ["đoán", "toán"],
        "goanx": ["đoán", "toán"],
        "goanj": ["đoán", "toán"],
        "poans": ["đoán", "toán"],
        "poanf": ["đoán", "toán"],
        "poanr": ["đoán", "toán"],
        "poanx": ["đoán", "toán"],
        "poanj": ["đoán", "toán"],
        "phoans": ["đoán", "toán"],
        "phoanf": ["đoán", "toán"],
        "phoanr": ["đoán", "toán"],
        "phoanx": ["đoán", "toán"],
        "phoanj": ["đoán", "toán"],
        "troans": ["đoán", "toán"],
        "troanf": ["đoán", "toán"],
        "troanr": ["đoán", "toán"],
        "troanx": ["đoán", "toán"],
        "troanj": ["đoán", "toán"],
        "koans": ["đoán", "toán"],
        "koanf": ["đoán", "toán"],
        "koanr": ["đoán", "toán"],
        "koanx": ["đoán", "toán"],
        "koanj": ["đoán", "toán"],
        "boams": ["bám", "nhám"],
        "boamf": ["bám", "nhám"],
        "boamr": ["bám", "nhám"],
        "boamx": ["bám", "nhám"],
        "boamj": ["bám", "nhám"],
        "moams": ["bám", "nhám"],
        "moamf": ["bám", "nhám"],
        "moamr": ["bám", "nhám"],
        "moamx": ["bám", "nhám"],
        "moamj": ["bám", "nhám"],
        "voams": ["bám", "nhám"],
        "voamf": ["bám", "nhám"],
        "voamr": ["bám", "nhám"],
        "voamx": ["bám", "nhám"],
        "voamj": ["bám", "nhám"],
        "noams": ["bám", "nhám"],
        "noamf": ["bám", "nhám"],
        "noamr": ["bám", "nhám"],
        "noamx": ["bám", "nhám"],
        "noamj": ["bám", "nhám"],
        "roamf": ["bám", "nhám"],
        "roamr": ["bám", "nhám"],
        "roamx": ["bám", "nhám"],
        "roamj": ["bám", "nhám"],
        "goams": ["bám", "nhám"],
        "goamf": ["bám", "nhám"],
        "goamr": ["bám", "nhám"],
        "goamx": ["bám", "nhám"],
        "goamj": ["bám", "nhám"],
        "poams": ["bám", "nhám"],
        "poamf": ["bám", "nhám"],
        "poamr": ["bám", "nhám"],
        "poamx": ["bám", "nhám"],
        "poamj": ["bám", "nhám"],
        "phoams": ["bám", "nhám"],
        "phoamf": ["bám", "nhám"],
        "phoamr": ["bám", "nhám"],
        "phoamx": ["bám", "nhám"],
        "phoamj": ["bám", "nhám"],
        "troams": ["bám", "nhám"],
        "troamf": ["bám", "nhám"],
        "troamr": ["bám", "nhám"],
        "troamx": ["bám", "nhám"],
        "troamj": ["bám", "nhám"],
        "koams": ["bám", "nhám"],
        "koamf": ["bám", "nhám"],
        "koamr": ["bám", "nhám"],
        "koamx": ["bám", "nhám"],
        "koamj": ["bám", "nhám"],
        "goasm": ["bám", "nhám"],
        "noaxm": ["bám", "nhám"],
        "noxam": ["bám", "nhám"],
        "goasn": ["đoán", "toán"],
        "trojan": ["đoán", "toán"],
        "boangs": ["loáng", "thoáng"],
        "boangf": ["loáng", "thoáng"],
        "boangr": ["loáng", "thoáng"],
        "boangx": ["loáng", "thoáng"],
        "boangj": ["loáng", "thoáng"],
        "moangs": ["loáng", "thoáng"],
        "moangf": ["loáng", "thoáng"],
        "moangr": ["loáng", "thoáng"],
        "moangx": ["loáng", "thoáng"],
        "moangj": ["loáng", "thoáng"],
        "voangs": ["loáng", "thoáng"],
        "voangf": ["loáng", "thoáng"],
        "voangr": ["loáng", "thoáng"],
        "voangx": ["loáng", "thoáng"],
        "voangj": ["loáng", "thoáng"],
        "noangs": ["loáng", "thoáng"],
        "noangf": ["loáng", "thoáng"],
        "noangr": ["loáng", "thoáng"],
        "noangx": ["loáng", "thoáng"],
        "noangj": ["loáng", "thoáng"],
        "roangs": ["loáng", "thoáng"],
        "roangf": ["loáng", "thoáng"],
        "roangr": ["loáng", "thoáng"],
        "roangx": ["loáng", "thoáng"],
        "roangj": ["loáng", "thoáng"],
        "goangs": ["loáng", "thoáng"],
        "goangf": ["loáng", "thoáng"],
        "goangr": ["loáng", "thoáng"],
        "goangx": ["loáng", "thoáng"],
        "goangj": ["loáng", "thoáng"],
        "poangs": ["loáng", "thoáng"],
        "poangf": ["loáng", "thoáng"],
        "poangr": ["loáng", "thoáng"],
        "poangx": ["loáng", "thoáng"],
        "poangj": ["loáng", "thoáng"],
        "phoangs": ["loáng", "thoáng"],
        "phoangf": ["loáng", "thoáng"],
        "phoangr": ["loáng", "thoáng"],
        "phoangx": ["loáng", "thoáng"],
        "phoangj": ["loáng", "thoáng"],
        "troangs": ["loáng", "thoáng"],
        "troangf": ["loáng", "thoáng"],
        "troangr": ["loáng", "thoáng"],
        "troangx": ["loáng", "thoáng"],
        "troangj": ["loáng", "thoáng"],
        "koangs": ["loáng", "thoáng"],
        "koangf": ["loáng", "thoáng"],
        "koangr": ["loáng", "thoáng"],
        "koangx": ["loáng", "thoáng"],
        "koangj": ["loáng", "thoáng"],
        "boanhs": ["oánh", "hoành"],
        "boanhf": ["oánh", "hoành"],
        "boanhr": ["oánh", "hoành"],
        "boanhx": ["oánh", "hoành"],
        "boanhj": ["oánh", "hoành"],
        "moanhs": ["oánh", "hoành"],
        "moanhf": ["oánh", "hoành"],
        "moanhr": ["oánh", "hoành"],
        "moanhx": ["oánh", "hoành"],
        "moanhj": ["oánh", "hoành"],
        "voanhs": ["oánh", "hoành"],
        "voanhf": ["oánh", "hoành"],
        "voanhr": ["oánh", "hoành"],
        "voanhx": ["oánh", "hoành"],
        "voanhj": ["oánh", "hoành"],
        "noanhs": ["oánh", "hoành"],
        "noanhf": ["oánh", "hoành"],
        "noanhr": ["oánh", "hoành"],
        "noanhx": ["oánh", "hoành"],
        "noanhj": ["oánh", "hoành"],
        "roanhs": ["oánh", "hoành"],
        "roanhf": ["oánh", "hoành"],
        "roanhr": ["oánh", "hoành"],
        "roanhx": ["oánh", "hoành"],
        "roanhj": ["oánh", "hoành"],
        "goanhs": ["oánh", "hoành"],
        "goanhf": ["oánh", "hoành"],
        "goanhr": ["oánh", "hoành"],
        "goanhx": ["oánh", "hoành"],
        "goanhj": ["oánh", "hoành"],
        "poanhs": ["oánh", "hoành"],
        "poanhf": ["oánh", "hoành"],
        "poanhr": ["oánh", "hoành"],
        "poanhx": ["oánh", "hoành"],
        "poanhj": ["oánh", "hoành"],
        "phoanhs": ["oánh", "hoành"],
        "phoanhf": ["oánh", "hoành"],
        "phoanhr": ["oánh", "hoành"],
        "phoanhx": ["oánh", "hoành"],
        "phoanhj": ["oánh", "hoành"],
        "troanhs": ["oánh", "hoành"],
        "troanhf": ["oánh", "hoành"],
        "troanhr": ["oánh", "hoành"],
        "troanhx": ["oánh", "hoành"],
        "troanhj": ["oánh", "hoành"],
        "koanhs": ["oánh", "hoành"],
        "koanhf": ["oánh", "hoành"],
        "koanhr": ["oánh", "hoành"],
        "koanhx": ["oánh", "hoành"],
        "koanhj": ["oánh", "hoành"],
        "boatj": ["toát", "thoát"],
        "moatj": ["toát", "thoát"],
        "voats": ["toát", "thoát"],
        "voatj": ["toát", "thoát"],
        "noats": ["toát", "thoát"],
        "noatj": ["toát", "thoát"],
        "roats": ["toát", "thoát"],
        "roatj": ["toát", "thoát"],
        "goatj": ["toát", "thoát"],
        "poats": ["toát", "thoát"],
        "poatj": ["toát", "thoát"],
        "phoats": ["toát", "thoát"],
        "phoatj": ["toát", "thoát"],
        "troats": ["toát", "thoát"],
        "troatj": ["toát", "thoát"],
        "koats": ["toát", "thoát"],
        "koatj": ["toát", "thoát"],
        "boaps": ["táp", "nháp"],
        "boapj": ["táp", "nháp"],
        "moaps": ["táp", "nháp"],
        "moapj": ["táp", "nháp"],
        "voaps": ["táp", "nháp"],
        "voapj": ["táp", "nháp"],
        "noaps": ["táp", "nháp"],
        "noapj": ["táp", "nháp"],
        "roaps": ["táp", "nháp"],
        "roapj": ["táp", "nháp"],
        "goaps": ["táp", "nháp"],
        "goapj": ["táp", "nháp"],
        "poaps": ["táp", "nháp"],
        "poapj": ["táp", "nháp"],
        "phoaps": ["táp", "nháp"],
        "phoapj": ["táp", "nháp"],
        "troaps": ["táp", "nháp"],
        "troapj": ["táp", "nháp"],
        "koaps": ["táp", "nháp"],
        "koapj": ["táp", "nháp"],
        "boachs": ["tách", "vách"],
        "boachj": ["tách", "vách"],
        "moachs": ["tách", "vách"],
        "moachj": ["tách", "vách"],
        "voachs": ["tách", "vách"],
        "voachj": ["tách", "vách"],
        "noachs": ["tách", "vách"],
        "noachj": ["tách", "vách"],
        "roachs": ["tách", "vách"],
        "roachj": ["tách", "vách"],
        "goachs": ["tách", "vách"],
        "goachj": ["tách", "vách"],
        "poachs": ["tách", "vách"],
        "poachj": ["tách", "vách"],
        "phoachs": ["tách", "vách"],
        "phoachj": ["tách", "vách"],
        "troachs": ["tách", "vách"],
        "troachj": ["tách", "vách"],
        "koachs": ["tách", "vách"],
        "koachj": ["tách", "vách"],
        "boacs": ["bác", "khác"],
        "boacj": ["bác", "khác"],
        "moacs": ["bác", "khác"],
        "moacj": ["bác", "khác"],
        "voacs": ["bác", "khác"],
        "voacj": ["bác", "khác"],
        "noacs": ["bác", "khác"],
        "noacj": ["bác", "khác"],
        "roacs": ["bác", "khác"],
        "roacj": ["bác", "khác"],
        "goacs": ["bác", "khác"],
        "goacj": ["bác", "khác"],
        "poacs": ["bác", "khác"],
        "poacj": ["bác", "khác"],
        "phoacs": ["bác", "khác"],
        "phoacj": ["bác", "khác"],
        "troacs": ["bác", "khác"],
        "troacj": ["bác", "khác"],
        "koacs": ["bác", "khác"],
        "koacj": ["bác", "khác"],
        "boets": ["khoét", "toét"],
        "boetj": ["khoét", "toét"],
        "moets": ["khoét", "toét"],
        "moetj": ["khoét", "toét"],
        "voets": ["khoét", "toét"],
        "voetj": ["khoét", "toét"],
        "noets": ["khoét", "toét"],
        "noetj": ["khoét", "toét"],
        "roets": ["khoét", "toét"],
        "roetj": ["khoét", "toét"],
        "goets": ["khoét", "toét"],
        "goetj": ["khoét", "toét"],
        "poetj": ["khoét", "toét"],
        "phoets": ["khoét", "toét"],
        "phoetj": ["khoét", "toét"],
        "troets": ["khoét", "toét"],
        "troetj": ["khoét", "toét"],
        "koets": ["khoét", "toét"],
        "koetj": ["khoét", "toét"],
        "doets": ["khoét", "toét"],
        "doetj": ["khoét", "toét"],
        "boeps": ["bẹp", "nhẹp"],
        "boepj": ["bẹp", "nhẹp"],
        "moeps": ["bẹp", "nhẹp"],
        "moepj": ["bẹp", "nhẹp"],
        "voeps": ["bẹp", "nhẹp"],
        "voepj": ["bẹp", "nhẹp"],
        "noeps": ["bẹp", "nhẹp"],
        "noepj": ["bẹp", "nhẹp"],
        "roeps": ["bẹp", "nhẹp"],
        "roepj": ["bẹp", "nhẹp"],
        "goeps": ["bẹp", "nhẹp"],
        "goepj": ["bẹp", "nhẹp"],
        "poeps": ["bẹp", "nhẹp"],
        "poepj": ["bẹp", "nhẹp"],
        "phoeps": ["bẹp", "nhẹp"],
        "phoepj": ["bẹp", "nhẹp"],
        "troeps": ["bẹp", "nhẹp"],
        "troepj": ["bẹp", "nhẹp"],
        "koeps": ["bẹp", "nhẹp"],
        "koepj": ["bẹp", "nhẹp"],
        "doeps": ["bẹp", "nhẹp"],
        "doepj": ["bẹp", "nhẹp"],
        "boecs": ["hoéc", "ngoéc"],
        "boecj": ["hoéc", "ngoéc"],
        "moecs": ["hoéc", "ngoéc"],
        "moecj": ["hoéc", "ngoéc"],
        "voecs": ["hoéc", "ngoéc"],
        "voecj": ["hoéc", "ngoéc"],
        "noecs": ["hoéc", "ngoéc"],
        "noecj": ["hoéc", "ngoéc"],
        "roecs": ["hoéc", "ngoéc"],
        "roecj": ["hoéc", "ngoéc"],
        "goecs": ["hoéc", "ngoéc"],
        "goecj": ["hoéc", "ngoéc"],
        "poecs": ["hoéc", "ngoéc"],
        "poecj": ["hoéc", "ngoéc"],
        "phoecs": ["hoéc", "ngoéc"],
        "phoecj": ["hoéc", "ngoéc"],
        "troecs": ["hoéc", "ngoéc"],
        "troecj": ["hoéc", "ngoéc"],
        "koecs": ["hoéc", "ngoéc"],
        "koecj": ["hoéc", "ngoéc"],
        "doecs": ["hoéc", "ngoéc"],
        "doecj": ["hoéc", "ngoéc"],
        "boeos": ["ngoéo", "ngoẹo"],
        "boeof": ["ngoéo", "ngoẹo"],
        "boeor": ["ngoéo", "ngoẹo"],
        "boeox": ["ngoéo", "ngoẹo"],
        "boeoj": ["ngoéo", "ngoẹo"],
        "moeos": ["ngoéo", "ngoẹo"],
        "moeof": ["ngoéo", "ngoẹo"],
        "moeor": ["ngoéo", "ngoẹo"],
        "moeox": ["ngoéo", "ngoẹo"],
        "moeoj": ["ngoéo", "ngoẹo"],
        "voeos": ["ngoéo", "ngoẹo"],
        "voeof": ["ngoéo", "ngoẹo"],
        "voeor": ["ngoéo", "ngoẹo"],
        "voeox": ["ngoéo", "ngoẹo"],
        "voeoj": ["ngoéo", "ngoẹo"],
        "noeos": ["ngoéo", "ngoẹo"],
        "noeof": ["ngoéo", "ngoẹo"],
        "noeor": ["ngoéo", "ngoẹo"],
        "noeox": ["ngoéo", "ngoẹo"],
        "noeoj": ["ngoéo", "ngoẹo"],
        "roeos": ["ngoéo", "ngoẹo"],
        "roeof": ["ngoéo", "ngoẹo"],
        "roeor": ["ngoéo", "ngoẹo"],
        "roeox": ["ngoéo", "ngoẹo"],
        "roeoj": ["ngoéo", "ngoẹo"],
        "goeos": ["ngoéo", "ngoẹo"],
        "goeof": ["ngoéo", "ngoẹo"],
        "goeor": ["ngoéo", "ngoẹo"],
        "goeox": ["ngoéo", "ngoẹo"],
        "goeoj": ["ngoéo", "ngoẹo"],
        "poeos": ["ngoéo", "ngoẹo"],
        "poeof": ["ngoéo", "ngoẹo"],
        "poeor": ["ngoéo", "ngoẹo"],
        "poeox": ["ngoéo", "ngoẹo"],
        "poeoj": ["ngoéo", "ngoẹo"],
        "phoeos": ["ngoéo", "ngoẹo"],
        "phoeof": ["ngoéo", "ngoẹo"],
        "phoeor": ["ngoéo", "ngoẹo"],
        "phoeox": ["ngoéo", "ngoẹo"],
        "phoeoj": ["ngoéo", "ngoẹo"],
        "troeos": ["ngoéo", "ngoẹo"],
        "troeof": ["ngoéo", "ngoẹo"],
        "troeor": ["ngoéo", "ngoẹo"],
        "troeox": ["ngoéo", "ngoẹo"],
        "troeoj": ["ngoéo", "ngoẹo"],
        "koeos": ["ngoéo", "ngoẹo"],
        "koeof": ["ngoéo", "ngoẹo"],
        "koeor": ["ngoéo", "ngoẹo"],
        "koeox": ["ngoéo", "ngoẹo"],
        "koeoj": ["ngoéo", "ngoẹo"],
        "doeos": ["ngoéo", "ngoẹo"],
        "doeof": ["ngoéo", "ngoẹo"],
        "doeor": ["ngoéo", "ngoẹo"],
        "doeox": ["ngoéo", "ngoẹo"],
        "doeoj": ["ngoéo", "ngoẹo"],
        "boens": ["hoen", "nhoèn"],
        "boenf": ["hoen", "nhoèn"],
        "boenr": ["hoen", "nhoèn"],
        "boenx": ["hoen", "nhoèn"],
        "boenj": ["hoen", "nhoèn"],
        "moens": ["hoen", "nhoèn"],
        "moenf": ["hoen", "nhoèn"],
        "moenr": ["hoen", "nhoèn"],
        "moenx": ["hoen", "nhoèn"],
        "moenj": ["hoen", "nhoèn"],
        "voens": ["hoen", "nhoèn"],
        "voenf": ["hoen", "nhoèn"],
        "voenr": ["hoen", "nhoèn"],
        "voenx": ["hoen", "nhoèn"],
        "voenj": ["hoen", "nhoèn"],
        "noens": ["hoen", "nhoèn"],
        "noenf": ["hoen", "nhoèn"],
        "noenr": ["hoen", "nhoèn"],
        "noenx": ["hoen", "nhoèn"],
        "noenj": ["hoen", "nhoèn"],
        "roens": ["hoen", "nhoèn"],
        "roenf": ["hoen", "nhoèn"],
        "roenr": ["hoen", "nhoèn"],
        "roenx": ["hoen", "nhoèn"],
        "roenj": ["hoen", "nhoèn"],
        "goens": ["hoen", "nhoèn"],
        "goenf": ["hoen", "nhoèn"],
        "goenr": ["hoen", "nhoèn"],
        "goenx": ["hoen", "nhoèn"],
        "goenj": ["hoen", "nhoèn"],
        "poens": ["hoen", "nhoèn"],
        "poenf": ["hoen", "nhoèn"],
        "poenr": ["hoen", "nhoèn"],
        "poenx": ["hoen", "nhoèn"],
        "poenj": ["hoen", "nhoèn"],
        "phoens": ["hoen", "nhoèn"],
        "phoenf": ["hoen", "nhoèn"],
        "phoenr": ["hoen", "nhoèn"],
        "phoenx": ["hoen", "nhoèn"],
        "phoenj": ["hoen", "nhoèn"],
        "troens": ["hoen", "nhoèn"],
        "troenf": ["hoen", "nhoèn"],
        "troenr": ["hoen", "nhoèn"],
        "troenx": ["hoen", "nhoèn"],
        "troenj": ["hoen", "nhoèn"],
        "koens": ["hoen", "nhoèn"],
        "koenf": ["hoen", "nhoèn"],
        "koenr": ["hoen", "nhoèn"],
        "koenx": ["hoen", "nhoèn"],
        "koenj": ["hoen", "nhoèn"],
        "doens": ["hoen", "nhoèn"],
        "doenf": ["hoen", "nhoèn"],
        "doenr": ["hoen", "nhoèn"],
        "doenx": ["hoen", "nhoèn"],
        "doenj": ["hoen", "nhoèn"],
        "boems": ["thòm", "thèm"],
        "boemf": ["thòm", "thèm"],
        "boemr": ["thòm", "thèm"],
        "boemx": ["thòm", "thèm"],
        "boemj": ["thòm", "thèm"],
        "moems": ["thòm", "thèm"],
        "moemf": ["thòm", "thèm"],
        "moemr": ["thòm", "thèm"],
        "moemx": ["thòm", "thèm"],
        "moemj": ["thòm", "thèm"],
        "voems": ["thòm", "thèm"],
        "voemf": ["thòm", "thèm"],
        "voemr": ["thòm", "thèm"],
        "voemx": ["thòm", "thèm"],
        "voemj": ["thòm", "thèm"],
        "noems": ["thòm", "thèm"],
        "noemf": ["thòm", "thèm"],
        "noemr": ["thòm", "thèm"],
        "noemx": ["thòm", "thèm"],
        "noemj": ["thòm", "thèm"],
        "roems": ["thòm", "thèm"],
        "roemf": ["thòm", "thèm"],
        "roemr": ["thòm", "thèm"],
        "roemx": ["thòm", "thèm"],
        "roemj": ["thòm", "thèm"],
        "goems": ["thòm", "thèm"],
        "goemf": ["thòm", "thèm"],
        "goemr": ["thòm", "thèm"],
        "goemx": ["thòm", "thèm"],
        "goemj": ["thòm", "thèm"],
        "poemf": ["thòm", "thèm"],
        "poemr": ["thòm", "thèm"],
        "poemx": ["thòm", "thèm"],
        "poemj": ["thòm", "thèm"],
        "phoems": ["thòm", "thèm"],
        "phoemf": ["thòm", "thèm"],
        "phoemr": ["thòm", "thèm"],
        "phoemx": ["thòm", "thèm"],
        "phoemj": ["thòm", "thèm"],
        "troems": ["thòm", "thèm"],
        "troemf": ["thòm", "thèm"],
        "troemr": ["thòm", "thèm"],
        "troemx": ["thòm", "thèm"],
        "troemj": ["thòm", "thèm"],
        "koems": ["thòm", "thèm"],
        "koemf": ["thòm", "thèm"],
        "koemr": ["thòm", "thèm"],
        "koemx": ["thòm", "thèm"],
        "koemj": ["thòm", "thèm"],
        "doems": ["thòm", "thèm"],
        "doemf": ["thòm", "thèm"],
        "doemr": ["thòm", "thèm"],
        "doemx": ["thòm", "thèm"],
        "doemj": ["thòm", "thèm"],
        "coens": ["hoen", "nhoèn"],
        "coenf": ["hoen", "nhoèn"],
        "coenr": ["hoen", "nhoèn"],
        "coenx": ["hoen", "nhoèn"],
        "coenj": ["hoen", "nhoèn"],
        "soens": ["hoen", "nhoèn"],
        "soenf": ["hoen", "nhoèn"],
        "soenr": ["hoen", "nhoèn"],
        "soenx": ["hoen", "nhoèn"],
        "soenj": ["hoen", "nhoèn"],
        "coems": ["thòm", "thèm"],
        "coemf": ["thòm", "thèm"],
        "coemr": ["thòm", "thèm"],
        "coemx": ["thòm", "thèm"],
        "coemj": ["thòm", "thèm"],
        "soems": ["thòm", "thèm"],
        "soemf": ["thòm", "thèm"],
        "soemr": ["thòm", "thèm"],
        "soemx": ["thòm", "thèm"],
        "soemj": ["thòm", "thèm"],
        "coets": ["khoét", "toét"],
        "coetj": ["khoét", "toét"],
        "soets": ["khoét", "toét"],
        "soetj": ["khoét", "toét"],
        "coeps": ["bẹp", "nhẹp"],
        "coepj": ["bẹp", "nhẹp"],
        "soeps": ["bẹp", "nhẹp"],
        "soepj": ["bẹp", "nhẹp"],
        "coecs": ["hoéc", "ngoéc"],
        "coecj": ["hoéc", "ngoéc"],
        "soecs": ["hoéc", "ngoéc"],
        "soecj": ["hoéc", "ngoéc"],
        "goast": ["toát", "thoát"],
        "goasp": ["toát", "thoát"],
        "goasc": ["khác", "toác"],
        "sosen": ["hoen", "nhoèn"],
        "doesn": ["hoen", "nhoèn"],
        "howa": ["xóa", "tóa"],
        "dowa": ["xóa", "tóa"],
        "nowa": ["xóa", "tóa"],
        "sowa": ["xóa", "tóa"],
        "towa": ["xóa", "tóa"],
        "rowa": ["xóa", "tóa"],
        "gifi": ["cái", "gì"],
        "gisi": ["cái", "gì"],
        "giji": ["cái", "gì"],
        "chixe": ["vui", "vẻ"],
        "dues": ["vui", "vẻ"],
        "hues": ["vui", "vẻ"],
        "sues": ["vui", "vẻ"],
        "rues": ["vui", "vẻ"],
        "tues": ["vui", "vẻ"],
        "ties": ["vui", "vẻ"],
        "dies": ["vui", "vẻ"],
        "lies": ["vui", "vẻ"],
        "vies": ["vui", "vẻ"],
        "hies": ["vui", "vẻ"],
        "pies": ["vui", "vẻ"],
        "mise": ["vui", "vẻ"],
        "nise": ["vui", "vẻ"],
        "kise": ["vui", "vẻ"],
        "hise": ["vui", "vẻ"],
        "bise": ["vui", "vẻ"],
        "tise": ["vui", "vẻ"],
        "dise": ["vui", "vẻ"],
        "sise": ["vui", "vẻ"],
        "chise": ["vui", "vẻ"],
        "lise": ["vui", "vẻ"],
        "vise": ["vui", "vẻ"],
        "kife": ["vui", "vẻ"],
        "mife": ["vui", "vẻ"],
        "nife": ["vui", "vẻ"],
        "hife": ["vui", "vẻ"],
        "sife": ["vui", "vẻ"],
        "tife": ["vui", "vẻ"],
        "bife": ["vui", "vẻ"],
        "dife": ["vui", "vẻ"],
        "chife": ["vui", "vẻ"],
        "rife": ["vui", "vẻ"],
        "kire": ["vui", "vẻ"],
        "nire": ["vui", "vẻ"],
        "bire": ["vui", "vẻ"],
        "rire": ["vui", "vẻ"],
        "chire": ["vui", "vẻ"],
        "lire": ["vui", "vẻ"],
        "vire": ["vui", "vẻ"],
        "kije": ["vui", "vẻ"],
        "mije": ["vui", "vẻ"],
        "nije": ["vui", "vẻ"],
        "hije": ["vui", "vẻ"],
        "sije": ["vui", "vẻ"],
        "tije": ["vui", "vẻ"],
        "bije": ["vui", "vẻ"],
        "dije": ["vui", "vẻ"],
        "rije": ["vui", "vẻ"],
        "chije": ["vui", "vẻ"],
        "nuse": ["vui", "vẻ"],
        "suse": ["vui", "vẻ"],
        "buse": ["vui", "vẻ"],
        "duse": ["vui", "vẻ"],
        "guse": ["vui", "vẻ"],
        "huse": ["vui", "vẻ"],
        "muse": ["vui", "vẻ"],
        "puse": ["vui", "vẻ"],
        "ruse": ["vui", "vẻ"],
        "tuse": ["vui", "vẻ"],
        "chuse": ["vui", "vẻ"],
        "bufe": ["vui", "vẻ"],
        "dufe": ["vui", "vẻ"],
        "gufe": ["vui", "vẻ"],
        "hufe": ["vui", "vẻ"],
        "mufe": ["vui", "vẻ"],
        "nufe": ["vui", "vẻ"],
        "rufe": ["vui", "vẻ"],
        "sufe": ["vui", "vẻ"],
        "tufe": ["vui", "vẻ"],
        "chufe": ["vui", "vẻ"],
        "bure": ["vui", "vẻ"],
        "cure": ["vui", "vẻ"],
        "dure": ["vui", "vẻ"],
        "gure": ["vui", "vẻ"],
        "hure": ["vui", "vẻ"],
        "lure": ["vui", "vẻ"],
        "mure": ["vui", "vẻ"],
        "nure": ["vui", "vẻ"],
        "pure": ["vui", "vẻ"],
        "rure": ["vui", "vẻ"],
        "sure": ["vui", "vẻ"],
        "ture": ["vui", "vẻ"],
        "chure": ["vui", "vẻ"],
        "luxe": ["vui", "vẻ"],
        "buje": ["vui", "vẻ"],
        "duje": ["vui", "vẻ"],
        "guje": ["vui", "vẻ"],
        "huje": ["vui", "vẻ"],
        "muje": ["vui", "vẻ"],
        "nuje": ["vui", "vẻ"],
        "ruje": ["vui", "vẻ"],
        "suje": ["vui", "vẻ"],
        "tuje": ["vui", "vẻ"],
        "chuje": ["vui", "vẻ"],
        "kuse": ["vui", "vẻ"],
        "kufe": ["vui", "vẻ"],
        "kure": ["vui", "vẻ"],
        "kuxe": ["vui", "vẻ"],
        "kuje": ["vui", "vẻ"],
        "pufe": ["vui", "vẻ"],
        "puxe": ["vui", "vẻ"],
        "puje": ["vui", "vẻ"],
        "dire": ["vui", "vẻ"],
        "hire": ["vui", "vẻ"],
        "life": ["vui", "vẻ"],
        "mire": ["vui", "vẻ"],
        "sire": ["vui", "vẻ"],
        "tire": ["vui", "vẻ"],
        "rise": ["vui", "vẻ"],
        "pise": ["vui", "vẻ"],
        "pife": ["vui", "vẻ"],
        "pire": ["vui", "vẻ"],
        "pixe": ["vui", "vẻ"],
        "pije": ["vui", "vẻ"],
        "kans": ["bàn", "đàn"],
        "kanf": ["bàn", "đàn"],
        "kanr": ["bàn", "đàn"],
        "kanx": ["bàn", "đàn"],
        "kanj": ["bàn", "đàn"],
        "pans": ["bàn", "đàn"],
        "panf": ["bàn", "đàn"],
        "panr": ["bàn", "đàn"],
        "panx": ["bàn", "đàn"],
        "panj": ["bàn", "đàn"],
        "kams": ["bám", "nhám"],
        "kamf": ["bám", "nhám"],
        "kamr": ["bám", "nhám"],
        "kamx": ["bám", "nhám"],
        "kamj": ["bám", "nhám"],
        "pams": ["bám", "nhám"],
        "pamf": ["bám", "nhám"]
    ]

    private static func matchesIeUeStemDelayedDiacriticUnlatch(
        wordRawKeys: [Character],
        character: Character
    ) -> Bool {
        let lowerWord = String(wordRawKeys).lowercased()
        let c = character.lowercased()
        let ieStems = ["mixers", "chiefs", "tiers", "biers", "piers", "hires", "tires", "mires", "sires", "miser", "mixer", "mixes", "sixes", "trier", "tries", "pier", "pies"]
        for stem in ieStems where lowerWord.hasPrefix(stem) {
            let tail = String(lowerWord.dropFirst(stem.count))
            guard !tail.isEmpty else { continue }
            if c == "e" && matchesDiphthongCodaTail(tail, nonStopCodas: ["", "u", "m", "n", "ng"], stopCodas: ["c", "t", "p"], allowD: false) {
                return true
            }
            if "sj".contains(c)
                && (["c", "p", "t"].contains(tail)
                    || matchesDiphthongCodaTail(tail, nonStopCodas: [], stopCodas: ["c", "t", "p"], requiredDiacritics: "e", allowToneOverride: false, allowD: false)) {
                return true
            }
        }
        let ueStems = ["purses", "curses", "cures", "curse", "nurse", "purse", "muses", "ruses", "tuxes"]
        for stem in ueStems where lowerWord.hasPrefix(stem) {
            let tail = String(lowerWord.dropFirst(stem.count))
            guard !tail.isEmpty else { continue }
            if c == "e" && matchesDiphthongCodaTail(tail, nonStopCodas: ["", "m", "n", "nh"], stopCodas: ["c", "p", "t", "ch"], allowD: false) {
                return true
            }
            if "sj".contains(c)
                && matchesDiphthongCodaTail(tail, nonStopCodas: [], stopCodas: ["c", "p", "t", "ch"], requiredDiacritics: "e", allowToneOverride: false, allowD: false) {
                return true
            }
        }
        return false
    }

    private static func matchesUyOaOeClusterUnlatch(
        wordRawKeys: [Character],
        prefix2: String,
        rhymeAfterOnset: [String],
        character: Character
    ) -> Bool {
        guard let firstKey = wordRawKeys.first?.lowercased().first,
              !"wfjz".contains(firstKey) else {
            return false
        }
        let c = character.lowercased()
        let isDOnset = firstKey == "d"

        // 1. 'qu' onset + 'yê' / 'uy' stop-coda & non-stop-coda unlatch (e.g. quyretes / quryetes -> quyết, quyretej / quryetej -> quyệt, quyrense / quryense -> quyến, quyrts / quryts -> quýt)
        if prefix2 == "qu" && rhymeAfterOnset.count >= 3 {
            if ((rhymeAfterOnset[0] == "y" && "rfx".contains(rhymeAfterOnset[1]))
                || ("rfx".contains(rhymeAfterOnset[0]) && rhymeAfterOnset[1] == "y"))
                && ["t", "p", "ch"].contains(rhymeAfterOnset[2...].joined())
                && "sj".contains(c) {
                return true
            }
            if rhymeAfterOnset.count >= 4
                && ((rhymeAfterOnset[0] == "y"
                    && (("rsfjx".contains(rhymeAfterOnset[1]) && rhymeAfterOnset[2] == "e")
                        || (rhymeAfterOnset[1] == "e" && "rsfjx".contains(rhymeAfterOnset[2]))))
                    || ("rsfjx".contains(rhymeAfterOnset[0]) && rhymeAfterOnset[1] == "y" && rhymeAfterOnset[2] == "e")) {
                let tail = rhymeAfterOnset[3...].joined()
                if c == "e" && matchesDiphthongCodaTail(tail, nonStopCodas: ["n"], stopCodas: ["t", "c", "ch"], allowD: false) {
                    return true
                }
                if "sj".contains(c) && matchesDiphthongCodaTail(tail, nonStopCodas: [], stopCodas: ["t", "c", "ch"], requiredDiacritics: "e", allowToneOverride: false, allowD: false) {
                    return true
                }
            }
        }

        let effRhyme = "ou".contains(firstKey) ? wordRawKeys.map({ $0.lowercased() }) : rhymeAfterOnset
        guard effRhyme.count >= 4 else { return false }

        // 2. 'uy' + stop-coda ('t', 'p', 'ch') + tone override ('s', 'j') (e.g. tuyrts -> tuýt, tuyrtj -> tuỵt, suyrts -> suýt, huyrchs -> huých, uyrchs -> uých)
        if effRhyme[0] == "u"
            && ((effRhyme[1] == "y" && "rfx".contains(effRhyme[2]))
                || ("rfx".contains(effRhyme[1]) && effRhyme[2] == "y")) {
            let tail = effRhyme[3...].joined()
            if "sj".contains(c) && ["t", "p", "ch"].contains(tail) {
                return true
            }
        }

        // 3. 'uyê' + coda ('n', 't', 'c', 'ch') + tone override & delayed 'e' (e.g. tuyretes -> tuyết, tuyretej -> tuyệt, chuyrenje -> chuyện, nguyrenxe -> nguyễn)
        if effRhyme.count >= 5
            && effRhyme[0] == "u"
            && ((effRhyme[1] == "y" && (("rsfjx".contains(effRhyme[2]) && effRhyme[3] == "e") || (effRhyme[2] == "e" && "rsfjx".contains(effRhyme[3]))))
                || ("rsfjx".contains(effRhyme[1]) && effRhyme[2] == "y" && effRhyme[3] == "e")) {
            let tail = effRhyme[4...].joined()
            if c == "e" && (tail == "d" || matchesDiphthongCodaTail(tail, nonStopCodas: ["n"], stopCodas: ["t", "c", "ch"], allowD: isDOnset)) {
                return true
            }
            if "sj".contains(c) && matchesDiphthongCodaTail(tail, nonStopCodas: [], stopCodas: ["t", "c", "ch"], requiredDiacritics: "e", allowToneOverride: false, allowD: isDOnset) {
                return true
            }
            if isDOnset && c == "d" && matchesDiphthongCodaTail(tail, nonStopCodas: ["n"], stopCodas: ["t", "c", "ch"], requiredDiacritics: "e", allowToneOverride: true, allowD: false) {
                return true
            }
        }

        // 4. 'oa' / 'oă' + stop-coda ('c', 'p', 't', 'ch') + tone override ('s', 'j') & optional 'w' (e.g. hoarts -> hoát, hoartj -> hoạt, hoartws -> hoắt, ngoarcwj -> ngoặc, oarchs -> oách)
        if effRhyme[0] == "o"
            && (("rfx".contains(effRhyme[1]) && effRhyme[2] == "a")
                || (effRhyme[1] == "a" && "rfx".contains(effRhyme[2]))) {
            let tail = effRhyme[3...].joined()
            let oaStopCodas: Set<String> = ["c", "p", "t", "ch"]
            if c == "w" && matchesDiphthongCodaTail(tail, nonStopCodas: [], stopCodas: oaStopCodas, allowD: isDOnset) {
                return true
            }
            if "sj".contains(c) {
                if matchesDiphthongCodaTail(tail, nonStopCodas: [], stopCodas: oaStopCodas, allowToneOverride: false, allowD: isDOnset)
                    || matchesDiphthongCodaTail(tail, nonStopCodas: [], stopCodas: oaStopCodas, requiredDiacritics: "w", allowToneOverride: false, allowD: isDOnset) {
                    return true
                }
            }
            if isDOnset && c == "d" {
                if matchesDiphthongCodaTail(tail, nonStopCodas: [], stopCodas: oaStopCodas, allowToneOverride: true, allowD: false)
                    || matchesDiphthongCodaTail(tail, nonStopCodas: [], stopCodas: oaStopCodas, requiredDiacritics: "w", allowToneOverride: true, allowD: false) {
                    return true
                }
            }
        }

        // 5. 'oe' + stop-coda ('c', 'p', 't') + tone override ('s', 'j') (e.g. lorets / loerts -> loét, loretj / loertj -> loẹt, torets -> toét, khorets -> khoét, orets -> oét)
        if effRhyme[0] == "o"
            && (("rfx".contains(effRhyme[1]) && effRhyme[2] == "e")
                || (effRhyme[1] == "e" && "rfx".contains(effRhyme[2]))) {
            let tail = effRhyme[3...].joined()
            let oeStopCodas: Set<String> = ["c", "p", "t"]
            if "sj".contains(c) && matchesDiphthongCodaTail(tail, nonStopCodas: [], stopCodas: oeStopCodas, allowToneOverride: false, allowD: isDOnset) {
                return true
            }
            if isDOnset && c == "d" && matchesDiphthongCodaTail(tail, nonStopCodas: [], stopCodas: oeStopCodas, allowToneOverride: true, allowD: false) {
                return true
            }
        }

        return false
    }

    private static func matchesVowelInitialDiphthongUnlatch(
        wordRawKeys: [Character],
        character: Character
    ) -> Bool {
        let lowerKeys = wordRawKeys.map { $0.lowercased() }
        guard lowerKeys.count >= 4 else { return false }
        let k0 = lowerKeys[0]
        let k1 = lowerKeys[1]
        let k2 = lowerKeys[2]
        let tail = lowerKeys[3...].joined()
        let c = character.lowercased()

        if k0 == "u" && (("rsfjx".contains(k1) && k2 == "o") || (k1 == "o" && "rsfjx".contains(k2))) {
            if "wo".contains(c) && matchesDiphthongCodaTail(tail, nonStopCodas: ["i", "u", "m", "n", "ng"], stopCodas: ["p", "t", "c"], allowD: false) {
                return true
            }
            if "sj".contains(c) && matchesDiphthongCodaTail(tail, nonStopCodas: [], stopCodas: ["p", "t", "c"], requiredDiacritics: "wo", allowToneOverride: false, allowD: false) {
                return true
            }
        }

        if k0 == "u" && (("rsfjx".contains(k1) && k2 == "a") || (k1 == "a" && "rsfjx".contains(k2))) {
            if c == "a"
                && String(wordRawKeys).lowercased() != "uran"
                && matchesDiphthongCodaTail(tail, nonStopCodas: ["m", "n", "ng", "y"], stopCodas: ["t", "c"], allowD: false) {
                return true
            }
            if "sj".contains(c) && matchesDiphthongCodaTail(tail, nonStopCodas: [], stopCodas: ["t", "c"], requiredDiacritics: "a", allowToneOverride: false, allowD: false) {
                return true
            }
        }

        if (k0 == "i" || k0 == "y") && (("rsfjx".contains(k1) && k2 == "e") || (k1 == "e" && "rsfjx".contains(k2))) {
            if c == "e" && matchesDiphthongCodaTail(tail, nonStopCodas: ["u", "m", "n", "ng"], stopCodas: ["c", "t", "p"], allowD: false) {
                return true
            }
            if "sj".contains(c) && matchesDiphthongCodaTail(tail, nonStopCodas: [], stopCodas: ["c", "t", "p"], requiredDiacritics: "e", allowToneOverride: false, allowD: false) {
                return true
            }
        }

        if k0 == "u" && (("rsfjx".contains(k1) && k2 == "e") || (k1 == "e" && "rsfjx".contains(k2))) {
            if c == "e" && matchesDiphthongCodaTail(tail, nonStopCodas: ["m", "n", "nh"], stopCodas: ["p", "t", "ch"], allowD: false) {
                return true
            }
            if "sj".contains(c) && matchesDiphthongCodaTail(tail, nonStopCodas: [], stopCodas: ["p", "t", "ch"], requiredDiacritics: "e", allowToneOverride: false, allowD: false) {
                return true
            }
        }

        return false
    }

    private static func matchesDiphthongCodaTail(
        _ tail: String,
        nonStopCodas: Set<String>,
        stopCodas: Set<String>,
        requiredDiacritics: String = "",
        allowToneOverride: Bool = true,
        allowD: Bool = true
    ) -> Bool {
        var rem = tail.lowercased()
        if !requiredDiacritics.isEmpty {
            guard let dIdx = rem.firstIndex(where: { requiredDiacritics.contains($0) }) else {
                return false
            }
            rem.remove(at: dIdx)
        }
        if allowD {
            if let dIdx = rem.firstIndex(of: "d") {
                rem.remove(at: dIdx)
            }
        } else if rem.contains("d") {
            return false
        }
        if nonStopCodas.contains(rem) || stopCodas.contains(rem) {
            return true
        }
        guard allowToneOverride, let last = rem.last else {
            return false
        }
        let base = String(rem.dropLast())
        if "sfrxj".contains(last) && nonStopCodas.contains(base) {
            return true
        }
        if "sj".contains(last) && stopCodas.contains(base) {
            return true
        }
        return false
    }

    private static func matchesMonophthongStopCodaDiacriticUnlatch(
        wordRawKeys: [Character],
        prefix2: String,
        rhymeAfterOnset: [String],
        character: Character
    ) -> Bool {
        guard let firstKey = wordRawKeys.first?.lowercased().first,
              !"wfjz".contains(firstKey),
              firstKey != "p" || prefix2 == "ph" else {
            return false
        }
        let c = character.lowercased()
        let effRhyme: [String]
        if prefix2 == "gi"
            && rhymeAfterOnset.count >= 4
            && rhymeAfterOnset[0] == "i"
            && "rfx".contains(rhymeAfterOnset[1])
            && "aeou".contains(rhymeAfterOnset[2]) {
            if rhymeAfterOnset.count == 4 && "cpt".contains(rhymeAfterOnset[3]) && "sj".contains(c) {
                return true
            }
            if rhymeAfterOnset.count == 5 && "ae".contains(rhymeAfterOnset[2]) && rhymeAfterOnset[3...].joined() == "ch" && "sj".contains(c) {
                return true
            }
            effRhyme = [rhymeAfterOnset[2], rhymeAfterOnset[1]] + Array(rhymeAfterOnset[3...])
        } else if prefix2 == "qu"
            && rhymeAfterOnset.count >= 3
            && "rfx".contains(rhymeAfterOnset[0])
            && "aeo".contains(rhymeAfterOnset[1]) {
            if rhymeAfterOnset.count == 3 && "cpt".contains(rhymeAfterOnset[2]) && "sj".contains(c) {
                return true
            }
            if rhymeAfterOnset.count == 4 && "ae".contains(rhymeAfterOnset[1]) && rhymeAfterOnset[2...].joined() == "ch" && "sj".contains(c) {
                return true
            }
            effRhyme = [rhymeAfterOnset[1], rhymeAfterOnset[0]] + Array(rhymeAfterOnset[2...])
        } else {
            effRhyme = "aeou".contains(firstKey) ? wordRawKeys.map({ $0.lowercased() }) : rhymeAfterOnset
        }
        guard effRhyme.count >= 4,
              "rfx".contains(effRhyme[1]) else {
            return false
        }
        let v = effRhyme[0]
        if v == "e" && firstKey == "c" && prefix2 != "ch" {
            return false
        }
        let stopCodas: Set<String>
        let diacritics: String
        switch v {
        case "a":
            stopCodas = ["c", "p", "t"]
            diacritics = "wa"
        case "e":
            stopCodas = ["c", "p", "t", "ch"]
            diacritics = "e"
        case "o":
            stopCodas = ["c", "p", "t"]
            diacritics = "ow"
        case "u":
            stopCodas = ["c", "t"]
            diacritics = "w"
        default:
            return false
        }
        let lowerWord = String(wordRawKeys).lowercased()
        if ["herpe", "merche", "perche"].contains(lowerWord) {
            return false
        }
        let tail = effRhyme[2...].joined()
        let isDOnset = firstKey == "d"
        if diacritics.contains(c) {
            var rem = tail
            if isDOnset, let dIdx = rem.firstIndex(of: "d") {
                rem.remove(at: dIdx)
            } else if rem.contains("d") {
                return false
            }
            guard let last = rem.last, "sj".contains(last) else { return false }
            return stopCodas.contains(String(rem.dropLast()))
        }
        if "sj".contains(c) {
            var rem = tail
            if isDOnset, let dIdx = rem.firstIndex(of: "d") {
                rem.remove(at: dIdx)
            } else if rem.contains("d") {
                return false
            }
            guard let last = rem.last, diacritics.contains(last) else { return false }
            return stopCodas.contains(String(rem.dropLast()))
        }
        if isDOnset && c == "d" && !tail.contains("d") {
            return matchesDiphthongCodaTail(
                tail,
                nonStopCodas: [],
                stopCodas: stopCodas,
                requiredDiacritics: diacritics,
                allowToneOverride: true,
                allowD: false
            ) || (tail.last.map { "sj".contains($0) } == true && stopCodas.contains(String(tail.dropLast())))
        }
        return false
    }

    private static func matchesPreDiacriticStopCodaToneOverrideUnlatch(
        wordRawKeys: [Character],
        prefix2: String,
        rhymeAfterOnset: [String],
        character: Character
    ) -> Bool {
        guard let firstKey = wordRawKeys.first?.lowercased().first,
              !"wfjz".contains(firstKey),
              firstKey != "p" || prefix2 == "ph" else {
            return false
        }
        let c = character.lowercased()
        let isDOnset = firstKey == "d"
        let effRhyme: [String]
        if prefix2 == "gi"
            && rhymeAfterOnset.count >= 5
            && rhymeAfterOnset[0] == "i"
            && "rfx".contains(rhymeAfterOnset[1])
            && "aeou".contains(rhymeAfterOnset[2]) {
            effRhyme = [rhymeAfterOnset[2], rhymeAfterOnset[1]] + Array(rhymeAfterOnset[3...])
            if effRhyme[0] == "u" && effRhyme[2] == "o" {
                let uoTail = effRhyme[3...].joined()
                if "wo".contains(c) && matchesDiphthongCodaTail(uoTail, nonStopCodas: ["i", "u", "m", "n", "ng"], stopCodas: ["p", "t", "c"], allowD: false) {
                    return true
                }
                if "sj".contains(c) && matchesDiphthongCodaTail(uoTail, nonStopCodas: [], stopCodas: ["p", "t", "c"], requiredDiacritics: "wo", allowToneOverride: false, allowD: false) {
                    return true
                }
            }
        } else if prefix2 == "qu"
            && rhymeAfterOnset.count >= 4
            && "rfx".contains(rhymeAfterOnset[0])
            && "aeoy".contains(rhymeAfterOnset[1]) {
            effRhyme = [rhymeAfterOnset[1], rhymeAfterOnset[0]] + Array(rhymeAfterOnset[2...])
        } else {
            effRhyme = "aeiouy".contains(firstKey) ? wordRawKeys.map({ $0.lowercased() }) : rhymeAfterOnset
        }
        guard effRhyme.count >= 4, "aeiouy".contains(effRhyme[0]) else {
            return false
        }
        var rem = effRhyme.joined()
        let secondIdx = rem.index(after: rem.startIndex)
        guard let toneIdx = rem[secondIdx...].firstIndex(where: { "rfx".contains($0) }) else {
            return false
        }
        rem.remove(at: toneIdx)

        if "sj".contains(c) {
            if isDOnset, let dIdx = rem.firstIndex(of: "d") {
                rem.remove(at: dIdx)
            } else if rem.contains("d") {
                return false
            }
        } else if isDOnset && c == "d" && !rem.contains("d") {
            if let last = rem.last, "sj".contains(last) {
                rem.removeLast()
            }
        } else {
            return false
        }

        let patterns: [(vowel: String, codas: Set<String>)] = [
            ("uyee", ["c", "t", "ch"]),
            ("uwow", ["c", "p", "t"]),
            ("uow", ["c", "p", "t"]),
            ("uwo", ["c", "p", "t", "cw", "pw", "tw"]),
            ("uoo", ["c", "p", "t"]),
            ("uaa", ["c", "t"]),
            ("uee", ["p", "t", "ch"]),
            ("iee", ["c", "p", "t"]),
            ("yee", ["c", "p", "t", "ch"]),
            ("owa", ["c", "p", "t", "ch"]),
            ("oaw", ["c", "p", "t", "ch"]),
            ("aw", ["c", "p", "t"]),
            ("aa", ["c", "p", "t"]),
            ("ee", ["c", "p", "t", "ch"]),
            ("oo", ["c", "p", "t"]),
            ("ow", ["c", "p", "t"]),
            ("uw", ["c", "t"])
        ]
        for (vowel, codas) in patterns where rem.hasPrefix(vowel) {
            if "iey".contains(vowel.first!) && firstKey == "c" && prefix2 != "ch" {
                return false
            }
            let coda = String(rem.dropFirst(vowel.count))
            if codas.contains(coda) {
                return true
            }
        }
        return false
    }

    private static func matchesPostCodaStopToneOverrideUnlatch(
        wordRawKeys: [Character],
        prefix2: String,
        rhymeAfterOnset: [String],
        character: Character
    ) -> Bool {
        guard let firstKey = wordRawKeys.first?.lowercased().first,
              !"wfjz".contains(firstKey),
              firstKey != "p" || prefix2 == "ph" else {
            return false
        }
        let c = character.lowercased()
        let isDOnset = firstKey == "d"
        let effRhyme = "aeiouy".contains(firstKey) ? wordRawKeys.map({ $0.lowercased() }) : rhymeAfterOnset
        guard effRhyme.count >= 3, "aeiouy".contains(effRhyme[0]) else {
            return false
        }
        let rawRhyme = effRhyme.joined()
        let basePatterns: [(base: String, diacritics: Set<String>)] = [
            ("uyeech", [""]), ("uyeet", [""]), ("uyeec", [""]),
            ("uyech", ["e", ""]), ("uyet", ["e", ""]), ("uyec", ["e", ""]),
            ("uwowc", [""]), ("uwowp", [""]), ("uwowt", [""]),
            ("uowc", ["w", ""]), ("uowp", ["w", ""]), ("uowt", ["w", ""]),
            ("uwoc", ["w", ""]), ("uwop", ["w", ""]), ("uwot", ["w", ""]),
            ("uooc", [""]), ("uoop", [""]), ("uoot", [""]),
            ("uoc", ["w", "o", ""]), ("uop", ["w", ""]), ("uot", ["w", "o", ""]),
            ("uaat", [""]), ("uaac", [""]),
            ("uat", ["a", ""]), ("uac", ["a", ""]),
            ("ueech", [""]), ("ueet", [""]), ("ueep", [""]),
            ("uech", ["e", ""]), ("uet", ["e", ""]), ("uep", ["e", ""]),
            ("ieet", [""]), ("ieec", [""]), ("ieep", [""]),
            ("iet", ["e", ""]), ("iec", ["e", ""]), ("iep", ["e", ""]),
            ("yeet", [""]), ("yeec", [""]), ("yeep", [""]),
            ("yet", ["e", ""]), ("yec", ["e", ""]), ("yep", ["e", ""]),
            ("oawch", [""]), ("oawt", [""]), ("oawc", [""]), ("oawp", [""]),
            ("owach", ["w", ""]), ("owat", ["w", ""]), ("owac", ["w", ""]), ("owap", ["w", ""]),
            ("oach", ["w", ""]), ("oat", ["w", ""]), ("oac", ["w", ""]), ("oap", ["w", ""]),
            ("oet", [""]), ("oec", [""]), ("oep", [""]),
            ("uych", [""]), ("uyt", [""]), ("uyp", [""]),
            ("ych", [""]), ("yt", [""]), ("yp", [""]), ("yc", [""]),
            ("awch", [""]), ("aach", [""]), ("eech", [""]),
            ("ach", ["w", "a", ""]), ("ech", ["e", ""]), ("ich", [""]),
            ("awc", [""]), ("awp", [""]), ("awt", [""]),
            ("aac", [""]), ("aap", [""]), ("aat", [""]),
            ("ac", ["w", "a", ""]), ("ap", ["w", "a", ""]), ("at", ["w", "a", ""]),
            ("eec", [""]), ("eep", [""]), ("eet", [""]),
            ("ec", ["e", ""]), ("ep", ["e", ""]), ("et", ["e", ""]),
            ("ic", [""]), ("ip", [""]), ("it", [""]),
            ("ooc", [""]), ("oop", [""]), ("oot", [""]),
            ("owc", [""]), ("owp", [""]), ("owt", [""]),
            ("oc", ["o", "w", ""]), ("op", ["o", "w", ""]), ("ot", ["o", "w", ""]),
            ("uwc", [""]), ("uwt", [""]),
            ("uc", ["w", ""]), ("up", [""]), ("ut", ["w", ""])
        ]
        for (base, diacritics) in basePatterns where rawRhyme.hasPrefix(base) {
            if "iey".contains(base.first!) && firstKey == "c" && prefix2 != "ch" {
                return false
            }
            if base.first == "e" && firstKey == "g" && prefix2 != "gh" && prefix2 != "gi" {
                return false
            }
            if !"iey".contains(base.first!) && firstKey == "k" && prefix2 != "kh" {
                return false
            }
            let tail = String(rawRhyme.dropFirst(base.count))
            let toneChars = tail.filter { "rfx".contains($0) }
            guard toneChars.count == 1, let toneChar = toneChars.first,
                  let toneIdx = tail.firstIndex(of: toneChar) else {
                continue
            }
            var rem = tail
            rem.remove(at: toneIdx)

            if "sj".contains(c) {
                if isDOnset, let dIdx = rem.firstIndex(of: "d") {
                    rem.remove(at: dIdx)
                } else if rem.contains("d") {
                    return false
                }
                guard diacritics.contains(rem) else { return false }
                if toneChar == "r" && c == "s"
                    && ((base == "et" && tail == "er" && firstKey == "m")
                        || (base == "ot" && tail == "or" && "mr".contains(firstKey))) {
                    return false
                }
                return true
            }

            if !c.isEmpty && diacritics.contains(c) {
                if isDOnset, let dIdx = rem.firstIndex(of: "d") {
                    rem.remove(at: dIdx)
                } else if rem.contains("d") {
                    return false
                }
                if rem == "j" || rem == "s" {
                    return true
                }
                return false
            }

            if isDOnset && c == "d" && !rem.contains("d") {
                if let last = rem.last, "sj".contains(last) {
                    let diac = String(rem.dropLast())
                    if diacritics.contains(diac) {
                        return true
                    }
                }
                return false
            }
            return false
        }
        return false
    }

    private static func isVietnameseCollocation(candidateWord: String, lastCompletedWord: String) -> Bool {
        let prev = lastCompletedWord.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !prev.isEmpty, let prefixes = vietnameseCollocationPrefixes[candidateWord.lowercased()] else {
            return false
        }
        if prefixes.contains(prev) {
            return true
        }
        let strippedPrev = prev.trimmingCharacters(in: CharacterSet.letters.inverted)
        if prefixes.contains(strippedPrev) {
            return true
        }
        return prefixes.contains(where: { prefix in
            guard prev.hasSuffix(prefix), prev.count > prefix.count else { return false }
            let charBefore = prev[prev.index(prev.endIndex, offsetBy: -prefix.count - 1)]
            return !charBefore.isLetter
        })
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
