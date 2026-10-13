//
//  TonePlacementTests.swift
//  VietFlowEngineTests
//
//  Tier 3: Dual Tone Placement Precision Suite (>= 90 test cases)
//  Compares Modern Style (hòa, thúy, khỏe) vs Traditional Style (hoà, thuý, khoẻ)
//  and verifies unanimous placement on closed rhymes and triphthongs.
//

import Foundation
import VietFlowEngine

public final class TonePlacementTests: VietFlowTestCase {
    private var modernEngine: VietnameseEngineProtocol!
    private var traditionalEngine: VietnameseEngineProtocol!
    
    public override func setUp() {
        super.setUp()
        modernEngine = makeEngine(inputMethod: .telex, tonePlacement: .modern)
        traditionalEngine = makeEngine(inputMethod: .telex, tonePlacement: .traditional)
    }
    
    private func assertModern(_ input: String, _ expected: String, file: StaticString = #file, line: UInt = #line) {
        modernEngine.reset()
        let (_, output) = typeSequence(input, into: modernEngine)
        XCTAssertEqual(output, expected, "Failed Modern for: '\(input)'", file: file, line: line)
    }
    
    private func assertTraditional(_ input: String, _ expected: String, file: StaticString = #file, line: UInt = #line) {
        traditionalEngine.reset()
        let (_, output) = typeSequence(input, into: traditionalEngine)
        XCTAssertEqual(output, expected, "Failed Traditional for: '\(input)'", file: file, line: line)
    }
    
    // MARK: - Open Diphthong 'oa' with 5 Tones (10 tests: 5 Modern + 5 Traditional)
    func test_tone_oa_s_modern() { assertModern("hoas", "hóa") }
    func test_tone_oa_f_modern() { assertModern("hoaf", "hòa") }
    func test_tone_oa_r_modern() { assertModern("hoar", "hỏa") }
    func test_tone_oa_x_modern() { assertModern("hoax", "hõa") }
    func test_tone_oa_j_modern() { assertModern("hoaj", "họa") }
    
    func test_tone_oa_s_traditional() { assertTraditional("hoas", "hoá") }
    func test_tone_oa_f_traditional() { assertTraditional("hoaf", "hoà") }
    func test_tone_oa_r_traditional() { assertTraditional("hoar", "hoả") }
    func test_tone_oa_x_traditional() { assertTraditional("hoax", "hoã") }
    func test_tone_oa_j_traditional() { assertTraditional("hoaj", "hoạ") }
    
    // MARK: - Open Diphthong 'uy' with 5 Tones (10 tests)
    func test_tone_uy_s_modern() { assertModern("thuys", "thúy") }
    func test_tone_uy_f_modern() { assertModern("thuyf", "thùy") }
    func test_tone_uy_r_modern() { assertModern("thuyr", "thủy") }
    func test_tone_uy_x_modern() { assertModern("thuyx", "thũy") }
    func test_tone_uy_j_modern() { assertModern("thuyj", "thụy") }
    
    func test_tone_uy_s_traditional() { assertTraditional("thuys", "thuý") }
    func test_tone_uy_f_traditional() { assertTraditional("thuyf", "thuỳ") }
    func test_tone_uy_r_traditional() { assertTraditional("thuyr", "thuỷ") }
    func test_tone_uy_x_traditional() { assertTraditional("thuyx", "thuỹ") }
    func test_tone_uy_j_traditional() { assertTraditional("thuyj", "thuỵ") }
    
    // MARK: - Open Diphthong 'oe' with 5 Tones (10 tests)
    func test_tone_oe_s_modern() { assertModern("khoes", "khóe") }
    func test_tone_oe_f_modern() { assertModern("khoef", "khòe") }
    func test_tone_oe_r_modern() { assertModern("khoer", "khỏe") }
    func test_tone_oe_x_modern() { assertModern("khoex", "khõe") }
    func test_tone_oe_j_modern() { assertModern("khoej", "khọe") }
    
    func test_tone_oe_s_traditional() { assertTraditional("khoes", "khoé") }
    func test_tone_oe_f_traditional() { assertTraditional("khoef", "khoè") }
    func test_tone_oe_r_traditional() { assertTraditional("khoer", "khoẻ") }
    func test_tone_oe_x_traditional() { assertTraditional("khoex", "khoẽ") }
    func test_tone_oe_j_traditional() { assertTraditional("khoej", "khoẹ") }
    
