//
//  BasicTelexTests.swift
//  VietFlowEngineTests
//
//  Tier 1 & Tier 2: Comprehensive Telex Keystroke & Feature Coverage (>= 150 test cases)
//

import Foundation
import VietFlowEngine

public final class BasicTelexTests: VietFlowTestCase {
    private var engine: VietnameseEngineProtocol!
    
    public override func setUp() {
        super.setUp()
        engine = makeEngine(inputMethod: .telex, tonePlacement: .modern)
    }
    
    private func assertTelex(_ input: String, _ expected: String, file: StaticString = #file, line: UInt = #line) {
        engine.reset()
        let (_, output) = typeSequence(input, into: engine)
        XCTAssertEqual(output, expected, "Failed for input: '\(input)'", file: file, line: line)
    }
    
    // MARK: - Monophthongs & Diacritics (14 tests)
    func test_telex_diacritic_aa() { assertTelex("aa", "â") }
    func test_telex_diacritic_aw() { assertTelex("aw", "ă") }
    func test_telex_diacritic_ee() { assertTelex("ee", "ê") }
    func test_telex_diacritic_oo() { assertTelex("oo", "ô") }
    func test_telex_diacritic_ow() { assertTelex("ow", "ơ") }
    func test_telex_diacritic_uw() { assertTelex("uw", "ư") }
    func test_telex_diacritic_dd() { assertTelex("dd", "đ") }
    
    func test_telex_diacritic_AA() { assertTelex("AA", "Â") }
    func test_telex_diacritic_AW() { assertTelex("AW", "Ă") }
    func test_telex_diacritic_EE() { assertTelex("EE", "Ê") }
    func test_telex_diacritic_OO() { assertTelex("OO", "Ô") }
    func test_telex_diacritic_OW() { assertTelex("OW", "Ơ") }
    func test_telex_diacritic_UW() { assertTelex("UW", "Ư") }
    func test_telex_diacritic_DD() { assertTelex("DD", "Đ") }
    
    // MARK: - Vowel 'a' with 6 Tones (5 tests)
    func test_telex_tone_as() { assertTelex("as", "á") }
    func test_telex_tone_af() { assertTelex("af", "à") }
    func test_telex_tone_ar() { assertTelex("ar", "ả") }
    func test_telex_tone_ax() { assertTelex("ax", "ã") }
    func test_telex_tone_aj() { assertTelex("aj", "ạ") }
    
    // MARK: - Vowel 'ă' (aw) with 6 Tones (5 tests)
    func test_telex_tone_aws() { assertTelex("aws", "ắ") }
    func test_telex_tone_awf() { assertTelex("awf", "ằ") }
    func test_telex_tone_awr() { assertTelex("awr", "ẳ") }
    func test_telex_tone_awx() { assertTelex("awx", "ẵ") }
    func test_telex_tone_awj() { assertTelex("awj", "ặ") }
    
    // MARK: - Vowel 'â' (aa) with 6 Tones (5 tests)
    func test_telex_tone_aas() { assertTelex("aas", "ấ") }
    func test_telex_tone_aaf() { assertTelex("aaf", "ầ") }
    func test_telex_tone_aar() { assertTelex("aar", "ẩ") }
    func test_telex_tone_aax() { assertTelex("aax", "ẫ") }
    func test_telex_tone_aaj() { assertTelex("aaj", "ậ") }
    
    // MARK: - Vowel 'e' with 6 Tones (5 tests)
    func test_telex_tone_es() { assertTelex("es", "é") }
    func test_telex_tone_ef() { assertTelex("ef", "è") }
    func test_telex_tone_er() { assertTelex("er", "ẻ") }
    func test_telex_tone_ex() { assertTelex("ex", "ẽ") }
    func test_telex_tone_ej() { assertTelex("ej", "ẹ") }
    
