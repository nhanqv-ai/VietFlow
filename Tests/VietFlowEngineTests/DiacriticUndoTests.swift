//
//  DiacriticUndoTests.swift
//  VietFlowEngineTests
//
//  Tier 3: Diacritic & Tone Undo, Escape, and Tone Override Suite (>= 80 test cases)
//  Covers double-press tone toggle, triple-key mark undo, tone override, and explicit 'z'/'0' clearing.
//

import Foundation
import VietFlowEngine

public final class DiacriticUndoTests: VietFlowTestCase {
    private var telexEngine: VietnameseEngineProtocol!
    private var vniEngine: VietnameseEngineProtocol!
    
    public override func setUp() {
        super.setUp()
        telexEngine = makeEngine(inputMethod: .telex, tonePlacement: .modern, autoCorrectEnglish: false)
        vniEngine = makeEngine(inputMethod: .vni, tonePlacement: .modern)
    }
    
    private func assertTelexUndo(_ input: String, _ expected: String, file: StaticString = #file, line: UInt = #line) {
        telexEngine.reset()
        let (_, output) = typeSequence(input, into: telexEngine)
        XCTAssertEqual(output, expected, "Failed Telex Undo for: '\(input)'", file: file, line: line)
    }
    
    private func assertVNIUndo(_ input: String, _ expected: String, file: StaticString = #file, line: UInt = #line) {
        vniEngine.reset()
        let (_, output) = typeSequence(input, into: vniEngine)
        XCTAssertEqual(output, expected, "Failed VNI Undo for: '\(input)'", file: file, line: line)
    }
    
    // MARK: - Tone Undo on Double-Press (20 tests)
    func test_undo_tone_bass() { assertTelexUndo("bass", "bas") }
    func test_undo_tone_baff() { assertTelexUndo("baff", "baf") }
    func test_undo_tone_barr() { assertTelexUndo("barr", "bar") }
    func test_undo_tone_baxx() { assertTelexUndo("baxx", "bax") }
    func test_undo_tone_bajj() { assertTelexUndo("bajj", "baj") }
    
    func test_undo_tone_toanss() { assertTelexUndo("toanss", "toans") }
    func test_undo_tone_toanff() { assertTelexUndo("toanff", "toanf") }
    func test_undo_tone_toanrr() { assertTelexUndo("toanrr", "toanr") }
    func test_undo_tone_toanxx() { assertTelexUndo("toanxx", "toanx") }
    func test_undo_tone_toanjj() { assertTelexUndo("toanjj", "toanj") }
    
    func test_undo_tone_mejj() { assertTelexUndo("mejj", "mej") }
    func test_undo_tone_ngurr() { assertTelexUndo("ngurr", "ngur") }
    func test_undo_tone_choxx() { assertTelexUndo("choxx", "chox") }
    func test_undo_tone_cass() { assertTelexUndo("cass", "cas") }
    func test_undo_tone_diff() { assertTelexUndo("diff", "dif") }
    
    func test_undo_tone_vieetjj() { assertTelexUndo("vieetjj", "vieetj") }
    func test_undo_tone_tieengss() { assertTelexUndo("tieengss", "tieengs") }
    func test_undo_tone_dduwowjcjj() { assertTelexUndo("dduwowjcjj", "dduwowjcj") }
    func test_undo_tone_nguowfiff() { assertTelexUndo("nguowfiff", "nguowfif") }
    func test_undo_tone_truwowfngff() { assertTelexUndo("truwowfngff", "truwowfngf") }
    
    // MARK: - Diacritic Undo on Repeated Keypress (20 tests)
    func test_undo_mark_aaa() { assertTelexUndo("aaa", "aa") }
    func test_undo_mark_eee() { assertTelexUndo("eee", "ee") }
    func test_undo_mark_ooo() { assertTelexUndo("ooo", "oo") }
    func test_undo_mark_ddd() { assertTelexUndo("ddd", "dd") }
    func test_undo_mark_aww() { assertTelexUndo("aww", "aw") }
    func test_undo_mark_oww() { assertTelexUndo("oww", "ow") }
    func test_undo_mark_uww() { assertTelexUndo("uww", "uw") }
    func test_undo_mark_ww() { assertTelexUndo("ww", "w") }
    
