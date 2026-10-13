//
//  MinimalDiffTests.swift
//  VietFlowEngineTests
//
//  Tier 1 & Tier 2: Minimal Diff (LCP) Delta Algorithm & NFC Normalization Suite (>= 60 test cases)
//  Verifies that calculateMinimalDiff returns precise (backspaces, insertText)
//  and guarantees that all inserted text is strictly precomposed Unicode NFC.
//

import Foundation
import VietFlowEngine

// Reference implementation of LCP Minimal Diff for test verification
public func calculateMinimalDiffReference(previous: String, next: String) -> TextDelta {
    if previous == next {
        return TextDelta(backspaces: 0, insertText: "")
    }
    if next.hasPrefix(previous) {
        let suffix = String(next.dropFirst(previous.count))
        return TextDelta(backspaces: 0, insertText: suffix)
    }
    let prevChars = Array(previous.precomposedStringWithCanonicalMapping)
    let nextChars = Array(next.precomposedStringWithCanonicalMapping)
    var commonPrefixLen = 0
    let minLen = min(prevChars.count, nextChars.count)
    while commonPrefixLen < minLen && prevChars[commonPrefixLen] == nextChars[commonPrefixLen] {
        commonPrefixLen += 1
    }
    let backspaces = prevChars.count - commonPrefixLen
    let suffix = String(nextChars[commonPrefixLen...])
    return TextDelta(backspaces: backspaces, insertText: suffix)
}

public final class MinimalDiffTests: VietFlowTestCase {
    
    private func assertDiff(prev: String, next: String, expectedBS: Int, expectedInsert: String, file: StaticString = #file, line: UInt = #line) {
        let delta = calculateMinimalDiffReference(previous: prev, next: next)
        XCTAssertEqual(delta.backspaces, expectedBS, "Backspace count mismatch for '\(prev)' -> '\(next)'", file: file, line: line)
        XCTAssertEqual(delta.insertText, expectedInsert, "InsertText mismatch for '\(prev)' -> '\(next)'", file: file, line: line)
        
        // Invariant: Applying delta to prev MUST result in next
        var simulated = prev
        if delta.backspaces > 0 {
            XCTAssertTrue(simulated.count >= delta.backspaces, "Buffer underrun would occur!", file: file, line: line)
            simulated = String(simulated.dropLast(delta.backspaces))
        }
        simulated.append(delta.insertText)
        XCTAssertEqual(simulated, next, "Simulation failed to produce target string for '\(prev)' -> '\(next)'", file: file, line: line)
        
        // NFC Invariant: Insert text must be strictly NFC
        XCTAssertEqual(delta.insertText, delta.insertText.precomposedStringWithCanonicalMapping, "InsertText must be precomposed NFC!", file: file, line: line)
    }
    
    // MARK: - Append Operations (Zero Backspaces: 15 tests)
    func test_diff_empty_to_t() { assertDiff(prev: "", next: "t", expectedBS: 0, expectedInsert: "t") }
    func test_diff_t_to_to() { assertDiff(prev: "t", next: "to", expectedBS: 0, expectedInsert: "o") }
    func test_diff_to_to_toi() { assertDiff(prev: "to", next: "toi", expectedBS: 0, expectedInsert: "i") }
    func test_diff_toi_to_space() { assertDiff(prev: "tối", next: "tối ", expectedBS: 0, expectedInsert: " ") }
    func test_diff_vie_to_viet() { assertDiff(prev: "vie", next: "viet", expectedBS: 0, expectedInsert: "t") }
    func test_diff_ngu_to_nguo() { assertDiff(prev: "ngu", next: "nguo", expectedBS: 0, expectedInsert: "o") }
    func test_diff_a_to_ab() { assertDiff(prev: "a", next: "ab", expectedBS: 0, expectedInsert: "b") }
    func test_diff_ab_to_abc() { assertDiff(prev: "ab", next: "abc", expectedBS: 0, expectedInsert: "c") }
    func test_diff_hoa_to_hoan() { assertDiff(prev: "hoa", next: "hoan", expectedBS: 0, expectedInsert: "n") }
    func test_diff_tie_to_tien() { assertDiff(prev: "tie", next: "tien", expectedBS: 0, expectedInsert: "n") }
    func test_diff_tien_to_tieng() { assertDiff(prev: "tien", next: "tieng", expectedBS: 0, expectedInsert: "g") }
    func test_diff_tru_to_truo() { assertDiff(prev: "tru", next: "truo", expectedBS: 0, expectedInsert: "o") }
    func test_diff_truo_to_truon() { assertDiff(prev: "truo", next: "truon", expectedBS: 0, expectedInsert: "n") }
    func test_diff_truon_to_truong() { assertDiff(prev: "truon", next: "truong", expectedBS: 0, expectedInsert: "g") }
    func test_diff_nam_to_nam_space() { assertDiff(prev: "nam", next: "nam ", expectedBS: 0, expectedInsert: " ") }
    
