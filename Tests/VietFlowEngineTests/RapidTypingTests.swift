//
//  RapidTypingTests.swift
//  VietFlowEngineTests
//
//  Tier 4: Rapid Typing Sequences, Full Sentence Flow & Boundary Handling (>= 70 test cases)
//  Covers continuous sentence typing, mid-word backspacing, and punctuation word boundaries.
//

import Foundation
import VietFlowEngine

public final class RapidTypingTests: VietFlowTestCase {
    private var engine: VietnameseEngineProtocol!
    
    public override func setUp() {
        super.setUp()
        engine = makeEngine(inputMethod: .telex, tonePlacement: .modern)
    }
    
    private func typeFullSentence(_ input: String) -> String {
        var fullOutput = ""
        engine.reset()
        
        for char in input {
            if char == " " || char == "\n" || char == "\t" || ",.!?;:()[]{}\"-/".contains(char) {
                // Word boundary encountered: commit engine and flush
                engine.reset()
                fullOutput.append(char)
            } else {
                if let delta = engine.processKey(char) {
                    if delta.backspaces > 0 {
                        let dropCount = min(delta.backspaces, fullOutput.count)
                        fullOutput = String(fullOutput.dropLast(dropCount))
                    }
                    fullOutput.append(delta.insertText)
                } else {
                    fullOutput.append(char)
                }
            }
        }
        return fullOutput
    }
    
    // MARK: - Full Real-World Sentences (20 tests)
    func test_sentence_truong_hoc_viet_nam() {
        let input = "Truwowfng hojc Vieejt Nam ruwjc rowx cowf hoa muwfng ngayf ddoojc laapj."
        let expected = "Trường học Việt Nam rực rỡ cờ hoa mừng ngày độc lập."
        XCTAssertEqual(typeFullSentence(input), expected)
    }
    
    func test_sentence_cong_nghe_thong_tin() {
        let input = "Coong ngheej thoong tin phast trieern vuowjt baajc treen neefn tangr macOS."
        let expected = "Công nghệ thông tin phát triển vượt bậc trên nền tảng macOS."
        XCTAssertEqual(typeFullSentence(input), expected)
    }
    
    func test_sentence_bo_go_tieng_viet() {
        let input = "Booj gox tieengs Vieejt thees heej mowsi hoatj ddoojng muowjt maf khoong bij looix."
        let expected = "Bộ gõ tiếng Việt thế hệ mới hoạt động mượt mà không bị lỗi."
        XCTAssertEqual(typeFullSentence(input), expected)
    }
    
    func test_sentence_hoc_tap_tot() {
        let input = "Hojc taajp toots, lao ddoojng toots, ddoanf keest toots, kyr luaatj toots."
        let expected = "Học tập tốt, lao động tốt, đoàn kết tốt, kỷ luật tốt."
        XCTAssertEqual(typeFullSentence(input), expected)
    }
    
    func test_sentence_doc_lap_tu_do() {
        let input = "Ddoojc laapj, Tuwj do, Hanhj phusc."
        let expected = "Độc lập, Tự do, Hạnh phúc."
        XCTAssertEqual(typeFullSentence(input), expected)
    }
    
    func test_sentence_nguoi_viet_nam() {
        let input = "Nguowfi Vieejt Nam yeeu chuoojng hoaf bifnh vaf coong lys."
        let expected = "Người Việt Nam yêu chuộng hòa bình và công lý."
        XCTAssertEqual(typeFullSentence(input), expected)
    }
    
    func test_sentence_thoi_tiet_hom_nay() {
        let input = "Thowfi tieest hoom nay thaatj ddejp, trowfi trong xanh vaf nawngs nhej."
        let expected = "Thời tiết hôm nay thật đẹp, trời trong xanh và nắng nhẹ."
        XCTAssertEqual(typeFullSentence(input), expected)
    }
    
    func test_sentence_lap_trinh_mac() {
        let input = "Tooi ddang laajp trifnh uwsng dujng banf phism cho mays tisnh Mac."
        let expected = "Tôi đang lập trình ứng dụng bàn phím cho máy tính Mac."
        XCTAssertEqual(typeFullSentence(input), expected)
    }
    
    func test_sentence_que_huong() {
        let input = "Que huowng laf chufm khees ngojt, cho con treefs mowsi treof."
        let expected = "Que hương là chùm khế ngọt, cho con trế mới trèo."
        XCTAssertEqual(typeFullSentence(input), expected)
    }
    