    // MARK: - Open Diphthong 'ue' (6 tests)
    func test_tone_ue_s_modern() { assertModern("thues", "thúe") }
    func test_tone_ue_f_modern() { assertModern("thuef", "thùe") }
    func test_tone_ue_r_modern() { assertModern("thuer", "thủe") }
    func test_tone_ue_s_traditional() { assertTraditional("thues", "thué") }
    func test_tone_ue_f_traditional() { assertTraditional("thuef", "thuè") }
    func test_tone_ue_r_traditional() { assertTraditional("thuer", "thuẻ") }
    
    // MARK: - Words: tuy, xoe, loa, thoa (12 tests)
    func test_tone_tuy_f_modern() { assertModern("tuyf", "tùy") }
    func test_tone_tuy_f_traditional() { assertTraditional("tuyf", "tuỳ") }
    func test_tone_tuy_s_modern() { assertModern("tuys", "túy") }
    func test_tone_tuy_s_traditional() { assertTraditional("tuys", "tuý") }
    
    func test_tone_xoe_r_modern() { assertModern("xoer", "xỏe") }
    func test_tone_xoe_r_traditional() { assertTraditional("xoer", "xoẻ") }
    func test_tone_xoe_x_modern() { assertModern("xoex", "xõe") }
    func test_tone_xoe_x_traditional() { assertTraditional("xoex", "xoẽ") }
    
    func test_tone_loa_f_modern() { assertModern("loaf", "lòa") }
    func test_tone_loa_f_traditional() { assertTraditional("loaf", "loà") }
    func test_tone_thoa_s_modern() { assertModern("thoas", "thóa") }
    func test_tone_thoa_s_traditional() { assertTraditional("thoas", "thoá") }
    
    // MARK: - Closed Rhymes (Must be IDENTICAL in both styles: 20 tests)
    func test_closed_toan_s_modern() { assertModern("toans", "toán") }
    func test_closed_toan_s_traditional() { assertTraditional("toans", "toán") }
    func test_closed_toan_f_modern() { assertModern("toanf", "toàn") }
    func test_closed_toan_f_traditional() { assertTraditional("toanf", "toàn") }
    func test_closed_toan_r_modern() { assertModern("toanr", "toản") }
    func test_closed_toan_r_traditional() { assertTraditional("toanr", "toản") }
    func test_closed_toan_x_modern() { assertModern("toanx", "toãn") }
    func test_closed_toan_x_traditional() { assertTraditional("toanx", "toãn") }
    func test_closed_toan_j_modern() { assertModern("toanj", "toạn") }
    func test_closed_toan_j_traditional() { assertTraditional("toanj", "toạn") }
    
    func test_closed_tien_s_modern() { assertModern("tieens", "tiến") }
    func test_closed_tien_s_traditional() { assertTraditional("tieens", "tiến") }
    func test_closed_tien_f_modern() { assertModern("tieenf", "tiền") }
    func test_closed_tien_f_traditional() { assertTraditional("tieenf", "tiền") }
    
    func test_closed_muon_j_modern() { assertModern("muwownj", "mượn") }
    func test_closed_muon_j_traditional() { assertTraditional("muwownj", "mượn") }
    func test_closed_thuan_j_modern() { assertModern("thuaanj", "thuận") }
    func test_closed_thuan_j_traditional() { assertTraditional("thuaanj", "thuận") }
    func test_closed_cuon_s_modern() { assertModern("cuoowns", "cuốn") }
    func test_closed_cuon_s_traditional() { assertTraditional("cuoowns", "cuốn") }
    
    // MARK: - Monophthongs (Identical in both styles: 12 tests)
    func test_mono_ba_s() { assertModern("bas", "bá"); assertTraditional("bas", "bá") }
    func test_mono_ba_f() { assertModern("baf", "bà"); assertTraditional("baf", "bà") }
    func test_mono_me_j() { assertModern("mej", "mẹ"); assertTraditional("mej", "mẹ") }
    func test_mono_ngu_r() { assertModern("ngur", "ngủ"); assertTraditional("ngur", "ngủ") }
    func test_mono_cho_s() { assertModern("chos", "chó"); assertTraditional("chos", "chó") }
    func test_mono_le_x() { assertModern("leex", "lễ"); assertTraditional("leex", "lễ") }
    
