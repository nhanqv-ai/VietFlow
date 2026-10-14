//
//  TrilingualUserExperienceTests.swift
//  VietFlowEngineTests
//
//  Milestone M-E2E / Requirement R4: Trilingual User Experience Automated Verification Suite.
//  Comprehensive 4-tier simulation of real-world Vietnamese, English, and Japanese typing workflows.
//  Evaluates:
//  - Tier 1: Feature Coverage (CamelCase, URLs, English keywords, Vietnamese single-syllable preservation, Romaji lexicon, Romaji phonotactics, Status Bar feedback, Kotoeri sync)
//  - Tier 2: Boundary & Corner Cases (Punctuation, bursts, extreme lengths, symbols, single vs double escapes)
//  - Tier 3: Cross-Feature Interactions (Code tokens in Vietnamese, English after Romaji, CamelCase in URLs)
//  - Tier 4: Real-World Multilingual Application Scenarios (Developer chat, PR review, culinary diary, mid-word/cross-word backspace)
//  - Enforces strict Unicode NFC normalization and throughput benchmarks.
//

import AppKit
import Combine
import Foundation
import VietFlowApp
import VietFlowEngine
import VietFlowState

public final class TrilingualUserExperienceTests: VietFlowTestCase {
    private var cancellables = Set<AnyCancellable>()

    public override func setUp() {
        super.setUp()
        cancellables.removeAll()
    }

    public override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - Simulation Helpers

    @discardableResult
    private func apply(
        _ input: String,
        inputMethod: InputMethod = .telex,
        file: StaticString = #file,
        line: UInt = #line
    ) -> String {
        let engine = makeEngine(inputMethod: inputMethod, tonePlacement: .modern)
        return applyKeystrokesAndBackspacesToScreenBuffer(input, engine: engine, file: file, line: line)
    }

    private func assertBuffer(
        _ input: String,
        equals expected: String,
        inputMethod: InputMethod = .telex,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let result = apply(input, inputMethod: inputMethod, file: file, line: line)
        XCTAssertEqual(
            result,
            expected,
            "Trilingual typing mismatch. Input: '\(input)', Expected: '\(expected)', Got: '\(result)'",
            file: file,
            line: line
        )
    }

    // =========================================================================
    // MARK: - Tier 1: Feature Coverage (48 tests)
    // =========================================================================

    // --- Feature 1: CamelCase / PascalCase Identifiers (Tests 1-6) ---

    func test_tier1_01_camelcase_apple_platforms_macos_ios_watchos() {
        assertBuffer("macOS iOS iPadOS watchOS tvOS", equals: "macOS iOS iPadOS watchOS tvOS")
    }

    func test_tier1_02_camelcase_react_hooks_usestate_useeffect() {
        assertBuffer("useState useEffect useCallback useRef useMemo", equals: "useState useEffect useCallback useRef useMemo")
    }

    func test_tier1_03_camelcase_ui_event_handlers_onclick_viewmodel() {
        assertBuffer("onClick onSubmit onHover viewModel nextProps", equals: "onClick onSubmit onHover viewModel nextProps")
    }

    func test_tier1_04_pascalcase_brand_and_frameworks_vietflow_swiftui_superclip() {
        assertBuffer("VietFlow SuperClip SwiftUI AppKit CoreGraphics", equals: "VietFlow SuperClip SwiftUI AppKit CoreGraphics")
    }

    func test_tier1_05_pascalcase_services_github_gitlab_youtube_chatgpt() {
        assertBuffer("GitHub GitLab YouTube ChatGPT OpenAI", equals: "GitHub GitLab YouTube ChatGPT OpenAI")
    }

    func test_tier1_06_camelcase_languages_typescript_javascript_graphql_postgresql() {
        assertBuffer("TypeScript JavaScript PostgreSQL GraphQL", equals: "TypeScript JavaScript PostgreSQL GraphQL")
    }

    // --- Feature 2: Technical Domains, URLs & Extensions (Tests 7-12) ---

    func test_tier1_07_dotted_domains_japanese_nhk_yahoo_amazon_co_jp() {
        assertBuffer("nhk.or.jp yahoo.co.jp amazon.co.jp", equals: "nhk.or.jp yahoo.co.jp amazon.co.jp")
    }

    func test_tier1_08_dotted_domains_country_tlds_us_es_tw_vn() {
        assertBuffer("example.us amazon.es shopee.tw google.com.vn", equals: "example.us amazon.es shopee.tw google.com.vn")
    }

    func test_tier1_09_code_file_extensions_readme_md_index_ts_app_rs() {
        assertBuffer("readme.md index.ts app.rs", equals: "readme.md index.ts app.rs")
    }

    func test_tier1_10_web_extensions_style_css_file_sh_config_aw_main_swift() {
        assertBuffer("style.css file.sh config.aw main.swift package.json v1.0.0", equals: "style.css file.sh config.aw main.swift package.json v1.0.0")
    }

    func test_tier1_11_technical_separators_slash_at_hyphen_underscore() {
        assertBuffer("user@example.us api/v1/auth auth-service header_icon.png", equals: "user@example.us api/v1/auth auth-service header_icon.png")
    }

    func test_tier1_12_full_url_protocols_https_git_ssh() {
        assertBuffer("https://nhk.or.jp/news git@github.com:vietflow/core.git", equals: "https://nhk.or.jp/news git@github.com:vietflow/core.git")
    }

    // --- Feature 3: Expanded English Keywords (Tests 13-18) ---

    func test_tier1_13_english_keywords_batch1_yes_use_user_case_base() {
        assertBuffer("yes use user users used case base phase chase", equals: "yes use user users used case base phase chase")
    }

    func test_tier1_14_english_keywords_batch2_rose_pose_house_mouse_course() {
        assertBuffer("rose pose nose lose dose hose house mouse pause cause course source force horse nurse parse", equals: "rose pose nose lose dose hose house mouse pause cause course source force horse nurse parse")
    }

    func test_tier1_15_english_keywords_batch3_sense_dense_false_focus_status_virus() {
        assertBuffer("else sense dense tense false pulse verse focus status virus bonus minus campus lotus nexus", equals: "else sense dense tense false pulse verse focus status virus bonus minus campus lotus nexus")
    }

    func test_tier1_16_english_keywords_batch4_next_text_context_index_syntax_linux() {
        assertBuffer("next text context index prefix suffix matrix syntax regex complex relax linux unix nginx tmux redux pixel proxy axios", equals: "next text context index prefix suffix matrix syntax regex complex relax linux unix nginx tmux redux pixel proxy axios")
    }

    func test_tier1_17_english_keywords_batch5_year_hear_appear_engineer_poor_door() {
        assertBuffer("year hear near dear bear pear gear wear tear fear appear career engineer our hour four pour sour tour your door floor poor beer deer peer", equals: "year hear near dear bear pear gear wear tear fear appear career engineer our hour four pour sour tour your door floor poor beer deer peer")
    }

    func test_tier1_18_english_keywords_batch6_news_review_down_town_own_dawn() {
        assertBuffer("new news view views review preview interview down town brown crown own shown known grown dawn lawn pawn", equals: "new news view views review preview interview down town brown crown own shown known grown dawn lawn pawn")
    }

    // --- Feature 4: Strict Vietnamese Single-Syllable Preservation & Double-Key Escape (Tests 19-24) ---

    func test_tier1_19_vietnamese_preservation_car_bar_tar_her_sir() {
        assertBuffer("car bar tar her sir", equals: "c\u{1EA3} b\u{1EA3} t\u{1EA3} h\u{1EBB} s\u{1EC9}")
    }

    func test_tier1_20_vietnamese_preservation_bus_gas_box_tax_max() {
        assertBuffer("bus gas box tax max", equals: "b\u{00FA} g\u{00E1} b\u{00F5} t\u{00E3} m\u{00E3}")
    }

    func test_tier1_21_vietnamese_preservation_mix_six_sex_now_how() {
        assertBuffer("mix six sex now how", equals: "m\u{0129} s\u{0129} s\u{1EBD} n\u{01A1} h\u{01A1}")
    }

    func test_tier1_22_vietnamese_preservation_low_row_cow_raw_law_saw_hair() {
        assertBuffer("low row cow raw law saw hair", equals: "l\u{01A1} r\u{01A1} c\u{01A1} r\u{0103} l\u{0103} s\u{0103} h\u{1EA3}i")
    }

    func test_tier1_23_double_key_escape_restores_english_carr_barr_tarr_herr() {
        assertBuffer("carr barr tarr herr sirr buss gass", equals: "car bar tar her sir bus gas")
    }

    func test_tier1_24_double_key_escape_restores_english_sexx_noww_howw_boxx() {
        assertBuffer("boxx taxx maxx mixx sixx sexx noww howw loww roww coww raww laww saww hairr", equals: "box tax max mix six sex now how low row cow raw law saw hair")
    }

    // --- Feature 5: Japanese Romaji Curated Lexicon (Tests 25-30) ---

    func test_tier1_25_japanese_places_tokyo_osaka_kyoto_shinjuku_shibuya() {
        assertBuffer("osaka tokyo kyoto shinjuku shibuya harajuku akihabara asakusa okinawa", equals: "osaka tokyo kyoto shinjuku shibuya harajuku akihabara asakusa okinawa")
    }

    func test_tier1_26_japanese_places_hiroshima_yokohama_fukuoka_sapporo_fuji() {
        assertBuffer("hiroshima yokohama fukuoka sapporo sendai nagoya narita haneda kamakura hakone fuji", equals: "hiroshima yokohama fukuoka sapporo sendai nagoya narita haneda kamakura hakone fuji")
    }

    func test_tier1_27_japanese_culinary_sushi_sashimi_wasabi_tempura_ramen() {
        assertBuffer("sushi sashimi wasabi tempura takoyaki okonomiyaki yakitori ramen udon soba", equals: "sushi sashimi wasabi tempura takoyaki okonomiyaki yakitori ramen udon soba")
    }