    func test_undo_mark_AAA() { assertTelexUndo("AAA", "AA") }
    func test_undo_mark_EEE() { assertTelexUndo("EEE", "EE") }
    func test_undo_mark_OOO() { assertTelexUndo("OOO", "OO") }
    func test_undo_mark_DDD() { assertTelexUndo("DDD", "DD") }
    func test_undo_mark_AWW() { assertTelexUndo("AWW", "AW") }
    func test_undo_mark_OWW() { assertTelexUndo("OWW", "OW") }
    func test_undo_mark_UWW() { assertTelexUndo("UWW", "UW") }
    
    func test_undo_mark_baaa() { assertTelexUndo("baaa", "baa") }
    func test_undo_mark_beee() { assertTelexUndo("beee", "bee") }
    func test_undo_mark_booo() { assertTelexUndo("booo", "boo") }
    func test_undo_mark_ddda() { assertTelexUndo("ddda", "dda") }
    func test_undo_mark_caww() { assertTelexUndo("caww", "caw") }
    
    // MARK: - Tone Override ("Last Tone Wins": 20 tests)
    func test_override_toan_s_to_f() { assertTelexUndo("toansf", "toàn") }
    func test_override_toan_f_to_r() { assertTelexUndo("toanfr", "toản") }
    func test_override_toan_r_to_x() { assertTelexUndo("toanrx", "toãn") }
    func test_override_toan_x_to_j() { assertTelexUndo("toanxj", "toạn") }
    func test_override_toan_j_to_s() { assertTelexUndo("toanjs", "toán") }
    
    func test_override_ba_s_to_f() { assertTelexUndo("basf", "bà") }
    func test_override_ba_f_to_s() { assertTelexUndo("bafs", "bá") }
    func test_override_ca_r_to_x() { assertTelexUndo("carx", "cã") }
    func test_override_me_j_to_s() { assertTelexUndo("mejs", "mé") }
    func test_override_ngu_r_to_f() { assertTelexUndo("nugrf", "nugf") }
    
    func test_override_viet_s_to_j() { assertTelexUndo("vieetsj", "việt") }
    func test_override_viet_j_to_s() { assertTelexUndo("vieetjs", "viết") }
    func test_override_tieng_f_to_s() { assertTelexUndo("tieengfs", "tiếng") }
    func test_override_duoc_s_to_j() { assertTelexUndo("dduwowcsj", "được") }
    func test_override_nguoi_s_to_f() { assertTelexUndo("nguowisf", "người") }
    
    func test_override_vni_toan_1_to_2() { assertVNIUndo("toan12", "toàn") }
    func test_override_vni_toan_2_to_3() { assertVNIUndo("toan23", "toản") }
    func test_override_vni_toan_3_to_4() { assertVNIUndo("toan34", "toãn") }
    func test_override_vni_toan_4_to_5() { assertVNIUndo("toan45", "toạn") }
    func test_override_vni_toan_5_to_1() { assertVNIUndo("toan51", "toán") }
    
    // MARK: - Explicit Tone Clearing with 'z' (Telex) and '0' (VNI: 20 tests)
    func test_clear_telex_toans_z() { assertTelexUndo("toansz", "toan") }
    func test_clear_telex_toanf_z() { assertTelexUndo("toanfz", "toan") }
    func test_clear_telex_toanr_z() { assertTelexUndo("toanrz", "toan") }
    func test_clear_telex_toanx_z() { assertTelexUndo("toanxz", "toan") }
    func test_clear_telex_toanj_z() { assertTelexUndo("toanjz", "toan") }
    