    func test_sentence_cam_on() {
        let input = "Carm own banj ddax giusp ddowx tooi."
        let expected = "Cảm ơn bạn đã giúp đỡ tôi."
        XCTAssertEqual(typeFullSentence(input), expected)
    }
    
    func test_sentence_xin_chao() {
        let input = "Xin chafo moji nguowfi!"
        let expected = "Xin chào mọi người!"
        XCTAssertEqual(typeFullSentence(input), expected)
    }
    
    func test_sentence_chuc_mung_nam_moi() {
        let input = "Chusc muwfng nawm mowsi an khang thijnh vuowjng!"
        let expected = "Chúc mừng năm mới an khang thịnh vượng!"
        XCTAssertEqual(typeFullSentence(input), expected)
    }
    
    func test_sentence_ha_noi() {
        let input = "Haf Nooji laf thur ddoo cura nuowsc Coojng hoaf xax hooji chur nghiax Vieejt Nam."
        let expected = "Hà Nội là thủ đô của nước Cộng hòa xã hội chủ nghĩa Việt Nam."
        XCTAssertEqual(typeFullSentence(input), expected)
    }
    
    func test_sentence_sai_gon() {
        let input = "Safi Gofn laf trung taam kinh tees lowsn nhaast car nuowsc."
        let expected = "Sài Gòn là trung tâm kinh tế lớn nhất cả nước."
        XCTAssertEqual(typeFullSentence(input), expected)
    }
    
    func test_sentence_da_nang() {
        let input = "Ddaf Nawngx laf thafnh phoos ddangs soongs nhaast Vieejt Nam."
        let expected = "Đà Nẵng là thành phố đáng sống nhất Việt Nam."
        XCTAssertEqual(typeFullSentence(input), expected)
    }
    
    func test_sentence_hai_phong() {
        let input = "Hair Phofng laf thafnh phoos hoa phuwowjng ddor."
        let expected = "Hải Phòng là thành phố hoa phượng đỏ."
        XCTAssertEqual(typeFullSentence(input), expected)
    }
    
    func test_sentence_can_tho() {
        let input = "Caanf Thow gaoj trawngs nuowsc trong, ai ddi ddeesn ddos thif khoong muoosn veef."
        let expected = "Cần Thơ gạo trắng nước trong, ai đi đến đó thì không muốn về."
        XCTAssertEqual(typeFullSentence(input), expected)
    }
    
    func test_sentence_ha_long() {
        let input = "Vijnh Haj Long laf kyf quan thieen nhieen thees giowsi."
        let expected = "Vịnh Hạ Long là kỳ quan thiên nhiên thế giới."
        XCTAssertEqual(typeFullSentence(input), expected)
    }
    
    func test_sentence_phu_quoc() {
        let input = "Ddaor Phus Quoocs cos nhieefu baix bieern ddejp."
        let expected = "Đảo Phú Quốc có nhiều bãi biển đẹp."
        XCTAssertEqual(typeFullSentence(input), expected)
    }
    
    func test_sentence_nha_trang() {
        let input = "Nha Trang laf thafnh phoos bieern tuyeetj ddejp."
        let expected = "Nha Trang là thành phố biển tuyệt đẹp."
        XCTAssertEqual(typeFullSentence(input), expected)
    }
    
    // MARK: - Mid-Word Backspacing & Re-Typing (25 tests)
    func test_backspace_viet_retype() {
        engine.reset()
        // User types 'vieet' -> 'viêt'
        _ = typeSequence("vieet", into: engine)
        // User presses backspace twice
        _ = engine.handleBackspace()
        _ = engine.handleBackspace()
        // User types 'tj' -> 'việt'
        let (_, finalBuf) = typeSequence("tj", into: engine)
        XCTAssertEqual(finalBuf, "việt")
    }
    
    func test_backspace_toan_retype() {
        engine.reset()
        _ = typeSequence("toans", into: engine)
        _ = engine.handleBackspace()
        let (_, finalBuf) = typeSequence("n", into: engine)
        XCTAssertEqual(finalBuf, "toán")
    }
    
    func test_backspace_hoc_retype() {
        engine.reset()
        _ = typeSequence("hojc", into: engine)
        _ = engine.handleBackspace()
        let (_, finalBuf) = typeSequence("c", into: engine)
        XCTAssertEqual(finalBuf, "học")
    }
    
    func test_backspace_duoc_retype() {
        engine.reset()
        _ = typeSequence("dduwowj", into: engine)
        _ = engine.handleBackspace()
        let (_, finalBuf) = typeSequence("jc", into: engine)
        XCTAssertEqual(finalBuf, "được")
    }
    