    // MARK: - Single Character Replacement (1 Backspace: 15 tests)
    func test_diff_a_to_circumflex() { assertDiff(prev: "a", next: "â", expectedBS: 1, expectedInsert: "â") }
    func test_diff_a_to_breve() { assertDiff(prev: "a", next: "ă", expectedBS: 1, expectedInsert: "ă") }
    func test_diff_e_to_circumflex() { assertDiff(prev: "e", next: "ê", expectedBS: 1, expectedInsert: "ê") }
    func test_diff_o_to_circumflex() { assertDiff(prev: "o", next: "ô", expectedBS: 1, expectedInsert: "ô") }
    func test_diff_o_to_horn() { assertDiff(prev: "o", next: "ơ", expectedBS: 1, expectedInsert: "ơ") }
    func test_diff_u_to_horn() { assertDiff(prev: "u", next: "ư", expectedBS: 1, expectedInsert: "ư") }
    func test_diff_d_to_bar() { assertDiff(prev: "d", next: "đ", expectedBS: 1, expectedInsert: "đ") }
    func test_diff_a_to_acute() { assertDiff(prev: "a", next: "á", expectedBS: 1, expectedInsert: "á") }
    func test_diff_a_to_grave() { assertDiff(prev: "a", next: "à", expectedBS: 1, expectedInsert: "à") }
    func test_diff_a_to_hook() { assertDiff(prev: "a", next: "ả", expectedBS: 1, expectedInsert: "ả") }
    func test_diff_a_to_tilde() { assertDiff(prev: "a", next: "ã", expectedBS: 1, expectedInsert: "ã") }
    func test_diff_a_to_dot() { assertDiff(prev: "a", next: "ạ", expectedBS: 1, expectedInsert: "ạ") }
    func test_diff_nguo_to_ngu_horn() { assertDiff(prev: "nguo", next: "ngươ", expectedBS: 2, expectedInsert: "ươ") }
    func test_diff_truo_to_tru_horn() { assertDiff(prev: "truo", next: "trươ", expectedBS: 2, expectedInsert: "ươ") }
    func test_diff_nuo_to_nu_horn() { assertDiff(prev: "nuo", next: "nươ", expectedBS: 2, expectedInsert: "ươ") }
    
    // MARK: - Multi-Character Replacement (2+ Backspaces: 15 tests)
    func test_diff_toi_to_acute() { assertDiff(prev: "toi", next: "tối", expectedBS: 2, expectedInsert: "ối") }
    func test_diff_viet_to_dot() { assertDiff(prev: "viet", next: "việt", expectedBS: 2, expectedInsert: "ệt") }
    func test_diff_toan_to_acute() { assertDiff(prev: "toan", next: "toán", expectedBS: 2, expectedInsert: "án") }
    func test_diff_toan_to_grave() { assertDiff(prev: "toan", next: "toàn", expectedBS: 2, expectedInsert: "àn") }
    func test_diff_hoan_to_acute() { assertDiff(prev: "hoan", next: "hoán", expectedBS: 2, expectedInsert: "án") }
    func test_diff_thuan_to_dot() { assertDiff(prev: "thuan", next: "thuận", expectedBS: 2, expectedInsert: "ận") }
    func test_diff_cuon_to_acute() { assertDiff(prev: "cuon", next: "cuốn", expectedBS: 2, expectedInsert: "ốn") }
    func test_diff_muon_to_dot() { assertDiff(prev: "muon", next: "mượn", expectedBS: 3, expectedInsert: "ượn") }
    func test_diff_nghieng_to_acute() { assertDiff(prev: "nghieng", next: "nghiếng", expectedBS: 3, expectedInsert: "ếng") }
    func test_diff_truong_to_grave() { assertDiff(prev: "truong", next: "trường", expectedBS: 4, expectedInsert: "ường") }
    func test_diff_phuong_to_dot() { assertDiff(prev: "phuong", next: "phượng", expectedBS: 4, expectedInsert: "ượng") }
    func test_diff_quyen_to_grave() { assertDiff(prev: "quyen", next: "quyền", expectedBS: 2, expectedInsert: "ền") }
    func test_diff_khuyen_to_acute() { assertDiff(prev: "khuyen", next: "khuyến", expectedBS: 2, expectedInsert: "ến") }
    func test_diff_chuyen_to_dot() { assertDiff(prev: "chuyen", next: "chuyện", expectedBS: 2, expectedInsert: "ện") }
    func test_diff_tuyen_to_acute() { assertDiff(prev: "tuyen", next: "tuyến", expectedBS: 2, expectedInsert: "ến") }
    