    func test_tier1_28_japanese_culinary_matcha_wagyu_gyoza_tonkatsu_teriyaki() {
        assertBuffer("matcha wagyu gyoza tonkatsu karaage teriyaki sukiyaki izakaya konbini", equals: "matcha wagyu gyoza tonkatsu karaage teriyaki sukiyaki izakaya konbini")
    }

    func test_tier1_29_japanese_social_arigatou_konnichiwa_sumimasen_daijoubu() {
        assertBuffer("shinkansen sensei senpai kouhai arigatou konnichiwa konbanwa ohayou oyasumi sumimasen gomennasai itadakimasu gochisousama otsukaresama yoroshiku onegaishimasu daijoubu", equals: "shinkansen sensei senpai kouhai arigatou konnichiwa konbanwa ohayou oyasumi sumimasen gomennasai itadakimasu gochisousama otsukaresama yoroshiku onegaishimasu daijoubu")
    }

    func test_tier1_30_japanese_cultural_anime_manga_origami_samurai_sakura_tsunami() {
        assertBuffer("nihon nihongo kanji hiragana katakana romaji furigana anime manga otaku cosplay karaoke emoji tsunami origami ikigai kaizen kanban bushido samurai ninja shogun geisha kimono yukata tatami futon onsen ryokan torii jinja matsuri sakura momiji hikari kokoro mirai hoshi tsuki", equals: "nihon nihongo kanji hiragana katakana romaji furigana anime manga otaku cosplay karaoke emoji tsunami origami ikigai kaizen kanban bushido samurai ninja shogun geisha kimono yukata tatami futon onsen ryokan torii jinja matsuri sakura momiji hikari kokoro mirai hoshi tsuki")
    }

    // --- Feature 6: Japanese Romaji Phonotactics & Adjectives (Tests 31-36) ---

    func test_tier1_31_romaji_adjectives_shii_ending_oishii_tanoshii_ureshii() {
        assertBuffer("kawaii sugoi yabai urusai oishii tanoshii ureshii", equals: "kawaii sugoi yabai urusai oishii tanoshii ureshii")
    }

    func test_tier1_32_romaji_adjectives_shii_ending_kanashii_muzukashii_yasashii() {
        assertBuffer("kanashii muzukashii yasashii atarashii", equals: "kanashii muzukashii yasashii atarashii")
    }

    func test_tier1_33_romaji_adjectives_shii_ending_atarashii_isogashii_subarashii() {
        assertBuffer("isogashii subarashii natsukashii", equals: "isogashii subarashii natsukashii")
    }

    func test_tier1_34_romaji_adjectives_shii_ending_natsukashii_mendokusai() {
        assertBuffer("mendokusai sabishii ayashii", equals: "mendokusai sabishii ayashii")
    }

    func test_tier1_35_romaji_phonotactic_sh_ts_clusters_shinkansen_tsunami_tsuki() {
        assertBuffer("shinjuku tsunami shinkansen tsuki shashin tsukiji", equals: "shinjuku tsunami shinkansen tsuki shashin tsukiji")
    }

    func test_tier1_36_romaji_geminates_and_clusters_matcha_matsuri_tatami() {
        assertBuffer("matcha matsuri tatami hokkaido ippon", equals: "matcha matsuri tatami hokkaido ippon")
    }

    // --- Feature 7: Status Bar Foreign IME Auto-Suspension Feedback (Tests 37-42) ---

    func test_tier1_37_status_bar_suspended_tooltip_contains_exact_string() {
        let mockManager = MockInputSourceManager(initialSourceID: "com.apple.keylayout.ABC", isForeign: false)
        let state = AppStateManager(inputSourceManager: mockManager)
        let controller = StatusBarController(stateManager: state)

        state.handleInputSourceChanged(newSourceID: "com.apple.inputmethod.Kotoeri.Japanese", isForeign: true)
        controller.updateIcon()

        let expectedTooltip = "VietFlow \u{2014} Ch\u{1EBF} \u{0111}\u{1ED9}: T\u{1EA1}m ng\u{01B0}ng \u{2014} \u{0110}ang nh\u{01B0}\u{1EDD}ng b\u{1ED9} g\u{00F5} Ngo\u{1EA1}i ng\u{1EEF} [E] (Click \u{0111}\u{1EC3} k\u{00ED}ch ho\u{1EA1}t Ti\u{1EBF}ng Vi\u{1EC7}t)"
        XCTAssertEqual(controller.statusItem.button?.toolTip, expectedTooltip)
    }

    func test_tier1_38_status_bar_suspended_context_menu_header_exact_string() {
        let mockManager = MockInputSourceManager(initialSourceID: "com.apple.keylayout.ABC", isForeign: false)
        let state = AppStateManager(inputSourceManager: mockManager)
        let controller = StatusBarController(stateManager: state)

        state.handleInputSourceChanged(newSourceID: "com.apple.inputmethod.Kotoeri.Japanese", isForeign: true)
        let menu = controller.buildContextMenu()
        let modeItem = menu.items.first(where: { $0.title.hasPrefix("Ch\u{1EBF} \u{0111}\u{1ED9}:") })

        let expectedHeader = "Ch\u{1EBF} \u{0111}\u{1ED9}: T\u{1EA1}m ng\u{01B0}ng \u{2014} \u{0110}ang nh\u{01B0}\u{1EDD}ng b\u{1ED9} g\u{00F5} Ngo\u{1EA1}i ng\u{1EEF} [E]"
        XCTAssertEqual(modeItem?.title, expectedHeader)
    }

    func test_tier1_39_status_bar_active_vietnamese_tooltip_and_context_menu() {
        let mockManager = MockInputSourceManager(initialSourceID: "com.apple.keylayout.ABC", isForeign: false)
        let state = AppStateManager(inputSourceManager: mockManager)
        state.currentInputMode = .vietnamese
        let controller = StatusBarController(stateManager: state)
        controller.updateIcon()

        let tooltip = controller.statusItem.button?.toolTip ?? ""
        XCTAssertTrue(tooltip.contains("Ti\u{1EBF}ng Vi\u{1EC7}t"), "Active tooltip must mention Tieng Viet")
        XCTAssertFalse(tooltip.contains("T\u{1EA1}m ng\u{01B0}ng"), "Active tooltip must not indicate suspended")

        let menu = controller.buildContextMenu()
        let modeItem = menu.items.first(where: { $0.title.hasPrefix("Ch\u{1EBF} \u{0111}\u{1ED9}:") })
        XCTAssertTrue(modeItem?.title.contains("[V]") == true, "Active menu header must contain [V]")
    }

    func test_tier1_40_status_bar_vector_icon_mode_e_when_suspended() {
        let mockManager = MockInputSourceManager(initialSourceID: "com.apple.keylayout.ABC", isForeign: false)
        let state = AppStateManager(inputSourceManager: mockManager)
        let controller = StatusBarController(stateManager: state)

        state.handleInputSourceChanged(newSourceID: "com.apple.inputmethod.Kotoeri.Japanese", isForeign: true)
        controller.updateIcon()

        XCTAssertEqual(state.currentInputMode, .english)
        let icon = controller.statusItem.button?.image
        XCTAssertNotNil(icon)
        XCTAssertEqual(icon?.size.width, 22.0)
        XCTAssertEqual(icon?.size.height, 22.0)
    }

    func test_tier1_41_status_bar_vector_icon_mode_v_when_active() {
        let mockManager = MockInputSourceManager(initialSourceID: "com.apple.keylayout.ABC", isForeign: false)
        let state = AppStateManager(inputSourceManager: mockManager)
        state.currentInputMode = .vietnamese
        let controller = StatusBarController(stateManager: state)
        controller.updateIcon()

        let icon = controller.statusItem.button?.image
        XCTAssertNotNil(icon)
        XCTAssertEqual(icon?.size.width, 22.0)
        XCTAssertEqual(icon?.size.height, 22.0)
    }

    func test_tier1_42_status_bar_zero_emojis_audit_across_all_labels() {
        let mockManager = MockInputSourceManager(initialSourceID: "com.apple.keylayout.ABC", isForeign: false)
        let state = AppStateManager(inputSourceManager: mockManager)
        let controller = StatusBarController(stateManager: state)

        for mode in [InputMode.vietnamese, InputMode.english] {
            state.currentInputMode = mode
            controller.updateIcon()
            let tip = controller.statusItem.button?.toolTip ?? ""
            for ch in tip {
                let cp = ch.unicodeScalars.first?.value ?? 0
                XCTAssertFalse((0x1F300...0x1FAFF).contains(cp) || (0x2600...0x27BF).contains(cp), "Found emoji in tooltip: \(ch)")
            }

            let menu = controller.buildContextMenu()
            for item in menu.items {
                for ch in item.title {
                    let cp = ch.unicodeScalars.first?.value ?? 0
                    XCTAssertFalse((0x1F300...0x1FAFF).contains(cp) || (0x2600...0x27BF).contains(cp), "Found emoji in menu item: \(ch)")
                }
            }
        }
    }

    // --- Feature 8: Japanese IME Kotoeri Modes Synchronization (Tests 43-48) ---