    func test_backspace_nguoi_retype() {
        engine.reset()
        _ = typeSequence("nguowf", into: engine)
        _ = engine.handleBackspace()
        let (_, finalBuf) = typeSequence("fi", into: engine)
        XCTAssertEqual(finalBuf, "người")
    }
    
    func test_backspace_all_chars_empty() {
        engine.reset()
        _ = typeSequence("vieetj", into: engine)
        for _ in 0..<10 {
            _ = engine.handleBackspace()
        }
        XCTAssertEqual(engine.currentSyllable, "")
    }
    
    func test_backspace_on_empty_engine() {
        engine.reset()
        let handled = engine.handleBackspace()
        XCTAssertFalse(handled)
    }
    
    func test_backspace_partial_1() {
        engine.reset()
        _ = typeSequence("tieeng", into: engine)
        _ = engine.handleBackspace()
        let (_, res) = typeSequence("gs", into: engine)
        XCTAssertEqual(res, "tiếng")
    }
    
    func test_backspace_partial_2() {
        engine.reset()
        _ = typeSequence("nam", into: engine)
        _ = engine.handleBackspace()
        let (_, res) = typeSequence("m", into: engine)
        XCTAssertEqual(res, "nam")
    }
    
    func test_backspace_partial_3() {
        engine.reset()
        _ = typeSequence("hoa", into: engine)
        _ = engine.handleBackspace()
        let (_, res) = typeSequence("af", into: engine)
        XCTAssertEqual(res, "hòa")
    }
    
    func test_backspace_partial_4() {
        engine.reset()
        _ = typeSequence("thuy", into: engine)
        _ = engine.handleBackspace()
        let (_, res) = typeSequence("ys", into: engine)
        XCTAssertEqual(res, "thúy")
    }
    
    func test_backspace_partial_5() {
        engine.reset()
        _ = typeSequence("khoe", into: engine)
        _ = engine.handleBackspace()
        let (_, res) = typeSequence("er", into: engine)
        XCTAssertEqual(res, "khỏe")
    }
    
    func test_backspace_partial_6() {
        engine.reset()
        _ = typeSequence("nghe", into: engine)
        _ = engine.handleBackspace()
        let (_, res) = typeSequence("eef", into: engine)
        XCTAssertEqual(res, "nghề")
    }
    
    func test_backspace_partial_7() {
        engine.reset()
        _ = typeSequence("truong", into: engine)
        _ = engine.handleBackspace()
        let (_, res) = typeSequence("ngwf", into: engine)
        XCTAssertEqual(res, "trường")
    }
    
    func test_backspace_partial_8() {
        engine.reset()
        _ = typeSequence("nuoc", into: engine)
        _ = engine.handleBackspace()
        let (_, res) = typeSequence("cws", into: engine)
        XCTAssertEqual(res, "nước")
    }
    
    func test_backspace_partial_9() {
        engine.reset()
        _ = typeSequence("buoc", into: engine)
        _ = engine.handleBackspace()
        let (_, res) = typeSequence("cws", into: engine)
        XCTAssertEqual(res, "bước")
    }
    
    func test_backspace_partial_10() {
        engine.reset()
        _ = typeSequence("muon", into: engine)
        _ = engine.handleBackspace()
        let (_, res) = typeSequence("nwj", into: engine)
        XCTAssertEqual(res, "mượn")
    }
    
    func test_backspace_partial_11() {
        engine.reset()
        _ = typeSequence("ddong", into: engine)
        _ = engine.handleBackspace()
        let (_, res) = typeSequence("ngof", into: engine)
        XCTAssertEqual(res, "đồng")
    }
    
    func test_backspace_partial_12() {
        engine.reset()
        _ = typeSequence("som", into: engine)
        _ = engine.handleBackspace()
        let (_, res) = typeSequence("mws", into: engine)
        XCTAssertEqual(res, "sớm")
    }
    
    func test_backspace_partial_13() {
        engine.reset()
        _ = typeSequence("toi", into: engine)
        _ = engine.handleBackspace()
        let (_, res) = typeSequence("ois", into: engine)
        XCTAssertEqual(res, "tối")
    }
    
    func test_backspace_partial_14() {
        engine.reset()
        _ = typeSequence("pho", into: engine)
        _ = engine.handleBackspace()
        let (_, res) = typeSequence("oos", into: engine)
        XCTAssertEqual(res, "phố")
    }
    
