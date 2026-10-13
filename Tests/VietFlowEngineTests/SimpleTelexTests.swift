//
//  SimpleTelexTests.swift
//  VietFlowEngineTests
//
//  Tier 1: Simple Telex Input Method Specification Tests (>= 80 test cases)
//  Key distinction: 'w' is strictly a diacritic modifier and does NOT produce standalone 'ư'.
//

import Foundation
import VietFlowEngine

public final class SimpleTelexTests: VietFlowTestCase {
    private var engine: VietnameseEngineProtocol!
    
    public override func setUp() {
        super.setUp()
        engine = makeEngine(inputMethod: .simpleTelex, tonePlacement: .modern)
    }
    
    private func assertSimpleTelex(_ input: String, _ expected: String, file: StaticString = #file, line: UInt = #line) {
        engine.reset()
        let (_, output) = typeSequence(input, into: engine)
        XCTAssertEqual(output, expected, "Failed Simple Telex for: '\(input)'", file: file, line: line)
    }
    
    // MARK: - 'w' Standalone Preservation (15 tests)
    func test_simpletelex_w_standalone() { assertSimpleTelex("w", "w") }
    func test_simpletelex_ww_standalone() { assertSimpleTelex("ww", "ww") }
    func test_simpletelex_www_url() { assertSimpleTelex("www", "www") }
    func test_simpletelex_web() { assertSimpleTelex("web", "web") }
    func test_simpletelex_win() { assertSimpleTelex("win", "win") }
    func test_simpletelex_wifi() { assertSimpleTelex("wifi", "wifi") }
    func test_simpletelex_word() { assertSimpleTelex("word", "word") }
    func test_simpletelex_work() { assertSimpleTelex("work", "work") }
    func test_simpletelex_wiki() { assertSimpleTelex("wiki", "wiki") }
    func test_simpletelex_warning() { assertSimpleTelex("warning", "warning") }
    func test_simpletelex_water() { assertSimpleTelex("water", "water") }
    func test_simpletelex_welcome() { assertSimpleTelex("welcome", "welcome") }
    func test_simpletelex_window() { assertSimpleTelex("window", "window") }
    func test_simpletelex_wa_not_ua() { assertSimpleTelex("wa", "wa") }
    func test_simpletelex_we_not_ue() { assertSimpleTelex("we", "we") }
    
    // MARK: - Diacritics via Double Key & Modifier 'w' (14 tests)
    func test_simpletelex_diacritic_aa() { assertSimpleTelex("aa", "â") }
    func test_simpletelex_diacritic_ee() { assertSimpleTelex("ee", "ê") }
    func test_simpletelex_diacritic_oo() { assertSimpleTelex("oo", "ô") }
    func test_simpletelex_diacritic_dd() { assertSimpleTelex("dd", "đ") }
    func test_simpletelex_diacritic_aw() { assertSimpleTelex("aw", "ă") }
    func test_simpletelex_diacritic_ow() { assertSimpleTelex("ow", "ơ") }
    func test_simpletelex_diacritic_uw() { assertSimpleTelex("uw", "ư") }
    
    func test_simpletelex_diacritic_AA() { assertSimpleTelex("AA", "Â") }
    func test_simpletelex_diacritic_EE() { assertSimpleTelex("EE", "Ê") }
    func test_simpletelex_diacritic_OO() { assertSimpleTelex("OO", "Ô") }
    func test_simpletelex_diacritic_DD() { assertSimpleTelex("DD", "Đ") }
    func test_simpletelex_diacritic_AW() { assertSimpleTelex("AW", "Ă") }
    func test_simpletelex_diacritic_OW() { assertSimpleTelex("OW", "Ơ") }
    func test_simpletelex_diacritic_UW() { assertSimpleTelex("UW", "Ư") }
    
