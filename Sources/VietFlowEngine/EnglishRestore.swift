//
//  EnglishRestore.swift
//  VietFlowEngine
//
//  Automatic English word restoration, phonotactic validation, and bypass latching.
//

import Foundation

public struct EnglishRestoreState: Equatable, Sendable {
    /// True if the current word is bypassed (raw English mode until next delimiter).
    public var isBypassed: Bool
    /// Buffer of raw keystrokes typed for the current active token.
    public var rawKeystrokes: [Character]

    public init(isBypassed: Bool = false, rawKeystrokes: [Character] = []) {
        self.isBypassed = isBypassed
        self.rawKeystrokes = rawKeystrokes
    }

    public mutating func appendKey(_ char: Character) {
        rawKeystrokes.append(char)
    }

    public mutating func popKey() -> Character? {
        guard !rawKeystrokes.isEmpty else { return nil }
        return rawKeystrokes.removeLast()
    }

    public mutating func reset() {
        isBypassed = false
        rawKeystrokes.removeAll(keepingCapacity: true)
    }

    public var rawString: String {
        String(rawKeystrokes)
    }
}

public enum EnglishKeywords {
    public static let commonKeywords: Set<String> = [
        // Developer keywords & system commands
        "code", "post", "view", "format", "string", "struct", "print", "while",
        "class", "filter", "clear", "create", "system", "window", "document",
        "switch", "case", "break", "return", "import", "export", "false", "true",
        "commit", "branch", "merge", "push", "pull", "fetch", "clone", "status", "diff",
        "text", "test", "cost", "most", "fast", "broadcast", "terminal",
        "command", "buffer", "buff", "apple", "google", "microsoft", "github", "docker",
        "rust", "golang", "swift", "python", "java", "ruby", "node", "npm", "yarn",
        "make", "build", "debug", "release", "const", "var", "let", "func", "function",
        "public", "private", "fileprivate", "internal", "open", "static", "final",
        "class", "enum", "protocol", "extension", "typealias", "associatedtype",
        "async", "await", "actor", "sendable", "init", "deinit", "subscript", "self",
        "super", "nil", "null", "none", "some", "any", "where", "for", "in", "repeat",
        "guard", "else", "defer", "catch", "throw", "throws", "try",
        "operator", "precedencegroup", "mutating", "nonmutating",
        "override", "convenience", "required", "dynamic", "optional", "lazy",
        "weak", "unowned", "isolated", "nonisolated", "viewing", "viewer", "views",
        "mkdir", "curl", "ssh", "git", "http", "https", "core", "deep", "user", "cargo", "origin", "nano", "wifi", "water", "cat", "macos",
        "word", "warning", "report", "localhost",
        "pattern", "letter", "button", "better", "common", "matter",
        "swim", "swing", "sweet", "swap", "fix",
        "server", "service", "version", "person",
        "surf", "turf", "toward", "towards", "coward",

        // Common English words without valid Vietnamese collisions (Requirement R1)
        "yes", "use", "users", "used", "base", "phase", "chase",
        "rose", "pose", "nose", "lose", "dose", "hose", "house", "mouse",
        "pause", "cause", "course", "source", "force", "horse", "nurse", "parse",
        "sense", "dense", "tense", "pulse", "verse", "focus", "virus",
        "bonus", "minus", "campus", "lotus", "nexus", "next", "context",
        "index", "prefix", "suffix", "matrix", "syntax", "regex", "complex", "relax",
        "linux", "unix", "nginx", "tmux", "redux", "pixel", "proxy", "axios",
        "year", "hear", "near", "dear", "bear", "pear", "gear", "wear", "tear", "fear",
        "appear", "career", "engineer", "our", "hour", "four", "pour", "sour", "tour", "your",
        "door", "floor", "poor", "beer", "deer", "peer", "new", "news",
        "review", "preview", "interview", "overview", "webview",
        "down", "downs", "download", "downloads", "downloaded", "downloading", "downloader",
        "upload", "uploads", "uploaded", "uploading", "uploader",
        "dropdown", "markdown", "shutdown", "countdown", "breakdown", "lockdown",
        "slowdown", "showdown", "touchdown", "downtown", "downward", "downwards",
        "downgrade", "downstream", "downsize", "downtime", "downfall", "downhill",
        "town", "towns", "brown", "crown", "crowns", "gown", "gowns", "clown", "frown", "drown",
        "own", "owns", "owned", "owning", "owner", "owners", "ownership",
        "shown", "known", "grown", "thrown", "blown", "flown",
        "dawn", "dawns", "lawn", "lawns", "pawn", "pawns", "fawn", "yawn", "spawn", "prawn",
        "power", "powers", "powered", "powerful", "tower", "towers",
        "flower", "flowers", "shower", "showers", "lower", "lowers", "lowered", "lowest",
        "slower", "slowest", "follow", "follows", "followed", "following", "follower", "followers",
        "yellow", "pillow", "hollow", "willow", "fellow", "mellow", "swallow", "shallow",
        "shadow", "shadows", "window", "windows", "meadow", "widow", "elbow", "rainbow",
        "borrow", "tomorrow", "sorrow", "narrow", "arrow", "arrows", "sparrow",
        "allow", "allows", "allowed", "allowing",
        "vowel", "vowels", "towel", "towels", "bowel", "bowl", "bowls", "owl", "owls", "howl",
        "powder", "browser", "browsers", "crowd", "crowds", "crowded",
        "lawyer", "lawyers", "lawsuit", "lawful", "drawer", "drawers", "hawk", "hawks",
        "awesome", "awful", "awkward", "award", "awards", "aware", "away", "awake", "awaken",
        "jaw", "jaws", "paw", "paws",
        "hardware", "software", "firmware", "malware", "middleware", "warehouse",
        "network", "networks", "framework", "frameworks", "homework", "teamwork", "artwork",
        "work", "works", "worked", "working", "worker", "workers",
        "workflow", "workload", "workout", "workshop", "workspace", "workstation",
        "words", "password", "passwords", "keyword", "keywords", "world", "worlds",
        "worm", "worms", "worn", "worse", "worst", "worth", "worthy", "worship",
        "warm", "warms", "warn", "warns", "warned", "warnings", "ward", "wards", "ware", "wares",
        "want", "wants", "walk", "walks", "wall", "walls", "wallet", "wash", "waste", "watch",
        "way", "ways", "wait", "wake", "wave", "waves", "warrior", "warrant", "warranty",
        "with", "within", "without", "witness", "witch", "width", "wide", "wider", "widest",
        "widget", "widgets", "wife", "wild", "will", "win", "wins", "winner", "winners",
        "wind", "winds", "wine", "wing", "wings", "winter", "wire", "wires", "wireless",
        "wise", "wisdom", "wish", "wizard", "would", "wound", "wood", "wool", "wonder", "worry",
        "web", "website", "websites", "webhook", "webpack", "websocket", "welcome", "well", "west",
        "week", "weeks", "weekend", "weight", "weird",
        "barcode", "unicode", "hardcode", "encode", "decode", "vscode", "xcode", "passcode",
        "target", "targets", "market", "markets", "carpet", "basket", "blanket", "jacket",
        "packet", "pocket", "rocket", "socket", "ticket", "bucket", "bracket", "helmet",
        "planet", "closet", "bullet", "tablet", "toilet", "outlet", "budget", "gadget",
        "garden", "gardens", "carbon", "carton", "cartoon", "pardon", "jargon",
        "margin", "margins", "virgin", "bargain", "captain", "certain", "curtain",
        "fountain", "mountain", "domain", "remain", "contain", "obtain", "maintain", "explain",
        "partner", "partners", "parcel", "partial", "particle", "particular", "partition", "party",
        "depart", "department", "apartment", "marble", "marvel", "marker", "markers", "markup",
        "harvest", "harmony", "harbor", "harder", "hardest", "hardly", "hazard",
        "normal", "formal", "formula", "former", "perform", "inform", "confirm", "transform", "platform",
        "morning", "corner", "corners", "border", "borders", "order", "orders", "ordered", "ordering",
        "record", "records", "accord", "afford", "lord", "cord", "sword", "discord",
        "forward", "forwards", "backward", "backwards", "upward", "outward", "inward", "reward",
        "short", "shorter", "shortest", "shortcut", "sport", "sports", "sort", "sorts",
        "port", "ports", "portal", "portable", "portion", "portrait", "fort", "fortune",
        "foreign", "forest", "forever", "forget", "forgive", "fork", "form", "forms",
        "storm", "storms", "born", "corn", "horn", "horns", "torn", "pork", "cork", "york",
        "norm", "norms", "dorm", "organ", "organize", "organization", "orbit", "ordinary",
        "servers", "services", "versions", "persons", "personal", "percent", "perfect", "period", "permit",
        "number", "numbers", "member", "members", "remember", "center", "centers", "central",
        "enter", "enters", "pointer", "pointers", "counter", "master", "masters", "faster", "fastest",
        "poster", "cluster", "register", "sister", "chapter", "quarter", "reporter", "character",
        "filters", "shelter", "writer", "meter", "parameter", "computer", "router", "routers",
        "editor", "editors", "monitor", "monitors", "visitor", "operator", "generator",
        "factor", "factors", "factory", "actor", "doctor", "vector", "sector", "director",
        "mentor", "investor", "motor", "author", "authors", "major", "minor", "senior", "junior",
        "prior", "priority", "behavior", "favor", "favorite", "labor", "neighbor", "humor",
        "mirror", "error", "errors", "cursor", "sensor", "processor", "color", "colors", "vendor", "tailor",
        "render", "sender", "tender", "gender", "under", "understand", "elder", "older",
        "folder", "folders", "holder", "shoulder", "builder", "spider", "provider",
        "leader", "reader", "header", "headers", "loader", "shader", "modern", "intern",
        "journal", "journey", "turn", "turns", "return", "returns", "burn", "burns",
        "earn", "learn", "concern", "govern", "government", "term", "terms", "firm", "firms",
        "first", "burst", "thirst", "moist", "hoist",
        "lexer", "parser", "compiler", "interpreter", "debugger", "profiler", "logger",
        "adapter", "wrapper", "mapper", "helper", "handler", "listener", "observer",
        "subscriber", "publisher", "consumer", "producer", "dispatcher", "controller",
        "manager", "component", "container", "database", "storage", "session", "cookie",
        "token", "refresh", "access", "request", "response", "payload", "endpoint",
        "stream", "channel", "queue", "queues", "queued", "thread", "threads", "process",
        "runtime", "memory", "reference", "instance", "object", "objects", "reject",
        "rejects", "rejected", "project", "projects", "subject", "subjects", "select",
        "selects", "selected", "connect", "connects", "connected", "protect", "protected",
        "expect", "expected", "inspect", "respect", "direct", "correct", "effect",
        "effects", "detect", "detected", "collect", "reflect", "conflict", "predict",
        "strict", "district", "contact", "contract", "extract", "impact", "compact",
        "product", "products", "conduct", "construct", "instruct", "passport",
        "passports", "passkey", "passkeys", "crossword", "classroom",
        "wi", "there", "where", "here", "were", "these", "those", "whose", "chosen",
        "more", "chore", "bore", "tore", "wore", "shore", "store", "stores", "stored",
        "score", "scores", "ignore", "ignored", "restore", "restored", "explore",
        "explorer", "before", "therefore", "hire", "hires", "hired", "tire", "tires",
        "tired", "entire", "retire", "require", "requires", "required", "inspire",
        "expire", "desire", "admire", "empire", "pure", "purely", "sure", "surely",
        "ensure", "insure", "assure", "secure", "security", "cure", "cures", "cured",
        "lure", "nature", "feature", "features", "future", "picture", "pictures",
        "structure", "structures", "architecture", "culture", "capture", "gesture",
        "lecture", "mixture", "moisture", "posture", "texture", "adventure", "creature",
        "furniture", "literature", "signature", "temperature", "measure", "pleasure",
        "treasure", "pressure", "exposure", "closure", "leisure", "figure",
        "configure", "failure", "procedure", "gatsby", "bootstrap", "zoom", "zero", "zone",
        "piece", "pieces", "niece", "nieces", "chose", "refuse", "refused", "refuses",
        "refusing", "refusal", "peruse", "perused", "peruses", "purse", "purses",
        "curse", "curses", "cursed", "cursing", "emerge", "emerged", "emerges",
        "emerging", "emergency", "emergencies", "vue", "o2o",
        "mere", "dire", "rise", "rises", "risen", "rising", "reuse", "reused",
        "reuses", "reusing", "reusable", "refer", "refers", "referred", "referring",
        "referral", "reset", "resets", "resetting", "resort", "resorts", "reform",
        "reforms", "reformed", "deform", "deformed", "defrost", "defence", "defences",
        "defend", "defends", "defended", "defending", "defender", "defendant",
        "deed", "deeds", "deem", "deemed", "deems",
        "seem", "seems", "seemed", "seeming", "seemingly", "sofa", "sofas",
        "chief", "chiefs", "chiefly", "thief", "thieves", "tier", "tiers", "pier", "piers",
        "siege", "besiege", "liege", "fiend", "fiends", "diesel",
        "keep", "keeps", "peep", "peeps", "troop", "troops", "poop",
        "roast", "roasts", "roasted", "boast", "boasts", "coast", "coasts", "coastal",
        "boats", "coats", "goats", "soaps", "rooms", "booms", "moons",
        "roar", "roars", "soars", "oars", "roofs",
        "two", "twos", "twofold", "pair", "pairs",
        "chairman", "chairmen", "chairwoman", "chairperson", "armchair", "armchairs", "wheelchair", "wheelchairs",
        "aura", "auras", "austere", "austerity",
        "dues", "hues", "cues", "sues", "rues", "guest", "guests",
        "bars", "cars", "mars", "tars", "wars", "honors", "donors", "hers",
        "cheers", "cheered", "cheering", "cheerful", "veers", "veered", "veering",
        "hairs", "chairs", "lairs", "choirs", "moors", "boors", "boar", "boars", "soar",
        "lore", "ore", "ores", "pore", "pores",
        "chefs", "refs", "reefs", "beefs", "hoofs", "nerfs", "serfs",
        "gulf", "gulfs", "golf", "golfs", "wolf", "wolfs",
        "nerf", "serf", "kerf", "miser",
        "boxes", "boxer", "boxers", "mixes", "mixer", "mixers",
        "vexes", "hexes", "sexes", "lexus", "oxen", "vixen", "thorax", "xerox",
        "display", "displays", "muscle", "muscles", "castle", "castles",
        "hustle", "hustles", "bustle", "bustles", "thistle", "thistles",
        "pestle", "pestles", "nestle", "nestles", "trestle", "trestles",
        "beetle", "beetles", "chestnut", "chestnuts", "dustbin", "dustpan", "passbook",
        "died", "dies", "ties", "pies", "lies", "vies", "tries", "trier", "bier", "biers",
        "diet", "diets", "dieted", "dieting", "quiet", "quiets", "quieted", "quieter", "quietest", "quietly",
        "goes", "does", "foes", "woes", "roes", "noes", "toes", "hoes",
        "trees", "sees", "buys", "guys", "pays", "puts", "taxis", "sixes",
        "pasta", "pastas", "rasta", "basta", "lisp", "lisps", "gasp", "gasps", "rasp", "rasps", "cusp", "cusps",
        "pass", "mass", "lass", "less", "mess", "guess", "chess",
        "kiss", "miss", "hiss", "piss", "boss", "loss", "moss", "toss",
        "cuss", "muss", "puss", "truss",
        "chaff", "quaff", "cheff", "tiff", "biff", "miff", "riff",
        "off", "doff", "toff", "cuff", "puff", "muff", "ruff", "tuff",
        "purr", "burr", "curr", "err",
        "moats", "moans", "roams", "coax", "coaxes", "coaxed",
        "doom", "dooms", "loom", "looms", "goop", "goops", "goons", "loons",
        "teems", "teens", "queens", "keen", "keens", "keenly", "cheep", "cheeps",
        "airs", "haircut", "haircuts", "hairpin", "hairpins", "hairnet", "hairless", "airless"
    ]
}