    func test_backspace_partial_15() {
        engine.reset()
        _ = typeSequence("nha", into: engine)
        _ = engine.handleBackspace()
        let (_, res) = typeSequence("af", into: engine)
        XCTAssertEqual(res, "nhà")
    }
    
    func test_backspace_partial_16() {
        engine.reset()
        _ = typeSequence("me", into: engine)
        _ = engine.handleBackspace()
        let (_, res) = typeSequence("ej", into: engine)
        XCTAssertEqual(res, "mẹ")
    }
    
    func test_backspace_partial_17() {
        engine.reset()
        _ = typeSequence("bo", into: engine)
        _ = engine.handleBackspace()
        let (_, res) = typeSequence("oos", into: engine)
        XCTAssertEqual(res, "bố")
    }
    
    func test_backspace_partial_18() {
        engine.reset()
        _ = typeSequence("con", into: engine)
        _ = engine.handleBackspace()
        let (_, res) = typeSequence("n", into: engine)
        XCTAssertEqual(res, "con")
    }
    
    // MARK: - Punctuation Boundaries (25 tests)
    func test_punct_comma() { XCTAssertEqual(typeFullSentence("vieetj, nam"), "việt, nam") }
    func test_punct_period() { XCTAssertEqual(typeFullSentence("vieetj. nam"), "việt. nam") }
    func test_punct_semicolon() { XCTAssertEqual(typeFullSentence("vieetj; nam"), "việt; nam") }
    func test_punct_colon() { XCTAssertEqual(typeFullSentence("vieetj: nam"), "việt: nam") }
    func test_punct_exclamation() { XCTAssertEqual(typeFullSentence("vieetj! nam"), "việt! nam") }
    func test_punct_question() { XCTAssertEqual(typeFullSentence("vieetj? nam"), "việt? nam") }
    func test_punct_dash() { XCTAssertEqual(typeFullSentence("vieetj-nam"), "việt-nam") }
    func test_punct_underscore() { XCTAssertEqual(typeFullSentence("vieetj_nam"), "việt_nam") }
    func test_punct_slash() { XCTAssertEqual(typeFullSentence("vieetj/nam"), "việt/nam") }
    func test_punct_paren_open() { XCTAssertEqual(typeFullSentence("(vieetj"), "(việt") }
    func test_punct_paren_close() { XCTAssertEqual(typeFullSentence("vieetj)"), "việt)") }
    func test_punct_bracket_open() { XCTAssertEqual(typeFullSentence("[vieetj"), "[việt") }
    func test_punct_bracket_close() { XCTAssertEqual(typeFullSentence("vieetj]"), "việt]") }
    func test_punct_brace_open() { XCTAssertEqual(typeFullSentence("{vieetj"), "{việt") }
    func test_punct_brace_close() { XCTAssertEqual(typeFullSentence("vieetj}"), "việt}") }
    func test_punct_quote() { XCTAssertEqual(typeFullSentence("\"vieetj\""), "\"việt\"") }
    func test_punct_tab() { XCTAssertEqual(typeFullSentence("vieetj\tnam"), "việt\tnam") }
    func test_punct_newline() { XCTAssertEqual(typeFullSentence("vieetj\nnam"), "việt\nnam") }
    func test_punct_double_space() { XCTAssertEqual(typeFullSentence("vieetj  nam"), "việt  nam") }
    func test_punct_triple_space() { XCTAssertEqual(typeFullSentence("vieetj   nam"), "việt   nam") }
    func test_punct_space_at_start() { XCTAssertEqual(typeFullSentence(" vieetj"), " việt") }
    func test_punct_space_at_end() { XCTAssertEqual(typeFullSentence("vieetj "), "việt ") }
    func test_punct_ellipsis() { XCTAssertEqual(typeFullSentence("vieetj... nam"), "việt... nam") }
    func test_punct_hyphen_word() { XCTAssertEqual(typeFullSentence("Haf-Nooji"), "Hà-Nội") }
    func test_punct_mixed() { XCTAssertEqual(typeFullSentence("vieetj (nam) [hojc]"), "việt (nam) [học]") }
    