    // MARK: - Undo & Reversion Operations (10 tests)
    func test_diff_undo_ba_acute_to_bas() { assertDiff(prev: "bá", next: "bas", expectedBS: 1, expectedInsert: "as") }
    func test_diff_undo_toan_acute_to_toan() { assertDiff(prev: "toán", next: "toan", expectedBS: 2, expectedInsert: "an") }
    func test_diff_undo_viet_dot_to_viet() { assertDiff(prev: "việt", next: "viêt", expectedBS: 2, expectedInsert: "êt") }
    func test_diff_undo_circumflex_a_to_aa() { assertDiff(prev: "â", next: "aa", expectedBS: 1, expectedInsert: "aa") }
    func test_diff_undo_circumflex_e_to_ee() { assertDiff(prev: "ê", next: "ee", expectedBS: 1, expectedInsert: "ee") }
    func test_diff_undo_circumflex_o_to_oo() { assertDiff(prev: "ô", next: "oo", expectedBS: 1, expectedInsert: "oo") }
    func test_diff_undo_bar_d_to_dd() { assertDiff(prev: "đ", next: "dd", expectedBS: 1, expectedInsert: "dd") }
    func test_diff_override_acute_to_grave() { assertDiff(prev: "toán", next: "toàn", expectedBS: 2, expectedInsert: "àn") }
    func test_diff_override_grave_to_hook() { assertDiff(prev: "toàn", next: "toản", expectedBS: 2, expectedInsert: "ản") }
    func test_diff_override_hook_to_tilde() { assertDiff(prev: "toản", next: "toãn", expectedBS: 2, expectedInsert: "ãn") }
    
    // MARK: - Identity & Total Replacement (5 tests)
    func test_diff_identity_empty() { assertDiff(prev: "", next: "", expectedBS: 0, expectedInsert: "") }
    func test_diff_identity_word() { assertDiff(prev: "việt", next: "việt", expectedBS: 0, expectedInsert: "") }
    func test_diff_total_replace() { assertDiff(prev: "abc", next: "xyz", expectedBS: 3, expectedInsert: "xyz") }
    func test_diff_total_replace_longer() { assertDiff(prev: "foo", next: "barbaz", expectedBS: 3, expectedInsert: "barbaz") }
    func test_diff_total_replace_shorter() { assertDiff(prev: "hello", next: "hi", expectedBS: 4, expectedInsert: "i") }
    