public enum EnglishRestoreDetector {
    
    /// Technical separators connecting sub-tokens in URLs, domains, paths, and identifiers.
    public static let technicalSeparators: Set<Character> = [".", "/", "@", "-", "_"]

    /// Known technical extensions, TLDs, and segments following separators that must not transform to Vietnamese.
    public static let technicalExtensions: Set<String> = [
        "or", "us", "es", "tw", "aw",
        "md", "ts", "rs", "css", "sh", "swift", "json",
        "co", "jp", "vn", "com", "org", "net", "edu", "gov", "io", "ai",
        "js", "py", "rb", "go", "cpp", "yaml", "yml", "toml", "xml", "html",
        "sql", "txt", "log", "tar", "gz", "zip", "app", "dev", "me", "cc"
    ]

    /// Specific segments immediately following technical separators that collide with Vietnamese syllables.
    public static let collidingExtensions: Set<String> = [
        "or", "us", "es", "tw", "aw", "tar"
    ]

    public static func isTechnicalSeparator(_ char: Character) -> Bool {
        technicalSeparators.contains(char)
    }

    public static func isTechnicalExtension(_ ext: String) -> Bool {
        technicalExtensions.contains(ext.lowercased())
    }

    public static func isCollidingExtension(_ ext: String) -> Bool {
        collidingExtensions.contains(ext.lowercased())
    }
    
