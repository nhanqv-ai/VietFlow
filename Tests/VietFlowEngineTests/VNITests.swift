//
//  VNITests.swift
//  VietFlowEngineTests
//
//  Tier 1: VNI Input Method Full Feature Suite (>= 120 test cases)
//  Numbers 1-5 for tones, 6-9 for diacritics, 0 for clear tone, number preservation.
//

import Foundation
import VietFlowEngine

public final class VNITests: VietFlowTestCase {
    private var engine: VietnameseEngineProtocol!
    
    public override func setUp() {
        super.setUp()
        engine = makeEngine(inputMethod: .vni, tonePlacement: .modern)
    }
    
    private func assertVNI(_ input: String, _ expected: String, file: StaticString = #file, line: UInt = #line) {
        engine.reset()
        let (_, output) = typeSequence(input, into: engine)
        XCTAssertEqual(output, expected, "Failed VNI for: '\(input)'", file: file, line: line)
    }
    
    // MARK: - Diacritics 6-9 (14 tests)
    func test_vni_diacritic_a8() { assertVNI("a8", "ă") }
    func test_vni_diacritic_a6() { assertVNI("a6", "â") }
    func test_vni_diacritic_e6() { assertVNI("e6", "ê") }
    func test_vni_diacritic_o6() { assertVNI("o6", "ô") }
    func test_vni_diacritic_o7() { assertVNI("o7", "ơ") }
    func test_vni_diacritic_u7() { assertVNI("u7", "ư") }
    func test_vni_diacritic_d9() { assertVNI("d9", "đ") }
    
    func test_vni_diacritic_A8() { assertVNI("A8", "Ă") }
    func test_vni_diacritic_A6() { assertVNI("A6", "Â") }
    func test_vni_diacritic_E6() { assertVNI("E6", "Ê") }
    func test_vni_diacritic_O6() { assertVNI("O6", "Ô") }
    func test_vni_diacritic_O7() { assertVNI("O7", "Ơ") }
    func test_vni_diacritic_U7() { assertVNI("U7", "Ư") }
    func test_vni_diacritic_D9() { assertVNI("D9", "Đ") }
    
    // MARK: - Vowel 'a' with 6 Tones (5 tests)
    func test_vni_tone_a1() { assertVNI("a1", "á") }
    func test_vni_tone_a2() { assertVNI("a2", "à") }
    func test_vni_tone_a3() { assertVNI("a3", "ả") }
    func test_vni_tone_a4() { assertVNI("a4", "ã") }
    func test_vni_tone_a5() { assertVNI("a5", "ạ") }
    
    // MARK: - Vowel 'ă' (a8) with 6 Tones (5 tests)
    func test_vni_tone_a81() { assertVNI("a81", "ắ") }
    func test_vni_tone_a82() { assertVNI("a82", "ằ") }
    func test_vni_tone_a83() { assertVNI("a83", "ẳ") }
    func test_vni_tone_a84() { assertVNI("a84", "ẵ") }
    func test_vni_tone_a85() { assertVNI("a85", "ặ") }
    
    // MARK: - Vowel 'â' (a6) with 6 Tones (5 tests)
    func test_vni_tone_a61() { assertVNI("a61", "ấ") }
    func test_vni_tone_a62() { assertVNI("a62", "ầ") }
    func test_vni_tone_a63() { assertVNI("a63", "ẩ") }
    func test_vni_tone_a64() { assertVNI("a64", "ẫ") }
    func test_vni_tone_a65() { assertVNI("a65", "ậ") }
    
    // MARK: - Vowel 'e' with 6 Tones (5 tests)
    func test_vni_tone_e1() { assertVNI("e1", "é") }
    func test_vni_tone_e2() { assertVNI("e2", "è") }
    func test_vni_tone_e3() { assertVNI("e3", "ẻ") }
    func test_vni_tone_e4() { assertVNI("e4", "ẽ") }
    func test_vni_tone_e5() { assertVNI("e5", "ẹ") }
    
