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
        "make", "build", "debug", "release", "const", "vars", "vary", "varies", "varied", "varying",
        "variable", "variables", "variance", "variant", "variants", "variation", "variations", "variety", "varieties", "various", "varnish", "varsity",
        "let", "func", "function",
        "public", "private", "fileprivate", "internal", "open", "static", "final",
        "class", "enum", "protocol", "extension", "typealias", "associatedtype",
        "async", "await", "actor", "sendable", "init", "deinit", "subscript", "self",
        "super", "nil", "null", "none", "some", "any", "where", "for", "in", "info", "into", "inside", "install", "instead", "instant", "insert", "insist", "infant", "infect", "infer", "repeat",
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
        "purr", "burr", "curr", "err", "arr",
        "moats", "moans", "roams", "coax", "coaxes", "coaxed",
        "doom", "dooms", "loom", "looms", "goop", "goops", "goons", "loons",
        "teems", "teens", "queens", "keen", "keens", "keenly", "cheep", "cheeps",
        "airs", "haircut", "haircuts", "hairpin", "hairpins", "hairnet", "hairless", "airless",
        "chair", "lair", "sire", "sires", "sired", "mire", "mires", "mired",
        "muse", "muses", "mused", "musing", "ruse", "ruses",
        "goer", "goers", "doer", "doers", "poem", "poems", "poet", "poets", "duet", "duets",
        "photo", "photos", "homo", "phono", "exo", "moron", "morons", "loco", "coco",
        "dojo", "dojos", "mojo", "boost", "roost", "goofs", "swops", "bias",
        "sass", "sassy", "brass", "glass", "grass", "class",
        "laws", "raws", "saws", "gawk", "gawks", "bawk", "bawks",
        "mohawk", "mohawks", "tomahawk", "tomahawks", "lora", "qlora",
        "arms", "harms", "charms", "barns", "darns", "urns", "churns",
        "thorns", "morns", "terns", "kerns", "berms", "perms", "barfs",
        "naifs", "coifs", "loafs", "oafs", "liars", "leers", "seers",
        "queer", "queers", "corsair", "corsairs", "chasm", "chasms",
        "disc", "discs", "tues", "duos",
        "life", "lifelong", "lifestyle", "lifetime", "lifespan", "lifeguard",
        "lifeline", "lifeless", "wildlife", "afterlife", "nightlife", "midlife",
        "minx", "minxes", "manx", "bronx", "spanx", "sans",
        "axis", "axes", "axon", "axons", "axiom", "axioms",
        "thaw", "thaws", "thawed", "thawing",
        "hero", "heroes", "heroic", "heroin", "heroine", "heroism", "nero",
        "morn", "corm", "porn", "loris",
        "pars", "irs", "sirs", "dirs", "ors", "urs", "ers", "roots", "harz",
        "rife", "ajar", "ajax", "maxi", "maxis", "taxi", "trex", "tuxes", "luxe",
        "berm", "berms", "derm", "dermis", "churn", "churns", "urn", "urns", "ire",
        "barn", "barns", "darn", "darns", "tarn", "tarns", "barf", "barfs",
        "harm", "harms", "charm", "charms", "thorn", "thorns",
        "curs", "burs", "vers", "fers", "oofs", "goof",
        "caws", "maws", "haws", "sere",
        "won", "wow", "wows", "yens", "kern",
        "hex", "nix", "tux", "dux",
        "ufo", "ufos", "nasa", "taxa",
        "memes", "themes", "beset", "besets", "xanax",
        "dodos", "gotos", "topos", "mamas", "datas", "nonos", "rojos", "toxo", "roxo",
        "noop", "noops", "dadas", "hies", "lire", "lise", "vire", "vise", "vises", "quasar", "quasars", "hangars",
        "loofs", "siete", "data", "goto", "sata", "toto", "loto", "topo", "sapa", "napa", "tapa", "capa", "poco",
        "choco", "quoto", "chara", "charas", "boron", "tureen", "tureens", "siren", "sirens", "bisect", "bisects", "bisected",
        "tested", "tester", "testers", "termed", "kerned", "kernel", "kernels"
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
        "sql", "txt", "log", "tar", "var", "gz", "zip", "app", "dev", "me", "cc"
    ]

    /// Specific segments immediately following technical separators that collide with Vietnamese syllables.
    public static let collidingExtensions: Set<String> = [
        "or", "us", "es", "tw", "aw", "tar", "var"
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
        "sh", "ts", "cc", "nn", "bc", "gc"
    ]

    /// Invalid coda consonant clusters in Vietnamese (English-only codas).
    public static let invalidCodaClusters: Set<String> = [
        "st", "nd", "nt", "rt", "rd", "ld", "rk", "rm", "rn",
        "lp", "lt", "lf", "mp", "mb", "ct", "ft", "ck", "ll",
        "bb", "gg", "th", "sh", "ph", "gh", "kh",
        "tl", "cl", "pl", "nl", "ml", "cc", "nn"
    ]

    /// English medial double-consonant + vowel/consonant sequences that never occur in valid Vietnamese words.
    public static let invalidMedialDoubleConsonants: [String] = [
        "tta", "tte", "tti", "tto", "ttu", "tty",
        "lla", "lle", "lli", "llo", "llu", "lly",
        "ppa", "ppe", "ppi", "ppo", "ppu", "ppy",
        "bba", "bbe", "bbi", "bbo", "bbu", "bby",
        "ffa", "ffe", "ffi", "ffo", "ffu", "ffy", "ffl", "ffs", "ffh", "ffr",
        "mma", "mme", "mmi", "mmo", "mmu", "mmy",
        "nna", "nne", "nni", "nno", "nnu", "nny", "nnx", "dnn", "nnl", "nns",
        "cca", "cce", "cci", "cco", "ccu", "ccy", "cch",
        "rra", "rre", "rri", "rro", "rru", "rry", "rrh", "rrs",
        "ssa", "sse", "ssi", "sso", "ssu", "ssy",
        "ssw", "ssr", "ssh", "ssl", "ssm", "ssn", "ssb"
    ]

    /// English 'sw-', 'tw-', 'dw-', and 'thw-' prefixes that are not valid Vietnamese 'sư-' / 'tư-' / 'dư-' / 'thư-' syllables in Telex.
    public static let invalidTelexSwPrefixes: [String] = [
        "swi", "swe", "swap", "swan", "swat", "swam", "swag", "swor", "swu", "swarm", "swarth",
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

    /// Returns the substring after the last technical separator (`.`, `/`, `@`, `-`, `_`), or the original string if none is present.
    public static func tokenAfterLastSeparator(_ text: String) -> String {
        if let lastSepIdx = text.lastIndex(where: { isTechnicalSeparator($0) }) {
            return String(text[text.index(after: lastSepIdx)...])
        }
        return text
    }

    // MARK: - Smart Lexicon / Stem Disambiguation for Telex Double-Key Escape

    /// True double-s stems before a vowel (a, e, i, o, u).
    private static let trueDoubleSVowelStems: Set<String> = [
        // -ess-
        "me", "se", "le", "gue", "che", "dre", "stre", "ble", "ve", "te",
        "addre", "obse", "asse", "posse", "nece",
        // -iss-
        "i", "ti", "fi", "mi", "ki", "hi", "pi", "bli", "swi", "sci",
        // -ass-
        "a", "pa", "ma", "cla", "gla", "gra", "bra", "sa", "ta", "qua", "wa",
        "hara", "emba", "amba", "carca", "canva", "compa", "surpa", "bypa", "trespa",
        // -oss-
        "bo", "mo", "to", "cro", "glo", "flo", "fo", "go", "blo", "co", "colo", "opo", "embo", "acro",
        // -uss-
        "cu", "pu", "tu", "discu", "concu", "percu", "repercu", "bru"
    ]

    /// True double-s stems before 'h' (Japanese Romaji geminate 'ssh' and English 'crosshair').
    private static let trueDoubleSHStems: Set<String> = [
        "i", "a", "e", "o", "u",
        "ira", "za", "re", "ha", "ke", "se", "ni", "bu", "sa", "ra", "ma",
        "shu", "ta", "te", "ka", "mi", "ho", "to", "yo", "yu", "ro",
        "ga", "ge", "gi", "go", "da", "de", "do", "ba", "be", "bo",
        "pa", "pe", "po", "ku", "su", "tsu", "fu", "mu", "nyuu"
    ]

    /// True double-f stems before a vowel or consonant.
    private static let trueDoubleFStems: Set<String> = [
        "a", "e", "o", "i",
        "co", "di", "su", "bu", "mu", "ru", "pu", "cu", "du", "flu", "scu", "shu", "stu", "snu", "blu", "tu",
        "ti", "mi", "bi", "ri", "sti", "cli", "whi", "ski", "spi", "sni", "gri",
        "cha", "qua", "sta", "gra", "ga", "ba", "ra", "wa", "sna", "sca", "ta", "da", "tra",
        "do", "to", "bo", "sco"
    ]

    /// True double-r stems before 'a'.
    private static let trueDoubleRAStems: Set<String> = [
        "a", "wa", "ba", "ca", "ma", "na", "ta", "te", "fe", "se", "co", "to", "cu", "hu", "embo", "emba", "har", "emb"
    ]

    /// True double-r stems before 'e' (note: bare->barrel/barren/barred, cure->current, core->correct, tore->torrent, sure->surrender, pure->purred, refere->referred are restored on the next char).
    private static let trueDoubleREStems: Set<String> = [
        "e", "occu", "recu", "incu", "concu", "fe", "te", "inte", "dete",
        "bu", "squi", "qua", "wa", "ga", "blu", "slu", "spu", "sti", "whi"
    ]

    /// True double-r stems before 'i'.
    private static let trueDoubleRIStems: Set<String> = [
        "a", "ca", "ma", "ba", "ha", "pa", "ta", "ga", "wa",
        "be", "che", "fe", "me", "te", "pe",
        "co", "ho", "to", "wo", "so", "lo",
        "hu", "bu", "fu", "pu", "scu", "flu", "blu", "i"
    ]

    /// True double-r stems before 'o'.
    private static let trueDoubleROStems: Set<String> = [
        "e", "mi", "a", "na", "spa", "ma", "ha", "ba", "fa", "ya",
        "bo", "to", "omo", "so", "fu", "bu", "cu", "ho", "te", "co", "su", "inter"
    ]

    /// True double-r stems before 'u'.
    private static let trueDoubleRUStems: Set<String> = [
        "cu", "fe", "ci", "su", "inte", "co", "ba", "ve"
    ]

    /// True double-r stems before 'y'.
    private static let trueDoubleRYStems: Set<String> = [
        "ca", "ma", "ha", "pa", "ba", "ta", "sta", "spa", "qua",
        "so", "wo", "lo", "to", "bo",
        "fe", "me", "be", "che", "je", "ke", "te", "pe",
        "cu", "hu", "fu", "mu", "su", "bu", "blu", "flu", "scu"
    ]

    /// True double-d stems before a vowel.
    private static let trueDoubleDStems: Set<String> = [
        "a", "su", "embe", "pa", "we", "be", "pu", "bi", "ki",
        "bla", "ma", "sa", "o", "re", "u", "ru", "shu", "fo", "to",
        "mu", "bu", "te", "gi", "ca", "shre", "sk", "sl", "sp", "st", "gr"
    ]

    /// Determines whether a double Telex key (`ss`, `ff`, `rr`, `xx`, `jj`, `dd`) before `nextChar`
    /// belongs to a genuine double-letter English or Romaji word (`true`), or is a Telex escape on a
    /// single-letter English word that should collapse to a single letter (`false`).
    public static func shouldKeepDoubleTelexKey(
        stem: String,
        activeStem: String,
        key: String,
        nextChar: String
    ) -> Bool {
        var s = tokenAfterLastSeparator(stem).lowercased()
        var a = tokenAfterLastSeparator(activeStem).lowercased()
        if s.hasPrefix("dd") && !s.hasPrefix("ddd") {
            s = String(s.dropFirst())
        }
        if a.hasPrefix("dd") && !a.hasPrefix("ddd") {
            a = String(a.dropFirst())
        }
        let k = key.lowercased()
        let next = nextChar.lowercased()

        guard !s.isEmpty, !next.isEmpty else { return true }
        let lastStemChar = s.last!
        let stemEndsWithVowel = "aeiouy".contains(lastStemChar)
        let nextIsVowel = "aeiouy".contains(next)

        switch k {
        case "x":
            // Only 'exxon' has legitimate medial 'xx'
            return (s == "e" || a == "e") && next == "o"

        case "j":
            // Only 'hajj' / 'hajji' has legitimate medial 'jj'
            return s == "ha" || a == "ha"

        case "s":
            guard stemEndsWithVowel else {
                // Consonant before 'ss' (e.g. 'firsst', 'bursst', 'conssole', 'persson', 'curssor', 'elsse', 'falsse', 'pulsse', 'alsso', 'abssent', 'obsserve', 'subsset'): always collapse
                return false
            }
            if !nextIsVowel {
                switch next {
                case "h":
                    return s.hasSuffix("cro")
                        || trueDoubleSHStems.contains(s)
                        || trueDoubleSHStems.contains(a)
                case "t":
                    return (s.hasSuffix("cla") && s != "cla")
                        || s.hasSuffix("cro")
                        || s.hasSuffix("gla")
                        || s.hasSuffix("gra")
                        || s.hasSuffix("le")
                case "k":
                    return s.hasSuffix("pa")
                        || s.hasSuffix("cro")
                        || (s.hasSuffix("cla") && s != "cla")
                        || s.hasSuffix("gla")
                        || s.hasSuffix("le")
                case "p":
                    return s == "mi" || a == "mi"
                        || s.hasSuffix("pa")
                        || s.hasSuffix("cro")
                        || (s.hasSuffix("cla") && s != "cla")
                        || s.hasSuffix("gla")
                        || s.hasSuffix("le")
                case "c":
                    return s.hasSuffix("pa")
                        || s.hasSuffix("cro")
                        || (s.hasSuffix("cla") && s != "cla")
                        || s.hasSuffix("gla")
                        || s.hasSuffix("le")
                default:
                    if (s == "wi" || a == "wi") && next == "d" {
                        return false // 'wissdom' -> 'wisdom'
                    }
                    return true
                }
            }
            // nextChar is a vowel (a, e, i, o, u, y)
            if next == "y" {
                return !["ea", "bu", "no", "ro", "co", "dai", "noi"].contains(s)
            }
            for candidate in [s, a] where !candidate.isEmpty {
                if trueDoubleSVowelStems.contains(candidate)
                    || candidate == "pe"
                    || candidate.hasSuffix("pe")
                    || candidate == "mi"
                    || (candidate.hasSuffix("mi") && next == "i")
                    || candidate.hasSuffix("pa")
                    || candidate.hasSuffix("ma")
                    || candidate.hasSuffix("cla")
                    || candidate.hasSuffix("gla")
                    || candidate.hasSuffix("gra")
                    || candidate.hasSuffix("bra")
                    || candidate.hasSuffix("cro")
                    || candidate.hasSuffix("bo")
                    || candidate.hasSuffix("to")
                    || candidate.hasSuffix("lo")
                    || candidate.hasSuffix("mo")
                    || candidate.hasSuffix("glo")
                    || candidate.hasSuffix("flo")
                    || candidate.hasSuffix("bl")
                    || candidate.hasSuffix("dr")
                    || candidate.hasSuffix("pr")
                    || candidate.hasSuffix("st")
                    || candidate.hasSuffix("gu")
                    || candidate.hasSuffix("ru") {
                    if candidate == "ba" && next != "o" { continue } // base/basic -> 1 's' (basses restored on 3rd 's')
                    if candidate == "ca" && !"ao".contains(next) { continue } // case/casino -> 1 's' (cassette/casserole restored on next char)
                    if candidate == "la" && !"io".contains(next) { continue } // laser -> 1 's' (lasses restored on next 's')
                    if candidate == "lo" && next == "e" { continue } // lose/loser -> 1 's' (losses restored on next 's')
                    if candidate == "clo" || candidate.hasSuffix("clo") { continue } // close/closer/closest -> 1 's'
                    if candidate == "pa" && next == "e" { continue } // phase -> 1 's'
                    if candidate == "pre" && !"ui".contains(next) { continue } // present/preserve -> 1 's' (pressed/presses restored on next char)
                    if candidate == "pro" && !"e".contains(next) { continue } // prosecute -> 1 's'
                    return true
                }
                if candidate == "po" && "iu".contains(next) { return true } // possible, possum (pose/position/positive -> 1 's', possess restored on next 's')
                if candidate == "di" && "oi".contains(next) { return true } // dissolve, dissipate (disable/disease -> 1 's')
                if candidate == "ca" && "ao".contains(next) { return true } // cassava, cassock
                if candidate == "ba" && next == "o" { return true } // bassoon
                if candidate == "la" && "io".contains(next) { return true } // lassi, lasso
                if candidate == "cha" && next == "i" { return true } // chassis
                if candidate == "pre" && "ui".contains(next) { return true } // pressure, pressing
                if candidate == "de" && next == "e" { return false } // desert/deserve
                if candidate == "ru" && next == "i" { return true } // russian, russia
                if candidate == "fu" && next == "y" { return true } // fussy
                if candidate.count >= 3 && (
                    candidate.hasSuffix("ce")
                    || candidate.hasSuffix("fe")
                    || candidate.hasSuffix("gre")
                    || (candidate.hasSuffix("pre") && candidate != "pre")
                    || candidate.hasSuffix("tre")
                    || candidate.hasSuffix("ne")
                    || candidate.hasSuffix("le")
                ) {
                    return true
                }
            }
            return false

        case "f":
            guard stemEndsWithVowel else { return false }
            if next == "t" {
                return s == "o"
                    || s.hasSuffix("sti")
                    || s.hasSuffix("cli")
                    || s.hasSuffix("sta")
                    || s.hasSuffix("blu")
                    || s.hasSuffix("stu")
            }
            if next == "l" || next == "r" {
                if (s == "de" || a == "de" || s == "re" || a == "re") && next == "r" {
                    return false // 'deffrost' -> 'defrost', 'reffresh' -> 'refresh'
                }
                return true
            }
            if trueDoubleFStems.contains(s) || trueDoubleFStems.contains(a) {
                return true
            }
            for candidate in [s, a] where candidate.count >= 2 {
                if candidate.hasSuffix("a")
                    || candidate.hasSuffix("e")
                    || candidate.hasSuffix("o")
                    || candidate.hasSuffix("i")
                    || candidate.hasSuffix("u") {
                    // Single-f exceptions: safe, life, wife, knife, strife, cafe, default, define, defend, defeat, defect, defer, before, refer, prefer, info, sofa, tofu, wifi, hifi, ufo, chef, brief, chief, grief, leaf, deaf, beef, reef, roof, proof, hoof, loaf, half, calf, wolf, self, shelf, golf, gulf
                    let singleFStems: Set<String> = [
                        "sa", "li", "wi", "kni", "stri", "ca", "de", "be", "re", "pre",
                        "in", "so", "to", "hi", "u", "che", "brie", "chie", "grie",
                        "lea", "dea", "bee", "ree", "roo", "proo", "hoo", "loa",
                        "hal", "cal", "wol", "sel", "shel", "gol", "gul", "ra", "wa"
                    ]
                    if !singleFStems.contains(candidate) {
                        return true
                    }
                }
            }
            return false

        case "r":
            guard stemEndsWithVowel else { return false }
            if !nextIsVowel {
                if next == "h" { return true } // diarrhea, cirrhosis, myrrh, catarrh
                if (s == "patte" || a == "patte") && next == "n" { return true }
                if next == "s" {
                    return ["pu", "bu", "cu", "e", "whi", "chi"].contains(s)
                        || ["pu", "bu", "cu", "e", "whi", "chi"].contains(a)
                }
                return false
            }
            switch next {
            case "a":
                return trueDoubleRAStems.contains(s)
                    || trueDoubleRAStems.contains(a)
                    || s.hasSuffix("fe")
                    || s.hasSuffix("ba")
                    || s.hasSuffix("ra")
                    || s.hasSuffix("ta")
                    || s.hasSuffix("wa")
                    || s.hasSuffix("na")
            case "e":
                return trueDoubleREStems.contains(s)
                    || trueDoubleREStems.contains(a)
                    || (s.hasSuffix("cu") && s != "cu")
                    || s.hasSuffix("te")
                    || s.hasSuffix("qua")
            case "i":
                return trueDoubleRIStems.contains(s)
                    || trueDoubleRIStems.contains(a)
                    || s.hasSuffix("ca")
                    || s.hasSuffix("ma")
                    || s.hasSuffix("ba")
                    || s.hasSuffix("wa")
                    || s.hasSuffix("te")
                    || s.hasSuffix("ho")
                    || s.hasSuffix("co")
                    || s.hasSuffix("wo")
                    || s.hasSuffix("hu")
                    || s.hasSuffix("cu")
            case "o":
                return trueDoubleROStems.contains(s)
                    || trueDoubleROStems.contains(a)
                    || s.hasSuffix("su")
                    || s.hasSuffix("bo")
                    || s.hasSuffix("mo")
                    || s.hasSuffix("to")
                    || s.hasSuffix("te")
                    || s.hasSuffix("co")
                    || s.hasSuffix("mi")
                    || s.hasSuffix("na")
                    || s.hasSuffix("a")
            case "u":
                return trueDoubleRUStems.contains(s)
                    || trueDoubleRUStems.contains(a)
                    || s.hasSuffix("te")
                    || s.hasSuffix("cu")
                    || s.hasSuffix("su")
                    || s.hasSuffix("co")
            case "y":
                return trueDoubleRYStems.contains(s)
                    || trueDoubleRYStems.contains(a)
                    || s.hasSuffix("ca")
                    || s.hasSuffix("ma")
                    || s.hasSuffix("ba")
                    || s.hasSuffix("wo")
                    || s.hasSuffix("so")
                    || s.hasSuffix("lo")
                    || s.hasSuffix("fe")
                    || s.hasSuffix("be")
                    || s.hasSuffix("che")
                    || s.hasSuffix("hu")
                    || s.hasSuffix("cu")
                    || s.hasSuffix("fu")
            default:
                return false
            }

        case "d":
            guard stemEndsWithVowel else { return false }
            if next == "l" || next == "r" || next == "n" {
                return true // middle, middleware, paddle, address, cudnn
            }
            if (s == "no" || a == "no") && next == "i" {
                return true // nodding
            }
            if (s == "la" || a == "la") && next == "e" {
                return true // ladder
            }
            return trueDoubleDStems.contains(s)
                || trueDoubleDStems.contains(a)
                || s.hasSuffix("be")
                || s.hasSuffix("pa")
                || s.hasSuffix("we")
                || s.hasSuffix("bi")
                || s.hasSuffix("ki")
                || s.hasSuffix("ma")
                || s.hasSuffix("sa")
                || s.hasSuffix("shre")

        default:
            return true
        }
    }

    /// Evaluates whether a word in State 1 (immediately after a non-bypassed Double-Press Tone Undo)
    /// should expand its undone double tone consonant back to 2 consonants.
    public static func shouldExpandUndoneDoubleToneConsonant(
        fullRawWord: String,
        activeRawWord: String
    ) -> Bool {
        let lowerFull = tokenAfterLastSeparator(fullRawWord).lowercased()
        let lowerActive = tokenAfterLastSeparator(activeRawWord).lowercased()
        guard lowerActive.count >= 3 else { return false }
        let nextChar = String(lowerActive.last!)
        let beforeNextFull = String(lowerFull.dropLast())
        let beforeNextActive = String(lowerActive.dropLast())

        for key in ["s", "f", "r", "x", "j"] {
            let kk = key + key
            if beforeNextActive.hasSuffix(kk) {
                if beforeNextActive.hasSuffix(kk + key) {
                    return false
                }
                let fullStem = String(beforeNextFull.dropLast(2))
                let activeStem = String(beforeNextActive.dropLast(2))
                return shouldKeepDoubleTelexKey(
                    stem: fullStem,
                    activeStem: activeStem,
                    key: key,
                    nextChar: nextChar
                )
            }
        }

        return hasInvalidMedialDoubleConsonant(lowerFull) || hasInvalidMedialDoubleConsonant(lowerActive)
    }

    /// Stems in already-bypassed words where a duplicate Telex 'ee' before a consonant/vowel should collapse to 'e'.
    private static let collapseBypassEEStems: Set<String> = [
        "del", "sel", "lev", "dev", "rev", "sev", "nev", "ev",
        "pres", "res", "des", "el", "tel", "cel", "mel", "rel",
        "rep", "dep", "prep", "sep", "def", "ref", "pref",
        "sec", "rec", "dec", "nec", "spec", "exec",
        "proj", "obj", "subj", "rej", "inj",
        "coll", "conn", "corr", "eff", "aff", "suff", "diff", "buff",
        "inter", "enter", "gener", "oper", "moder", "feder", "liter", "numer", "liber"
    ]

    /// Stems in already-bypassed words where 'ee' is a genuine English double-e and must NOT collapse.
    private static let preserveBypassEEStems: Set<String> = [
        "car", "eng", "engin", "pion", "volunt", "guarant", "committ", "employ", "train", "interview", "refug", "pay", "trust", "absen", "attend", "deg", "agr", "disagr", "f", "s", "tr", "fr", "gr", "sp", "st", "sl", "sw", "wh", "ch", "sh", "cr", "br", "dr", "fl", "gl", "pl", "bl", "cl", "sc", "sk", "sm", "sn", "tw", "thr", "scr", "spl", "spr", "str",
        "b", "d", "g", "h", "j", "k", "l", "m", "n", "p", "q", "r", "t", "v", "w", "y", "z",
        "qu", "kn", "wr", "coff", "toff", "suceed", "succ", "proc", "exc", "ind", "br", "st", "tw", "betw", "harl", "canteen", "sixt", "sevent", "eight", "ninet", "thirt", "fourt", "fift", "hall", "scr", "tur"
    ]

    /// Stems in already-bypassed words where a duplicate Telex 'oo' before a consonant should collapse to 'o'.
    private static let collapseBypassOOStems: Set<String> = [
        "rob", "col", "contr", "mon", "phot", "sol", "log", "tod", "got", "aut", "zer", "her", "dem", "mem", "inf", "rep",
        "mod", "cod", "nod", "bod", "fol", "hol", "shoul", "ord", "bord",
        "doc", "doct", "mot", "fact", "act", "vect", "sect", "direct", "edit", "monit", "visit", "operat", "generat",
        "process", "sens", "curs", "err", "mirr", "maj", "min", "seni", "juni", "pri", "auth", "fav", "lab", "hum", "vend", "tail",
        "comm", "butt", "less", "sess", "pers", "vers", "reas", "seas"
    ]

    /// Stems in already-bypassed words where a duplicate Telex 'aa' before a consonant should collapse to 'a'.
    private static let collapseBypassAAStems: Set<String> = [
        "dat", "man", "pack", "stor", "mess", "us", "im", "dam", "vill", "av", "sav", "nav", "cab", "hab", "tab", "lab",
        "bal", "tal", "sal", "mal", "pal", "scal", "whal", "val", "cal", "gal", "fal", "ral",
        "par", "car", "bar", "tar", "mar", "war", "far", "dar", "har", "jar", "sar", "var",
        "shar", "spar", "squar", "awar", "compar", "prepar", "declar", "star", "scar", "glar", "flar",
        "cas", "bas", "phas", "chas", "las", "mas", "pas", "gas", "tas", "vas", "fas", "nas", "ras",
        "saf", "caf", "waf", "spac", "plac", "grac", "trac", "fac", "pac", "rac", "lac",
        "mak", "tak", "bak", "wak", "lak", "shak", "snak", "brak", "stak",
        "fram", "gam", "nam", "sam", "blam", "flam", "sham",
        "gat", "lat", "rat", "stat", "plat", "mat", "hat", "fat", "creat", "updat"
    ]

    /// Evaluates whether a word that is ALREADY in `isBypassed == true` mode and ends with a double Telex key
    /// (`ss`, `ff`, `rr`, `xx`, `jj`, `dd`, `aa`, `ee`, `oo`) should collapse the duplicate key when `nextChar` is typed.
    public static func shouldCollapseDoubleTelexKeyInBypass(
        fullPreedit: String,
        activePreedit: String,
        nextChar: Character
    ) -> Bool {
        let lowerFull = tokenAfterLastSeparator(fullPreedit).lowercased()
        let lowerActive = tokenAfterLastSeparator(activePreedit).lowercased()
        let next = String(nextChar).lowercased()
        guard lowerActive.count >= 2, next.first?.isLetter == true else { return false }

        for key in ["s", "f", "r", "x", "j", "d"] {
            let kk = key + key
            if lowerActive.hasSuffix(kk) && !lowerActive.hasSuffix(kk + key) {
                let fullStem = String(lowerFull.dropLast(2))
                let activeStem = String(lowerActive.dropLast(2))
                if fullStem.isEmpty && key == "d" {
                    return true
                }
                guard !fullStem.isEmpty else { return false }
                return !shouldKeepDoubleTelexKey(
                    stem: fullStem,
                    activeStem: activeStem,
                    key: key,
                    nextChar: next
                )
            }
        }

        if lowerActive.hasSuffix("ee") && !lowerActive.hasSuffix("eee") {
            let fullStem = String(lowerFull.dropLast(2))
            let activeStem = String(lowerActive.dropLast(2))
            if preserveBypassEEStems.contains(fullStem) || preserveBypassEEStems.contains(activeStem) {
                return false
            }
            if (fullStem.hasSuffix("i") || activeStem.hasSuffix("i")) && !"aeiouy".contains(next) {
                return true // fieeld -> field, vieew -> view, pieece -> piece
            }
            if collapseBypassEEStems.contains(fullStem) || collapseBypassEEStems.contains(activeStem) {
                return true // deleete -> delete, seleect -> select, leveel -> level
            }
        }

        if lowerActive.hasSuffix("oo") && !lowerActive.hasSuffix("ooo") {
            let fullStem = String(lowerFull.dropLast(2))
            let activeStem = String(lowerActive.dropLast(2))
            if (fullStem.hasSuffix("u") || activeStem.hasSuffix("u")) && !"aeiouy".contains(next) {
                return true // quoote -> quote
            }
            if (collapseBypassOOStems.contains(fullStem) || collapseBypassOOStems.contains(activeStem))
                && !"aeiouy".contains(next) {
                return true // roboot -> robot, coloor -> color, controol -> control
            }
        }

        if lowerActive.hasSuffix("aa") && !lowerActive.hasSuffix("aaa") {
            let fullStem = String(lowerFull.dropLast(2))
            let activeStem = String(lowerActive.dropLast(2))
            if (fullStem.hasSuffix("u") || activeStem.hasSuffix("u")) && !"aeiouy".contains(next) {
                return true // duaal -> dual
            }
            if (collapseBypassAAStems.contains(fullStem) || collapseBypassAAStems.contains(activeStem))
                && !"aeiouy".contains(next) {
                return true // caase -> case, baase -> base, saafe -> safe, daata -> data
            }
        }

        return false
    }

    /// Already-bypassed words that end with a single 'a', 'e', 'o', or 'd' where pressing the same key a second time
    /// at the end of the word is a Telex escape habit and should be absorbed immediately.
    private static let delayedBypassAbsorbWords: Set<String> = [
        // -a
        "data", "meta", "beta", "quota", "extra", "ultra", "infra", "contra", "camera", "opera", "agenda", "schema", "formula", "replica", "umbrella", "vanilla", "gorilla", "villa", "sofa", "soda", "cola", "yoga", "visa", "pizza", "plaza", "drama", "comma", "lemma", "gamma", "sigma", "alpha", "delta", "omega", "zebra", "cobra", "chakra", "mantra", "tantra", "aura", "flora", "fauna", "sauna", "trauma", "stigma", "dogma", "enigma", "asthma", "plasma", "cinema", "panama", "canada", "alaska", "florida", "atlanta", "indiana", "montana", "nevada", "oklahoma",
        // -e
        "theme", "gene", "scene", "here", "there", "where", "were", "mere", "these", "those", "whose", "chose", "lose", "close", "pose", "rose", "nose", "dose", "hose", "house", "mouse", "pause", "cause", "course", "source", "force", "horse", "nurse", "parse", "sense", "dense", "tense", "false", "pulse", "verse", "else", "case", "base", "phase", "chase", "use", "safe", "code", "mode", "node", "side", "wide", "ride", "hide", "guide", "slide", "pride", "bride", "stride", "divide", "provide", "decide", "inside", "outside", "beside", "include", "exclude", "conclude", "attitude", "latitude", "longitude", "altitude", "magnitude", "gratitude", "solitude", "multitude", "aptitude", "rade", "fade", "made", "jade", "wade", "shade", "blade", "grade", "trade", "spade", "evade", "invade", "parade", "arcade", "brigade", "cascade", "decade", "upgrade", "downgrade", "complete", "delete", "compete", "concrete", "athlete", "obsolete", "discrete", "secrete", "create", "update", "state", "date", "gate", "late", "rate", "mate", "hate", "fate", "plate", "slate", "skate", "crate", "grate", "pirate", "private", "climate", "estimate", "ultimate", "intimate", "animate", "legitimate", "approximate", "separate", "operate", "generate", "moderate", "federate", "liberate", "tolerate", "accelerate", "celebrate", "decorate", "elaborate", "collaborate", "incorporate", "demonstrate", "illustrate", "frustrate", "concentrate", "penetrate", "arbitrate", "administrate", "magistrate", "candidate", "validate", "consolidate", "accommodate", "intimidate", "liquidate", "mandate", "rotate", "locate", "allocate", "relocate", "advocate", "educate", "indicate", "dedicate", "medicate", "predicate", "syndicate", "communicate", "complicate", "duplicate", "replicate", "implicate", "fabricate", "lubricate", "intricate", "eradicate", "certificate", "authenticate", "sophisticate", "domesticate", "prognosticate", "share", "care", "rare", "spare", "square", "aware", "compare", "prepare", "declare", "ware", "hardware", "software", "firmware", "malware", "middleware", "nightmare", "welfare", "bare", "dare", "fare", "glare", "flare", "stare", "scare", "store", "more", "before", "therefore", "ignore", "restore", "explore", "score", "shore", "chore", "bore", "tore", "wore", "core", "nature", "feature", "future", "picture", "structure", "architecture", "culture", "capture", "gesture", "lecture", "mixture", "moisture", "posture", "texture", "adventure", "creature", "furniture", "literature", "signature", "temperature", "measure", "pleasure", "treasure", "pressure", "exposure", "closure", "leisure", "figure", "configure", "failure", "procedure", "secure", "ensure", "insure", "assure", "fire", "hire", "tire", "wire", "entire", "retire", "require", "inquire", "acquire", "inspire", "expire", "desire", "admire", "empire", "sincere", "sphere", "atmosphere", "interfere", "piece", "niece", "voice", "choice", "notice", "office", "service", "practice", "justice", "device", "advice", "price", "slice", "spice", "twice", "rice", "nice", "mice", "dice", "vice", "ice", "place", "space", "grace", "trace", "face", "pace", "race", "lace", "surface", "replace", "embrace", "palace", "menace", "terrace", "furnace", "necklace", "workplace", "fireplace", "marketplace", "interface", "namespace", "workspace", "whitespace", "backspace", "page", "cage", "rage", "wage", "stage", "image", "damage", "manage", "package", "storage", "usage", "message", "passage", "massage", "village", "cottage", "baggage", "luggage", "postage", "hostage", "shortage", "mortgage", "vintage", "advantage", "percentage", "heritage", "marriage", "carriage", "coverage", "average", "beverage", "leverage", "garbage", "cabbage", "sausage", "language", "voyage", "courage", "encourage", "discourage", "engage", "mortgage",
        // -o
        "mono", "photo", "solo", "logo", "todo", "goto", "auto", "zero", "hero", "demo", "memo", "info", "repo", "video", "audio", "radio", "studio", "ratio", "patio", "portfolio", "scenario", "io", "bio", "trio", "crypto", "micro", "macro", "retro", "metro", "intro", "outro", "astro", "neuro", "thermo", "pseudo", "turbo", "combo", "jumbo", "limbo", "placebo", "gazebo", "torpedo", "tuxedo", "avocado", "tornado", "bravado", "el-nino", "casino", "domino", "albino", "rhino", "piano", "volcano", "soprano", "oregano", "espresso", "lasso", "peso", "torso", "virtuoso", "manifesto", "pesto", "gusto", "motto", "grotto", "lotto", "risotto", "palazzo", "intermezzo", "paparazzo", "echo", "macho", "poncho", "rancho", "gaucho", "psycho", "banjo", "dojo", "mojo", "bistro", "maestro", "allegro", "oprano", "cello", "hello", "halo", "silo", "kilo", "polo", "yolo", "igloo",
        // -d
        "dead", "head", "read", "lead", "bread", "spread", "thread", "tread", "dread", "stead", "instead", "ahead", "overhead", "widespread", "download", "upload", "reload", "payload", "workload", "offload", "overload", "road", "load", "toad", "broad", "abroad", "railroad", "crossroad", "board", "keyboard", "dashboard", "clipboard", "cardboard", "billboard", "motherboard", "skateboard", "snowboard", "surfboard", "whiteboard", "blackboard", "cupboard", "onboard", "hard", "card", "yard", "ward", "guard", "award", "reward", "toward", "forward", "backward", "upward", "downward", "inward", "outward", "awkward", "coward", "wizard", "hazard", "lizard", "blizzard", "standard", "orchard", "mustard", "custard", "bastard", "leopard", "shepherd", "vineyard", "graveyard", "backyard", "courtyard", "shipyard", "junkyard", "word", "lord", "cord", "ford", "sword", "record", "accord", "afford", "discord", "password", "keyword", "crossword", "foreword", "bird", "third", "weird", "good", "wood", "food", "mood", "hood", "blood", "flood", "brood", "stood", "understood", "misunderstood", "childhood", "adulthood", "neighborhood", "brotherhood", "sisterhood", "motherhood", "fatherhood", "likelihood", "livelihood", "falsehood", "knighthood", "priesthood", "manhood", "womanhood", "boyhood", "girlhood", "statehood", "nationhood", "hardwood", "firewood", "plywood", "hollywood", "cloud", "loud", "proud", "aloud", "shroud", "crowd", "fraud", "applaud"
    ]

    /// Evaluates whether pressing `character` (one of `a`, `e`, `o`, `d`) at the end of an already-bypassed word
    /// should be absorbed as a duplicate Telex diacritic escape key.
    public static func shouldAbsorbDelayedBypassDiacritic(
        wordPreedit: String,
        character: Character
    ) -> Bool {
        let lower = tokenAfterLastSeparator(wordPreedit).lowercased()
        let ch = String(character).lowercased()
        guard ["a", "e", "o", "d"].contains(ch), lower.hasSuffix(ch), !lower.hasSuffix(ch + ch) else {
            return false
        }
        return delayedBypassAbsorbWords.contains(lower)
    }

    /// Leading 'd-' prefixes where an initial Telex 'dd-' should collapse to 'd-' when English auto-restore triggers.
    private static let leadingDDCollapsePrefixes: [String] = [
        "defa", "desi", "down", "dele", "deve", "devi", "docu", "disp", "doma", "direct",
        "dete", "depe", "defi", "debu", "depl", "deta", "dyna", "data", "date", "driv", "dock",
        "diff", "digi", "disa", "disc", "dist", "divi", "doub", "draf", "drop", "dura",
        "del", "dev", "deb", "dig", "dou", "dyn", "div", "dr"
    ]

    /// Normalizes a leading 'dd' or 'đ' in an already-bypassed token if it matches an English 'd-' prefix
    /// (e.g. 'ddeffault' -> 'default', 'ddessign' -> 'design', 'ddowwnload' -> 'download').
    public static func normalizeBypassedLeadingDD(_ text: String) -> String {
        if let lastSepIdx = text.lastIndex(where: { isTechnicalSeparator($0) }) {
            let nextIdx = text.index(after: lastSepIdx)
            let prefix = String(text[..<nextIdx])
            let tail = String(text[nextIdx...])
            return prefix + normalizeBypassedLeadingDD(tail)
        }
        let lower = text.lowercased()
        if lower.hasPrefix("dd") && !lower.hasPrefix("ddd") && text.count >= 4 {
            let withoutOneD = String(lower.dropFirst())
            if isEnglishKeyword(withoutOneD) || leadingDDCollapsePrefixes.contains(where: { withoutOneD.hasPrefix($0) }) {
                var chars = Array(text)
                chars.remove(at: 1)
                return String(chars)
            }
        } else if (lower.hasPrefix("đ")) && text.count >= 4 {
            let firstChar = text.first!
            let replacementD: Character = firstChar.isUppercase ? "D" : "d"
            let withoutStroke = String(replacementD) + String(text.dropFirst())
            let lowerWithoutStroke = withoutStroke.lowercased()
            if isEnglishKeyword(lowerWithoutStroke) || leadingDDCollapsePrefixes.contains(where: { lowerWithoutStroke.hasPrefix($0) }) {
                return withoutStroke
            }
        }
        return text
    }

    /// Explicit words where a medial Telex 'aa' escape should collapse to 'a' when English auto-restore triggers in Step 3/5b/8.
    private static let explicitAACollapsePrefixes: [String] = [
        "caase", "baase", "phaase", "chaase", "saafe", "daata",
        "spaace", "plaace", "graace", "traace", "faace", "paace", "raace", "laace",
        "maake", "taake", "baake", "waake", "laake", "shaake", "snaake", "braake", "staake",
        "fraame", "gaame", "naame", "saame", "blaame", "flaame", "shaame",
        "daate", "gaate", "laate", "raate", "staate", "plaate", "maate", "haate", "faate", "creaate", "updaate",
        "scaale", "taale", "saale", "maale", "paale", "whaale",
        "shaare", "caare", "raare", "spaare", "squaare", "waare", "baare", "daare", "faare", "glaare", "flaare", "staare", "scaare",
        "paage", "caage", "raage", "waage", "staage", "imaage", "manaage", "packaage", "storaage", "usaage", "messaage"
    ]

    /// Normalizes a raw keystroke string when English auto-restore triggers in Step 3, 5b, 6, or 8,
    /// collapsing unambiguous Telex double-key escapes (`dd` at word start, medial `ss`/`ff`/`rr`/`xx`/`jj`/`dd`/`ww` after non-Vietnamese codas, `iee`/`uaa`/`uoo` + consonant, `caase`/`baase`/`saafe`).
    public static func collapseEscapedTelexInRestoredEnglish(_ rawWord: String) -> String {
        if let lastSepIdx = rawWord.lastIndex(where: { isTechnicalSeparator($0) }) {
            let nextIdx = rawWord.index(after: lastSepIdx)
            let prefix = String(rawWord[..<nextIdx])
            let tail = String(rawWord[nextIdx...])
            return prefix + collapseEscapedTelexInRestoredEnglish(tail)
        }

        guard rawWord.count >= 3 else { return rawWord }
        var chars = Array(rawWord)
        var lower = rawWord.lowercased()

        // 1. Leading 'dd' on English words (e.g. 'ddefault' -> 'default', 'ddesign' -> 'design', 'ddownload' -> 'download', 'ddelete' -> 'delete', 'ddriver' -> 'driver')
        if lower.hasPrefix("dd") && !lower.hasPrefix("ddd") {
            let withoutOneD = String(lower.dropFirst())
            if isEnglishKeyword(withoutOneD) || leadingDDCollapsePrefixes.contains(where: { withoutOneD.hasPrefix($0) }) {
                chars.remove(at: 1)
                lower = String(chars).lowercased()
            }
        }

        guard chars.count >= 4 else { return String(chars) }

        // 1b. Medial double or triple Telex key ('ss', 'ff', 'rr', 'xx', 'jj', 'dd', 'ww') right before the final character
        // when the preceding syllable had an un-transformed non-Vietnamese coda (e.g. 'objject' -> 'object', 'objjject' -> 'objject',
        // 'elsse' -> 'else', 'falsse' -> 'false', 'pulsse' -> 'pulse', 'alsso' -> 'also', 'abssent' -> 'absent', 'obsserve' -> 'observe',
        // 'subsset' -> 'subset', 'alrready' -> 'already', 'selffish' -> 'selfish', 'welffare' -> 'welfare', 'alwways' -> 'always', 'subwway' -> 'subway').
        let beforeLast = String(lower.dropLast())
        let nextChar = String(lower.last!)
        for key in ["s", "f", "r", "x", "j", "d", "w"] {
            let kk = key + key
            let kkk = kk + key
            if beforeLast.hasSuffix(kkk) && !beforeLast.hasSuffix(kkk + key) {
                let stem = String(beforeLast.dropLast(3))
                if !stem.isEmpty {
                    chars.remove(at: chars.count - 2)
                    return String(chars)
                }
            } else if beforeLast.hasSuffix(kk) && !beforeLast.hasSuffix(kkk) {
                let stem = String(beforeLast.dropLast(2))
                if !stem.isEmpty {
                    if key == "w" {
                        if let lastStem = stem.last, !"aeiouy".contains(lastStem) {
                            chars.remove(at: chars.count - 2)
                            return String(chars)
                        }
                    } else if !shouldKeepDoubleTelexKey(stem: stem, activeStem: stem, key: key, nextChar: nextChar) {
                        chars.remove(at: chars.count - 2)
                        return String(chars)
                    }
                }
            }
        }

        // 2. Diphthong circumflex escape before consonant ('vieew' -> 'view', 'pieece' -> 'piece', 'fieeld' -> 'field', 'duaal' -> 'dual', 'quoote' -> 'quote')
        let explicitDiphthongEscapePrefixes: [String] = [
            "vieew", "pieece", "fieeld", "chieef", "brieef", "grieef", "relieef", "belieef", "thieef", "nieece", "sieege", "shieeld", "yieeld", "wieeld", "fieerce", "pieerce", "frieend", "clieent",
            "duaal", "actuaal", "visuaal", "manuaal", "mutuaal", "annuaal", "casuaal", "rituaal", "virtuaal", "equaal", "usuaal", "graduaal", "guardiaan",
            "quoote", "quoota", "liquoor"
        ]
        if explicitDiphthongEscapePrefixes.contains(where: { lower.hasPrefix($0) }) {
            let lowerChars = chars.map { String($0).lowercased() }
            if lowerChars.count >= 4 {
                for i in 0..<(lowerChars.count - 3) {
                    let c0 = lowerChars[i]
                    let c1 = lowerChars[i + 1]
                    let c2 = lowerChars[i + 2]
                    let c3 = lowerChars[i + 3]
                    let isThreeSame = (i + 3 < lowerChars.count && c1 == c2 && c2 == c3)
                        || (i > 0 && lowerChars[i - 1] == c1 && c1 == c2)
                    if !isThreeSame && !"aeiouy".contains(c3) {
                        if (c0 == "i" && c1 == "e" && c2 == "e")
                            || (c0 == "u" && c1 == "a" && c2 == "a")
                            || (c0 == "u" && c1 == "o" && c2 == "o") {
                            chars.remove(at: i + 2)
                            return String(chars)
                        }
                    }
                }
            }
        }

        // 3. Explicit 'aa' escape words (e.g. 'caase' -> 'case', 'baase' -> 'base', 'saafe' -> 'safe')
        if explicitAACollapsePrefixes.contains(where: { lower.hasPrefix($0) }),
           let range = lower.range(of: "aa"),
           !lower.contains("aaa") {
            let idx = lower.distance(from: lower.startIndex, to: range.lowerBound)
            if idx + 1 < chars.count {
                chars.remove(at: idx + 1)
                return String(chars)
            }
        }

        return String(chars)
    }
}

