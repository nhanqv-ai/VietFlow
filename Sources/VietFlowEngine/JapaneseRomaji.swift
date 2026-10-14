//
//  JapaneseRomaji.swift
//  VietFlowEngine
//
//  Japanese Romaji Lexicon, Phonotactics and Syllable Chaining Validator for Vietnamese Mode.
//

import Foundation

public enum JapaneseRomajiLexicon {
    /// Curated lexicon of unambiguous Japanese Romaji vocabulary,
    /// proper nouns, culinary terms, expressions, and cultural words (Requirement R2).
    public static let words: Set<String> = [
        // Proper Nouns and Places
        "osaka", "tokyo", "kyoto", "shinjuku", "shibuya", "harajuku", "akihabara",
        "asakusa", "okinawa", "hiroshima", "yokohama", "fukuoka", "sapporo", "sendai",
        "nagoya", "narita", "haneda", "kamakura", "hakone", "fuji", "nara", "kobe",
        "chiba", "saitama", "hokkaido", "ginza", "roppongi", "ueno", "ikebukuro",
        "tsukiji", "odaiba", "nikko",

        // Culinary Terms
        "sushi", "sashimi", "wasabi", "tempura", "takoyaki", "okonomiyaki", "yakitori",
        "ramen", "udon", "soba", "matcha", "wagyu", "gyoza", "tonkatsu", "karaage",
        "teriyaki", "sukiyaki", "izakaya", "konbini", "bento", "onigiri", "miso",
        "dashi", "mirin", "edamame", "tamagoyaki", "unagi", "mochi", "taiyaki",
        "natto", "senbei", "dorayaki", "kombu", "shoyu", "tsukemono",

        // Expressions and Greetings
        "arigatou", "konnichiwa", "konbanwa", "ohayou", "oyasumi", "sumimasen",
        "gomennasai", "itadakimasu", "gochisousama", "otsukaresama", "yoroshiku",
        "onegaishimasu", "daijoubu", "ganbatte", "douzo", "tadaima", "okaeri",
        "ittekimasu", "itterasshai", "kanpai",

        // Adjectives and Expressions
        "kawaii", "sugoi", "yabai", "urusai", "mendokusai", "natsukashii", "oishii",
        "tanoshii", "ureshii", "kanashii", "muzukashii", "yasashii", "atarashii",
        "isogashii", "subarashii", "ayashii", "sabishii", "kakkoii", "omoshiroi",
        "tsuyoi", "yowai", "hayai", "osoi", "takai", "yasui", "chiisai", "ookii",

        // Cultural, General and Everyday Terms
        "shinkansen", "sensei", "senpai", "kouhai", "nihon", "nihongo", "kanji",
        "hiragana", "katakana", "romaji", "furigana", "anime", "manga", "otaku",
        "cosplay", "karaoke", "emoji", "tsunami", "origami", "ikigai", "kaizen",
        "kanban", "bushido", "samurai", "ninja", "shogun", "geisha", "kimono",
        "yukata", "tatami", "futon", "onsen", "ryokan", "torii", "jinja", "matsuri",
        "sakura", "momiji", "hikari", "kokoro", "mirai", "hoshi", "tsuki",
        "chibi", "waifu", "shoujo", "shounen", "seinen", "doujinshi", "isekai",
        "ippon", "shashin",

        // Workplace, BrSE & Business Terms
        "hourensou", "houkoku", "renraku", "soudan", "kaigi", "shiryou", "kakunin",
        "shounin", "mitsumori", "nouki", "shimekiri", "tantousha", "okyakusama",
        "keiyaku", "seikyuusho", "shiyousho", "sekkei", "kaihatsu", "kenshuu",
        "shucchou", "zangyou", "yuukyuu", "teishutsu", "shuusei", "shinchoku",
        "kadai", "mondai", "taisaku", "genba", "genbutsu", "genjitsu", "hansei",
        "chousa", "kentou", "renkei", "kyouryoku", "shitsumon", "kaitou", "iraisho",
        "anken", "koumoku", "gamen", "shori", "dousa",

        // Conversational, Pronouns, Time, Verbs & Common Names
        "desu", "deshita", "mashita", "masen", "gozaimasu", "arigatougozaimasu",
        "ohayougozaimasu", "otsukaresamadeshita", "yoroshikuonegaishimasu",
        "wakarimashita", "kashikomarimashita", "sumimasendeshita", "naruhodo",
        "yappari", "kekkou", "zettai", "ippai", "chotto", "matte", "kudasai",
        "onegai", "kore", "sore", "dore", "koko", "soko", "asoko", "doko",
        "watashi", "anata", "kanojo", "kare", "minasan", "tomodachi", "kazoku",
        "haru", "natsu", "fuyu", "hiru", "yoru", "ashita", "kinou", "kyou",
        "raishuu", "konshuu", "senshuu", "raigetsu", "kongetsu", "sengetsu",
        "kuro", "kuroi", "shiro", "shiroi", "akai", "kiiroi", "midori",
        "suru", "kuru", "miru", "neru", "taberu", "nomu", "kaeru", "wakaru",
        "dekiru", "owaru", "hajimaru", "kawaru", "tomaru", "kimaru",
        "kuruma", "densha", "hikouki", "jitensha", "kuukou", "byouin", "ginkou",
        "daigaku", "gakkou", "kaisha", "shigoto", "benkyou", "ryokou", "ryugaku",
        "seikatsu", "naruto", "sasuke", "kakashi", "itachi", "hinata", "jiraiya",
        "tsunade", "haruka", "misaki", "chisato", "hisashi", "musashi", "suzuki",
        "tanaka", "yamamoto", "watanabe", "takahashi", "itou", "satou", "kobayashi",
        "nakamura", "katou", "yoshida", "yamada", "sasaki", "yamaguchi", "matsumoto",
        "inoue", "kimura", "hayashi", "shimizu"
    ]
}