    func test_clear_telex_vieetj_z() { assertTelexUndo("vieetjz", "viêt") }
    func test_clear_telex_tieengs_z() { assertTelexUndo("tieengsz", "tiêng") }
    func test_clear_telex_nguowfi_z() { assertTelexUndo("nguowfiz", "ngươi") }
    func test_clear_telex_quyeenf_z() { assertTelexUndo("quyeenfz", "quyên") }
    func test_clear_telex_dduwowjc_z() { assertTelexUndo("dduwowjcz", "đươc") }
    
    func test_clear_telex_literal_z_toan() { assertTelexUndo("toanz", "toanz") }
    func test_clear_telex_literal_z_viet() { assertTelexUndo("vieetz", "viêtz") }
    func test_clear_telex_literal_z_nam() { assertTelexUndo("namz", "namz") }
    func test_clear_telex_literal_z_hoc() { assertTelexUndo("hoocz", "hôcz") }
    
    func test_clear_vni_toan1_0() { assertVNIUndo("toan10", "toan") }
    func test_clear_vni_toan2_0() { assertVNIUndo("toan20", "toan") }
    func test_clear_vni_toan3_0() { assertVNIUndo("toan30", "toan") }
    func test_clear_vni_toan4_0() { assertVNIUndo("toan40", "toan") }
    func test_clear_vni_toan5_0() { assertVNIUndo("toan50", "toan") }
    func test_clear_vni_literal_0_toan() { assertVNIUndo("toan0", "toan0") }
    