    // MARK: - Vowel 'ê' (e6) with 6 Tones (5 tests)
    func test_vni_tone_e61() { assertVNI("e61", "ế") }
    func test_vni_tone_e62() { assertVNI("e62", "ề") }
    func test_vni_tone_e63() { assertVNI("e63", "ể") }
    func test_vni_tone_e64() { assertVNI("e64", "ễ") }
    func test_vni_tone_e65() { assertVNI("e65", "ệ") }
    
    // MARK: - Vowel 'i' with 6 Tones (5 tests)
    func test_vni_tone_i1() { assertVNI("i1", "í") }
    func test_vni_tone_i2() { assertVNI("i2", "ì") }
    func test_vni_tone_i3() { assertVNI("i3", "ỉ") }
    func test_vni_tone_i4() { assertVNI("i4", "ĩ") }
    func test_vni_tone_i5() { assertVNI("i5", "ị") }
    
    // MARK: - Vowel 'o' with 6 Tones (5 tests)
    func test_vni_tone_o1() { assertVNI("o1", "ó") }
    func test_vni_tone_o2() { assertVNI("o2", "ò") }
    func test_vni_tone_o3() { assertVNI("o3", "ỏ") }
    func test_vni_tone_o4() { assertVNI("o4", "õ") }
    func test_vni_tone_o5() { assertVNI("o5", "ọ") }
    
    // MARK: - Vowel 'ô' (o6) with 6 Tones (5 tests)
    func test_vni_tone_o61() { assertVNI("o61", "ố") }
    func test_vni_tone_o62() { assertVNI("o62", "ồ") }
    func test_vni_tone_o63() { assertVNI("o63", "ổ") }
    func test_vni_tone_o64() { assertVNI("o64", "ỗ") }
    func test_vni_tone_o65() { assertVNI("o65", "ộ") }
    
    // MARK: - Vowel 'ơ' (o7) with 6 Tones (5 tests)
    func test_vni_tone_o71() { assertVNI("o71", "ớ") }
    func test_vni_tone_o72() { assertVNI("o72", "ờ") }
    func test_vni_tone_o73() { assertVNI("o73", "ở") }
    func test_vni_tone_o74() { assertVNI("o74", "ỡ") }
    func test_vni_tone_o75() { assertVNI("o75", "ợ") }
    
    // MARK: - Vowel 'u' with 6 Tones (5 tests)
    func test_vni_tone_u1() { assertVNI("u1", "ú") }
    func test_vni_tone_u2() { assertVNI("u2", "ù") }
    func test_vni_tone_u3() { assertVNI("u3", "ủ") }
    func test_vni_tone_u4() { assertVNI("u4", "ũ") }
    func test_vni_tone_u5() { assertVNI("u5", "ụ") }
    
    // MARK: - Vowel 'ư' (u7) with 6 Tones (5 tests)
    func test_vni_tone_u71() { assertVNI("u71", "ứ") }
    func test_vni_tone_u72() { assertVNI("u72", "ừ") }
    func test_vni_tone_u73() { assertVNI("u73", "ử") }
    func test_vni_tone_u74() { assertVNI("u74", "ữ") }
    func test_vni_tone_u75() { assertVNI("u75", "ự") }
    
    // MARK: - Vowel 'y' with 6 Tones (5 tests)
    func test_vni_tone_y1() { assertVNI("y1", "ý") }
    func test_vni_tone_y2() { assertVNI("y2", "ỳ") }
    func test_vni_tone_y3() { assertVNI("y3", "ỷ") }
    func test_vni_tone_y4() { assertVNI("y4", "ỹ") }
    func test_vni_tone_y5() { assertVNI("y5", "ỵ") }
    
    // MARK: - Common Syllables in VNI (35 tests)
    func test_vni_word_ba1() { assertVNI("ba1", "bá") }
    func test_vni_word_ba2() { assertVNI("ba2", "bà") }
    func test_vni_word_ba3() { assertVNI("ba3", "bả") }
    func test_vni_word_ba4() { assertVNI("ba4", "bã") }
    func test_vni_word_ba5() { assertVNI("ba5", "bạ") }
    
    func test_vni_word_ca1() { assertVNI("ca1", "cá") }
    func test_vni_word_ca2() { assertVNI("ca2", "cà") }
    