    /// Delimiter characters that terminate a word and reset English bypass.
    public static let wordDelimiters: Set<Character> = [
        " ", "\t", "\n", "\r",
        ".", ",", "!", "?", ":", ";", "/", "\\",
        "-", "_", "(", ")", "[", "]", "{", "}",
        "\"", "'", "`", "@", "#", "$", "%", "^",
        "&", "*", "+", "=", "<", ">", "|", "~"
    ]

    /// Invalid onset consonant clusters in Vietnamese (English-only clusters).
    public static let invalidOnsetClusters: Set<String> = [
        "br", "cr", "dr", "fr", "gr", "pr", "str",
        "sc", "sk", "sl", "sm", "sn", "sp", "st", "sw",
        "fl", "gl", "cl", "bl", "pl", "kn", "gn", "wr", "wh",
        "sh", "ts"
    ]

    /// Invalid coda consonant clusters in Vietnamese (English-only codas).
    public static let invalidCodaClusters: Set<String> = [
        "st", "nd", "nt", "rt", "rd", "ld", "rk", "rm", "rn",
        "lp", "lt", "lf", "mp", "ct", "ft", "ck", "ll",
        "bb", "gg", "th", "sh", "ph", "gh", "kh",
        "tl", "cl", "pl", "nl", "ml"
    ]

