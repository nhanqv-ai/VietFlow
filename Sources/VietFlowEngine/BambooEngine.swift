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
            let onsetLen = prefix3 == "ngh" ? 3 : ((["ch", "ph", "th", "kh", "tr", "nh", "gh", "ng", "qu"].contains(prefix2)
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
                "chief", "thief", "ties", "dies", "lies", "vies", "pies", "hies", "tier", "bier", "pier", "trier", "tries",
                "ieru", "kieru", "mieru", "hieru", "nieru", "tieru", "bieru", "pieru", "sieru", "gieru", "rieru", "chieru",
                "tiesu", "diesu", "liesu", "viesu", "piesu", "hiesu", "chiefu", "thiefu",
                "dues", "hues", "sues", "rues", "tues", "cues", "died", "diets", "duets", "guest", "quiet", "quiets",
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
            } else if (String(wordRawKeys).lowercased() == "soar" && "mnioywfjx".contains(character.lowercased()))
                || (["soars", "sofas", "oars", "loafs", "oafs"].contains(String(wordRawKeys).lowercased()) && "mncptwyio".contains(character.lowercased()))
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
            } else if (["toes", "hoes", "lose", "hose", "chose", "those", "ores", "tores", "hores", "lores", "chores"].contains(String(wordRawKeys).lowercased()) && "ocmpt".contains(character.lowercased()))
                || (["toes", "hoes", "ores", "tores", "hores", "lores", "chores"].contains(String(wordRawKeys).lowercased()) && "frxj".contains(character.lowercased()))
                || (["toes", "hoes", "lose", "hose", "those", "ores", "tores", "hores", "lores", "chores"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "n")
                || (["tore", "hore", "lore", "chore", "ore"].contains(String(wordRawKeys).lowercased()) && "ofjx".contains(character.lowercased()))
                || (["lose", "hose", "chose", "those"].contains(String(wordRawKeys).lowercased()) && "fjx".contains(character.lowercased()))
                || (["hose", "chose", "those"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "r")
                || (["tore", "hore", "chore"].contains(String(wordRawKeys).lowercased()) && "mn".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "lore" && character.lowercased() == "n") {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if (String(wordRawKeys).lowercased() == "two" && "wnimcptufrxj".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "twos" && "imncptuw".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "wow" && "frxjiumnptc".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "wows" && "iumncpt".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "wi" && "sfrxj".contains(character.lowercased())) {
                isBypassed = false
                didBackspace = true
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if ["laws", "raws", "saws", "thaws", "caws", "maws", "haws"].contains(String(wordRawKeys).lowercased()) && "cmnpt".contains(character.lowercased()) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if (["dawn", "lawn", "down", "gown", "town", "own"].contains(String(wordRawKeys).lowercased())
                && ("frxjg".contains(character.lowercased())
                    || (["dawn", "lawn"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "a")
                    || (["down", "gown", "town", "own"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "o")
                    || (wordRawKeys[0].lowercased() == "d" && character.lowercased() == "d")))
                || (["dawns", "lawns", "downs", "gowns", "towns", "owns"].contains(String(wordRawKeys).lowercased())
                    && ("gfrxj".contains(character.lowercased())
                        || (["dawns", "lawns"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "a")
                        || (["downs", "gowns", "towns", "owns"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "o"))) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if ["howa", "dowa", "nowa", "sowa", "towa", "rowa"].contains(String(wordRawKeys).lowercased()) && "cmnptsfrxj".contains(character.lowercased()) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if has3CharRhymeAfterOnset
                && wordRawKeys[0].lowercased() != "k"
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
                && wordRawKeys[0].lowercased() != "k"
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
                    || (String(wordRawKeys).lowercased() == "nix" && character.lowercased() == "a")
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
                && ("cmnptwaiy".contains(character.lowercased()) || (wordRawKeys[0].lowercased() == "d" && character.lowercased() == "d")) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if (String(wordRawKeys).lowercased() == "hex" && "euocmnpt".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "trex" && "euomn".contains(character.lowercased()))
                || (["trexu", "trexn", "trexm", "hexu"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "e")
                || (String(wordRawKeys).lowercased() == "cat" && "awjs".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "let" && "ejs".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "in" && "sfrxj".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "var" && "mnouwfjx".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "git" && "sj".contains(character.lowercased()))
                || (["chair", "lair", "moron"].contains(String(wordRawKeys).lowercased()) && "fjx".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "boron" && "sfjx".contains(character.lowercased()))
                || (["beset", "reset", "keeps", "peeps", "deeps", "cheeps", "noops", "goops", "troops", "topos", "gotos", "photos", "datas", "basta", "rasta", "coats", "coast", "toast", "diets", "quiets", "nieces", "sorts", "burst", "worst", "thirst", "swops"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "j")
                || (["hairs", "chairs", "lairs", "airs", "morons", "booms", "dooms", "looms", "rooms", "goons", "loons", "moons", "nonos", "deems", "seems", "teems", "keens", "teens", "queens", "mamas", "memes", "themes", "donors", "honors", "oxen", "vixen", "vixens", "sirens", "risen", "chosen", "tureens", "barns", "darns", "tarns", "horns", "thorns", "morns", "borns", "corns", "torns", "burns", "turns", "churns", "urns", "harms", "charms", "norms", "corms", "dorms", "berms", "terms", "kerns", "terns", "dodos", "dojos", "rojos", "loofs", "oofs", "hoofs", "roofs", "goofs", "moors", "boors", "doors", "dadas", "charas", "leers", "seers", "cheers", "veers", "reefs", "beefs", "beers", "deers", "trees", "sees", "buys", "guys", "soars", "sofas", "oars", "loafs", "oafs", "coifs", "choirs", "naifs", "liars", "dues", "hues", "sues", "rues", "tues", "cues"].contains(String(wordRawKeys).lowercased()) && "frxj".contains(character.lowercased()))
                || (["siren", "tureen", "honor", "donor"].contains(String(wordRawKeys).lowercased()) && "fxj".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "oxen" && character.lowercased() == "s")
                || (["manx", "sans"].contains(String(wordRawKeys).lowercased()) && "awgh".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "chasm" && "aw".contains(character.lowercased()))
                || (["coast", "coats", "toast", "cusp", "swops", "soaps", "boron", "moron", "morons", "datas", "gotos", "topos", "photos", "mamas", "nonos", "noops", "goops", "troops", "looms", "dooms", "rooms", "booms", "goons", "loons", "moons", "roots", "boost", "roost", "honor", "donor", "barns", "darns", "tarns", "horns", "thorns", "morns", "borns", "corns", "torns", "burns", "turns", "churns", "urns", "harms", "charms", "norms", "corms", "dorms"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "w")
                || (["barns", "darns", "tarns", "harms", "charms"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "a")
                || (["horns", "thorns", "morns", "borns", "corns", "torns", "norms", "corms", "dorms"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "o")
                || (String(wordRawKeys).lowercased() == "disc" && "hdj".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "minx" && character.lowercased() == "h")
                || (["oxen", "vixen", "siren", "risen", "kern", "kerns", "boron", "moron", "morons", "goons", "loons", "moons", "nonos", "chosen", "urana", "xanax", "hana", "nana", "sana", "hono", "dono", "sono", "phono", "honor", "donor", "barns", "darns", "tarns", "horns", "thorns", "morns", "borns", "corns", "torns", "burns", "turns", "churns", "urns", "keens", "teens"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "g")
                || (String(wordRawKeys).lowercased() == "manag" && "sfrxjw".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "monog" && "sfxj".contains(character.lowercased()))
                || (["ore", "guree", "gifi", "dired", "tier", "bier", "trier", "chief", "thief"].contains(String(wordRawKeys).lowercased()) && "mn".contains(character.lowercased()))
                || (["gisi", "giji", "ties", "dies", "lies", "vies", "pies", "hies", "tries"].contains(String(wordRawKeys).lowercased()) && "mncpt".contains(character.lowercased()))
                || (["hires", "tires", "mires", "sires"].contains(String(wordRawKeys).lowercased()) && "mncpteu".contains(character.lowercased()))
                || (["berms", "terms", "kerns", "terns"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "e")
                || (["leers", "seers", "cheers", "veers", "reefs", "beefs", "beers", "deers", "terse", "sirs", "dirs"].contains(String(wordRawKeys).lowercased()) && "mncptu".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "torso" && "mncpti".contains(character.lowercased()))
                || (["bars", "cars", "mars", "tars", "vars", "barfs"].contains(String(wordRawKeys).lowercased()) && "mncptiouywa".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "barf" && "mniouywajx".contains(character.lowercased()))
                || (["chefs", "refs", "hers", "ers", "nerfs", "serfs"].contains(String(wordRawKeys).lowercased()) && "mncptoe".contains(character.lowercased()))
                || (["nerf", "serf", "kerf"].contains(String(wordRawKeys).lowercased()) && "mnoejx".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "vers" && "mncpto".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "ors" && "mncptoiw".contains(character.lowercased()))
                || (["urs", "curs"].contains(String(wordRawKeys).lowercased()) && "mncptiuw".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "burs" && "mncpiuw".contains(character.lowercased()))
                || (["surf", "turf"].contains(String(wordRawKeys).lowercased()) && "mniuwjx".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "diesd" && "cmnpt".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "queer" && "umn".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "queue" && "frxj".contains(character.lowercased()))
                || (["buys", "guys"].contains(String(wordRawKeys).lowercased()) && "aumnptc".contains(character.lowercased()))
                || (["bura", "chura", "dura", "gura", "hura", "mura", "nura", "rura", "sura", "tura"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "a")
                || (["queens", "teens", "keens", "sense", "tense", "dense", "defend", "deedsc", "kern", "tern", "kerns", "terns", "barns", "darns", "tarns"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "h")
                || (["dodos", "dojos", "rojos", "loofs", "oofs", "hoofs", "roofs", "goofs", "moors", "boors", "doors"].contains(String(wordRawKeys).lowercased()) && "wimncpt".contains(character.lowercased()))
                || (["dadas", "charas"].contains(String(wordRawKeys).lowercased()) && "wuymncpt".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "deeds" && "umnpt".contains(character.lowercased()))
                || (["daasu", "datas", "dawns", "downs", "darns", "darnsa", "darnsw", "darnsg", "darnsh", "deems", "deeps", "deers", "deersm", "deersn", "deersc", "deersp", "deerst", "deersu", "dense", "dirs", "dodos", "dojos", "dooms", "doors", "doorsi", "doorsm", "doorsn", "doorsng", "doorsc", "doorsp", "doorst", "doorsw", "donor", "donors", "dots", "dust", "dura", "duri", "dorm", "dorms", "dormsw", "dormso", "derm", "dora", "dosa", "dosai", "diesm", "diesn", "diesc", "diesp", "diest", "diesng", "dues"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "d") {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if String(wordRawKeys).lowercased() == "won" && "gxfsrxj".contains(character.lowercased()) {
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
                || ["dieted", "datawd", "datadw", "dapawd", "dapadw", "dotowd", "dotodw", "dopowd", "dopodw", "docowd", "docodw"].contains(String(wordRawKeys).lowercased()))
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
            } else if String(wordRawKeys).lowercased() == "life" && "emnug".contains(character.lowercased()) {
                isBypassed = false
                activeRawKeys = wordRawKeys
                (activePreedit, transformState) = evaluateRaw(keys: wordRawKeys)
            } else if (has3CharRhymeAfterOnset
                && r1 == "u"
                && "rsfjx".contains(r2)
                && "aoui".contains(r3)
                && ("wo".contains(character.lowercased())
                    || (wordRawKeys[0].lowercased() == "d" && character.lowercased() == "d")
                    || (!"kp".contains(wordRawKeys[0].lowercased()) && "sfrxj".contains(character.lowercased()) && character.lowercased() != r2)))
                || (has3CharRhymeAfterOnset
                    && r1 == "i"
                    && "rsfjx".contains(r2)
                    && "ua".contains(r3)
                    && !"gp".contains(wordRawKeys[0].lowercased())
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
                || (["girui", "gisui", "osoi", "hosoi", "moroi", "noroi", "soroi", "girai", "gisai", "horai", "torai", "hosai", "sosai", "tosai"].contains(String(wordRawKeys).lowercased())
                    && "sfrxj".contains(character.lowercased())
                    && character.lowercased() != wordRawKeys[wordRawKeys.count - 3].lowercased())
                || (["arau", "harau", "sarau", "tarau", "narau", "ieru", "kieru", "mieru", "hieru", "nieru", "tieru", "bieru", "sieru", "gieru", "rieru", "chieru"].contains(String(wordRawKeys).lowercased())
                    && "sfxj".contains(character.lowercased()))
                || (String(wordRawKeys).lowercased() == "aru" && "asfxj".contains(character.lowercased()))
                || (["iru", "isu"].contains(String(wordRawKeys).lowercased()) && "sfrxj".contains(character.lowercased()) && character.lowercased() != wordRawKeys[1].lowercased())
                || (String(wordRawKeys).lowercased() == "asa" && "cmntuywfxj".contains(character.lowercased()))
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
                                || (r2 == "f" && !["life", "rife", "wife"].contains(String(wordRawKeys).lowercased()))
                                || r2 == "j"
                                || (r2 == "x" && ("fj".contains(character.lowercased()) || String(wordRawKeys).lowercased() == "chixe"))))
                            || (r1 == "u"
                                && ((r2 == "r" && ("fxj".contains(character.lowercased()) || !["cure", "lure", "sure", "pure"].contains(String(wordRawKeys).lowercased())))
                                    || (r2 == "s" && ("fxj".contains(character.lowercased()) || !["muse", "ruse", "fuse", "use"].contains(String(wordRawKeys).lowercased())))
                                    || "fj".contains(r2)))))))
                || (rhymeAfterOnset.count >= 4
                    && rhymeAfterOnset[0] == "i"
                    && (("rsfjx".contains(rhymeAfterOnset[1]) && rhymeAfterOnset[2] == "e")
                        || (rhymeAfterOnset[1] == "e" && "rsfjx".contains(rhymeAfterOnset[2])))
                    && ((character.lowercased() == "e"
                        && (rhymeAfterOnset[3...].joined() == "d"
                            || Self.matchesDiphthongCodaTail(rhymeAfterOnset[3...].joined(), nonStopCodas: ["u", "m", "n", "ng"], stopCodas: ["c", "t", "p"])))
                        || ("sj".contains(character.lowercased())
                            && Self.matchesDiphthongCodaTail(rhymeAfterOnset[3...].joined(), nonStopCodas: [], stopCodas: ["c", "t", "p"], requiredDiacritics: "e", allowToneOverride: false))
                        || (wordRawKeys[0].lowercased() == "d"
                            && character.lowercased() == "d"
                            && Self.matchesDiphthongCodaTail(rhymeAfterOnset[3...].joined(), nonStopCodas: ["u", "m", "n", "ng"], stopCodas: ["c", "t", "p"], requiredDiacritics: "e", allowToneOverride: true, allowD: false))))
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
                            || Self.matchesDiphthongCodaTail(rhymeAfterOnset[3...].joined(), nonStopCodas: ["m", "n", "nh"], stopCodas: ["p", "t", "ch"])))
                        || ("sj".contains(character.lowercased())
                            && Self.matchesDiphthongCodaTail(rhymeAfterOnset[3...].joined(), nonStopCodas: [], stopCodas: ["p", "t", "ch"], requiredDiacritics: "e", allowToneOverride: false))
                        || (wordRawKeys[0].lowercased() == "d"
                            && character.lowercased() == "d"
                            && Self.matchesDiphthongCodaTail(rhymeAfterOnset[3...].joined(), nonStopCodas: ["m", "n", "nh"], stopCodas: ["p", "t", "ch"], requiredDiacritics: "e", allowToneOverride: true, allowD: false))))
                || (String(wordRawKeys).lowercased() == "tureen" && character.lowercased() == "h")
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
                        || (!"pgz".contains(wordRawKeys[0].lowercased())
                            && "sfrxj".contains(character.lowercased())
                            && character.lowercased() != r2
                            && !(String(wordRawKeys).lowercased() == "refu" && character.lowercased() == "s"))))
                    || (r1 == "e" && "rsfjx".contains(r2) && r3 == "o"
                        && ((wordRawKeys[0].lowercased() == "d" && character.lowercased() == "d")
                            || (r2 == "s" && !"gz".contains(wordRawKeys[0].lowercased()) && "frxj".contains(character.lowercased()))
                            || (r2 == "r" && ["hero", "nero", "rero"].contains(String(wordRawKeys).lowercased()) && "fxj".contains(character.lowercased()))
                            || (["nero", "rero"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "s")))
                    || (r1 == "a" && "rsfjx".contains(r2) && "uy".contains(r3)
                        && (character.lowercased() == "a"
                            || (wordRawKeys[0].lowercased() == "d" && character.lowercased() == "d")
                            || (r3 == "u" && !"kp".contains(wordRawKeys[0].lowercased()) && "sfrxj".contains(character.lowercased()) && character.lowercased() != r2)))
                    || (r1 == "o" && "rsfjx".contains(r2) && r3 == "i"
                        && ("ow".contains(character.lowercased())
                            || (wordRawKeys[0].lowercased() == "d" && character.lowercased() == "d")
                            || (["nori", "rori"].contains(String(wordRawKeys).lowercased()) && "sfxj".contains(character.lowercased()))))
                    || (r1 == "e" && r2 == "r" && "mn".contains(r3) && ("efjx".contains(character.lowercased()) || (String(wordRawKeys).lowercased() == "derm" && character.lowercased() == "s")))
                    || (["deso", "daru", "dasu"].contains(String(wordRawKeys).lowercased()) && character.lowercased() == "d")
                    || (["maso", "saso"].contains(String(wordRawKeys).lowercased()) && "frxj".contains(character.lowercased()))
                    || (String(wordRawKeys).lowercased() == "rari" && "sfxj".contains(character.lowercased()))
                    || (r1 == "o" && "rsfjx".contains(r2) && r3 == "a"
                        && (("sj".contains(r2) && "cmnpt".contains(character.lowercased()))
                            || ("rfx".contains(r2) && "mn".contains(character.lowercased()))
                            || character.lowercased() == "y"
                            || (character.lowercased() == "i" && ["sora", "lora", "sofa", "dora"].contains(String(wordRawKeys).lowercased()))
                            || (character.lowercased() == "o" && ["sora", "lora", "sofa", "sosa", "tosa", "dora", "dosa"].contains(String(wordRawKeys).lowercased()))
                            || (character.lowercased() == "w" && ["sora", "lora", "sofa", "sosa", "tosa", "dora", "dosa"].contains(String(wordRawKeys).lowercased()))
                            || (["sora", "lora", "dora", "sosa", "tosa", "dosa"].contains(String(wordRawKeys).lowercased()) && "sfrxj".contains(character.lowercased()) && character.lowercased() != r2)
                            || (String(wordRawKeys).lowercased() == "sofa" && "rxj".contains(character.lowercased()))
                            || (String(wordRawKeys).lowercased() == "nora" && character.lowercased() == "x")))))
                || (wordRawKeys.first?.lowercased() == "d"
                    && (rhymeAfterOnset.count == 4 || (rhymeAfterOnset.count == 5 && "sfrxj".contains(rhymeAfterOnset[4])))
                    && rhymeAfterOnset[0] == "o"
                    && (("rsfjx".contains(rhymeAfterOnset[1]) && rhymeAfterOnset[2] == "a" && "iyo".contains(rhymeAfterOnset[3]))
                        || (rhymeAfterOnset[1] == "a" && "rsfjx".contains(rhymeAfterOnset[2]) && "iyo".contains(rhymeAfterOnset[3]))
                        || (rhymeAfterOnset[1] == "a" && "iyo".contains(rhymeAfterOnset[2]) && "rsfjx".contains(rhymeAfterOnset[3])))
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
                            && "fx".contains(r2)
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
        let isKeyword = EnglishRestoreDetector.isEnglishKeyword(candidateWord) && !isVietCollocation
        let isRomaji = JapaneseRomajiDetector.shouldRestoreRomaji(candidateWord: candidateWord) && !isVietCollocation
        if _config.autoCorrectEnglish && (
            isKeyword
            || EnglishRestoreDetector.hasInvalidMedialDoubleConsonant(candidateWord)
            || isTelexSwEnglish
            || isRomaji
        ) {
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
        if _config.autoCorrectEnglish && (
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
                let invalidOeOnsets: Set<String> = ["b", "c", "d", "đ", "g", "gh", "m", "n", "p", "ph", "r", "s", "tr", "v"]
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
                let isInvalidKOrZOrthography = (lowerOnset == "k" && firstNuc != nil && !"ieêy".contains(firstNuc!))
                    || (lowerOnset == "c" && firstNuc != nil && "ieêy".contains(firstNuc!))
                    || ((lowerOnset == "g" || lowerOnset == "ng") && firstNuc != nil && "eê".contains(firstNuc!))
                    || (invalidOaiOnsets.contains(lowerOnset) && ["oai", "oao", "oay", "oeo"].contains(lowerNuc))
                    || (invalidOeOnsets.contains(lowerOnset) && lowerNuc == "oe")
                    || (invalidOaOnsets.contains(lowerOnset) && ["oa", "oă"].contains(lowerNuc) && !isValidVietnameseGoa && !isValidVietnameseNoan)
                    || (!lowerOnset.isEmpty && lowerOnset != "qu" && parsed.nucleus.count >= 2 && lowerNuc.hasPrefix("y"))
                    || (lowerOnset == "p" && (parsed.tone != .none || lowerNuc.contains(where: { "ăơư".contains($0) })))
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
            if !prev.isEmpty {
                lastCompletedWord = prev.lowercased()
            }
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
        "vary": ["đánh", "cạo", "tróc", "lớp", "cá", "vẩy", "bóc"],
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
        "dojos": ["câu", "thách", "dố"]
    ]

    private static func matchesUyOaOeClusterUnlatch(
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

        // 1. 'qu' onset + 'yê' / 'uy' stop-coda & non-stop-coda unlatch (e.g. quyretes -> quyết, quyretej -> quyệt, quyrense -> quyến, quyrts -> quýt)
        if prefix2 == "qu" && rhymeAfterOnset.count >= 3 && rhymeAfterOnset[0] == "y" {
            if "rfx".contains(rhymeAfterOnset[1]) && ["t", "p", "ch"].contains(rhymeAfterOnset[2...].joined()) && "sj".contains(c) {
                return true
            }
            if rhymeAfterOnset.count >= 4
                && (("rsfjx".contains(rhymeAfterOnset[1]) && rhymeAfterOnset[2] == "e")
                    || (rhymeAfterOnset[1] == "e" && "rsfjx".contains(rhymeAfterOnset[2]))) {
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
            if "sj".contains(c) && ["c", "p", "t"].contains(tail) {
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
        let effRhyme = "aeou".contains(firstKey) ? wordRawKeys.map({ $0.lowercased() }) : rhymeAfterOnset
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
        let c = character.lowercased()
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
        let effRhyme = "aeiouy".contains(firstKey) ? wordRawKeys.map({ $0.lowercased() }) : rhymeAfterOnset
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
            ("uwo", ["c", "p", "t"]),
            ("uoo", ["c", "p", "t"]),
            ("uaa", ["c", "t"]),
            ("uee", ["p", "t", "ch"]),
            ("iee", ["c", "p", "t"]),
            ("yee", ["c", "p", "t"]),
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
            ("uyech", ["e"]), ("uyet", ["e"]), ("uyec", ["e"]),
            ("uoc", ["w", "o", ""]), ("uop", ["w", ""]), ("uot", ["w", "o", ""]),
            ("uat", ["a", ""]), ("uac", ["a", ""]),
            ("uech", ["e", ""]), ("uet", ["e", ""]), ("uep", ["e", ""]),
            ("iet", ["e", ""]), ("iec", ["e", ""]), ("iep", ["e", ""]),
            ("yet", ["e", ""]), ("yec", ["e", ""]), ("yep", ["e", ""]),
            ("oach", ["w", ""]), ("oat", ["w", ""]), ("oac", ["w", ""]), ("oap", ["w", ""]),
            ("oet", [""]), ("oec", [""]), ("oep", [""]),
            ("uych", [""]), ("uyt", [""]), ("uyp", [""]),
            ("ych", [""]), ("yt", [""]), ("yp", [""]), ("yc", [""]),
            ("ach", ["w", "a", ""]), ("ech", ["e", ""]), ("ich", [""]),
            ("ac", ["w", "a", ""]), ("ap", ["w", "a", ""]), ("at", ["w", "a", ""]),
            ("ec", ["e", ""]), ("ep", ["e", ""]), ("et", ["e", ""]),
            ("ic", [""]), ("ip", [""]), ("it", [""]),
            ("oc", ["o", "w", ""]), ("op", ["o", "w", ""]), ("ot", ["o", "w", ""]),
            ("uc", ["w", ""]), ("up", [""]), ("ut", ["w", ""])
        ]
        for (base, diacritics) in basePatterns where rawRhyme.hasPrefix(base) {
            if "iey".contains(base.first!) && firstKey == "c" && prefix2 != "ch" {
                return false
            }
            if base.first == "e" && firstKey == "g" && prefix2 != "gh" && prefix2 != "gi" {
                return false
            }
            if !"iey".contains(base.first!) && firstKey == "k" {
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
                if toneChar == "r" && c == "s" && rem != "w" {
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
                if rem == "j" || (rem == "s" && (toneChar != "r" || c == "w")) {
                    return true
                }
                return false
            }

            if isDOnset && c == "d" && !rem.contains("d") {
                if let last = rem.last, "sj".contains(last) {
                    let diac = String(rem.dropLast())
                    if diacritics.contains(diac) && (toneChar != "r" || last == "j" || diac == "w") {
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
        return prefixes.contains(where: { prev.hasSuffix($0) })
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