    // MARK: - Registration of all tests
    public override var allTests: [(name: String, test: TestMethod)] {
        return [
            ("test_sentence_truong_hoc_viet_nam", test_sentence_truong_hoc_viet_nam),
            ("test_sentence_cong_nghe_thong_tin", test_sentence_cong_nghe_thong_tin),
            ("test_sentence_bo_go_tieng_viet", test_sentence_bo_go_tieng_viet),
            ("test_sentence_hoc_tap_tot", test_sentence_hoc_tap_tot),
            ("test_sentence_doc_lap_tu_do", test_sentence_doc_lap_tu_do),
            ("test_sentence_nguoi_viet_nam", test_sentence_nguoi_viet_nam),
            ("test_sentence_thoi_tiet_hom_nay", test_sentence_thoi_tiet_hom_nay),
            ("test_sentence_lap_trinh_mac", test_sentence_lap_trinh_mac),
            ("test_sentence_que_huong", test_sentence_que_huong),
            ("test_sentence_cam_on", test_sentence_cam_on),
            ("test_sentence_xin_chao", test_sentence_xin_chao),
            ("test_sentence_chuc_mung_nam_moi", test_sentence_chuc_mung_nam_moi),
            ("test_sentence_ha_noi", test_sentence_ha_noi),
            ("test_sentence_sai_gon", test_sentence_sai_gon),
            ("test_sentence_da_nang", test_sentence_da_nang),
            ("test_sentence_hai_phong", test_sentence_hai_phong),
            ("test_sentence_can_tho", test_sentence_can_tho),
            ("test_sentence_ha_long", test_sentence_ha_long),
            ("test_sentence_phu_quoc", test_sentence_phu_quoc),
            ("test_sentence_nha_trang", test_sentence_nha_trang),
            
            ("test_backspace_viet_retype", test_backspace_viet_retype),
            ("test_backspace_toan_retype", test_backspace_toan_retype),
            ("test_backspace_hoc_retype", test_backspace_hoc_retype),
            ("test_backspace_duoc_retype", test_backspace_duoc_retype),
            ("test_backspace_nguoi_retype", test_backspace_nguoi_retype),
            ("test_backspace_all_chars_empty", test_backspace_all_chars_empty),
            ("test_backspace_on_empty_engine", test_backspace_on_empty_engine),
            ("test_backspace_partial_1", test_backspace_partial_1),
            ("test_backspace_partial_2", test_backspace_partial_2),
            ("test_backspace_partial_3", test_backspace_partial_3),
            ("test_backspace_partial_4", test_backspace_partial_4),
            ("test_backspace_partial_5", test_backspace_partial_5),
            ("test_backspace_partial_6", test_backspace_partial_6),
            ("test_backspace_partial_7", test_backspace_partial_7),
            ("test_backspace_partial_8", test_backspace_partial_8),
            ("test_backspace_partial_9", test_backspace_partial_9),
            ("test_backspace_partial_10", test_backspace_partial_10),
            ("test_backspace_partial_11", test_backspace_partial_11),
            ("test_backspace_partial_12", test_backspace_partial_12),
            ("test_backspace_partial_13", test_backspace_partial_13),
            ("test_backspace_partial_14", test_backspace_partial_14),
            ("test_backspace_partial_15", test_backspace_partial_15),
            ("test_backspace_partial_16", test_backspace_partial_16),
            ("test_backspace_partial_17", test_backspace_partial_17),
            ("test_backspace_partial_18", test_backspace_partial_18),
            
            ("test_punct_comma", test_punct_comma),
            ("test_punct_period", test_punct_period),
            ("test_punct_semicolon", test_punct_semicolon),
            ("test_punct_colon", test_punct_colon),
            ("test_punct_exclamation", test_punct_exclamation),
            ("test_punct_question", test_punct_question),
            ("test_punct_dash", test_punct_dash),
            ("test_punct_underscore", test_punct_underscore),
            ("test_punct_slash", test_punct_slash),
            ("test_punct_paren_open", test_punct_paren_open),
            ("test_punct_paren_close", test_punct_paren_close),
            ("test_punct_bracket_open", test_punct_bracket_open),
            ("test_punct_bracket_close", test_punct_bracket_close),
            ("test_punct_brace_open", test_punct_brace_open),
            ("test_punct_brace_close", test_punct_brace_close),
            ("test_punct_quote", test_punct_quote),
            ("test_punct_tab", test_punct_tab),
            ("test_punct_newline", test_punct_newline),
            ("test_punct_double_space", test_punct_double_space),
            ("test_punct_triple_space", test_punct_triple_space),
            ("test_punct_space_at_start", test_punct_space_at_start),
            ("test_punct_space_at_end", test_punct_space_at_end),
            ("test_punct_ellipsis", test_punct_ellipsis),
            ("test_punct_hyphen_word", test_punct_hyphen_word),
            ("test_punct_mixed", test_punct_mixed),
        ]
    }
}