    /// English medial double-consonant + vowel/consonant sequences that never occur in valid Vietnamese words.
    public static let invalidMedialDoubleConsonants: [String] = [
        "tta", "tte", "tti", "tto", "ttu", "tty",
        "lla", "lle", "lli", "llo", "llu", "lly",
        "ppa", "ppe", "ppi", "ppo", "ppu", "ppy",
        "bba", "bbe", "bbi", "bbo", "bbu", "bby",
        "ffa", "ffe", "ffi", "ffo", "ffu", "ffy", "ffl", "ffs", "ffh", "ffr",
        "mma", "mme", "mmi", "mmo", "mmu", "mmy",
        "nna", "nne", "nni", "nno", "nnu", "nny",
        "cca", "cce", "cci", "cco", "ccu", "ccy", "cch",
        "rra", "rre", "rri", "rro", "rru", "rry",
        "ssa", "sse", "ssi", "sso", "ssu", "ssy",
        "ssw", "ssc", "ssp", "ssk", "ssr", "ssh", "ssl", "ssm", "ssn",
        "ssb", "ssd", "ssf", "ssg", "sst", "ssv"
    ]

    /// English 'sw-', 'tw-', 'dw-', and 'thw-' prefixes that are not valid Vietnamese 'sư-' / 'tư-' / 'dư-' / 'thư-' syllables in Telex.
    public static let invalidTelexSwPrefixes: [String] = [
        "swi", "swe", "swap", "swan", "swat", "swam", "swag", "swor", "swu", "swarm",
        "twi", "twe",
        "dwi", "dwe", "dwarf", "dwarv",
        "thwart"
    ]