    // MARK: - Vowel 'ê' (ee) with 6 Tones (5 tests)
    func test_telex_tone_ees() { assertTelex("ees", "ế") }
    func test_telex_tone_eef() { assertTelex("eef", "ề") }
    func test_telex_tone_eer() { assertTelex("eer", "ể") }
    func test_telex_tone_eex() { assertTelex("eex", "ễ") }
    func test_telex_tone_eej() { assertTelex("eej", "ệ") }
    
    // MARK: - Vowel 'i' with 6 Tones (5 tests)
    func test_telex_tone_is() { assertTelex("is", "í") }
    func test_telex_tone_if() { assertTelex("if", "ì") }
    func test_telex_tone_ir() { assertTelex("ir", "ỉ") }
    func test_telex_tone_ix() { assertTelex("ix", "ĩ") }
    func test_telex_tone_ij() { assertTelex("ij", "ị") }
    
    // MARK: - Vowel 'o' with 6 Tones (5 tests)
    func test_telex_tone_os() { assertTelex("os", "ó") }
    func test_telex_tone_of() { assertTelex("of", "ò") }
    func test_telex_tone_or() { assertTelex("or", "ỏ") }
    func test_telex_tone_ox() { assertTelex("ox", "õ") }
    func test_telex_tone_oj() { assertTelex("oj", "ọ") }
    
    // MARK: - Vowel 'ô' (oo) with 6 Tones (5 tests)
    func test_telex_tone_oos() { assertTelex("oos", "ố") }
    func test_telex_tone_oof() { assertTelex("oof", "ồ") }
    func test_telex_tone_oor() { assertTelex("oor", "ổ") }
    func test_telex_tone_oox() { assertTelex("oox", "ỗ") }
    func test_telex_tone_ooj() { assertTelex("ooj", "ộ") }
    
    // MARK: - Vowel 'ơ' (ow) with 6 Tones (5 tests)
    func test_telex_tone_ows() { assertTelex("ows", "ớ") }
    func test_telex_tone_owf() { assertTelex("owf", "ờ") }
    func test_telex_tone_owr() { assertTelex("owr", "ở") }
    func test_telex_tone_owx() { assertTelex("owx", "ỡ") }
    func test_telex_tone_owj() { assertTelex("owj", "ợ") }
    
    // MARK: - Vowel 'u' with 6 Tones (5 tests)
    func test_telex_tone_us() { assertTelex("us", "ú") }
    func test_telex_tone_uf() { assertTelex("uf", "ù") }
    func test_telex_tone_ur() { assertTelex("ur", "ủ") }
    func test_telex_tone_ux() { assertTelex("ux", "ũ") }
    func test_telex_tone_uj() { assertTelex("uj", "ụ") }
    
    // MARK: - Vowel 'ư' (uw) with 6 Tones (5 tests)
    func test_telex_tone_uws() { assertTelex("uws", "ứ") }
    func test_telex_tone_uwf() { assertTelex("uwf", "ừ") }
    func test_telex_tone_uwr() { assertTelex("uwr", "ử") }
    func test_telex_tone_uwx() { assertTelex("uwx", "ữ") }
    func test_telex_tone_uwj() { assertTelex("uwj", "ự") }
    
    // MARK: - Vowel 'y' with 6 Tones (5 tests)
    func test_telex_tone_ys() { assertTelex("ys", "ý") }
    func test_telex_tone_yf() { assertTelex("yf", "ỳ") }
    func test_telex_tone_yr() { assertTelex("yr", "ỷ") }
    func test_telex_tone_yx() { assertTelex("yx", "ỹ") }
    func test_telex_tone_yj() { assertTelex("yj", "ỵ") }
    
    // MARK: - Standalone 'w' & Double Horn Shortcuts (8 tests)
    func test_telex_shortcut_w() { assertTelex("w", "ư") }
    func test_telex_shortcut_wa() { assertTelex("wa", "ưa") }
    func test_telex_shortcut_was() { assertTelex("was", "ứa") }
    func test_telex_shortcut_waf() { assertTelex("waf", "ừa") }
    func test_telex_shortcut_uow() { assertTelex("uow", "ươ") }
    func test_telex_shortcut_uows() { assertTelex("uows", "ướ") }
    func test_telex_shortcut_uowf() { assertTelex("uowf", "ườ") }
    func test_telex_shortcut_uwow() { assertTelex("uwow", "ươ") }
    