    func test_tier1_43_classifier_identifies_kotoeri_japanese_hiragana() {
        XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: "com.apple.inputmethod.Kotoeri.Japanese"))
        XCTAssertFalse(InputSourceClassifier.isLatinKeyboardLayout(sourceID: "com.apple.inputmethod.Kotoeri.Japanese"))
    }

    func test_tier1_44_classifier_identifies_kotoeri_katakana_and_halfwidth() {
        XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: "com.apple.inputmethod.Kotoeri.Japanese.Katakana"))
        XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: "com.apple.inputmethod.Kotoeri.Japanese.HalfWidthKana"))
        XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: "com.apple.inputmethod.Kotoeri.Japanese.FullWidthRoman"))
    }

    func test_tier1_45_classifier_identifies_kotoeri_romaji_typing_roman() {
        XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: "com.apple.inputmethod.Kotoeri.RomajiTyping.Roman"))
        XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: "com.apple.inputmethod.Japanese.Alphanumeric"))
    }

    func test_tier1_46_classifier_identifies_third_party_japanese_imes() {
        XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: "com.google.inputmethod.Japanese.Roman"))
        XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: "com.justsystems.inputmethod.atok2023"))
        XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: "org.mozc.inputmethod.Japanese"))
    }

    func test_tier1_47_state_manager_auto_suspends_and_saves_pre_foreign_mode() {
        let mockManager = MockInputSourceManager(initialSourceID: "com.apple.keylayout.ABC", isForeign: false)
        let state = AppStateManager(inputSourceManager: mockManager)
        state.currentInputMode = .vietnamese
        XCTAssertFalse(state.isSuspendedByForeignIME)

        state.handleInputSourceChanged(newSourceID: "com.apple.inputmethod.Kotoeri.Japanese", isForeign: true)
        XCTAssertTrue(state.isSuspendedByForeignIME)
        XCTAssertEqual(state.currentInputMode, .english)
        XCTAssertEqual(state.savedPreForeignMode, .vietnamese)
    }

    func test_tier1_48_state_manager_auto_restores_pre_foreign_mode_on_latin_return() {
        let mockManager = MockInputSourceManager(initialSourceID: "com.apple.keylayout.ABC", isForeign: false)
        let state = AppStateManager(inputSourceManager: mockManager)
        state.currentInputMode = .vietnamese

        state.handleInputSourceChanged(newSourceID: "com.apple.inputmethod.Kotoeri.Japanese", isForeign: true)
        XCTAssertTrue(state.isSuspendedByForeignIME)

        state.handleInputSourceChanged(newSourceID: "com.apple.keylayout.ABC", isForeign: false)
        XCTAssertFalse(state.isSuspendedByForeignIME)
        XCTAssertEqual(state.currentInputMode, .vietnamese)
    }

    // =========================================================================
    // MARK: - Tier 2: Boundary & Corner Cases (42 tests)
    // =========================================================================

    func test_tier2_49_empty_input_produces_empty_screen() {
        assertBuffer("", equals: "")
    }

    func test_tier2_50_single_space_and_whitespace_boundaries() {
        assertBuffer(" ", equals: " ")
        assertBuffer("  \t  \n ", equals: "  \t  \n ")
    }

    func test_tier2_51_single_character_isolated_keystrokes() {
        assertBuffer("a", equals: "a")
        assertBuffer("e", equals: "e")
        assertBuffer("w", equals: "\u{01B0}")
        assertBuffer("ww", equals: "w")
        assertBuffer("s", equals: "s")
        assertBuffer("r", equals: "r")
    }

    func test_tier2_52_consecutive_dots_and_ellipses() {
        assertBuffer("...", equals: "...")
        assertBuffer("nhk..or...jp", equals: "nhk..or...jp")
    }

    func test_tier2_53_consecutive_slashes_and_paths() {
        assertBuffer("https://///nhk.or.jp///news", equals: "https://///nhk.or.jp///news")
    }

    func test_tier2_54_consecutive_hyphens_and_dashes() {
        assertBuffer("--user--defined--style--", equals: "--user--defined--style--")
    }

    func test_tier2_55_consecutive_underscores() {
        assertBuffer("__init____main____name__", equals: "__init____main____name__")
    }

    func test_tier2_56_enclosing_parentheses_around_urls() {
        assertBuffer("(https://nhk.or.jp)", equals: "(https://nhk.or.jp)")
    }

    func test_tier2_57_enclosing_brackets_around_identifiers() {
        assertBuffer("[useState, useEffect]", equals: "[useState, useEffect]")
    }

    func test_tier2_58_enclosing_curly_braces_around_tokens() {
        assertBuffer("{status: true, code: 200}", equals: "{status: true, code: 200}")
    }

    func test_tier2_59_enclosing_angle_brackets_generics() {
        assertBuffer("Map<TypeScript, JavaScript>", equals: "Map<TypeScript, JavaScript>")
    }

    func test_tier2_60_single_quotes_around_romaji() {
        assertBuffer("'tokyo' 'osaka' 'kyoto'", equals: "'tokyo' 'osaka' 'kyoto'")
    }

    func test_tier2_61_double_quotes_around_camelcase() {
        assertBuffer("\"useState\" \"watchOS\" \"GitHub\"", equals: "\"useState\" \"watchOS\" \"GitHub\"")
    }

    func test_tier2_62_backticks_around_code_identifiers() {
        assertBuffer("`index.ts` `style.css` `readme.md`", equals: "`index.ts` `style.css` `readme.md`")
    }

    func test_tier2_63_mixed_enclosing_punctuation_and_symbols() {
        assertBuffer("([{'nhk.or.jp'}])", equals: "([{'nhk.or.jp'}])")
    }

    func test_tier2_64_single_c_vs_car_vs_carr() {
        assertBuffer("c", equals: "c")
        assertBuffer("car", equals: "c\u{1EA3}")
        assertBuffer("carr", equals: "car")
    }

    func test_tier2_65_single_s_vs_sex_vs_sexx() {
        assertBuffer("s", equals: "s")
        assertBuffer("sex", equals: "s\u{1EBD}")
        assertBuffer("sexx", equals: "sex")
    }

    func test_tier2_66_single_n_vs_now_vs_noww() {
        assertBuffer("n", equals: "n")
        assertBuffer("now", equals: "n\u{01A1}")
        assertBuffer("noww", equals: "now")
    }

    func test_tier2_67_single_b_vs_box_vs_boxx() {
        assertBuffer("b", equals: "b")
        assertBuffer("box", equals: "b\u{00F5}")
        assertBuffer("boxx", equals: "box")
    }

    func test_tier2_68_single_m_vs_mix_vs_mixx() {
        assertBuffer("m", equals: "m")
        assertBuffer("mix", equals: "m\u{0129}")
        assertBuffer("mixx", equals: "mix")
    }

    func test_tier2_69_single_t_vs_tax_vs_taxx() {
        assertBuffer("t", equals: "t")
        assertBuffer("tax", equals: "t\u{00E3}")
        assertBuffer("taxx", equals: "tax")
    }

    func test_tier2_70_single_h_vs_how_vs_howw() {
        assertBuffer("h", equals: "h")
        assertBuffer("how", equals: "h\u{01A1}")
        assertBuffer("howw", equals: "how")
    }

    func test_tier2_71_single_l_vs_low_vs_loww() {
        assertBuffer("l", equals: "l")
        assertBuffer("low", equals: "l\u{01A1}")
        assertBuffer("loww", equals: "low")
    }

    func test_tier2_72_single_r_vs_raw_vs_raww() {
        assertBuffer("r", equals: "r")
        assertBuffer("raw", equals: "r\u{0103}")
        assertBuffer("raww", equals: "raw")
    }

    func test_tier2_73_single_g_vs_gas_vs_gass() {
        assertBuffer("g", equals: "g")
        assertBuffer("gas", equals: "g\u{00E1}")
        assertBuffer("gass", equals: "gas")
    }

    func test_tier2_74_rapid_burst_alternating_words_and_punctuation() {
        assertBuffer("status,user;status.user/status-user", equals: "status,user;status.user/status-user")
    }

    func test_tier2_75_extreme_token_length_long_url() {
        let longUrl = "https://subdomain.service.organization.co.jp/api/v2/resources/deep/endpoint?query=status&filter=active"
        assertBuffer(longUrl, equals: longUrl)
    }

    func test_tier2_76_extreme_token_length_deeply_nested_file_path() {
        let longPath = "src/modules/presentation/components/common/subviews/NavigationHeaderView.module.css"
        assertBuffer(longPath, equals: longPath)
    }

    func test_tier2_77_extreme_token_length_long_japanese_compound() {
        assertBuffer("itadakimasugochisousamaarigatou", equals: "itadakimasugochisousamaarigatou")
    }

    func test_tier2_78_embedded_version_numbers_semantic_versioning() {
        assertBuffer("v1.0.0 v2.14.3-beta.1 v3.0.0-rc.2", equals: "v1.0.0 v2.14.3-beta.1 v3.0.0-rc.2")
    }

    func test_tier2_79_embedded_digits_technical_identifiers_ipv6_utf8() {
        assertBuffer("v1.0.0 x86_64 arm64 utf8 h264 base64 md5 sha256", equals: "v1.0.0 x86_64 arm64 utf8 h264 base64 md5 sha256")
    }

    func test_tier2_80_casing_variations_all_caps_macos_ios_youtube() {
        assertBuffer("MACOS IOS YOUTUBE GITHUB OPENAI", equals: "MACOS IOS YOUTUBE GITHUB OPENAI")
    }

    func test_tier2_81_casing_variations_capitalized_romaji_places() {
        assertBuffer("Tokyo Osaka Kyoto Shinjuku Shibuya", equals: "Tokyo Osaka Kyoto Shinjuku Shibuya")
    }

    func test_tier2_82_symbols_mathematical_operators_in_code() {
        assertBuffer("sum = a + b * c / d - e;", equals: "sum = a + b * c / d - e;")
    }

    func test_tier2_83_symbols_comparison_and_logical_operators() {
        assertBuffer("x >= 10 && y <= 20 || z != 0", equals: "x >= 10 && y <= 20 || z != 0")
    }

    func test_tier2_84_trailing_punctuation_dot_comma_semicolon() {
        assertBuffer("readme.md. style.css, index.ts; main.swift:", equals: "readme.md. style.css, index.ts; main.swift:")
    }

    func test_tier2_85_leading_punctuation_at_hash_dollar() {
        assertBuffer("@user #general $price %ratio &status *ptr", equals: "@user #general $price %ratio &status *ptr")
    }

    func test_tier2_86_interspersed_tabs_and_newlines() {
        assertBuffer("status\tuser\nreview\tyear", equals: "status\tuser\nreview\tyear")
    }

    func test_tier2_87_repeated_vowels_english_vs_vietnamese() {
        assertBuffer("beer deer peer door floor poor", equals: "beer deer peer door floor poor")
    }

    func test_tier2_88_double_tone_keys_clearing_and_restoring() {
        assertBuffer("tieff", equals: "tief")
        assertBuffer("tiess", equals: "ties")
    }

    func test_tier2_89_vni_engine_camelcase_and_dotted_paths() {
        assertBuffer("macOS nhk.or.jp index.ts", equals: "macOS nhk.or.jp index.ts", inputMethod: .vni)
    }

    func test_tier2_90_vni_engine_japanese_romaji_and_english() {
        assertBuffer("tokyo osaka sushi ramen status review", equals: "tokyo osaka sushi ramen status review", inputMethod: .vni)
    }

    // =========================================================================
    // MARK: - Tier 3: Cross-Feature Interactions (18 tests)
    // =========================================================================

    func test_tier3_91_camelcase_in_urls_github_endpoints() {
        assertBuffer("https://api.gitHub.com/graphqlEndpoint", equals: "https://api.gitHub.com/graphqlEndpoint")
    }

    func test_tier3_92_camelcase_in_file_paths_react_components() {
        assertBuffer("src/components/UserAvatarView.module.css", equals: "src/components/UserAvatarView.module.css")
    }

    func test_tier3_93_english_words_following_japanese_romaji_food() {
        assertBuffer("sushi barr ramen shop wagyu steak matcha tea", equals: "sushi bar ramen shop wagyu steak matcha tea")
    }

    func test_tier3_94_english_words_following_japanese_romaji_places() {
        assertBuffer("tokyo station shinkansen train sakura park origami paper", equals: "tokyo station shinkansen train sakura park origami paper")
    }

    func test_tier3_95_japanese_romaji_in_vietnamese_sentences_culinary() {
        assertBuffer("H\u{00F4}m nay t\u{00F4}i \u{0111}i \u{0103}n ramen v\u{00E0} sushi \u{1EDF} Shibuya", equals: "H\u{00F4}m nay t\u{00F4}i \u{0111}i \u{0103}n ramen v\u{00E0} sushi \u{1EDF} Shibuya")
    }

    func test_tier3_96_japanese_romaji_in_vietnamese_sentences_travel() {
        assertBuffer("T\u{00F4}i mua v\u{00E9} \u{0111}i shinkansen t\u{1EEB} Tokyo \u{0111}\u{1EBF}n Osaka", equals: "T\u{00F4}i mua v\u{00E9} \u{0111}i shinkansen t\u{1EEB} Tokyo \u{0111}\u{1EBF}n Osaka")
    }

    func test_tier3_97_vietnamese_sentences_with_react_code_tokens() {
        assertBuffer("D\u{00F9}ng useState v\u{00E0} useEffect trong component React", equals: "D\u{00F9}ng useState v\u{00E0} useEffect trong component React")
    }

    func test_tier3_98_vietnamese_sentences_with_git_and_devops_commands() {
        assertBuffer("Ch\u{00FA}ng t\u{00F4}i deploy l\u{00EA}n GitHub Actions v\u{00E0} ki\u{1EC3}m tra status", equals: "Ch\u{00FA}ng t\u{00F4}i deploy l\u{00EA}n GitHub Actions v\u{00E0} ki\u{1EC3}m tra status")
    }

    func test_tier3_99_dotted_domains_inside_vietnamese_sentences() {
        assertBuffer("Truy c\u{1EAD}p nhk.or.jp \u{0111}\u{1EC3} theo d\u{00F5}i tin t\u{1EE9}c nh\u{00E9}", equals: "Truy c\u{1EAD}p nhk.or.jp \u{0111}\u{1EC3} theo d\u{00F5}i tin t\u{1EE9}c nh\u{00E9}")
    }

    func test_tier3_100_email_addresses_inside_vietnamese_sentences() {
        assertBuffer("G\u{1EED}i th\u{01B0} t\u{1EDB}i contact@example.us tr\u{01B0}\u{1EDB}c khi commit", equals: "G\u{1EED}i th\u{01B0} t\u{1EDB}i contact@example.us tr\u{01B0}\u{1EDB}c khi commit")
    }

    func test_tier3_101_vietnamese_words_with_english_substrings_ca_nha() {
        assertBuffer("car nh\u{00E0}", equals: "c\u{1EA3} nh\u{00E0}")
    }

    func test_tier3_102_vietnamese_words_with_english_substrings_hai_phong() {
        assertBuffer("hair ph\u{00F2}ng", equals: "h\u{1EA3}i ph\u{00F2}ng")
    }

    func test_tier3_103_vietnamese_words_with_english_substrings_no_ao_ho_lua() {
        assertBuffer("now \u{00E1}o v\u{00E0} how l\u{1EED}a", equals: "n\u{01A1} \u{00E1}o v\u{00E0} h\u{01A1} l\u{1EED}a")
    }

    func test_tier3_104_adjacent_camelcase_and_english_keywords() {
        assertBuffer("call useState then return false", equals: "call useState then return false")
    }

    func test_tier3_105_double_key_escapes_in_mixed_sentences() {
        assertBuffer("T\u{00F4}i l\u{00E1}i carr v\u{00E0} b\u{1EAF}t buss \u{0111}i l\u{00E0}m", equals: "T\u{00F4}i l\u{00E1}i car v\u{00E0} b\u{1EAF}t bus \u{0111}i l\u{00E0}m")
    }

    func test_tier3_106_trilingual_code_switching_single_line() {
        assertBuffer("Ch\u{00E0}o b\u{1EA1}n, m\u{1EDF} index.ts v\u{00E0} g\u{1EED}i arigatou nh\u{00E9}!", equals: "Ch\u{00E0}o b\u{1EA1}n, m\u{1EDF} index.ts v\u{00E0} g\u{1EED}i arigatou nh\u{00E9}!")
    }

    func test_tier3_107_json_payload_with_vietnamese_and_romaji_values() {
        assertBuffer("{\"city\": \"Tokyo\", \"dish\": \"ramen\", \"note\": \"ngon\"}", equals: "{\"city\": \"Tokyo\", \"dish\": \"ramen\", \"note\": \"ngon\"}")
    }

    func test_tier3_108_markdown_links_combining_vietnamese_text_and_url() {
        assertBuffer("[Trang ch\u{1EE7} NHK](https://nhk.or.jp/news)", equals: "[Trang ch\u{1EE7} NHK](https://nhk.or.jp/news)")
    }

    // =========================================================================
    // MARK: - Tier 4: Real-World Multilingual Application Scenarios (10 tests)
    // =========================================================================

    func test_tier4_109_scenario1_trilingual_developer_chat() {
        let input = "Chao ban, kiem tra useState va useEffect tai https://github.com/react/core nhe. Arigatou gozaimasu!"
        let expected = "Chao ban, kiem tra useState va useEffect tai https://github.com/react/core nhe. Arigatou gozaimasu!"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_110_scenario2_pull_request_code_review() {
        let input = "Code review cho PR nay: Hay kiem tra lai status trong index.ts va style.css de tranh loi render."
        let expected = "Code review cho PR nay: Hay kiem tra lai status trong index.ts va style.css de tranh loi render."
        assertBuffer(input, equals: expected)
    }

    func test_tier4_111_scenario3_japanese_culinary_and_travel_diary() {
        let input = "Chuyen di Tokyo va Kyoto rat vui! Chung toi da an sushi, ramen, tempura va wagyu o Shinjuku. Trai nghiem shinkansen that la sugoi va oishii!"
        let expected = "Chuyen di Tokyo va Kyoto rat vui! Chung toi da an sushi, ramen, tempura va wagyu o Shinjuku. Trai nghiem shinkansen that la sugoi va oishii!"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_112_scenario4_mid_word_backspace_correction_romaji() {
        let input = "wasaba<BS>i"
        assertBuffer(input, equals: "wasabi")
    }

    func test_tier4_113_scenario4b_mid_word_backspace_correction_camelcase() {
        let input = "useStzte<BS><BS><BS>ate"
        assertBuffer(input, equals: "useState")
    }

    func test_tier4_114_scenario5_cross_word_backspace_across_space() {
        let input = "xin chao <BS>f cac ban"
        assertBuffer(input, equals: "xin ch\u{00E0}o cac ban")
    }

    func test_tier4_115_scenario6_technical_markdown_documentation() {
        let input = "# Huong dan cai dat\nCai dat qua yarn hoac npm:\nnpm install axios redux\nXem readme.md de biet them chi tiet."
        let expected = "# Huong dan cai dat\nCai dat qua yarn hoac npm:\nnpm install axios redux\nXem readme.md de biet them chi tiet."
        assertBuffer(input, equals: expected)
    }

    func test_tier4_116_scenario7_trilingual_customer_support_ticket() {
        let input = "Kinh gui quy khach, ticket ve dich vu tai Yokohama branch da duoc update voi status thanh cong. Xin cam on va onegaishimasu!"
        let expected = "Kinh gui quy khach, ticket ve dich vu tai Yokohama branch da duoc update voi status thanh cong. Xin cam on va onegaishimasu!"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_117_scenario8_complex_multistep_editing_backspace_stress() {
        let input = "tokyoo<BS> osakaa<BS> kyotoo<BS> shinjukuu<BS>"
        assertBuffer(input, equals: "tokyo osaka kyoto shinjuku")
    }

    func test_tier4_118_scenario9_throughput_and_unicode_nfc_benchmark() {
        let textSample = "VietFlow macOS iOS useState useEffect nhk.or.jp index.ts tokyo osaka sushi ramen arigatou status review "
        var longInput = ""
        for _ in 0..<20 {
            longInput += textSample
        }

        let engine = makeEngine(inputMethod: .telex, tonePlacement: .modern)
        let startTime = Date()
        let result = applyKeystrokesAndBackspacesToScreenBuffer(longInput, engine: engine)
        let duration = Date().timeIntervalSince(startTime)
        let avgPerKey = (duration / Double(longInput.count)) * 1000.0

        XCTAssertTrue(avgPerKey < 1.0, "Average throughput must be < 1.0ms per keystroke (measured: \(avgPerKey)ms)")
        XCTAssertEqual(result, result.precomposedStringWithCanonicalMapping, "Full benchmark result must be strictly Unicode NFC normalized")
    }

    func test_tier4_119_multiword_vietnamese_phrases_mo_ta_dac_ta_dien_ta_ta_thuc() {
        assertBuffer("moo tar ", equals: "mô tả ")
        assertBuffer("ddawcj tar ", equals: "đặc tả ")
        assertBuffer("dieexn tar ", equals: "diễn tả ")
        assertBuffer("tar thuwcj ", equals: "tả thực ")
        assertBuffer("moo tar chi tieets veef booj gox VietFlow treen macOS taij osaka vaf tokyo", equals: "mô tả chi tiết về bộ gõ VietFlow trên macOS tại osaka và tokyo")
    }

    func test_tier4_120_japanese_brse_workplace_and_business_vocabulary() {
        let input = "hourensou houkoku renraku soudan kaigi shiryou kakunin shounin mitsumori nouki shimekiri tantousha okyakusama keiyaku seikyuusho shiyousho sekkei kaihatsu kenshuu shucchou zangyou yuukyuu teishutsu shuusei shinchoku"
        assertBuffer(input, equals: input)
    }

    func test_tier4_121_japanese_polite_verbs_copulas_and_conversational_expressions() {
        let input = "desu deshita mashita masen gozaimasu arigatougozaimasu ohayougozaimasu otsukaresamadeshita yoroshikuonegaishimasu wakarimashita kashikomarimashita sumimasendeshita naruhodo yappari kekkou zettai ippai chotto matte kudasai onegai"
        assertBuffer(input, equals: input)
    }

    func test_tier4_122_japanese_demonstratives_pronouns_colors_verbs_and_names() {
        let input = "kore sore dore koko soko asoko doko watashi anata kanojo kare minasan tomodachi kazoku kuro kuroi shiro shiroi suru kuru miru neru hajimaru naruto sasuke haruka misaki chisato tanaka hayashi kaisha"
        assertBuffer(input, equals: input)
    }

    func test_tier4_123_english_ss_consonant_and_ct_coda_technical_words() {
        let input = "password passwords passcode passport passkey crossword classroom lexer parser compiler queue reject project subject select connect protect expect inspect respect"
        assertBuffer(input, equals: input)
    }

    func test_tier4_124_scenario10_brse_slack_standup_trilingual_with_backspace() {
        let input = "Ohayougozaimasu Tanaka-san, hoom nay team ddax kakunin xong shiryou vaf update password, queue, lexer trong project. Xin guwir houkoku shinchoku truwowcs shimekiri, yoroshikuonegaishimasu!"
        let expected = "Ohayougozaimasu Tanaka-san, hôm nay team đã kakunin xong shiryou và update password, queue, lexer trong project. Xin gửi houkoku shinchoku trước shimekiri, yoroshikuonegaishimasu!"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_125_japanese_hyphenated_honorifics_and_prefectures() {
        let input = "Tanaka-san Yamada-san Suzuki-san Sato-sama Ito-sensei Nakamura-buchou Kobayashi-kachou Kato-shachou Haruka-chan Naruto-kun Tokyo-to Osaka-fu Kyoto-fu Hokkaido-chou Chiba-ken Saitama-ken Kanagawa-ken Shinjuku-ku Shibuya-ku"
        assertBuffer(input, equals: input)
    }

    func test_tier4_126_japanese_keigo_verbs_and_jlpt_daily_vocabulary() {
        let input = "tabemasu nomimasu ikimasu kaerimasu hanashimasu tsukurimasu uchiawase kaigishitsu uketsuke jimusho mitsumorisho ryoushuusho keiyakusho sekkeisho houkokusho shitsureishimasu otsukaresamadesu osewaninarimasu shouchishimashita ryoukaishimashita"
        assertBuffer(input, equals: input)
    }

    func test_tier4_127_english_th_coda_and_common_re_se_words() {
        let input = "tooth teeth booth bluetooth smooth there where here were these those whose chosen more chore bore tore wore shore store score ignore restore explore before therefore hire hires tire pure sure cure zoom zero zone"
        assertBuffer(input, equals: input)
    }

    func test_tier4_128_english_hyphenated_compounds_and_cloud_frameworks() {
        let input = "wi-fi real-time up-to-date end-to-end check-in check-out log-in log-out sign-in sign-out drop-down pop-up follow-up open-source full-stack front-end back-end auto-update gatsby bootstrap kubernetes terraform"
        assertBuffer(input, equals: input)
    }

    func test_tier4_129_scenario11_business_email_keigo_and_cloud_architecture() {
        let input = "Osewaninarimasu Sato-sama, chusng tooi ddax restore database vaf deploy heej thoongs real-time qua wi-fi taij jimusho Tokyo-to. Moij feature trong architecture ddeeuf secure, shouchishimashita!"
        let expected = "Osewaninarimasu Sato-sama, chúng tôi đã restore database và deploy hệ thống real-time qua wi-fi tại jimusho Tokyo-to. Mọi feature trong architecture đều secure, shouchishimashita!"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_130_english_trans_cons_boots_gats_prefixes_and_ff_clusters() {
        let input = "transfer transform translate transaction transparent transition transport transmission transmit construct constraint constant consumer consult bootstrap gatsby hotspot offspring offline offset offshore offload offhand"
        assertBuffer(input, equals: input)
    }

    func test_tier4_131_japanese_verb_conjugations_te_ta_nai_tai_forms() {
        let input = "tabete tabeta tabenai tabetai mite mita minai mitai shite shita shinai shitai kite kita konai kitai itte itta ikanai ikitai katte katta kawanai kaitai matte matta matanai machitai yonde yonda yomanai yomitai"
        assertBuffer(input, equals: input)
    }

    func test_tier4_132_mid_word_backspace_and_retype_english_and_romaji() {
        let input = "passwrod<BS><BS><BS>ord transmisison<BS><BS><BS><BS>sion offspirng<BS><BS><BS><BS>ring bootstarp<BS><BS><BS>rap shinkanesn<BS><BS><BS>sen otsukareasam<BS><BS><BS><BS>sama shouchishimashtia<BS><BS><BS>ita tot<BS>oth tehre<BS><BS><BS><BS>here zomo<BS><BS>om"
        let expected = "password transmission offspring bootstrap shinkansen otsukaresama shouchishimashita tooth there zoom"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_133_cross_word_backspace_across_trilingual_tokens() {
        let input = "Chusng tooi ddang test transmission vaf otsukaresama<BS><BS><BS><BS><BS><BS><BS><BS><BS><BS><BS><BS>shouchishimashita trong buooir hopj"
        let expected = "Chúng tôi đang test transmission và shouchishimashita trong buổi họp"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_134_scenario12_devops_networking_and_japanese_client_review() {
        let input = " Tanaka-sama, heej thoongs transmission ddax offload sang server offline vaf bootstrap xong cluster. Chusng tooi ddax kakunin vaf tabete bento truowsc khi release!"
        let expected = " Tanaka-sama, hệ thống transmission đã offload sang server offline và bootstrap xong cluster. Chúng tôi đã kakunin và tabete bento trước khi release!"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_135_japanese_geminate_ssh_and_conversational_adverbs() {
        let input = "issho isshoni isshou isshoukenmei irasshai irasshaimase zasshi ressha hassha kesshite asshuku sesshu kesshou nisshi busshi sasshi mochiron tabun zenzen chanto itsumo tokidoki tamani suguni yukkuri hayaku"
        assertBuffer(input, equals: input)
    }

    func test_tier4_136_japanese_tokyo_stations_neighborhoods_and_regions() {
        let input = "akihabara ikebukuro roppongi harajuku ebisu meguro shinagawa ueno asakusa ginza odaiba kichijoji shimokitazawa nakameguro daikanyama omotesando kabukicho marunouchi otemachi nihonbashi tsukiji toyosu haneda narita kansai kanto okinawa hakone kamakura fujisan"
        assertBuffer(input, equals: input)
    }

    func test_tier4_137_english_emerge_refuse_piece_purse_curse_and_dge_age_words() {
        let input = "piece pieces niece nieces chose refuse refused refuses refusal peruse purse purses curse curses cursed emerge emerged emerges emerging emergency emergencies bridge fridge edge badge judge budget gadget widget message package storage"
        assertBuffer(input, equals: input)
    }

    func test_tier4_138_vni_alphanumeric_tech_tokens_and_trilingual_sentence() {
        let input = "Chu1ng to6i d9a4 deploy vue3 web3 http2 http3 oauth2 base64 sha256 utf8 i18n l10n k8s s3 ec2 p2p b2b b2c o2o ta5i akihabara va2 roppongi!"
        let expected = "Chúng tôi đã deploy vue3 web3 http2 http3 oauth2 base64 sha256 utf8 i18n l10n k8s s3 ec2 p2p b2b b2c o2o tại akihabara và roppongi!"
        assertBuffer(input, equals: expected, inputMethod: .vni)
    }

    func test_tier4_139_scenario13_simple_telex_trilingual_tokyo_commute_and_incident_response() {
        let input = "Chusng tooi ddang ddi ressha tuwf akihabara ddeens roppongi isshoni. Neeus cos emergency hoawcj client refuse piece code nayf, team sex emerge vowsi solution mowsi!"
        let expected = "Chúng tôi đang đi ressha từ akihabara đến roppongi isshoni. Nếu có emergency hoặc client refuse piece code này, team sẽ emerge với solution mới!"
        assertBuffer(input, equals: expected, inputMethod: .simpleTelex)
    }

    func test_tier4_140_english_re_and_de_prefixed_words_multi_tone_offglide_protection() {
        let input = "refer refers referred referral reset resets resetting resort resorts reform reforms reformed reuse reused reuses reusable defend defends defended defender defendant defence defences deform deformed defrost deed deeds deem deemed mere dire rise rises risen rising"
        assertBuffer(input, equals: input)
    }

    func test_tier4_141_english_are_ere_ire_ore_ise_ize_words() {
        let input = "share care compare prepare declare square spare nightmare welfare sincere sphere atmosphere interfere fier<BS><BS>re firewall firebase wire wireless retire entire require inquire acquire inspire expire desire admire analyze organize recognize realize initialize serialize optimize customize summarize authorize synchronize prioritize"
        let expected = "share care compare prepare declare square spare nightmare welfare sincere sphere atmosphere interfere fire firewall firebase wire wireless retire entire require inquire acquire inspire expire desire admire analyze organize recognize realize initialize serialize optimize customize summarize authorize synchronize prioritize"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_142_japanese_dictionary_form_verbs_ru_su_bu_mu_tsu() {
        let input = "uru deru kesu osu motsu tatsu matsu katsu utsu sodatsu kaesu naosu nokosu okosu orosu otosu watasu hanasu sagasu hakobu erabu narabu manabu yobu tobu asobu musubu susumu tanomu wasureru oshieru oboeru kotaeru ukeru akeru shimeru tsukeru kakeru tasukeru hajimeru kimeru shiraberu"
        assertBuffer(input, equals: input)
    }

    func test_tier4_143_english_nce_ncy_nch_nse_nge_words() {
        let input = "fence hence since prince convince province chance dance romance finance balance distance instance substance assistance resistance performance importance insurance compliance guidance agency currency frequency tendency efficiency bench branch launch lunch punch trench wrench french pinch inch sense dense tense immense intense expense defense offense license response change range strange arrange exchange challenge orange"
        assertBuffer(input, equals: input)
    }

    func test_tier4_144_scenario14_software_architecture_refactoring_and_japanese_qa_review() {
        let input = "Nakamura-buchou, chusng tooi ddax shiraberu vaf naosu xong bug reset state. Team ddax refactor module defense để reuse component, optimize hiệu năng vaf tasukeru QA team kangaeru test cases!"
        let expected = "Nakamura-buchou, chúng tôi đã shiraberu và naosu xong bug reset state. Team đã refactor module defense để reuse component, optimize hiệu năng và tasukeru QA team kangaeru test cases!"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_145_japanese_reduplications_mimetics_and_cvncvn_adverbs() {
        let input = "dandan zenzen sanzan tantan banban ranran gangan dondon ponpon konkon nonbiri runrun sorosoro boroboro gorogoro noronoro torotoro poroporo moromoro korokoro barabara parapara sarasara zarazara karakara garagara harahara daradara perapera pikapika nikoniko dokidoki wakuwaku girigiri baribari batabata fuwafuwa sowasowa"
        assertBuffer(input, equals: input)
    }

    func test_tier4_146_japanese_medial_nn_and_cc_geminates_and_daily_nouns() {
        let input = "sennen shinnen zannen honne konna sonna anna donna minna annai mannaka tenno tennou onnanoko kocchi socchi acchi docchi maccha icchi micchaku bocchan isu uso hosoi hoso soto moto momo kesa konya konban maiasa maiban mainichi maishuu maitsuki maitoshi"
        assertBuffer(input, equals: input)
    }

    func test_tier4_147_japanese_katakana_long_vowel_loanwords_in_romaji() {
        let input = "meeru beesu keesu reesu keeki seetaa teeburu suteeki karee geemu peeji imeeji suteeji maneejaa pureeyaa deeta deetabeesu koohii kooto nooto booto soosu koosu supootsu suupu ruuru puuru tsuuru guruupu suupaa yuuzaa menyuu kaaten kaado paatii maaketto saabisu paatonaa apaato depaato sumaato sutaato sukaato"
        assertBuffer(input, equals: input)
    }

    func test_tier4_148_english_prefixes_dis_mis_un_in_sub_sup_ex_en_em_and_nn_cc_words() {
        let input = "discover discovery discuss discussion disconnect discount discourse disclose dismiss dispose dispute disrupt distribute disturb diverse divide divorce mistake misunderstand misuse uncover undergo understand undertake uniform unique universal university include increase indicate inform information infrastructure initial inject inquire insert inspect inspire install instruct integrate interact interface interfere interpret interrupt interview introduce investigate succeed success successful suggest supervise support suppose suppress surprise surround survive suspect suspend sustain exceed except exchange exclude excuse execute exercise exist expand expect experience experiment expert explain explore export expose express extend extract enable encounter encourage endorse endure enforce engage enhance ensure enter enterprise entertain entire environment embark embarrass embed embrace emerge employ empower seem seems seemed seeming seemingly sofa sofas connect channel tunnel banner manner dinner winner inner runner scanner annual announce account accept access accident accurate accuse occur occupy"
        assertBuffer(input, equals: input)
    }

    func test_tier4_149_scenario15_japanese_office_daily_life_and_english_project_planning() {
        let input = "Kesa minna ddax check meeru vaf annai lịch họp konban. Dự án dandan ổn định, sorosoro team sẽ connect qua channel Slack để discuss phương án support account access cho khách hàng!"
        let expected = "Kesa minna đã check meeru và annai lịch họp konban. Dự án dandan ổn định, sorosoro team sẽ connect qua channel Slack để discuss phương án support account access cho khách hàng!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Test Registration (149 Tests)
    // =========================================================================

    public override var allTests: [(name: String, test: TestMethod)] {
        return [
            // Tier 1: Feature Coverage (48 tests)
            ("test_tier1_01_camelcase_apple_platforms_macos_ios_watchos", test_tier1_01_camelcase_apple_platforms_macos_ios_watchos),
            ("test_tier1_02_camelcase_react_hooks_usestate_useeffect", test_tier1_02_camelcase_react_hooks_usestate_useeffect),
            ("test_tier1_03_camelcase_ui_event_handlers_onclick_viewmodel", test_tier1_03_camelcase_ui_event_handlers_onclick_viewmodel),
            ("test_tier1_04_pascalcase_brand_and_frameworks_vietflow_swiftui_superclip", test_tier1_04_pascalcase_brand_and_frameworks_vietflow_swiftui_superclip),
            ("test_tier1_05_pascalcase_services_github_gitlab_youtube_chatgpt", test_tier1_05_pascalcase_services_github_gitlab_youtube_chatgpt),
            ("test_tier1_06_camelcase_languages_typescript_javascript_graphql_postgresql", test_tier1_06_camelcase_languages_typescript_javascript_graphql_postgresql),
            ("test_tier1_07_dotted_domains_japanese_nhk_yahoo_amazon_co_jp", test_tier1_07_dotted_domains_japanese_nhk_yahoo_amazon_co_jp),
            ("test_tier1_08_dotted_domains_country_tlds_us_es_tw_vn", test_tier1_08_dotted_domains_country_tlds_us_es_tw_vn),
            ("test_tier1_09_code_file_extensions_readme_md_index_ts_app_rs", test_tier1_09_code_file_extensions_readme_md_index_ts_app_rs),
            ("test_tier1_10_web_extensions_style_css_file_sh_config_aw_main_swift", test_tier1_10_web_extensions_style_css_file_sh_config_aw_main_swift),
            ("test_tier1_11_technical_separators_slash_at_hyphen_underscore", test_tier1_11_technical_separators_slash_at_hyphen_underscore),
            ("test_tier1_12_full_url_protocols_https_git_ssh", test_tier1_12_full_url_protocols_https_git_ssh),
            ("test_tier1_13_english_keywords_batch1_yes_use_user_case_base", test_tier1_13_english_keywords_batch1_yes_use_user_case_base),
            ("test_tier1_14_english_keywords_batch2_rose_pose_house_mouse_course", test_tier1_14_english_keywords_batch2_rose_pose_house_mouse_course),
            ("test_tier1_15_english_keywords_batch3_sense_dense_false_focus_status_virus", test_tier1_15_english_keywords_batch3_sense_dense_false_focus_status_virus),
            ("test_tier1_16_english_keywords_batch4_next_text_context_index_syntax_linux", test_tier1_16_english_keywords_batch4_next_text_context_index_syntax_linux),
            ("test_tier1_17_english_keywords_batch5_year_hear_appear_engineer_poor_door", test_tier1_17_english_keywords_batch5_year_hear_appear_engineer_poor_door),
            ("test_tier1_18_english_keywords_batch6_news_review_down_town_own_dawn", test_tier1_18_english_keywords_batch6_news_review_down_town_own_dawn),
            ("test_tier1_19_vietnamese_preservation_car_bar_tar_her_sir", test_tier1_19_vietnamese_preservation_car_bar_tar_her_sir),
            ("test_tier1_20_vietnamese_preservation_bus_gas_box_tax_max", test_tier1_20_vietnamese_preservation_bus_gas_box_tax_max),
            ("test_tier1_21_vietnamese_preservation_mix_six_sex_now_how", test_tier1_21_vietnamese_preservation_mix_six_sex_now_how),
            ("test_tier1_22_vietnamese_preservation_low_row_cow_raw_law_saw_hair", test_tier1_22_vietnamese_preservation_low_row_cow_raw_law_saw_hair),
            ("test_tier1_23_double_key_escape_restores_english_carr_barr_tarr_herr", test_tier1_23_double_key_escape_restores_english_carr_barr_tarr_herr),
            ("test_tier1_24_double_key_escape_restores_english_sexx_noww_howw_boxx", test_tier1_24_double_key_escape_restores_english_sexx_noww_howw_boxx),
            ("test_tier1_25_japanese_places_tokyo_osaka_kyoto_shinjuku_shibuya", test_tier1_25_japanese_places_tokyo_osaka_kyoto_shinjuku_shibuya),
            ("test_tier1_26_japanese_places_hiroshima_yokohama_fukuoka_sapporo_fuji", test_tier1_26_japanese_places_hiroshima_yokohama_fukuoka_sapporo_fuji),
            ("test_tier1_27_japanese_culinary_sushi_sashimi_wasabi_tempura_ramen", test_tier1_27_japanese_culinary_sushi_sashimi_wasabi_tempura_ramen),
            ("test_tier1_28_japanese_culinary_matcha_wagyu_gyoza_tonkatsu_teriyaki", test_tier1_28_japanese_culinary_matcha_wagyu_gyoza_tonkatsu_teriyaki),
            ("test_tier1_29_japanese_social_arigatou_konnichiwa_sumimasen_daijoubu", test_tier1_29_japanese_social_arigatou_konnichiwa_sumimasen_daijoubu),
            ("test_tier1_30_japanese_cultural_anime_manga_origami_samurai_sakura_tsunami", test_tier1_30_japanese_cultural_anime_manga_origami_samurai_sakura_tsunami),
            ("test_tier1_31_romaji_adjectives_shii_ending_oishii_tanoshii_ureshii", test_tier1_31_romaji_adjectives_shii_ending_oishii_tanoshii_ureshii),
            ("test_tier1_32_romaji_adjectives_shii_ending_kanashii_muzukashii_yasashii", test_tier1_32_romaji_adjectives_shii_ending_kanashii_muzukashii_yasashii),
            ("test_tier1_33_romaji_adjectives_shii_ending_atarashii_isogashii_subarashii", test_tier1_33_romaji_adjectives_shii_ending_atarashii_isogashii_subarashii),
            ("test_tier1_34_romaji_adjectives_shii_ending_natsukashii_mendokusai", test_tier1_34_romaji_adjectives_shii_ending_natsukashii_mendokusai),
            ("test_tier1_35_romaji_phonotactic_sh_ts_clusters_shinkansen_tsunami_tsuki", test_tier1_35_romaji_phonotactic_sh_ts_clusters_shinkansen_tsunami_tsuki),
            ("test_tier1_36_romaji_phonotactic_geminates_and_clusters_matcha_matsuri_tatami", test_tier1_36_romaji_geminates_and_clusters_matcha_matsuri_tatami),
            ("test_tier1_37_status_bar_suspended_tooltip_contains_exact_string", test_tier1_37_status_bar_suspended_tooltip_contains_exact_string),
            ("test_tier1_38_status_bar_suspended_context_menu_header_exact_string", test_tier1_38_status_bar_suspended_context_menu_header_exact_string),
            ("test_tier1_39_status_bar_active_vietnamese_tooltip_and_context_menu", test_tier1_39_status_bar_active_vietnamese_tooltip_and_context_menu),
            ("test_tier1_40_status_bar_vector_icon_mode_e_when_suspended", test_tier1_40_status_bar_vector_icon_mode_e_when_suspended),
            ("test_tier1_41_status_bar_vector_icon_mode_v_when_active", test_tier1_41_status_bar_vector_icon_mode_v_when_active),
            ("test_tier1_42_status_bar_zero_emojis_audit_across_all_labels", test_tier1_42_status_bar_zero_emojis_audit_across_all_labels),
            ("test_tier1_43_classifier_identifies_kotoeri_japanese_hiragana", test_tier1_43_classifier_identifies_kotoeri_japanese_hiragana),
            ("test_tier1_44_classifier_identifies_kotoeri_katakana_and_halfwidth", test_tier1_44_classifier_identifies_kotoeri_katakana_and_halfwidth),
            ("test_tier1_45_classifier_identifies_kotoeri_romaji_typing_roman", test_tier1_45_classifier_identifies_kotoeri_romaji_typing_roman),
            ("test_tier1_46_classifier_identifies_third_party_japanese_imes", test_tier1_46_classifier_identifies_third_party_japanese_imes),
            ("test_tier1_47_state_manager_auto_suspends_and_saves_pre_foreign_mode", test_tier1_47_state_manager_auto_suspends_and_saves_pre_foreign_mode),
            ("test_tier1_48_state_manager_auto_restores_pre_foreign_mode_on_latin_return", test_tier1_48_state_manager_auto_restores_pre_foreign_mode_on_latin_return),

            // Tier 2: Boundary & Corner Cases (42 tests)
            ("test_tier2_49_empty_input_produces_empty_screen", test_tier2_49_empty_input_produces_empty_screen),
            ("test_tier2_50_single_space_and_whitespace_boundaries", test_tier2_50_single_space_and_whitespace_boundaries),
            ("test_tier2_51_single_character_isolated_keystrokes", test_tier2_51_single_character_isolated_keystrokes),
            ("test_tier2_52_consecutive_dots_and_ellipses", test_tier2_52_consecutive_dots_and_ellipses),
            ("test_tier2_53_consecutive_slashes_and_paths", test_tier2_53_consecutive_slashes_and_paths),
            ("test_tier2_54_consecutive_hyphens_and_dashes", test_tier2_54_consecutive_hyphens_and_dashes),
            ("test_tier2_55_consecutive_underscores", test_tier2_55_consecutive_underscores),
            ("test_tier2_56_enclosing_parentheses_around_urls", test_tier2_56_enclosing_parentheses_around_urls),
            ("test_tier2_57_enclosing_brackets_around_identifiers", test_tier2_57_enclosing_brackets_around_identifiers),
            ("test_tier2_58_enclosing_curly_braces_around_tokens", test_tier2_58_enclosing_curly_braces_around_tokens),
            ("test_tier2_59_enclosing_angle_brackets_generics", test_tier2_59_enclosing_angle_brackets_generics),
            ("test_tier2_60_single_quotes_around_romaji", test_tier2_60_single_quotes_around_romaji),
            ("test_tier2_61_double_quotes_around_camelcase", test_tier2_61_double_quotes_around_camelcase),
            ("test_tier2_62_backticks_around_code_identifiers", test_tier2_62_backticks_around_code_identifiers),
            ("test_tier2_63_mixed_enclosing_punctuation_and_symbols", test_tier2_63_mixed_enclosing_punctuation_and_symbols),
            ("test_tier2_64_single_c_vs_car_vs_carr", test_tier2_64_single_c_vs_car_vs_carr),
            ("test_tier2_65_single_s_vs_sex_vs_sexx", test_tier2_65_single_s_vs_sex_vs_sexx),
            ("test_tier2_66_single_n_vs_now_vs_noww", test_tier2_66_single_n_vs_now_vs_noww),
            ("test_tier2_67_single_b_vs_box_vs_boxx", test_tier2_67_single_b_vs_box_vs_boxx),
            ("test_tier2_68_single_m_vs_mix_vs_mixx", test_tier2_68_single_m_vs_mix_vs_mixx),
            ("test_tier2_69_single_t_vs_tax_vs_taxx", test_tier2_69_single_t_vs_tax_vs_taxx),
            ("test_tier2_70_single_h_vs_how_vs_howw", test_tier2_70_single_h_vs_how_vs_howw),
            ("test_tier2_71_single_l_vs_low_vs_loww", test_tier2_71_single_l_vs_low_vs_loww),
            ("test_tier2_72_single_r_vs_raw_vs_raww", test_tier2_72_single_r_vs_raw_vs_raww),
            ("test_tier2_73_single_g_vs_gas_vs_gass", test_tier2_73_single_g_vs_gas_vs_gass),
            ("test_tier2_74_rapid_burst_alternating_words_and_punctuation", test_tier2_74_rapid_burst_alternating_words_and_punctuation),
            ("test_tier2_75_extreme_token_length_long_url", test_tier2_75_extreme_token_length_long_url),
            ("test_tier2_76_extreme_token_length_deeply_nested_file_path", test_tier2_76_extreme_token_length_deeply_nested_file_path),
            ("test_tier2_77_extreme_token_length_long_japanese_compound", test_tier2_77_extreme_token_length_long_japanese_compound),
            ("test_tier2_78_embedded_version_numbers_semantic_versioning", test_tier2_78_embedded_version_numbers_semantic_versioning),
            ("test_tier2_79_embedded_digits_technical_identifiers_ipv6_utf8", test_tier2_79_embedded_digits_technical_identifiers_ipv6_utf8),
            ("test_tier2_80_casing_variations_all_caps_macos_ios_youtube", test_tier2_80_casing_variations_all_caps_macos_ios_youtube),
            ("test_tier2_81_casing_variations_capitalized_romaji_places", test_tier2_81_casing_variations_capitalized_romaji_places),
            ("test_tier2_82_symbols_mathematical_operators_in_code", test_tier2_82_symbols_mathematical_operators_in_code),
            ("test_tier2_83_symbols_comparison_and_logical_operators", test_tier2_83_symbols_comparison_and_logical_operators),
            ("test_tier2_84_trailing_punctuation_dot_comma_semicolon", test_tier2_84_trailing_punctuation_dot_comma_semicolon),
            ("test_tier2_85_leading_punctuation_at_hash_dollar", test_tier2_85_leading_punctuation_at_hash_dollar),
            ("test_tier2_86_interspersed_tabs_and_newlines", test_tier2_86_interspersed_tabs_and_newlines),
            ("test_tier2_87_repeated_vowels_english_vs_vietnamese", test_tier2_87_repeated_vowels_english_vs_vietnamese),
            ("test_tier2_88_double_tone_keys_clearing_and_restoring", test_tier2_88_double_tone_keys_clearing_and_restoring),
            ("test_tier2_89_vni_engine_camelcase_and_dotted_paths", test_tier2_89_vni_engine_camelcase_and_dotted_paths),
            ("test_tier2_90_vni_engine_japanese_romaji_and_english", test_tier2_90_vni_engine_japanese_romaji_and_english),

            // Tier 3: Cross-Feature Interactions (18 tests)
            ("test_tier3_91_camelcase_in_urls_github_endpoints", test_tier3_91_camelcase_in_urls_github_endpoints),
            ("test_tier3_92_camelcase_in_file_paths_react_components", test_tier3_92_camelcase_in_file_paths_react_components),
            ("test_tier3_93_english_words_following_japanese_romaji_food", test_tier3_93_english_words_following_japanese_romaji_food),
            ("test_tier3_94_english_words_following_japanese_romaji_places", test_tier3_94_english_words_following_japanese_romaji_places),
            ("test_tier3_95_japanese_romaji_in_vietnamese_sentences_culinary", test_tier3_95_japanese_romaji_in_vietnamese_sentences_culinary),
            ("test_tier3_96_japanese_romaji_in_vietnamese_sentences_travel", test_tier3_96_japanese_romaji_in_vietnamese_sentences_travel),
            ("test_tier3_97_vietnamese_sentences_with_react_code_tokens", test_tier3_97_vietnamese_sentences_with_react_code_tokens),
            ("test_tier3_98_vietnamese_sentences_with_git_and_devops_commands", test_tier3_98_vietnamese_sentences_with_git_and_devops_commands),
            ("test_tier3_99_dotted_domains_inside_vietnamese_sentences", test_tier3_99_dotted_domains_inside_vietnamese_sentences),
            ("test_tier3_100_email_addresses_inside_vietnamese_sentences", test_tier3_100_email_addresses_inside_vietnamese_sentences),
            ("test_tier3_101_vietnamese_words_with_english_substrings_ca_nha", test_tier3_101_vietnamese_words_with_english_substrings_ca_nha),
            ("test_tier3_102_vietnamese_words_with_english_substrings_hai_phong", test_tier3_102_vietnamese_words_with_english_substrings_hai_phong),
            ("test_tier3_103_vietnamese_words_with_english_substrings_no_ao_ho_lua", test_tier3_103_vietnamese_words_with_english_substrings_no_ao_ho_lua),
            ("test_tier3_104_adjacent_camelcase_and_english_keywords", test_tier3_104_adjacent_camelcase_and_english_keywords),
            ("test_tier3_105_double_key_escapes_in_mixed_sentences", test_tier3_105_double_key_escapes_in_mixed_sentences),
            ("test_tier3_106_trilingual_code_switching_single_line", test_tier3_106_trilingual_code_switching_single_line),
            ("test_tier3_107_json_payload_with_vietnamese_and_romaji_values", test_tier3_107_json_payload_with_vietnamese_and_romaji_values),
            ("test_tier3_108_markdown_links_combining_vietnamese_text_and_url", test_tier3_108_markdown_links_combining_vietnamese_text_and_url),

            // Tier 4: Real-World Multilingual Application Scenarios (36 tests)
            ("test_tier4_109_scenario1_trilingual_developer_chat", test_tier4_109_scenario1_trilingual_developer_chat),
            ("test_tier4_110_scenario2_pull_request_code_review", test_tier4_110_scenario2_pull_request_code_review),
            ("test_tier4_111_scenario3_japanese_culinary_and_travel_diary", test_tier4_111_scenario3_japanese_culinary_and_travel_diary),
            ("test_tier4_112_scenario4_mid_word_backspace_correction_romaji", test_tier4_112_scenario4_mid_word_backspace_correction_romaji),
            ("test_tier4_113_scenario4b_mid_word_backspace_correction_camelcase", test_tier4_113_scenario4b_mid_word_backspace_correction_camelcase),
            ("test_tier4_114_scenario5_cross_word_backspace_across_space", test_tier4_114_scenario5_cross_word_backspace_across_space),
            ("test_tier4_115_scenario6_technical_markdown_documentation", test_tier4_115_scenario6_technical_markdown_documentation),
            ("test_tier4_116_scenario7_trilingual_customer_support_ticket", test_tier4_116_scenario7_trilingual_customer_support_ticket),
            ("test_tier4_117_scenario8_complex_multistep_editing_backspace_stress", test_tier4_117_scenario8_complex_multistep_editing_backspace_stress),
            ("test_tier4_118_scenario9_throughput_and_unicode_nfc_benchmark", test_tier4_118_scenario9_throughput_and_unicode_nfc_benchmark),
            ("test_tier4_119_multiword_vietnamese_phrases_mo_ta_dac_ta_dien_ta_ta_thuc", test_tier4_119_multiword_vietnamese_phrases_mo_ta_dac_ta_dien_ta_ta_thuc),
            ("test_tier4_120_japanese_brse_workplace_and_business_vocabulary", test_tier4_120_japanese_brse_workplace_and_business_vocabulary),
            ("test_tier4_121_japanese_polite_verbs_copulas_and_conversational_expressions", test_tier4_121_japanese_polite_verbs_copulas_and_conversational_expressions),
            ("test_tier4_122_japanese_demonstratives_pronouns_colors_verbs_and_names", test_tier4_122_japanese_demonstratives_pronouns_colors_verbs_and_names),
            ("test_tier4_123_english_ss_consonant_and_ct_coda_technical_words", test_tier4_123_english_ss_consonant_and_ct_coda_technical_words),
            ("test_tier4_124_scenario10_brse_slack_standup_trilingual_with_backspace", test_tier4_124_scenario10_brse_slack_standup_trilingual_with_backspace),
            ("test_tier4_125_japanese_hyphenated_honorifics_and_prefectures", test_tier4_125_japanese_hyphenated_honorifics_and_prefectures),
            ("test_tier4_126_japanese_keigo_verbs_and_jlpt_daily_vocabulary", test_tier4_126_japanese_keigo_verbs_and_jlpt_daily_vocabulary),
            ("test_tier4_127_english_th_coda_and_common_re_se_words", test_tier4_127_english_th_coda_and_common_re_se_words),
            ("test_tier4_128_english_hyphenated_compounds_and_cloud_frameworks", test_tier4_128_english_hyphenated_compounds_and_cloud_frameworks),
            ("test_tier4_129_scenario11_business_email_keigo_and_cloud_architecture", test_tier4_129_scenario11_business_email_keigo_and_cloud_architecture),
            ("test_tier4_130_english_trans_cons_boots_gats_prefixes_and_ff_clusters", test_tier4_130_english_trans_cons_boots_gats_prefixes_and_ff_clusters),
            ("test_tier4_131_japanese_verb_conjugations_te_ta_nai_tai_forms", test_tier4_131_japanese_verb_conjugations_te_ta_nai_tai_forms),
            ("test_tier4_132_mid_word_backspace_and_retype_english_and_romaji", test_tier4_132_mid_word_backspace_and_retype_english_and_romaji),
            ("test_tier4_133_cross_word_backspace_across_trilingual_tokens", test_tier4_133_cross_word_backspace_across_trilingual_tokens),
            ("test_tier4_134_scenario12_devops_networking_and_japanese_client_review", test_tier4_134_scenario12_devops_networking_and_japanese_client_review),
            ("test_tier4_135_japanese_geminate_ssh_and_conversational_adverbs", test_tier4_135_japanese_geminate_ssh_and_conversational_adverbs),
            ("test_tier4_136_japanese_tokyo_stations_neighborhoods_and_regions", test_tier4_136_japanese_tokyo_stations_neighborhoods_and_regions),
            ("test_tier4_137_english_emerge_refuse_piece_purse_curse_and_dge_age_words", test_tier4_137_english_emerge_refuse_piece_purse_curse_and_dge_age_words),
            ("test_tier4_138_vni_alphanumeric_tech_tokens_and_trilingual_sentence", test_tier4_138_vni_alphanumeric_tech_tokens_and_trilingual_sentence),
            ("test_tier4_139_scenario13_simple_telex_trilingual_tokyo_commute_and_incident_response", test_tier4_139_scenario13_simple_telex_trilingual_tokyo_commute_and_incident_response),
            ("test_tier4_140_english_re_and_de_prefixed_words_multi_tone_offglide_protection", test_tier4_140_english_re_and_de_prefixed_words_multi_tone_offglide_protection),
            ("test_tier4_141_english_are_ere_ire_ore_ise_ize_words", test_tier4_141_english_are_ere_ire_ore_ise_ize_words),
            ("test_tier4_142_japanese_dictionary_form_verbs_ru_su_bu_mu_tsu", test_tier4_142_japanese_dictionary_form_verbs_ru_su_bu_mu_tsu),
            ("test_tier4_143_english_nce_ncy_nch_nse_nge_words", test_tier4_143_english_nce_ncy_nch_nse_nge_words),
            ("test_tier4_144_scenario14_software_architecture_refactoring_and_japanese_qa_review", test_tier4_144_scenario14_software_architecture_refactoring_and_japanese_qa_review),
            ("test_tier4_145_japanese_reduplications_mimetics_and_cvncvn_adverbs", test_tier4_145_japanese_reduplications_mimetics_and_cvncvn_adverbs),
            ("test_tier4_146_japanese_medial_nn_and_cc_geminates_and_daily_nouns", test_tier4_146_japanese_medial_nn_and_cc_geminates_and_daily_nouns),
            ("test_tier4_147_japanese_katakana_long_vowel_loanwords_in_romaji", test_tier4_147_japanese_katakana_long_vowel_loanwords_in_romaji),
            ("test_tier4_148_english_prefixes_dis_mis_un_in_sub_sup_ex_en_em_and_nn_cc_words", test_tier4_148_english_prefixes_dis_mis_un_in_sub_sup_ex_en_em_and_nn_cc_words),
            ("test_tier4_149_scenario15_japanese_office_daily_life_and_english_project_planning", test_tier4_149_scenario15_japanese_office_daily_life_and_english_project_planning),
        ]
    }
}