    /// Voiceless stop codas that can ONLY take Acute (sắc) or Dot (nặng) tones.
    public static let stopCodas: Set<String> = ["c", "ch", "p", "t", "k"]

    public static func isWordDelimiter(_ char: Character) -> Bool {
        wordDelimiters.contains(char)
    }

    public static func hasInvalidOnsetCluster(_ onset: String) -> Bool {
        let lower = onset.lowercased()
        for cluster in invalidOnsetClusters {
            if lower.hasPrefix(cluster) { return true }
        }
        return false
    }

    public static func hasInvalidCodaCluster(_ coda: String) -> Bool {
        let lower = coda.lowercased()
        for cluster in invalidCodaClusters {
            if lower.hasSuffix(cluster) || lower == cluster { return true }
        }
        return false
    }

    public static func hasInvalidMedialDoubleConsonant(_ rawWord: String) -> Bool {
        let lower = rawWord.lowercased()
        guard lower.count >= 4 else { return false }
        for pattern in invalidMedialDoubleConsonants {
            if lower.contains(pattern) { return true }
        }
        return false
    }

    public static func hasInvalidTelexSwPrefix(_ rawWord: String) -> Bool {
        let lower = rawWord.lowercased()
        for prefix in invalidTelexSwPrefixes {
            if lower.hasPrefix(prefix) { return true }
        }
        return false
    }