    // MARK: - Common Consonant Onsets & Basic Words (50 tests)
    func test_telex_word_ba() { assertTelex("ba", "ba") }
    func test_telex_word_baf() { assertTelex("baf", "bà") }
    func test_telex_word_bas() { assertTelex("bas", "bá") }
    func test_telex_word_bar() { assertTelex("bar", "bả") }
    func test_telex_word_bax() { assertTelex("bax", "bã") }
    func test_telex_word_baj() { assertTelex("baj", "bạ") }
    
    func test_telex_word_ca() { assertTelex("ca", "ca") }
    func test_telex_word_caf() { assertTelex("caf", "cà") }
    func test_telex_word_cas() { assertTelex("cas", "cá") }
    func test_telex_word_car() { assertTelex("car", "cả") }
    func test_telex_word_cax() { assertTelex("cax", "cã") }
    func test_telex_word_caj() { assertTelex("caj", "cạ") }
    
    func test_telex_word_cha() { assertTelex("cha", "cha") }
    func test_telex_word_chas() { assertTelex("chas", "chá") }
    func test_telex_word_chonj() { assertTelex("chonj", "chọn") }
    func test_telex_word_chawm() { assertTelex("chawm", "chăm") }
    func test_telex_word_chur() { assertTelex("chur", "chủ") }
    
    func test_telex_word_da() { assertTelex("da", "da") }
    func test_telex_word_daf() { assertTelex("daf", "dà") }
    func test_telex_word_das() { assertTelex("das", "dá") }
    
    func test_telex_word_ddas() { assertTelex("ddas", "đá") }
    func test_telex_word_ddats() { assertTelex("ddaats", "đất") }
    func test_telex_word_ddos() { assertTelex("ddos", "đó") }
    func test_telex_word_ddaay() { assertTelex("ddaay", "đây") }
    func test_telex_word_ddoofng() { assertTelex("ddoofng", "đồng") }
    func test_telex_word_dduwowjc() { assertTelex("dduwowjc", "được") }
    
    func test_telex_word_gaf() { assertTelex("gaf", "gà") }
    func test_telex_word_gias() { assertTelex("gias", "giá") }
    func test_telex_word_gioir() { assertTelex("gioir", "giỏi") }
    func test_telex_word_gawjp() { assertTelex("gawjp", "gặp") }
    
    func test_telex_word_hoa() { assertTelex("hoa", "hoa") }
    func test_telex_word_hoaf() { assertTelex("hoaf", "hòa") }
    func test_telex_word_hojc() { assertTelex("hojc", "học") }
    func test_telex_word_huowng() { assertTelex("huowng", "hương") }
    
    func test_telex_word_khi() { assertTelex("khi", "khi") }
    func test_telex_word_khuyeens() { assertTelex("khuyeens", "khuyến") }
    
    func test_telex_word_lafm() { assertTelex("lafm", "làm") }
    func test_telex_word_luowjn() { assertTelex("luowjn", "lượn") }
    
    func test_telex_word_mej() { assertTelex("mej", "mẹ") }
    func test_telex_word_meof() { assertTelex("meof", "mèo") }
    func test_telex_word_muwownj() { assertTelex("muwownj", "mượn") }
    
    func test_telex_word_nam() { assertTelex("nam", "nam") }
    func test_telex_word_nhaf() { assertTelex("nhaf", "nhà") }
    func test_telex_word_nuowcs() { assertTelex("nuowcs", "nước") }
    func test_telex_word_ngheef() { assertTelex("ngheef", "nghề") }
    func test_telex_word_nghiengs() { assertTelex("nghiengs", "nghiếng") }
    func test_telex_word_nguowfi() { assertTelex("nguowfi", "người") }
    
