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

    func test_tier4_150_english_ief_ier_eep_oa_oo_words_and_chiefue_disambiguation() {
        let input = "chief chiefs chiefly thief thieves tier tiers pier piers siege besiege liege fiend fiends diesel keep keeps peep peeps troop troops poop roast roasts roasted boast boasts coast coasts coastal boats coats goats soaps rooms booms moons roar roars soars oars roofs chiefue"
        let expected = "chief chiefs chiefly thief thieves tier tiers pier piers siege besiege liege fiend fiends diesel keep keeps peep peeps troop troops poop roast roasts roasted boast boasts coast coasts coastal boats coats goats soaps rooms booms moons roar roars soars oars roofs chiều"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_151_japanese_short_verbs_and_teiru_nagara_tara_reba_yasui_nikui_sugiru() {
        let input = "aru iru eru kiru niru heru teru keru naru saru nuru musu dete deta nete neta osoreru osorete dekakeru dekakete ireru irete inoru inotte tabeteiru hataraiteiru hanashinagara tabetara tabereba tabenakereba wakariyasui tsukaiyasui wakarinikui tsukainikui muzukashisugiru omoshirosugiru keredomo soredemo shitagatte tatoeba chinamini tokorode"
        assertBuffer(input, equals: input)
    }

    func test_tier4_152_mid_word_backspace_typos_in_english_and_romaji_words() {
        let input = "meeri<BS>u meeru<BS>u resot<BS>rt refom<BS>rm defom<BS>rm resorr<BS>t reforr<BS>m deforr<BS>m chieff<BS> thieff<BS> sorosor<BS>ro dandann<BS>"
        let expected = "meeru meeru resort reform deform resort reform deform chief thief sorosoro dandan"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_153_english_scientific_and_ious_eous_uous_adjectives() {
        let input = "brief grief relief belief cashier frontier premier souvenir barrier carrier courier warrior supplier identifier modifier qualifier verifier field yield shield wield fierce pierce friend client science scientific scientist patient ancient efficient sufficient gradient ingredient orient convenient audience experience conscious precious delicious suspicious ambitious cautious various serious curious furious mysterious obvious previous generous dangerous numerous enormous anonymous continuous ambiguous"
        assertBuffer(input, equals: input)
    }

    func test_tier4_154_scenario16_trilingual_product_launch_and_japanese_stakeholder_sync() {
        let input = "Tatoeba khi chief architect thiết kế free tier, chusng ta cần keep giao diện wakariyasui vaf tsukaiyasui. Chinamini chiều nay (chiefue) team sẽ dekakeru gặp khách hàng để báo cáo continuous experience!"
        let expected = "Tatoeba khi chief architect thiết kế free tier, chúng ta cần keep giao diện wakariyasui và tsukaiyasui. Chinamini chiều nay (chiều) team sẽ dekakeru gặp khách hàng để báo cáo continuous experience!"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_155_english_tw_prefixes_two_disambiguation_and_calendar_numbers() {
        let input = "two twos twofold twice twin twins twist twisted twisting twig twigs twilight twinkle twitter twelve twenty twentieth tweet tweets tweeted tweak tweaks tweaked tweed tuesday tuesdays wednesday thursday friday saturday sunday monday january february august september october november december twowng twongr"
        let expected = "two twos twofold twice twin twins twist twisted twisting twig twigs twilight twinkle twitter twelve twenty twentieth tweet tweets tweeted tweak tweaks tweaked tweed tuesday tuesdays wednesday thursday friday saturday sunday monday january february august september october november december tương tưởng"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_156_english_ai_au_ou_oi_oy_eu_ew_ui_ue_que_gue_words() {
        let input = "pair pairs chairman chairmen chairwoman chairperson armchair armchairs wheelchair wheelchairs aura auras austere austerity dues hues cues sues rues guest guests venue venues avenue avenues revenue revenues continue continues value values argue argues rescue rescues colleague colleagues dialogue catalogue technique techniques unique critique boutique"
        assertBuffer(input, equals: input)
    }

    func test_tier4_157_japanese_counters_numbers_time_and_kinship_vocabulary() {
        let input = "ichiban niban sanban hitori futari sannin hitotsu futatsu mittsu yottsu itsutsu muttsu nanatsu yattsu kokonotsu ippon nihon sanbon ippai nihai sanbai ikkai nikai sankai issai nisai sansai yonsai gosai rokusai hatachi isshuukan nishuukan ikkagetsu nikagetsu kazoku ryoushin otousan okaasan oniisan oneesan otouto imouto musuko musume tomodachi senpai kouhai douryou joushi buka"
        assertBuffer(input, equals: input)
    }

    func test_tier4_158_japanese_corporate_departments_and_business_documents() {
        let input = "kaigishitsu uketsuke jimusho eigyoubu kaihatsubu kikakubu torishimariyaku kabunushi ryoushuusho mitsumorisho hacchuusho nouhinsho keiyakusho houkokusho sekkeisho teiansho kikakusho rirekisho jikoshoukai uchiawase bounenkai shinnenkai kangeikai soubetsukai"
        assertBuffer(input, equals: input)
    }

    func test_tier4_159_scenario17_quarterly_business_review_and_japanese_contract_signing() {
        let input = "Thứ Ba (tuesday), chairman vaf two guests từ Tokyo sẽ có buổi uchiawase tại kaigishitsu cùng twenty colleagues. Chusng ta cần kiểm tra twice bản mitsumorisho, keiyakusho vaf nouhinsho để đạt mục tiêu revenue tương tưởng (twowng twongr)!"
        let expected = "Thứ Ba (tuesday), chairman và two guests từ Tokyo sẽ có buổi uchiawase tại kaigishitsu cùng twenty colleagues. Chúng ta cần kiểm tra twice bản mitsumorisho, keiyakusho và nouhinsho để đạt mục tiêu revenue tương tưởng (tương tưởng)!"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_160_english_sw_dw_thw_prefixes_and_vietnamese_shorthand_preservation() {
        let input = "sword swords swordfish swore sworn swung swum swarm swarms swarmed dwell dweller dwelling dwindle dwindled dwarf dwarfs dwarves thwart thwarted thwarts swar dwa thwa thwr"
        let expected = "sword swords swordfish swore sworn swung swum swarm swarms swarmed dwell dweller dwelling dwindle dwindled dwarf dwarfs dwarves thwart thwarted thwarts sửa dưa thưa thử"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_161_english_plural_rs_fs_lf_coda_and_ore_eer_oar_words() {
        let input = "bars cars mars tars wars honors donors hers cheers cheered cheering cheerful veers veered hairs chairs lairs choirs moors boors boar boars soar lore ore ores pore pores chefs refs reefs beefs hoofs nerfs serfs gulf gulfs golf golfs wolf wolfs"
        assertBuffer(input, equals: input)
    }

    func test_tier4_162_japanese_two_mora_nouns_names_and_sha_sho_structural_patterns() {
        let input = "sora nora dora mura nori toori muri pari maru gero basu gasu nasu tasu dasu hana kana nana mana sana kama nama hama kawa sawa nawa Hana-chan Kana-san Nana-chan shoubousho shiyakusho keisatsusho zeimusho basho jisho"
        assertBuffer(input, equals: input)
    }

    func test_tier4_163_japanese_passive_causative_potential_and_compound_inflections() {
        let input = "taberareru taberareta taberarenai mirareru korareru homerarera okorareru tanomareru tabesaseru tabesaseta misaseru yomaseru kakaseru tabesugiru nomisugiru takasugiru yomiyasui kakiyasui yominikui kakinikui tabenagara arukinagara tabenakatta ikanakatta"
        assertBuffer(input, equals: input)
    }

    func test_tier4_164_scenario18_trilingual_hospitality_and_software_release_celebration() {
        let input = "Sau khi hoàn thành sửa lỗi (swar) vaf vượt qua mọi rào cản thwart tiến độ, team cheers cùng các chefs tại izakaya trên con đường Chuo-toori! Dù lịch trình chotto muri, Hana-chan vẫn đặt basu cho cả đoàn ngắm sora vaf hana bên dòng kawa."
        let expected = "Sau khi hoàn thành sửa lỗi (sửa) và vượt qua mọi rào cản thwart tiến độ, team cheers cùng các chefs tại izakaya trên con đường Chuo-toori! Dù lịch trình chotto muri, Hana-chan vẫn đặt basu cho cả đoàn ngắm sora và hana bên dòng kawa."
        assertBuffer(input, equals: expected)
    }

    func test_tier4_165_japanese_katakana_long_vowel_aafu_aasu_aaru_eefu_eesu_eeru() {
        let input = "puran buranchi kuranchi burando gurando haafu saafu taafu naasu paasu baasu daasu gaaru paaru seefu peesu supeesu reeru beeru seeru teeru neeru sukeeru"
        assertBuffer(input, equals: input)
    }

    func test_tier4_166_english_x_family_and_multitone_rf_er_words() {
        let input = "nerf serf kerf miser boxes boxer boxers mixes mixer mixers vexes hexes sexes lexus oxen vixen thorax xerox prefix prefixes suffix suffixes matrix matrices paradox orthodox equinox detox"
        assertBuffer(input, equals: input)
    }

    func test_tier4_167_english_lk_lm_lv_rb_rp_rg_rv_rch_coda_clusters() {
        let input = "walk walks talked chalk stalk folk yolk silk milk bulk calm palm balm psalm realm helm film bulb valve solve resolve dissolve evolve involve revolve shelves wolves halves calves curb herb verb suburb disturb absorb harp sharp warp urge purge surge merge forge large charge curve carve starve nerve serve reserve preserve observe march arch search torch porch church"
        assertBuffer(input, equals: input)
    }

    func test_tier4_168_japanese_katakana_it_loanwords_in_romaji() {
        let input = "furoo fairu foruda fureemu fureemuwaaku furonto furontoendo bakkuendo saabaa saabisu shisutemu tesuto deeta deetabeesu nettowaaku sekyuriti purojekuto puroguramu purosesu purotokoru apurikeeshon apuri akaunto akusesu intaanetto intaafeesu enjinia maneejaa riidaa menbaa yuuzaa kuraianto burauza sukuriin sukejuuru tasuku chiketto bagu ririisu depuroi rebyuu maaji komitto ripojitori dokyumento fiidobakku miitingu imeeji peeji messeeji eraa suteetasu pafoomansu resuponsu rikuesuto roguin roguauto pasuwaado"
        assertBuffer(input, equals: input)
    }

    func test_tier4_169_scenario19_git_branch_workflow_and_katakana_it_standup() {
        let input = "Sáng nay enjinia team tạo buranchi mới từ ripojitori để maaji tính năng supeesu vaf sukeeru. Chusng ta cần check kĩ puran, tránh để nerf pafoomansu của mixer service hoặc gây eraa trên baasu hệ thống!"
        let expected = "Sáng nay enjinia team tạo buranchi mới từ ripojitori để maaji tính năng supeesu và sukeeru. Chúng ta cần check kĩ puran, tránh để nerf pafoomansu của mixer service hoặc gây eraa trên baasu hệ thống!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 11: -tle/-cle/-ple Words, -ies/-oes Verbs & Japanese -au/-aru/-eru Verbs (5 Tests)
    // =========================================================================

    func test_tier4_170_english_tle_cle_ple_and_medial_st_sc_sp_compounds() {
        let input = "display displays displayed displaying muscle muscles castle castles hustle hustles bustle bustles thistle thistles pestle pestles nestle nestles trestle trestles beetle beetles chestnut chestnuts dustbin dustpan passbook crossbow crossbar basswood chessboard pressman"
        assertBuffer(input, equals: input)
    }

    func test_tier4_171_english_ies_oes_ees_diet_quiet_and_tieseng_disambiguation() {
        let input = "died dies ties pies lies vies tries trier bier biers diet diets dieted dieting quiet quiets quieted quieter quietest quietly goes does foes woes roes noes toes hoes trees sees buys guys pays puts taxis sixes pasta pastas rasta basta lisp lisps gasp gasps rasp rasps cusp cusps tieseng"
        let expected = "died dies ties pies lies vies tries trier bier biers diet diets dieted dieting quiet quiets quieted quieter quietest quietly goes does foes woes roes noes toes hoes trees sees buys guys pays puts taxis sixes pasta pastas rasta basta lisp lisps gasp gasps rasp rasps cusp cusps tiếng"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_172_japanese_au_aru_iru_eru_verbs_and_daily_nouns() {
        let input = "arau harau sarau tarau sasaru nasaru masaru tasaru hasaru asaru chiru biru ieru mieru asa masa doro oto narau warau morau ukagau chigau mukau tsukau omou utau hirou sorou sasou mayou kayou kikoeru oboeru kangaeru oshieru kotaeru tsutaeru mukaeru"
        assertBuffer(input, equals: input)
    }

    func test_tier4_173_japanese_verb_conjugations_mashou_tai_nakatta_teiru_rareru_saseru_tara_reba() {
        let input = "ikimashou tabemashou shimashou kaerimashou ikitai tabetai shitai mitai ikitakunai ikitakatta ikanakatta tabenakatta shinakatta wakaranakatta ikanakereba tabeteiru miteiru shiteiru matteiru nondeiru taberareru mirareru korareru tabesaseru ikaseru ittara tabetara ikeba mireba tabenasai ikinasai"
        assertBuffer(input, equals: input)
    }

    func test_tier4_174_scenario20_trilingual_ui_display_debug_and_japanese_payment_workflow() {
        let input = "Buổi asa hôm nay trên biru tầng 5, màn hình display đã mieru rõ ràng và không còn oto lạ khi user buys gói pasta hay pays hoá đơn harau qua app; hệ thống goes mượt mà, does đúng thiết kế vaf giữ quiet ổn định!"
        let expected = "Buổi asa hôm nay trên biru tầng 5, màn hình display đã mieru rõ ràng và không còn oto lạ khi user buys gói pasta hay pays hoá đơn harau qua app; hệ thống goes mượt mà, does đúng thiết kế và giữ quiet ổn định!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 12: -ss/-ff/-rr Finals, -nl/-ml Codas, Air- Compounds & Ko-So-A-Do Adnominals (5 Tests)
    // =========================================================================

    func test_tier4_175_english_double_final_ss_ff_rr_words_and_less_ness_suffixes() {
        let input = "pass mass lass less mess guess chess kiss miss hiss piss boss loss moss toss cuss muss puss truss chaff quaff cheff tiff biff miff riff off spin-off doff toff cuff puff cream-puff muff ruff tuff purr burr curr err harmless armless moonless hairless airless wireless serverless stateless lossless"
        assertBuffer(input, equals: input)
    }

    func test_tier4_176_english_nl_ml_coda_clusters_air_compounds_and_oa_oo_ee_words() {
        let input = "keen keens keenly only mainly plainly suddenly openly evenly commonly certainly airs airman airmen airgun airbus airline airport airplane aircraft haircut haircuts hairpin hairpins hairnet moats moans roams coax coaxes coaxed doom dooms loom looms goop goops goons loons teems teens queens cheep cheeps"
        assertBuffer(input, equals: input)
    }

    func test_tier4_177_japanese_ko_so_a_do_adnominals_mono_and_katakana_p_b_g_d_words() {
        let input = "kono sono ano dono mono hono puro puraza garasu gacha guree guru buru puru bara bata pata pasa para poro boro basa gara goro gasa gata dara"
        assertBuffer(input, equals: input)
    }

    func test_tier4_178_english_ai_oi_ou_digraph_families() {
        let input = "mail emails fail failure detail retail domain remain contain obtain maintain entertain sustain retain pain gain bargain rain brain train drain grain strain stain chain blockchain plain explain complain campaign wait await trait portrait paid raid maid afraid claim oil boil coil foil soil spoil toilet coin bitcoin join point endpoint checkpoint appoint void avoid android voice invoice choice noise out about shout scout workout checkout layout logout timeout loud cloud icloud proud found sound round around surround background ground bound pound compound wound count account discount mount amount mountain fountain"
        assertBuffer(input, equals: input)
    }

    func test_tier4_179_scenario21_trilingual_game_dev_gacha_and_airline_booking_chat() {
        let input = "Trong kono bản spin-off mới của dự án gacha, sono hiệu ứng garasu màu guree tại puraza đã pass toàn bộ QA mà không gây loss hay mess; team puro đang keenly theo dõi chuyến airbus trước khi off đi cắt haircut cuối tuần!"
        let expected = "Trong kono bản spin-off mới của dự án gacha, sono hiệu ứng garasu màu guree tại puraza đã pass toàn bộ QA mà không gây loss hay mess; team puro đang keenly theo dõi chuyến airbus trước khi off đi cắt haircut cuối tuần!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 13: -rrh/-ffd Clusters, -ooing Words, Photo/Poem/Boost & 2-Mora Romaji (5 Tests)
    // =========================================================================

    func test_tier4_180_english_rrh_ffd_medial_clusters_and_ooing_words() {
        let input = "diarrhea cirrhosis myrrh arrhythmia pyrrhic hemorrhage hemorrhoid gonorrhea catarrh purrs purred burrs errs erred cuffed puffed muffed stuffed bluffed scuffed snuffed riffed tiffed miffed biffed chaffed quaffed doffed scoffed booing cooing mooing wooing shooing"
        assertBuffer(input, equals: input)
    }

    func test_tier4_181_english_photo_poem_poet_duet_boost_roost_dojo_and_ire_use_words() {
        let input = "photo photos photon photons photograph photographs photographer photography photoshop photocopy chair lair sire sires sired mire mires mired muse muses mused musing ruse ruses goer goers doer doers poem poems poet poets poetic poetry duet duets homo phono exo moron morons loco coco dojo dojos mojo boost boosts boosted booster roost roosts rooster goofs swops bias biases biased"
        assertBuffer(input, equals: input)
    }

    func test_tier4_182_japanese_two_mora_ru_ro_re_su_so_se_ji_jo_wa_fu_and_oi_adjectives() {
        let input = "taru baru paru garu daru piru seru meru beru peru muru duru ruru huru pura nure mure bure gure dure rure ure puri pora pasu pisu hesu sesu mesu tesu besu pesu gesu resu esu nusu susu busu pusu gusu dusu rusu usu nuse suse buse puse guse duse ruse posa paji poji puji giji nowa sowa towa rowa owa pafu kefu mefu nefu hefu sefu tefu defu befu pefu gefu refu efu moroi noroi"
        assertBuffer(input, equals: input)
    }

    func test_tier4_183_english_greek_latin_prefixes_co_re_pre_de_micro_crypto_thermo() {
        let input = "cooperate cooperation cooperative coordinate coordinates coordinated coordinating coordination coordinator coexist coexistence coincide coincident coincidence zoology zoological zoologist reopen reopened reorganize reorganized reenter reentry reelect reexamine reestablish reevaluate reinforce preapprove preoccupy preorder deodorant"
        assertBuffer(input, equals: input)
    }

    func test_tier4_184_scenario22_trilingual_photography_workshop_and_dojo_training_chat() {
        let input = "Chiều nay tại dojo ở peru, các poet vaf doer mang theo nhiều photos chụp trên chair cạnh taru để boost cảm hứng; dù mạng hơi noroi và thiết bị khá moroi nhưng không hề có bias, mỗi poem hay duet đều khiến khán giả cooing mà không ai booing cả!"
        let expected = "Chiều nay tại dojo ở peru, các poet và doer mang theo nhiều photos chụp trên chair cạnh taru để boost cảm hứng; dù mạng hơi noroi và thiết bị khá moroi nhưng không hề có bias, mỗi poem hay duet đều khiến khán giả cooing mà không ai booing cả!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 14: C/G/NG Orthography, -urou/-usou/-ujou Romaji, Cu(r/s/j)o Unlatch & AI/ML Tech Terms (5 Tests)
    // =========================================================================

    func test_tier4_185_japanese_urou_usou_ujou_long_vowel_and_uro_uso_ujo_disambiguation() {
        let input = "nuro suro muro buro guro duro ruro uro nuso suso muso buso puso guso duso ruso mujo sujo bujo kurou furou murou burou rurou surou nurou gurou purou durou fusou nusou susou kusou yusou zusou pusou gusou dusou rusou usou musou busou kujou mujou nujou fujou sujou yujou gujou bujou pujou dujou rujou ujou nusowc musoon busowm mujowt"
        let expected = "nuro suro muro buro guro duro ruro uro nuso suso muso buso puso guso duso ruso mujo sujo bujo kurou furou murou burou rurou surou nurou gurou purou durou fusou nusou susou kusou yusou zusou pusou gusou dusou rusou usou musou busou kujou mujou nujou fujou sujou yujou gujou bujou pujou dujou rujou ujou nước muốn bướm mượt"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_186_english_c_g_ng_front_vowel_orthography_and_laws_raws_saws_unlatch() {
        let input = "gems gets gels germs genes gents gees geeks cents cells celts cedes cites laws raws saws lawss rawss sawss gawk gawks bawk bawks mohawk mohawks tomahawk tomahawks sass sassy brass glass grass class lawsc rawsn sawsc sawsp sawst"
        let expected = "gems gets gels germs genes gents gees geeks cents cells celts cedes cites laws raws saws laws raws saws gawk gawks bawk bawks mohawk mohawks tomahawk tomahawks sass sassy brass glass grass class lắc rắn sắc sắp sắt"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_187_ai_ml_cloud_devops_and_nnx_dnn_nnl_nns_clusters() {
        let input = "onnx cudnn lora qlora gguf tensor tensors tensorflow pytorch keras numpy scipy pandas matplotlib jupyter transformer transformers tokenizer tokenizers embedding embeddings inference prompt prompts finetune finetuning dataset datasets checkpoint checkpoints gradient gradients epoch epochs dropout softmax sigmoid perplexity latency throughput quantize quantization distill distillation vllm ollama langchain pinecone milvus qdrant pgvector thinly cleanly inns finns banns"
        assertBuffer(input, equals: input)
    }

    func test_tier4_188_japanese_rei_sei_kei_and_ou_vocabulary() {
        let input = "kirei hirei shirei girei jirei irei korei torei borei dorei orei murei burei gurei purei urei kasei hasei tasei wasei yasei basei dasei kisei misei nisei hisei bisei gisei jisei risei isei kosei hosei sosei tosei yosei gosei bosei dosei musei fusei yusei jusei rikei fukei wakei reizouko undou boushi houhou jouhou ryokou gakkou ginkou kuukou kenkou seikou saikou tarou jirou saburou gorou ichirou satou katou itou saitou gotou kondou andou endou sudou kudou"
        assertBuffer(input, equals: input)
    }

    func test_tier4_189_scenario23_trilingual_ai_llm_inference_and_japanese_bathhouse_relax_chat() {
        let input = "Sau khi finetune mô hình lora và xuất file onnx chạy trên cudnn, chúng ta đã sửa hết bugs trong gems và sass theo đúng laws của dự án; tối nay cả nhóm sẽ ngâm buro thư giãn, ăn mì tại yokocho mà không còn kurou hay musou nữa, ai cũng muốn (musoon) uống nước (nusowc) mát!"
        let expected = "Sau khi finetune mô hình lora và xuất file onnx chạy trên cudnn, chúng ta đã sửa hết bugs trong gems và sass theo đúng laws của dự án; tối nay cả nhóm sẽ ngâm buro thư giãn, ăn mì tại yokocho mà không còn kurou hay musou nữa, ai cũng muốn (muốn) uống nước (nước) mát!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 15: Off-Glide S-Cluster Split Guard, Oai/Oay Onset Orthography, -rms/-rns Plurals & Romaji -ai/-ui (5 Tests)
    // =========================================================================

    func test_tier4_190_english_offglide_s_clusters_and_chasm_disc_corsair() {
        let input = "caustic roister miasma cloister cloisters boisterous moisture moisten hoist hoisted foist foisted joist joists oyster oysters disaster disasters acoustic acoustics diagnostic diagnostics chasm chasms spasm spasms plasma plasmas disc discs disk disks corsair corsairs"
        assertBuffer(input, equals: input)
    }

    func test_tier4_191_english_rms_rns_rfs_fs_rs_plurals_and_ed_ing_forms() {
        let input = "arms harms charms barns darns urns churns thorns morns terns kerns berms perms barfs armed arming harmed harming charmed charming darned darning churned churning permed barfed barfing naifs coifs loafs oafs liars leers seers queer queers tues duos"
        assertBuffer(input, equals: input)
    }

    func test_tier4_192_japanese_oai_onset_orthography_and_rai_sai_rui_sui_ura_vocabulary() {
        let input = "soroi sosori girai morai horai torai gorai borai gisai mosai nosai hosai sosai tosai bosai dosai girui gisui urana uraya urayama urayasu uragiri uragiru uraguchi uraniwa uragawa mosaic mosaics bonsai bonsais prosaic archaic algebraic voltaic photovoltaic formulaic"
        assertBuffer(input, equals: input)
    }

    func test_tier4_193_english_ism_ist_istic_and_spect_spire_families() {
        let input = "prism prisms schism altruism egoism heroism tourism terrorism journalism capitalism socialism communism mechanism mechanisms organism organisms metabolism symbolism optimism pessimism criticism mysticism skepticism fascism racism plastic plastics elastic drastic fantastic sarcastic scholastic enthusiastic mystic mystics rustic artistic statistic statistics realistic optimistic pessimistic holistic logistic logistics linguistic linguistics heuristic heuristics domestic majestic aspect aspects prospect prospects respect respects suspect suspects inspect inspects expect expects perspective perspectives"
        assertBuffer(input, equals: input)
    }

    func test_tier4_194_scenario24_trilingual_disaster_recovery_bosai_and_urayasu_trip_chat() {
        let input = "Trong buổi diễn tập bosai tại urayasu gần công viên, hệ thống lưu trữ trên discs đã vượt qua bài test chịu tải caustic mà không để xảy ra chasm dữ liệu; mọi thiết bị soroi đầy đủ từ cổng uraguchi đến khu vườn bonsai và bức tường mosaic, giúp giảm thiểu harms cho toàn bộ dự án!"
        let expected = "Trong buổi diễn tập bosai tại urayasu gần công viên, hệ thống lưu trữ trên discs đã vượt qua bài test chịu tải caustic mà không để xảy ra chasm dữ liệu; mọi thiết bị soroi đầy đủ từ cổng uraguchi đến khu vườn bonsai và bức tường mosaic, giúp giảm thiểu harms cho toàn bộ dự án!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 16: -owing Split Guard, Single-Vowel Y Coda Orthography, Life Unlatch & Romaji -fu/-ju (5 Tests)
    // =========================================================================

    func test_tier4_195_english_owing_awing_ewing_participles() {
        let input = "bowing mowing rowing sowing towing vowing cowing sawing pawing jawing cawing rawing lawing thawing drawing gnawing clawing flawing brewing chewing crewing hewing mewing sewing skewing spewing stewing viewing reviewing interviewing previewing renewing"
        assertBuffer(input, equals: input)
    }

    func test_tier4_196_english_single_y_coda_orthography_and_life_disambiguation() {
        let input = "lynx styx calyx oryx coccyx bombyx minx minxes manx bronx spanx sans life lifelong lifestyle lifetime lifespan lifeguard lifeline lifeless wildlife afterlife nightlife midlife lifeem lifeen lifeeu"
        let expected = "lynx styx calyx oryx coccyx bombyx minx minxes manx bronx spanx sans life lifelong lifestyle lifetime lifespan lifeguard lifeline lifeless wildlife afterlife nightlife midlife liềm liền liều"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_197_japanese_ifu_ufu_iju_uju_and_cuuw_unlatch() {
        let input = "kifu hifu gifu rufu kufu mufu nufu fufu sufu yufu gufu bufu dufu pufu kiju miju niju hiju biju giju riju kuju muju nuju fuju suju yuju guju buju puju duju ruju cufuw"
        let expected = "kifu hifu gifu rufu kufu mufu nufu fufu sufu yufu gufu bufu dufu pufu kiju miju niju hiju biju giju riju kuju muju nuju fuju suju yuju guju buju puju duju ruju cừu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_198_japanese_wa_za_ze_zo_zu_and_oru_ori_vocabulary() {
        let input = "kawaru kawari kawagoe kawaguchi kawanishi kawase sawaru sawagi sawagu sawayaka mawaru mawari mawasu mawashi tawara tawamure nawate nawabari yawaraka yawarakai yawaragu zawazawa owari owaru suwaru suwari biwako niwatori wakaba wakame wakamono wakare wakaru wakai wakate wakayama wakusei warau warai waribiki warikan kazari kazaru mazaru mazeru mazui hazukashii hazusu suzuki suzume suzushii kizuku kizuna mizugi mizuumi shizuka shizuku shizen bijin bijutsu gijutsu kaoru naoru taoru kaori naori haori"
        assertBuffer(input, equals: input)
    }

    func test_tier4_199_scenario25_trilingual_gifu_wildlife_expedition_and_rowing_lifestyle_chat() {
        let input = "Chuyến dã ngoại khám phá wildlife tại tỉnh gifu vaf suối nước nóng yufuin mang lại trải nghiệm lifestyle tuyệt vời; cả đoàn vừa chèo thuyền rowing trên hồ biwako, vừa ngắm loài linh miêu lynx quý hiếm và quyết định làm việc chăm chỉ liền (lifeen) mạch suốt tuần tới!"
        let expected = "Chuyến dã ngoại khám phá wildlife tại tỉnh gifu và suối nước nóng yufuin mang lại trải nghiệm lifestyle tuyệt vời; cả đoàn vừa chèo thuyền rowing trên hồ biwako, vừa ngắm loài linh miêu lynx quý hiếm và quyết định làm việc chăm chỉ liền (liền) mạch suốt tuần tới!"
        assertBuffer(input, equals: expected)
    }

    // --- Cycle 17: Mid-Word Tone Clusters, Mid-Word 'z' After Tone, 'oe' Onset Orthography & '-ise' Unlatch (Tests 200-204) ---

    func test_tier4_200_english_mid_word_tone_clusters_rs_rj_rf_sf_sr() {
        let input = "terse terser tersest tersely corset corsets corsage borscht gorse morse torso torsos torsion perjure perjures perjured perjury surfer surfers surfing surface surfaces surfaced surfeit surfboard turfed serfdom perfume perforate curfew parfait forfeit satisfy satisfies satisfied satisfaction misfit misfits misfire misfortune disfigure disrupt disrupts disrupted disruption disregard disrespect misread misrule"
        assertBuffer(input, equals: input)
    }

    func test_tier4_201_mid_word_z_after_tone_and_end_of_word_z_clear_preservation() {
        let input = "horizon horizons horizontal horizontally misuzu isuzu kanarazu kisarazu mirza forza tarzan marzipan harz toansz moiwsz yeusez"
        let expected = "horizon horizons horizontal horizontally misuzu isuzu kanarazu kisarazu mirza forza tarzan marzipan harz toan mơi yêu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_202_invalid_oe_onsets_and_axis_thaw_hero_vocabulary() {
        let input = "gore gores gored sore sores sorely cores bores pores mores sose sosei sosen mose bose bosei gose gosei rore axis axes axon axons axiom axioms thaw thaws thawed thawing hero heroes heroic heroin heroine heroism nero morn corm porn loris pars irs sirs dirs ors urs ers roots"
        assertBuffer(input, equals: input)
    }

    func test_tier4_203_japanese_ise_isu_isa_eso_seru_reru_and_i_e_unlatch() {
        let input = "mise nise kise hise bise gise tise dise sise rire kiseru hiseru niseru saseru kaseru maseru naseru haseru taseru daseru yaseru noseru koseru moseru yoseru rareru reru rero rere rora rori roro rore rara rari raru rira riru rura ruri kisa misa hisa chisa kisu misu nisu hisu risu aisu naisu husu tusu kusu yusu huse tuse yuse huso tuso kuso yuso keso meso neso heso teso deso beso geso tiseeng giseeng miseen kiseem hiseen"
        let expected = "mise nise kise hise bise gise tise dise sise rire kiseru hiseru niseru saseru kaseru maseru naseru haseru taseru daseru yaseru noseru koseru moseru yoseru rareru reru rero rere rora rori roro rore rara rari raru rira riru rura ruri kisa misa hisa chisa kisu misu nisu hisu risu aisu naisu husu tusu kusu yusu huse tuse yuse huso tuso kuso yuso keso meso neso heso teso deso beso geso tiếng giếng miến kiếm hiến"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_204_scenario26_trilingual_horizon_store_mise_and_heroic_refactor_chat() {
        let input = "Sau khi dạo quanh các cửa hàng mise cổ kính ở kisarazu vaf thưởng thức kem aisu vị marzipan cùng súp borscht nóng hổi, đội ngũ heroic engineers đã ngắm đường chân trời horizon tuyệt đẹp, đồng thời viết tài liệu concise & terse để cải thiện tiến (tiseeng) độ dự án!"
        let expected = "Sau khi dạo quanh các cửa hàng mise cổ kính ở kisarazu và thưởng thức kem aisu vị marzipan cùng súp borscht nóng hổi, đội ngũ heroic engineers đã ngắm đường chân trời horizon tuyệt đẹp, đồng thời viết tài liệu concise & terse để cải thiện tiến (tiếng) độ dự án!"
        assertBuffer(input, equals: expected)
    }

    // --- Cycle 18: Non-'qu' 'y+' Nucleus Orthography, Invalid 'oa' Onsets, '-mb-' Coda Cluster & Romaji/English Lexicon (Tests 205-209) ---

    func test_tier4_205_english_non_qu_y_nucleus_orthography_pyre_tyre_lyre_byre_gyre() {
        let input = "pyre pyres pyrex pyrite pyro pyramid pyramids tyre tyres tyrant tyrants tyranny tyro tyros lyre lyres lyric lyrics lyrical byre byres byron gyre gyres gyro gyros gyrate gyrates quyenef quyeets yeues"
        let expected = "pyre pyres pyrex pyrite pyro pyramid pyramids tyre tyres tyrant tyrants tyranny tyro tyros lyre lyres lyric lyrics lyrical byre byres byron gyre gyres gyro gyros gyrate gyrates quyền quyết yếu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_206_invalid_oa_onsets_trojan_borax_mosa_nosa_bosa_rora() {
        let input = "trojan trojans borax mosa nosa bosa rora moan moans roan roans roam roams boar boars roar roars"
        assertBuffer(input, equals: input)
    }

    func test_tier4_207_english_mb_coda_cluster_boombox_catacomb_and_ajax_taxi_luxe() {
        let input = "boombox bomb bombs bomber comb combs combine combat combo tomb tombs womb climb climbs thumb thumbs crumb crumbs humble rumble stumble tumble symbol symbols rife ajar ajax maxi maxis taxi trex tuxes luxe"
        assertBuffer(input, equals: input)
    }

    func test_tier4_208_japanese_yasa_yoso_kase_mase_sase_kosa_soso_hura_vocabulary() {
        let input = "yasa yase yoso yose kase kaso mase maso nase hase sase saso sasu tase dase gase kosa kose gosa dosa sosa soso tosa hura hure huri huro"
        assertBuffer(input, equals: input)
    }

    func test_tier4_209_scenario27_trilingual_security_trojan_ajax_and_tosa_trip_chat() {
        let input = "Đội bảo mật vừa phát hiện mã độc trojan ẩn trong request ajax nên đã rà soát toàn bộ module pyrex; cuối tuần này cả nhóm sẽ bắt taxi ra sân bay đi vùng tosa ngắm cảnh soso vaf mang theo loa boombox nghe nhạc!"
        let expected = "Đội bảo mật vừa phát hiện mã độc trojan ẩn trong request ajax nên đã rà soát toàn bộ module pyrex; cuối tuần này cả nhóm sẽ bắt taxi ra sân bay đi vùng tosa ngắm cảnh soso và mang theo loa boombox nghe nhạc!"
        assertBuffer(input, equals: expected)
    }

    // --- Cycle 19: Single-'p' Onset Tone/Horn Orthography, 'uê' Non-Palatal Coda Rule, 'C+u+r+V' Unlatching & Romaji/English Lexicon (Tests 210-214) ---

    func test_tier4_210_single_p_onset_tone_horn_orthography_and_ph_preservation() {
        let input = "poof poofs perm perms pers purs pox para pare pares pared pore pores pored pose poses posed peso pesos pisa puro pura puri paza paze pazo purr purrs phoos phowr phuwowngj pin poo pee"
        let expected = "poof poofs perm perms pers purs pox para pare pares pared pore pores pored pose poses posed peso pesos pisa puro pura puri paza paze pazo purr purrs phố phở phượng pin pô pê"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_211_ue_non_palatal_coda_orthography_tureen_and_vietnamese_ue_preservation() {
        let input = "tureen tureens careen careens spleen queen queens quene tuyeen tuyeetj huees thuee hueechs khueechs"
        let expected = "tureen tureens careen careens spleen quên queens quên tuyên tuyệt huế thuê huếch khuếch"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_212_english_r_controlled_barn_darn_harm_charm_thorn_churn_urn_swarth() {
        let input = "berm berms derm dermis churn churns urn urns ire barn barns darn darns tarn tarns barf barfs harm harms charm charms thorn thorns curs burs vers fers oofs goof swarth swarthy swar"
        let expected = "berm berms derm dermis churn churns urn urns ire barn barns darn darns tarn tarns barf barfs harm harms charm charms thorn thorns curs burs vers fers oofs goof swarth swarthy sửa"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_213_japanese_sura_suri_turo_tura_ture_nura_bura_gura_guri_and_vietnamese_unlatch() {
        let input = "sura suri turo tura ture turi nura nuri bura buri gura guri turooi guriw suraw nuraw buraw"
        let expected = "sura suri turo tura ture turi nura nuri bura buri gura guri tuổi gửi sửa nửa bửa"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_214_scenario28_trilingual_ramen_tureen_gura_stream_and_charm_chat() {
        let input = "Tối qua cả nhóm vừa xem stream của gura vừa thưởng thức súp trong thố tureen lớn tại quán cổ gần barn ngoại ô; món ăn có sức charm đặc biệt, không gây harm cho sức khoẻ vaf giúp anh em guriw (guriw) trọn niềm vui tuổi (turooi) trẻ!"
        let expected = "Tối qua cả nhóm vừa xem stream của gura vừa thưởng thức súp trong thố tureen lớn tại quán cổ gần barn ngoại ô; món ăn có sức charm đặc biệt, không gây harm cho sức khoẻ và giúp anh em gửi (gửi) trọn niềm vui tuổi (tuổi) trẻ!"
        assertBuffer(input, equals: expected)
    }

    // --- Cycle 20: Invalid 'g/gh/v + oa' Orthography, 'caws/maws/haws' & 'mara/hara/sara/tara' & 'kiete/miete' Unlatching (Tests 215-219) ---

    func test_tier4_215_invalid_g_gh_v_oa_onsets_gora_gosa_goats_goal_and_vietnamese_oa_preservation() {
        let input = "gora gosa goats goal goals goad goads hoar toar doaj ddoanj ngoan khoac"
        let expected = "gora gosa goats goal goals goad goads hỏa tỏa dọa đoạn ngoan khoac"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_216_english_caws_maws_haws_sere_and_vietnamese_cawst_mawst_hawst_unlatch() {
        let input = "caws maws hawsaws<BS><BS><BS> claws flaws draws straws paws jaws yaws sere cawst mawst hawst cawsn mawsc"
        let expected = "caws maws haws claws flaws draws straws paws jaws yaws sere cắt mắt hắt cắn mắc"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_217_japanese_mara_hara_sara_tara_and_vietnamese_maran_haram_saram_taram_unlatch() {
        let input = "mara hara sara tara maran haram saram taram"
        let expected = "mara hara sara tara mẩn hẩm sẩm tẩm"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_218_japanese_kire_nire_bire_gire_giro_hore_kieru_kiete_miete_uete_suete_and_unlatch() {
        let input = "kire nire bire gire giro hore kieru kiete miete uete suete kietes kietej mietes mietej kireem"
        let expected = "kire nire bire gire giro hore kieru kiete miete uete suete kiết kiệt miết miệt kiểm"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_219_scenario29_trilingual_sara_kire_sushi_and_kieru_bug_chat() {
        let input = "Tại quán sushi truyền thống, đầu bếp bày các lát cá kire đều đặn lên đĩa sara gốm cổ cạnh gốc cây nire; trong lúc đó team kỹ thuật đã làm kieru hoàn toàn lỗi hiển thị để miete rõ các chỉ số trên màn hình vaf kiểm (kireem) tra kĩ từng chi tiết kietej (kietej) tác!"
        let expected = "Tại quán sushi truyền thống, đầu bếp bày các lát cá kire đều đặn lên đĩa sara gốm cổ cạnh gốc cây nire; trong lúc đó team kỹ thuật đã làm kieru hoàn toàn lỗi hiển thị để miete rõ các chỉ số trên màn hình và kiểm (kiểm) tra kĩ từng chi tiết kiệt (kiệt) tác!"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_220_japanese_uwa_non_split_uwagi_uwaki_uwabe_uwate_and_suwa_guwa_buwa_unlatch() {
        let input = "uwagi uwaki uwabe uwate uwagaki uwanose suwa guwa buwa uwa uwas uwaf suwar suwax buwaf buwax guwaf"
        let expected = "uwagi uwaki uwabe uwate uwagaki uwanose suwa guwa buwa ưa ứa ừa sửa sữa bừa bữa gừa"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_221_english_won_wow_wows_yens_kern_and_vietnamese_wong_wonx_yense_unlatch() {
        let input = "won wow wows yens kern kerns wong wonx wonf yense"
        let expected = "won wow wows yens kern kerns ương ưỡn ườn yến"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_222_japanese_horo_moro_moso_toro_toso_soro_noro_noso_and_vietnamese_unlatch() {
        let input = "horo moro moso toro toso soro noro noso moroi noroi soroi moron morons toron toson tosot mosot nosot tosoi mosoi nosoi"
        let expected = "horo moro moso toro toso soro noro noso moroi noroi soroi moron morons tổn tốn tốt mốt nốt tối mối nối"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_223_japanese_tere_kere_nere_bere_dere_tese_kese_mese_nese_hese_sese_bese_dese_nesu_and_unlatch() {
        let input = "tere kere nere bere dere tese kese mese nese hese sese bese dese nesu kesech keset teset heset mesen nesen besen nesue mesue tesue"
        let expected = "tere kere nere bere dere tese kese mese nese hese sese bese dese nesu kếch kết tết hết mến nến bến nếu mếu tếu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_224_scenario30_trilingual_suwa_trip_uwagi_toro_sushi_and_won_wow_chat() {
        let input = "Chuyến đi hồ suwa mùa thu se lạnh nên mọi người đều mặc thêm áo khoác uwagi ấm áp, thưởng thức bữa (buwax) tối (tosoi) với sushi cá ngừ béo toro chỉ vài nghìn yens; cả nhóm đều thốt lên wow khi đội nhà won giải đấu vaf nếu (nesue) sửa (suwar) xong lỗi kern font cũng như kese sạch cache cũ thì kết (keset) quả sẽ tốt (tosot) hơn nữa!"
        let expected = "Chuyến đi hồ suwa mùa thu se lạnh nên mọi người đều mặc thêm áo khoác uwagi ấm áp, thưởng thức bữa (bữa) tối (tối) với sushi cá ngừ béo toro chỉ vài nghìn yens; cả nhóm đều thốt lên wow khi đội nhà won giải đấu và nếu (nếu) sửa (sửa) xong lỗi kern font cũng như kese sạch cache cũ thì kết (kết) quả sẽ tốt (tốt) hơn nữa!"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_225_japanese_howa_dowa_giwa_huwa_nuwa_ruwa_and_vietnamese_unlatch() {
        let input = "howa dowa giwa huwa nuwa ruwa howacj towats giwax huwas nuwar ruwar"
        let expected = "howa dowa giwa huwa nuwa ruwa hoặc toắt giữa hứa nửa rửa"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_226_english_hex_nix_tux_dux_and_vietnamese_hexe_nixu_tuxn_duxng_unlatch() {
        let input = "hex nix tux dux hexe nixu tuxn tuxm duxng"
        let expected = "hex nix tux dux hễ nĩu tũn tũm dũng"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_227_japanese_maja_naja_haja_saja_taja_baja_gaja_daja_raja_and_vietnamese_unlatch() {
        let input = "maja naja haja saja taja baja gaja daja raja tajap hajau dajay gajay bajac"
        let expected = "maja naja haja saja taja baja gaja daja raja tập hậu dậy gậy bậc"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_228_japanese_nojo_hojo_sojo_tojo_bojo_gojo_nujo_hujo_tujo_gujo_dujo_rujo_and_unlatch() {
        let input = "nojo hojo sojo tojo bojo gojo gojou hojou tojou nujo hujo tujo gujo dujo rujo hojoi tojoi bojoi nojoi hojop tojot bojot rujowu"
        let expected = "nojo hojo sojo tojo bojo gojo gojou hojou tojou nujo hujo tujo gujo dujo rujo hội tội bội nội hộp tột bột rượu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_229_scenario31_trilingual_gojo_hojo_hex_nix_tux_and_dowa_chat() {
        let input = "Trên máy trạm chạy nix và linux tux, kỹ thuật viên kiểm tra mã màu hex cho nhân vật gojo và gia tộc hojo trong truyện cổ dowa; hễ (hexe) phát hiện lỗi hiển thị giữa (giwax) các khung hình hoặc (howacj) tập (tajap) dữ liệu hội (hojoi) thoại thì hệ thống sẽ tự động hứa (huwas) đồng bộ lại ngay!"
        let expected = "Trên máy trạm chạy nix và linux tux, kỹ thuật viên kiểm tra mã màu hex cho nhân vật gojo và gia tộc hojo trong truyện cổ dowa; hễ (hễ) phát hiện lỗi hiển thị giữa (giữa) các khung hình hoặc (hoặc) tập (tập) dữ liệu hội (hội) thoại thì hệ thống sẽ tự động hứa (hứa) đồng bộ lại ngay!"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_230_english_and_romaji_ufo_ufos_nasa_sasa_hasa_tasa_dasa_rasa_and_unlatch() {
        let input = "ufo ufos nasa hasa sasa tasa dasa rasa tasam tasan tasat nasau hasap dasau rasat"
        let expected = "ufo ufos nasa hasa sasa tasa dasa rasa tấm tấn tất nấu hấp dấu rất"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_231_english_and_romaji_taxa_maxa_naxa_haxa_saxa_baxa_gaxa_daxa_raxa_and_unlatch() {
        let input = "taxa maxa naxa haxa saxa baxa gaxa daxa raxa maxau haxay gaxay baxay daxay"
        let expected = "taxa maxa naxa haxa saxa baxa gaxa daxa raxa mẫu hẫy gẫy bẫy dẫy"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_232_romaji_mafa_nafa_hafa_safa_tafa_bafa_gafa_dafa_rafa_and_unlatch() {
        let input = "mafa nafa hafa safa tafa bafa gafa dafa rafa mafam nafan hafau tafan bafau dafau"
        let expected = "mafa nafa hafa safa tafa bafa gafa dafa rafa mầm nần hầu tần bầu dầu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_233_romaji_mofo_nofo_hofo_sofo_tofo_bofo_gofo_dofo_rofo_and_unlatch() {
        let input = "mofo nofo hofo sofo tofo bofo gofo dofo rofo hofoi mofoi nofoi tofoi bofoi dofoi rofoi hofon bofon tofon"
        let expected = "mofo nofo hofo sofo tofo bofo gofo dofo rofo hồi mồi nồi tồi bồi dồi rồi hồn bồn tồn"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_234_scenario32_trilingual_nasa_ufo_taxa_sasa_and_rasa_chatbot_chat() {
        let input = "Dữ liệu vệ tinh nasa vừa công bố báo cáo về ufo và phân loại các loài thực vật taxa bao gồm trúc sasa Nhật Bản; nhóm kỹ sư dùng framework rasa để huấn luyện mô hình phân tích mẫu (maxau) vật, tránh bẫy (baxay) nhiễu và kiểm tra rất (rasat) kĩ dấu (dasau) hiệu phản hồi (hofoi) trước khi nấu (nasau) bữa tối bên nồi (nofoi) lẩu tofu!"
        let expected = "Dữ liệu vệ tinh nasa vừa công bố báo cáo về ufo và phân loại các loài thực vật taxa bao gồm trúc sasa Nhật Bản; nhóm kỹ sư dùng framework rasa để huấn luyện mô hình phân tích mẫu (mẫu) vật, tránh bẫy (bẫy) nhiễu và kiểm tra rất (rất) kĩ dấu (dấu) hiệu phản hồi (hồi) trước khi nấu (nấu) bữa tối bên nồi (nồi) lẩu tofu!"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_235_english_memes_themes_beset_xanax_dodos_gotos_topos_datas_and_rojos() {
        let input = "memes themes beset besets xanax dodos gotos topos mamas datas nonos rojos toxo roxo"
        let expected = "memes themes beset besets xanax dodos gotos topos mamas datas nonos rojos toxo roxo"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_236_japanese_turu_hufu_tufu_huju_tuju_gisi_gifi_and_vietnamese_w_unlatch() {
        let input = "turu hufu tufu huju tuju gisi gifi turuw hufuw tufuw hujuw tujuw"
        let expected = "turu hufu tufu huju tuju gisi gifi tửu hừu từu hựu tựu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_237_romaji_kefe_refe_keje_reje_and_vietnamese_cmnptu_unlatch() {
        let input = "kefe mefe nefe hefe sefe tefe befe defe refe keje meje neje heje seje teje beje deje reje hefen befen defen bejenh mejeu tejet"
        let expected = "kefe mefe nefe hefe sefe tefe befe defe refe keje meje neje heje seje teje beje deje reje hền bền dền bệnh mệu tệt"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_238_romaji_moxo_roxo_and_vietnamese_cmnpti_unlatch() {
        let input = "moxo noxo hoxo soxo toxo boxo goxo doxo roxo moxoi noxoi doxoi roxoi hoxon"
        let expected = "moxo noxo hoxo soxo toxo boxo goxo doxo roxo mỗi nỗi dỗi rỗi hỗn"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_239_scenario33_trilingual_memes_themes_turu_hufu_and_gotos_refactor_chat() {
        let input = "Sau khi đổi themes giao diện tối và chia sẻ vài memes vui nhộn về cặp vợ chồng hufu gấp hạc giấy turu, nhóm phát triển đã loại bỏ toàn bộ lệnh gotos rối rắm khiến dự án bị beset bởi lỗi bộ nhớ; mỗi (moxoi) thành viên đều kiên trì bền (befen) bỉ xử lý dứt điểm căn bệnh (bejenh) rò rỉ tài nguyên để đạt thành tựu (tujuw) vượt bậc!"
        let expected = "Sau khi đổi themes giao diện tối và chia sẻ vài memes vui nhộn về cặp vợ chồng hufu gấp hạc giấy turu, nhóm phát triển đã loại bỏ toàn bộ lệnh gotos rối rắm khiến dự án bị beset bởi lỗi bộ nhớ; mỗi (mỗi) thành viên đều kiên trì bền (bền) bỉ xử lý dứt điểm căn bệnh (bệnh) rò rỉ tài nguyên để đạt thành tựu (tựu) vượt bậc!"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_240_english_noop_noops_dadas_hies_lire_lise_vire_vise_quasar_hangars_and_noopj_unlatch() {
        let input = "noop noops dadas hies lire lise vire vise vises quasar quasars hangars noopj"
        let expected = "noop noops dadas hies lire lise vire vise vises quasar quasars hangars nộp"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_241_japanese_hieru_hiete_nieru_niete_iete_kujo_and_vietnamese_ieu_iet_unlatch() {
        let input = "hieru hiete nieru niete iete kujo kierue mierue hierue nierue hietes hietej nietes nietej ietes ietej dietes dietej"
        let expected = "hieru hiete nieru niete iete kujo kiểu miểu hiểu niểu hiết hiệt niết niệt iết iệt diết diệt"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_242_vietnamese_free_tone_unlatch_tier_bier_pier_ties_dies_lies_vies_pies_hies_chief_thief() {
        let input = "tierue tiereu tierem tieren bierue biereu bieren tiesue diesue liesue hiesue diesec diesem diesen diesep dieset liesec liesem liesen liesep lieset chiefen chiefeu chiefue thiefen thiefeu thiefue diesel"
        let expected = "tiểu tiểu tiểm tiển biểu biểu biển tiếu diếu liếu hiếu diếc diếm diến diếp diết liếc liếm liến liếp liết chiền chiều chiều thiền thiều thiều diesel"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_243_japanese_kufo_rufo_muxu_ruxu_kuxo_ruxo_kife_dife_kije_rije_and_vietnamese_unlatch() {
        let input = "kufo mufo nufo hufo sufo tufo bufo gufo dufo rufo muxu nuxu huxu suxu buxu guxu ruxu kuxo muxo nuxo huxo suxo tuxo buxo guxo duxo ruxo kife mife nife hife sife tife bife dife kije mije nije hije sije tije bije dije rije huxuw buxuw muxuw nuxuw suxuw ruxuw duxowng huxowng tuxowng muxow ruxow tifeen mifeen hifeen bifeen tijeen hijeen bijeen dijeen"
        let expected = "kufo mufo nufo hufo sufo tufo bufo gufo dufo rufo muxu nuxu huxu suxu buxu guxu ruxu kuxo muxo nuxo huxo suxo tuxo buxo guxo duxo ruxo kife mife nife hife sife tife bife dife kije mije nije hije sije tije bije dije rije hữu bữu mữu nữu sữu rữu dưỡng hưỡng tưỡng mưỡ rưỡ tiền miền hiền biền tiện hiện biện diện"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_244_scenario34_trilingual_noop_quasar_kujo_hieru_and_free_tone_ieu_iet_chat() {
        let input = "Trong ca trực đêm tại kujo, kỹ sư đã thay các hàm noop và noops thừa trong module quasar trước khi trà kịp hieru và món canh nieru trên bếp; cả nhóm đều hiểu (hierue) rõ từng kiểu (kierue) biểu (bierue) đồ dữ liệu, kiểm tra kỹ mặt tiền (tifeen) giao diện (dijeen) và tiêu diệt (dietej) triệt để mọi lỗi phát sinh trước khi nộp (noopj) báo cáo buổi chiều (chiefue)!"
        let expected = "Trong ca trực đêm tại kujo, kỹ sư đã thay các hàm noop và noops thừa trong module quasar trước khi trà kịp hieru và món canh nieru trên bếp; cả nhóm đều hiểu (hiểu) rõ từng kiểu (kiểu) biểu (biểu) đồ dữ liệu, kiểm tra kỹ mặt tiền (tiền) giao diện (diện) và tiêu diệt (diệt) triệt để mọi lỗi phát sinh trước khi nộp (nộp) báo cáo buổi chiều (chiều)!"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_245_japanese_nuete_muete_tieru_bieru_sieru_gieru_rieru_tiete_riete_and_vietnamese_unlatch() {
        let input = "nuete muete tieru bieru sieru gieru rieru tiete biete siete giete riete loofs nuetes nuetej muetes muetej tietes tietej bietes bietej sietes sietej gietes gietej rietes rietej sierue gierue rierue"
        let expected = "nuete muete tieru bieru sieru gieru rieru tiete biete siete giete riete loofs nuết nuệt muết muệt tiết tiệt biết biệt siết siệt giết giệt riết riệt siểu giểu riểu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_246_japanese_kete_sete_hete_mete_tete_bete_rete_and_vietnamese_et_unlatch() {
        let input = "kete sete hete mete tete bete rete dete nete ketes ketej setes setej hetes hetej metes metej tetes tetej betes betej retes retej detes detej netes netej letes letej"
        let expected = "kete sete hete mete tete bete rete dete nete kết kệt sết sệt hết hệt mết mệt tết tệt bết bệt rết rệt dết dệt nết nệt lết lệt"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_247_vietnamese_stop_final_cvtv_unlatch_motoj_sotos_batas_bataj_gatas_gataj() {
        let input = "moto soto bata gata pata motoj motos sotos sotoj batas bataj gatas gataj dataj datas"
        let expected = "moto soto bata gata pata một mốt sốt sột bất bật gất gật dật datas"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_248_vietnamese_nasal_final_cvnv_cvmv_fjx_unlatch_honof_donof_hanaj_manaj_hamaf() {
        let input = "hana mana nana sana kama hama nama sama momo homo mono hono dono sono kono hanaf hanaj hanax manaf manaj manax nanaf nanaj sanaf hamaf hamaj hamax namaf namaj namax samaf samaj samax momof momox homof homoj honof honoj honox donof donoj donox monof monoj monox sonof sonoj sonox honor donor"
        let expected = "hana mana nana sana kama hama nama sama momo homo mono hono dono sono kono hần hận hẫn mần mận mẫn nần nận sần hầm hậm hẫm nầm nậm nẫm sầm sậm sẫm mồm mỗm hồm hộm hồn hộn hỗn dồn dộn dỗn mồn mộn mỗn sồn sộn sỗn honor donor"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_249_scenario35_trilingual_nuete_hete_moto_and_vietnamese_delayed_circumflex_chat() {
        let input = "Sau nhiều năm hete tại Nhật Bản và tự tay nuete chiếc túi vải thủ công ở vùng moto, nghệ nhân dệt (detej) lụa vẫn giữ nguyên tính nết (netes) giản dị, dồn (donof) hết (hetes) tâm hồn (honof) vào một (motoj) xưởng hầm (hamaf) ấm áp và bật (bataj) đèn đón khách bất (batas) kể ngày mưa!"
        let expected = "Sau nhiều năm hete tại Nhật Bản và tự tay nuete chiếc túi vải thủ công ở vùng moto, nghệ nhân dệt (dệt) lụa vẫn giữ nguyên tính nết (nết) giản dị, dồn (dồn) hết (hết) tâm hồn (hồn) vào một (một) xưởng hầm (hầm) ấm áp và bật (bật) đèn đón khách bất (bất) kể ngày mưa!"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_250_english_and_romaji_data_goto_sata_toto_loto_mata_hata_noto_and_vietnamese_unlatch() {
        let input = "data goto sata toto loto mata nata hata tata rata noto hoto boto doto roto datas gotos dataj datad datads gotoj gotos matas mataj natas nataj hatas hataj satas sataj tatas tataj ratas rataj notos notoj hotos hotoj totos totoj botos botoj dotos dotoj dotods dotodj rotos rotoj lotos lotoj"
        let expected = "data goto sata toto loto mata nata hata tata rata noto hoto boto doto roto datas gotos dật đât đất gột gotos mất mật nất nật hất hật sất sật tất tật rất rật nốt nột hốt hột tốt tột bốt bột dốt dột đốt đột rốt rột lốt lột"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_251_english_and_romaji_sapa_napa_tapa_capa_topo_lapa_hopo_and_vietnamese_ap_op_ep_unlatch() {
        let input = "sapa napa tapa capa lapa hapa gapa dapa bapa mapa rapa topo hopo lopo bopo copo nopo dopo sopo mopo ropo bepe sepe nepe tepe depe hepe kepe mepe repe sapas sapaj napas napaj tapas tapaj capas capaj lapas lapaj hapas hapaj gapas gapaj dapas dapaj dapads dapadj bapas bapaj mapas mapaj rapas rapaj topos topoj hopos hopoj lopos lopoj bopos bopoj copos copoj nopos nopoj dopos dopoj dopods dopodj sopos sopoj mopos mopoj ropos ropoj bepes bepej sepes sepej nepes nepej tepes tepej depes depej depeds depedj hepes hepej mepes mepej repes repej"
        let expected = "sapa napa tapa capa lapa hapa gapa dapa bapa mapa rapa topo hopo lopo bopo copo nopo dopo sopo mopo ropo bepe sepe nepe tepe depe hepe kepe mepe repe sấp sập nấp nập tấp tập cấp cập lấp lập hấp hập gấp gập dấp dập đấp đập bấp bập mấp mập rấp rập topos tộp hốp hộp lốp lộp bốp bộp cốp cộp nốp nộp dốp dộp đốp độp sốp sộp mốp mộp rốp rộp bếp bệp sếp sệp nếp nệp tếp tệp dếp dệp đếp đệp hếp hệp mếp mệp rếp rệp"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_252_english_and_romaji_coco_loco_poco_moco_toco_soco_doco_boco_hoco_goco_roco_and_vietnamese_oc_unlatch() {
        let input = "coco loco poco moco toco soco doco boco hoco goco roco cocos cocoj locos locoj mocos mocoj tocos tocoj socos socoj docos docoj docods docodj bocos bocoj hocos hocoj gocos gocoj rocos rocoj"
        let expected = "coco loco poco moco toco soco doco boco hoco goco roco cốc cộc lốc lộc mốc mộc tốc tộc sốc sộc dốc dộc đốc độc bốc bộc hốc hộc gốc gộc rốc rộc"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_253_vietnamese_nasal_final_en_em_fjx_unlatch_bened_dened_lemed_nemed_remed_semed() {
        let input = "bene dene mene nene rene sene tene leme meme neme reme seme teme benef benej benex denef denej denex denedf denedj menef menej menex nenef nenej nenex renef renej renex senef senej senex tenef tenej tenex lemef lemej lemex memef memej memex nemef nemej nemex remef remej remex semef semej semex temef temej temex"
        let expected = "bên dên mên nên rên sên tên lêm mêm nêm rêm sêm têm bền bện bễn dền dện dễn đền đện mền mện mễn nền nện nễn rền rện rễn sền sện sễn tền tện tễn lềm lệm lễm mềm mệm mễm nềm nệm nễm rềm rệm rễm sềm sệm sễm tềm tệm tễm"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_254_scenario36_trilingual_data_goto_sata_sapa_toto_coco_and_vietnamese_delayed_circumflex_chat() {
        let input = "Khi phân tích data trên ổ cứng sata và loại bỏ lệnh goto cũ ở dự án toto tại vùng noto, kỹ sư đi du lịch sapa và napa vẫn kịp đóng hộp (hopoj) tài liệu, cập (capaj) nhật tập (tapaj) hồ sơ, lập (lapaj) tức xuống bếp (bepes) pha một cốc (cocos) cacao coco nóng để giữ tốc (tocos) độ làm việc tốt (totos) nhất bất (batas) chấp cơn lốc (locos) mùa đông!"
        let expected = "Khi phân tích data trên ổ cứng sata và loại bỏ lệnh goto cũ ở dự án toto tại vùng noto, kỹ sư đi du lịch sapa và napa vẫn kịp đóng hộp (hộp) tài liệu, cập (cập) nhật tập (tập) hồ sơ, lập (lập) tức xuống bếp (bếp) pha một cốc (cốc) cacao coco nóng để giữ tốc (tốc) độ làm việc tốt (tốt) nhất bất (bất) chấp cơn lốc (lốc) mùa đông!"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_255_english_and_romaji_choto_chata_choco_chapa_chopo_chete_chepe_quoto_photo_and_vietnamese_unlatch() {
        let input = "choto chata choco chapa chopo chete chepe quoto photo photos theta thetas chotos chotoj chatas chataj chocos chocoj chapas chapaj chopos chopoj chetes chetej chepes chepej quotos quotoj photoj thetej"
        let expected = "choto chata choco chapa chopo chete chepe quoto photo photos theta thetas chốt chột chất chật chốc chộc chấp chập chốp chộp chết chệt chếp chệp quốt quột phột thệt"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_256_japanese_chire_chise_chife_chije_chixe_chieru_chiete_and_vietnamese_ie_unlatch() {
        let input = "chire chise chife chije chixe chieru chiete chireen chiseen chifeen chijeen chixeen chireeu chiseeu chifeeu chijeeu chixeeu chiseet chijeet chiseec chierue chietes chietej"
        let expected = "chire chise chife chije chixe chieru chiete chiển chiến chiền chiện chiễn chiểu chiếu chiều chiệu chiễu chiết chiệt chiếc chiểu chiết chiệt"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_257_japanese_churu_chure_churo_chusu_chuse_chuso_chujo_chuju_chufo_chufu_chuxu_chuxo_and_vietnamese_unlatch() {
        let input = "churu chure churo chusu chuse chuso chujo chuju chufo chufu chuxu chuxo churuw chuxuw churowng chusowng chujowng chufowng chuxowng chusowc chujowc"
        let expected = "churu chure churo chusu chuse chuso chujo chuju chufo chufu chuxu chuxo chửu chữu chưởng chướng chượng chường chưỡng chước chược"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_258_japanese_chaja_chafa_chaxa_chasa_and_vietnamese_digraph_circumflex_unlatch() {
        let input = "chaja chafa chaxa chasa chajac chajam chajan chajap chajat chajau chajay chafam chafan chafau chafay chaxam chaxan chaxau chaxay chasac chasam chasan chasap chasat chasau chasay"
        let expected = "chaja chafa chaxa chasa chậc chậm chận chập chật chậu chậy trầm chần chầu chầy chẫm chẫn chẫu chẫyấc chấm chấn chấp chất chấu chấy".replacingOccurrences(of: "trầm", with: "chầm").replacingOccurrences(of: "chẫyấc", with: "chẫy chấc")
        assertBuffer(input, equals: expected)
    }

    func test_tier4_259_scenario37_trilingual_choto_choco_chieru_chire_and_vietnamese_digraph_unlatch_chat() {
        let input = "Trong giờ giải lao choto tại văn phòng Tokyo, cả nhóm thưởng thức bánh choco trước khi đá kịp chieru và ngắm cánh hoa sakura chire ngoài cửa sổ; anh kỹ sư vẫn chăm chú chốt (chotos) phương án thiết kế, chấp (chapas) nhận thử thách, chiết (chietes) xuất dữ liệu buổi chiều (chifeeu) và gửi lời chúc chưởng (churowng) phòng thật chậm (chajam) rãi, chắc chắn!"
        let expected = "Trong giờ giải lao choto tại văn phòng Tokyo, cả nhóm thưởng thức bánh choco trước khi đá kịp chieru và ngắm cánh hoa sakura chire ngoài cửa sổ; anh kỹ sư vẫn chăm chú chốt (chốt) phương án thiết kế, chấp (chấp) nhận thử thách, chiết (chiết) xuất dữ liệu buổi chiều (chiều) và gửi lời chúc chưởng (chưởng) phòng thật chậm (chậm) rãi, chắc chắn!"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_260_english_and_romaji_chara_charas_bara_gara_dara_nara_rara_and_vietnamese_ar_unlatch() {
        let input = "chara charas kara bara gara dara nara rara mara hara sara tara baram baran baray garam garan garay daram daran daray naram naran naray raram raran raray maram maran haram haran saram saran saray taram taran taray charam charan charay"
        let expected = "chara charas kara bara gara dara nara rara mara hara sara tara bẩm bẩn bẩy gẩm gẩn gẩy dẩm dẩn dẩy nẩm nẩn nẩy rẩm rẩn rẩy mẩm mẩn hẩm hẩn sẩm sẩn sẩy tẩm tẩn tẩy chẩm chẩn chẩy"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_261_japanese_koro_boro_goro_doro_roro_horo_toro_and_vietnamese_or_unlatch() {
        let input = "koro boro goro doro roro horo moro toro soro noro moroi noroi soroi moron morons boron borom boroi gorom goron goroi dorom doron doroi rorom roron roroi horom horon horoi torom toron toroi sorom soron noron choroi chorom"
        let expected = "koro boro goro doro roro horo moro toro soro noro moroi noroi soroi moron morons boron bổm bổi gổm gổn gổi dổm dổn dổi rổm rổn rổi hổm hổn hổi tổm tổn tổi sổm sổn nổn chổi chổm"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_262_japanese_mufe_chufe_muje_chuje_and_vietnamese_free_tone_ue_unlatch() {
        let input = "mufe nufe hufe sufe tufe bufe gufe dufe rufe chufe muje nuje huje suje tuje buje guje duje ruje chuje husee hufee hujee tusee tujee dusee dujee susee chusee chujee huseenh chuseenh tuseet dujeet"
        let expected = "mufe nufe hufe sufe tufe bufe gufe dufe rufe chufe muje nuje huje suje tuje buje guje duje ruje chuje huế huề huệ tuế tuệ duế duệ suế chuế chuệ huếnh chuếnh tuết duệt"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_263_vietnamese_duete_unlatch_duetes_duetej_and_duet_duets_preservation() {
        let input = "duet duets duete duetes duetej suete suetes suetej nuete nuetes nuetej muete muetes muetej"
        let expected = "duet duets duete duết duệt suete suết suệt nuete nuết nuệt muete muết muệt"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_264_scenario38_trilingual_chara_bara_nara_and_vietnamese_free_tone_ue_ar_or_chat() {
        let input = "Khi thiết kế chara mới lấy cảm hứng từ vườn hoa hồng bara tại thành phố nara và dạo chơi ngắm cảnh goro, họa sĩ đi chuyến tàu đêm về cố đô Huế (husee) vẫn cẩn (charan) thận dùng tẩy (taray) chỉnh lại từng bản tẩm (taram) màu phác thảo, dùng đòn bẩy (baray) sáng tạo để hạt giống nghệ thuật nẩy (naray) mầm và không để tổn (toron) hại đến tiến độ duyệt (dujeet) bản mẫu!"
        let expected = "Khi thiết kế chara mới lấy cảm hứng từ vườn hoa hồng bara tại thành phố nara và dạo chơi ngắm cảnh goro, họa sĩ đi chuyến tàu đêm về cố đô Huế (huế) vẫn cẩn (chẩn) thận dùng tẩy (tẩy) chỉnh lại từng bản tẩm (tẩm) màu phác thảo, dùng đòn bẩy (bẩy) sáng tạo để hạt giống nghệ thuật nẩy (nẩy) mầm và không để tổn (tổn) hại đến tiến độ duyệt (duệt) bản mẫu!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 31: Dura/Chura, Chese/Chere & Free-Tone -rn/-rm Unlatching
    // =========================================================================

    func test_tier4_265_japanese_dura_duri_chura_churi_and_vietnamese_ur_w_unlatch() {
        let input = "dura duri chura churi sura suri bura buri gura guri nura nuri duraw duriw churaw churiw suraw buraw nuraw guriw"
        let expected = "dura duri chura churi sura suri bura buri gura guri nura nuri dửa dửi chửa chửi sửa bửa nửa gửi"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_266_japanese_rese_chese_chefe_cheje_chere_cheru_and_vietnamese_e_unlatch() {
        let input = "rese chese chefe cheje chere cheru reset resets resen reseu cheset chejet chesem chesen chefen chejen cheseu chefeu chejeu cherem cheren chereu cherue"
        let expected = "rese chese chefe cheje chere cheru reset resets rến rếu chết chệt chếm chến chền chện chếu chều chệu chểm chển chểu chểu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_267_english_rn_preservation_and_vietnamese_free_tone_rng_unlatch() {
        let input = "turn turns turned burn burns burned churn churns churned urn urns barn barns darn darns tarn tarns morn morns morning thorn thorns born borne corn corns corner horn horns torn turng burng churng urng barng darng tarng morng thorng borng corng horng torng"
        let expected = "turn turns turned burn burns burned churn churns churned urn urns barn barns darn darns tarn tarns morn morns morning thorn thorns born borne corn corns corner horn horns torn tủng bủng chủng ủng bảng dảng tảng mỏng thỏng bỏng cỏng hỏng tỏng"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_268_english_rn_rm_preservation_and_vietnamese_free_tone_rnw_rngw_rmw_unlatch() {
        let input = "turnw turngw burnw burngw churnw churngw urnw urngw barnw barngw darnw darngw tarnw tarngw mornw thornw bornw cornw hornw tornw harm harms harmed harmw charm charms charmed charmw corm corms cormw"
        let expected = "tửn tửng bửn bửng chửn chửng ửn ửng bẳn bẳng dẳn dẳng tẳn tẳng mởn thởn bởn cởn hởn tởn harm harms harmed hẳm charm charms charmed chẳm corm corms cởm"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_269_scenario39_trilingual_chura_okinawa_turn_burn_and_vietnamese_free_tone_rng_chat() {
        let input = "Trong chuyến thăm thủy cung chura tại Okinawa, kỹ sư kiểm tra bộ truyền động dura trước mỗi turn chạy thử để tránh burn mạch hay gây harm cho thiết bị; cả đội luôn ủng (urng) hộ việc lập bảng (barng) theo dõi trên từng tảng (tarng) băng mỏng (morng), phòng tránh hư hỏng (horng) hoặc bỏng (borng) nhiệt khi nắng ửng (urngw) lên và giữ tinh thần chững chạc trước mọi chủng (churng) loại lỗi phát sinh!"
        let expected = "Trong chuyến thăm thủy cung chura tại Okinawa, kỹ sư kiểm tra bộ truyền động dura trước mỗi turn chạy thử để tránh burn mạch hay gây harm cho thiết bị; cả đội luôn ủng (ủng) hộ việc lập bảng (bảng) theo dõi trên từng tảng (tảng) băng mỏng (mỏng), phòng tránh hư hỏng (hỏng) hoặc bỏng (bỏng) nhiệt khi nắng ửng (ửng) lên và giữ tinh thần chững chạc trước mọi chủng (chủng) loại lỗi phát sinh!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 32: Goop/Troop/Loom/Keen, Sees/Trees/Toes & -uree Unlatching
    // =========================================================================

    func test_tier4_270_english_goop_troop_keep_cheep_preservation_and_vietnamese_gop_trop_kep_chep_unlatch() {
        let input = "noop noops noopj goop goops goopj troop troops troopj keep keeps keepj cheep cheeps cheepj peep peeps"
        let expected = "noop noops nộp goop goops gộp troop troops trộp keep keeps kệp cheep cheeps chệp peep peeps"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_271_english_loom_doom_deem_seem_keen_preservation_and_vietnamese_tone_unlatch() {
        let input = "loom looms loomf loomr loomx loomj doom dooms doomf doomr doomx doomj doomd doomdf doomdj deem deems deemf deemr deemx deemj deemd deemdf deemdj seem seems seemf seemr seemx seemj keen keens keenf keenr keenx keenj"
        let expected = "loom looms lồm lổm lỗm lộm doom dooms dồm dổm dỗm dộm đôm đồm độm deem deems dềm dểm dễm dệm đêm đềm đệm seem seems sềm sểm sễm sệm keen keens kền kển kễn kện"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_272_english_sees_trees_toes_hoes_preservation_and_vietnamese_sep_sen_seu_toet_hoet_unlatch() {
        let input = "sees seesp seesn seesu seest seesch trees treest treesu toes toest toess hoes hoest hoess foes woes roes noes"
        let expected = "sees sếp sến sếu sết sếch trees trết trếu toes toét toes hoes hoét hoes foes woes roes noes"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_273_japanese_hure_ture_dure_chure_preservation_and_vietnamese_huenh_tuenh_chuenh_unlatch() {
        let input = "hure ture dure sure bure gure nure mure rure chure tureen huree turee duree churee hureenh tureenh chureenh"
        let expected = "hure ture dure sure bure gure nure mure rure chure tureen huể tuể duể chuể huểnh tuểnh chuểnh"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_274_scenario40_trilingual_goop_loom_keen_sees_toes_and_vietnamese_gop_lom_ken_sep_toet_chat() {
        let input = "Khi đọc báo cáo tổng gộp (goopj) từ nhánh main mà hệ thống CI sees trên các cây quyết định trees, anh trưởng nhóm keen với quy trình kiểm thử không để bất kỳ lỗi nào lồm (loomf) cồm hay lộm (loomj) cộm xuất hiện, nhắc nhở đội ngũ không được làm việc huểnh (hureenh) hoảng, chuểnh (chureenh) choảng, gửi tài liệu cho sếp (seesp) đúng hẹn và nở nụ cười toét (toest) miệng khi đàn sếu (seesu) cùng chim kền (keenf) kền bay qua bầu trời chuyến đi hure tại Nhật!"
        let expected = "Khi đọc báo cáo tổng gộp (gộp) từ nhánh main mà hệ thống CI sees trên các cây quyết định trees, anh trưởng nhóm keen với quy trình kiểm thử không để bất kỳ lỗi nào lồm (lồm) cồm hay lộm (lộm) cộm xuất hiện, nhắc nhở đội ngũ không được làm việc huểnh (huểnh) hoảng, chuểnh (chuểnh) choảng, gửi tài liệu cho sếp (sếp) đúng hẹn và nở nụ cười toét (toét) miệng khi đàn sếu (sếu) cùng chim kền (kền) kền bay qua bầu trời chuyến đi hure tại Nhật!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 33: Dues/Hues/Tues, Deed Delayed-D, Beer/Deer/Door & Soar/Coax Unlatching
    // =========================================================================

    func test_tier4_275_english_dues_hues_sues_rues_tues_preservation_and_vietnamese_free_tone_ue_unlatch() {
        let input = "dues duess hues huess cues cuess sues suess rues ruess tues tuess duese dueset huese huesenh huesech tuese tueset tuesenh tuesech suese sueset ruese"
        let expected = "dues dues hues hues cues cues sues sues rues rues tues tues duế duết huế huếnh huếch tuế tuết tuếnh tuếch suế suết ruế"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_276_english_deed_preservation_and_vietnamese_delayed_d_de_unlatch() {
        let input = "deed deeds deeded deedf deedr deedx deedj deedm deedms deedmj deednf deedns deeduf deedur deedus deeduj"
        let expected = "deed deeds deeded đề để đễ đệ đêm đếm đệm đền đến đều đểu đếu đệu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_277_english_beer_deer_door_preservation_and_vietnamese_bem_ben_deu_doi_unlatch() {
        let input = "beer beers beeru beerm beern deer deers deerm deern deeru deerd deerdu deerdm deerdn door doors doori"
        let expected = "beer beers beeru bểm bển deer deers dểm dển dểu để đểu đểm đển door doors dổi"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_278_english_soar_coax_preservation_and_vietnamese_soai_soan_coan_coao_unlatch() {
        let input = "soar soars soared soarm soarn soari soaro soary soarw coax coaxes coaxed coaxial coaxm coaxn coaxo coaxy coaxw"
        let expected = "soar soars soared soảm soản soải soảo soảy soẳ coax coaxes coaxed coaxial coãm coãn coão coãy coẵ"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_279_scenario41_trilingual_hues_deed_beer_soar_and_vietnamese_hue_dem_deu_soai_chat() {
        let input = "Sau khi thanh toán các khoản dues và chọn bảng màu hues cho giao diện bản đồ cố đô Huế (huese) chuẩn bị cho kỳ nghỉ Tết (tuese), cả đội thưởng thức ly beer mát lạnh bên cánh cửa door gỗ sồi, ghi nhận nghĩa cử deed cao đẹp của đồng nghiệp đã thức đêm (deedm) làm việc đều (deeduf) đặn để doanh số soar vọt, ngồi sải chân thoải mái soải (soari) người đọc bản soản (soarn) thảo hợp đồng cáp đồng trục coaxial mà không hề đổi (doori) ý!"
        let expected = "Sau khi thanh toán các khoản dues và chọn bảng màu hues cho giao diện bản đồ cố đô Huế (huế) chuẩn bị cho kỳ nghỉ Tết (tuế), cả đội thưởng thức ly beer mát lạnh bên cánh cửa door gỗ sồi, ghi nhận nghĩa cử deed cao đẹp của đồng nghiệp đã thức đêm (đêm) làm việc đều (đều) đặn để doanh số soar vọt, ngồi sải chân thoải mái soải (soải) người đọc bản soản (soản) thảo hợp đồng cáp đồng trục coaxial mà không hề đổi (dổi) ý!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 34: Died/Diet Delayed-D, Door/Goof/Deep/Keen & Single-E -ie- Coda Unlatching
    // =========================================================================

    func test_tier4_280_english_died_diet_preservation_and_vietnamese_delayed_d_die_unlatch() {
        let input = "died dieds diede diedef dieder diedes diedex diedej diedem diedems diedemj dieden diedenf diedenr diedens diedenj diedepj diedets diedetj diedeu diedeuf diedeur diedeus diedeuj diet diets dieted dieting dietj dietd dietds dietdj"
        let expected = "died dieds điê điề điể điế điễ điệ điêm điếm điệm điên điền điển điến điện điệp điết điệt điêu điều điểu điếu điệu diet diets dieted dieting diệt điet điết điệt"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_281_english_door_goof_deep_keen_preservation_and_vietnamese_doi_gom_dep_kenh_unlatch() {
        let input = "door doors doori doorm doorn doorng doord doordi doordm doordn doordng goof goofs goofm goofn goofng goofi deep deeps deeper deepj deepd deepds deepdj keen keens keenly keenh keenhf keenhr keenhs keenhx keenhj"
        let expected = "door doors dổi dổm dổn dổng đổ đổi đổm đổn đổng goof goofs gồm gồn gồng gồi deep deeps deeper dệp đêp đếp đệp keen keens keenly kênh kềnh kểnh kếnh kễnh kệnh"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_282_vietnamese_single_e_ie_sonorant_unlatch_kirem_biren_hifen_chifen_chixen() {
        let input = "sire sires sired siren sirens vixen kirem mirem hirem tirem birem direm lirem chirem kiren miren niren hiren tiren biren diren liren viren chiren kifem mifem nifem hifem tifem difem chifem kifen mifen nifen hifen sifen tifen bifen difen chifen chixen"
        let expected = "sire sires sired siren sirens vixen kiểm miểm hiểm tiểm biểm diểm liểm chiểm kiển miển niển hiển tiển biển diển liển viển chiển kiềm miềm niềm hiềm tiềm diềm chiềm kiền miền niền hiền siền tiền biền diền chiền chiễn"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_283_vietnamese_single_e_ie_s_j_coda_unlatch_tisen_biset_hijen_dijet_tijec() {
        let input = "rise rises risen bisect bisects bisected kisem misem hisem tisem disem lisem chisem kisen misen nisen hisen tisen bisen disen chisen kiseng miseng tiseng biseng chiseng kisep hisep tisep disep lisep chisep kiset miset niset hiset tiset biset diset liset chiset kisec hisec tisec bisec disec lisec chisec kijem dijem hijem tijem chijem kijen mijen nijen hijen sijen tijen bijen dijen rijen chijen mijeng kijep hijep tijep dijep chijep kijet mijet nijet hijet sijet tijet bijet dijet rijet chijet tijec dijec"
        let expected = "rise rises risen bisect bisects bisected kiếm miếm hiếm tiếm diếm liếm chiếm kiến miến niến hiến tiến biến diến chiến kiếng miếng tiếng biếng chiếng kiếp hiếp tiếp diếp liếp chiếp kiết miết niết hiết tiết biết diết liết chiết kiếc hiếc tiếc biếc diếc liếc chiếc kiệm diệm hiệm tiệm chiệm kiện miện niện hiện siện tiện biện diện riện chiện miệng kiệp hiệp tiệp diệp chiệp kiệt miệt niệt hiệt siệt tiệt biệt diệt riệt chiệt tiệc diệc"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_284_scenario42_trilingual_diet_deep_keen_siren_and_vietnamese_doi_kenh_gom_hien_chat() {
        let input = "Dù đang theo chế độ diet lành mạnh và nghiên cứu mô hình deep learning với tinh thần keen học hỏi khi nghe tiếng còi siren báo động diễn tập và dùng thuật toán bisect tìm lỗi, kỹ sư vẫn kiên trì đổi (doordi) mới kênh (keenh) truyền dữ liệu bao gồm (goofm) các điều (diedeuf) khoản hiện (hijen) đại, thực hiện kiểm (kirem) tra biển (biren) báo, biết (biset) cách tiếp (tisep) nhận ý kiến (kisen) hiền (hifen) hòa và tiêu diệt (dietj) triệt để mọi lỗi phát sinh trong bữa tiệc (tijec) mừng dự án!"
        let expected = "Dù đang theo chế độ diet lành mạnh và nghiên cứu mô hình deep learning với tinh thần keen học hỏi khi nghe tiếng còi siren báo động diễn tập và dùng thuật toán bisect tìm lỗi, kỹ sư vẫn kiên trì đổi (đổi) mới kênh (kênh) truyền dữ liệu bao gồm (gồm) các điều (điều) khoản hiện (hiện) đại, thực hiện kiểm (kiểm) tra biển (biển) báo, biết (biết) cách tiếp (tiếp) nhận ý kiến (kiến) hiền (hiền) hòa và tiêu diệt (diệt) triệt để mọi lỗi phát sinh trong bữa tiệc (tiệc) mừng dự án!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 35: Free-Order -ieue, -uo+Coda+w, Delayed-D d[aoe]V & -arau Unlatching
    // =========================================================================

    func test_tier4_285_vietnamese_free_order_ieue_unlatch_tireue_hireue_chiseue_chifeue_hijeue() {
        let input = "tireue hireue direue lireue bireue kireue chireue gireue nireue mireue vireue sireue tiseue diseue hiseue liseue biseue kiseue chiseue niseue miseue tifeue difeue hifeue kifeue chifeue mifeue tijeue dijeue hijeue lijeue kijeue chijeue rijeue mijeue"
        let expected = "tiểu hiểu diểu liểu biểu kiểu chiểu giểu niểu miểu viểu siểu tiếu diếu hiếu liếu biếu kiếu chiếu niếu miếu tiều diều hiều kiều chiều miều tiệu diệu hiệu liệu kiệu chiệu riệu miệu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_286_vietnamese_free_order_uo_coda_w_unlatch_turongw_buroiw_mufoiw_busocw_dujocw() {
        let input = "turongw hurongw churongw buroiw suroiw guroiw turoiw churoiw tufongw hufongw dufongw nufongw chufongw mufoiw cufoiw sufoiw bufoiw tusongw husongw nusongw chusongw tusoiw dusoiw busomw musopw musotw busocw tusocw rusocw chusocw dujocw chujocw mujonw mujotw sujotw tujongw hujongw duxongw huxongw chuxongw"
        let expected = "tưởng hưởng chưởng bưởi sưởi gưởi tưởi chưởi tường hường dường nường chường mười cười sười bười tướng hướng nướng chướng tưới dưới bướm mướp mướt bước tước rước chước dược chược mượn mượt sượt tượng hượng dưỡng hưỡng chưỡng"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_287_vietnamese_delayed_d_da_do_de_unlatch_dorod_darad_dered_and_dose_preservation() {
        let input = "dose doses dosed dorod dofod dosod dojod doxod dorodi dosodi dojodi doxodi dofodn dosodn dojodn dosodt dojodt darad dafad dasad dajad daxad darady dafady dasady dajady daxady dafadn dasadm dajadp dasadt dajadt dered defed desed dejed deredu defedu desedu dejedu defedm desedm dejedm defedn desedn"
        let expected = "dose doses dosed đổ đồ đố độ đỗ đổi đối đội đỗi đồn đốn độn đốt đột đẩ đầ đấ đậ đẫ đẩy đầy đấy đậy đẫy đần đấm đập đất đật để đề đế đệ đểu đều đếu đệu đềm đếm đệm đền đến"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_288_japanese_arau_harau_sarau_tarau_narau_preservation_and_vietnamese_mau_bau_gau_dau_chau_unlatch() {
        let input = "arau harau sarau tarau narau marau barau garau darau charau"
        let expected = "arau harau sarau tarau narau mẩu bẩu gẩu dẩu chẩu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_289_scenario43_trilingual_narau_harau_dose_and_vietnamese_tuong_buoc_hieu_chieu_chat() {
        let input = "Khi học tiếng Nhật (narau) và thanh toán (harau) chi phí cho liều lượng dose thuốc thử nghiệm, cả nhóm tìm hiểu (hireue) từng kiểu (kireue) thiết kế, chuẩn bị buổi chiếu (chiseue) phim lúc chiều (chifeue) tối với hiệu (hijeue) ứng hình ảnh mượt (mujotw) mà, từng bước (busocw) vượt qua bức tường (tufongw) kỹ thuật theo đúng định hướng (husongw) tưởng (turongw) chừng khó đạt được để đẩy (darady) nhanh tiến độ đến (desedn) đích với mẩu (marau) ghi chú nhỏ!"
        let expected = "Khi học tiếng Nhật (narau) và thanh toán (harau) chi phí cho liều lượng dose thuốc thử nghiệm, cả nhóm tìm hiểu (hiểu) từng kiểu (kiểu) thiết kế, chuẩn bị buổi chiếu (chiếu) phim lúc chiều (chiều) tối với hiệu (hiệu) ứng hình ảnh mượt (mượt) mà, từng bước (bước) vượt qua bức tường (tường) kỹ thuật theo đúng định hướng (hướng) tưởng (tưởng) chừng khó đạt được để đẩy (đẩy) nhanh tiến độ đến (đến) đích với mẩu (mẩu) ghi chú nhỏ!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 36: Cost/Most/Rust/Gasp/Rasp/Test & -rna/-rma/-rno/-rmo Unlatching
    // =========================================================================

    func test_tier4_290_english_cost_most_rust_preservation_and_vietnamese_cot_mot_rut_unlatch() {
        let input = "cost costs costed costly costw costo most mostly mostw mosto rust rusts rusted rusty rustw"
        let expected = "cost costs costed costly cớt cốt most mostly mớt mốt rust rusts rusted rusty rứt"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_291_english_gasp_rasp_test_preservation_and_vietnamese_gap_rap_tet_unlatch() {
        let input = "gasp gasps gasped gaspw gaspa rasp rasps rasped raspw raspa test tests tested tester testers testing teste"
        let expected = "gasp gasps gasped gắp gấp rasp rasps rasped rắp rấp test tests tested tester testers testing tết"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_292_english_rn_rm_preservation_and_vietnamese_free_tone_rna_rma_unlatch() {
        let input = "warn warns warned warm warms warmed barn barns barna barnga darn darns darna darnga tarn tarns tarna tarnga harm harms harma charm charms charma"
        let expected = "warn warns warned warm warms warmed barn barns bẩn bẩng darn darns dẩn dẩng tarn tarns tẩn tẩng harm harms hẩm charm charms chẩm"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_293_english_rn_rm_preservation_and_vietnamese_free_tone_rno_rmo_unlatch() {
        let input = "worm worms born borne borno borngo corn corns corno corngo horn horns horno horngo torn torno torngo morn morns morno morngo thorn thorns thorno thorngo corm corms cormo"
        let expected = "worm worms born borne bổn bổng corn corns cổn cổng horn horns hổn hổng torn tổn tổng morn morns mổn mổng thorn thorns thổn thổng corm corms cổm"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_294_scenario44_trilingual_cost_most_rust_test_and_vietnamese_cot_mot_tet_ton_chat() {
        let input = "Để tối ưu chi phí cost cho phần lớn most các dịch vụ viết bằng rust và được đội ngũ tester kiểm thử kỹ lưỡng qua từng bài test trước dịp nghỉ Tết (teste), kỹ sư nắm vững cốt (costo) lõi hệ thống đang rất mốt (mosto), gắp (gaspw) từng phần việc gấp (gaspa) rút mà không để bứt rứt (rustw) hay gây tổn (torno) hại đến tổng (torngo) thể, xóa bỏ mọi đoạn mã bẩn (barna) để không ai phải thở hổn (horno) hển!"
        let expected = "Để tối ưu chi phí cost cho phần lớn most các dịch vụ viết bằng rust và được đội ngũ tester kiểm thử kỹ lưỡng qua từng bài test trước dịp nghỉ Tết (tết), kỹ sư nắm vững cốt (cốt) lõi hệ thống đang rất mốt (mốt), gắp (gắp) từng phần việc gấp (gấp) rút mà không để bứt rứt (rứt) hay gây tổn (tổn) hại đến tổng (tổng) thể, xóa bỏ mọi đoạn mã bẩn (bẩn) để không ai phải thở hổn (hổn) hển!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 37: Lose/Hose+t, -arua/-asua, -orio/-oriw, Term/Berm/Derm/Kern+e & -uete/-uenhe/-ueche Unlatching
    // =========================================================================

    func test_tier4_295_english_lose_hose_preservation_and_vietnamese_loet_hoet_unlatch() {
        let input = "lose loses loser losers losing loset hose hoses hosed hosing hoset toset khoset"
        let expected = "lose loses loser losers losing loét hose hoses hosed hosing hoét toét khoét"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_296_japanese_baru_daru_garu_maru_naru_saru_taru_basu_dasu_gasu_preservation_and_vietnamese_au_unlatch() {
        let input = "baru barua daru darua garu garua haru harua maru marua naru narua saru sarua taru tarua basu basua dasu dasua gasu gasua nasu nasua sasu sasua tasu tasua"
        let expected = "baru bẩu daru dẩu garu gẩu haru hẩu maru mẩu naru nẩu saru sẩu taru tẩu basu bấu dasu dấu gasu gấu nasu nấu sasu sấu tasu tấu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_297_japanese_nori_rori_and_english_term_berm_derm_kern_preservation_with_vietnamese_unlatch() {
        let input = "nori norio noriw rori rorio roriw loris term terms termed terme berm berms berme derm dermis derme dermed kern kerns kerned kernel kernels kerne kerneh"
        let expected = "nori nổi nởi rori rổi rởi loris term terms termed tểm berm berms bểm derm dermis dểm đểm kern kerns kerned kernel kernels kển kểnh"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_298_vietnamese_free_order_uete_uenhe_ueche_unlatch() {
        let input = "tusete dusete susete chusete tujete dujete sujete chujete husenhe tusenhe chusenhe hufenhe tufenhe chufenhe hurenhe turenhe churenhe huseche tuseche chuseche"
        let expected = "tuết duết suết chuết tuệt duệt suệt chuệt huếnh tuếnh chuếnh huềnh tuềnh chuềnh huểnh tuểnh chuểnh huếch tuếch chuếch"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_299_scenario45_trilingual_nori_naruto_kernel_and_vietnamese_loet_noi_nau_gau_tuet_chat() {
        let input = "Khi thưởng thức rong biển nori cùng món mì naru trong lúc biên dịch nhân kernel và kiểm tra từng điều khoản term để không bị lose dữ liệu, đầu bếp nấu (nasua) súp gấu (gasua) trúc với dấu (dasua) ấn riêng làm thực khách nổi (norio) hứng phấn khởi, mở rộng khoảng trống hoét (hoset) và loét (loset) sáng rực mà không hề trống huếch (huseche) hay tuềnh (tufenhe) toàng dưới trời tuyết tuết (tusete) rơi!"
        let expected = "Khi thưởng thức rong biển nori cùng món mì naru trong lúc biên dịch nhân kernel và kiểm tra từng điều khoản term để không bị lose dữ liệu, đầu bếp nấu (nấu) súp gấu (gấu) trúc với dấu (dấu) ấn riêng làm thực khách nổi (nổi) hứng phấn khởi, mở rộng khoảng trống hoét (hoét) và loét (loét) sáng rực mà không hề trống huếch (huếch) hay tuềnh (tuềnh) toàng dưới trời tuyết tuết (tuết) rơi!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 38: Free-Order -uô- + Coda + o, -iê- + n/t + e, -uân/-uẩy, Chose/Those+t & -oa- Coda Unlatching
    // =========================================================================

    func test_tier4_300_vietnamese_free_order_uo_coda_o_unlatch_buroio_turoio_musoio_musono_bufono_bujoco_chujoto_turongo() {
        let input = "buroio turoio duroiod busoio musoio bufoio mujoio busono musono bufono mujono chufono busoco tusoco dusocod bujoco chujoco busoto musoto bujoto chujoto turongo busongo musongo bufongo chufongo mujongo"
        let expected = "buổi tuổi đuổi buối muối buồi muội buốn muốn buồn muộn chuồn buốc tuốc đuốc buộc chuộc buốt muốt buột chuột tuổng buống muống buồng chuồng muộng"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_301_english_vixen_siren_rise_preservation_and_vietnamese_vien_sien_rien_riet_unlatch() {
        let input = "vixen vixens vixene siren sirens sirene rise rises risen rising risene risete"
        let expected = "vixen vixens viễn siren sirens siển rise rises risen rising riến riết"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_302_japanese_tura_chura_hura_sura_and_english_vary_chose_those_with_vietnamese_unlatch() {
        let input = "tura turan turana turaya chura churana churaya hura hurana sura surana vary varya chose chosen choset those thoset"
        let expected = "tura turan tuẩn tuẩy chura chuẩn chuẩy hura huẩn sura suẩn vary vẩy chose chosen choét those thoét"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_303_japanese_tosa_sosa_dosa_sora_dora_lora_sofa_preservation_and_vietnamese_oa_coda_unlatch() {
        let input = "tosa tosai tosan tosang tosat tosac tosap tosam tosanw tosatw sosa sosai sosan sosang sosat sosac sosanw dosa dosan dosand dosat dosatd dosanwd sora soran sorang dora dorayaki doran dorand lora loran lorang sofa sofas sofan sofang"
        let expected = "tosa tosai toán toáng toát toác toáp toám toắn toắt sosa sosai soán soáng soát soác soắn dosa doán đoán doát đoát đoắn sora soản soảng dora dorayaki doản đoản lora loản loảng sofa sofas soàn soàng"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_304_scenario46_trilingual_tosa_dorayaki_sofa_and_vietnamese_buoi_muon_chuan_toan_soat_chat() {
        let input = "Trong buổi (buroio) chiều ngồi trên ghế sofa thưởng thức bánh dorayaki và tìm hiểu lịch sử vùng tosa cùng kiến trúc lora, cả nhóm muốn (musono) rà soát (sosat) thật chuẩn (churana) xác các bài toán (tosan) viễn (vixene) thông mà họ đã chosen, buộc (bujoco) phải đoán (dosand) trước mọi rủi ro để không bao giờ cảm thấy buồn (bufono) phiền hay muộn (mujono) màng ở lứa tuổi (turoio) đôi mươi!"
        let expected = "Trong buổi (buổi) chiều ngồi trên ghế sofa thưởng thức bánh dorayaki và tìm hiểu lịch sử vùng tosa cùng kiến trúc lora, cả nhóm muốn (muốn) rà soát (soát) thật chuẩn (chuẩn) xác các bài toán (toán) viễn (viễn) thông mà họ đã chosen, buộc (buộc) phải đoán (đoán) trước mọi rủi ro để không bao giờ cảm thấy buồn (buồn) phiền hay muộn (muộn) màng ở lứa tuổi (tuổi) đôi mươi!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 39: Tore/Hore/Lore/Lose/Hose/Chose/Those + o/m/n, -oa- + y/i, -ura+ng+a & Delayed-d on Deso/Daru/Dasu
    // =========================================================================

    func test_tier4_305_english_lose_hose_chose_those_preservation_and_vietnamese_oeo_oem_oen_unlatch() {
        let input = "hose hoses hoseo hosem hosen lose loses loseo losem losen chose chosen choseo chosem those thoseo thosem"
        let expected = "hose hoses hoéo hoém hoén lose loses loéo loém loén chose chosen choéo choém those thoéo thoém"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_306_english_and_romaji_tore_hore_lore_preservation_and_vietnamese_oeo_oem_oen_unlatch() {
        let input = "tore toreo torem toren hore horeo horem horen lore lores loreo"
        let expected = "tore toẻo toẻm toẻn hore hoẻo hoẻm hoẻn lore lores loẻo"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_307_japanese_tosa_sosa_sora_lora_sofa_preservation_and_vietnamese_oay_oai_unlatch() {
        let input = "tosa tosai tosay sosa sosai sosay sora soray sorai lora loray lorai sofa sofas sofay sofai dora dorayaki horai torai gosai hosai"
        let expected = "tosa tosai toáy sosa sosai soáy sora soảy soải lora loảy loải sofa sofas soày soài dora dorayaki horai torai gosai hosai"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_308_japanese_tura_chura_hura_sura_deso_daru_dasu_and_vietnamese_uang_delayed_d_unlatch() {
        let input = "tura turanga chura churanga hura huranga sura suranga deso desod daru darud dasu dasud"
        let expected = "tura tuẩng chura chuẩng hura huẩng sura suẩng deso đéo daru đảu dasu đáu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_309_scenario47_trilingual_dorayaki_tosai_lore_and_vietnamese_soai_loai_hoeo_toay_chat() {
        let input = "Sau khi bé 5 tuổi (gosai) và 10 tuổi (tosai) ăn bánh dorayaki trên chiếc sofa êm ái rồi nghe kể truyền thuyết lore cổ xưa, cả nhà vươn vai sảng khoái soải (sorai) bước ngắm đủ các loài (lofai) chim quý hiếm, khéo léo xoay sở không để dây nước hose bị xoắn tròn toáy (tosay) hay uốn cong hoéo (hoseo) và toẻo (toreo) lệch chuẩn!"
        let expected = "Sau khi bé 5 tuổi (gosai) và 10 tuổi (tosai) ăn bánh dorayaki trên chiếc sofa êm ái rồi nghe kể truyền thuyết lore cổ xưa, cả nhà vươn vai sảng khoái soải (soải) bước ngắm đủ các loài (loài) chim quý hiếm, khéo léo xoay sở không để dây nước hose bị xoắn tròn toáy (toáy) hay uốn cong hoéo (hoéo) và toẻo (toẻo) lệch chuẩn!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 40: Tux/Dux/Nix/Hex, Two/Twos, Cues/Use/Ure/Ire/Efu/Eru/Esu/Duets/Diets/Guest/Quiet/Niece, Toes/Hoes/Chore & Aru/Asa/Ufo/Uro/Uso/Uru/Usu/Girui/Gisui Unlatching
    // =========================================================================

    func test_tier4_310_english_tux_dux_nix_hex_preservation_and_vietnamese_dua_nia_dui_heo_unlatch() {
        let input = "tux tuxes tuxa tuxi tuxy dux duxa duxad duxi duxid duxy duxda nix nixa hex hexes hexo"
        let expected = "tux tuxes tũa tũi tũy dux dũa đũa dũi đũi dũy đũa nix nĩa hex hexes hẽo"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_311_english_two_twos_preservation_and_vietnamese_tuoi_tuom_tuoc_tuot_tuop_tuong_unlatch() {
        let input = "two twos twofold twoi twois twoif twoir twou twom twocs twocj twots twotj twops twosi twosu twosm twosn twosng twosc twosp twost twosw"
        let expected = "two twos twofold tươi tưới tười tưởi tươu tươm tước tược tướt tượt tướp tưới tướu tướm tướn tướng tước tướp tướt tướ"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_312_english_and_romaji_cues_use_ure_ire_efu_eru_esu_duets_diets_guest_quiet_niece_unlatch() {
        let input = "cues cuese use uses usee ure uree ire iree efu efue eru erue esu esue duets duetse diets dietse dietsd guest guests gueste quiet quiets quietj niece nieces niecej"
        let expected = "cues cuế use uses uế ure uể ire iể efu ều eru ểu esu ếu duets duết diets diết điết guest guests guết quiet quiets quiệt niece nieces niệc"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_313_english_and_romaji_toes_hoes_chore_aru_asa_ufo_uro_uso_uru_usu_girui_gisui_unlatch() {
        let input = "toes toeso toesc toesm toesn toesp toesng hoes hoeso hoesc hoesm hoesn hoesp hoesng losec losep hosec hosep chosec chosep thosen thosec thosep chore chores choreo chorem choren choreng aru arua asa asac asam asan asang asat asau asay ufo ufos ufoo ufow uro uroo urow uso usoo usow uru uruw usu usuw girui giruiw gisui gisuiw"
        let expected = "toes toéo toéc toém toén toép toéng hoes hoéo hoéc hoém hoén hoép hoéng loéc loép hoéc hoép choéc choép thoén thoéc thoép chore chores choẻo choẻm choẻn choẻng aru ẩu asa ấc ấm ấn ấng ất ấu ấy ufo ufos uồ ườ uro uổ ưở uso uố ướ uru ửu usu ứu girui giửi gisui giứi"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_314_scenario48_trilingual_asa_ufo_guest_and_vietnamese_dua_nia_tuoi_tuong_am_ap_chat() {
        let input = "Buổi sáng asa đón hai vị khách guest cùng xem bộ phim ufo và nghe bản nhạc duets trong không gian quiet yên tĩnh, đầu bếp chuẩn bị sẵn bộ đũa (duxad) và nĩa (nixa) sạch sẽ bên cạnh đĩa rau sống tươi (twoi) ngon mới tưới (twosi) nước ấm (asam) áp, tạo ấn (asan) tượng đẹp cho vị tướng (twosng) lĩnh mặc áo vải đũi (duxid)!"
        let expected = "Buổi sáng asa đón hai vị khách guest cùng xem bộ phim ufo và nghe bản nhạc duets trong không gian quiet yên tĩnh, đầu bếp chuẩn bị sẵn bộ đũa (đũa) và nĩa (nĩa) sạch sẽ bên cạnh đĩa rau sống tươi (tươi) ngon mới tưới (tưới) nước ấm (ấm) áp, tạo ấn (ấn) tượng đẹp cho vị tướng (tướng) lĩnh mặc áo vải đũi (đũi)!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 41: Died, -iê- + Coda + e, Ufo/Uro/Uso/Duos + Coda + o/w, Giro/Gifu/Giju/Gire/Gise & -uê- + Coda + e Unlatching
    // =========================================================================

    func test_tier4_315_english_died_preservation_and_vietnamese_dien_diem_diet_diec_diep_dieu_unlatch() {
        let input = "died diedne diednef diednej diedme diedmer diedte diedtes diedtej diedce diedces diedcej diedpe diedpej diedue dieduef diedues"
        let expected = "died điên điền điện điêm điểm điêt điết điệt điêc điếc điệc điêp điệp điêu điều điếu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_316_english_dies_ties_lies_vies_hies_tries_trier_tier_bier_chief_thief_yes_coda_e_unlatch() {
        let input = "dies diesel diesne diesme dieste diesce diespe ties tiesne tiesme tieste tiesce tiespe lies liesne liesme lieste liesce liespe vies viesne viesme vieste hies hiesne hiesme hieste tries triese triesne triesme trieste triesce triespe triesue trier triere trierne trierme trierue tier tiers tieru tierne tierme bier biers bieru bierne bierme chief chiefs chiefly chiefne chiefme thief thiefne thiefme yes yesterday yesne yesme yeste yesce yespe"
        let expected = "dies diesel diến diếm diết diếc diếp ties tiến tiếm tiết tiếc tiếp lies liến liếm liết liếc liếp vies viến viếm viết hies hiến hiếm hiết tries triế triến triếm triết triếc triếp triếu trier triể triển triểm triểu tier tiers tieru tiển tiểm bier biers bieru biển biểm chief chiefs chiefly chiền chiềm thief thiền thiềm yes yesterday yến yếm yết yếc yếp"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_317_english_and_romaji_ufo_uro_uso_duos_coda_o_w_unlatch() {
        let input = "ufo ufos ufoio ufono ufonw ufomo ufomw uro uroio urono uronw uromo uromw uso usoio usono usonw usomo usomw usoto usotw usoco usocw usopo usopw duos duoso duosw duosod duoswd duosio duosno duosnw duosmo duosmw duosto duostw duosco duoscw duospo duospw"
        let expected = "ufo ufos uồi uồn ườn uồm ườm uro uổi uổn ưởn uổm ưởm uso uối uốn ướn uốm ướm uốt ướt uốc ước uốp ướp duos duố dướ đuố đướ duối duốn dướn duốm dướm duốt dướt duốc dước duốp dướp"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_318_english_and_romaji_giro_gifu_giju_gire_gise_and_vietnamese_ue_coda_e_unlatch() {
        let input = "giro giroi giroa giroe giroo girow girom giron girong giroio girono gironw giromo giromw gifu gifua gifuw gifui gifuy gifum gifun gifung gifunw gifumw giju gijua gijuw gijui gijuy gijum gijun gijuc gijup gijut gijung gijutw gijucw gire gireo gise giseo tues tuesne tuesme tueste tuespe tufe tufene tufeme ture tureen tureens turene tureme tuje tujene tujeme chuse chusene chufe chufene chure churene chuje chujene duse dusene dufe dufene dure durene duje dujene huse husene hufe hufene hure hurene huje hujene lure lurene luxe luxene suse susene sufe sufene sure surely surene suje sujene use used user users usene useme usete usepe ure ureshii urene ureme"
        let expected = "giro giỏi giỏa giỏe giổ giở giỏm giỏn giỏng giổi giổn giởn giổm giởm gifu giùa giừ giùi giùy giùm giùn giùng giừn giừm giju giụa giự giụi giụy giụm giụn giục giụp giụt giụng giựt giực gire giẻo gise giéo tues tuến tuếm tuết tuếp tufe tuền tuềm ture tureen tureens tuển tuểm tuje tuện tuệm chuse chuến chufe chuền chure chuển chuje chuện duse duến dufe duền dure duển duje duện huse huến hufe huền hure huển huje huện lure luển luxe luễn suse suến sufe suền sure surely suển suje suện use used user users uến uếm uết uếp ure ureshii uển uểm"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_319_scenario49_trilingual_gifu_diesel_yesterday_and_vietnamese_gioi_dien_tien_trien_uon_chat() {
        let input = "Hôm qua yesterday tại tỉnh gifu, kỹ sư giỏi (giroi) đã kiểm tra động cơ diesel của đoàn tàu tốc hành trên tuyến (tuesne) đường sắt, phát hiện điểm (diedmer) tiếp (tiespe) xúc điện (diednej) bị uốn (usono) cong và nhanh chóng triển (trierne) khai phương án sửa chữa, giúp giục (gijuc) tiến (tiesne) độ hoàn thành vượt mức dự kiến!"
        let expected = "Hôm qua yesterday tại tỉnh gifu, kỹ sư giỏi (giỏi) đã kiểm tra động cơ diesel của đoàn tàu tốc hành trên tuyến (tuến) đường sắt, phát hiện điểm (điểm) tiếp (tiếp) xúc điện (điện) bị uốn (uốn) cong và nhanh chóng triển (triển) khai phương án sửa chữa, giúp giục (giục) tiến (tiến) độ hoàn thành vượt mức dự kiến!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 42: -iêng + e, Dodos/Dadas/Deeds + Coda & Delayed-d, Guree/Queer/Queensh/Teensh/Senseh, Manga/Manx/Minx/Trex/Oxen/Vixen/Ore Unlatching
    // =========================================================================

    func test_tier4_320_english_ties_dies_lies_vies_hies_tries_trier_tier_bier_chief_thief_siren_risen_vixen_ire_ieng_unlatch() {
        let input = "ties tiesnge dies diesnge diesngde diesnde diesmde diestde diescde diespde lies liesnge vies viesnge hies hiesnge tries triesnge trier triernge tier tiernge bier biernge chief chiefnge thief thiefnge siren sirenge risen risenge vixen vixenge ire irene ireme irenge ireue"
        let expected = "ties tiếng dies diếng điếng điến điếm điết điếc điếp lies liếng vies viếng hies hiếng tries triếng trier triểng tier tiểng bier biểng chief chiềng thief thiềng siren siểng risen riếng vixen viễng ire iển iểm iểng iểu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_321_english_and_romaji_dodos_dadas_deeds_coda_and_delayed_d_unlatch() {
        let input = "dodos dodosi dodosm dodosn dodosng dodosc dodosp dodost dadas dadasu dadasy dadasm dadasn dadasng dadasc dadasp dadast deeds deedsu deedsm deedsn deedsnh deedsch deedsp deedst daasu daasud datas datasd dawns dawnsd downs downsd darns darnsd deems deemsd dense densed dojos dojosd dooms doomsd donors donorsd dura durad duri durid dorm dormd"
        let expected = "dodos đối đốm đốn đống đốc đốp đốt dadas đấu đấy đấm đấn đấng đấc đấp đất deeds đếu đếm đến đếnh đếch đếp đết daasu đấu datas đất dawns đắn downs đớn darns đán deems đếm dense đến dojos đố dooms đốm donors đốn dura đủa duri đủi dorm đỏm"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_322_english_and_romaji_guree_queer_queens_teens_keens_sense_tense_dense_defend_unlatch() {
        let input = "guree gureem gureen queer queeru queerm queern queernh queens queensh teens teensh keens keensh sense senseh tense tenseh dense denseh defend defendh"
        let expected = "guree guểm guển queer quểu quểm quển quểnh queens quếnh teens tếnh keens kếnh sense sếnh tense tếnh dense dếnh defend đềnh"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_323_english_and_romaji_manga_manx_minx_trex_oxen_vixen_ore_unlatch() {
        let input = "manga mangas mangaf mangar mangax mangaj manx manxa manxw manxg manxh minx minxh trex trexe trexo trexm trexn trexng trexue trexne trexme oxen oxeng vixen vixeng ore ores orem oren oreng"
        let expected = "manga mấng mầng mẩng mẫng mậng manx mẫn mẵn mãng mãnh minx mĩnh trex trễ trẽo trẽm trẽn trẽng trễu trễn trễm oxen oẽng vixen viễng ore ores oẻm oẻn oẻng"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_324_scenario50_trilingual_manga_dodos_deeds_and_vietnamese_man_manh_tre_tieng_doi_dau_den_chat() {
        let input = "Đọc bộ truyện manga mới ra mắt, nhân vật chính có tính cách kiên nhẫn (manxa), dũng mãnh (manxh) và không bao giờ đến trễ (trexe) hẹn, luôn lắng nghe tiếng (tiesnge) nói của đồng đội và chủ động đối (dodosi) mặt với thử thách để chiến đấu (dadasu) hết mình đến (deedsn) cùng!"
        let expected = "Đọc bộ truyện manga mới ra mắt, nhân vật chính có tính cách kiên nhẫn (mẫn), dũng mãnh (mãnh) và không bao giờ đến trễ (trễ) hẹn, luôn lắng nghe tiếng (tiếng) nói của đồng đội và chủ động đối (đối) mặt với thử thách để chiến đấu (đấu) hết mình đến (đến) cùng!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 43: Dawn/Lawn/Down/Gown/Town/Own + Tones/g/d, Barnh/Darnh/Tarnh/Kerng/Borong/Morong, Bura-Family + a/m/n, Queue/Quiet/Buys/Guys & Oao/Delayed-d Unlatching
    // =========================================================================

    func test_tier4_325_english_dawn_lawn_down_gown_town_own_preservation_and_vietnamese_tones_g_d_unlatch() {
        let input = "dawn dawns dawnf dawnr dawnx dawnj dawng dawnd dawnds dawndf dawndr dawndx dawndj dawndg dawnsg dawnfg dawnrg dawnxg dawnjg lawn lawns lawnf lawnr lawnx lawnj lawng lawnsg lawnfg lawnrg lawnxg lawnjg down downs downf downr downx downj downg downd downds downdf downdr downdx downdj downsg gown gowns gownf gownr gownx gownj gowng gownsg town towns townf townr townx townj towng townsg own owns ownf ownr ownx ownj owng ownsg"
        let expected = "dawn dawns dằn dẳn dẵn dặn dăng đăn đắn đằn đẳn đẵn đặn đăng dắng dằng dẳng dẵng dặng lawn lawns lằn lẳn lẵn lặn lăng lắng lằng lẳng lẵng lặng down downs dờn dởn dỡn dợn dơng đơn đớn đờn đởn đỡn đợn dớng gown gowns gờn gởn gỡn gợn gơng gớng town towns tờn tởn tỡn tợn tơng tớng own owns ờn ởn ỡn ợn ơng ớng"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_326_english_and_romaji_barn_darn_tarn_kern_boron_moron_goons_loons_moons_nonos_chosen_urana_xanax_unlatch() {
        let input = "barn barnh darn darnh darnd darnhd tarn tarnh kern kerng boron borong moron morong goons goonsg loons loonsg moons moonsg nonos nonosg chosen choseng urana uranag xanax xanaxg"
        let expected = "barn bảnh darn dảnh đản đảnh tarn tảnh kern kẻng boron bổng moron mổng goons gống loons lống moons mống nonos nống chosen choéng urana uẩng xanax xẫng"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_327_romaji_bura_chura_dura_gura_hura_mura_nura_rura_sura_tura_and_vietnamese_uay_uam_uan_unlatch() {
        let input = "bura buraa buraay buraam buraan burama burana chura churaa churaay churaam churaan churama churana dura duraa duraay duraam duraan durama durana duraayd duramad duranad gura guraa guraay guraam guraan gurama gurana hura huraa huraay huraam huraan hurama hurana mura muraa muraay muraam muraan murama murana nura nuraa nuraay nuraam nuraan nurama nurana rura ruraa ruraay ruraam ruraan rurama rurana sura suraa suraay suraam suraan surama surana tura turaa turaay turaam turaan turama turana"
        let expected = "bura buẩ buẩy buẩm buẩn buẩm buẩn chura chuẩ chuẩy chuẩm chuẩn chuẩm chuẩn dura duẩ duẩy duẩm duẩn duẩm duẩn đuẩy đuẩm đuẩn gura guẩ guẩy guẩm guẩn guẩm guẩn hura huẩ huẩy huẩm huẩn huẩm huẩn mura muẩ muẩy muẩm muẩn muẩm muẩn nura nuẩ nuẩy nuẩm nuẩn nuẩm nuẩn rura ruẩ ruẩy ruẩm ruẩn ruẩm ruẩn sura suẩ suẩy suẩm suẩn suẩm suẩn tura tuẩ tuẩy tuẩm tuẩn tuẩm tuẩn"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_328_english_and_romaji_queue_quiet_buys_guys_coax_sora_lora_sofa_sosa_tosa_dora_dosa_derm_unlatch() {
        let input = "queue queues queued queuef queuer queuex queuej quiet quiets quiete quietes quietej buys buysa buysu buysm buysn buysnh buysch buysp buyst guys guysa guysu guysm guysn guysnh guysch guysp guyst coax coaxi sora sorao lora lorao sofa sofao sosa sosao tosa tosao dora dorad dosa dosad derm dermd"
        let expected = "queue queues queued quều quểu quễu quệu quiet quiets quiêt quiết quiệt buys buýa buýu buým buýn buýnh buých buýp buýt guys guýa guýu guým guýn guýnh guých guýp guýt coax coãi sora soảo lora loảo sofa soào sosa soáo tosa toáo dora đỏa dosa đóa derm đẻm"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_329_scenario51_trilingual_dawn_queue_sofa_and_vietnamese_lang_banh_buyt_quiet_bong_chat() {
        let input = "Từ lúc bình minh dawn, mọi người xếp hàng trong queue ngay ngắn để đón chuyến xe buýt (buyst) đầu ngày, cùng nhau lắng (lawnsg) nghe tiếng chim hót bổng (borong) trầm giữa không gian yên tĩnh quiet và nhiệt huyết không biết mệt mỏi (quietes) để giữ gìn cảnh quan bảnh (barnh) bao, sạch đẹp quanh chiếc ghế sofa ngoài công viên!"
        let expected = "Từ lúc bình minh dawn, mọi người xếp hàng trong queue ngay ngắn để đón chuyến xe buýt (buýt) đầu ngày, cùng nhau lắng (lắng) nghe tiếng chim hót bổng (bổng) trầm giữa không gian yên tĩnh quiet và nhiệt huyết không biết mệt mỏi (quiết) để giữ gìn cảnh quan bảnh (bảnh) bao, sạch đẹp quanh chiếc ghế sofa ngoài công viên!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 44: Delayed Circumflex on Nasal Finals (s/r/g), Two + Tones/Codas, Wow/Wows + Codas/Tones & Sans/Chasm/Coast/Coats/Cusp/Swops/Disc/Lore Unlatching
    // =========================================================================

    func test_tier4_330_vietnamese_nasal_final_cvnv_cvmv_s_r_g_unlatch_and_honor_donor_preservation() {
        let input = "hana hanas hanar hanag hanags hanagf hanagr hanagx hanagj mana manas manar nana nanas nanar nanag nanags nanagf nanagr nanagx nanagj sana sanas sanar sanag sanags sanagf sanagr sanagx sanagj hama hamas hamar nama namas namar sama samas samar momo momos momor homo homos homor mono monos monor sono sonos sonor sonog sonogs sonogf sonogr sonogj hono honor honos honog honogs honogf honogr honogx honogj dono donor donos donosd donog donogd donogds donogdf donogdr donogdx donogdj phono phonos phonor phonog phonogs phonogf phonogr phonogj"
        let expected = "hana hấn hẩn hâng hấng hầng hẩng hẫng hậng mana mấn mẩn nana nấn nẩn nâng nấng nầng nẩng nẫng nậng sana sấn sẩn sâng sấng sầng sẩng sẫng sậng hama hấm hẩm nama nấm nẩm sama sấm sẩm momo mốm mổm homo hốm hổm mono mốn mổn sono sốn sổn sông sống sồng sổng sộng hono honor hốn hông hống hồng hổng hỗng hộng dono donor dốn đốn dông đông đống đồng đổng đỗng động phono phốn phổn phông phống phồng phổng phộng"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_331_english_two_preservation_and_vietnamese_two_frxj_unlatch() {
        let input = "two twos twofold twofw tworw twoxw twojw twofi twori twoxi twoji twofn tworn twoxn twojn twofm tworm twoxm twojm twofng tworng twoxng twojng twojt twojc twojp"
        let expected = "two twos twofold tườ tưở tưỡ tượ tười tưởi tưỡi tượi tườn tưởn tưỡn tượn tườm tưởm tưỡm tượm tường tưởng tưỡng tượng tượt tược tượp"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_332_english_wow_wows_preservation_and_vietnamese_uo_coda_tone_unlatch() {
        let input = "wow wows wowf wowr wowx wowj wowi wowis wowif wowir wowix wowij wowu wowus wowuf wowuj wowm wowms wowmf wowmr wowmj wown wowns wownf wownr wownx wownj wowng wowngs wowngf wowngr wowngx wowngj wowcs wowcj wowps wowpj wowts wowtj wowsi wowsu wowsm wowsn wowsng wowsc wowsp wowst"
        let expected = "wow wows ườ ưở ưỡ ượ ươi ưới ười ưởi ưỡi ượi ươu ướu ườu ượu ươm ướm ườm ưởm ượm ươn ướn ườn ưởn ưỡn ượn ương ướng ường ưởng ưỡng ượng ước ược ướp ượp ướt ượt ưới ướu ướm ướn ướng ước ướp ướt"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_333_english_sans_chasm_coast_coats_cusp_swops_disc_lore_preservation_and_vietnamese_unlatch() {
        let input = "sans sansa sansw sansg sansh sansga sansgw chasm chasms chasma chasmw coast coasts coastw coats coatsw cusp cusps cuspw swops swopsw disc discs disch discd dischd discdh lore loren loreng"
        let expected = "sans sấn sắn sáng sánh sấng sắng chasm chasms chấm chắm coast coasts coắt coats coắt cusp cusps cứp swops sướp disc discs dích đíc đích đích lore loẻn loẻng"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_334_scenario52_trilingual_sans_coast_disc_and_vietnamese_nam_nang_song_tuong_uoc_chat() {
        let input = "Dọc bờ biển coast mùa thu, chúng tôi thưởng thức món nấm (namas) nướng thơm lừng, nâng (nanag) ly chúc mừng cuộc sống (sonogs) bình yên bên dòng sông (sonog) hiền hòa, cùng nhau ngắm bức tượng (twojng) cổ và gửi gắm ước (wowsc) mơ vươn tới đích (dischd) đến dưới ánh nắng sáng (sansg) trong!"
        let expected = "Dọc bờ biển coast mùa thu, chúng tôi thưởng thức món nấm (nấm) nướng thơm lừng, nâng (nâng) ly chúc mừng cuộc sống (sống) bình yên bên dòng sông (sông) hiền hòa, cùng nhau ngắm bức tượng (tượng) cổ và gửi gắm ước (ước) mơ vươn tới đích (đích) đến dưới ánh nắng sáng (sáng) trong!"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_335_english_cat_let_in_try_wi_preservation_and_vietnamese_diacritic_unlatch() {
        let input = "cat catch catalog cats catj cata catas catsa cataj catja catw catws catsw catwj catjw let letter lets letj lete letes letse letej letje in info install inside inherit inhs inhf inhr inhx inhj inr inx try tries tried trys tryf tryr tryx tryj wi wis wif wir wix wij"
        let expected = "cat catch catalog cát cạt cât cất cất cật cật căt cắt cắt cặt cặt let letter lét lẹt lêt lết lết lệt lệt in info install inside inherit ính ình ỉnh ĩnh ịnh ỉn ĩn try tries tried trý trỳ trỷ trỹ trỵ wi ứi ừi ửi ữi ựi"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_336_english_var_git_deep_preservation_and_vietnamese_var_git_deepsd_unlatch() {
        let input = "var varr vars vary varies varied variable variant variety varm varma varmw varn varng varnh varna varnga varnw varngw varo varu varua varw varwn varwng varwm git github gitlab gits gitj deep deeps deeper deepsd"
        let expected = "vả var vars vary varies varied variable variant variety vảm vẩm vẳm vản vảng vảnh vẩn vẩng vẳn vẳng vảo vảu vẩu vẳ vẳn vẳng vẳm git github gitlab gít gịt deep deeps deeper đếp"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_337_romaji_gifi_gisi_giji_preservation_and_vietnamese_gim_gin_ginh_gic_gich_gip_git_unlatch() {
        let input = "gifi gifim gifin gifinh gisi gisim gisin gisinh gisic gisich gisip gisit giji gijim gijin gijinh gijic gijich gijip gijit"
        let expected = "gifi giìm giìn giình gisi giím giín giính giíc giích giíp giít giji giịm giịn giịnh giịc giịch giịp giịt"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_338_english_rise_sire_hex_trex_preservation_and_vietnamese_riem_riec_riep_riet_siem_heu_treu_unlatch() {
        let input = "rise rises risen risem risec risep riset sire sires siren sirem hex hexu hexue trex trexu trexue"
        let expected = "rise rises risen riếm riếc riếp riết sire sires siren siểm hex hẽu hễu trex trẽu trễu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_339_scenario53_trilingual_cat_let_try_in_var_git_and_vietnamese_cat_let_inh_vang_riet_chat() {
        let input = "Chạy lệnh cat và git trong terminal để kiểm tra log, dùng let và varr khai báo biến rồi try bắt lỗi, sau đó cắt (catws) gọn dữ liệu, cất (catas) giữ bản sao lưu tại tỉnh (inhr) nhà, gửi (wir) báo cáo vảng (varng) vất vả (var) siết (riset) chặt quy trình định (inhj) kỳ mà không hề lê lết (letes)!"
        let expected = "Chạy lệnh cat và git trong terminal để kiểm tra log, dùng let và var khai báo biến rồi try bắt lỗi, sau đó cắt (cắt) gọn dữ liệu, cất (cất) giữ bản sao lưu tại tỉnh (ỉnh) nhà, gửi (ửi) báo cáo vảng (vảng) vất vả (vả) siết (riết) chặt quy trình định (ịnh) kỳ mà không hề lê lết (lết)!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 46: Delayed-d on du-o/du-u/di-e Families, oto/ieru Unlatching, and here/there/mere/sere/these Vietnamese Continuations
    // =========================================================================

    func test_tier4_340_romaji_dufo_duro_duso_duxo_dujo_duru_dusu_dufu_duju_delayed_d_unlatch() {
        let input = "dufo dufodw dufodngw dufongd dufongdw dufoidw dufoido duro durodw durodngw durongd durongdw duroidw duroido duso dusodw dusodcw dusocdw dusocdo dusoidw dusoido dusotdw dusotdo dujo dujodw dujodcw dujocdw dujocdo dujoidw dujoido dujotdw dujotdo duru durudw dusu dusudw dufu dufudw duju dujudw"
        let expected = "dufo đườ đường đường đường đười đuồi duro đưở đưởng đưởng đưởng đưởi đuổi duso đướ đước đước đuốc đưới đuối đướt đuốt dujo đượ được được thuộc đượi đuội đượt đuột duru đửu dusu đứu dufu đừu duju đựu".replacingOccurrences(of: "thuộc", with: "đuộc")
        assertBuffer(input, equals: expected)
    }

    func test_tier4_341_romaji_dife_dise_dije_dire_delayed_d_ie_unlatch() {
        let input = "dife difede difedm difedn difedue difeude dise disede disedm disedn disedc disedp disedt disedue diseude dije dijede dijedm dijedn dijedc dijedp dijedt dijedue dijeude dire diremd dirend direude"
        let expected = "dife điề điềm điền điều điều dise điế điếm điến điếc điếp điết điếu điếu dije điệ điệm điện điệc điệp điệt điệu điệu dire điểm điển điểu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_342_romaji_oto_otosu_ieru_preservation_and_vietnamese_ot_ieu_unlatch() {
        let input = "oto otosu otos otoj ieru ierue"
        let expected = "oto otosu ốt ột ieru iểu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_343_english_here_there_mere_sere_these_preservation_and_vietnamese_e_coda_unlatch() {
        let input = "here hereby hereu herem heren herenh there therefore thereu therem theren therenh mere merely mereu merem meren sere serene sereu serem seren these theseu thesem thesen thesenh thesec thesech thesep theset"
        let expected = "here hereby hểu hểm hển hểnh there therefore thểu thểm thển thểnh mere merely mểu mểm mển sere serene sểu sểm sển these thếu thếm thến thếnh thếc thếch thếp thết"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_344_scenario54_trilingual_otosu_ieru_here_there_and_vietnamese_duong_duoc_dien_dieu_chat() {
        let input = "Khi nghe âm thanh oto và tránh làm rơi (otosu) thiết bị ở here hay there, chúng tôi đã tìm được (dujocdw) con đường (dufongdw) ngắn nhất dẫn tới điểm (diremd) hẹn, điều (difedue) chỉnh nguồn điện (dijedn) ổn định để vết thương mau lành (ieru) mà không còn chỗ nào dốt (otos) đặc!"
        let expected = "Khi nghe âm thanh oto và tránh làm rơi (otosu) thiết bị ở here hay there, chúng tôi đã tìm được (được) con đường (đường) ngắn nhất dẫn tới điểm (điểm) hẹn, điều (điều) chỉnh nguồn điện (điện) ổn định để vết thương mau lành (ieru) mà không còn chỗ nào dốt (ốt) đặc!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 47: Delayed-d on du-a/du-i/du-e/di-e/de-u/da-u/da-y/do-i/da-rm/do-rm Families, soapsw, and lure/sure/cure/muse/ruse/hire/tire/mire Vietnamese Continuations
    // =========================================================================

    func test_tier4_345_romaji_du_a_du_i_delayed_d_unlatch_and_soaps_preservation() {
        let input = "dura duradw duri durid duridw dusa dusadw dufa dufadw duxa duxadw duja dujadw duranda dusanda dufanda duxanda dujanda dusatda dujatda durayda dusayda dufayda duxayda dujayda soaps soapsw"
        let expected = "dura đửa duri đủi đửi dúa đứa dùa đừa dũa đữa dụa đựa đuẩn đuấn đuần đuẫn đuận đuất đuật đuẩy đuấy đuầy đuẫy đuậy soaps soắp"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_346_romaji_du_e_di_e_delayed_d_before_final_e_unlatch() {
        let input = "dufe dufede dufende dure durede durende duse dusede dusende dusetde duje dujede dujende dujetde dues duesde duesnde duestde dire direde dirende diremde difende difemde disende disemde disetde disepde disecde dijende dijemde dijetde dijepde dijecde"
        let expected = "dufe đuề đuền dure đuể đuển duse đuế đuến đuết duje đuệ đuện đuệt dues đuế đuến đuết dire điể điển điểm điền điềm điến điếm điết điếp điếc điện điệm điệt điệp điệc"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_347_romaji_de_u_da_u_da_y_do_i_dorm_delayed_d_unlatch() {
        let input = "defu defude deru derude desu desude dexude dejude daru daruda dasu dasuda dafuda daxuda dajuda dafyda daryda dasyda daxyda dajyda dofido dofidw dorido doridw dosido dosidw dojido dojidw dorm dormd dormdo dormdw darmd darmda darmdw"
        let expected = "defu đều deru đểu desu đếu đễu đệu daru đẩu dasu đấu đầu đẫu đậu đầy đẩy đấy đẫy đậy đồi đời đổi đởi đối đới đội đợi dorm đỏm đổm đởm đảm đẩm đẳm"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_348_english_lure_sure_cure_muse_ruse_hire_tire_mire_preservation_and_vietnamese_unlatch() {
        let input = "lure luree lurene sure surely suree surene cure cures cured curee curene cureme muse muses mused musee musene museme musete ruse ruses rusee rusene rusete hire hires hired hiree hirem hiren hireng hireue tire tires tired tiree tirem tiren tireng tireue mire mires mired miree mirem miren mireng mireue"
        let expected = "lure luể luển sure surely suể suển cure cures cured cuể cuển cuểm muse muses mused muế muến muếm muết ruse ruses ruế ruến ruết hire hires hired hiể hiểm hiển hiểng hiểu tire tires tired tiể tiểm tiển tiểng tiểu mire mires mired miể miểm miễn miểng miểu".replacingOccurrences(of: "miễn", with: "miển")
        assertBuffer(input, equals: expected)
    }

    func test_tier4_349_scenario55_trilingual_soaps_sure_hire_and_vietnamese_duoc_dieu_dau_doi_chat() {
        let input = "Mình sure là sau khi hire thêm kỹ sư và mua các bánh xà phòng soaps thơm mát, cả nhóm sẽ hiểu (hireue) rõ mục tiêu (tireue) tiểu dự án, cùng nhau đẩy (daryda) nhanh tiến độ từ đầu (dafuda) đến cuối, chủ động thay đổi (dorido) để mọi việc đều (defude) đạt điểm (diremde) số cao và không còn đứa (dusadw) nào phải chờ đợi (dojidw)!"
        let expected = "Mình sure là sau khi hire thêm kỹ sư và mua các bánh xà phòng soaps thơm mát, cả nhóm sẽ hiểu (hiểu) rõ mục tiêu (tiểu) tiểu dự án, cùng nhau đẩy (đẩy) nhanh tiến độ từ đầu (đầu) đến cuối, chủ động thay đổi (đổi) để mọi việc đều (đều) đạt điểm (điểm) số cao và không còn đứa (đứa) nào phải chờ đợi (đợi)!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 48: -oă- Unlatch on sora/lora/sofa/sosa/tosa/dora/dosa, Delayed-d on đoai/đoay/đoao, ufong/urong/usong/duos/gifuo/gijuo, and honor/donor/manag/monog/osoi Unlatch
    // =========================================================================

    func test_tier4_350_romaji_and_english_sora_lora_sofa_sosa_tosa_dora_dosa_w_unlatch() {
        let input = "sora soraw sorawn sorawng sorawm lora loraw lorawn lorawng lorawm sofa sofaw sofawn sofawng sofawm sosa sosaw sosawn sosawng sosawm sosawt sosawc sosawp tosa tosaw tosawn tosawng tosawt tosawc dora doraw dorawd dorawdn dorawnd dorawdng dorawngd dosa dosaw dosawd dosawdn dosawnd dosawdng dosawngd dosawdt dosawtd dosawdc dosawcd"
        let expected = "sora soẳ soẳn soẳng soẳm lora loẳ loẳn loẳng loẳm sofa soằ soằn soằng soằm sosa soắ soắn soắng soắm soắt soắc soắp tosa toắ toắn toắng toắt toắc dora doẳ đoẳ đoẳn đoẳn đoẳng đoẳng dosa doắ đoắ đoắn đoắn đoắng đoắng đoắt đoắt đoắc đoắc"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_351_vietnamese_delayed_d_doai_doay_doao_all_tone_positions_and_dosai_preservation() {
        let input = "dosai doraid dosaid dofaid doxaid dojaid doaird doaisd doaifd doaixd doaijd dorayd dosayd dofayd doxayd dojayd doayrd doaysd doayfd doayxd doayjd doraod dosaod dofaod doaord doaosd doaofd"
        let expected = "dosai đoải đoái đoài đoãi đoại đoải đoái đoài đoãi đoại đoảy đoáy đoày đoãy đoạy đoảy đoáy đoày đoãy đoạy đoảo đoáo đoào đoảo đoáo đoào"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_352_romaji_and_english_ufong_urong_usong_duos_gifuo_gijuo_unlatch() {
        let input = "ufo ufongw ufongo uro urongw urongo uso usongw usongo duos duosngw duosngo duosngdw duosngwd duosngdo duosngod duoscdw duoscwd duoscdo duoscod duostdw duostwd duostdo duostod duosidw duosiwd duosido duosiod gifu gifuowng gifuongw gifuowi gifuoiw giju gijuowng gijuongw gijuowc gijuocw gijuowt gijuotw"
        let expected = "ufo ường uồng uro ưởng uổng uso ướng uống duos dướng duống đướng đướng đuống đuống đước đước đuốc đuốc đướt đướt đuốt đuốt đưới đưới đuối đuối gifu giường giường giười giười giju giượng giượng giược giược giượt giượt"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_353_delayed_d_before_coda_before_e_on_di_e_du_e_and_honor_donor_manag_monog_osoi_unlatch() {
        let input = "diredne diredme dirednge diredue difedne difedme disedne disedme disedte disedpe disedce dijedne dijedme dijedte dijedpe dijedce duredne durednhe dufedne dufednhe dusedne dusednhe dusedte dusedche dujedne dujednhe dujedte dujedche yesnge usenhe useche urenhe honor honors honorg donor donors donorg donorgd donord donordg manage manager manags managf managr managx managj monogram monogs monogf monogx monogj osoi osoiw"
        let expected = "điển điểm điểng điểu điền điềm điến điếm điết điếp điếc điện điệm điệt điệp điệc đuển đuểnh đuền đuềnh đuến đuếnh đuết đuếch đuện đuệnh đuệt đuệch yếng uếnh uếch uểnh honor honors hổng donor donors dổng đổng đổn đổng manage manager mấng mầng mẩng mẫng mậng monogram mống mồng mỗng mộng osoi ới"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_354_scenario56_trilingual_dosai_duos_gifu_manager_and_vietnamese_giuong_uong_doai_chat() {
        let input = "Dù tiến độ ban đầu hơi osoi sau chuyến công tác gifu của vị manager, bộ đôi duos kỹ sư vẫn không đoái (dosaid) hoài mệt mỏi mà thức trắng bên chiếc giường (gifuongw) nhỏ, vừa uống (usongo) trà nóng vừa tháo gỡ những mắt xích xoắn (sosawn) rối và sửa từng chỗ hỏng (honorg) để nhận được (duoscdw) sự khen thưởng xứng đáng!"
        let expected = "Dù tiến độ ban đầu hơi osoi sau chuyến công tác gifu của vị manager, bộ đôi duos kỹ sư vẫn không đoái (đoái) hoài mệt mỏi mà thức trắng bên chiếc giường (giường) nhỏ, vừa uống (uống) trà nóng vừa tháo gỡ những mắt xích xoắn (xoắn) rối và sửa từng chỗ hỏng (hổng) để nhận được (đước) sự khen thưởng xứng đáng!".replacingOccurrences(of: "(xoắn)", with: "(soắn)")
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 49: w Unlatch on Romaji C-o-[rsfjx]-o / C-a-[rsfjx]-a, ô/â -> ơ/ă Across Codas, and siren/risen/vixe/dired/diesd Unlatch
    // =========================================================================

    func test_tier4_355_romaji_coro_cofo_coso_cojo_w_unlatch_and_preservation() {
        let input = "moro morow morown morowm horo horow horown horowm toro torow torown torowm soro sorow sorown noro norow norown doro dorow dorowd dorowdn hofo hofow hofown hofowm sofo sofow sofown tofo tofow tofowm mofo mofow mofowm dofo dofow dofowd dofowdm hoso hosow hosown hosowt hosowp toso tosow tosown tosowt tosowp soso sosow sosown sosowm moso mosow mosown mosowm dojo dojow dojowd dojowdn dojowdt dojowdp hojo hojow hojowt hojowp sojo sojow sojowm tojo tojow bojo bojow bojowm bojowp"
        let expected = "moro mở mởn mởm horo hở hởn hởm toro tở tởn tởm soro sở sởn noro nở nởn doro dở đở đởn hofo hờ hờn hờm sofo sờ sờn tofo tờ tờm mofo mờ mờm dofo dờ đờ đờm hoso hớ hớn hớt hớp toso tớ tớn tớt tớp soso sớ sớn sớm moso mớ mớn mớm dojo dợ đợ đợn đợt đợp hojo hợ hợt hợp sojo sợ sợm tojo tợ bojo bợ bợm bợp"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_356_romaji_cara_casa_cafa_caja_w_unlatch_and_preservation() {
        let input = "mara maraw marawn marawng hara haraw harawn harawng sara saraw sarawn tara taraw tarawn nara naraw narawn dara daraw darawd darawdn chara charaw charawn charawng masa masaw masawn masawng masawt masawc nasa nasaw nasawn nasawng sasa sasaw sasawn sasawt sasawc tasa tasaw tasawt dasa dasawd dasawdn dasawdng dasawdt dafa dafawd dafawdn dafawdng dafawdm maja majawt majawc naja najawng daja dajawd dajawdn dajawdng dajawdt dajawdc dajawdp"
        let expected = "mara mẳ mẳn mẳng hara hẳ hẳn hẳng sara sẳ sẳn tara tẳ tẳn nara nẳ nẳn dara dẳ đẳ đẳn chara chẳ chẳn chẳng masa mắ mắn mắng mắt mắc nasa nắ nắn nắng sasa sắ sắn sắt sắc tasa tắ tắt dasa đắ đắn đắng đắt dafa đằ đằn đằng đằm maja mặt mặc naja nặng daja đặ đặn đặng đặt đặc đặp"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_357_english_and_romaji_boron_moron_datas_gotos_topos_dodos_dadas_and_cvnv_cvmv_w_unlatch() {
        let input = "boron boronw moron moronw datas datasw dataswd datasdw gotos gotosw topos toposw dodos dodosw dodoswn dodoswt dadas dadasw dadaswn dadaswng dadaswt honowf sonows donowd donowdf donowds hanawf hanaws manawj namawf namaws"
        let expected = "boron bởn moron mởn datas dắt đắt đắt gotos gớt topos tớp dodos đớ đớn đớt dadas đắ đắn đắng đắt hờn sớn đơn đờn đớn hằn hắn mặn nằm nắm"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_358_english_siren_risen_vixen_died_dies_preservation_and_vietnamese_sireng_riseng_vixem_dired_diesd_unlatch() {
        let input = "siren sirens sireng risen riseng vixen vixens vixem died diredm diredn diredng dies diesdm diesdn diesdng diesdc diesdp diesdt"
        let expected = "siren sirens siểng risen riếng vixen vixens viễm died điểm điển điểng dies điếm điến điếng điếc điếp điết"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_359_scenario57_trilingual_moron_datas_siren_dojo_and_vietnamese_mo_han_dat_diem_chat() {
        let input = "Tại võ đường dojo ở vùng nara, khi tiếng còi siren vang lên báo hiệu bộ dữ liệu datas đã sẵn sàng, mọi người đều vui vẻ mỉm cười hớn hở (horow) vì chẳng (charawng) còn ai phải trăn trở mở (morow) lại bản nháp cũ hay lo lắng bị trừ điểm (diredm), cùng nhau nắm (namaws) chặt cơ hội để đặt (dajawdt) mục tiêu cao nhất!"
        let expected = "Tại võ đường dojo ở vùng nara, khi tiếng còi siren vang lên báo hiệu bộ dữ liệu datas đã sẵn sàng, mọi người đều vui vẻ mỉm cười hớn hở (hở) vì chẳng (chẳng) còn ai phải trăn trở mở (mở) lại bản nháp cũ hay lo lắng bị trừ điểm (điểm), cùng nhau nắm (nắm) chặt cơ hội để đặt (đặt) mục tiêu cao nhất!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 50: w Unlatch on door/goof/loom/doom & Plural -oo- Words, dojos/rojos/loofs/oofs/charas Unlatch, and duetj/duetsd/duetds Delayed-e Unlatch
    // =========================================================================

    func test_tier4_360_english_door_goof_loom_doom_w_unlatch_and_preservation() {
        let input = "door doorw doorwd doordw doorwn doorwm doorwi doordwn goof goofs goofw goofwm goofwn goofwi loom looms loomw loomwf loomws loomwr loomwx loomwj doom dooms doomw doomwd doomdw doomwdf doomwds doomwdr doomwdx doomwdj"
        let expected = "door dở đở đở dởn dởm dởi đởn goof goofs gờ gờm gờn gời loom looms lơm lờm lớm lởm lỡm lợm doom dooms dơm đơm đơm đờm đớm đởm đỡm đợm"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_361_english_plural_oo_words_and_mamas_nonos_w_unlatch() {
        let input = "mamas mamasw nonos nonosw noops noopsw goops goopsw goopjw troops troopsw troopjw looms loomsw dooms doomsw doomswd doomsdw rooms roomsw booms boomsw goons goonsw loons loonsw moons moonsw roots rootsw boost boostw roost roostw"
        let expected = "mamas mắm nonos nớn noops nớp goops gớp gợp troops trớp trợp looms lớm dooms dớm đớm đớm rooms rớm booms bớm goons gớn loons lớn moons mớn roots rớt boost bớt roost rớt"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_362_english_and_romaji_dojos_rojos_loofs_oofs_charas_unlatch() {
        let input = "dojos dojosw dojoswd dojosi dojosid dojosm dojosn dojosng dojosc dojosp dojost rojos rojosw rojoswn rojoswt rojosi rojosm rojosn rojosng rojosc rojosp rojost loofs loofsw loofswm loofswn loofsi loofsm loofsn loofsng loofsc loofsp loofst oofs oofsw oofswm oofswn oofswt oofswp oofsi oofsm oofsn oofsng oofsc oofsp oofst charas charasw charaswn charaswng charaswm charaswt charaswc charaswp charasn charasng charasm charast charasc charasp charasy charasu"
        let expected = "dojos dớ đớ đối đối dốm dốn dống dốc dốp dốt rojos rớ rớn rớt rối rốm rốn rống rốc rốp rốt loofs lớ lớm lớn lối lốm lốn lống lốc lốp lốt oofs ớ ớm ớn ớt ớp ối ốm ốn ống ốc ốp ốt charas chắ chắn chẳng chắm chắt chắc chắp chấn chấng chấm chấtấc chấp chấy chấu".replacingOccurrences(of: "chẳng", with: "chắng").replacingOccurrences(of: "đối đối", with: "dối đối").replacingOccurrences(of: "chấtấc", with: "chất chấc")
        assertBuffer(input, equals: expected)
    }

    func test_tier4_363_english_duet_duets_preservation_and_vietnamese_duetj_duetsd_duetds_delayed_e_unlatch() {
        let input = "duet duets duetse duetsed duetsde duetdse duetje duetjed duetjde duetdje"
        let expected = "duet duets duết đuết đuết đuết duệt đuệt đuệt đuệt"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_364_scenario58_trilingual_rooms_troops_roots_boost_and_vietnamese_lon_rot_chac_chan_chat() {
        let input = "Sau khi kiểm tra các phòng rooms và bổ sung thêm lực lượng troops để boost hiệu suất từ gốc roots, cả đội đã chắc (charaswc) chắn (charaswn) vượt qua nỗi sợ bóng tối sau cánh cửa door để bước ra thế giới rộng lớn (loonsw), hái những trái ớt (oofswt) chín đỏ và ăn bữa cơm sớm (loomsw) ấm áp!"
        let expected = "Sau khi kiểm tra các phòng rooms và bổ sung thêm lực lượng troops để boost hiệu suất từ gốc roots, cả đội đã chắc (chắc) chắn (chắn) vượt qua nỗi sợ bóng tối sau cánh cửa door để bước ra thế giới rộng lớn (lớn), hái những trái ớt (ớt) chín đỏ và ăn bữa cơm sớm (lớm) ấm áp!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 51: Single-e ie+Coda Unlatch on ties/dies/lies/vies/hies/tries & tier/bier/pier/trier/chief/thief, w Unlatch on C-[ao]-[pt]-[ao]/oto/honor/donor/asa, and dire+d Unlatch
    // =========================================================================

    func test_tier4_365_english_ties_dies_lies_vies_hies_tries_single_e_coda_unlatch_and_preservation() {
        let input = "ties tiesn tiesm tiesng tiesc tiesp tiest dies diesel diesn diesm diesng diesc diesp diest diesnd diesmd diesngd diescd diespd diestd lies liesn liesm liesng liesc liesp liest vies viesn viesm viesng viesc viesp viest hies hiesn hiesm hiesng hiesp hiest tries triesn triesm triesng triesc triesp triest"
        let expected = "ties tiến tiếm tiếng tiếc tiếp tiết dies diesel diến diếm diếng diếc diếp diết điến điếm điếng điếc điếp điết lies liến liếm liếng liếc liếp liết vies viến viếm viếng viếc viếp viết hies hiến hiếm hiếng hiếp hiết tries triến triếm triếng triếc triếp triết"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_366_english_tier_bier_pier_trier_chief_thief_single_e_sonorant_unlatch_and_preservation() {
        let input = "tier tiers tieru tiern tierm tierng bier biers bieru biern bierm bierng pier piers trier triern trierm trierng chief chiefs chiefly chiefn chiefm chiefng thief thiefn thiefm thiefng"
        let expected = "tier tiers tieru tiển tiểm tiểng bier biers bieru biển biểm biểng pier piers trier triển triểm triểng chief chiefs chiefly chiền chiềm chiềng thief thiền thiềm thiềng"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_367_romaji_and_english_cvptv_oto_w_before_tone_unlatch_and_preservation() {
        let input = "mata mataws matawj data dataws datawsd datawds datawj datawjd datawdj soto sotows sotowj goto gotows gotowj topo topows topowj hopo hopows hopowj capa capaws capawj tapa tapaws tapawj sapa sapaws sapawj chata chataws chatawj chapa chapaws chapawj choto chotows chotowj chopo chopows chopowj oto otosu otows otowj otosw otojw"
        let expected = "mata mắt mặt data dắt đắt đắt dặt đặt đặt soto sớt sợt goto gớt gợt topo tớp tợp hopo hớp hợp capa cắp cặp tapa tắp tập sapa sắp sặp chata chắt chặt chapa chắp chặp choto chớt chợt chopo chớp chợp oto otosu ớt ợt ớt ợt".replacingOccurrences(of: "tập", with: "tặp")
        assertBuffer(input, equals: expected)
    }

    func test_tier4_368_english_and_romaji_honor_donor_asa_w_and_dire_difed_dijed_single_e_unlatch() {
        let input = "honor honors honorw donor donors donorw donorwd donordw asa asaw asawn asawng asawm asawt asawc asawp dire diredm diredn diredng diredue difedm difedn difedng difedue dijedm dijedn dijedc dijedp dijedt dijedue"
        let expected = "honor honors hởn donor donors dởn đởn đởn asa ắ ắn ắng ắm ắt ắc ắp dire điểm điển điểng điểu điềm điền điềng điều điệm điện điệc điệp điệt điệu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_369_scenario59_trilingual_chief_tier_sapa_oto_and_vietnamese_tien_viet_bien_dat_chat() {
        let input = "Vị kỹ sư trưởng chief ở phân khúc tier cao cấp vừa đi công tác sapa về đã nhanh chóng viết (viest) báo cáo tiến (tiesn) độ, triển (triern) khai tàu khảo sát vùng biển (biern) và đặt (datawjd) mục tiêu hợp (hopowj) tác chặt (chatawj) chẽ để không phát sinh tiếng ồn oto bất thường!"
        let expected = "Vị kỹ sư trưởng chief ở phân khúc tier cao cấp vừa đi công tác sapa về đã nhanh chóng viết (viết) báo cáo tiến (tiến) độ, triển (triển) khai tàu khảo sát vùng biển (biển) và đặt (đặt) mục tiêu hợp (hợp) tác chặt (chặt) chẽ để không phát sinh tiếng ồn oto bất thường!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 52: died+Tone+Coda/u+e Unlatch, Plural -rns/-rms w/g Unlatch, Romaji -oi w Unlatch, and dora/dosa/kern/tern Unlatch
    // =========================================================================

    func test_tier4_370_english_died_tone_coda_and_dieu_unlatch_and_preservation() {
        let input = "died diedsn diedsm diedsng diedst diedsc diedsp diedfn diedfm diedfng diedrn diedrm diedrng diedxn diedxm diedxng diedjn diedjm diedjng diedjt diedjc diedjp diedsue diedfue diedrue diedxue diedjue dieduse diedufe diedure dieduxe dieduje"
        let expected = "died điến điếm điếng điết điếc điếp điền điềm điềng điển điểm điểng điễn điễm điễng điện điệm điệng điệt điệc điệp điếu điều điểu điễu điệu điếu điều điểu điễu điệu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_371_english_plural_rns_rms_w_and_g_unlatch_and_preservation() {
        let input = "barns barnsw barnsg darns darnsw darnswd darnsdw darnsg darnsgd darnsdg tarns tarnsw tarnsg horns hornsw hornsg thorns thornsw thornsg morns mornsw mornsg burns burnsw burnsg turns turnsw turnsg churns churnsw churnsg urns urnsw urnsg harms harmsw charms charmsw"
        let expected = "barns bắn báng darns dắn đắn đắn dáng đáng đáng tarns tắn táng horns hớn hóng thorns thớn thóng morns mớn móng burns bứn búng turns tứn túng churns chứn chúng urns ứn úng harms hắm charms chắm"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_372_romaji_osoi_hosoi_moroi_noroi_soroi_w_unlatch_and_preservation() {
        let input = "osoi osoiw hosoi hosoiw moroi moroiw noroi noroiw soroi soroiw doroiw doroiwd doroidw tofoiw hofoiw tojoiw hojoiw dojoiwd dojoidw"
        let expected = "osoi ới hosoi hới moroi mởi noroi nởi soroi sởi dởi đởi đởi tời hời tợi hợi đợi đợi"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_373_romaji_dora_dosa_and_english_kern_tern_unlatch_and_preservation() {
        let input = "dora dorayaki doraid doradi doraod dorado doradn doradng dorady doradw dosa dosai dosaod dosado dosadn dosadt dosadi dosady dosadw kern kernel kerns kernh kernhe kerng terns ternh ternhe"
        let expected = "dora dorayaki đoải đoải đoảo đoảo đoản đoảng đoảy đoẳ dosa dosai đoáo đoáo đoán đoát đoái đoáy đoắ kern kernel kerns kẻnh kểnh kẻng terns tẻnh tểnh"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_374_scenario60_trilingual_kernel_hosoi_turns_and_vietnamese_dien_dieu_doan_doi_chat() {
        let input = "Sau khi tiến trình phụ đã died trong nhân kernel, chúng (churnsg) tôi lần lượt turns kiểm tra các chỉ số hosoi để dự đoán (dosadn) nguyên nhân, điều (diedfue) chỉnh nguồn điện (diedjn) và kiên nhẫn đợi (dojoiwd) kết quả đáng (darnsgd) tin cậy trước khi ăn bánh dorayaki!"
        let expected = "Sau khi tiến trình phụ đã died trong nhân kernel, chúng (chúng) tôi lần lượt turns kiểm tra các chỉ số hosoi để dự đoán (đoán) nguyên nhân, điều (điều) chỉnh nguồn điện (điện) và kiên nhẫn đợi (đợi) kết quả đáng (đáng) tin cậy trước khi ăn bánh dorayaki!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 53: keen/keens/teens g Unlatch, leers/seers/cheers/veers/reefs/beefs Coda Unlatch, soars/loafs/oafs/coifs Unlatch, chefs/refs Unlatch, and hoofs/roofs/goofs Unlatch
    // =========================================================================

    func test_tier4_375_english_keen_keens_teens_g_and_leers_seers_cheers_veers_coda_unlatch() {
        let input = "keen keenly keens keeng keengf keengs keengr keengx keengj keensg teens teensg leers leersm leersn leerst leersp leersu seers seersm seersn seerst seersp seersu cheers cheered cheering cheerful cheersm cheersn cheerst cheersp cheersc cheersu veers veered veering veersm veersn veerst veersp veersu reefs reefsm reefsn reefst reefsp reefsc reefsu beefs beefsm beefsn beefst beefsp beefsc beefsu"
        let expected = "keen keenly keens kêng kềng kếng kểng kễng kệng kếng teens tếng leers lếm lến lết lếp lếu seers sếm sến sết sếp sếu cheers cheered cheering cheerful chếm chến chết chếp chếc chếu veers veered veering vếm vến vết vếp vếu reefs rếm rến rết rếp rếc rếu beefs bếm bến bết bếp bếc bếu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_376_english_soars_loafs_oafs_coifs_unlatch_and_preservation() {
        let input = "soars soarsn soarsng soarst soarsi soarsy soarso soarsw soarswn soarswt loafs loafsn loafsng loafst loafsc loafsi loafsy loafso loafsw loafswn loafswt oafs oafsn oafsng oafst oafsc oafsi oafsy oafso oafsw oafswn oafswt coifs coifso coifsw"
        let expected = "soars soán soáng soát soái soáy soáo soắ soắn soắt loafs loán loáng loát loác loái loáy loáo loắ loắn loắt oafs oán oáng oát oác oái oáy oáo oắ oắn oắt coifs cối cới"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_377_english_chefs_refs_midword_tone_override_unlatch_and_preservation() {
        let input = "chefs chefsn chefsm chefsc chefsp chefst chefso chefse chefsen chefsem chefset chefsep chefsec chefseu refs refsn refsm refsc refsp refst refso refse refsen refsem refset refsep refsec refseu"
        let expected = "chefs chén chém chéc chép chét chéo chế chến chếm chết chếp chếc chếu refs rén rém réc rép rét réo rế rến rếm rết rếp rếc rếu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_378_english_hoofs_roofs_goofs_unlatch_and_preservation() {
        let input = "hoofs hoofsw hoofswn hoofswt hoofsi hoofsm hoofsn hoofsng hoofsc hoofsp hoofst roofs roofsw roofswn roofswt roofsi roofsm roofsn roofsng roofsc roofsp roofst goofs goofsw goofswn goofswt goofsi goofsm goofsn goofsng goofsc goofsp goofst"
        let expected = "hoofs hớ hớn hớt hối hốm hốn hống hốc hốp hốt roofs rớ rớn rớt rối rốm rốn rống rốc rốp rốt goofs gớ gớn gớt gối gốm gốn gống gốc gốp gốt"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_379_scenario61_trilingual_cheers_chefs_roofs_and_vietnamese_keeng_soat_bep_goc_chat() {
        let input = "Tiếng chuông leng kêng (keeng) và kềng (keengf) càng vang lên trên mái nhà roofs, các đầu bếp chefs trong gian bếp (beefsp) ấm cúng cùng nâng ly cheers chúc mừng sau khi rà soát (soarst) hết (chefset) các quy trình từ gốc (goofsc) đến ngọn!"
        let expected = "Tiếng chuông leng kêng (kêng) và kềng (kềng) càng vang lên trên mái nhà roofs, các đầu bếp chefs trong gian bếp (bếp) ấm cúng cùng nâng ly cheers chúc mừng sau khi rà soát (soát) hết (chết) các quy trình từ gốc (gốc) đến ngọn!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 54: Mid-Word r->s and r->f Tone Override Unlatch on bars/cars/mars/tars/barfs/barf, hers/ers/nerfs/serfs/nerf/serf/kerf/vers, sirs/dirs, and ors/urs/curs/burs/surf/turf
    // =========================================================================

    func test_tier4_380_english_bars_cars_mars_tars_midword_tone_override_unlatch_and_preservation() {
        let input = "bars barsn barsm barsng barsc barsp barst barsi barso barsu barsy barsw barswn barswt barsa barsan barsat cars carsn carsm carsng carsc carsp carst carsi carso carsu carsy carsw carswn carswt carsa carsan carsat mars marsn marsm marsng marsc marsp marst marsi marso marsu marsy marsw marswn marswt marsa marsan marsat tars tarsn tarsm tarsng tarsc tarsp tarst tarsi tarso tarsu tarsy tarsw tarswn tarswt tarsa tarsan tarsat"
        let expected = "bars bán bám báng bác báp bát bái báo báu báy bắ bắn bắt bấ bấn bất cars cán cám cáng các cáp cát cái cáo cáu cáy cắ cắn cắt cấ cấn cất mars mán mám máng mác máp mát mái máo máu máy mắ mắn mắt mấ mấn mất tars tán tám táng tác táp tát tái táo táu táy tắ tắn tắt tấ tấn tất"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_381_english_hers_ers_vers_sirs_dirs_midword_tone_override_unlatch_and_preservation() {
        let input = "hers herse hersen hersem herset hersep herseu hersn hersm hersc hersp herst herso ers erse ersen erset ersn ersm ersc ersp erst erso vers verse versn versm versc versp verst verso sirs sirsn sirsm sirsc sirsp sirst sirsu dirs dirsd dirsn dirsnd dirsdn dirsm dirsc dirsp dirst dirstd dirsdt dirsu"
        let expected = "hers hế hến hếm hết hếp hếu hén hém héc hép hét héo ers ế ến ết én ém éc ép ét éo vers verse vén vém véc vép vét véo sirs sín sím síc síp sít síu dirs đí dín đín đín dím díc díp dít đít đít díu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_382_english_ors_urs_curs_burs_midword_tone_override_unlatch_and_preservation() {
        let input = "ors orsw orswn orswt orso orson orsot orsi orsm orsn orsc orsp orst urs ursw urswn urswt ursi ursuw urswu ursm ursn ursc ursp urst curs curse cursw curswn curswt cursi cursuw curswu cursm cursn cursc cursp curst burs burst bursw burswn burswt bursi bursuw burswu bursm bursn bursc bursp"
        let expected = "ors ớ ớn ớt ố ốn ốt ói óm ón óc óp ót urs ứ ứn ứt úi ứu ứu úm ún úc úp út curs curse cứ cứn cứt cúi cứu cứu cúm cún cúc cúp cút burs burst bứ bứn bứt búi bứu bứu búm bún búc búp"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_383_english_barf_barfs_nerf_nerfs_serf_serfs_kerf_surf_turf_tone_override_unlatch() {
        let input = "barf barfn barfm barfng barfi barfo barfu barfy barfw barfwn barfwng barfwm barfa barfan barfang barfam barfau barfay barfs barfsn barfst barfsw barfswn barfswt barfsa barfsan barfsat nerf nerfn nerfm nerfo nerfe nerfen nerfem nerfeu nerfs nerfsn nerfsm nerfst nerfsp nerfso nerfse nerfsen nerfsem nerfset nerfsep nerfseu serf serfn serfm serfo serfe serfen serfem serfeu serfs serfsn serfsm serfst serfsp serfso serfse serfsen serfsem serfset serfsep serfseu kerf kerfn kerfm kerfo kerfe kerfen kerfem kerfeu kerfenh surf surfn surfm surfi surfuw surfw surfwa surfwi surfwu surfwn surfwng surfwm turf turfn turfm turfi turfuw turfw turfwa turfwi turfwu turfwn turfwng turfwm"
        let expected = "barf bàn bàm bàng bài bào bàu bày bằ bằn bằng bằm bầ bần bầng bầm bầu bầy barfs bán bát bắ bắn bắt bấ bấn bất nerf nèn nèm nèo nề nền nềm nều nerfs nén ném nét nép néo nế nến nếm nết nếp nếu serf sèn sèm sèo sề sền sềm sều serfs sén sém sét sép séo sế sến sếm sết sếp sếu kerf kèn kèm kèo kề kền kềm kều kềnh surf sùn sùm sùi sừu sừ sừa sừi sừu sừn sừng sừm turf tùn tùm tùi từu từ từa từi từu từn từng từm"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_384_scenario62_trilingual_cars_bars_surf_and_vietnamese_ban_het_cuu_nen_chat() {
        let input = "Dọc bãi biển nơi du khách đang surf sóng và đỗ xe cars gần các quầy bars, đội cứu (curswu) hộ đã làm việc hết (herset) mình trên nền (nerfen) cát trắng, thắp nến (nerfsen) hướng dẫn tàu thuyền cập bến an toàn và bán (barsn) từng (turfwng) phần nước mát cho mọi người!"
        let expected = "Dọc bãi biển nơi du khách đang surf sóng và đỗ xe cars gần các quầy bars, đội cứu (cứu) hộ đã làm việc hết (hết) mình trên nền (nền) cát trắng, thắp nến (nến) hướng dẫn tàu thuyền cập bến an toàn và bán (bán) từng (từng) phần nước mát cho mọi người!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 55: oars/choirs/moors/boors Unlatch, ores/tores/hores/lores/chores/ore Unlatch, hires/tires/mires/sires/berms Unlatch
    // =========================================================================

    func test_tier4_385_english_oars_choirs_moors_boors_unlatch_and_preservation() {
        let input = "oars oarsn oarsng oarst oarsc oarsi oarsy oarso oarsw oarswn oarswt choirs choirso choirsw moors moorsw moorswn moorswt moorsi moorsm moorsn moorsng moorsc moorsp moorst boors boorsw boorswn boorswt boorsi boorsm boorsn boorsng boorsc boorsp boorst"
        let expected = "oars oán oáng oát oác oái oáy oáo oắ oắn oắt choirs chối chới moors mớ mớn mớt mối mốm mốn mống mốc mốp mốt boors bớ bớn bớt bối bốm bốn bống bốc bốp bốt"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_386_english_ores_tores_hores_lores_chores_ore_unlatch_and_preservation() {
        let input = "ore oreo ores oreso oresn oresm orest oresc oresp tores toreso toresn toresm torest hores horeso horesn horesm horest lores loreso loresn loresm lorest chores choreso choresn choresm chorest"
        let expected = "ore oẻo ores oéo oén oém oét oéc oép tores toéo toén toém toét hores hoéo hoén hoém hoét lores loéo loén loém loét chores choéo choén choém choét"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_387_english_hires_tires_mires_sires_berms_unlatch_and_preservation() {
        let input = "hires hirese hiresn hiresm hiresng hirest hiresp hiresc hiresue tires tirese tiresn tiresm tiresng tirest tiresp tiresc tiresue mires mirese miresn miresm miresng mirest miresp miresc miresue sires sirese siresn siresm siresng sirest siresp siresc siresue berms bermse"
        let expected = "hires hiế hiến hiếm hiếng hiết hiếp hiếc hiếu tires tiế tiến tiếm tiếng tiết tiếp tiếc tiếu mires miế miến miếm miếng miết miếp miếc miếu sires siế siến siếm siếng siết siếp siếc siếu berms bếm"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_388_english_plural_midword_tone_override_preservation_and_unlatch_matrix() {
        let input = "oars choirs moors boors ores tores hores lores chores hires tires mires sires berms oarsm moorsn boorsn hiresng tiresngchores"
        let expected = "oars choirs moors boors ores tores hores lores chores hires tires mires sires berms oám mốn bốn hiếng tiresngchores"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_389_scenario63_trilingual_choirs_chores_tires_and_vietnamese_choi_bon_hien_toet_chat() {
        let input = "Sau buổi tập hát của dàn đồng ca choirs và hoàn thành việc nhà chores cũng như thay lốp xe tires, cả bốn (boorsn) thành viên đều từ chối (choirso) nghỉ sớm để hiến (hiresn) kế hoạch mới với nụ cười tươi toét (torest) trên môi (moorsi)!"
        let expected = "Sau buổi tập hát của dàn đồng ca choirs và hoàn thành việc nhà chores cũng như thay lốp xe tires, cả bốn (bốn) thành viên đều từ chối (chối) nghỉ sớm để hiến (hiến) kế hoạch mới với nụ cười tươi toét (toét) trên môi (mối)!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 56: General Mid-Word Tone Override (r/s -> s/f/r/x/j), beer/deer/beers/deers, door/doors/goof, and soar/coax/tore/hore/lore/chore/ore/lose/hose/chose/those Tone Override Unlatch
    // =========================================================================

    func test_tier4_390_vietnamese_general_midword_tone_override_rs_rf_rj_rx_sf_sr_sj_sx() {
        let input = "harsn harfn harjn harxn basfn basrn basjn basxn lasfm tasjo hosfng cosfn misfnh tisfnh hisfnh disfnhd misrnh disrnhd curfm curfn curfng curfwng tersn terst tersen terset corsn corst corsw corso torsn torst torson torsot torsoi"
        let expected = "hán hàn hạn hãn bàn bản bạn bãn làm tạo hòng còn mình tình hình đình mỉnh đỉnh cùm cùn cùng cừng tén tét tến tết cón cót cớ cố tón tót tốn tốt tối"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_391_english_beer_deer_beers_deers_tone_override_and_coda_unlatch() {
        let input = "beer beers beerf beerfn beerfm beerfu beerx beerxn beerj beerjn beerjt beersm beersn beerst beersp beersc beersu deer deers deerf deerfd deerfnd deerfud deerxd deerjd deerjtd deersd deersn deersnd deersm deersmd deerst deerstd deersu deersud"
        let expected = "beer beers bề bền bềm bều bễ bễn bệ bện bệt bếm bến bết bếp bếc bếu deer deers dề đề đền đều đễ đệ đệt đế dến đến dếm đếm dết đết dếu đếu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_392_english_door_doors_goof_tone_override_and_coda_unlatch() {
        let input = "door doors doorf doorfd doorfnd doorfngd doorfid doorfwid doorxd doorxid doorxwd doorjd doorjid doorjnd doorjngd doorjtd doorjwtd doorsd doorsi doorsid doorsm doorsmd doorsn doorsnd doorsng doorsngd doorsc doorscd doorsp doorspd doorst doorstd doorsw doorswd goof goofs goofr goofrng goofri goofrwi goofx goofxng goofxw goofj goofjng goofji goofjp goofjwi"
        let expected = "door doors dồ đồ đồn đồng đồi đời đỗ đỗi đỡ độ đội độn động đột đợt đố dối đối dốm đốm dốn đốn dống đống dốc đốc dốp đốp dốt đốt dớ đớ goof goofs gổ gổng gổi gởi gỗ gỗng gỡ gộ gộng gội gộp gợi"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_393_english_soar_coax_tore_hore_lore_chore_ore_lose_hose_chose_those_tone_override_unlatch() {
        let input = "soar soarf soarfn soarfng soarfi soarfwng soarx soarxng soarj soarjn soarjt soarji coax coaxes coaxed coaxf coaxfn coaxfng coaxr coaxrng coaxs coaxsn coaxst coaxsi coaxsy coaxswn coaxswt coaxj coaxjn coaxjt orefo orejo torefo torejt horefo horejt lorefo lorejt chorefo chorejt lose loser losefo losejt hose hosefo hosejt chose chosefo chosejt those thosefo thosejt"
        let expected = "soar sòa soàn soàng soài soằng sõa soãng sọa soạn soạt soại coax coaxes coaxed còa coàn coàng cỏa coảng cóa coán coát coái coáy coắn coắt cọa coạn coạt oèo oẹo toèo toẹt hoèo hoẹt loèo loẹt choèo choẹt lose loser loèo loẹt hose hoèo hoẹt chose choèo choẹt those thoèo thoẹt"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_394_scenario64_trilingual_doors_beers_coax_and_vietnamese_dong_den_soan_ban_chat() {
        let input = "Sau khi đóng các cánh cửa doors và mang hai ly beers ra bàn, anh ấy khéo léo coaxes cả nhóm cùng đồng (doorfngd) tâm hiệp lực đến (deersnd) phút cuối để soạn (soarjn) thảo bản ghi chú terse về tư thế torso, giúp các bạn (basjn) làm (lasfm) việc hết mình (misfnh) và gộp (goofjp) kết quả đúng hạn!"
        let expected = "Sau khi đóng các cánh cửa doors và mang hai ly beers ra bàn, anh ấy khéo léo coaxes cả nhóm cùng đồng (đồng) tâm hiệp lực đến (đến) phút cuối để soạn (soạn) thảo bản ghi chú terse về tư thế torso, giúp các bạn (bạn) làm (làm) việc hết mình (mình) và gộp (gộp) kết quả đúng hạn!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 57: Mid-Word Tone Overrides on -rn/-rm Stems (barn/darn/tarn/born/corn/horn/morn/torn/burn/turn/churn/urn/harm/charm/norm/dorm/corm/term/berm/derm/kern/tern) and Plural -rns/-rms Circumflex/Palatal Unlatch
    // =========================================================================

    func test_tier4_395_english_barn_darn_tarn_born_corn_horn_morn_torn_tone_override_unlatch() {
        let input = "barn barnf barnfg barnfw barnfa barnfag barnj barnjg barnjw barnjwg barnja barnx barnxg darn darnf darnfd darnfgd darnfad darnj darnjd darnjgd darnjwd darnjad darnx darnxd tarn tarnf tarnfg tarnfw tarnfa tarnj tarnjg tarnjw tarnja born bornf bornfg bornfo bornfog bornfw bornj bornjg bornjo bornjog bornjw bornx bornxg borns bornsg bornso bornsog bornsw corn cornf cornfg cornfo cornfog cornj cornjg cornjo cornjog corns cornsg cornso cornsog cornsw horn hornf hornfg hornfo hornfog hornj hornjg hornjo hornjog morn mornf mornfg mornfo mornfog mornj mornjg mornjo mornjog torn tornf tornfg tornfo tornfog tornj tornjg tornjo tornjog torns tornsg tornso tornsog tornsw"
        let expected = "barn bàn bàng bằn bần bầng bạn bạng bặn bặng bận bãn bãng darn dàn đàn đàng đần dạn đạn đạng đặn đận dãn đãn tarn tàn tàng tằn tần tạn tạng tặn tận born bòn bòng bồn bồng bờn bọn bọng bộn bộng bợn bõn bõng borns bóng bốn bống bớn corn còn còng cồn cồng cọn cọng cộn cộng corns cóng cốn cống cớn horn hòn hòng hồn hồng họn họng hộn hộng morn mòn mòng mồn mồng mọn mọng mộn mộng torn tòn tòng tồn tồng tọn tọng tộn tộng torns tóng tốn tống tớn"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_396_english_burn_turn_churn_urn_harm_charm_norm_dorm_corm_tone_override_unlatch() {
        let input = "burn burnf burnfg burnfw burnfwg burnj burnjg burnjw burnjwg burnx burnxg burnxwg turn turnf turnfg turnfw turnfwg turnj turnjg turnjw turnjwg turnx turnxg churn churnf churnfg churnfwg churnj churnjg churnjwg churnx churnxg churnxwg urn urnf urnfg urnfw urnfwg urnj urnjg urnjw urnjwg urnx urnxg harm harmful harmj harmjw harmja harmx harmxa charm charmf charmfw charmfa charmj charmjw charmja charmx charmxa norm normf normfo normfw normj normjo normjw dorm dormf dormfd dormfod dormfwd dormj dormjd dormjod dormjwd dorms dormsd dormsod dormswd corm cormf cormfo cormfw cormj cormjo cormjw corms cormso cormsw"
        let expected = "burn bùn bùng bừn bừng bụn bụng bựn bựng bũn bũng bững turn tùn tùng từn từng tụn tụng tựn tựng tũn tũng churn chùn chùng chừng chụn chụng chựng chũn chũng chững urn ùn ùng ừn ừng ụn ụng ựn ựng ũn ũng harm harmful hạm hặm hậm hãm hẫm charm chàm chằm chầm chạm chặm chậm chãm chẫm norm nòm nồm nờm nọm nộm nợm dorm dòm đòm đồm đờm dọm đọm độm đợm dorms đóm đốm đớm corm còm cồm cờm cọm cộm cợm corms cốm cớm"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_397_english_term_berm_derm_kern_tern_tone_override_and_plural_e_unlatch() {
        let input = "term terms termse termf termfe termx termxe termj termje berm berms bermse bermf bermfe bermx bermxe bermj bermje derm dermf dermfd dermfed dermx dermxd dermxed dermj dermjd dermjed derms dermsd dermse dermsed kern kerns kernse kernsg kernseg kernsh kernshe kernf kernfe kernfg kernfeg kernfh kernfeh kernx kernxe kernxg kernxeg kernj kernje kernjg kernjeg kernjh kernjeh terns ternse ternsh ternshe ternf ternfe ternx ternxe ternj ternje"
        let expected = "term terms tếm tèm tềm tẽm tễm tẹm tệm berm berms bếm bèm bềm bẽm bễm bẹm bệm derm dèm đèm đềm dẽm đẽm đễm dẹm đẹm đệm dém đém dếm đếm kern kerns kến kéng kếng kénh kếnh kèn kền kèng kềng kènh kềnh kẽn kễn kẽng kễng kẹn kện kẹng kệng kẹnh kệnh terns tến ténh tếnh tèn tền tẽn tễn tẹn tện"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_398_english_plural_rns_rms_circumflex_and_palatal_unlatch() {
        let input = "barns barnsa barnsag barnsh darns darnsa darnsad darnsag darnsh darnshd darnsdh tarns tarnsa tarnsag tarnsh harms harmsa charms charmsa horns hornso hornsog thorns thornso thornsog morns mornso mornsog norms normsw normso"
        let expected = "barns bấn bấng bánh darns dấn đấn dấng dánh đánh đánh tarns tấn tấng tánh harms hấm charms chấm horns hốn hống thorns thốn thống morns mốn mống norms nớm nốm"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_399_scenario65_trilingual_norms_terms_harmful_and_vietnamese_cham_ung_thong_kenh_chat() {
        let input = "Dù các điều khoản terms và chuẩn mực norms mới không gây harmful cho hệ thống, đội vận hành vẫn thận trọng chạm (charmj) tay vào bảng điều khiển để từng (turnfwg) bước kiểm tra đường kênh (kernfeh) truyền dẫn và thống (thornsog) nhất phương án dự phòng trong đêm (dermsed)!"
        let expected = "Dù các điều khoản terms và chuẩn mực norms mới không gây harmful cho hệ thống, đội vận hành vẫn thận trọng chạm (chạm) tay vào bảng điều khiển để từng (từng) bước kiểm tra đường kênh (kềnh) truyền dẫn và thống (thống) nhất phương án dự phòng trong đêm (đếm)!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 58: Mid-Word Dot Tone Override (j) on -st/-sp/-sc/-rt/-rp/-rc/-ft/-xt Stems and Tone Override Unlatch on var/yes
    // =========================================================================

    func test_tier4_400_english_st_sp_sc_keyword_stems_midword_dot_tone_override_unlatch() {
        let input = "cost costj costjo costjw most mostj mostjo mostjw rust rustj rustjw gasp gasps gaspj gaspjw gaspja rasp rasps raspj raspjw raspja cusp cusps cuspj cuspjw lisp lisps lispj test tests testj testje disc discs discj discjh discjhd discjd coast coasts coastj coastjw coats coatsj coatsjw soaps soapsj soapsjw boost boostj boostjw roost roostj roostjw roots rootsj rootsjw noops noopsj noopsjw goops goopsj goopsjw troops troopsj troopsjw"
        let expected = "cost cọt cột cợt most mọt một mợt rust rụt rựt gasp gasps gạp gặp gập rasp rasps rạp rặp rập cusp cusps cụp cựp lisp lisps lịp test tests tẹt tệt disc discs dịc dịch địch địc coast coasts coạt coặt coats coạt coặt soaps soạp soặp boost bột bợt roost rột rợt roots rột rợt noops nộp nợp goops gộp gợp troops trộp trợp"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_401_english_rt_rp_rc_stems_midword_dot_tone_override_unlatch() {
        let input = "cart carts cartj cartja cartjw mart marts martj martja martjw tart tarts tartj tartja tartjw dart darts dartj dartjd dartjad dartjwd hart harts hartj hartja hartjw sort sorts sortj sortjo sortjw tort torts tortj tortjo tortjw mort mortj mortjo mortjw curt curtj curtjw hurt hurts hurtj hurtjw dirt dirts dirtj dirtjd carp carps carpj carpja carpjw harp harps harpj harpja harpjw tarp tarps tarpj tarpja tarpjw marc marcj marcja marcjw marcjh torc torcj torcjo art arts artj artja artjw arc arcs arcj arcja arcjw arcjh orc orcs orcj orcjo"
        let expected = "cart carts cạt cật cặt mart marts mạt mật mặt tart tarts tạt tật tặt dart darts dạt đạt đật đặt hart harts hạt hật hặt sort sorts sọt sột sợt tort torts tọt tột tợt mort mọt một mợt curt cụt cựt hurt hurts hụt hựt dirt dirts dịt địt carp carps cạp cập cặp harp harps hạp hập hặp tarp tarps tạp tập tặp marc mạc mậc mặc mạch torc tọc tộc art arts ạt ật ặt arc arcs ạc ậc ặc ạch orc orcs ọc ộc"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_402_english_ft_xt_stems_midword_dot_tone_override_unlatch() {
        let input = "daft daftj daftjd daftjad daftjwd raft rafts raftj raftja raftjw loft lofts loftj loftjo loftjw soft softj softjo softjw tuft tufts tuftj tuftjw left leftj leftje heft heftj heftje deft deftj deftjd deftjed theft thefts theftj theftje gift gifts giftj lift lifts liftj rift rifts riftj sift sifts siftj next nextj nextje text texts textj textje aft aftj aftja aftjw oft oftj oftjo oftjw"
        let expected = "daft dạt đạt đật đặt raft rafts rạt rật rặt loft lofts lọt lột lợt soft sọt sột sợt tuft tufts tụt tựt left lẹt lệt heft hẹt hệt deft dẹt đẹt đệt theft thefts thẹt thệt gift gifts gịt lift lifts lịt rift rifts rịt sift sifts sịt next nẹt nệt text texts tẹt tệt aft ạt ật ặt oft ọt ột ợt"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_403_english_var_and_yes_midword_tone_override_unlatch_and_preservation() {
        let input = "quar var trais var caay var las var vaats var var laij var chawng bij var awn var var troojn var varr /var/log vars varsn varsm varsng varsc varsp varst varsi varso varsu varsy varsw varswn varswt varsa varsan varsat varf varfn varfng varfm varfo varfy varj varjn varjng varjm varjo varjy varjc varjch varjp varjt varx varxn varxng varxm varxo varxy yes yesfe yesfen yesfne yesfeu yesfue yesre yesren yesrne yesreu yesrue yesxe yesxen yesxne yesxeu yesxue yesje yesjen yesjne yesjeu yesjue yesjet yesjte"
        let expected = "quả vả trái vả cây vả lá vả vất vả vả lại vả chăng bị vả ăn vả vả trộn vả var /var/log vars ván vám váng vác váp vát vái váo váu váy vắ vắn vắt vấ vấn vất và vàn vàng vàm vào vày vạ vạn vạng vạm vạo vạy vạc vạch vạp vạt vã vãn vãng vãm vão vãy yes yề yền yền yều yều yể yển yển yểu yểu yễ yễn yễn yễu yễu yệ yện yện yệu yệu yệt yệt"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_404_scenario66_trilingual_cost_most_disc_var_yes_and_vietnamese_mot_gap_dich_va_yen_chat() {
        let input = "Sau khi kiểm tra chi phí cost của ổ đĩa disc và khai báo các biến vars với phản hồi yes, cả nhóm đã hái quả vả (quar var) ngọt mát, gặp (gaspjw) nhau tại một (mostjo) điểm hẹn yên bình ở vùng yền (yesfne) để dịch (discjh) tài liệu và (varf) đặt (dartjwd) các giỏ hàng carts lên mặt (martjw) bàn!"
        let expected = "Sau khi kiểm tra chi phí cost của ổ đĩa disc và khai báo các biến vars với phản hồi yes, cả nhóm đã hái quả vả (quả vả) ngọt mát, gặp (gặp) nhau tại một (một) điểm hẹn yên bình ở vùng yền (yền) để dịch (dịch) tài liệu và (và) đặt (đặt) các giỏ hàng carts lên mặt (mặt) bàn!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 59: Tone Override Unlatch on barf/nerf/serf/kerf/surf/turf (j/x), Stop-Coda -fc/-fp/-ft/-xc/-xp/-xt (s), and Palatal -rch/-fch/-xch (s/j)
    // =========================================================================

    func test_tier4_405_english_barf_nerf_serf_kerf_surf_turf_dot_and_tilde_tone_override_unlatch() {
        let input = "barf barfs barfj barfjn barfjm barfjt barfjc barfjch barfjp barfjo barfjw barfjwn barfjwt barfjwc barfja barfjan barfjat barfjac barfx barfxn barfxng barfxo nerf nerfs nerfj nerfje nerfjen nerfjem nerfjet nerfx nerfxe nerfxen serf serfs serfj serfje serfjen serfjet serfx serfxe kerf kerfj kerfje kerfjen kerfjet kerfjenh kerfx kerfxe kerfxenh surf surfs surfj surfjn surfjt surfjp surfjc surfjw surfjwc surfx surfxng surfxw surfxwa surfxwng turf turfs turfj turfjm turfjt turfjc turfjw turfjwa turfjwc turfx turfxng turfxw turfxwng"
        let expected = "barf barfs bạ bạn bạm bạt bạc bạch bạp bạo bặ bặn bặt bặc bậ bận bật bậc bã bãn bãng bão nerf nerfs nẹ nệ nện nệm nệt nẽ nễ nễn serf serfs sẹ sệ sện sệt sẽ sễ kerf kẹ kệ kện kệt kệnh kẽ kễ kễnh surf surfs sụ sụn sụt sụp sục sự sực sũ sũng sữ sữa sững turf turfs tụ tụm tụt tục tự tựa tực tũ tũng tữ tững"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_406_vietnamese_fc_fp_xc_xp_midword_acute_and_dot_tone_override_unlatch() {
        let input = "bafcs bafcj cafcs cafcsa cafcsw cafcj khafcs khafcj mafcs mafcj tafcs tafcj xafcs xafcj bafps bafpj cafps cafpsa cafpsw cafpj dafpsd dafpjd gafps gafpj hafps hafpj lafps lafpj mafps mafpj nafps nafpj phafps phafpj rafps rafpj safps safpj tafps tafpj bofcs bofcso bofcj cofcs cofcso cofcj gofcs gofcso gofcj hofcs hofcso hofcj lofcs lofcso lofcj mofcs mofcso mofcj sofcs sofcj tofcs tofcj bofps bofpso bofpsw bofpj gofps gofpso gofpsw gofpj hofps hofpso hofpsw hofpjo hofpjw chufcs chufcj dufcsd dufcjd hufcs hufcj khufcs khufcj lufcs lufcj mufcs mufcj phufcs phufcj sufcs sufcsw sufcj tufcs tufcj thufcs thufcj xufcs xufcj"
        let expected = "bác bạc các cấc cắc cạc khác khạc mác mạc tác tạc xác xạc báp bạp cáp cấp cắp cạp đáp đạp gáp gạp háp hạp láp lạp máp mạp náp nạp pháp phạm ráp rạp sáp sạp táp tạp bóc bốc bọc cóc cốc cọc góc gốc gọc hóc hốc học lóc lốc lọc móc mốc mọc sóc sọc tóc tọc bóp bốp bớp bọp góp gốp gớp gọp hóp hốp hớp hộp hợp chúc chục đúc đục húc hục khúc khục lúc lục múc mục phúc phục súc sức sục túc tục thúc thục xúc xục".replacingOccurrences(of: "phạm", with: "phạp")
        assertBuffer(input, equals: expected)
    }

    func test_tier4_407_vietnamese_ft_xt_midword_acute_tone_override_and_english_plural_preservation() {
        let input = "rafts lofts tufts thefts gifts lifts rifts sifts texts bafts baftsa baftsw cafts caftsa caftsw dafts daftsd daftsad daftswd hafts khafts lafts mafts nafts phafts safts tafts thafts vafts xafts bofts cofts coftso coftsw dofts doftsd gofts hofts mofts moftso moftsw nofts rofts softs softso softsw bufts cufts chufts dufts duftsd hufts lufts mufts nufts phufts rufts sufts suftsw vufts befts beftse chefts cheftse defts deftsd deftsed ghefts kefts keftse khefts mefts meftse nefts neftse phefts refts sefts tefts teftse vefts xefts xeftse bifts chifts difts diftsd hifts kifts khifts mifts nifts phifts tifts thifts vifts xifts caxts caxtsa caxtsw coxts coxtso coxtsw cuxts cuxtsw lexts lextse lixts"
        let expected = "rafts lofts tufts thefts gifts lifts rifts sifts texts bát bất bắt cát cất cắt dát đát đất đắt hát khát lát mát nát phát sát tát thát vát xát bót cót cốt cớt dót đót gót hót mót mốt mớt nót rót sót sốt sớt bút cút chút dút đút hút lút mút nút phút rút sút sứt vút bét bết chét chết dét đét đết ghét két kết khét mét mết nét nết phét rét sét tét tết vét xét xết bít chít dít đít hít kít khít mít nít phít tít thít vít xít cát cất cắt cót cốt cớt cút cứt lét lết lít"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_408_english_and_vietnamese_rch_fch_xch_acute_and_dot_tone_override_unlatch() {
        let input = "arch perch merch march marchs marchj barchs barchj carchs carchj garchj harchs harchj kharchs kharchj larchs larchj narchs narchj pharchs pharchj rarchs rarchj sarchs sarchj tarchs tarchj tharchs tharchj varchs varchj xarchs xarchj birchs birchj chirchj dirchs dirchsd dirchj dirchjd hirchs hirchj kirchs kirchj khirchs khirchj lirchs lirchj mirchs mirchj nhirchs nhirchj phirchs phirchj rirchs rirchj sirchs sirchj tirchs tirchj thirchs thirchj virchs virchj xirchs xirchj safchs safchj lifchs lifchj archj irchs irchj"
        let expected = "arch perch merch march mách mạch bách bạch cách cạch gạch hách hạch khách khạch lách lạch nách nạch phách phạch rách rạch sách sạch tách tạch thách thạch vách vạch xách xạch bích bịch chịch dích đích dịch địch hích hịch kích kịch khích khịch lích lịch mích mịch nhích nhịch phích phịch rích rịch sích sịch tích tịch thích thịch vích vịch xích xịch sách sạch lích lịch ạch ích ịch"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_409_scenario67_trilingual_gifts_texts_surf_march_and_vietnamese_tu_su_sach_ke_khach_chat() {
        let input = "Trong tháng march, sau khi gửi các món quà gifts và tin nhắn texts cho những người bạn (barfjn) đam mê surf sóng, chúng tôi đã tự (turfjw) mình sắp xếp lại kệ (kerfje) sách (sarchs) thật sạch (sarchj) sẽ để đón tiếp quý khách (kharchs) đến hợp (hofpjw) tác thực sự (surfjw) hiệu quả!"
        let expected = "Trong tháng march, sau khi gửi các món quà gifts và tin nhắn texts cho những người bạn (bạn) đam mê surf sóng, chúng tôi đã tự (tự) mình sắp xếp lại kệ (kệ) sách (sách) thật sạch (sạch) sẽ để đón tiếp quý khách (khách) đến hợp (hợp) tác thực sự (sự) hiệu quả!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 60: Vietnamese Phrase Collocations (cảm/biết/nhớ ơn, bàn chải, con lăn, thỏa mãn, giun sán, cà rốt, có thể, như thế), Symmetric ă->â / ơ->ô Override, and chair/lair/boron/moron/beset/reset/in Tone Unlatch
    // =========================================================================

    func test_tier4_410_vietnamese_collocation_phrases_on_chai_lan_man_san_rot_the_au_den_ret() {
        let input = "camr own cams own bieets own nhows own mang own ddeefn own trar own taj own voo own lafm own thaays owns ngans owns phats owns banf chair caay chair luwowcj chair mays chair ddang chair nois lair con lawn caay lawn sown lawn ddang lawn thoar manx vieen manx baats manx tuwj manx giun sans taayr sans thuoocs sans caf roots cur roots ddooms looms cos there khoong there cuj there taajp there cow there nhuw these xu these uwu these thay these lafm aura chayj aura ngooi defend bawts defend con reset bawns toes tung toes ddor hoes"
        let expected = "cảm ơn cám ơn biết ơn nhớ ơn mang ơn đền ơn trả ơn tạ ơn vô ơn làm ơn thấy ớn ngán ớn phát ớn bàn chải cây chải lược chải máy chải đang chải nói lải con lăn cây lăn sơn lăn đang lăn thỏa mãn viên mãn bất mãn tự mãn giun sán tẩy sán thuốc sán cà rốt củ rốt đốm lốm có thể không thể cụ thể tập thể cơ thể như thế xu thế ưu thế thay thế làm ẩu chạy ẩu ngôi đền bắt đền con rết bắn tóe tung tóe đỏ hóe"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_411_english_awn_own_awns_owns_circumflex_and_midword_tone_override_unlatch() {
        let input = "dawn dawna dawnad dawns dawnsa dawnsad dawnsf dawnsfd dawnsr dawnsrd dawnsx dawnsxd dawnsj dawnsjd lawn lawna lawnag lawns lawnsa lawnsag lawnsf lawnsr lawnsx lawnsj down downo downod downs downso downsod downsf downsfd downsr downsrd downsx downsxd downsj downsjd gown gowno gowns gownso gownsf gownsr gownsx gownsj town towno towns townso townsf townsr townsx townsj own owno owns ownso ownsog ownsf ownsr ownsx ownsj"
        let expected = "dawn dân đân dawns dấn đấn dằn đằn dẳn đẳn dẵn đẵn dặn đặn lawn lân lâng lawns lấn lấng lằn lẳn lẵn lặn down dôn đôn downs dốn đốn dờn đờn dởn đởn dỡn đỡn dợn đợn gown gôn gowns gốn gờn gởn gỡn gợn town tôn towns tốn tờn tởn tỡn tợn own ôn owns ốn ống ờn ởn ỡn ợn"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_412_english_chair_lair_hairs_chairs_lairs_airs_tone_override_unlatch() {
        let input = "chair chairs chairf chairj chairx lair lairs lairf lairj lairx hairs hairsf hairsj hairsx chairsf chairsj chairsx lairsf lairsj lairsx airs airsf airsj airsx"
        let expected = "chair chairs chài chại chãi lair lairs lài lại lãi hairs hài hại hãi chài chại chãi lài lại lãi airs ài ại ãi"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_413_english_boron_moron_morons_beset_reset_in_tone_override_unlatch() {
        let input = "boron borons boronsg boronf boronfg boronj boronjg boronx boronxg moron morons moronf moronfg moronj moronjg moronx moronxg moronsw moronsg moronsf moronsj moronsx beset besets besetj reset resets resetj in info into inside install instead instant insert insist infant infect infer ins inf inr inx inj"
        let expected = "boron bốn bống bồn bồng bộn bộng bỗn bỗng moron morons mồn mồng mộn mộng mỗn mỗng mớn mống mồn mộn mỗn beset besets bệt reset resets rệt in info into inside install instead instant insert insist infant infect infer ín ìn ỉn ĩn ịn"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_414_scenario68_trilingual_install_inside_reset_and_vietnamese_biet_on_ban_chai_the_he_chat() {
        let input = "Sau khi install gói cập nhật inside hệ thống và reset cấu hình, cả tập thể (taajp there) đều biết ơn (bieets own) sự hỗ trợ kịp thời để hoàn thành mục tiêu một cách thỏa mãn (thoar manx), mua thêm bàn chải (banf chair) và con lăn (con lawn) sơn tường mới với sự thay đổi rõ rệt (resetj) như thế (nhuw these)!"
        let expected = "Sau khi install gói cập nhật inside hệ thống và reset cấu hình, cả tập thể (tập thể) đều biết ơn (biết ơn) sự hỗ trợ kịp thời để hoàn thành mục tiêu một cách thỏa mãn (thỏa mãn), mua thêm bàn chải (bàn chải) và con lăn (con lăn) sơn tường mới với sự thay đổi rõ rệt (rệt) như thế (như thế)!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 61: Vietnamese góa/noãn Orthography, Romaji & English Phrase Collocations (say sưa, gỗ sưa, củ nưa, cái giỏ, nước ối, trôi nổi, ăn sổi, hoa dơn, rau dớn, lớn tớn, đánh vảy), and Plural Keyword Tone Override Unlatch
    // =========================================================================

    func test_tier4_415_vietnamese_goa_noan_orthography_and_romaji_english_phrase_collocations() {
        let input = "baf goas goas phuj goas buaj owr goas noanx noaxn noanx caauf noanx safo phongs noanx gora gosa goats goal nosa say suwa goox suwa caay suwa hoa suwa hoof suwa cur nuwa bootj nuwa awn buwa chos sura tieengs sura nguyeenf rura chuwir rura cais giro chieecs giro lafn giro cais gire taams gire boong gise luas gise nuwowcs osoi tuis osoi vowx osoi trooi noroi chifm noroi awn soroi muoois soroi hoa down lay down cur down rau downs caay downs noomj rau downs lowns towns chayj lowns towns ddanhs vary caoj vary trocs vary"
        let expected = "bà góa góa phụ góa bụa ở góa noãn noãn noãn cầu noãn sào phóng noãn gora gosa goats goal nosa say sưa gỗ sưa cây sưa hoa sưa hồ suwa củ nưa bột nưa ăn bưa chó sủa tiếng sủa nguyền rủa chửi rủa cái giỏ chiếc giỏ làn giỏ cái giẻ tấm giẻ bông gié lúa gié nước ối túi ối vỡ ối trôi nổi chìm nổi ăn sổi muối sổi hoa dơn lay dơn củ dơn rau dớn cây dớn nộm rau dớn lớn tớn chạy lớn tớn đánh vảy cạo vảy tróc vảy"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_416_english_plural_ooms_oons_eems_eens_tone_override_unlatch() {
        let input = "booms boomsf boomsr boomsx boomsj dooms doomsf doomsfd doomsr doomsrd doomsx doomsxd doomsj doomsjd looms loomsf loomsr loomsx loomsj rooms roomsf roomsr roomsx roomsj goons goonsf goonsr goonsx goonsj loons loonsf loonsr loonsx loonsj moons moonsf moonsr moonsx moonsj nonos nonosf nonosr nonosx nonosj deems deemsf deemsfd deemsr deemsrd deemsx deemsxd deemsj deemsjd seems seemsf seemsr seemsx seemsj teems teemsf teemsr teemsx teemsj keens keensf keensr keensx keensj teens teensf teensr teensx teensj queens queensf queensr queensx queensj mamas mamasf mamasr mamasx mamasj memes memesf memesr memesx memesj themes themesf themesr themesx themesj donors donorsf donorsfd donorsr donorsrd donorsx donorsxd donorsj donorsjd honors honorsf honorsr honorsx honorsj"
        let expected = "booms bồm bổm bỗm bộm dooms dồm đồm dổm đổm dỗm đỗm dộm độm looms lồm lổm lỗm lộm rooms rồm rổm rỗm rộm goons gồn gổn gỗn gộn loons lồn lổn lỗn lộn moons mồn mổn mỗn mộn nonos nồn nổn nỗn nộn deems dềm đềm dểm đểm dễm đễm dệm đệm seems sềm sểm sễm sệm teems tềm tểm tễm tệm keens kền kển kễn kện teens tền tển tễn tện queens quền quển quễn quện mamas mầm mẩm mẫm mậm memes mềm mểm mễm mệm themes thềm thểm thễm thệm donors dồn đồn dổn đổn dỗn đỗn dộn độn honors hồn hổn hỗn hộn"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_417_english_stop_coda_plurals_and_stems_dot_tone_override_unlatch() {
        let input = "keeps keepsj deeps deepsj deepsjd cheeps cheepsj noops noopsj goops goopsj troops troopsj topos toposj gotos gotosj photos photosj datas datasj datasjd basta bastaj rasta rastaj coats coatsj coast coastj diets dietsj dietsjd quiets quietsj nieces niecesj sorts sortsj burst burstj worst worstj thirst thirstj swops swopsj"
        let expected = "keeps kệp deeps dệp đệp cheeps chệp noops nộp goops gộp troops trộp topos tộp gotos gột photos phột datas dật đật basta bật rasta rật coats coạt coast coạt diets diệt điệt quiets quiệt nieces niệc sorts sọt burst bụt worst ượt thirst thịt swops sượp"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_418_english_oxen_vixen_siren_sirens_risen_tureen_chosen_tone_override_unlatch() {
        let input = "oxen oxenf oxenr oxenj oxens vixen vixenf vixenr vixenj vixens vixensf vixensr vixensx vixensj siren sirenf sirenx sirenj sirens sirensf sirensr sirensx sirensj risen risenf risenr risenx risenj tureen tureenf tureenx tureenj tureens tureensf tureensr tureensx tureensj chosen chosenf chosenr chosenx chosenj"
        let expected = "oxen oèn oẻn oẹn oén vixen viền viển viện vixens viền viển viễn viện siren siền siễn siện sirens siền siển siễn siện risen riền riển riễn riện tureen tuền tuễn tuện tureens tuền tuển tuễn tuện chosen choèn choẻn choẽn choẹn"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_419_scenario69_trilingual_suwa_photos_rooms_and_vietnamese_say_sua_goa_phu_noan_cau_chat() {
        let input = "Trong chuyến đi ngắm hồ suwa và chụp photos các rooms cổ kính, đoàn nghiên cứu say sưa (say suwa) tìm hiểu về gỗ sưa (goox suwa), nếm thử nộm rau dớn (rau downs), ngắm hoa dơn (hoa down) bên chiếc giỏ (chieecs giro) mây của bà góa (baf goas), đồng thời tổng hợp (goopsj) tài liệu về tế bào noãn cầu (noanx caauf) và dịch nước ối (nuwowcs osoi) tại bệnh viện (vixenj)!"
        let expected = "Trong chuyến đi ngắm hồ suwa và chụp photos các rooms cổ kính, đoàn nghiên cứu say sưa (say sưa) tìm hiểu về gỗ sưa (gỗ sưa), nếm thử nộm rau dớn (rau dớn), ngắm hoa dơn (hoa dơn) bên chiếc giỏ (chiếc giỏ) mây của bà góa (bà góa), đồng thời tổng hợp (gộp) tài liệu về tế bào noãn cầu (noãn cầu) và dịch nước ối (nước ối) tại bệnh viện (viện)!"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_420_vietnamese_collocation_phrases_ban_tan_bun_tun_bon_con_dom_bem() {
        let input = "barn cow barn vawn barn phieen barn kichj barn bieen barn xuaats barn nguyeen barn nhaatj barn tarn ddi tarn booj keo tarn nhietj quatj tarn nhietj vieets tarn manj burn tay chaan burn rurn sowj burn rurn keo kietj burn xirn tinhs burn xirn turn tinhs toans turn murn nhor nhawtj turn murn born tinhs born xern keo kietj born xern corn nhor corn bes corn dorm hangf dorm ddoof dorm pin dorm berm awn nois berm meps miengj berm meps toes luwar toes"
        let expected = "barn cơ bản văn bản phiên bản kịch bản biên bản xuất bản nguyên bản nhật bản tarn đi tản bộ keo tản nhiệt quạt tản nhiệt viết tản mạn burn tay chân bủn rủn sợ bủn rủn keo kiệt bủn xỉn tính bủn xỉn turn tính toán tủn mủn nhỏ nhặt tủn mủn born tính bỏn xẻn keo kiệt bỏn xẻn corn nhỏ cỏn bé cỏn dorm hàng dỏm đồ dỏm pin dỏm berm ăn nói bẻm mép miệng bẻm mép toes lửa tóe"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_421_english_plural_rns_rms_midword_tone_override_unlatch() {
        let input = "barns barnsf barnsr barnsx barnsj darns darnsf darnsfd darnsr darnsrd darnsx darnsxd darnsj darnsjd tarns tarnsf tarnsr tarnsx tarnsj horns hornsf hornsr hornsx hornsj thorns thornsf thornsr thornsx thornsj morns mornsf mornsr mornsx mornsj borns bornsf bornsr bornsx bornsj corns cornsf cornsr cornsx cornsj torns tornsf tornsr tornsx tornsj burns burnsf burnsr burnsx burnsj turns turnsf turnsr turnsx turnsj churns churnsf churnsr churnsx churnsj urns urnsf urnsr urnsx urnsj harms harmsf harmsr harmsx harmsj charms charmsf charmsr charmsx charmsj norms normsf normsr normsx normsj corms cormsf cormsr cormsx cormsj dorms dormsf dormsfd dormsr dormsrd dormsx dormsxd dormsj dormsjd berms bermsf bermsr bermsx bermsj terms termsf termsr termsx termsj kerns kernsf kernsr kernsx kernsj terns ternsf ternsr ternsx ternsj"
        let expected = "barns bàn bản bãn bạn darns dàn đàn dản đản dãn đãn dạn đạn tarns tàn tản tãn tạn horns hòn hỏn hõn họn thorns thòn thỏn thõn thọn morns mòn mỏn mõn mọn borns bòn bỏn bõn bọn corns còn cỏn cõn cọn torns tòn tỏn tõn tọn burns bùn bủn bũn bụn turns tùn tủn tũn tụn churns chùn chủn chũn chụn urns ùn ủn ũn ụn harms hàm hảm hãm hạm charms chàm chảm chãm chạm norms nòm nỏm nõm nọm corms còm cỏm cõm cọm dorms dòm đòm dỏm đỏm dõm đõm dọm đọm berms bèm bẻm bẽm bẹm terms tèm tẻm tẽm tẹm kerns kèn kẻn kẽn kẹn terns tèn tẻn tẽn tẹn"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_422_english_plural_oors_oofs_odos_ojos_adas_aras_tone_override_unlatch() {
        let input = "dodos dodosf dodosr dodosx dodosj dojos dojosf dojosfd dojosr dojosrd dojosx dojosxd dojosj dojosjd rojos rojosf rojosr rojosx rojosj loofs loofsf loofsr loofsx loofsj oofs oofsf oofsr oofsx oofsj hoofs hoofsf hoofsr hoofsx hoofsj roofs roofsf roofsr roofsx roofsj goofs goofsf goofsr goofsx goofsj moors moorsf moorsr moorsx moorsj boors boorsf boorsr boorsx boorsj doors doorsf doorsfd doorsr doorsrd doorsx doorsxd doorsj doorsjd dadas dadasf dadasr dadasx dadasj charas charasf charasr charasx charasj"
        let expected = "dodos đồ đổ đỗ độ dojos dồ đồ dổ đổ dỗ đỗ dộ độ rojos rồ rổ rỗ rộ loofs lồ lổ lỗ lộ oofs ồ ổ ỗ ộ hoofs hồ hổ hỗ hộ roofs rồ rổ rỗ rộ goofs gồ gổ gỗ gộ moors mồ mổ mỗ mộ boors bồ bổ bỗ bộ doors dồ đồ dổ đổ dỗ đỗ dộ độ dadas đầ đẩ đẫ đậ charas chầ chẩ chẫ chậ"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_423_english_plural_eers_eefs_ees_uys_oars_oafs_oifs_oirs_aifs_iars_toes_hoes_does_unlatch() {
        let input = "leers leersf leersr leersx leersj seers seersf seersr seersx seersj cheers cheersf cheersr cheersx cheersj veers veersf veersr veersx veersj reefs reefsf reefsr reefsx reefsj beefs beefsf beefsr beefsx beefsj beers beersf beersr beersx beersj deers deersf deersfd deersr deersrd deersx deersxd deersj deersjd trees treesf treesr treesx treesj sees seesf seesr seesx seesj buys buysf buysr buysx buysj guys guysf guysr guysx guysj soars soarsf soarsr soarsx soarsj oars oarsf oarsr oarsx oarsj loafs loafsf loafsr loafsx loafsj oafs oafsf oafsr oafsx oafsj coifs coifsf coifsr coifsx coifsj choirs choirsf choirsr choirsx choirsj naifs naifsf naifsr naifsx naifsj liars liarsf liarsr liarsx liarsj toes toesf toesr toesx toesj hoes hoesf hoesr hoesx hoesj hairs hairsr chairs chairsr lairs lairsr airs airsr morons moronsr"
        let expected = "leers lề lể lễ lệ seers sề sể sễ sệ cheers chề chể chễ chệ veers về vể vễ vệ reefs rề rể rễ rệ beefs bề bể bễ bệ beers bề bể bễ bệ deers dề đề dể để dễ đễ dệ đệ trees trề trể trễ trệ sees sề sể sễ sệ buys bùy bủy bũy bụy guys gùy gủy gũy gụy soars sòa sỏa sõa sọa oars òa ỏa õa ọa loafs lòa lỏa lõa lọa oafs òa ỏa õa ọa coifs còi cỏi cõi cọi choirs chòi chỏi chõi chọi naifs nài nải nãi nại liars lìa lỉa lĩa lịa toes tòe tỏe tõe tọe hoes hòe hỏe hõe họe hairs hải chairs chải lairs lải airs ải morons mổn"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_424_scenario70_trilingual_burn_turn_dorm_and_vietnamese_co_ban_tan_nhiet_bun_run_hang_dom_chat() {
        let input = "Trong phòng dorm, mình kiểm tra phiên bản (phieen barn) cơ bản (cow barn) của quạt tản nhiệt (quatj tarn nhietj) để máy không bị burn khi render: tránh mua hàng dỏm (hangf dorm) hay pin dỏm (pin dorm), đừng tính toán tủn mủn (tinhs toans turn murn) hay keo kiệt bỏn xẻn (keo kietj born xern) kẻo lúc máy hỏng lại sợ bủn rủn (sowj burn rurn) cả tay chân!"
        let expected = "Trong phòng dorm, mình kiểm tra phiên bản (phiên bản) cơ bản (cơ bản) của quạt tản nhiệt (quạt tản nhiệt) để máy không bị burn khi render: tránh mua hàng dỏm (hàng dỏm) hay pin dỏm (pin dỏm), đừng tính toán tủn mủn (tính toán tủn mủn) hay keo kiệt bỏn xẻn (keo kiệt bỏn xẻn) kẻo lúc máy hỏng lại sợ bủn rủn (sợ bủn rủn) cả tay chân!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 63: Vietnamese Diphthong Collocations (-eo/-au/-ui/-iu/-ai/-ao) and Medial-Tone Diphthong Override Unlatch
    // =========================================================================

    func test_tier4_425_vietnamese_collocation_phrases_heo_neo_keo_meo_beo_heo_teo_neo_sau_bau_nau_tau() {
        let input = "hero nowi hero lanhs vungf hero lanhs vawngs hero cheets hero nero moij nero dduwowngf khawps nero muoon nero keso cais keso looi keso daay keso khoas keso meso mops meso mawtj meso beso chaats beso thitj beso raats beso heso hoa heso laas heso khoo heso teso tis teso neso daay neso chawngf neso sasu thuws sasu thangs sasu soos sasu muwowif sasu basu quys basu kho basu chaau basu nasu aarn nasu nuwowng nasu tasu goox tasu caay tasu".replacingOccurrences(of: "laas", with: "las")
        let expected = "hero nơi hẻo lánh vùng hẻo lánh vắng hẻo chết hẻo nero mọi nẻo đường khắp nẻo muôn nẻo keso cái kéo lôi kéo dây kéo khóa kéo meso móp méo mặt méo beso chất béo thịt béo rất béo heso hoa héo lá héo khô héo teso tí téo neso dây néo chằng néo sasu thứ sáu tháng sáu số sáu mười sáu basu quý báu kho báu châu báu nasu ẩn náu nương náu tasu gỗ táu cây táu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_426_vietnamese_collocation_phrases_tui_mui_rui_hui_sui_rai_sao_biu_biu_niu_riu_riu_niu() {
        let input = "turi buoonf turi ngaamj nguif turi thaan muri thaays muri longf chanhj longf muri longf ruri may ruri xui ruri vaanj ruri huri hawts huri beenhj huri suri vieen suri thuoocs suri awn suri caro rari muwa rari racs nawmf rari racs saso chim saso thooir saso tieengs saso biru def biru chee bai def biru biju baanj biju vuwowngs biju niju nungx niju hay nungx niju riju raauf riju buoonf raauf riju risu lius risu roonj risu nisu bams nisu giuwx nisu"
        let expected = "turi buồn tủi ngậm ngùi tủi thân muri thấy mủi lòng chạnh lòng mủi lòng ruri may rủi xui rủi vận rủi huri hắt hủi bệnh hủi suri viên sủi thuốc sủi ăn sủi cảo rari mưa rải rác nằm rải rác saso chim sáo thổi sáo tiếng sáo biru dè bỉu chê bai dè bỉu biju bận bịu vướng bịu niju nũng nịu hay nũng nịu riju rầu rịu buồn rầu rịu risu líu ríu rộn ríu nisu bám níu giữ níu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_427_romaji_and_english_ero_eso_maso_saso_rari_nori_rori_tone_override_unlatch() {
        let input = "hero herof herox heroj nero nerof nerox neroj rero rerof rerox reroj keso kesof kesor kesox kesoj meso mesof mesor mesox mesoj neso nesof nesor nesox nesoj heso hesof hesor hesox hesoj teso tesof tesor tesox tesoj deso desof desor desox desoj beso besof besor besox besoj maso masof masor masox masoj saso sasof sasor sasox sasoj rari rarif raris rarix rarij nori norif noris norix norij rori rorif roris rorix rorij"
        let expected = "hero hèo hẽo hẹo nero nèo nẽo nẹo rero rèo rẽo rẹo keso kèo kẻo kẽo kẹo meso mèo mẻo mẽo mẹo neso nèo nẻo nẽo nẹo heso hèo hẻo hẽo hẹo teso tèo tẻo tẽo tẹo deso dèo dẻo dẽo dẹo beso bèo bẻo bẽo bẹo maso mào mảo mão mạo saso sào sảo são sạo rari rài rái rãi rại nori nòi nói nõi nọi rori ròi rói rõi rọi"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_428_romaji_uri_iru_isu_ifu_iju_aru_asu_tone_override_unlatch() {
        let input = "muri murif muris murix murij suri surif suris surix surij turi turif turis turix turij nuri nurif nuris nurix nurij buri burif buris burix burij duri durif duris durix durij huri hurif huris hurix hurij ruri rurif ruris rurix rurij churi churif churis churix churij biru biruf birus birux biruj miru miruf mirus mirux miruj niru niruf nirus nirux niruj chiru chiruf chirus chirux chiruj risu risuf risur risux risuj nisu nisuf nisur nisux nisuj misu misuf misur misux misuj hisu hisuf hisur hisux hisuj biju bijuf bijus bijur bijux niju nijuf nijus nijur nijux riju rijuf rijus rijur rijux haru haruf harus harux haruj maru maruf marus marux maruj taru taruf tarus tarux taruj baru baruf barus barux baruj basu basuf basur basux basuj sasu sasuf sasur sasux sasuj nasu nasuf nasur nasux nasuj tasu tasuf tasur tasux tasuj"
        let expected = "muri mùi múi mũi mụi suri sùi súi sũi sụi turi tùi túi tũi tụi nuri nùi núi nũi nụi buri bùi búi bũi bụi duri dùi dúi dũi dụi huri hùi húi hũi hụi ruri rùi rúi rũi rụi churi chùi chúi chũi chụi biru bìu bíu bĩu bịu miru mìu míu mĩu mịu niru nìu níu nĩu nịu chiru chìu chíu chĩu chịu risu rìu rỉu rĩu rịu nisu nìu nỉu nĩu nịu misu mìu mỉu mĩu mịu hisu hìu hỉu hĩu hịu biju bìu bíu bỉu bĩu niju nìu níu nỉu nĩu riju rìu ríu rỉu rĩu haru hàu háu hãu hạu maru màu máu mãu mạu taru tàu táu tãu tạu baru bàu báu bãu bạu basu bàu bảu bãu bạu sasu sàu sảu sãu sạu nasu nàu nảu nãu nạu tasu tàu tảu tãu tạu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_429_scenario71_trilingual_hero_sasuke_naruto_and_vietnamese_heo_lanh_thu_sau_quy_bau_ban_biu_chat() {
        let input = "Vào ngày thứ sáu (thuws sasu), dù công việc đang rất bận bịu (baanj biju) nhưng cả nhóm vẫn mang theo cái kéo (cais keso), viên thuốc sủi (thuoocs suri) và bản đồ kho báu (kho basu) để vượt qua mọi nẻo đường (moij nero dduwowngf) mưa rải rác (muwa rari racs) đến thăm ngôi làng vùng hẻo lánh (vungf hero lanhs), nơi có tiếng chim sáo (chim saso) kêu líu ríu (lius risu) như trong phim về nhân vật hero naruto và sasuke!"
        let expected = "Vào ngày thứ sáu (thứ sáu), dù công việc đang rất bận bịu (bận bịu) nhưng cả nhóm vẫn mang theo cái kéo (cái kéo), viên thuốc sủi (thuốc sủi) và bản đồ kho báu (kho báu) để vượt qua mọi nẻo đường (mọi nẻo đường) mưa rải rác (mưa rải rác) đến thăm ngôi làng vùng hẻo lánh (vùng hẻo lánh), nơi có tiếng chim sáo (chim sáo) kêu líu ríu (líu ríu) như trong phim về nhân vật hero naruto và sasuke!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 64: Medial-Tone góa/noãn, -oa/-ua/-ê/-ô Collocations, and C-o-[rsfjx]-o / C-e-[rsfjx]-e / -ura / -ora / -osa Tone Override Unlatch
    // =========================================================================

    func test_tier4_430_vietnamese_medial_tone_goa_noan_and_oa_ua_e_o_collocations() {
        let input = "gosa baf gosa owr gosa noxan caauf nora norax noraxn tosa chayj tosa bawns tosa lora tawms lora bura vaay bura giawng bura tura mocj tua tura gai tua tura kere nghe kere baats kere ddangs kere bere bowi bere boons bere nere kinhs nere trongj nere rere con rere changf rere horo con horo xaaus horo toro chim toro gioox toro soro cuoons soro cuwar soro noro chays noro bungf noro moro ca moro banf moro boro booif boro thuoocs boro hofo mawtj hofo bowf hofo bofo chim bofo caau"
        let expected = "gosa bà góa ở góa noãn cầu nora nõa noãn tosa chạy tóa bắn tóa lora tắm lỏa bura vây bủa giăng bủa tura mọc tua tủa gai tua tủa kere nghe kể bất kể đáng kể bere bơi bể bốn bể nere kính nể trọng nể rere con rể chàng rể horo con hổ xấu hổ toro chim tổ giỗ tổ soro cuốn sổ cửa sổ noro cháy nổ bùng nổ moro ca mổ bàn mổ boro bồi bổ thuốc bổ hofo mặt hồ bờ hồ bofo chim bồ câu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_431_romaji_ura_ora_osa_sofa_tone_override_unlatch() {
        let input = "mura muraf muras murax muraj hura huraf huras hurax huraj sura suraf suras surax suraj tura turaf turas turax turaj nura nuraf nuras nurax nuraj bura buraf buras burax buraj gura guraf guras gurax guraj dura duraf durafd duras durasd durax duraxd duraj durajd rura ruraf ruras rurax ruraj chura churaf churas churax churaj sora soraf soras sorax soraj lora loraf loras lorax loraj dora doraf dorafd doras dorasd dorax doraxd doraj dorajd sosa sosaf sosar sosax sosaj tosa tosaf tosar tosax tosaj dosa dosaf dosafd dosar dosard dosax dosaxd dosaj dosajd sofa sofar sofax sofaj"
        let expected = "mura mùa múa mũa mụa hura hùa húa hũa hụa sura sùa súa sũa sụa tura tùa túa tũa tụa nura nùa núa nũa nụa bura bùa búa bũa bụa gura gùa gúa gũa gụa dura dùa đùa dúa đúa dũa đũa dụa đụa rura rùa rúa rũa rụa chura chùa chúa chũa chụa sora sòa sóa sõa sọa lora lòa lóa lõa lọa dora dòa đòa dóa đóa dõa đõa dọa đọa sosa sòa sỏa sõa sọa tosa tòa tỏa tõa tọa dosa dòa đòa dỏa đỏa dõa đõa dọa đọa sofa sỏa sõa sọa"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_432_romaji_coro_coso_cofo_cojo_coxo_tone_override_unlatch() {
        let input = "horo horof horox horoj moro morof morox moroj toro torof torox toroj soro sorof sorox soroj noro norof norox noroj boro borof borox boroj goro gorof gorox goroj doro dorof dorofd dorox doroxd doroj dorojd roro rorof rorox roroj hoso hosof hosor hosox hosoj toso tosof tosor tosox tosoj moso mosof mosor mosox mosoj noso nosof nosor nosox nosoj hofo hofos hofor hofox hofoj bofo bofos bofor bofox bofoj tofo tofos tofor tofox tofoj dofo dofos dofosd dofor doford dofox dofoxd dofoj dofojd"
        let expected = "horo hồ hỗ hộ moro mồ mỗ mộ toro tồ tỗ tộ soro sồ sỗ sộ noro nồ nỗ nộ boro bồ bỗ bộ goro gồ gỗ gộ doro dồ đồ dỗ đỗ dộ độ roro rồ rỗ rộ hoso hồ hổ hỗ hộ toso tồ tổ tỗ tộ moso mồ mổ mỗ mộ noso nồ nổ nỗ nộ hofo hố hổ hỗ hộ bofo bố bổ bỗ bộ tofo tố tổ tỗ tộ dofo dố đố dổ đổ dỗ đỗ dộ độ"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_433_romaji_cere_cese_cefe_ceje_tone_override_unlatch_and_english_preservation() {
        let input = "tere teref terex terej kere keref kerex kerej nere neref nerex nerej bere beref berex berej dere deref derefd derex derexd derej derejd rere reref rerex rerej chere cheref cherex cherej tese tesef teser tesex tesej kese kesef keser kesex kesej mese mesef meser mesex mesej nese nesef neser nesex nesej hese hesef heser hesex hesej sese sesef seser sesex sesej bese besef beser besex besej dese desef desefd desex desexd desej desejd rese resef resex resej chese chesef cheser chesex chesej kefe kefes kefer kefex kefej defe defes defesd defex defexd defej defejd defer defers refer refers reset beset"
        let expected = "tere tề tễ tệ kere kề kễ kệ nere nề nễ nệ bere bề bễ bệ dere dề đề dễ đễ dệ đệ rere rề rễ rệ chere chề chễ chệ tese tề tể tễ tệ kese kề kể kễ kệ mese mề mể mễ mệ nese nề nể nễ nệ hese hề hể hễ hệ sese sề sể sễ sệ bese bề bể bễ bệ dese dề đề dễ đễ dệ đệ rese rề rễ rệ chese chề chể chễ chệ kefe kế kể kễ kệ defe dế đế dễ đễ dệ đệ defer defers refer refers reset beset"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_434_scenario72_trilingual_sofa_dora_defer_and_vietnamese_goa_noan_cua_so_mat_ho_chat() {
        let input = "Ngồi trên ghế sofa bên cửa sổ (cuwar soro) nhìn ra mặt hồ (mawtj hofo) nơi đàn chim bồ câu (chim bofo caau) đang bay lượn, bác sĩ giải thích về tế bào noãn cầu (noxan caauf) cho bà góa (baf gosa) và chàng rể (changf rere) đáng kể (ddangs kere): dù gai xương rồng mọc tua tủa (mocj tua tura) quanh đôi đũa (duraxd) tre và đóa (dorasd) hoa hồng, chúng ta không nên defer ca mổ (ca moro) để lan tỏa (tosar) niềm vui tại vùng tosa!"
        let expected = "Ngồi trên ghế sofa bên cửa sổ (cửa sổ) nhìn ra mặt hồ (mặt hồ) nơi đàn chim bồ câu (chim bồ câu) đang bay lượn, bác sĩ giải thích về tế bào noãn cầu (noãn cầu) cho bà góa (bà góa) và chàng rể (chàng rể) đáng kể (đáng kể): dù gai xương rồng mọc tua tủa (mọc tua tủa) quanh đôi đũa (đũa) tre và đóa (đóa) hoa hồng, chúng ta không nên defer ca mổ (ca mổ) để lan tỏa (tỏa) niềm vui tại vùng tosa!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 65: -ê/-ô Collocations, C-a-[rsfjx]-a Tone Override, C-o-j-o / C-e-j-e Acute Override, and honor/donor Tone Override
    // =========================================================================

    func test_tier4_435_vietnamese_collocation_phrases_te_ke_be_ne_he_te_be_ke_te_he_ke() {
        let input = "tese kinh tese quoocs tese thuwcj tese y tese kese thieets kese thoongs kese nhieetj kese bese mej bese boongf bese leex bese nefe nawngj nefe thowj nefe hefe khoong hefe chawrng hefe chus hefe tefe chinhr tefe befe boonj befe boons befe kefe caanj kefe lieenf kefe teje tieenf teje tooif teje heje thees heje quan heje lieen heje keje mawcj keje gias keje tur keje"
        let expected = "tese kinh tế quốc tế thực tế y tế kese thiết kế thống kế nhiệt kế bese mẹ bế bồng bế lễ bế nefe nặng nề thợ nề hefe không hề chẳng hề chú hề tefe chỉnh tề befe bộn bề bốn bề kefe cận kề liền kề teje tiền tệ tồi tệ heje thế hệ quan hệ liên hệ keje mặc kệ giá kệ tủ kệ"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_436_vietnamese_collocation_phrases_ho_to_so_ro_mo_to_so_ho_bo_no_go() {
        let input = "hoso cais hoso mieengj hoso ddaof hoso toso yeeus toso nguyeen toso baox toso soso con soso chuwx soso taanf soso chir soso daan soso rofo ddieen rofo phats rofo mofo naams mofo ddoor mofo hooi tofo ngaay tofo gaf tofo sofo beos sofo to sofo hojo baor hojo cuwus hojo cawn hojo ungr hojo bojo ddi bojo chayj bojo cans bojo toanf bojo tieens bojo nojo phaanx nojo thinhj nojo goxo caay goxo banf goxo nhaf goxo ddoof goxo"
        let expected = "hoso cái hố miệng hố đào hố toso yếu tố nguyên tố bão tố soso con số chữ số tần số chỉ số dân số rofo điên rồ phát rồ mofo nấm mồ đổ mồ hôi tofo ngây tồ gà tồ sofo béo sồ to sồ hojo bảo hộ cứu hộ căn hộ ủng hộ bojo đi bộ chạy bộ cán bộ toàn bộ tiến bộ nojo phẫn nộ thịnh nộ goxo cây gỗ bàn gỗ nhà gỗ đồ gỗ"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_437_romaji_cara_casa_cafa_caja_caxa_tone_override_and_coda_unlatch() {
        let input = "mara marafm marafn maraxn marajp hara harafm harafn harajn sara sarafm sarafn sarajp tara tarafm tarafn tarafng tarajn tarajp tarajt dara darafm darafmd darafn darafnd daraxn daraxnd darajm darajmd darajn darajnd darajp darajpd darajt darajtd masa masafm masafn masajp tasa tasafm tasafn tasajp tasajt basa basafm basarm basajp dasa dasafm dasafmd dasarm dasarmd dasajp dasajpd mafa mafasm mafarn mafajp tafa tafasm tafarn tafajp tafajt maja majafm majasm majarn maxa maxafm maxasm maxarn maxajp charas sasaru nasaru masaru tasaru hasaru"
        let expected = "mara mầm mần mẫn mập hara hầm hần hận sara sầm sần sập tara tầm tần tầng tận tập tật dara dầm đầm dần đần dẫn đẫn dậm đậm dận đận dập đập dật đật masa mầm mần mập tasa tầm tần tập tật basa bầm bẩm bập dasa dầm đầm dẩm đẩm dập đập mafa mấm mẩn mập tafa tấm tẩn tập tật maja mầm mấm mẩn maxa mầm mấm mẩn mập charas sasaru nasaru masaru tasaru hasaru"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_438_romaji_cojo_coxo_ceje_chefe_and_english_honor_donor_tone_override_unlatch() {
        let input = "nojo nojos nojof nojor nojox hojo hojos hojof hojor hojox sojo sojos sojof sojor sojox tojo tojos tojof tojor tojox bojo bojos bojof bojor bojox gojo gojos gojof gojor gojox dojo dojof dojofd dojor dojord dojox dojoxd dojos rojos moxo moxos moxof moxor moxoj doxo doxos doxosd doxof doxofd doxor doxord doxoj doxojd keje kejes kejef kejer kejex teje tejes tejef tejer tejex deje dejes dejesd dejef dejefd dejer dejerd dejex dejexd cheje chejes chejef chejer chejex honor honorf honorx honorj donor donord donorf donorfd donorx donorxd donorj donorjd"
        let expected = "nojo nố nồ nổ nỗ hojo hố hồ hổ hỗ sojo số sồ sổ sỗ tojo tố tồ tổ tỗ bojo bố bồ bổ bỗ gojo gố gồ gổ gỗ dojo dồ đồ dổ đổ dỗ đỗ dojos rojos moxo mố mồ mổ mộ doxo dố đố dồ đồ dổ đổ dộ độ keje kế kề kể kễ teje tế tề tể tễ deje dế đế dề đề dể để dễ đễ cheje chế chề chể chễ honor hồn hỗn hộn donor đổn dồn đồn dỗn đỗn dộn độn"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_439_scenario73_trilingual_gojo_soso_honor_and_vietnamese_kinh_te_thiet_ke_can_ho_cay_go_chat() {
        let input = "Dù điểm đánh giá soso nhưng mẫu thiết kế (thieets kese) căn hộ (cawn hojo) tại tầng (tarafng) cao với bàn gỗ (banf goxo) và tủ kệ (tur keje) chỉnh tề (chinhr tefe) không hề (khoong hefe) tồi tệ (tooif teje): các nhà kinh tế (kinh tese) thế hệ (thees heje) mới đánh giá toàn bộ (toanf bojo) yếu tố (yeeus toso) tần số (taanf soso) đều đạt chuẩn, xứng đáng nhận giải honor từ nhà tài trợ donor sau màn biểu diễn của gojo tại các võ đường dojos!"
        let expected = "Dù điểm đánh giá soso nhưng mẫu thiết kế (thiết kế) căn hộ (căn hộ) tại tầng (tầng) cao với bàn gỗ (bàn gỗ) và tủ kệ (tủ kệ) chỉnh tề (chỉnh tề) không hề (không hề) tồi tệ (tồi tệ): các nhà kinh tế (kinh tế) thế hệ (thế hệ) mới đánh giá toàn bộ (toàn bộ) yếu tố (yếu tố) tần số (tần số) đều đạt chuẩn, xứng đáng nhận giải honor từ nhà tài trợ donor sau màn biểu diễn của gojo tại các võ đường dojos!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 66: Delayed-Circumflex Collocations (sân/hân/hâm/sâm/hôn/môn/hôm), C-u-[rsfjx]-[ou] Tone Override, and giro/gifu/giju/gire/gise/duos/dure-d Unlatch
    // =========================================================================

    func test_tier4_440_vietnamese_collocation_phrases_san_han_ham_sam_hon_mon_hom_ro_ro_do_ho_no_ne_re_reo_miu() {
        let input = "sana ra sana treen sana giwax sana hana raats hana vinh hana hama bij hama lof hama sama nhaan sama hoongf sama traf sama hono keets hono ddinhs hono hoangf hono mono booj mono chuyeen mono thur mono homo chieeuf homo ddeem homo maays homo roro cais roro ddan roro roxo mawtj roxo loox roxo doxo duj doxo khuyeen doxo hoxo tuwowng hoxo cuwus hoxo noxo suwj noxo luwcj luoon noxo luwcj neje caau neje chaaps neje reje treex reje bungj reje rero manhr rero vungf rero misu baaus misu nius misu"
        let expected = "sana ra sân trên sân giữa sân hana rất hân vinh hân hama bị hâm lò hâm sama nhân sâm hồng sâm trà sâm hono kết hôn đính hôn hoàng hôn mono bộ môn chuyên môn thủ môn homo chiều hôm đêm hôm mấy hôm roro cái rổ đan rổ roxo mặt rỗ lỗ rỗ doxo dụ dỗ khuyên dỗ hoxo tương hỗ cứu hỗ noxo sự nỗ lực luôn nỗ lực neje câu nệ chấp nệ reje trễ rệ bụng rệ rero mảnh rẻo vùng rẻo misu bấu míu níu míu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_441_romaji_curo_cuso_cufo_cujo_cuxo_tone_override_and_duos_unlatch() {
        let input = "turo turoswng turofwng turojwng turoswc turosoc suro suroswng surofwng muro muroswp murofwn murojwn murojwt duro durofwng durofwngd durojwcd durojotd huro huroswng hurofwng hurojwng churo churoswng churofwng churojwng churoswc churojwc tuso tusorwng tusofwng tusojwng tufo tufoswng tuforwng tufojwng tujo tujoswng tujofwng tujorwng duos duosfwngd duosrwngd duosxwngd duosjwngd duosjwcd duosfond duosjond"
        let expected = "turo tướng tường tượng tước tuốc suro sướng sường muro mướp mườn mượn mượt duro dường đường được đuột huro hướng hường hượng churo chướng chường chượng chước chược tuso tưởng tường tượng tufo tướng tưởng tượng tujo tướng tường tưởng duos đường đưởng đưỡng đượng được đuồn đuộn"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_442_romaji_curu_cusu_cufu_cuju_cuxu_tone_override_w_unlatch() {
        let input = "turu turusw turufw turuxw turujw suru surusw surufw suruxw surujw huru hurusw hurufw huruxw hurujw churu churusw churufw churuxw churujw duru durusw durufw duruxw durujw durujwd tufu tufusw tufurw tufuxw tufujw hufu hufusw hufurw hufuxw hufujw tuju tujusw tujufw tujurw tujuxw huju hujusw hujufw hujurw hujuxw"
        let expected = "turu tứu từu tữu tựu suru sứu sừu sữu sựu huru hứu hừu hữu hựu churu chứu chừu chữu chựu duru dứu dừu dữu dựu đựu tufu tứu tửu tữu tựu hufu hứu hửu hữu hựu tuju tứu từu tửu tữu huju hứu hừu hửu hữu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_443_romaji_giro_gifu_giju_gire_gise_tone_override_and_dure_duse_dufe_duje_delayed_d_unlatch() {
        let input = "giro giros girof girox giroj girosng girofng gifu gifus gifur gifux gifuj gifusw gifurw gifuxw gifujw giju gijus gijuf gijur gijux gijusw gijufw gijurw gijuxw gire gires giref girex girej gise gisef giser gisex gisej dure dured durede duse dused dusede dufe dufed dufede duje dujed dujede"
        let expected = "giro gió giò giõ giọ gióng giòng gifu giú giủ giũ giụ giứ giử giữ giự giju giú giù giủ giũ giứ giừ giử giữ gire gié giè giẽ giẹ gise giè giẻ giẽ giẹ dure đủe đuể duse đúe đuế dufe đùe đuề duje đụe đuệ"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_444_scenario74_trilingual_sana_mono_duos_and_vietnamese_nhan_sam_hoang_hon_chieu_hom_chat() {
        let input = "Dưới ánh hoàng hôn (hoangf hono) chiều hôm (chieeuf homo) ấy tại tỉnh gifu, bộ đôi duos vận động viên của bộ môn (booj mono) điền kinh bước ra sân (ra sana) trong làn gió (giros) mát, uống trà nhân sâm (nhaan sama) và giữ (gifuxw) vững sự nỗ lực (suwj noxo luwcj) phi thường trên con đường (durofwngd) chinh phục thành tựu (turujw) mới cùng cô bạn sana!"
        let expected = "Dưới ánh hoàng hôn (hoàng hôn) chiều hôm (chiều hôm) ấy tại tỉnh gifu, bộ đôi duos vận động viên của bộ môn (bộ môn) điền kinh bước ra sân (ra sân) trong làn gió (gió) mát, uống trà nhân sâm (nhân sâm) và giữ (giữ) vững sự nỗ lực (sự nỗ lực) phi thường trên con đường (đường) chinh phục thành tựu (tựu) mới cùng cô bạn sana!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 67: Extended Collocations (chế/dế/rế/tể/bệ/sệ/chệ/dề/rề/sề/mề/sộ/tộ/mía/rỉa/dủa/chủi), C-[ao]-[pt]-[ao]-w & d-Stop-Coda Unlatch, Nasal -âng/-ông/-ênh/-ến/-ếm, and C-[iu]-[rsfjx]-e Tone Override
    // =========================================================================

    func test_tier4_445_vietnamese_collocation_phrases_che_de_re_me_te_de_be_se_che_de_re_se_me_so_to_do_mo_mia_ria_dua_chui() {
        let input = "chese hanj chese cow chese pha chese tais chese dese con dese tieengs dese ddas dese bawts dese rese cais rese ddan rese roor rese mese baf mese cacs mese tere chuas tere ddoof tere moor tere dere khinh dere beje haj beje cais beje chaan beje seje chayr seje bungj seje mawtj seje cheje cheemx cheje treex cheje defe daamf defe uwowts defe refe leef refe chaamj refe sefe lownj sefe heo sefe beos sefe mefe cais mefe longf mefe sojo ddoof sojo keets sojo tojo kho tojo cas kho tojo nooif tojo dofo ngaay dofo ddieen dofo moso cais moso chaan moso misa caay misa nuwowcs misa eps misa rira cawns rira gawmj rira moor rira dura gotj dura trau dura maif dura churi luri churi"
        let expected = "chese hạn chế cơ chế pha chế tái chế dese con dế tiếng dế đá dế bắt dế rese cái rế đan rế rổ rế mese bà mế các mế tere chúa tể đồ tể mổ tể dere khinh dể beje hạ bệ cái bệ chân bệ seje chảy sệ bụng sệ mặt sệ cheje chễm chệ trễ chệ defe dầm dề ướt dề refe lề rề chậm rề sefe lợn sề heo sề béo sề mefe cái mề lòng mề sojo đồ sộ kết sộ tojo kho tộ cá kho tộ nồi tộ dofo ngây dồ điên dồ moso cái mố chân mố misa cây mía nước mía ép mía rira cắn rỉa gặm rỉa mổ rỉa dura gọt dủa trau dủa mài dủa churi lủi chủi"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_446_delayed_circumflex_stop_coda_w_sj_and_d_sj_unlatch() {
        let input = "tata tataws tatawj mata mataws matawj sata sataws satawj nata nataws natawj hata hataws hatawj data dataws datawj datawsd datawjd datawds datawdj datad datads datadj datadws datadwj tapa tapaws tapawj sapa sapaws sapawj napa napaws napawj lapa lapaws lapawj gapa gapaws gapawj capa capaws capawj dapa dapaws dapawj dapawsd dapawjd dapad dapads dapadj dapadws dapadwj topo topows topowj hopo hopows hopowj lopo lopows lopowj bopo bopows bopowj copo copows copowj nopo nopows nopowj dopo dopowsd dopowjd dopod dopods dopodj dopodws dopodwj toto totows totowj hoto hotows hotowj boto botows botowj goto gotows gotowj doto dotowsd dotowjd dotod dotods dotodj dotodws dotodwj doco docod docods docodj dete deted deteds detedj depe deped depeds depedj dieted dieteds dietedj dueted dueteds duetedj photos photosw"
        let expected = "tata tắt tặt mata mắt mặt sata sắt sặt nata nắt nặt hata hắt hặt data dắt dặt đắt đặt đắt đặt đât đất đật đắt đặt tapa tắp tặp sapa sắp sặp napa nắp nặp lapa lắp lặp gapa gắp gặp capa cắp cặp dapa dắp dặp đắp đặp đâp đấp đập đắp đặp topo tớp tợp hopo hớp hợp lopo lớp lợp bopo bớp bợp copo cớp cợp nopo nớp nợp dopo đớp đợp đôp đốp độp đớp đợp toto tớt tợt hoto hớt hợt boto bớt bợt goto gớt gợt doto đớt đợt đôt đốt đột đớt đợt doco đôc đốc độc dete đêt đết đệt depe đêp đếp đệp dieted điết điệt đuêt đuết đuệt photos phớt"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_447_delayed_circumflex_nasal_coda_ang_ong_enh_en_em_and_managw_unlatch() {
        let input = "tanag tanags danag danagd danagxd nanag nanagf lanag vanag vanagw vanagws sanag hanag banag chanag managw managws managwf managwr managwx managwj manage manager tonog bonog conog conogs donog donogd donogfd honog lonog nonog ronog sonog tronog chonog phonog keneh beneh benehs benehj leneh lenehr meneh teneh veneh cheneh chenehf deneh denehd heneh henehx seneh denes denesd nenes benes menes senes tenes henes kenes demes demesd nemes temes semes bemes kemes nener bener tener nemer temer memes themes"
        let expected = "tâng tấng dâng đâng đẫng nâng nầng lâng vâng văng vắng sâng hâng bâng châng măng mắng mằng mẳng mẵng mặng manage manager tông bông công cống dông đông đồng hông lông nông rông sông trông chông phông kênh bênh bếnh bệnh lênh lểnh mênh tênh vênh chênh chềnh dênh đênh hênh hễnh sênh dến đến nến bến mến sến tến hến kến dếm đếm nếm tếm sếm bếm kếm nển bển tển nểm tểm memes themes"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_448_romaji_cire_cise_cife_cije_cure_cuse_cufe_cuje_tone_override_unlatch() {
        let input = "kire kirese kiresen kirefen kirejen kirexen nire niresen nirefen bire biresen birefen chire chiresen chirefen chireseu chirefeu mise misefen miseren misejen misexen misefeu nise nisefem niserem nisejem tise tisefen tiseren tisejen tisexen tisefeu bise bisefen biseren bisejen hise hisefen hiseren hisejen dise disefend diserend disejend disefeud kife kifesen kiferen kifejen tife tifesen tiferen tifejen kije kijesen kijefen kijeren tije tijesen tijefen tijeren ture turese turefe turexe tureje turejech hure hurese hurefe hureje chure churese chureje churesenh churejech tuse tusere tusefe tusexe tuseje huse husere husefe huseje duse dusejed tufe tufese tufere tufeje hufe hufese hufeje tuje tujese tujefe tujere huje hujese hujefe"
        let expected = "kire kiế kiến kiền kiện kiễn nire niến niền bire biến biền chire chiến chiền chiếu chiều mise miền miển miện miễn miều nise niềm niểm niệm tise tiền tiển tiện tiễn tiều bise biền biển biện hise hiền hiển hiện dise điền điển điện điều kife kiến kiển kiện tife tiến tiển tiện kije kiến kiền kiển tije tiến tiền tiển ture tuế tuề tuễ tuệ tuệch hure huế huề huệ chure chuế chuệ chuếnh chuệch tuse tuể tuề tuễ tuệ huse huể huề huệ duse đuệ tufe tuế tuể tuệ hufe huế huệ tuje tuế tuề tuể huje huế huề"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_449_scenario75_trilingual_chese_misa_tojo_and_vietnamese_co_che_nuoc_mia_ca_kho_to_chat() {
        let input = "Theo cơ chế (cow chese) phối hợp (hopowj) mới trên kênh (keneh) truyền thông công (conog) cộng, đoàn kiến (kiresen) trúc sư đến (denesd) thăm công trình đồ sộ (ddoof sojo) tại tojo, thưởng thức cá kho tộ (cas kho tojo) ăn kèm măng (managw) tươi và ly nước mía (nuwowcs misa) pha chế (pha chese) đặc biệt, vừa xem memes vừa đặt (datawjd) vé tàu đi cùng cô bạn misa!"
        let expected = "Theo cơ chế (cơ chế) phối hợp (hợp) mới trên kênh (kênh) truyền thông công (công) cộng, đoàn kiến (kiến) trúc sư đến (đến) thăm công trình đồ sộ (đồ sộ) tại tojo, thưởng thức cá kho tộ (cá kho tộ) ăn kèm măng (măng) tươi và ly nước mía (nước mía) pha chế (pha chế) đặc biệt, vừa xem memes vừa đặt (đặt) vé tàu đi cùng cô bạn misa!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 68: 5-Letter Romaji Collocations (giải/soái/toái/hoải/hối/mổi/tẩu/hẩu/giủi/giúi) & Tone Override Unlatch (osoi/hosoi/moroi/noroi/soroi/girui/gisui/girai/gisai/horai/torai/hosai/sosai/tosai/arau/harau/sarau/tarau/narau/ieru/kieru/C-e-[rsfjx]-u)
    // =========================================================================

    func test_tier4_450_vietnamese_collocation_phrases_giai_soai_toai_hoai_hoi_moi_tau_hau_giui_giui() {
        let input = "girai hoaf girai lys girai dieenx girai phaan girai lowif girai trao girai ddoatj girai sosai nguyeen sosai thoongs sosai ddaij sosai tuwowngs sosai tosai phieenf tosai vunj tosai horai bair horai oair horai hosoi sams hosoi haaps hosoi thucs hosoi khoong hosoi moroi noots moroi cais moroi tarau ddaof tarau bor tarau oongs tarau huts tarau harau haof harau ngon harau girui gaanf girui gisui ddaam gisui nhets gisui"
        let expected = "girai hòa giải lý giải diễn giải phân giải lời giải trao giải đoạt giải sosai nguyên soái thống soái đại soái tướng soái tosai phiền toái vụn toái horai bải hoải oải hoải hosoi sám hối hấp hối thúc hối không hối moroi nốt mổi cái mổi tarau đào tẩu bỏ tẩu ống tẩu hút tẩu harau hào hẩu ngon hẩu girui gần giủi gisui đâm giúi nhét giúi"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_451_romaji_osoi_hosoi_moroi_noroi_soroi_girui_gisui_girai_gisai_horai_torai_hosai_sosai_tosai_tone_override_unlatch() {
        let input = "osoi osoif osoir osoix osoij osoifw osoirw osoixw osoijw hosoi hosoif hosoir hosoix hosoij hosoifw hosoirw hosoixw hosoijw moroi morois moroif moroix moroij moroisw moroifw moroixw moroijw noroi norois noroif noroix noroij noroisw noroifw noroixw noroijw soroi sorois soroif soroix soroij soroisw soroifw soroixw soroijw girui giruis giruif giruix giruij gisui gisuif gisuir gisuix gisuij girai girais giraif giraix giraij gisai gisaif gisair gisaix gisaij horai horais horaif horaix horaij torai torais toraif toraix toraij hosai hosaif hosair hosaix hosaij sosai sosaif sosair sosaix sosaij tosai tosaif tosair tosaix tosaij"
        let expected = "osoi ồi ổi ỗi ội ời ởi ỡi ợi hosoi hồi hổi hỗi hội hời hởi hỡi hợi moroi mối mồi mỗi mội mới mời mỡi mợi noroi nối nồi nỗi nội nới nời nỡi nợi soroi sối sồi sỗi sội sới sời sỡi sợi girui giúi giùi giũi giụi gisui giùi giủi giũi giụi girai giái giài giãi giại gisai giài giải giãi giại horai hoái hoài hoãi hoại torai toái toài toãi toại hosai hoài hoải hoãi hoại sosai soài soải soãi soại tosai toài toải toãi toại"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_452_romaji_arau_harau_sarau_tarau_narau_and_ieru_kieru_mieru_hieru_nieru_tieru_bieru_sieru_gieru_rieru_chieru_tone_override_unlatch() {
        let input = "arau araus arauf araux arauj harau haraus harauf haraux harauj sarau sarauf saraux sarauj tarau taraus tarauf taraux tarauj narau naraus narauf naraux narauj ieru ieruse ierufe ieruxe ieruje kieru kieruse kierufe kieruxe kieruje mieru mieruse mierufe mieruxe mieruje hieru hieruse hierufe hieruxe hieruje nieru nieruse nierufe nieruxe nieruje tieru tieruse tierufe tieruxe tieruje bieru bieruse bierufe bieruxe bieruje sieru sieruse sierufe sieruxe sieruje gieru gieruse gierufe gieruxe gieruje rieru rieruse rierufe rieruxe rieruje chieru chieruse chierufe chieruxe chieruje"
        let expected = "arau ấu ầu ẫu ậu harau hấu hầu hẫu hậu sarau sầu sẫu sậu tarau tấu tầu tẫu tậu narau nấu nầu nẫu nậu ieru iếu iều iễu iệu kieru kiếu kiều kiễu kiệu mieru miếu miều miễu miệu hieru hiếu hiều hiễu hiệu nieru niếu niều niễu niệu tieru tiếu tiều tiễu tiệu bieru biếu biều biễu biệu sieru siếu siều siễu siệu gieru giếu giều giễu giệu rieru riếu riều riễu riệu chieru chiếu chiều chiễu chiệu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_453_romaji_ceru_cesu_cefu_tone_override_neros_reros_and_refuse_preservation() {
        let input = "keru keruse kerufe keruxe keruje teru teruse terufe teruxe teruje neru neruse nerufe neruxe neruje meru meruse merufe meruxe meruje beru beruse berufe beruxe beruje seru seruse serufe seruxe seruje reru reruse rerufe reruxe reruje cheru cheruse cherufe cheruxe cheruje hesu hesufe hesure hesuxe hesuje tesu tesufe tesure tesuxe tesuje mesu mesufe mesure mesuxe mesuje nesu nesufe nesure nesuxe nesuje besu besufe besure besuxe besuje sesu sesufe sesure sesuxe sesuje resu resufe resure resuxe resuje kefu kefuse kefure kefuxe kefuje tefu tefuse tefure tefuxe tefuje mefu mefuse mefure mefuxe mefuje nefu nefuse nefure nefuxe nefuje befu befuse befure befuxe befuje defu defuse defure defuxe defuje refu refure refuxe refuje neros reros refuse refused refuses"
        let expected = "keru kếu kều kễu kệu teru tếu tều tễu tệu neru nếu nều nễu nệu meru mếu mều mễu mệu beru bếu bều bễu bệu seru sếu sều sễu sệu reru rếu rều rễu rệu cheru chếu chều chễu chệu hesu hều hểu hễu hệu tesu tều tểu tễu tệu mesu mều mểu mễu mệu nesu nều nểu nễu nệu besu bều bểu bễu bệu sesu sều sểu sễu sệu resu rều rểu rễu rệu kefu kếu kểu kễu kệu tefu tếu tểu tễu tệu mefu mếu mểu mễu mệu nefu nếu nểu nễu nệu befu bếu bểu bễu bệu defu dếu dểu dễu dệu refu rểu rễu rệu néo réo refuse refused refuses"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_454_scenario76_trilingual_kieru_hosoi_sosai_and_vietnamese_ly_giai_nguyen_soai_sam_hoi_chat() {
        let input = "Để lý giải (lys girai) về nguyên soái (nguyeen sosai) trong tiểu thuyết lịch sử có hiệu (hieruje) ứng ánh sáng kieru và nét vẽ hosoi, tác giả đã diễn giải (dieenx girai) cảnh nhân vật sám hối (sams hosoi) rồi đào tẩu (ddaof tarau) trong đêm tối (tosoi) mà không hề phiền toái (phieenf tosai) hay refuse lời khuyên từ người bạn sosai!"
        let expected = "Để lý giải (lý giải) về nguyên soái (nguyên soái) trong tiểu thuyết lịch sử có hiệu (hiệu) ứng ánh sáng kieru và nét vẽ hosoi, tác giả đã diễn giải (diễn giải) cảnh nhân vật sám hối (sám hối) rồi đào tẩu (đào tẩu) trong đêm tối (tối) mà không hề phiền toái (phiền toái) hay refuse lời khuyên từ người bạn sosai!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 69: Collocations (gủi/dủi/nủi/bủi/mệ/dệ/gồ/sỗ/bỗ/mỗ/nồ/sế/nế/hế/kíu/híu/kía/chía) & Tone Override Unlatch (C-i-[rsfjx]-[ua]/nora/rora/gosa/gosai)
    // =========================================================================

    func test_tier4_455_vietnamese_collocation_phrases_gui_dui_nui_bui_me_de_go_so_bo_mo_no_se_ne_he_kiu_hiu_kia_chia() {
        let input = "guri gaanf guri duri con duri chuootj duri may duri xui duri nuri ngawns nuri its nuri trow nuri buri dden buri buij buri meje baf meje cacs meje oon meje deje beej deje gofo nooir gofo trans gofo ddaauf gofo mawtj gofo soxo nois soxo cuwowif soxo boxo nois boxo cuwowif boxo moxo laox moxo baanf moxo nofo gaf nofo con nofo sese bongs sese chieeuf sese xees sese nese neef nese hese cuwowif hese kisu cuwus kisu keeu kisu hisu mawts hisu cuwowif hisu kisa ddawngf kisa been kisa choox kisa chisa muix chisa sungs chisa"
        let expected = "guri gần gủi duri con dủi chuột dủi may dủi xui dủi nuri ngắn nủi ít nủi trơ nủi buri đen bủi bụi bủi meje bà mệ các mệ ôn mệ deje bệ dệ gofo nổi gồ trán gồ đầu gồ mặt gồ soxo nói sỗ cười sỗ boxo nói bỗ cười bỗ moxo lão mỗ bần mỗ nofo gà nồ con nồ sese bóng sế chiều sế xế sế nese nề nế hese cười hế kisu cứu kíu kêu kíu hisu mắt híu cười híu kisa đằng kía bên kía chỗ kía chisa mũi chía súng chía"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_456_romaji_cira_cisa_rira_misa_kisa_hisa_chisa_tone_override_unlatch() {
        let input = "rira riras riraf rirax riraj misa misaf misar misax misaj kisa kisaf kisar kisax kisaj hisa hisaf hisar hisax hisaj chisa chisaf chisar chisax chisaj"
        let expected = "rira ría rìa rĩa rịa misa mìa mỉa mĩa mịa kisa kìa kỉa kĩa kịa hisa hìa hỉa hĩa hịa chisa chìa chỉa chĩa chịa"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_457_romaji_kiru_kisu_kifu_kiju_tone_override_unlatch() {
        let input = "kiru kirus kiruf kirux kiruj kisu kisuf kisur kisux kisuj kifu kifus kifur kifux kifuj kiju kijus kijuf kijur kijux"
        let expected = "kiru kíu kìu kĩu kịu kisu kìu kỉu kĩu kịu kifu kíu kỉu kĩu kịu kiju kíu kìu kỉu kĩu"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_458_romaji_sora_lora_dora_sosa_tosa_dosa_sofa_and_nora_tone_and_vowel_unlatch() {
        let input = "sora sorai sorao soras soraf sorax soraj lora lorai lorao loras loraf lorax loraj dora doras doraf dorax doraj dorasd dorafd doraxd dorajd sosa sosao sosaf sosar sosax sosaj tosa tosao tosaf tosar tosax tosaj dosa dosaf dosar dosax dosaj dosafd dosard dosaxd dosajd sofa sofai sofar sofax sofaj nora norax noraxn"
        let expected = "sora soải soảo sóa sòa sõa sọa lora loải loảo lóa lòa lõa lọa dora dóa dòa dõa dọa đóa đòa đõa đọa sosa soáo sòa sỏa sõa sọa tosa toáo tòa tỏa tõa tọa dosa dòa dỏa dõa dọa đòa đỏa đõa đọa sofa soài sỏa sõa sọa nora nõa noãn"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_459_scenario77_trilingual_kisu_meje_gofo_and_vietnamese_gan_gui_ngan_nui_ba_me_bong_se_chat() {
        let input = "Trong chuyến thăm ngắn nủi (ngawns nuri) nhưng gần gủi (gaanf guri) bên bà mệ (baf meje) ở vùng đồi đá nổi gồ (nooir gofo) khi bóng sế (bongs sese) đổ dài đằng kía (ddawngf kisa), bé gosai cười híu (cuwowif hisu) mắt nhìn chú mèo nora nằm sát rìa (riraf) hiên nhà nghe nhạc kisu!"
        let expected = "Trong chuyến thăm ngắn nủi (ngắn nủi) nhưng gần gủi (gần gủi) bên bà mệ (bà mệ) ở vùng đồi đá nổi gồ (nổi gồ) khi bóng sế (bóng sế) đổ dài đằng kía (đằng kía), bé gosai cười híu (cười híu) mắt nhìn chú mèo nora nằm sát rìa (rìa) hiên nhà nghe nhạc kisu!"
        assertBuffer(input, equals: expected)
    }

    // =========================================================================
    // MARK: - Cycle 70: Standard-Telex Collocations (beer/deer/sees/deed/deeds/booms/sere/gisai/torai/hosai/nori/maso) & Vowel-Initial 3-Letter Romaji/English Unlatch
    // =========================================================================

    func test_tier4_460_vietnamese_collocation_phrases_beer_deer_sees_deed_deeds_booms_sere_gisai_torai_hosai_nori_maso() {
        let input = "beer bowi beer boons beer deer khinh deer sees bongs sees chieeuf sees deed con deed bowf deed mawtj deed deeds hoangf deeds thuwowngj deeds chaan deeds booms luas booms neeps booms sere chim sere chia sere gisai con gisai em gisai coo gisai torai tuwj torai hosai vangf hosai nori nhor nori bes nori maso maus maso chim maso"
        let expected = "beer bơi bể bốn bể deer khinh dể sees bóng sế chiều sế deed con đê bờ đê mặt đê deeds hoàng đế thượng đế chân đế booms lúa bốm nếp bốm sere chim sể chia sể gisai con giái em giái cô giái torai tự toải hosai vàng hoái nori nhỏ nỏi bé nỏi maso máu máo chim máo"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_461_vowel_initial_romaji_ire_ure_use_eru_esu_efu_tone_override_and_e_unlatch() {
        let input = "ire irese irefe irexe ireje iresem iresen ireseng ireset iresec iresep ireseu irefem irefen irejem irejen irejet irejec irejep irejeu ure urese urefe urexe ureje uresen uresem uresenh ureset uresech urefen urefem urefenh urejen urejem urejet urejech use user users used uses usefe usexe useje usefen usefem usefenh usejen usejem usejet usejech eru eruse erufe eruxe eruje esu esufe esure esuxe esuje efu efuse efure efuxe efuje ureshii"
        let expected = "ire iế iề iễ iệ iếm iến iếng iết iếc iếp iếu iềm iền iệm iện iệt iệc iệp iệu ure uế uề uễ uệ uến uếm uếnh uết uếch uền uềm uềnh uện uệm uệt uệch use user users used uses uề uễ uệ uền uềm uềnh uện uệm uệt uệch eru ếu ều ễu ệu esu ều ểu ễu ệu efu ếu ểu ễu ệu ureshii"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_462_vowel_initial_ufo_uro_uso_tone_override_and_wo_unlatch() {
        let input = "ufo ufos ufosw uforw ufoxw ufojw ufoso uforo ufoxo ufojo ufoswi ufoswm ufoswn ufoswt ufosoi ufoson ufosot uro urosw urofw uroxw urojw uroso urofo uroxo urojo uso usofw usorw usoxw usojw usofo usoro usoxo usojo"
        let expected = "ufo ufos ướ ưở ưỡ ượ uố uổ uỗ uộ ưới ướm ướn ướt uối uốn uốt uro ướ ườ ưỡ ượ uố uồ uỗ uộ uso ườ ưở ưỡ ượ uồ uổ uỗ uộ"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_463_vowel_initial_aru_iru_isu_asa_and_roes_noes_tone_override_unlatch() {
        let input = "aru arua arus aruf arux aruj arusa arufa aruxa aruja iru irus iruf irux iruj isu isuf isur isux isuj asa asaru asaf asax asaj asafn asafm asafng asafw asafwn asajm asajn asajt asajc asajp"
        let expected = "aru ẩu áu àu ãu ạu ấu ầu ẫu ậu iru íu ìu ĩu ịu isu ìu ỉu ĩu ịu asa asaru ầ ẫ ậ ần ầm ầng ằ ằn ậm ận ật ậc ập"
        assertBuffer(input, equals: expected)
    }

    func test_tier4_464_scenario78_trilingual_ufos_beer_deed_and_vietnamese_boi_be_con_de_hoang_de_con_giai_chat() {
        let input = "Sau buổi bơi bể (bowi beer) cùng cô em giái (em gisai) nhỏ nỏi (nhor nori), cả nhóm đi dọc con đê (con deed) ngắm cánh đồng lúa bốm (luas booms) vàng hoái (vangf hosai) dưới nắng bóng sế (bongs sees), vừa thưởng thức beer mát lạnh vừa đọc truyền thuyết về vị hoàng đế (hoangf deeds) và những đĩa bay ufos thật ureshii!"
        let expected = "Sau buổi bơi bể (bơi bể) cùng cô em giái (em giái) nhỏ nỏi (nhỏ nỏi), cả nhóm đi dọc con đê (con đê) ngắm cánh đồng lúa bốm (lúa bốm) vàng hoái (vàng hoái) dưới nắng bóng sế (bóng sế), vừa thưởng thức beer mát lạnh vừa đọc truyền thuyết về vị hoàng đế (hoàng đế) và những đĩa bay ufos thật ureshii!"
        assertBuffer(input, equals: expected)
    }

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

            // Tier 4: Real-World Multilingual Application Scenarios (111 tests)
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
            ("test_tier4_150_english_ief_ier_eep_oa_oo_words_and_chiefue_disambiguation", test_tier4_150_english_ief_ier_eep_oa_oo_words_and_chiefue_disambiguation),
            ("test_tier4_151_japanese_short_verbs_and_teiru_nagara_tara_reba_yasui_nikui_sugiru", test_tier4_151_japanese_short_verbs_and_teiru_nagara_tara_reba_yasui_nikui_sugiru),
            ("test_tier4_152_mid_word_backspace_typos_in_english_and_romaji_words", test_tier4_152_mid_word_backspace_typos_in_english_and_romaji_words),
            ("test_tier4_153_english_scientific_and_ious_eous_uous_adjectives", test_tier4_153_english_scientific_and_ious_eous_uous_adjectives),
            ("test_tier4_154_scenario16_trilingual_product_launch_and_japanese_stakeholder_sync", test_tier4_154_scenario16_trilingual_product_launch_and_japanese_stakeholder_sync),
            ("test_tier4_155_english_tw_prefixes_two_disambiguation_and_calendar_numbers", test_tier4_155_english_tw_prefixes_two_disambiguation_and_calendar_numbers),
            ("test_tier4_156_english_ai_au_ou_oi_oy_eu_ew_ui_ue_que_gue_words", test_tier4_156_english_ai_au_ou_oi_oy_eu_ew_ui_ue_que_gue_words),
            ("test_tier4_157_japanese_counters_numbers_time_and_kinship_vocabulary", test_tier4_157_japanese_counters_numbers_time_and_kinship_vocabulary),
            ("test_tier4_158_japanese_corporate_departments_and_business_documents", test_tier4_158_japanese_corporate_departments_and_business_documents),
            ("test_tier4_159_scenario17_quarterly_business_review_and_japanese_contract_signing", test_tier4_159_scenario17_quarterly_business_review_and_japanese_contract_signing),
            ("test_tier4_160_english_sw_dw_thw_prefixes_and_vietnamese_shorthand_preservation", test_tier4_160_english_sw_dw_thw_prefixes_and_vietnamese_shorthand_preservation),
            ("test_tier4_161_english_plural_rs_fs_lf_coda_and_ore_eer_oar_words", test_tier4_161_english_plural_rs_fs_lf_coda_and_ore_eer_oar_words),
            ("test_tier4_162_japanese_two_mora_nouns_names_and_sha_sho_structural_patterns", test_tier4_162_japanese_two_mora_nouns_names_and_sha_sho_structural_patterns),
            ("test_tier4_163_japanese_passive_causative_potential_and_compound_inflections", test_tier4_163_japanese_passive_causative_potential_and_compound_inflections),
            ("test_tier4_164_scenario18_trilingual_hospitality_and_software_release_celebration", test_tier4_164_scenario18_trilingual_hospitality_and_software_release_celebration),
            ("test_tier4_165_japanese_katakana_long_vowel_aafu_aasu_aaru_eefu_eesu_eeru", test_tier4_165_japanese_katakana_long_vowel_aafu_aasu_aaru_eefu_eesu_eeru),
            ("test_tier4_166_english_x_family_and_multitone_rf_er_words", test_tier4_166_english_x_family_and_multitone_rf_er_words),
            ("test_tier4_167_english_lk_lm_lv_rb_rp_rg_rv_rch_coda_clusters", test_tier4_167_english_lk_lm_lv_rb_rp_rg_rv_rch_coda_clusters),
            ("test_tier4_168_japanese_katakana_it_loanwords_in_romaji", test_tier4_168_japanese_katakana_it_loanwords_in_romaji),
            ("test_tier4_169_scenario19_git_branch_workflow_and_katakana_it_standup", test_tier4_169_scenario19_git_branch_workflow_and_katakana_it_standup),
            ("test_tier4_170_english_tle_cle_ple_and_medial_st_sc_sp_compounds", test_tier4_170_english_tle_cle_ple_and_medial_st_sc_sp_compounds),
            ("test_tier4_171_english_ies_oes_ees_diet_quiet_and_tieseng_disambiguation", test_tier4_171_english_ies_oes_ees_diet_quiet_and_tieseng_disambiguation),
            ("test_tier4_172_japanese_au_aru_iru_eru_verbs_and_daily_nouns", test_tier4_172_japanese_au_aru_iru_eru_verbs_and_daily_nouns),
            ("test_tier4_173_japanese_verb_conjugations_mashou_tai_nakatta_teiru_rareru_saseru_tara_reba", test_tier4_173_japanese_verb_conjugations_mashou_tai_nakatta_teiru_rareru_saseru_tara_reba),
            ("test_tier4_174_scenario20_trilingual_ui_display_debug_and_japanese_payment_workflow", test_tier4_174_scenario20_trilingual_ui_display_debug_and_japanese_payment_workflow),
            ("test_tier4_175_english_double_final_ss_ff_rr_words_and_less_ness_suffixes", test_tier4_175_english_double_final_ss_ff_rr_words_and_less_ness_suffixes),
            ("test_tier4_176_english_nl_ml_coda_clusters_air_compounds_and_oa_oo_ee_words", test_tier4_176_english_nl_ml_coda_clusters_air_compounds_and_oa_oo_ee_words),
            ("test_tier4_177_japanese_ko_so_a_do_adnominals_mono_and_katakana_p_b_g_d_words", test_tier4_177_japanese_ko_so_a_do_adnominals_mono_and_katakana_p_b_g_d_words),
            ("test_tier4_178_english_ai_oi_ou_digraph_families", test_tier4_178_english_ai_oi_ou_digraph_families),
            ("test_tier4_179_scenario21_trilingual_game_dev_gacha_and_airline_booking_chat", test_tier4_179_scenario21_trilingual_game_dev_gacha_and_airline_booking_chat),
            ("test_tier4_180_english_rrh_ffd_medial_clusters_and_ooing_words", test_tier4_180_english_rrh_ffd_medial_clusters_and_ooing_words),
            ("test_tier4_181_english_photo_poem_poet_duet_boost_roost_dojo_and_ire_use_words", test_tier4_181_english_photo_poem_poet_duet_boost_roost_dojo_and_ire_use_words),
            ("test_tier4_182_japanese_two_mora_ru_ro_re_su_so_se_ji_jo_wa_fu_and_oi_adjectives", test_tier4_182_japanese_two_mora_ru_ro_re_su_so_se_ji_jo_wa_fu_and_oi_adjectives),
            ("test_tier4_183_english_greek_latin_prefixes_co_re_pre_de_micro_crypto_thermo", test_tier4_183_english_greek_latin_prefixes_co_re_pre_de_micro_crypto_thermo),
            ("test_tier4_184_scenario22_trilingual_photography_workshop_and_dojo_training_chat", test_tier4_184_scenario22_trilingual_photography_workshop_and_dojo_training_chat),
            ("test_tier4_185_japanese_urou_usou_ujou_long_vowel_and_uro_uso_ujo_disambiguation", test_tier4_185_japanese_urou_usou_ujou_long_vowel_and_uro_uso_ujo_disambiguation),
            ("test_tier4_186_english_c_g_ng_front_vowel_orthography_and_laws_raws_saws_unlatch", test_tier4_186_english_c_g_ng_front_vowel_orthography_and_laws_raws_saws_unlatch),
            ("test_tier4_187_ai_ml_cloud_devops_and_nnx_dnn_nnl_nns_clusters", test_tier4_187_ai_ml_cloud_devops_and_nnx_dnn_nnl_nns_clusters),
            ("test_tier4_188_japanese_rei_sei_kei_and_ou_vocabulary", test_tier4_188_japanese_rei_sei_kei_and_ou_vocabulary),
            ("test_tier4_189_scenario23_trilingual_ai_llm_inference_and_japanese_bathhouse_relax_chat", test_tier4_189_scenario23_trilingual_ai_llm_inference_and_japanese_bathhouse_relax_chat),
            ("test_tier4_190_english_offglide_s_clusters_and_chasm_disc_corsair", test_tier4_190_english_offglide_s_clusters_and_chasm_disc_corsair),
            ("test_tier4_191_english_rms_rns_rfs_fs_rs_plurals_and_ed_ing_forms", test_tier4_191_english_rms_rns_rfs_fs_rs_plurals_and_ed_ing_forms),
            ("test_tier4_192_japanese_oai_onset_orthography_and_rai_sai_rui_sui_ura_vocabulary", test_tier4_192_japanese_oai_onset_orthography_and_rai_sai_rui_sui_ura_vocabulary),
            ("test_tier4_193_english_ism_ist_istic_and_spect_spire_families", test_tier4_193_english_ism_ist_istic_and_spect_spire_families),
            ("test_tier4_194_scenario24_trilingual_disaster_recovery_bosai_and_urayasu_trip_chat", test_tier4_194_scenario24_trilingual_disaster_recovery_bosai_and_urayasu_trip_chat),
            ("test_tier4_195_english_owing_awing_ewing_participles", test_tier4_195_english_owing_awing_ewing_participles),
            ("test_tier4_196_english_single_y_coda_orthography_and_life_disambiguation", test_tier4_196_english_single_y_coda_orthography_and_life_disambiguation),
            ("test_tier4_197_japanese_ifu_ufu_iju_uju_and_cuuw_unlatch", test_tier4_197_japanese_ifu_ufu_iju_uju_and_cuuw_unlatch),
            ("test_tier4_198_japanese_wa_za_ze_zo_zu_and_oru_ori_vocabulary", test_tier4_198_japanese_wa_za_ze_zo_zu_and_oru_ori_vocabulary),
            ("test_tier4_199_scenario25_trilingual_gifu_wildlife_expedition_and_rowing_lifestyle_chat", test_tier4_199_scenario25_trilingual_gifu_wildlife_expedition_and_rowing_lifestyle_chat),
            ("test_tier4_200_english_mid_word_tone_clusters_rs_rj_rf_sf_sr", test_tier4_200_english_mid_word_tone_clusters_rs_rj_rf_sf_sr),
            ("test_tier4_201_mid_word_z_after_tone_and_end_of_word_z_clear_preservation", test_tier4_201_mid_word_z_after_tone_and_end_of_word_z_clear_preservation),
            ("test_tier4_202_invalid_oe_onsets_and_axis_thaw_hero_vocabulary", test_tier4_202_invalid_oe_onsets_and_axis_thaw_hero_vocabulary),
            ("test_tier4_203_japanese_ise_isu_isa_eso_seru_reru_and_i_e_unlatch", test_tier4_203_japanese_ise_isu_isa_eso_seru_reru_and_i_e_unlatch),
            ("test_tier4_204_scenario26_trilingual_horizon_store_mise_and_heroic_refactor_chat", test_tier4_204_scenario26_trilingual_horizon_store_mise_and_heroic_refactor_chat),
            ("test_tier4_205_english_non_qu_y_nucleus_orthography_pyre_tyre_lyre_byre_gyre", test_tier4_205_english_non_qu_y_nucleus_orthography_pyre_tyre_lyre_byre_gyre),
            ("test_tier4_206_invalid_oa_onsets_trojan_borax_mosa_nosa_bosa_rora", test_tier4_206_invalid_oa_onsets_trojan_borax_mosa_nosa_bosa_rora),
            ("test_tier4_207_english_mb_coda_cluster_boombox_catacomb_and_ajax_taxi_luxe", test_tier4_207_english_mb_coda_cluster_boombox_catacomb_and_ajax_taxi_luxe),
            ("test_tier4_208_japanese_yasa_yoso_kase_mase_sase_kosa_soso_hura_vocabulary", test_tier4_208_japanese_yasa_yoso_kase_mase_sase_kosa_soso_hura_vocabulary),
            ("test_tier4_209_scenario27_trilingual_security_trojan_ajax_and_tosa_trip_chat", test_tier4_209_scenario27_trilingual_security_trojan_ajax_and_tosa_trip_chat),
            ("test_tier4_210_single_p_onset_tone_horn_orthography_and_ph_preservation", test_tier4_210_single_p_onset_tone_horn_orthography_and_ph_preservation),
            ("test_tier4_211_ue_non_palatal_coda_orthography_tureen_and_vietnamese_ue_preservation", test_tier4_211_ue_non_palatal_coda_orthography_tureen_and_vietnamese_ue_preservation),
            ("test_tier4_212_english_r_controlled_barn_darn_harm_charm_thorn_churn_urn_swarth", test_tier4_212_english_r_controlled_barn_darn_harm_charm_thorn_churn_urn_swarth),
            ("test_tier4_213_japanese_sura_suri_turo_tura_ture_nura_bura_gura_guri_and_vietnamese_unlatch", test_tier4_213_japanese_sura_suri_turo_tura_ture_nura_bura_gura_guri_and_vietnamese_unlatch),
            ("test_tier4_214_scenario28_trilingual_ramen_tureen_gura_stream_and_charm_chat", test_tier4_214_scenario28_trilingual_ramen_tureen_gura_stream_and_charm_chat),
            ("test_tier4_215_invalid_g_gh_v_oa_onsets_gora_gosa_goats_goal_and_vietnamese_oa_preservation", test_tier4_215_invalid_g_gh_v_oa_onsets_gora_gosa_goats_goal_and_vietnamese_oa_preservation),
            ("test_tier4_216_english_caws_maws_haws_sere_and_vietnamese_cawst_mawst_hawst_unlatch", test_tier4_216_english_caws_maws_haws_sere_and_vietnamese_cawst_mawst_hawst_unlatch),
            ("test_tier4_217_japanese_mara_hara_sara_tara_and_vietnamese_maran_haram_saram_taram_unlatch", test_tier4_217_japanese_mara_hara_sara_tara_and_vietnamese_maran_haram_saram_taram_unlatch),
            ("test_tier4_218_japanese_kire_nire_bire_gire_giro_hore_kieru_kiete_miete_uete_suete_and_unlatch", test_tier4_218_japanese_kire_nire_bire_gire_giro_hore_kieru_kiete_miete_uete_suete_and_unlatch),
            ("test_tier4_219_scenario29_trilingual_ramen_sara_kire_and_kieru_bug_chat", test_tier4_219_scenario29_trilingual_sara_kire_sushi_and_kieru_bug_chat),
            ("test_tier4_220_japanese_uwa_non_split_uwagi_uwaki_uwabe_uwate_and_suwa_guwa_buwa_unlatch", test_tier4_220_japanese_uwa_non_split_uwagi_uwaki_uwabe_uwate_and_suwa_guwa_buwa_unlatch),
            ("test_tier4_221_english_won_wow_wows_yens_kern_and_vietnamese_wong_wonx_yense_unlatch", test_tier4_221_english_won_wow_wows_yens_kern_and_vietnamese_wong_wonx_yense_unlatch),
            ("test_tier4_222_japanese_horo_moro_moso_toro_toso_soro_noro_noso_and_vietnamese_unlatch", test_tier4_222_japanese_horo_moro_moso_toro_toso_soro_noro_noso_and_vietnamese_unlatch),
            ("test_tier4_223_japanese_tere_kere_nere_bere_dere_tese_kese_mese_nese_hese_sese_bese_dese_nesu_and_unlatch", test_tier4_223_japanese_tere_kere_nere_bere_dere_tese_kese_mese_nese_hese_sese_bese_dese_nesu_and_unlatch),
            ("test_tier4_224_scenario30_trilingual_suwa_trip_uwagi_toro_sushi_and_won_wow_chat", test_tier4_224_scenario30_trilingual_suwa_trip_uwagi_toro_sushi_and_won_wow_chat),
            ("test_tier4_225_japanese_howa_dowa_giwa_huwa_nuwa_ruwa_and_vietnamese_unlatch", test_tier4_225_japanese_howa_dowa_giwa_huwa_nuwa_ruwa_and_vietnamese_unlatch),
            ("test_tier4_226_english_hex_nix_tux_dux_and_vietnamese_hexe_nixu_tuxn_duxng_unlatch", test_tier4_226_english_hex_nix_tux_dux_and_vietnamese_hexe_nixu_tuxn_duxng_unlatch),
            ("test_tier4_227_japanese_maja_naja_haja_saja_taja_baja_gaja_daja_raja_and_vietnamese_unlatch", test_tier4_227_japanese_maja_naja_haja_saja_taja_baja_gaja_daja_raja_and_vietnamese_unlatch),
            ("test_tier4_228_japanese_nojo_hojo_sojo_tojo_bojo_gojo_nujo_hujo_tujo_gujo_dujo_rujo_and_unlatch", test_tier4_228_japanese_nojo_hojo_sojo_tojo_bojo_gojo_nujo_hujo_tujo_gujo_dujo_rujo_and_unlatch),
            ("test_tier4_229_scenario31_trilingual_gojo_hojo_hex_nix_tux_and_dowa_chat", test_tier4_229_scenario31_trilingual_gojo_hojo_hex_nix_tux_and_dowa_chat),
            ("test_tier4_230_english_and_romaji_ufo_ufos_nasa_sasa_hasa_tasa_dasa_rasa_and_unlatch", test_tier4_230_english_and_romaji_ufo_ufos_nasa_sasa_hasa_tasa_dasa_rasa_and_unlatch),
            ("test_tier4_231_english_and_romaji_taxa_maxa_naxa_haxa_saxa_baxa_gaxa_daxa_raxa_and_unlatch", test_tier4_231_english_and_romaji_taxa_maxa_naxa_haxa_saxa_baxa_gaxa_daxa_raxa_and_unlatch),
            ("test_tier4_232_romaji_mafa_nafa_hafa_safa_tafa_bafa_gafa_dafa_rafa_and_unlatch", test_tier4_232_romaji_mafa_nafa_hafa_safa_tafa_bafa_gafa_dafa_rafa_and_unlatch),
            ("test_tier4_233_romaji_mofo_nofo_hofo_sofo_tofo_bofo_gofo_dofo_rofo_and_unlatch", test_tier4_233_romaji_mofo_nofo_hofo_sofo_tofo_bofo_gofo_dofo_rofo_and_unlatch),
            ("test_tier4_234_scenario32_trilingual_nasa_ufo_taxa_sasa_and_rasa_chatbot_chat", test_tier4_234_scenario32_trilingual_nasa_ufo_taxa_sasa_and_rasa_chatbot_chat),
            ("test_tier4_235_english_memes_themes_beset_xanax_dodos_gotos_topos_datas_and_rojos", test_tier4_235_english_memes_themes_beset_xanax_dodos_gotos_topos_datas_and_rojos),
            ("test_tier4_236_japanese_turu_hufu_tufu_huju_tuju_gisi_gifi_and_vietnamese_w_unlatch", test_tier4_236_japanese_turu_hufu_tufu_huju_tuju_gisi_gifi_and_vietnamese_w_unlatch),
            ("test_tier4_237_romaji_kefe_refe_keje_reje_and_vietnamese_cmnptu_unlatch", test_tier4_237_romaji_kefe_refe_keje_reje_and_vietnamese_cmnptu_unlatch),
            ("test_tier4_238_romaji_moxo_roxo_and_vietnamese_cmnpti_unlatch", test_tier4_238_romaji_moxo_roxo_and_vietnamese_cmnpti_unlatch),
            ("test_tier4_239_scenario33_trilingual_memes_themes_turu_hufu_and_gotos_refactor_chat", test_tier4_239_scenario33_trilingual_memes_themes_turu_hufu_and_gotos_refactor_chat),
            ("test_tier4_240_english_noop_noops_dadas_hies_lire_lise_vire_vise_quasar_hangars_and_noopj_unlatch", test_tier4_240_english_noop_noops_dadas_hies_lire_lise_vire_vise_quasar_hangars_and_noopj_unlatch),
            ("test_tier4_241_japanese_hieru_hiete_nieru_niete_iete_kujo_and_vietnamese_ieu_iet_unlatch", test_tier4_241_japanese_hieru_hiete_nieru_niete_iete_kujo_and_vietnamese_ieu_iet_unlatch),
            ("test_tier4_242_vietnamese_free_tone_unlatch_tier_bier_pier_ties_dies_lies_vies_pies_hies_chief_thief", test_tier4_242_vietnamese_free_tone_unlatch_tier_bier_pier_ties_dies_lies_vies_pies_hies_chief_thief),
            ("test_tier4_243_japanese_kufo_rufo_muxu_ruxu_kuxo_ruxo_kife_dife_kije_rije_and_vietnamese_unlatch", test_tier4_243_japanese_kufo_rufo_muxu_ruxu_kuxo_ruxo_kife_dife_kije_rije_and_vietnamese_unlatch),
            ("test_tier4_244_scenario34_trilingual_noop_quasar_kujo_hieru_and_free_tone_ieu_iet_chat", test_tier4_244_scenario34_trilingual_noop_quasar_kujo_hieru_and_free_tone_ieu_iet_chat),
            ("test_tier4_245_japanese_nuete_muete_tieru_bieru_sieru_gieru_rieru_tiete_riete_and_vietnamese_unlatch", test_tier4_245_japanese_nuete_muete_tieru_bieru_sieru_gieru_rieru_tiete_riete_and_vietnamese_unlatch),
            ("test_tier4_246_japanese_kete_sete_hete_mete_tete_bete_rete_and_vietnamese_et_unlatch", test_tier4_246_japanese_kete_sete_hete_mete_tete_bete_rete_and_vietnamese_et_unlatch),
            ("test_tier4_247_vietnamese_stop_final_cvtv_unlatch_motoj_sotos_batas_bataj_gatas_gataj", test_tier4_247_vietnamese_stop_final_cvtv_unlatch_motoj_sotos_batas_bataj_gatas_gataj),
            ("test_tier4_248_vietnamese_nasal_final_cvnv_cvmv_fjx_unlatch_honof_donof_hanaj_manaj_hamaf", test_tier4_248_vietnamese_nasal_final_cvnv_cvmv_fjx_unlatch_honof_donof_hanaj_manaj_hamaf),
            ("test_tier4_249_scenario35_trilingual_nuete_hete_moto_and_vietnamese_delayed_circumflex_chat", test_tier4_249_scenario35_trilingual_nuete_hete_moto_and_vietnamese_delayed_circumflex_chat),
            ("test_tier4_250_english_and_romaji_data_goto_sata_toto_loto_mata_hata_noto_and_vietnamese_unlatch", test_tier4_250_english_and_romaji_data_goto_sata_toto_loto_mata_hata_noto_and_vietnamese_unlatch),
            ("test_tier4_251_english_and_romaji_sapa_napa_tapa_capa_topo_lapa_hopo_and_vietnamese_ap_op_ep_unlatch", test_tier4_251_english_and_romaji_sapa_napa_tapa_capa_topo_lapa_hopo_and_vietnamese_ap_op_ep_unlatch),
            ("test_tier4_252_english_and_romaji_coco_loco_poco_moco_toco_soco_doco_boco_hoco_goco_roco_and_vietnamese_oc_unlatch", test_tier4_252_english_and_romaji_coco_loco_poco_moco_toco_soco_doco_boco_hoco_goco_roco_and_vietnamese_oc_unlatch),
            ("test_tier4_253_vietnamese_nasal_final_en_em_fjx_unlatch_bened_dened_lemed_nemed_remed_semed", test_tier4_253_vietnamese_nasal_final_en_em_fjx_unlatch_bened_dened_lemed_nemed_remed_semed),
            ("test_tier4_254_scenario36_trilingual_data_goto_sata_sapa_toto_coco_and_vietnamese_delayed_circumflex_chat", test_tier4_254_scenario36_trilingual_data_goto_sata_sapa_toto_coco_and_vietnamese_delayed_circumflex_chat),
            ("test_tier4_255_english_and_romaji_choto_chata_choco_chapa_chopo_chete_chepe_quoto_photo_and_vietnamese_unlatch", test_tier4_255_english_and_romaji_choto_chata_choco_chapa_chopo_chete_chepe_quoto_photo_and_vietnamese_unlatch),
            ("test_tier4_256_japanese_chire_chise_chife_chije_chixe_chieru_chiete_and_vietnamese_ie_unlatch", test_tier4_256_japanese_chire_chise_chife_chije_chixe_chieru_chiete_and_vietnamese_ie_unlatch),
            ("test_tier4_257_japanese_churu_chure_churo_chusu_chuse_chuso_chujo_chuju_chufo_chufu_chuxu_chuxo_and_vietnamese_unlatch", test_tier4_257_japanese_churu_chure_churo_chusu_chuse_chuso_chujo_chuju_chufo_chufu_chuxu_chuxo_and_vietnamese_unlatch),
            ("test_tier4_258_japanese_chaja_chafa_chaxa_chasa_and_vietnamese_digraph_circumflex_unlatch", test_tier4_258_japanese_chaja_chafa_chaxa_chasa_and_vietnamese_digraph_circumflex_unlatch),
            ("test_tier4_259_scenario37_trilingual_choto_choco_chieru_chire_and_vietnamese_digraph_unlatch_chat", test_tier4_259_scenario37_trilingual_choto_choco_chieru_chire_and_vietnamese_digraph_unlatch_chat),
            ("test_tier4_260_english_and_romaji_chara_charas_bara_gara_dara_nara_rara_and_vietnamese_ar_unlatch", test_tier4_260_english_and_romaji_chara_charas_bara_gara_dara_nara_rara_and_vietnamese_ar_unlatch),
            ("test_tier4_261_japanese_koro_boro_goro_doro_roro_horo_toro_and_vietnamese_or_unlatch", test_tier4_261_japanese_koro_boro_goro_doro_roro_horo_toro_and_vietnamese_or_unlatch),
            ("test_tier4_262_japanese_mufe_chufe_muje_chuje_and_vietnamese_free_tone_ue_unlatch", test_tier4_262_japanese_mufe_chufe_muje_chuje_and_vietnamese_free_tone_ue_unlatch),
            ("test_tier4_263_vietnamese_duete_unlatch_duetes_duetej_and_duet_duets_preservation", test_tier4_263_vietnamese_duete_unlatch_duetes_duetej_and_duet_duets_preservation),
            ("test_tier4_264_scenario38_trilingual_chara_bara_nara_and_vietnamese_free_tone_ue_ar_or_chat", test_tier4_264_scenario38_trilingual_chara_bara_nara_and_vietnamese_free_tone_ue_ar_or_chat),
            ("test_tier4_265_japanese_dura_duri_chura_churi_and_vietnamese_ur_w_unlatch", test_tier4_265_japanese_dura_duri_chura_churi_and_vietnamese_ur_w_unlatch),
            ("test_tier4_266_japanese_rese_chese_chefe_cheje_chere_cheru_and_vietnamese_e_unlatch", test_tier4_266_japanese_rese_chese_chefe_cheje_chere_cheru_and_vietnamese_e_unlatch),
            ("test_tier4_267_english_rn_preservation_and_vietnamese_free_tone_rng_unlatch", test_tier4_267_english_rn_preservation_and_vietnamese_free_tone_rng_unlatch),
            ("test_tier4_268_english_rn_rm_preservation_and_vietnamese_free_tone_rnw_rngw_rmw_unlatch", test_tier4_268_english_rn_rm_preservation_and_vietnamese_free_tone_rnw_rngw_rmw_unlatch),
            ("test_tier4_269_scenario39_trilingual_chura_okinawa_turn_burn_and_vietnamese_free_tone_rng_chat", test_tier4_269_scenario39_trilingual_chura_okinawa_turn_burn_and_vietnamese_free_tone_rng_chat),
            ("test_tier4_270_english_goop_troop_keep_cheep_preservation_and_vietnamese_gop_trop_kep_chep_unlatch", test_tier4_270_english_goop_troop_keep_cheep_preservation_and_vietnamese_gop_trop_kep_chep_unlatch),
            ("test_tier4_271_english_loom_doom_deem_seem_keen_preservation_and_vietnamese_tone_unlatch", test_tier4_271_english_loom_doom_deem_seem_keen_preservation_and_vietnamese_tone_unlatch),
            ("test_tier4_272_english_sees_trees_toes_hoes_preservation_and_vietnamese_sep_sen_seu_toet_hoet_unlatch", test_tier4_272_english_sees_trees_toes_hoes_preservation_and_vietnamese_sep_sen_seu_toet_hoet_unlatch),
            ("test_tier4_273_japanese_hure_ture_dure_chure_preservation_and_vietnamese_huenh_tuenh_chuenh_unlatch", test_tier4_273_japanese_hure_ture_dure_chure_preservation_and_vietnamese_huenh_tuenh_chuenh_unlatch),
            ("test_tier4_274_scenario40_trilingual_goop_loom_keen_sees_toes_and_vietnamese_gop_lom_ken_sep_toet_chat", test_tier4_274_scenario40_trilingual_goop_loom_keen_sees_toes_and_vietnamese_gop_lom_ken_sep_toet_chat),
            ("test_tier4_275_english_dues_hues_sues_rues_tues_preservation_and_vietnamese_free_tone_ue_unlatch", test_tier4_275_english_dues_hues_sues_rues_tues_preservation_and_vietnamese_free_tone_ue_unlatch),
            ("test_tier4_276_english_deed_preservation_and_vietnamese_delayed_d_de_unlatch", test_tier4_276_english_deed_preservation_and_vietnamese_delayed_d_de_unlatch),
            ("test_tier4_277_english_beer_deer_door_preservation_and_vietnamese_bem_ben_deu_doi_unlatch", test_tier4_277_english_beer_deer_door_preservation_and_vietnamese_bem_ben_deu_doi_unlatch),
            ("test_tier4_278_english_soar_coax_preservation_and_vietnamese_soai_soan_coan_coao_unlatch", test_tier4_278_english_soar_coax_preservation_and_vietnamese_soai_soan_coan_coao_unlatch),
            ("test_tier4_279_scenario41_trilingual_hues_deed_beer_soar_and_vietnamese_hue_dem_deu_soai_chat", test_tier4_279_scenario41_trilingual_hues_deed_beer_soar_and_vietnamese_hue_dem_deu_soai_chat),
            ("test_tier4_280_english_died_diet_preservation_and_vietnamese_delayed_d_die_unlatch", test_tier4_280_english_died_diet_preservation_and_vietnamese_delayed_d_die_unlatch),
            ("test_tier4_281_english_door_goof_deep_keen_preservation_and_vietnamese_doi_gom_dep_kenh_unlatch", test_tier4_281_english_door_goof_deep_keen_preservation_and_vietnamese_doi_gom_dep_kenh_unlatch),
            ("test_tier4_282_vietnamese_single_e_ie_sonorant_unlatch_kirem_biren_hifen_chifen_chixen", test_tier4_282_vietnamese_single_e_ie_sonorant_unlatch_kirem_biren_hifen_chifen_chixen),
            ("test_tier4_283_vietnamese_single_e_ie_s_j_coda_unlatch_tisen_biset_hijen_dijet_tijec", test_tier4_283_vietnamese_single_e_ie_s_j_coda_unlatch_tisen_biset_hijen_dijet_tijec),
            ("test_tier4_284_scenario42_trilingual_diet_deep_keen_siren_and_vietnamese_doi_kenh_gom_hien_chat", test_tier4_284_scenario42_trilingual_diet_deep_keen_siren_and_vietnamese_doi_kenh_gom_hien_chat),
            ("test_tier4_285_vietnamese_free_order_ieue_unlatch_tireue_hireue_chiseue_chifeue_hijeue", test_tier4_285_vietnamese_free_order_ieue_unlatch_tireue_hireue_chiseue_chifeue_hijeue),
            ("test_tier4_286_vietnamese_free_order_uo_coda_w_unlatch_turongw_buroiw_mufoiw_busocw_dujocw", test_tier4_286_vietnamese_free_order_uo_coda_w_unlatch_turongw_buroiw_mufoiw_busocw_dujocw),
            ("test_tier4_287_vietnamese_delayed_d_da_do_de_unlatch_dorod_darad_dered_and_dose_preservation", test_tier4_287_vietnamese_delayed_d_da_do_de_unlatch_dorod_darad_dered_and_dose_preservation),
            ("test_tier4_288_japanese_arau_harau_sarau_tarau_narau_preservation_and_vietnamese_mau_bau_gau_dau_chau_unlatch", test_tier4_288_japanese_arau_harau_sarau_tarau_narau_preservation_and_vietnamese_mau_bau_gau_dau_chau_unlatch),
            ("test_tier4_289_scenario43_trilingual_narau_harau_dose_and_vietnamese_tuong_buoc_hieu_chieu_chat", test_tier4_289_scenario43_trilingual_narau_harau_dose_and_vietnamese_tuong_buoc_hieu_chieu_chat),
            ("test_tier4_290_english_cost_most_rust_preservation_and_vietnamese_cot_mot_rut_unlatch", test_tier4_290_english_cost_most_rust_preservation_and_vietnamese_cot_mot_rut_unlatch),
            ("test_tier4_291_english_gasp_rasp_test_preservation_and_vietnamese_gap_rap_tet_unlatch", test_tier4_291_english_gasp_rasp_test_preservation_and_vietnamese_gap_rap_tet_unlatch),
            ("test_tier4_292_english_rn_rm_preservation_and_vietnamese_free_tone_rna_rma_unlatch", test_tier4_292_english_rn_rm_preservation_and_vietnamese_free_tone_rna_rma_unlatch),
            ("test_tier4_293_english_rn_rm_preservation_and_vietnamese_free_tone_rno_rmo_unlatch", test_tier4_293_english_rn_rm_preservation_and_vietnamese_free_tone_rno_rmo_unlatch),
            ("test_tier4_294_scenario44_trilingual_cost_most_rust_test_and_vietnamese_cot_mot_tet_ton_chat", test_tier4_294_scenario44_trilingual_cost_most_rust_test_and_vietnamese_cot_mot_tet_ton_chat),
            ("test_tier4_295_english_lose_hose_preservation_and_vietnamese_loet_hoet_unlatch", test_tier4_295_english_lose_hose_preservation_and_vietnamese_loet_hoet_unlatch),
            ("test_tier4_296_japanese_baru_daru_garu_maru_naru_saru_taru_basu_dasu_gasu_preservation_and_vietnamese_au_unlatch", test_tier4_296_japanese_baru_daru_garu_maru_naru_saru_taru_basu_dasu_gasu_preservation_and_vietnamese_au_unlatch),
            ("test_tier4_297_japanese_nori_rori_and_english_term_berm_derm_kern_preservation_with_vietnamese_unlatch", test_tier4_297_japanese_nori_rori_and_english_term_berm_derm_kern_preservation_with_vietnamese_unlatch),
            ("test_tier4_298_vietnamese_free_order_uete_uenhe_ueche_unlatch", test_tier4_298_vietnamese_free_order_uete_uenhe_ueche_unlatch),
            ("test_tier4_299_scenario45_trilingual_nori_naruto_kernel_and_vietnamese_loet_noi_nau_gau_tuet_chat", test_tier4_299_scenario45_trilingual_nori_naruto_kernel_and_vietnamese_loet_noi_nau_gau_tuet_chat),
            ("test_tier4_300_vietnamese_free_order_uo_coda_o_unlatch_buroio_turoio_musoio_musono_bufono_bujoco_chujoto_turongo", test_tier4_300_vietnamese_free_order_uo_coda_o_unlatch_buroio_turoio_musoio_musono_bufono_bujoco_chujoto_turongo),
            ("test_tier4_301_english_vixen_siren_rise_preservation_and_vietnamese_vien_sien_rien_riet_unlatch", test_tier4_301_english_vixen_siren_rise_preservation_and_vietnamese_vien_sien_rien_riet_unlatch),
            ("test_tier4_302_japanese_tura_chura_hura_sura_and_english_vary_chose_those_with_vietnamese_unlatch", test_tier4_302_japanese_tura_chura_hura_sura_and_english_vary_chose_those_with_vietnamese_unlatch),
            ("test_tier4_303_japanese_tosa_sosa_dosa_sora_dora_lora_sofa_preservation_and_vietnamese_oa_coda_unlatch", test_tier4_303_japanese_tosa_sosa_dosa_sora_dora_lora_sofa_preservation_and_vietnamese_oa_coda_unlatch),
            ("test_tier4_304_scenario46_trilingual_tosa_dorayaki_sofa_and_vietnamese_buoi_muon_chuan_toan_soat_chat", test_tier4_304_scenario46_trilingual_tosa_dorayaki_sofa_and_vietnamese_buoi_muon_chuan_toan_soat_chat),
            ("test_tier4_305_english_lose_hose_chose_those_preservation_and_vietnamese_oeo_oem_oen_unlatch", test_tier4_305_english_lose_hose_chose_those_preservation_and_vietnamese_oeo_oem_oen_unlatch),
            ("test_tier4_306_english_and_romaji_tore_hore_lore_preservation_and_vietnamese_oeo_oem_oen_unlatch", test_tier4_306_english_and_romaji_tore_hore_lore_preservation_and_vietnamese_oeo_oem_oen_unlatch),
            ("test_tier4_307_japanese_tosa_sosa_sora_lora_sofa_preservation_and_vietnamese_oay_oai_unlatch", test_tier4_307_japanese_tosa_sosa_sora_lora_sofa_preservation_and_vietnamese_oay_oai_unlatch),
            ("test_tier4_308_japanese_tura_chura_hura_sura_deso_daru_dasu_and_vietnamese_uang_delayed_d_unlatch", test_tier4_308_japanese_tura_chura_hura_sura_deso_daru_dasu_and_vietnamese_uang_delayed_d_unlatch),
            ("test_tier4_309_scenario47_trilingual_dorayaki_tosai_lore_and_vietnamese_soai_loai_hoeo_toay_chat", test_tier4_309_scenario47_trilingual_dorayaki_tosai_lore_and_vietnamese_soai_loai_hoeo_toay_chat),
            ("test_tier4_310_english_tux_dux_nix_hex_preservation_and_vietnamese_dua_nia_dui_heo_unlatch", test_tier4_310_english_tux_dux_nix_hex_preservation_and_vietnamese_dua_nia_dui_heo_unlatch),
            ("test_tier4_311_english_two_twos_preservation_and_vietnamese_tuoi_tuom_tuoc_tuot_tuop_tuong_unlatch", test_tier4_311_english_two_twos_preservation_and_vietnamese_tuoi_tuom_tuoc_tuot_tuop_tuong_unlatch),
            ("test_tier4_312_english_and_romaji_cues_use_ure_ire_efu_eru_esu_duets_diets_guest_quiet_niece_unlatch", test_tier4_312_english_and_romaji_cues_use_ure_ire_efu_eru_esu_duets_diets_guest_quiet_niece_unlatch),
            ("test_tier4_313_english_and_romaji_toes_hoes_chore_aru_asa_ufo_uro_uso_uru_usu_girui_gisui_unlatch", test_tier4_313_english_and_romaji_toes_hoes_chore_aru_asa_ufo_uro_uso_uru_usu_girui_gisui_unlatch),
            ("test_tier4_314_scenario48_trilingual_asa_ufo_guest_and_vietnamese_dua_nia_tuoi_tuong_am_ap_chat", test_tier4_314_scenario48_trilingual_asa_ufo_guest_and_vietnamese_dua_nia_tuoi_tuong_am_ap_chat),
            ("test_tier4_315_english_died_preservation_and_vietnamese_dien_diem_diet_diec_diep_dieu_unlatch", test_tier4_315_english_died_preservation_and_vietnamese_dien_diem_diet_diec_diep_dieu_unlatch),
            ("test_tier4_316_english_dies_ties_lies_vies_hies_tries_trier_tier_bier_chief_thief_yes_coda_e_unlatch", test_tier4_316_english_dies_ties_lies_vies_hies_tries_trier_tier_bier_chief_thief_yes_coda_e_unlatch),
            ("test_tier4_317_english_and_romaji_ufo_uro_uso_duos_coda_o_w_unlatch", test_tier4_317_english_and_romaji_ufo_uro_uso_duos_coda_o_w_unlatch),
            ("test_tier4_318_english_and_romaji_giro_gifu_giju_gire_gise_and_vietnamese_ue_coda_e_unlatch", test_tier4_318_english_and_romaji_giro_gifu_giju_gire_gise_and_vietnamese_ue_coda_e_unlatch),
            ("test_tier4_319_scenario49_trilingual_gifu_diesel_yesterday_and_vietnamese_gioi_dien_tien_trien_uon_chat", test_tier4_319_scenario49_trilingual_gifu_diesel_yesterday_and_vietnamese_gioi_dien_tien_trien_uon_chat),
            ("test_tier4_320_english_ties_dies_lies_vies_hies_tries_trier_tier_bier_chief_thief_siren_risen_vixen_ire_ieng_unlatch", test_tier4_320_english_ties_dies_lies_vies_hies_tries_trier_tier_bier_chief_thief_siren_risen_vixen_ire_ieng_unlatch),
            ("test_tier4_321_english_and_romaji_dodos_dadas_deeds_coda_and_delayed_d_unlatch", test_tier4_321_english_and_romaji_dodos_dadas_deeds_coda_and_delayed_d_unlatch),
            ("test_tier4_322_english_and_romaji_guree_queer_queens_teens_keens_sense_tense_dense_defend_unlatch", test_tier4_322_english_and_romaji_guree_queer_queens_teens_keens_sense_tense_dense_defend_unlatch),
            ("test_tier4_323_english_and_romaji_manga_manx_minx_trex_oxen_vixen_ore_unlatch", test_tier4_323_english_and_romaji_manga_manx_minx_trex_oxen_vixen_ore_unlatch),
            ("test_tier4_324_scenario50_trilingual_manga_dodos_deeds_and_vietnamese_man_manh_tre_tieng_doi_dau_den_chat", test_tier4_324_scenario50_trilingual_manga_dodos_deeds_and_vietnamese_man_manh_tre_tieng_doi_dau_den_chat),
            ("test_tier4_325_english_dawn_lawn_down_gown_town_own_preservation_and_vietnamese_tones_g_d_unlatch", test_tier4_325_english_dawn_lawn_down_gown_town_own_preservation_and_vietnamese_tones_g_d_unlatch),
            ("test_tier4_326_english_and_romaji_barn_darn_tarn_kern_boron_moron_goons_loons_moons_nonos_chosen_urana_xanax_unlatch", test_tier4_326_english_and_romaji_barn_darn_tarn_kern_boron_moron_goons_loons_moons_nonos_chosen_urana_xanax_unlatch),
            ("test_tier4_327_romaji_bura_chura_dura_gura_hura_mura_nura_rura_sura_tura_and_vietnamese_uay_uam_uan_unlatch", test_tier4_327_romaji_bura_chura_dura_gura_hura_mura_nura_rura_sura_tura_and_vietnamese_uay_uam_uan_unlatch),
            ("test_tier4_328_english_and_romaji_queue_quiet_buys_guys_coax_sora_lora_sofa_sosa_tosa_dora_dosa_derm_unlatch", test_tier4_328_english_and_romaji_queue_quiet_buys_guys_coax_sora_lora_sofa_sosa_tosa_dora_dosa_derm_unlatch),
            ("test_tier4_329_scenario51_trilingual_dawn_queue_sofa_and_vietnamese_lang_banh_buyt_quiet_bong_chat", test_tier4_329_scenario51_trilingual_dawn_queue_sofa_and_vietnamese_lang_banh_buyt_quiet_bong_chat),
            ("test_tier4_330_vietnamese_nasal_final_cvnv_cvmv_s_r_g_unlatch_and_honor_donor_preservation", test_tier4_330_vietnamese_nasal_final_cvnv_cvmv_s_r_g_unlatch_and_honor_donor_preservation),
            ("test_tier4_331_english_two_preservation_and_vietnamese_two_frxj_unlatch", test_tier4_331_english_two_preservation_and_vietnamese_two_frxj_unlatch),
            ("test_tier4_332_english_wow_wows_preservation_and_vietnamese_uo_coda_tone_unlatch", test_tier4_332_english_wow_wows_preservation_and_vietnamese_uo_coda_tone_unlatch),
            ("test_tier4_333_english_sans_chasm_coast_coats_cusp_swops_disc_lore_preservation_and_vietnamese_unlatch", test_tier4_333_english_sans_chasm_coast_coats_cusp_swops_disc_lore_preservation_and_vietnamese_unlatch),
            ("test_tier4_334_scenario52_trilingual_sans_coast_disc_and_vietnamese_nam_nang_song_tuong_uoc_chat", test_tier4_334_scenario52_trilingual_sans_coast_disc_and_vietnamese_nam_nang_song_tuong_uoc_chat),
            ("test_tier4_335_english_cat_let_in_try_wi_preservation_and_vietnamese_diacritic_unlatch", test_tier4_335_english_cat_let_in_try_wi_preservation_and_vietnamese_diacritic_unlatch),
            ("test_tier4_336_english_var_git_deep_preservation_and_vietnamese_var_git_deepsd_unlatch", test_tier4_336_english_var_git_deep_preservation_and_vietnamese_var_git_deepsd_unlatch),
            ("test_tier4_337_romaji_gifi_gisi_giji_preservation_and_vietnamese_gim_gin_ginh_gic_gich_gip_git_unlatch", test_tier4_337_romaji_gifi_gisi_giji_preservation_and_vietnamese_gim_gin_ginh_gic_gich_gip_git_unlatch),
            ("test_tier4_338_english_rise_sire_hex_trex_preservation_and_vietnamese_riem_riec_riep_riet_siem_heu_treu_unlatch", test_tier4_338_english_rise_sire_hex_trex_preservation_and_vietnamese_riem_riec_riep_riet_siem_heu_treu_unlatch),
            ("test_tier4_339_scenario53_trilingual_cat_let_try_in_var_git_and_vietnamese_cat_let_inh_vang_riet_chat", test_tier4_339_scenario53_trilingual_cat_let_try_in_var_git_and_vietnamese_cat_let_inh_vang_riet_chat),
            ("test_tier4_340_romaji_dufo_duro_duso_duxo_dujo_duru_dusu_dufu_duju_delayed_d_unlatch", test_tier4_340_romaji_dufo_duro_duso_duxo_dujo_duru_dusu_dufu_duju_delayed_d_unlatch),
            ("test_tier4_341_romaji_dife_dise_dije_dire_delayed_d_ie_unlatch", test_tier4_341_romaji_dife_dise_dije_dire_delayed_d_ie_unlatch),
            ("test_tier4_342_romaji_oto_otosu_ieru_preservation_and_vietnamese_ot_ieu_unlatch", test_tier4_342_romaji_oto_otosu_ieru_preservation_and_vietnamese_ot_ieu_unlatch),
            ("test_tier4_343_english_here_there_mere_sere_these_preservation_and_vietnamese_e_coda_unlatch", test_tier4_343_english_here_there_mere_sere_these_preservation_and_vietnamese_e_coda_unlatch),
            ("test_tier4_344_scenario54_trilingual_otosu_ieru_here_there_and_vietnamese_duong_duoc_dien_dieu_chat", test_tier4_344_scenario54_trilingual_otosu_ieru_here_there_and_vietnamese_duong_duoc_dien_dieu_chat),
            ("test_tier4_345_romaji_du_a_du_i_delayed_d_unlatch_and_soaps_preservation", test_tier4_345_romaji_du_a_du_i_delayed_d_unlatch_and_soaps_preservation),
            ("test_tier4_346_romaji_du_e_di_e_delayed_d_before_final_e_unlatch", test_tier4_346_romaji_du_e_di_e_delayed_d_before_final_e_unlatch),
            ("test_tier4_347_romaji_de_u_da_u_da_y_do_i_dorm_delayed_d_unlatch", test_tier4_347_romaji_de_u_da_u_da_y_do_i_dorm_delayed_d_unlatch),
            ("test_tier4_348_english_lure_sure_cure_muse_ruse_hire_tire_mire_preservation_and_vietnamese_unlatch", test_tier4_348_english_lure_sure_cure_muse_ruse_hire_tire_mire_preservation_and_vietnamese_unlatch),
            ("test_tier4_349_scenario55_trilingual_soaps_sure_hire_and_vietnamese_duoc_dieu_dau_doi_chat", test_tier4_349_scenario55_trilingual_soaps_sure_hire_and_vietnamese_duoc_dieu_dau_doi_chat),
            ("test_tier4_350_romaji_and_english_sora_lora_sofa_sosa_tosa_dora_dosa_w_unlatch", test_tier4_350_romaji_and_english_sora_lora_sofa_sosa_tosa_dora_dosa_w_unlatch),
            ("test_tier4_351_vietnamese_delayed_d_doai_doay_doao_all_tone_positions_and_dosai_preservation", test_tier4_351_vietnamese_delayed_d_doai_doay_doao_all_tone_positions_and_dosai_preservation),
            ("test_tier4_352_romaji_and_english_ufong_urong_usong_duos_gifuo_gijuo_unlatch", test_tier4_352_romaji_and_english_ufong_urong_usong_duos_gifuo_gijuo_unlatch),
            ("test_tier4_353_delayed_d_before_coda_before_e_on_di_e_du_e_and_honor_donor_manag_monog_osoi_unlatch", test_tier4_353_delayed_d_before_coda_before_e_on_di_e_du_e_and_honor_donor_manag_monog_osoi_unlatch),
            ("test_tier4_354_scenario56_trilingual_dosai_duos_gifu_manager_and_vietnamese_giuong_uong_doai_chat", test_tier4_354_scenario56_trilingual_dosai_duos_gifu_manager_and_vietnamese_giuong_uong_doai_chat),
            ("test_tier4_355_romaji_coro_cofo_coso_cojo_w_unlatch_and_preservation", test_tier4_355_romaji_coro_cofo_coso_cojo_w_unlatch_and_preservation),
            ("test_tier4_356_romaji_cara_casa_cafa_caja_w_unlatch_and_preservation", test_tier4_356_romaji_cara_casa_cafa_caja_w_unlatch_and_preservation),
            ("test_tier4_357_english_and_romaji_boron_moron_datas_gotos_topos_dodos_dadas_and_cvnv_cvmv_w_unlatch", test_tier4_357_english_and_romaji_boron_moron_datas_gotos_topos_dodos_dadas_and_cvnv_cvmv_w_unlatch),
            ("test_tier4_358_english_siren_risen_vixen_died_dies_preservation_and_vietnamese_sireng_riseng_vixem_dired_diesd_unlatch", test_tier4_358_english_siren_risen_vixen_died_dies_preservation_and_vietnamese_sireng_riseng_vixem_dired_diesd_unlatch),
            ("test_tier4_359_scenario57_trilingual_moron_datas_siren_dojo_and_vietnamese_mo_han_dat_diem_chat", test_tier4_359_scenario57_trilingual_moron_datas_siren_dojo_and_vietnamese_mo_han_dat_diem_chat),
            ("test_tier4_360_english_door_goof_loom_doom_w_unlatch_and_preservation", test_tier4_360_english_door_goof_loom_doom_w_unlatch_and_preservation),
            ("test_tier4_361_english_plural_oo_words_and_mamas_nonos_w_unlatch", test_tier4_361_english_plural_oo_words_and_mamas_nonos_w_unlatch),
            ("test_tier4_362_english_and_romaji_dojos_rojos_loofs_oofs_charas_unlatch", test_tier4_362_english_and_romaji_dojos_rojos_loofs_oofs_charas_unlatch),
            ("test_tier4_363_english_duet_duets_preservation_and_vietnamese_duetj_duetsd_duetds_delayed_e_unlatch", test_tier4_363_english_duet_duets_preservation_and_vietnamese_duetj_duetsd_duetds_delayed_e_unlatch),
            ("test_tier4_364_scenario58_trilingual_rooms_troops_roots_boost_and_vietnamese_lon_rot_chac_chan_chat", test_tier4_364_scenario58_trilingual_rooms_troops_roots_boost_and_vietnamese_lon_rot_chac_chan_chat),
            ("test_tier4_365_english_ties_dies_lies_vies_hies_tries_single_e_coda_unlatch_and_preservation", test_tier4_365_english_ties_dies_lies_vies_hies_tries_single_e_coda_unlatch_and_preservation),
            ("test_tier4_366_english_tier_bier_pier_trier_chief_thief_single_e_sonorant_unlatch_and_preservation", test_tier4_366_english_tier_bier_pier_trier_chief_thief_single_e_sonorant_unlatch_and_preservation),
            ("test_tier4_367_romaji_and_english_cvptv_oto_w_before_tone_unlatch_and_preservation", test_tier4_367_romaji_and_english_cvptv_oto_w_before_tone_unlatch_and_preservation),
            ("test_tier4_368_english_and_romaji_honor_donor_asa_w_and_dire_difed_dijed_single_e_unlatch", test_tier4_368_english_and_romaji_honor_donor_asa_w_and_dire_difed_dijed_single_e_unlatch),
            ("test_tier4_369_scenario59_trilingual_chief_tier_sapa_oto_and_vietnamese_tien_viet_bien_dat_chat", test_tier4_369_scenario59_trilingual_chief_tier_sapa_oto_and_vietnamese_tien_viet_bien_dat_chat),
            ("test_tier4_370_english_died_tone_coda_and_dieu_unlatch_and_preservation", test_tier4_370_english_died_tone_coda_and_dieu_unlatch_and_preservation),
            ("test_tier4_371_english_plural_rns_rms_w_and_g_unlatch_and_preservation", test_tier4_371_english_plural_rns_rms_w_and_g_unlatch_and_preservation),
            ("test_tier4_372_romaji_osoi_hosoi_moroi_noroi_soroi_w_unlatch_and_preservation", test_tier4_372_romaji_osoi_hosoi_moroi_noroi_soroi_w_unlatch_and_preservation),
            ("test_tier4_373_romaji_dora_dosa_and_english_kern_tern_unlatch_and_preservation", test_tier4_373_romaji_dora_dosa_and_english_kern_tern_unlatch_and_preservation),
            ("test_tier4_374_scenario60_trilingual_kernel_hosoi_turns_and_vietnamese_dien_dieu_doan_doi_chat", test_tier4_374_scenario60_trilingual_kernel_hosoi_turns_and_vietnamese_dien_dieu_doan_doi_chat),
            ("test_tier4_375_english_keen_keens_teens_g_and_leers_seers_cheers_veers_coda_unlatch", test_tier4_375_english_keen_keens_teens_g_and_leers_seers_cheers_veers_coda_unlatch),
            ("test_tier4_376_english_soars_loafs_oafs_coifs_unlatch_and_preservation", test_tier4_376_english_soars_loafs_oafs_coifs_unlatch_and_preservation),
            ("test_tier4_377_english_chefs_refs_midword_tone_override_unlatch_and_preservation", test_tier4_377_english_chefs_refs_midword_tone_override_unlatch_and_preservation),
            ("test_tier4_378_english_hoofs_roofs_goofs_unlatch_and_preservation", test_tier4_378_english_hoofs_roofs_goofs_unlatch_and_preservation),
            ("test_tier4_379_scenario61_trilingual_cheers_chefs_roofs_and_vietnamese_keeng_soat_bep_goc_chat", test_tier4_379_scenario61_trilingual_cheers_chefs_roofs_and_vietnamese_keeng_soat_bep_goc_chat),
            ("test_tier4_380_english_bars_cars_mars_tars_midword_tone_override_unlatch_and_preservation", test_tier4_380_english_bars_cars_mars_tars_midword_tone_override_unlatch_and_preservation),
            ("test_tier4_381_english_hers_ers_vers_sirs_dirs_midword_tone_override_unlatch_and_preservation", test_tier4_381_english_hers_ers_vers_sirs_dirs_midword_tone_override_unlatch_and_preservation),
            ("test_tier4_382_english_ors_urs_curs_burs_midword_tone_override_unlatch_and_preservation", test_tier4_382_english_ors_urs_curs_burs_midword_tone_override_unlatch_and_preservation),
            ("test_tier4_383_english_barf_barfs_nerf_nerfs_serf_serfs_kerf_surf_turf_tone_override_unlatch", test_tier4_383_english_barf_barfs_nerf_nerfs_serf_serfs_kerf_surf_turf_tone_override_unlatch),
            ("test_tier4_384_scenario62_trilingual_cars_bars_surf_and_vietnamese_ban_het_cuu_nen_chat", test_tier4_384_scenario62_trilingual_cars_bars_surf_and_vietnamese_ban_het_cuu_nen_chat),
            ("test_tier4_385_english_oars_choirs_moors_boors_unlatch_and_preservation", test_tier4_385_english_oars_choirs_moors_boors_unlatch_and_preservation),
            ("test_tier4_386_english_ores_tores_hores_lores_chores_ore_unlatch_and_preservation", test_tier4_386_english_ores_tores_hores_lores_chores_ore_unlatch_and_preservation),
            ("test_tier4_387_english_hires_tires_mires_sires_berms_unlatch_and_preservation", test_tier4_387_english_hires_tires_mires_sires_berms_unlatch_and_preservation),
            ("test_tier4_388_english_plural_midword_tone_override_preservation_and_unlatch_matrix", test_tier4_388_english_plural_midword_tone_override_preservation_and_unlatch_matrix),
            ("test_tier4_389_scenario63_trilingual_choirs_chores_tires_and_vietnamese_choi_bon_hien_toet_chat", test_tier4_389_scenario63_trilingual_choirs_chores_tires_and_vietnamese_choi_bon_hien_toet_chat),
            ("test_tier4_390_vietnamese_general_midword_tone_override_rs_rf_rj_rx_sf_sr_sj_sx", test_tier4_390_vietnamese_general_midword_tone_override_rs_rf_rj_rx_sf_sr_sj_sx),
            ("test_tier4_391_english_beer_deer_beers_deers_tone_override_and_coda_unlatch", test_tier4_391_english_beer_deer_beers_deers_tone_override_and_coda_unlatch),
            ("test_tier4_392_english_door_doors_goof_tone_override_and_coda_unlatch", test_tier4_392_english_door_doors_goof_tone_override_and_coda_unlatch),
            ("test_tier4_393_english_soar_coax_tore_hore_lore_chore_ore_lose_hose_chose_those_tone_override_unlatch", test_tier4_393_english_soar_coax_tore_hore_lore_chore_ore_lose_hose_chose_those_tone_override_unlatch),
            ("test_tier4_394_scenario64_trilingual_doors_beers_coax_and_vietnamese_dong_den_soan_ban_chat", test_tier4_394_scenario64_trilingual_doors_beers_coax_and_vietnamese_dong_den_soan_ban_chat),
            ("test_tier4_395_english_barn_darn_tarn_born_corn_horn_morn_torn_tone_override_unlatch", test_tier4_395_english_barn_darn_tarn_born_corn_horn_morn_torn_tone_override_unlatch),
            ("test_tier4_396_english_burn_turn_churn_urn_harm_charm_norm_dorm_corm_tone_override_unlatch", test_tier4_396_english_burn_turn_churn_urn_harm_charm_norm_dorm_corm_tone_override_unlatch),
            ("test_tier4_397_english_term_berm_derm_kern_tern_tone_override_and_plural_e_unlatch", test_tier4_397_english_term_berm_derm_kern_tern_tone_override_and_plural_e_unlatch),
            ("test_tier4_398_english_plural_rns_rms_circumflex_and_palatal_unlatch", test_tier4_398_english_plural_rns_rms_circumflex_and_palatal_unlatch),
            ("test_tier4_399_scenario65_trilingual_norms_terms_harmful_and_vietnamese_cham_ung_thong_kenh_chat", test_tier4_399_scenario65_trilingual_norms_terms_harmful_and_vietnamese_cham_ung_thong_kenh_chat),
            ("test_tier4_400_english_st_sp_sc_keyword_stems_midword_dot_tone_override_unlatch", test_tier4_400_english_st_sp_sc_keyword_stems_midword_dot_tone_override_unlatch),
            ("test_tier4_401_english_rt_rp_rc_stems_midword_dot_tone_override_unlatch", test_tier4_401_english_rt_rp_rc_stems_midword_dot_tone_override_unlatch),
            ("test_tier4_402_english_ft_xt_stems_midword_dot_tone_override_unlatch", test_tier4_402_english_ft_xt_stems_midword_dot_tone_override_unlatch),
            ("test_tier4_403_english_var_and_yes_midword_tone_override_unlatch_and_preservation", test_tier4_403_english_var_and_yes_midword_tone_override_unlatch_and_preservation),
            ("test_tier4_404_scenario66_trilingual_cost_most_disc_var_yes_and_vietnamese_mot_gap_dich_va_yen_chat", test_tier4_404_scenario66_trilingual_cost_most_disc_var_yes_and_vietnamese_mot_gap_dich_va_yen_chat),
            ("test_tier4_405_english_barf_nerf_serf_kerf_surf_turf_dot_and_tilde_tone_override_unlatch", test_tier4_405_english_barf_nerf_serf_kerf_surf_turf_dot_and_tilde_tone_override_unlatch),
            ("test_tier4_406_vietnamese_fc_fp_xc_xp_midword_acute_and_dot_tone_override_unlatch", test_tier4_406_vietnamese_fc_fp_xc_xp_midword_acute_and_dot_tone_override_unlatch),
            ("test_tier4_407_vietnamese_ft_xt_midword_acute_tone_override_and_english_plural_preservation", test_tier4_407_vietnamese_ft_xt_midword_acute_tone_override_and_english_plural_preservation),
            ("test_tier4_408_english_and_vietnamese_rch_fch_xch_acute_and_dot_tone_override_unlatch", test_tier4_408_english_and_vietnamese_rch_fch_xch_acute_and_dot_tone_override_unlatch),
            ("test_tier4_409_scenario67_trilingual_gifts_texts_surf_march_and_vietnamese_tu_su_sach_ke_khach_chat", test_tier4_409_scenario67_trilingual_gifts_texts_surf_march_and_vietnamese_tu_su_sach_ke_khach_chat),
            ("test_tier4_410_vietnamese_collocation_phrases_on_chai_lan_man_san_rot_the_au_den_ret", test_tier4_410_vietnamese_collocation_phrases_on_chai_lan_man_san_rot_the_au_den_ret),
            ("test_tier4_411_english_awn_own_awns_owns_circumflex_and_midword_tone_override_unlatch", test_tier4_411_english_awn_own_awns_owns_circumflex_and_midword_tone_override_unlatch),
            ("test_tier4_412_english_chair_lair_hairs_chairs_lairs_airs_tone_override_unlatch", test_tier4_412_english_chair_lair_hairs_chairs_lairs_airs_tone_override_unlatch),
            ("test_tier4_413_english_boron_moron_morons_beset_reset_in_tone_override_unlatch", test_tier4_413_english_boron_moron_morons_beset_reset_in_tone_override_unlatch),
            ("test_tier4_414_scenario68_trilingual_install_inside_reset_and_vietnamese_biet_on_ban_chai_the_he_chat", test_tier4_414_scenario68_trilingual_install_inside_reset_and_vietnamese_biet_on_ban_chai_the_he_chat),
            ("test_tier4_415_vietnamese_goa_noan_orthography_and_romaji_english_phrase_collocations", test_tier4_415_vietnamese_goa_noan_orthography_and_romaji_english_phrase_collocations),
            ("test_tier4_416_english_plural_ooms_oons_eems_eens_tone_override_unlatch", test_tier4_416_english_plural_ooms_oons_eems_eens_tone_override_unlatch),
            ("test_tier4_417_english_stop_coda_plurals_and_stems_dot_tone_override_unlatch", test_tier4_417_english_stop_coda_plurals_and_stems_dot_tone_override_unlatch),
            ("test_tier4_418_english_oxen_vixen_siren_sirens_risen_tureen_chosen_tone_override_unlatch", test_tier4_418_english_oxen_vixen_siren_sirens_risen_tureen_chosen_tone_override_unlatch),
            ("test_tier4_419_scenario69_trilingual_suwa_photos_rooms_and_vietnamese_say_sua_goa_phu_noan_cau_chat", test_tier4_419_scenario69_trilingual_suwa_photos_rooms_and_vietnamese_say_sua_goa_phu_noan_cau_chat),
            ("test_tier4_420_vietnamese_collocation_phrases_ban_tan_bun_tun_bon_con_dom_bem", test_tier4_420_vietnamese_collocation_phrases_ban_tan_bun_tun_bon_con_dom_bem),
            ("test_tier4_421_english_plural_rns_rms_midword_tone_override_unlatch", test_tier4_421_english_plural_rns_rms_midword_tone_override_unlatch),
            ("test_tier4_422_english_plural_oors_oofs_odos_ojos_adas_aras_tone_override_unlatch", test_tier4_422_english_plural_oors_oofs_odos_ojos_adas_aras_tone_override_unlatch),
            ("test_tier4_423_english_plural_eers_eefs_ees_uys_oars_oafs_oifs_oirs_aifs_iars_toes_hoes_does_unlatch", test_tier4_423_english_plural_eers_eefs_ees_uys_oars_oafs_oifs_oirs_aifs_iars_toes_hoes_does_unlatch),
            ("test_tier4_424_scenario70_trilingual_burn_turn_dorm_and_vietnamese_co_ban_tan_nhiet_bun_run_hang_dom_chat", test_tier4_424_scenario70_trilingual_burn_turn_dorm_and_vietnamese_co_ban_tan_nhiet_bun_run_hang_dom_chat),
            ("test_tier4_425_vietnamese_collocation_phrases_heo_neo_keo_meo_beo_heo_teo_neo_sau_bau_nau_tau", test_tier4_425_vietnamese_collocation_phrases_heo_neo_keo_meo_beo_heo_teo_neo_sau_bau_nau_tau),
            ("test_tier4_426_vietnamese_collocation_phrases_tui_mui_rui_hui_sui_rai_sao_biu_biu_niu_riu_riu_niu", test_tier4_426_vietnamese_collocation_phrases_tui_mui_rui_hui_sui_rai_sao_biu_biu_niu_riu_riu_niu),
            ("test_tier4_427_romaji_and_english_ero_eso_maso_saso_rari_nori_rori_tone_override_unlatch", test_tier4_427_romaji_and_english_ero_eso_maso_saso_rari_nori_rori_tone_override_unlatch),
            ("test_tier4_428_romaji_uri_iru_isu_ifu_iju_aru_asu_tone_override_unlatch", test_tier4_428_romaji_uri_iru_isu_ifu_iju_aru_asu_tone_override_unlatch),
            ("test_tier4_429_scenario71_trilingual_hero_sasuke_naruto_and_vietnamese_heo_lanh_thu_sau_quy_bau_ban_biu_chat", test_tier4_429_scenario71_trilingual_hero_sasuke_naruto_and_vietnamese_heo_lanh_thu_sau_quy_bau_ban_biu_chat),
            ("test_tier4_430_vietnamese_medial_tone_goa_noan_and_oa_ua_e_o_collocations", test_tier4_430_vietnamese_medial_tone_goa_noan_and_oa_ua_e_o_collocations),
            ("test_tier4_431_romaji_ura_ora_osa_sofa_tone_override_unlatch", test_tier4_431_romaji_ura_ora_osa_sofa_tone_override_unlatch),
            ("test_tier4_432_romaji_coro_coso_cofo_cojo_coxo_tone_override_unlatch", test_tier4_432_romaji_coro_coso_cofo_cojo_coxo_tone_override_unlatch),
            ("test_tier4_433_romaji_cere_cese_cefe_ceje_tone_override_unlatch_and_english_preservation", test_tier4_433_romaji_cere_cese_cefe_ceje_tone_override_unlatch_and_english_preservation),
            ("test_tier4_434_scenario72_trilingual_sofa_dora_defer_and_vietnamese_goa_noan_cua_so_mat_ho_chat", test_tier4_434_scenario72_trilingual_sofa_dora_defer_and_vietnamese_goa_noan_cua_so_mat_ho_chat),
            ("test_tier4_435_vietnamese_collocation_phrases_te_ke_be_ne_he_te_be_ke_te_he_ke", test_tier4_435_vietnamese_collocation_phrases_te_ke_be_ne_he_te_be_ke_te_he_ke),
            ("test_tier4_436_vietnamese_collocation_phrases_ho_to_so_ro_mo_to_so_ho_bo_no_go", test_tier4_436_vietnamese_collocation_phrases_ho_to_so_ro_mo_to_so_ho_bo_no_go),
            ("test_tier4_437_romaji_cara_casa_cafa_caja_caxa_tone_override_and_coda_unlatch", test_tier4_437_romaji_cara_casa_cafa_caja_caxa_tone_override_and_coda_unlatch),
            ("test_tier4_438_romaji_cojo_coxo_ceje_chefe_and_english_honor_donor_tone_override_unlatch", test_tier4_438_romaji_cojo_coxo_ceje_chefe_and_english_honor_donor_tone_override_unlatch),
            ("test_tier4_439_scenario73_trilingual_gojo_soso_honor_and_vietnamese_kinh_te_thiet_ke_can_ho_cay_go_chat", test_tier4_439_scenario73_trilingual_gojo_soso_honor_and_vietnamese_kinh_te_thiet_ke_can_ho_cay_go_chat),
            ("test_tier4_440_vietnamese_collocation_phrases_san_han_ham_sam_hon_mon_hom_ro_ro_do_ho_no_ne_re_reo_miu", test_tier4_440_vietnamese_collocation_phrases_san_han_ham_sam_hon_mon_hom_ro_ro_do_ho_no_ne_re_reo_miu),
            ("test_tier4_441_romaji_curo_cuso_cufo_cujo_cuxo_tone_override_and_duos_unlatch", test_tier4_441_romaji_curo_cuso_cufo_cujo_cuxo_tone_override_and_duos_unlatch),
            ("test_tier4_442_romaji_curu_cusu_cufu_cuju_cuxu_tone_override_w_unlatch", test_tier4_442_romaji_curu_cusu_cufu_cuju_cuxu_tone_override_w_unlatch),
            ("test_tier4_443_romaji_giro_gifu_giju_gire_gise_tone_override_and_dure_duse_dufe_duje_delayed_d_unlatch", test_tier4_443_romaji_giro_gifu_giju_gire_gise_tone_override_and_dure_duse_dufe_duje_delayed_d_unlatch),
            ("test_tier4_444_scenario74_trilingual_sana_mono_duos_and_vietnamese_nhan_sam_hoang_hon_chieu_hom_chat", test_tier4_444_scenario74_trilingual_sana_mono_duos_and_vietnamese_nhan_sam_hoang_hon_chieu_hom_chat),
            ("test_tier4_445_vietnamese_collocation_phrases_che_de_re_me_te_de_be_se_che_de_re_se_me_so_to_do_mo_mia_ria_dua_chui", test_tier4_445_vietnamese_collocation_phrases_che_de_re_me_te_de_be_se_che_de_re_se_me_so_to_do_mo_mia_ria_dua_chui),
            ("test_tier4_446_delayed_circumflex_stop_coda_w_sj_and_d_sj_unlatch", test_tier4_446_delayed_circumflex_stop_coda_w_sj_and_d_sj_unlatch),
            ("test_tier4_447_delayed_circumflex_nasal_coda_ang_ong_enh_en_em_and_managw_unlatch", test_tier4_447_delayed_circumflex_nasal_coda_ang_ong_enh_en_em_and_managw_unlatch),
            ("test_tier4_448_romaji_cire_cise_cife_cije_cure_cuse_cufe_cuje_tone_override_unlatch", test_tier4_448_romaji_cire_cise_cife_cije_cure_cuse_cufe_cuje_tone_override_unlatch),
            ("test_tier4_449_scenario75_trilingual_chese_misa_tojo_and_vietnamese_co_che_nuoc_mia_ca_kho_to_chat", test_tier4_449_scenario75_trilingual_chese_misa_tojo_and_vietnamese_co_che_nuoc_mia_ca_kho_to_chat),
            ("test_tier4_450_vietnamese_collocation_phrases_giai_soai_toai_hoai_hoi_moi_tau_hau_giui_giui", test_tier4_450_vietnamese_collocation_phrases_giai_soai_toai_hoai_hoi_moi_tau_hau_giui_giui),
            ("test_tier4_451_romaji_osoi_hosoi_moroi_noroi_soroi_girui_gisui_girai_gisai_horai_torai_hosai_sosai_tosai_tone_override_unlatch", test_tier4_451_romaji_osoi_hosoi_moroi_noroi_soroi_girui_gisui_girai_gisai_horai_torai_hosai_sosai_tosai_tone_override_unlatch),
            ("test_tier4_452_romaji_arau_harau_sarau_tarau_narau_and_ieru_kieru_mieru_hieru_nieru_tieru_bieru_sieru_gieru_rieru_chieru_tone_override_unlatch", test_tier4_452_romaji_arau_harau_sarau_tarau_narau_and_ieru_kieru_mieru_hieru_nieru_tieru_bieru_sieru_gieru_rieru_chieru_tone_override_unlatch),
            ("test_tier4_453_romaji_ceru_cesu_cefu_tone_override_neros_reros_and_refuse_preservation", test_tier4_453_romaji_ceru_cesu_cefu_tone_override_neros_reros_and_refuse_preservation),
            ("test_tier4_454_scenario76_trilingual_kieru_hosoi_sosai_and_vietnamese_ly_giai_nguyen_soai_sam_hoi_chat", test_tier4_454_scenario76_trilingual_kieru_hosoi_sosai_and_vietnamese_ly_giai_nguyen_soai_sam_hoi_chat),
            ("test_tier4_455_vietnamese_collocation_phrases_gui_dui_nui_bui_me_de_go_so_bo_mo_no_se_ne_he_kiu_hiu_kia_chia", test_tier4_455_vietnamese_collocation_phrases_gui_dui_nui_bui_me_de_go_so_bo_mo_no_se_ne_he_kiu_hiu_kia_chia),
            ("test_tier4_456_romaji_cira_cisa_rira_misa_kisa_hisa_chisa_tone_override_unlatch", test_tier4_456_romaji_cira_cisa_rira_misa_kisa_hisa_chisa_tone_override_unlatch),
            ("test_tier4_457_romaji_kiru_kisu_kifu_kiju_tone_override_unlatch", test_tier4_457_romaji_kiru_kisu_kifu_kiju_tone_override_unlatch),
            ("test_tier4_458_romaji_sora_lora_dora_sosa_tosa_dosa_sofa_and_nora_tone_and_vowel_unlatch", test_tier4_458_romaji_sora_lora_dora_sosa_tosa_dosa_sofa_and_nora_tone_and_vowel_unlatch),
            ("test_tier4_459_scenario77_trilingual_kisu_meje_gofo_and_vietnamese_gan_gui_ngan_nui_ba_me_bong_se_chat", test_tier4_459_scenario77_trilingual_kisu_meje_gofo_and_vietnamese_gan_gui_ngan_nui_ba_me_bong_se_chat),
            ("test_tier4_460_vietnamese_collocation_phrases_beer_deer_sees_deed_deeds_booms_sere_gisai_torai_hosai_nori_maso", test_tier4_460_vietnamese_collocation_phrases_beer_deer_sees_deed_deeds_booms_sere_gisai_torai_hosai_nori_maso),
            ("test_tier4_461_vowel_initial_romaji_ire_ure_use_eru_esu_efu_tone_override_and_e_unlatch", test_tier4_461_vowel_initial_romaji_ire_ure_use_eru_esu_efu_tone_override_and_e_unlatch),
            ("test_tier4_462_vowel_initial_ufo_uro_uso_tone_override_and_wo_unlatch", test_tier4_462_vowel_initial_ufo_uro_uso_tone_override_and_wo_unlatch),
            ("test_tier4_463_vowel_initial_aru_iru_isu_asa_and_roes_noes_tone_override_unlatch", test_tier4_463_vowel_initial_aru_iru_isu_asa_and_roes_noes_tone_override_unlatch),
            ("test_tier4_464_scenario78_trilingual_ufos_beer_deed_and_vietnamese_boi_be_con_de_hoang_de_con_giai_chat", test_tier4_464_scenario78_trilingual_ufos_beer_deed_and_vietnamese_boi_be_con_de_hoang_de_con_giai_chat),
        ]
    }
}