    public static func violatesStopCodaRestriction(coda: String, tone: Tone) -> Bool {
        let lower = coda.lowercased()
        guard stopCodas.contains(lower) else { return false }
        switch tone {
        case .grave, .hook, .tilde:
            return true
        case .none, .acute, .dot:
            return false
        }
    }

    public static func isEnglishKeyword(_ word: String) -> Bool {
        EnglishKeywords.commonKeywords.contains(word.lowercased())
    }

    /// Evaluates whether composition should be broken and restored to raw English.
    public static func shouldBreakComposition(
        rawWord: String,
        onset: String,
        coda: String,
        tone: Tone,
        isCvcValid: Bool,
        autoCorrectEnabled: Bool
    ) -> Bool {
        guard autoCorrectEnabled else { return false }

        // Rule 1: Known English keyword match
        if isEnglishKeyword(rawWord) || hasInvalidMedialDoubleConsonant(rawWord) {
            return true
        }

        // Rule 2: Invalid onset or coda consonant clusters
        if hasInvalidOnsetCluster(onset) || hasInvalidCodaCluster(coda) {
            return true
        }
        
        // Check if rawWord starts with or ends with invalid clusters
        let lowerRaw = rawWord.lowercased()
        for cluster in invalidOnsetClusters {
            if lowerRaw.hasPrefix(cluster) { return true }
        }
        for cluster in invalidCodaClusters {
            if lowerRaw.hasSuffix(cluster) { return true }
        }

        // Rule 3: Stop coda tone violation
        if violatesStopCodaRestriction(coda: coda, tone: tone) {
            return true
        }

        // Rule 4: Formal CVC phonotactic matrix failure
        if !isCvcValid {
            return true
        }

        return false
    }
}