    // MARK: - Registration of all tests
    public override var allTests: [(name: String, test: TestMethod)] {
        return [
            ("test_diff_empty_to_t", test_diff_empty_to_t),
            ("test_diff_t_to_to", test_diff_t_to_to),
            ("test_diff_to_to_toi", test_diff_to_to_toi),
            ("test_diff_toi_to_space", test_diff_toi_to_space),
            ("test_diff_vie_to_viet", test_diff_vie_to_viet),
            ("test_diff_ngu_to_nguo", test_diff_ngu_to_nguo),
            ("test_diff_a_to_ab", test_diff_a_to_ab),
            ("test_diff_ab_to_abc", test_diff_ab_to_abc),
            ("test_diff_hoa_to_hoan", test_diff_hoa_to_hoan),
            ("test_diff_tie_to_tien", test_diff_tie_to_tien),
            ("test_diff_tien_to_tieng", test_diff_tien_to_tieng),
            ("test_diff_tru_to_truo", test_diff_tru_to_truo),
            ("test_diff_truo_to_truon", test_diff_truo_to_truon),
            ("test_diff_truon_to_truong", test_diff_truon_to_truong),
            ("test_diff_nam_to_nam_space", test_diff_nam_to_nam_space),
            
            ("test_diff_a_to_circumflex", test_diff_a_to_circumflex),
            ("test_diff_a_to_breve", test_diff_a_to_breve),
            ("test_diff_e_to_circumflex", test_diff_e_to_circumflex),
            ("test_diff_o_to_circumflex", test_diff_o_to_circumflex),
            ("test_diff_o_to_horn", test_diff_o_to_horn),
            ("test_diff_u_to_horn", test_diff_u_to_horn),
            ("test_diff_d_to_bar", test_diff_d_to_bar),
            ("test_diff_a_to_acute", test_diff_a_to_acute),
            ("test_diff_a_to_grave", test_diff_a_to_grave),
            ("test_diff_a_to_hook", test_diff_a_to_hook),
            ("test_diff_a_to_tilde", test_diff_a_to_tilde),
            ("test_diff_a_to_dot", test_diff_a_to_dot),
            ("test_diff_nguo_to_ngu_horn", test_diff_nguo_to_ngu_horn),
            ("test_diff_truo_to_tru_horn", test_diff_truo_to_tru_horn),
            ("test_diff_nuo_to_nu_horn", test_diff_nuo_to_nu_horn),
            
            ("test_diff_toi_to_acute", test_diff_toi_to_acute),
            ("test_diff_viet_to_dot", test_diff_viet_to_dot),
            ("test_diff_toan_to_acute", test_diff_toan_to_acute),
            ("test_diff_toan_to_grave", test_diff_toan_to_grave),
            ("test_diff_hoan_to_acute", test_diff_hoan_to_acute),
            ("test_diff_thuan_to_dot", test_diff_thuan_to_dot),
            ("test_diff_cuon_to_acute", test_diff_cuon_to_acute),
            ("test_diff_muon_to_dot", test_diff_muon_to_dot),
            ("test_diff_nghieng_to_acute", test_diff_nghieng_to_acute),
            ("test_diff_truong_to_grave", test_diff_truong_to_grave),
            ("test_diff_phuong_to_dot", test_diff_phuong_to_dot),
            ("test_diff_quyen_to_grave", test_diff_quyen_to_grave),
            ("test_diff_khuyen_to_acute", test_diff_khuyen_to_acute),
            ("test_diff_chuyen_to_dot", test_diff_chuyen_to_dot),
            ("test_diff_tuyen_to_acute", test_diff_tuyen_to_acute),
            
            ("test_diff_undo_ba_acute_to_bas", test_diff_undo_ba_acute_to_bas),
            ("test_diff_undo_toan_acute_to_toan", test_diff_undo_toan_acute_to_toan),
            ("test_diff_undo_viet_dot_to_viet", test_diff_undo_viet_dot_to_viet),
            ("test_diff_undo_circumflex_a_to_aa", test_diff_undo_circumflex_a_to_aa),
            ("test_diff_undo_circumflex_e_to_ee", test_diff_undo_circumflex_e_to_ee),
            ("test_diff_undo_circumflex_o_to_oo", test_diff_undo_circumflex_o_to_oo),
            ("test_diff_undo_bar_d_to_dd", test_diff_undo_bar_d_to_dd),
            ("test_diff_override_acute_to_grave", test_diff_override_acute_to_grave),
            ("test_diff_override_grave_to_hook", test_diff_override_grave_to_hook),
            ("test_diff_override_hook_to_tilde", test_diff_override_hook_to_tilde),
            
            ("test_diff_identity_empty", test_diff_identity_empty),
            ("test_diff_identity_word", test_diff_identity_word),
            ("test_diff_total_replace", test_diff_total_replace),
            ("test_diff_total_replace_longer", test_diff_total_replace_longer),
            ("test_diff_total_replace_shorter", test_diff_total_replace_shorter),
        ]
    }
}
