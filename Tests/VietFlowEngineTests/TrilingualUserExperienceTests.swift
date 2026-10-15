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
    // MARK: - Test Registration (279 Tests)
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
        ]
    }
}
