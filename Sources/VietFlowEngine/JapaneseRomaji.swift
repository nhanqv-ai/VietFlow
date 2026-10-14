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
        "inoue", "kimura", "hayashi", "shimizu",

        // Honorifics, Keigo, Workplace & Daily JLPT Vocabulary (Cycle 2)
        "sama", "kamisama", "ousama", "himesama", "uchiawase", "kaigishitsu", "uketsuke",
        "jimusho", "buchou", "kachou", "shachou", "tenchou", "sekininsha", "kanrisha",
        "shain", "douryou", "torihikisaki", "kokyaku", "mitsumorisho", "ryoushuusho",
        "keiyakusho", "sekkeisho", "houkokusho", "teiansho", "ringisho", "kessai",
        "natsuin", "meishi", "aisatsu", "keigo", "sonkeigo", "kenjougo", "teineigo",
        "shitsurei", "shitsureishimasu", "otsukaresamadesu", "osewaninarimasu",
        "moushiwakearimasen", "gozaimasen", "shouchishimashita", "ryoukaishimashita",
        "kakuninshimashita", "renrakushimasu", "houkokushimasu", "soudanshimasu",
        "kentoushimasu", "taioushimasu", "shuuseishimasu", "teishutsushimasu",
        "sakuseishimasu", "henshinshimasu", "chikatetsu", "takushii", "kousaten",
        "shingou", "kippu", "nimotsu", "omiyage", "resutoran", "shokudou", "kissaten",
        "depaato", "suupaa", "kusuri", "kangoshi", "yuubinkyoku", "keisatsu",
        "toshokan", "bijutsukan", "eigakan", "doubutsuen", "taishikan", "chuugakkou",
        "shougakkou", "youchien", "kyoushitsu", "shokugyou", "kaishain", "ginkouin",
        "kyoushi", "gakusei", "ryuugakusei", "kenkyuusha", "bengoshi", "keisatsukan",
        "ryourinin", "untenshu", "ochazuke", "oyakodon", "katsudon", "gyuudon",
        "kaisendon", "nikujaga", "shabushabu", "yakiniku", "yakisoba", "yakiudon",
        "monjayaki", "imagawayaki", "daifuku", "warabimochi", "kakigoori", "anmitsu",
        "umeboshi", "furikake", "kamaboko", "chikuwa", "konnyaku", "shiitake",
        "shimeji", "matsutake", "daikon", "kabocha", "kyuuri", "tamanegi", "jagaimo",
        "satsumaimo", "takenoko",

        // Tokyo stations, Japanese regions, geminates & conversational adverbs (Cycle 4)
        "akihabara", "ikebukuro", "roppongi", "harajuku", "ebisu", "meguro", "shinagawa",
        "ueno", "asakusa", "ginza", "odaiba", "kichijoji", "shimokitazawa", "nakameguro",
        "daikanyama", "omotesando", "kabukicho", "marunouchi", "otemachi", "nihonbashi",
        "tsukiji", "toyosu", "haneda", "narita", "kansai", "chubu", "tohoku", "kanto",
        "kyushu", "shikoku", "okinawa", "hakone", "nikko", "kamakura", "kawagoe",
        "karuizawa", "atami", "fujisan", "biwako", "korewa", "sorewa", "arewa",
        "watashiwa", "anatawa", "konbanwa", "mochiron", "tabun", "zenzen", "chanto",
        "itsumo", "tokidoki", "tamani", "suguni", "yukkuri", "hayaku", "issho",
        "isshoni", "isshou", "isshoukenmei", "irasshai", "irasshaimase", "zasshi",
        "ressha", "hassha", "kesshite", "asshuku", "sesshu", "kesshou", "nisshi",
        "busshi", "sasshi", "hitori", "futari", "minna", "zenbu", "hanbun", "sukoshi",
        "takusan", "amari", "totemo", "sugoku", "meccha", "kawaii", "kakkoii",
        "suzushii", "atatakai", "ookii", "chiisai",

        // Dictionary-form Japanese verbs (-ru, -su, -bu, -mu, -tsu) (Cycle 5)
        "uru", "deru", "kesu", "osu", "motsu", "tatsu", "matsu", "katsu", "utsu",
        "sodatsu", "kaesu", "naosu", "nokosu", "okosu", "orosu", "otosu", "watasu",
        "damasu", "kogasu", "nagasu", "hanasu", "sagasu", "hakobu", "erabu",
        "narabu", "manabu", "yobu", "tobu", "korobu", "yorokobu", "asobu", "musubu",
        "susumu", "tsutsumu", "tanomu", "konomu", "umareru", "tsukareru", "wakareru",
        "wasureru", "taoreru", "kakureru", "arawareru", "abiru", "ochiru", "oriru",
        "kariru", "tariru", "ikiru", "shinjiru", "kanjiru", "kinjiru", "tojiru",
        "oujiru", "tsutaeru", "kangaeru", "oshieru", "oboeru", "kotaeru", "ukeru",
        "akeru", "shimeru", "tsukeru", "kakeru", "makeru", "yakeru", "wakeru",
        "sakeru", "todokeru", "tsuzukeru", "mitsukeru", "tasukeru", "azukeru",
        "katazukeru", "hajimeru", "kimeru", "atsumeru", "tomeru", "yameru",
        "homeru", "semeru", "shiraberu", "kuraberu", "naraberu", "noberu", "shaberu",

        // Daily nouns, Katakana loanwords & mimetics/adverbs (Cycle 6)
        "isu", "uso", "hosoi", "hoso", "soto", "moto", "momo",
        "meeru", "beesu", "keesu", "reesu",
        "kesa", "konya", "konban", "maiasa", "maiban", "mainichi", "maishuu", "maitsuki", "maitoshi",
        "sorosoro", "boroboro", "gorogoro", "noronoro", "torotoro", "poroporo", "moromoro", "korokoro",
        "dandan", "zenzen", "sanzan", "tantan", "banban", "ranran", "gangan", "dondon", "ponpon", "konkon", "nonbiri", "runrun",

        // 2-mora verbs & conjugations (Cycle 7)
        "aru", "iru", "eru", "kiru", "niru", "heru", "teru", "keru", "naru", "saru", "nuru", "musu",
        "dete", "deta", "nete", "neta",
        "osoreru", "osorete", "osoreta", "osorenai",
        "dekakeru", "dekakete", "dekaketa", "dekakenai",
        "ireru", "irete", "ireta", "irenai",
        "inoru", "inotte", "inotta", "inoranai",

        // Counters, kinship & workplace terms (Cycle 8)
        "gosai", "kaigishitsu", "uketsuke", "jimusho", "eigyoubu", "kaihatsubu", "kikakubu",
        "torishimariyaku", "kabunushi", "ryoushuusho", "mitsumorisho", "hacchuusho", "nouhinsho",
        "keiyakusho", "houkokusho", "sekkeisho", "teiansho", "kikakusho", "rirekisho",
        "jikoshoukai", "uchiawase", "bounenkai", "shinnenkai", "kangeikai", "soubetsukai",

        // Unambiguous 2-mora nouns, names & verbs (Cycle 9)
        "sora", "nora", "dora", "mura", "nori", "toori", "muri", "pari", "maru", "gero",
        "basu", "gasu", "nasu", "tasu", "dasu",
        "hana", "kana", "nana", "mana", "sana", "kama", "nama", "hama", "kawa", "sawa", "nawa",

        // Katakana long-vowel & IT/lifestyle loanwords (Cycle 10)
        "puran", "buranchi", "haafu", "saafu", "taafu", "naasu", "paasu", "baasu", "daasu",
        "gaaru", "paaru", "seefu", "peesu", "supeesu", "reeru", "beeru", "seeru", "teeru",
        "neeru", "sukeeru",

        // Everyday -au/-aru/-iru/-eru verbs & nouns (Cycle 11)
        "arau", "harau", "sarau", "tarau", "sasaru", "nasaru", "masaru", "tasaru", "hasaru", "asaru",
        "chiru", "biru", "ieru", "mieru", "asa", "masa", "doro", "oto",

        // Ko-so-a-do adnominals, mono, and p-/b-/g-/d- Katakana & mimetic roots (Cycle 12)
        "kono", "sono", "ano", "dono", "mono", "hono",
        "puro", "puraza", "garasu", "gacha", "guree", "guru", "buru", "puru",
        "bara", "bata", "pata", "pasa", "para", "poro", "boro", "basa",
        "gara", "goro", "gasa", "gata", "dara",

        // Unambiguous 2-mora -ru/-ro/-re/-su/-so/-se/-ji/-jo/-wa/-fu & -oi adjectives (Cycle 13 & 14)
        "taru", "baru", "paru", "garu", "daru", "piru", "seru", "meru", "beru", "peru",
        "muru", "duru", "ruru", "huru",
        "nuro", "suro", "muro", "buro", "guro", "duro", "ruro", "uro",
        "pura", "nure", "mure", "bure", "gure", "dure", "rure", "ure", "puri", "pora",
        "pasu", "pisu", "hesu", "sesu", "mesu", "tesu", "besu", "pesu", "gesu", "resu", "esu",
        "nusu", "susu", "busu", "pusu", "gusu", "dusu", "rusu", "usu",
        "nuso", "suso", "muso", "buso", "puso", "guso", "duso", "ruso",
        "nuse", "suse", "buse", "puse", "guse", "duse", "ruse", "posa",
        "paji", "poji", "puji", "giji", "mujo", "sujo", "bujo",
        "nowa", "sowa", "towa", "rowa", "owa",
        "pafu", "kefu", "mefu", "nefu", "hefu", "sefu", "tefu", "defu", "befu", "pefu", "gefu", "refu", "efu",
        "moroi", "noroi", "soroi", "sosori",
        "girai", "horai", "torai", "gisai", "hosai", "sosai", "tosai",
        "girui", "gisui", "urana", "uraya", "urayama", "urayasu", "uragiri", "uragiru", "uraguchi", "uraniwa", "uragawa",
        "kifu", "hifu", "gifu", "rufu", "kufu", "mufu", "nufu", "fufu", "sufu", "yufu", "gufu", "bufu", "dufu", "pufu",
        "kiju", "miju", "niju", "hiju", "biju", "giju", "riju",
        "kuju", "muju", "nuju", "fuju", "suju", "yuju", "guju", "buju", "puju", "duju", "ruju",
        "mise", "nise", "kise", "hise", "bise", "gise", "tise", "dise", "sise", "rire",
        "kiseru", "hiseru", "niseru", "saseru", "kaseru", "maseru", "naseru", "haseru",
        "taseru", "daseru", "yaseru", "noseru", "koseru", "moseru", "yoseru", "rareru",
        "reru", "rero", "rere", "rora", "rori", "roro", "rore",
        "rara", "rari", "raru", "rira", "riru", "rura", "ruri",
        "kisa", "misa", "hisa", "chisa", "kisu", "misu", "nisu", "hisu", "risu", "aisu", "naisu",
        "husu", "tusu", "kusu", "yusu", "huse", "tuse", "yuse", "huso", "tuso", "kuso", "yuso",
        "keso", "meso", "neso", "heso", "teso", "deso", "beso", "geso",
        "yasa", "yase", "yoso", "yose", "kase", "kaso", "mase", "maso", "nase", "hase",
        "sase", "saso", "sasu", "tase", "dase", "gase", "kosa", "kose", "gosa", "dosa",
        "sosa", "soso", "tosa", "hura", "hure", "huri", "huro",
        "sura", "suri", "turo", "tura", "ture", "turi", "nura", "nuri", "bura", "buri", "gura", "guri",
        "kire", "nire", "bire", "gire", "giro", "hore",
        "mara", "hara", "sara", "tara",
        "kieru", "kiete", "miete", "uete", "suete",
        "horo", "moro", "moso", "toro", "toso", "soro", "noro", "noso",
        "tere", "kere", "nere", "bere", "dere",
        "tese", "kese", "mese", "nese", "hese", "sese", "bese", "dese", "nesu",
        "suwa", "guwa", "buwa"
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
        "sha", "shi", "sho", "shu", "tsu"
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
    /// 4. Japanese long-vowel '-urou', '-usou', '-ujou' endings (e.g. musou, busou, mujou, kurou, furou, rurou)
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

        // Rule 4: Japanese -urou / -usou / -ujou long-vowel endings
        if lower.hasSuffix("urou") || lower.hasSuffix("usou") || lower.hasSuffix("ujou") {
            return true
        }

        return false
    }

    /// Determines whether composition should break and restore to raw Romaji.
    public static func shouldRestoreRomaji(candidateWord: String) -> Bool {
        return isRomajiWord(candidateWord) || hasRomajiStructuralPattern(candidateWord)
    }
}