    func test_vni_word_viet() { assertVNI("vie65t", "việt") }
    func test_vni_word_viet_end() { assertVNI("vie6t5", "việt") }
    func test_vni_word_nam() { assertVNI("nam", "nam") }
    func test_vni_word_tieng() { assertVNI("tie61ng", "tiếng") }
    func test_vni_word_tieng_end() { assertVNI("tie6ng1", "tiếng") }
    
    func test_vni_word_toan() { assertVNI("toan1", "toán") }
    func test_vni_word_toan_mid() { assertVNI("toa1n", "toán") }
    func test_vni_word_hoc() { assertVNI("ho5c", "học") }
    func test_vni_word_hoc_end() { assertVNI("hoc5", "học") }
    
    func test_vni_word_dat() { assertVNI("d9a85t", "đặt") }
    func test_vni_word_dat_end() { assertVNI("d9a8t5", "đặt") }
    func test_vni_word_duoc() { assertVNI("d9u7o75c", "được") }
    func test_vni_word_nguoi() { assertVNI("ngu7o7i2", "người") }
    func test_vni_word_truong() { assertVNI("tru7o7ng2", "trường") }
    func test_vni_word_nuoc() { assertVNI("nu7o71c", "nước") }
    func test_vni_word_buoc() { assertVNI("bu7o71c", "bước") }
    func test_vni_word_muon() { assertVNI("mu7o75n", "mượn") }
    
    func test_vni_word_dong() { assertVNI("d9o62ng", "đồng") }
    func test_vni_word_som() { assertVNI("so71m", "sớm") }
    func test_vni_word_toi() { assertVNI("to61i", "tối") }
    func test_vni_word_pho() { assertVNI("pho61", "phố") }
    func test_vni_word_nha() { assertVNI("nha2", "nhà") }
    func test_vni_word_me() { assertVNI("me5", "mẹ") }
    func test_vni_word_bo() { assertVNI("bo61", "bố") }
    func test_vni_word_con() { assertVNI("con", "con") }
    func test_vni_word_chuc() { assertVNI("chu1c", "chúc") }
    func test_vni_word_mung() { assertVNI("mu72ng", "mừng") }
    func test_vni_word_nam_moi() { assertVNI("mo71i", "mới") }
    
    // MARK: - Clear Tone with '0' (10 tests)
    func test_vni_clear_toan() { assertVNI("toan10", "toan") }
    func test_vni_clear_ba() { assertVNI("ba10", "ba") }
    func test_vni_clear_ca() { assertVNI("ca20", "ca") }
    func test_vni_clear_me() { assertVNI("me50", "me") }
    func test_vni_clear_ngu() { assertVNI("ngu30", "ngu") }
    func test_vni_clear_tieng() { assertVNI("tie6ng10", "tiêng") }
    func test_vni_clear_viet() { assertVNI("vie6t50", "viêt") }
    func test_vni_clear_pho() { assertVNI("pho610", "phô") }
    func test_vni_clear_so() { assertVNI("so710", "sơ") }
    func test_vni_clear_literal_0() { assertVNI("toan0", "toan0") }
    
    // MARK: - Number Preservation Tests (10 tests)
    func test_vni_number_100() { assertVNI("100", "100") }
    func test_vni_number_2026() { assertVNI("2026", "2026") }
    func test_vni_number_12345() { assertVNI("12345", "12345") }
    func test_vni_number_6789() { assertVNI("6789", "6789") }
    func test_vni_number_999() { assertVNI("999", "999") }
    func test_vni_number_0() { assertVNI("0", "0") }
    func test_vni_number_007() { assertVNI("007", "007") }
    func test_vni_number_pi() { assertVNI("3.14", "3.14") }
    func test_vni_number_phone() { assertVNI("0901234567", "0901234567") }
    func test_vni_number_port_8080() { assertVNI("8080", "8080") }
    