    func test_telex_word_phos() { assertTelex("phoos", "phố") }
    func test_telex_word_phuwowngj() { assertTelex("phuwowngj", "phượng") }
    
    func test_telex_word_quyeenf() { assertTelex("quyeenf", "quyền") }
    func test_telex_word_quas() { assertTelex("quas", "quá") }
    
    func test_telex_word_sowms() { assertTelex("sowms", "sớm") }
    func test_telex_word_thawfng() { assertTelex("thawfng", "thằng") }
    func test_telex_word_tieengs() { assertTelex("tieengs", "tiếng") }
    func test_telex_word_toans() { assertTelex("toans", "toán") }
    func test_telex_word_toois() { assertTelex("toois", "tối") }
    func test_telex_word_troong() { assertTelex("troong", "trông") }
    func test_telex_word_truwowfng() { assertTelex("truwowfng", "trường") }
    func test_telex_word_vieetj() { assertTelex("vieetj", "việt") }
    
    // MARK: - Upper Case & Mixed Case Preservation (15 tests)
    func test_telex_case_VIEETJ() { assertTelex("VIEETJ", "VIỆT") }
    func test_telex_case_Vietj() { assertTelex("Vietj", "Việt") }
    func test_telex_case_Vieetj() { assertTelex("Vieetj", "Việt") }
    func test_telex_case_vIETJ() { assertTelex("vIETJ", "vIỆT") }
    func test_telex_case_TOANS() { assertTelex("TOANS", "TOÁN") }
    func test_telex_case_Toans() { assertTelex("Toans", "Toán") }
    func test_telex_case_HAIPHOFNG() { assertTelex("HAIRPHOFNG", "HẢIPHÒNG") }
    func test_telex_case_HaiPhorng() { assertTelex("HairPhofng", "HảiPhòng") }
    func test_telex_case_DDATJ() { assertTelex("DDAWJT", "ĐẶT") }
    func test_telex_case_Ddatj() { assertTelex("Ddawjt", "Đặt") }
    func test_telex_case_NAM() { assertTelex("NAM", "NAM") }
    func test_telex_case_NGUOWFI() { assertTelex("NGUOWFI", "NGƯỜI") }
    func test_telex_case_Nguowfi() { assertTelex("Nguowfi", "Người") }
    func test_telex_case_TIEENGS() { assertTelex("TIEENGS", "TIẾNG") }
    func test_telex_case_Tieengs() { assertTelex("Tieengs", "Tiếng") }
    
    // MARK: - Stop Codas with Valid Sắc/Nặng (10 tests)
    func test_telex_stop_coda_bacs() { assertTelex("bacs", "bác") }
    func test_telex_stop_coda_bacj() { assertTelex("bacj", "bạc") }
    func test_telex_stop_coda_bats() { assertTelex("bats", "bát") }
    func test_telex_stop_coda_batj() { assertTelex("batj", "bạt") }
    func test_telex_stop_coda_bieets() { assertTelex("bieets", "biết") }
    func test_telex_stop_coda_bieetj() { assertTelex("bieetj", "biệt") }
    func test_telex_stop_coda_thichs() { assertTelex("thichs", "thích") }
    func test_telex_stop_coda_thichj() { assertTelex("thichj", "thịch") }
    func test_telex_stop_coda_hoops() { assertTelex("hoops", "hốp") }
    func test_telex_stop_coda_hoopj() { assertTelex("hoopj", "hộp") }
    
    // MARK: - Empty & Single Character Boundaries (5 tests)
    func test_telex_boundary_empty() { assertTelex("", "") }
    func test_telex_boundary_single_a() { assertTelex("a", "a") }
    func test_telex_boundary_single_b() { assertTelex("b", "b") }
    func test_telex_boundary_single_w() { assertTelex("w", "ư") }
    func test_telex_boundary_single_d() { assertTelex("d", "d") }
    