    // MARK: - Vowels with Tones in Simple Telex (25 tests)
    func test_simpletelex_tone_as() { assertSimpleTelex("as", "á") }
    func test_simpletelex_tone_af() { assertSimpleTelex("af", "à") }
    func test_simpletelex_tone_ar() { assertSimpleTelex("ar", "ả") }
    func test_simpletelex_tone_ax() { assertSimpleTelex("ax", "ã") }
    func test_simpletelex_tone_aj() { assertSimpleTelex("aj", "ạ") }
    
    func test_simpletelex_tone_aws() { assertSimpleTelex("aws", "ắ") }
    func test_simpletelex_tone_awf() { assertSimpleTelex("awf", "ằ") }
    func test_simpletelex_tone_awr() { assertSimpleTelex("awr", "ẳ") }
    func test_simpletelex_tone_awx() { assertSimpleTelex("awx", "ẵ") }
    func test_simpletelex_tone_awj() { assertSimpleTelex("awj", "ặ") }
    
    func test_simpletelex_tone_aas() { assertSimpleTelex("aas", "ấ") }
    func test_simpletelex_tone_aaf() { assertSimpleTelex("aaf", "ầ") }
    func test_simpletelex_tone_aar() { assertSimpleTelex("aar", "ẩ") }
    func test_simpletelex_tone_aax() { assertSimpleTelex("aax", "ẫ") }
    func test_simpletelex_tone_aaj() { assertSimpleTelex("aaj", "ậ") }
    
    func test_simpletelex_tone_ees() { assertSimpleTelex("ees", "ế") }
    func test_simpletelex_tone_eef() { assertSimpleTelex("eef", "ề") }
    func test_simpletelex_tone_eer() { assertSimpleTelex("eer", "ể") }
    func test_simpletelex_tone_eex() { assertSimpleTelex("eex", "ễ") }
    func test_simpletelex_tone_eej() { assertSimpleTelex("eej", "ệ") }
    
    func test_simpletelex_tone_oos() { assertSimpleTelex("oos", "ố") }
    func test_simpletelex_tone_oof() { assertSimpleTelex("oof", "ồ") }
    func test_simpletelex_tone_oor() { assertSimpleTelex("oor", "ổ") }
    func test_simpletelex_tone_oox() { assertSimpleTelex("oox", "ỗ") }
    func test_simpletelex_tone_ooj() { assertSimpleTelex("ooj", "ộ") }
    
    // MARK: - Words & Compound Syllables (20 tests)
    func test_simpletelex_word_viet() { assertSimpleTelex("vieetj", "việt") }
    func test_simpletelex_word_nam() { assertSimpleTelex("nam", "nam") }
    func test_simpletelex_word_tieng() { assertSimpleTelex("tieengs", "tiếng") }
    func test_simpletelex_word_toan() { assertSimpleTelex("toans", "toán") }
    func test_simpletelex_word_hoc() { assertSimpleTelex("hojc", "học") }
    func test_simpletelex_word_hoa() { assertSimpleTelex("hoaf", "hòa") }
    func test_simpletelex_word_khoe() { assertSimpleTelex("khoer", "khỏe") }
    func test_simpletelex_word_thuy() { assertSimpleTelex("thuys", "thúy") }
    func test_simpletelex_word_dat() { assertSimpleTelex("ddaats", "đất") }
    func test_simpletelex_word_duoc() { assertSimpleTelex("dduwowjc", "được") }
    func test_simpletelex_word_nguoi() { assertSimpleTelex("nguowfi", "người") }
    func test_simpletelex_word_truong() { assertSimpleTelex("truwowfng", "trường") }
    func test_simpletelex_word_nuoc() { assertSimpleTelex("nuowcs", "nước") }
    func test_simpletelex_word_buoc() { assertSimpleTelex("buwowsc", "bước") }
    func test_simpletelex_word_muon() { assertSimpleTelex("muwownj", "mượn") }
    func test_simpletelex_word_dong() { assertSimpleTelex("ddoofng", "đồng") }
    func test_simpletelex_word_som() { assertSimpleTelex("sowms", "sớm") }
    func test_simpletelex_word_toi() { assertSimpleTelex("toois", "tối") }
    func test_simpletelex_word_pho() { assertSimpleTelex("phoos", "phố") }
    func test_simpletelex_word_nha() { assertSimpleTelex("nhaf", "nhà") }
    