public enum JapaneseRomajiDetector {
    /// Japanese medial double consonants and affricates that never occur in native Vietnamese words.
    public static let invalidMedialClusters: [String] = [
        "kka", "kke", "kki", "kko", "kku",
        "ppa", "ppe", "ppi", "ppo", "ppu",
        "tcha", "tche", "tchi", "tcho", "tchu",
        "ccha", "cche", "cchi", "ccho", "cchu",
        "ssha", "sshe", "sshi", "ssho", "sshu",
        "shi", "shu", "tsu"
    ]

    /// Unambiguous Japanese-only onset prefixes (zero collision with Vietnamese phonotactics).
    public static let unambiguousOnsets: [String] = ["sh", "ts"]

    /// Checks if a word is a known Japanese Romaji keyword.
    public static func isRomajiWord(_ word: String) -> Bool {
        JapaneseRomajiLexicon.words.contains(word.lowercased())
    }

    /// Checks if a word matches unambiguous Japanese structural patterns:
    /// 1. Adjective suffix '-shii' (minimum length 5: e.g. oishii, tanoshii, subarashii)
    /// 2. Polite verb/copula suffixes ('-masu', '-mashita', '-masen', '-deshita', '-gozaimasu')
    /// 3. Japanese medial geminates and sibilant/affricate clusters ('kka', 'ppa', 'tcha', 'sha', 'shi', 'shu', 'tsu')
    public static func hasRomajiStructuralPattern(_ word: String) -> Bool {
        let lower = word.lowercased()
        guard lower.count >= 4 else { return false }

        // Rule 1: -shii adjectives (min length 5)
        if lower.count >= 5 && lower.hasSuffix("shii") {
            return true
        }

        // Rule 2: Polite verb/copula inflections (min length 6)
        if lower.count >= 6 && (
            lower.hasSuffix("masu")
            || lower.hasSuffix("mashita")
            || lower.hasSuffix("masen")
            || lower.hasSuffix("deshita")
            || lower.hasSuffix("gozaimasu")
        ) {
            return true
        }

        // Rule 3: Japanese medial geminates & unambiguous Hepburn clusters
        for pattern in invalidMedialClusters {
            if lower.contains(pattern) {
                return true
            }
        }

        return false
    }

    /// Determines whether composition should break and restore to raw Romaji.
    public static func shouldRestoreRomaji(candidateWord: String) -> Bool {
        return isRomajiWord(candidateWord) || hasRomajiStructuralPattern(candidateWord)
    }
}