    // MARK: - Registration of all tests
    public override var allTests: [(name: String, test: TestMethod)] {
        return [
            ("test_telex_diacritic_aa", test_telex_diacritic_aa),
            ("test_telex_diacritic_aw", test_telex_diacritic_aw),
            ("test_telex_diacritic_ee", test_telex_diacritic_ee),
            ("test_telex_diacritic_oo", test_telex_diacritic_oo),
            ("test_telex_diacritic_ow", test_telex_diacritic_ow),
            ("test_telex_diacritic_uw", test_telex_diacritic_uw),
            ("test_telex_diacritic_dd", test_telex_diacritic_dd),
            ("test_telex_diacritic_AA", test_telex_diacritic_AA),
            ("test_telex_diacritic_AW", test_telex_diacritic_AW),
            ("test_telex_diacritic_EE", test_telex_diacritic_EE),
            ("test_telex_diacritic_OO", test_telex_diacritic_OO),
            ("test_telex_diacritic_OW", test_telex_diacritic_OW),
            ("test_telex_diacritic_UW", test_telex_diacritic_UW),
            ("test_telex_diacritic_DD", test_telex_diacritic_DD),
            
            ("test_telex_tone_as", test_telex_tone_as),
            ("test_telex_tone_af", test_telex_tone_af),
            ("test_telex_tone_ar", test_telex_tone_ar),
            ("test_telex_tone_ax", test_telex_tone_ax),
            ("test_telex_tone_aj", test_telex_tone_aj),
            
            ("test_telex_tone_aws", test_telex_tone_aws),
            ("test_telex_tone_awf", test_telex_tone_awf),
            ("test_telex_tone_awr", test_telex_tone_awr),
            ("test_telex_tone_awx", test_telex_tone_awx),
            ("test_telex_tone_awj", test_telex_tone_awj),
            
            ("test_telex_tone_aas", test_telex_tone_aas),
            ("test_telex_tone_aaf", test_telex_tone_aaf),
            ("test_telex_tone_aar", test_telex_tone_aar),
            ("test_telex_tone_aax", test_telex_tone_aax),
            ("test_telex_tone_aaj", test_telex_tone_aaj),
            
            ("test_telex_tone_es", test_telex_tone_es),
            ("test_telex_tone_ef", test_telex_tone_ef),
            ("test_telex_tone_er", test_telex_tone_er),
            ("test_telex_tone_ex", test_telex_tone_ex),
            ("test_telex_tone_ej", test_telex_tone_ej),
            
            ("test_telex_tone_ees", test_telex_tone_ees),
            ("test_telex_tone_eef", test_telex_tone_eef),
            ("test_telex_tone_eer", test_telex_tone_eer),
            ("test_telex_tone_eex", test_telex_tone_eex),
            ("test_telex_tone_eej", test_telex_tone_eej),
            
            ("test_telex_tone_is", test_telex_tone_is),
            ("test_telex_tone_if", test_telex_tone_if),
            ("test_telex_tone_ir", test_telex_tone_ir),
            ("test_telex_tone_ix", test_telex_tone_ix),
            ("test_telex_tone_ij", test_telex_tone_ij),
            
            ("test_telex_tone_os", test_telex_tone_os),
            ("test_telex_tone_of", test_telex_tone_of),
            ("test_telex_tone_or", test_telex_tone_or),
            ("test_telex_tone_ox", test_telex_tone_ox),
            ("test_telex_tone_oj", test_telex_tone_oj),
            
            ("test_telex_tone_oos", test_telex_tone_oos),
            ("test_telex_tone_oof", test_telex_tone_oof),
            ("test_telex_tone_oor", test_telex_tone_oor),
            ("test_telex_tone_oox", test_telex_tone_oox),
            ("test_telex_tone_ooj", test_telex_tone_ooj),
            
            ("test_telex_tone_ows", test_telex_tone_ows),
            ("test_telex_tone_owf", test_telex_tone_owf),
            ("test_telex_tone_owr", test_telex_tone_owr),
            ("test_telex_tone_owx", test_telex_tone_owx),
            ("test_telex_tone_owj", test_telex_tone_owj),
            
            ("test_telex_tone_us", test_telex_tone_us),
            ("test_telex_tone_uf", test_telex_tone_uf),
            ("test_telex_tone_ur", test_telex_tone_ur),
            ("test_telex_tone_ux", test_telex_tone_ux),
            ("test_telex_tone_uj", test_telex_tone_uj),
            
            ("test_telex_tone_uws", test_telex_tone_uws),
            ("test_telex_tone_uwf", test_telex_tone_uwf),
            ("test_telex_tone_uwr", test_telex_tone_uwr),
            ("test_telex_tone_uwx", test_telex_tone_uwx),
            ("test_telex_tone_uwj", test_telex_tone_uwj),
            
            ("test_telex_tone_ys", test_telex_tone_ys),
            ("test_telex_tone_yf", test_telex_tone_yf),
            ("test_telex_tone_yr", test_telex_tone_yr),
            ("test_telex_tone_yx", test_telex_tone_yx),
            ("test_telex_tone_yj", test_telex_tone_yj),
            
            ("test_telex_shortcut_w", test_telex_shortcut_w),
            ("test_telex_shortcut_wa", test_telex_shortcut_wa),
            ("test_telex_shortcut_was", test_telex_shortcut_was),
            ("test_telex_shortcut_waf", test_telex_shortcut_waf),
            ("test_telex_shortcut_uow", test_telex_shortcut_uow),
            ("test_telex_shortcut_uows", test_telex_shortcut_uows),
            ("test_telex_shortcut_uowf", test_telex_shortcut_uowf),
            ("test_telex_shortcut_uwow", test_telex_shortcut_uwow),
            
            ("test_telex_word_ba", test_telex_word_ba),
            ("test_telex_word_baf", test_telex_word_baf),
            ("test_telex_word_bas", test_telex_word_bas),
            ("test_telex_word_bar", test_telex_word_bar),
            ("test_telex_word_bax", test_telex_word_bax),
            ("test_telex_word_baj", test_telex_word_baj),
            ("test_telex_word_ca", test_telex_word_ca),
            ("test_telex_word_caf", test_telex_word_caf),
            ("test_telex_word_cas", test_telex_word_cas),
            ("test_telex_word_car", test_telex_word_car),
            ("test_telex_word_cax", test_telex_word_cax),
            ("test_telex_word_caj", test_telex_word_caj),
            ("test_telex_word_cha", test_telex_word_cha),
            ("test_telex_word_chas", test_telex_word_chas),
            ("test_telex_word_chonj", test_telex_word_chonj),
            ("test_telex_word_chawm", test_telex_word_chawm),
            ("test_telex_word_chur", test_telex_word_chur),
            ("test_telex_word_da", test_telex_word_da),
            ("test_telex_word_daf", test_telex_word_daf),
            ("test_telex_word_das", test_telex_word_das),
            ("test_telex_word_ddas", test_telex_word_ddas),
            ("test_telex_word_ddats", test_telex_word_ddats),
            ("test_telex_word_ddos", test_telex_word_ddos),
            ("test_telex_word_ddaay", test_telex_word_ddaay),
            ("test_telex_word_ddoofng", test_telex_word_ddoofng),
            ("test_telex_word_dduwowjc", test_telex_word_dduwowjc),
            ("test_telex_word_gaf", test_telex_word_gaf),
            ("test_telex_word_gias", test_telex_word_gias),
            ("test_telex_word_gioir", test_telex_word_gioir),
            ("test_telex_word_gawjp", test_telex_word_gawjp),
            ("test_telex_word_hoa", test_telex_word_hoa),
            ("test_telex_word_hoaf", test_telex_word_hoaf),
            ("test_telex_word_hojc", test_telex_word_hojc),
            ("test_telex_word_huowng", test_telex_word_huowng),
            ("test_telex_word_khi", test_telex_word_khi),
            ("test_telex_word_khuyeens", test_telex_word_khuyeens),
            ("test_telex_word_lafm", test_telex_word_lafm),
            ("test_telex_word_luowjn", test_telex_word_luowjn),
            ("test_telex_word_mej", test_telex_word_mej),
            ("test_telex_word_meof", test_telex_word_meof),
            ("test_telex_word_muwownj", test_telex_word_muwownj),
            ("test_telex_word_nam", test_telex_word_nam),
            ("test_telex_word_nhaf", test_telex_word_nhaf),
            ("test_telex_word_nuowcs", test_telex_word_nuowcs),
            ("test_telex_word_ngheef", test_telex_word_ngheef),
            ("test_telex_word_nghiengs", test_telex_word_nghiengs),
            ("test_telex_word_nguowfi", test_telex_word_nguowfi),
            ("test_telex_word_phos", test_telex_word_phos),
            ("test_telex_word_phuwowngj", test_telex_word_phuwowngj),
            ("test_telex_word_quyeenf", test_telex_word_quyeenf),
            ("test_telex_word_quas", test_telex_word_quas),
            ("test_telex_word_sowms", test_telex_word_sowms),
            ("test_telex_word_thawfng", test_telex_word_thawfng),
            ("test_telex_word_tieengs", test_telex_word_tieengs),
            ("test_telex_word_toans", test_telex_word_toans),
            ("test_telex_word_toois", test_telex_word_toois),
            ("test_telex_word_troong", test_telex_word_troong),
            ("test_telex_word_truwowfng", test_telex_word_truwowfng),
            ("test_telex_word_vieetj", test_telex_word_vieetj),
            
            ("test_telex_case_VIEETJ", test_telex_case_VIEETJ),
            ("test_telex_case_Vietj", test_telex_case_Vietj),
            ("test_telex_case_Vieetj", test_telex_case_Vieetj),
            ("test_telex_case_vIETJ", test_telex_case_vIETJ),
            ("test_telex_case_TOANS", test_telex_case_TOANS),
            ("test_telex_case_Toans", test_telex_case_Toans),
            ("test_telex_case_HAIPHOFNG", test_telex_case_HAIPHOFNG),
            ("test_telex_case_HaiPhorng", test_telex_case_HaiPhorng),
            ("test_telex_case_DDATJ", test_telex_case_DDATJ),
            ("test_telex_case_Ddatj", test_telex_case_Ddatj),
            ("test_telex_case_NAM", test_telex_case_NAM),
            ("test_telex_case_NGUOWFI", test_telex_case_NGUOWFI),
            ("test_telex_case_Nguowfi", test_telex_case_Nguowfi),
            ("test_telex_case_TIEENGS", test_telex_case_TIEENGS),
            ("test_telex_case_Tieengs", test_telex_case_Tieengs),
            
            ("test_telex_stop_coda_bacs", test_telex_stop_coda_bacs),
            ("test_telex_stop_coda_bacj", test_telex_stop_coda_bacj),
            ("test_telex_stop_coda_bats", test_telex_stop_coda_bats),
            ("test_telex_stop_coda_batj", test_telex_stop_coda_batj),
            ("test_telex_stop_coda_bieets", test_telex_stop_coda_bieets),
            ("test_telex_stop_coda_bieetj", test_telex_stop_coda_bieetj),
            ("test_telex_stop_coda_thichs", test_telex_stop_coda_thichs),
            ("test_telex_stop_coda_thichj", test_telex_stop_coda_thichj),
            ("test_telex_stop_coda_hoops", test_telex_stop_coda_hoops),
            ("test_telex_stop_coda_hoopj", test_telex_stop_coda_hoopj),
            
            ("test_telex_boundary_empty", test_telex_boundary_empty),
            ("test_telex_boundary_single_a", test_telex_boundary_single_a),
            ("test_telex_boundary_single_b", test_telex_boundary_single_b),
            ("test_telex_boundary_single_w", test_telex_boundary_single_w),
            ("test_telex_boundary_single_d", test_telex_boundary_single_d),
        ]
    }
}