    // MARK: - Registration of all tests
    public override var allTests: [(name: String, test: TestMethod)] {
        return [
            ("test_undo_tone_bass", test_undo_tone_bass),
            ("test_undo_tone_baff", test_undo_tone_baff),
            ("test_undo_tone_barr", test_undo_tone_barr),
            ("test_undo_tone_baxx", test_undo_tone_baxx),
            ("test_undo_tone_bajj", test_undo_tone_bajj),
            ("test_undo_tone_toanss", test_undo_tone_toanss),
            ("test_undo_tone_toanff", test_undo_tone_toanff),
            ("test_undo_tone_toanrr", test_undo_tone_toanrr),
            ("test_undo_tone_toanxx", test_undo_tone_toanxx),
            ("test_undo_tone_toanjj", test_undo_tone_toanjj),
            ("test_undo_tone_mejj", test_undo_tone_mejj),
            ("test_undo_tone_ngurr", test_undo_tone_ngurr),
            ("test_undo_tone_choxx", test_undo_tone_choxx),
            ("test_undo_tone_cass", test_undo_tone_cass),
            ("test_undo_tone_diff", test_undo_tone_diff),
            ("test_undo_tone_vieetjj", test_undo_tone_vieetjj),
            ("test_undo_tone_tieengss", test_undo_tone_tieengss),
            ("test_undo_tone_dduwowjcjj", test_undo_tone_dduwowjcjj),
            ("test_undo_tone_nguowfiff", test_undo_tone_nguowfiff),
            ("test_undo_tone_truwowfngff", test_undo_tone_truwowfngff),
            
            ("test_undo_mark_aaa", test_undo_mark_aaa),
            ("test_undo_mark_eee", test_undo_mark_eee),
            ("test_undo_mark_ooo", test_undo_mark_ooo),
            ("test_undo_mark_ddd", test_undo_mark_ddd),
            ("test_undo_mark_aww", test_undo_mark_aww),
            ("test_undo_mark_oww", test_undo_mark_oww),
            ("test_undo_mark_uww", test_undo_mark_uww),
            ("test_undo_mark_ww", test_undo_mark_ww),
            ("test_undo_mark_AAA", test_undo_mark_AAA),
            ("test_undo_mark_EEE", test_undo_mark_EEE),
            ("test_undo_mark_OOO", test_undo_mark_OOO),
            ("test_undo_mark_DDD", test_undo_mark_DDD),
            ("test_undo_mark_AWW", test_undo_mark_AWW),
            ("test_undo_mark_OWW", test_undo_mark_OWW),
            ("test_undo_mark_UWW", test_undo_mark_UWW),
            ("test_undo_mark_baaa", test_undo_mark_baaa),
            ("test_undo_mark_beee", test_undo_mark_beee),
            ("test_undo_mark_booo", test_undo_mark_booo),
            ("test_undo_mark_ddda", test_undo_mark_ddda),
            ("test_undo_mark_caww", test_undo_mark_caww),
            
            ("test_override_toan_s_to_f", test_override_toan_s_to_f),
            ("test_override_toan_f_to_r", test_override_toan_f_to_r),
            ("test_override_toan_r_to_x", test_override_toan_r_to_x),
            ("test_override_toan_x_to_j", test_override_toan_x_to_j),
            ("test_override_toan_j_to_s", test_override_toan_j_to_s),
            ("test_override_ba_s_to_f", test_override_ba_s_to_f),
            ("test_override_ba_f_to_s", test_override_ba_f_to_s),
            ("test_override_ca_r_to_x", test_override_ca_r_to_x),
            ("test_override_me_j_to_s", test_override_me_j_to_s),
            ("test_override_ngu_r_to_f", test_override_ngu_r_to_f),
            ("test_override_viet_s_to_j", test_override_viet_s_to_j),
            ("test_override_viet_j_to_s", test_override_viet_j_to_s),
            ("test_override_tieng_f_to_s", test_override_tieng_f_to_s),
            ("test_override_duoc_s_to_j", test_override_duoc_s_to_j),
            ("test_override_nguoi_s_to_f", test_override_nguoi_s_to_f),
            ("test_override_vni_toan_1_to_2", test_override_vni_toan_1_to_2),
            ("test_override_vni_toan_2_to_3", test_override_vni_toan_2_to_3),
            ("test_override_vni_toan_3_to_4", test_override_vni_toan_3_to_4),
            ("test_override_vni_toan_4_to_5", test_override_vni_toan_4_to_5),
            ("test_override_vni_toan_5_to_1", test_override_vni_toan_5_to_1),
            
            ("test_clear_telex_toans_z", test_clear_telex_toans_z),
            ("test_clear_telex_toanf_z", test_clear_telex_toanf_z),
            ("test_clear_telex_toanr_z", test_clear_telex_toanr_z),
            ("test_clear_telex_toanx_z", test_clear_telex_toanx_z),
            ("test_clear_telex_toanj_z", test_clear_telex_toanj_z),
            ("test_clear_telex_vieetj_z", test_clear_telex_vieetj_z),
            ("test_clear_telex_tieengs_z", test_clear_telex_tieengs_z),
            ("test_clear_telex_nguowfi_z", test_clear_telex_nguowfi_z),
            ("test_clear_telex_quyeenf_z", test_clear_telex_quyeenf_z),
            ("test_clear_telex_dduwowjc_z", test_clear_telex_dduwowjc_z),
            ("test_clear_telex_literal_z_toan", test_clear_telex_literal_z_toan),
            ("test_clear_telex_literal_z_viet", test_clear_telex_literal_z_viet),
            ("test_clear_telex_literal_z_nam", test_clear_telex_literal_z_nam),
            ("test_clear_telex_literal_z_hoc", test_clear_telex_literal_z_hoc),
            ("test_clear_vni_toan1_0", test_clear_vni_toan1_0),
            ("test_clear_vni_toan2_0", test_clear_vni_toan2_0),
            ("test_clear_vni_toan3_0", test_clear_vni_toan3_0),
            ("test_clear_vni_toan4_0", test_clear_vni_toan4_0),
            ("test_clear_vni_toan5_0", test_clear_vni_toan5_0),
            ("test_clear_vni_literal_0_toan", test_clear_vni_literal_0_toan),
        ]
    }
}