    // MARK: - Triphthongs & Glides (12 tests)
    func test_triphthong_khuay_s_modern() { assertModern("khuaays", "khuấy") }
    func test_triphthong_khuay_s_traditional() { assertTraditional("khuaays", "khuấy") }
    func test_triphthong_nghieng_f_modern() { assertModern("nghiengf", "nghiềng") }
    func test_triphthong_nghieng_f_traditional() { assertTraditional("nghiengf", "nghiềng") }
    func test_triphthong_quyen_f_modern() { assertModern("quyeenf", "quyền") }
    func test_triphthong_quyen_f_traditional() { assertTraditional("quyeenf", "quyền") }
    func test_triphthong_khuyen_s_modern() { assertModern("khuyeens", "khuyến") }
    func test_triphthong_khuyen_s_traditional() { assertTraditional("khuyeens", "khuyến") }
    func test_triphthong_chuyen_j_modern() { assertModern("chuyenj", "chuyện") }
    func test_triphthong_chuyen_j_traditional() { assertTraditional("chuyenj", "chuyện") }
    func test_triphthong_tuyen_s_modern() { assertModern("tuyeens", "tuyến") }
    func test_triphthong_tuyen_s_traditional() { assertTraditional("tuyeens", "tuyến") }
    
    // MARK: - Registration of all tests
    public override var allTests: [(name: String, test: TestMethod)] {
        return [
            ("test_tone_oa_s_modern", test_tone_oa_s_modern),
            ("test_tone_oa_f_modern", test_tone_oa_f_modern),
            ("test_tone_oa_r_modern", test_tone_oa_r_modern),
            ("test_tone_oa_x_modern", test_tone_oa_x_modern),
            ("test_tone_oa_j_modern", test_tone_oa_j_modern),
            ("test_tone_oa_s_traditional", test_tone_oa_s_traditional),
            ("test_tone_oa_f_traditional", test_tone_oa_f_traditional),
            ("test_tone_oa_r_traditional", test_tone_oa_r_traditional),
            ("test_tone_oa_x_traditional", test_tone_oa_x_traditional),
            ("test_tone_oa_j_traditional", test_tone_oa_j_traditional),
            
            ("test_tone_uy_s_modern", test_tone_uy_s_modern),
            ("test_tone_uy_f_modern", test_tone_uy_f_modern),
            ("test_tone_uy_r_modern", test_tone_uy_r_modern),
            ("test_tone_uy_x_modern", test_tone_uy_x_modern),
            ("test_tone_uy_j_modern", test_tone_uy_j_modern),
            ("test_tone_uy_s_traditional", test_tone_uy_s_traditional),
            ("test_tone_uy_f_traditional", test_tone_uy_f_traditional),
            ("test_tone_uy_r_traditional", test_tone_uy_r_traditional),
            ("test_tone_uy_x_traditional", test_tone_uy_x_traditional),
            ("test_tone_uy_j_traditional", test_tone_uy_j_traditional),
            
            ("test_tone_oe_s_modern", test_tone_oe_s_modern),
            ("test_tone_oe_f_modern", test_tone_oe_f_modern),
            ("test_tone_oe_r_modern", test_tone_oe_r_modern),
            ("test_tone_oe_x_modern", test_tone_oe_x_modern),
            ("test_tone_oe_j_modern", test_tone_oe_j_modern),
            ("test_tone_oe_s_traditional", test_tone_oe_s_traditional),
            ("test_tone_oe_f_traditional", test_tone_oe_f_traditional),
            ("test_tone_oe_r_traditional", test_tone_oe_r_traditional),
            ("test_tone_oe_x_traditional", test_tone_oe_x_traditional),
            ("test_tone_oe_j_traditional", test_tone_oe_j_traditional),
            
            ("test_tone_ue_s_modern", test_tone_ue_s_modern),
            ("test_tone_ue_f_modern", test_tone_ue_f_modern),
            ("test_tone_ue_r_modern", test_tone_ue_r_modern),
            ("test_tone_ue_s_traditional", test_tone_ue_s_traditional),
            ("test_tone_ue_f_traditional", test_tone_ue_f_traditional),
            ("test_tone_ue_r_traditional", test_tone_ue_r_traditional),
            
            ("test_tone_tuy_f_modern", test_tone_tuy_f_modern),
            ("test_tone_tuy_f_traditional", test_tone_tuy_f_traditional),
            ("test_tone_tuy_s_modern", test_tone_tuy_s_modern),
            ("test_tone_tuy_s_traditional", test_tone_tuy_s_traditional),
            ("test_tone_xoe_r_modern", test_tone_xoe_r_modern),
            ("test_tone_xoe_r_traditional", test_tone_xoe_r_traditional),
            ("test_tone_xoe_x_modern", test_tone_xoe_x_modern),
            ("test_tone_xoe_x_traditional", test_tone_xoe_x_traditional),
            ("test_tone_loa_f_modern", test_tone_loa_f_modern),
            ("test_tone_loa_f_traditional", test_tone_loa_f_traditional),
            ("test_tone_thoa_s_modern", test_tone_thoa_s_modern),
            ("test_tone_thoa_s_traditional", test_tone_thoa_s_traditional),
            
            ("test_closed_toan_s_modern", test_closed_toan_s_modern),
            ("test_closed_toan_s_traditional", test_closed_toan_s_traditional),
            ("test_closed_toan_f_modern", test_closed_toan_f_modern),
            ("test_closed_toan_f_traditional", test_closed_toan_f_traditional),
            ("test_closed_toan_r_modern", test_closed_toan_r_modern),
            ("test_closed_toan_r_traditional", test_closed_toan_r_traditional),
            ("test_closed_toan_x_modern", test_closed_toan_x_modern),
            ("test_closed_toan_x_traditional", test_closed_toan_x_traditional),
            ("test_closed_toan_j_modern", test_closed_toan_j_modern),
            ("test_closed_toan_j_traditional", test_closed_toan_j_traditional),
            
            ("test_closed_tien_s_modern", test_closed_tien_s_modern),
            ("test_closed_tien_s_traditional", test_closed_tien_s_traditional),
            ("test_closed_tien_f_modern", test_closed_tien_f_modern),
            ("test_closed_tien_f_traditional", test_closed_tien_f_traditional),
            ("test_closed_muon_j_modern", test_closed_muon_j_modern),
            ("test_closed_muon_j_traditional", test_closed_muon_j_traditional),
            ("test_closed_thuan_j_modern", test_closed_thuan_j_modern),
            ("test_closed_thuan_j_traditional", test_closed_thuan_j_traditional),
            ("test_closed_cuon_s_modern", test_closed_cuon_s_modern),
            ("test_closed_cuon_s_traditional", test_closed_cuon_s_traditional),
            
            ("test_mono_ba_s", test_mono_ba_s),
            ("test_mono_ba_f", test_mono_ba_f),
            ("test_mono_me_j", test_mono_me_j),
            ("test_mono_ngu_r", test_mono_ngu_r),
            ("test_mono_cho_s", test_mono_cho_s),
            ("test_mono_le_x", test_mono_le_x),
            
            ("test_triphthong_khuay_s_modern", test_triphthong_khuay_s_modern),
            ("test_triphthong_khuay_s_traditional", test_triphthong_khuay_s_traditional),
            ("test_triphthong_nghieng_f_modern", test_triphthong_nghieng_f_modern),
            ("test_triphthong_nghieng_f_traditional", test_triphthong_nghieng_f_traditional),
            ("test_triphthong_quyen_f_modern", test_triphthong_quyen_f_modern),
            ("test_triphthong_quyen_f_traditional", test_triphthong_quyen_f_traditional),
            ("test_triphthong_khuyen_s_modern", test_triphthong_khuyen_s_modern),
            ("test_triphthong_khuyen_s_traditional", test_triphthong_khuyen_s_traditional),
            ("test_triphthong_chuyen_j_modern", test_triphthong_chuyen_j_modern),
            ("test_triphthong_chuyen_j_traditional", test_triphthong_chuyen_j_traditional),
            ("test_triphthong_tuyen_s_modern", test_triphthong_tuyen_s_modern),
            ("test_triphthong_tuyen_s_traditional", test_triphthong_tuyen_s_traditional),
        ]
    }
}