    // MARK: - Registration of all tests
    public override var allTests: [(name: String, test: TestMethod)] {
        return [
            ("test_vni_diacritic_a8", test_vni_diacritic_a8),
            ("test_vni_diacritic_a6", test_vni_diacritic_a6),
            ("test_vni_diacritic_e6", test_vni_diacritic_e6),
            ("test_vni_diacritic_o6", test_vni_diacritic_o6),
            ("test_vni_diacritic_o7", test_vni_diacritic_o7),
            ("test_vni_diacritic_u7", test_vni_diacritic_u7),
            ("test_vni_diacritic_d9", test_vni_diacritic_d9),
            ("test_vni_diacritic_A8", test_vni_diacritic_A8),
            ("test_vni_diacritic_A6", test_vni_diacritic_A6),
            ("test_vni_diacritic_E6", test_vni_diacritic_E6),
            ("test_vni_diacritic_O6", test_vni_diacritic_O6),
            ("test_vni_diacritic_O7", test_vni_diacritic_O7),
            ("test_vni_diacritic_U7", test_vni_diacritic_U7),
            ("test_vni_diacritic_D9", test_vni_diacritic_D9),
            
            ("test_vni_tone_a1", test_vni_tone_a1),
            ("test_vni_tone_a2", test_vni_tone_a2),
            ("test_vni_tone_a3", test_vni_tone_a3),
            ("test_vni_tone_a4", test_vni_tone_a4),
            ("test_vni_tone_a5", test_vni_tone_a5),
            
            ("test_vni_tone_a81", test_vni_tone_a81),
            ("test_vni_tone_a82", test_vni_tone_a82),
            ("test_vni_tone_a83", test_vni_tone_a83),
            ("test_vni_tone_a84", test_vni_tone_a84),
            ("test_vni_tone_a85", test_vni_tone_a85),
            
            ("test_vni_tone_a61", test_vni_tone_a61),
            ("test_vni_tone_a62", test_vni_tone_a62),
            ("test_vni_tone_a63", test_vni_tone_a63),
            ("test_vni_tone_a64", test_vni_tone_a64),
            ("test_vni_tone_a65", test_vni_tone_a65),
            
            ("test_vni_tone_e1", test_vni_tone_e1),
            ("test_vni_tone_e2", test_vni_tone_e2),
            ("test_vni_tone_e3", test_vni_tone_e3),
            ("test_vni_tone_e4", test_vni_tone_e4),
            ("test_vni_tone_e5", test_vni_tone_e5),
            
            ("test_vni_tone_e61", test_vni_tone_e61),
            ("test_vni_tone_e62", test_vni_tone_e62),
            ("test_vni_tone_e63", test_vni_tone_e63),
            ("test_vni_tone_e64", test_vni_tone_e64),
            ("test_vni_tone_e65", test_vni_tone_e65),
            
            ("test_vni_tone_i1", test_vni_tone_i1),
            ("test_vni_tone_i2", test_vni_tone_i2),
            ("test_vni_tone_i3", test_vni_tone_i3),
            ("test_vni_tone_i4", test_vni_tone_i4),
            ("test_vni_tone_i5", test_vni_tone_i5),
            
            ("test_vni_tone_o1", test_vni_tone_o1),
            ("test_vni_tone_o2", test_vni_tone_o2),
            ("test_vni_tone_o3", test_vni_tone_o3),
            ("test_vni_tone_o4", test_vni_tone_o4),
            ("test_vni_tone_o5", test_vni_tone_o5),
            
            ("test_vni_tone_o61", test_vni_tone_o61),
            ("test_vni_tone_o62", test_vni_tone_o62),
            ("test_vni_tone_o63", test_vni_tone_o63),
            ("test_vni_tone_o64", test_vni_tone_o64),
            ("test_vni_tone_o65", test_vni_tone_o65),
            
            ("test_vni_tone_o71", test_vni_tone_o71),
            ("test_vni_tone_o72", test_vni_tone_o72),
            ("test_vni_tone_o73", test_vni_tone_o73),
            ("test_vni_tone_o74", test_vni_tone_o74),
            ("test_vni_tone_o75", test_vni_tone_o75),
            
            ("test_vni_tone_u1", test_vni_tone_u1),
            ("test_vni_tone_u2", test_vni_tone_u2),
            ("test_vni_tone_u3", test_vni_tone_u3),
            ("test_vni_tone_u4", test_vni_tone_u4),
            ("test_vni_tone_u5", test_vni_tone_u5),
            
            ("test_vni_tone_u71", test_vni_tone_u71),
            ("test_vni_tone_u72", test_vni_tone_u72),
            ("test_vni_tone_u73", test_vni_tone_u73),
            ("test_vni_tone_u74", test_vni_tone_u74),
            ("test_vni_tone_u75", test_vni_tone_u75),
            
            ("test_vni_tone_y1", test_vni_tone_y1),
            ("test_vni_tone_y2", test_vni_tone_y2),
            ("test_vni_tone_y3", test_vni_tone_y3),
            ("test_vni_tone_y4", test_vni_tone_y4),
            ("test_vni_tone_y5", test_vni_tone_y5),
            
            ("test_vni_word_ba1", test_vni_word_ba1),
            ("test_vni_word_ba2", test_vni_word_ba2),
            ("test_vni_word_ba3", test_vni_word_ba3),
            ("test_vni_word_ba4", test_vni_word_ba4),
            ("test_vni_word_ba5", test_vni_word_ba5),
            ("test_vni_word_ca1", test_vni_word_ca1),
            ("test_vni_word_ca2", test_vni_word_ca2),
            ("test_vni_word_viet", test_vni_word_viet),
            ("test_vni_word_viet_end", test_vni_word_viet_end),
            ("test_vni_word_nam", test_vni_word_nam),
            ("test_vni_word_tieng", test_vni_word_tieng),
            ("test_vni_word_tieng_end", test_vni_word_tieng_end),
            ("test_vni_word_toan", test_vni_word_toan),
            ("test_vni_word_toan_mid", test_vni_word_toan_mid),
            ("test_vni_word_hoc", test_vni_word_hoc),
            ("test_vni_word_hoc_end", test_vni_word_hoc_end),
            ("test_vni_word_dat", test_vni_word_dat),
            ("test_vni_word_dat_end", test_vni_word_dat_end),
            ("test_vni_word_duoc", test_vni_word_duoc),
            ("test_vni_word_nguoi", test_vni_word_nguoi),
            ("test_vni_word_truong", test_vni_word_truong),
            ("test_vni_word_nuoc", test_vni_word_nuoc),
            ("test_vni_word_buoc", test_vni_word_buoc),
            ("test_vni_word_muon", test_vni_word_muon),
            ("test_vni_word_dong", test_vni_word_dong),
            ("test_vni_word_som", test_vni_word_som),
            ("test_vni_word_toi", test_vni_word_toi),
            ("test_vni_word_pho", test_vni_word_pho),
            ("test_vni_word_nha", test_vni_word_nha),
            ("test_vni_word_me", test_vni_word_me),
            ("test_vni_word_bo", test_vni_word_bo),
            ("test_vni_word_con", test_vni_word_con),
            ("test_vni_word_chuc", test_vni_word_chuc),
            ("test_vni_word_mung", test_vni_word_mung),
            ("test_vni_word_nam_moi", test_vni_word_nam_moi),
            
            ("test_vni_clear_toan", test_vni_clear_toan),
            ("test_vni_clear_ba", test_vni_clear_ba),
            ("test_vni_clear_ca", test_vni_clear_ca),
            ("test_vni_clear_me", test_vni_clear_me),
            ("test_vni_clear_ngu", test_vni_clear_ngu),
            ("test_vni_clear_tieng", test_vni_clear_tieng),
            ("test_vni_clear_viet", test_vni_clear_viet),
            ("test_vni_clear_pho", test_vni_clear_pho),
            ("test_vni_clear_so", test_vni_clear_so),
            ("test_vni_clear_literal_0", test_vni_clear_literal_0),
            
            ("test_vni_number_100", test_vni_number_100),
            ("test_vni_number_2026", test_vni_number_2026),
            ("test_vni_number_12345", test_vni_number_12345),
            ("test_vni_number_6789", test_vni_number_6789),
            ("test_vni_number_999", test_vni_number_999),
            ("test_vni_number_0", test_vni_number_0),
            ("test_vni_number_007", test_vni_number_007),
            ("test_vni_number_pi", test_vni_number_pi),
            ("test_vni_number_phone", test_vni_number_phone),
            ("test_vni_number_port_8080", test_vni_number_port_8080),
        ]
    }
}