    // MARK: - Tone Removal with 'z' (10 tests)
    func test_simpletelex_clear_toan() { assertSimpleTelex("toansz", "toan") }
    func test_simpletelex_clear_tieng() { assertSimpleTelex("tieengsz", "tiêng") }
    func test_simpletelex_clear_ba() { assertSimpleTelex("basz", "ba") }
    func test_simpletelex_clear_me() { assertSimpleTelex("mejz", "me") }
    func test_simpletelex_clear_ngu() { assertSimpleTelex("ngurz", "ngu") }
    func test_simpletelex_clear_ca() { assertSimpleTelex("casz", "ca") }
    func test_simpletelex_clear_da() { assertSimpleTelex("ddasz", "đa") }
    func test_simpletelex_clear_ho() { assertSimpleTelex("hoorz", "hô") }
    func test_simpletelex_clear_le() { assertSimpleTelex("leexz", "lê") }
    func test_simpletelex_clear_literal_z() { assertSimpleTelex("toanz", "toanz") }
    
    // MARK: - Registration of all tests
    public override var allTests: [(name: String, test: TestMethod)] {
        return [
            ("test_simpletelex_w_standalone", test_simpletelex_w_standalone),
            ("test_simpletelex_ww_standalone", test_simpletelex_ww_standalone),
            ("test_simpletelex_www_url", test_simpletelex_www_url),
            ("test_simpletelex_web", test_simpletelex_web),
            ("test_simpletelex_win", test_simpletelex_win),
            ("test_simpletelex_wifi", test_simpletelex_wifi),
            ("test_simpletelex_word", test_simpletelex_word),
            ("test_simpletelex_work", test_simpletelex_work),
            ("test_simpletelex_wiki", test_simpletelex_wiki),
            ("test_simpletelex_warning", test_simpletelex_warning),
            ("test_simpletelex_water", test_simpletelex_water),
            ("test_simpletelex_welcome", test_simpletelex_welcome),
            ("test_simpletelex_window", test_simpletelex_window),
            ("test_simpletelex_wa_not_ua", test_simpletelex_wa_not_ua),
            ("test_simpletelex_we_not_ue", test_simpletelex_we_not_ue),
            
            ("test_simpletelex_diacritic_aa", test_simpletelex_diacritic_aa),
            ("test_simpletelex_diacritic_ee", test_simpletelex_diacritic_ee),
            ("test_simpletelex_diacritic_oo", test_simpletelex_diacritic_oo),
            ("test_simpletelex_diacritic_dd", test_simpletelex_diacritic_dd),
            ("test_simpletelex_diacritic_aw", test_simpletelex_diacritic_aw),
            ("test_simpletelex_diacritic_ow", test_simpletelex_diacritic_ow),
            ("test_simpletelex_diacritic_uw", test_simpletelex_diacritic_uw),
            ("test_simpletelex_diacritic_AA", test_simpletelex_diacritic_AA),
            ("test_simpletelex_diacritic_EE", test_simpletelex_diacritic_EE),
            ("test_simpletelex_diacritic_OO", test_simpletelex_diacritic_OO),
            ("test_simpletelex_diacritic_DD", test_simpletelex_diacritic_DD),
            ("test_simpletelex_diacritic_AW", test_simpletelex_diacritic_AW),
            ("test_simpletelex_diacritic_OW", test_simpletelex_diacritic_OW),
            ("test_simpletelex_diacritic_UW", test_simpletelex_diacritic_UW),
            
            ("test_simpletelex_tone_as", test_simpletelex_tone_as),
            ("test_simpletelex_tone_af", test_simpletelex_tone_af),
            ("test_simpletelex_tone_ar", test_simpletelex_tone_ar),
            ("test_simpletelex_tone_ax", test_simpletelex_tone_ax),
            ("test_simpletelex_tone_aj", test_simpletelex_tone_aj),
            ("test_simpletelex_tone_aws", test_simpletelex_tone_aws),
            ("test_simpletelex_tone_awf", test_simpletelex_tone_awf),
            ("test_simpletelex_tone_awr", test_simpletelex_tone_awr),
            ("test_simpletelex_tone_awx", test_simpletelex_tone_awx),
            ("test_simpletelex_tone_awj", test_simpletelex_tone_awj),
            ("test_simpletelex_tone_aas", test_simpletelex_tone_aas),
            ("test_simpletelex_tone_aaf", test_simpletelex_tone_aaf),
            ("test_simpletelex_tone_aar", test_simpletelex_tone_aar),
            ("test_simpletelex_tone_aax", test_simpletelex_tone_aax),
            ("test_simpletelex_tone_aaj", test_simpletelex_tone_aaj),
            ("test_simpletelex_tone_ees", test_simpletelex_tone_ees),
            ("test_simpletelex_tone_eef", test_simpletelex_tone_eef),
            ("test_simpletelex_tone_eer", test_simpletelex_tone_eer),
            ("test_simpletelex_tone_eex", test_simpletelex_tone_eex),
            ("test_simpletelex_tone_eej", test_simpletelex_tone_eej),
            ("test_simpletelex_tone_oos", test_simpletelex_tone_oos),
            ("test_simpletelex_tone_oof", test_simpletelex_tone_oof),
            ("test_simpletelex_tone_oor", test_simpletelex_tone_oor),
            ("test_simpletelex_tone_oox", test_simpletelex_tone_oox),
            ("test_simpletelex_tone_ooj", test_simpletelex_tone_ooj),
            
            ("test_simpletelex_word_viet", test_simpletelex_word_viet),
            ("test_simpletelex_word_nam", test_simpletelex_word_nam),
            ("test_simpletelex_word_tieng", test_simpletelex_word_tieng),
            ("test_simpletelex_word_toan", test_simpletelex_word_toan),
            ("test_simpletelex_word_hoc", test_simpletelex_word_hoc),
            ("test_simpletelex_word_hoa", test_simpletelex_word_hoa),
            ("test_simpletelex_word_khoe", test_simpletelex_word_khoe),
            ("test_simpletelex_word_thuy", test_simpletelex_word_thuy),
            ("test_simpletelex_word_dat", test_simpletelex_word_dat),
            ("test_simpletelex_word_duoc", test_simpletelex_word_duoc),
            ("test_simpletelex_word_nguoi", test_simpletelex_word_nguoi),
            ("test_simpletelex_word_truong", test_simpletelex_word_truong),
            ("test_simpletelex_word_nuoc", test_simpletelex_word_nuoc),
            ("test_simpletelex_word_buoc", test_simpletelex_word_buoc),
            ("test_simpletelex_word_muon", test_simpletelex_word_muon),
            ("test_simpletelex_word_dong", test_simpletelex_word_dong),
            ("test_simpletelex_word_som", test_simpletelex_word_som),
            ("test_simpletelex_word_toi", test_simpletelex_word_toi),
            ("test_simpletelex_word_pho", test_simpletelex_word_pho),
            ("test_simpletelex_word_nha", test_simpletelex_word_nha),
            
            ("test_simpletelex_clear_toan", test_simpletelex_clear_toan),
            ("test_simpletelex_clear_tieng", test_simpletelex_clear_tieng),
            ("test_simpletelex_clear_ba", test_simpletelex_clear_ba),
            ("test_simpletelex_clear_me", test_simpletelex_clear_me),
            ("test_simpletelex_clear_ngu", test_simpletelex_clear_ngu),
            ("test_simpletelex_clear_ca", test_simpletelex_clear_ca),
            ("test_simpletelex_clear_da", test_simpletelex_clear_da),
            ("test_simpletelex_clear_ho", test_simpletelex_clear_ho),
            ("test_simpletelex_clear_le", test_simpletelex_clear_le),
            ("test_simpletelex_clear_literal_z", test_simpletelex_clear_literal_z),
        ]
    }
}
