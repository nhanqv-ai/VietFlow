//
//  EnglishRestoreTests.swift
//  VietFlowEngineTests
//
//  Tier 4: English Word Auto-Restoration, CVC Spellchecking & English Bypass Suite (>= 80 test cases)
//  Covers developer keywords, illegal stop-coda tones, invalid consonant clusters, and bypass latching.
//

import Foundation
import VietFlowEngine

public final class EnglishRestoreTests: VietFlowTestCase {
    private var engine: VietnameseEngineProtocol!
    
    public override func setUp() {
        super.setUp()
        engine = makeEngine(inputMethod: .telex, tonePlacement: .modern, autoCorrectEnglish: true)
    }
    
    private func assertRestore(_ input: String, _ expected: String, file: StaticString = #file, line: UInt = #line) {
        engine.reset()
        let (_, output) = typeSequence(input, into: engine)
        XCTAssertEqual(output, expected, "Failed English restore for: '\(input)'", file: file, line: line)
    }
    
    // MARK: - Common Developer Keywords (40 tests)
    func test_english_restore_code() { assertRestore("code", "code") }
    func test_english_restore_post() { assertRestore("post", "post") }
    func test_english_restore_view() { assertRestore("view", "view") }
    func test_english_restore_format() { assertRestore("format", "format") }
    func test_english_restore_string() { assertRestore("string", "string") }
    func test_english_restore_struct() { assertRestore("struct", "struct") }
    func test_english_restore_print() { assertRestore("print", "print") }
    func test_english_restore_while() { assertRestore("while", "while") }
    func test_english_restore_class() { assertRestore("class", "class") }
    func test_english_restore_filter() { assertRestore("filter", "filter") }
    func test_english_restore_clear() { assertRestore("clear", "clear") }
    func test_english_restore_create() { assertRestore("create", "create") }
    func test_english_restore_system() { assertRestore("system", "system") }
    func test_english_restore_window() { assertRestore("window", "window") }
    func test_english_restore_document() { assertRestore("document", "document") }
    func test_english_restore_switch() { assertRestore("switch", "switch") }
    func test_english_restore_break() { assertRestore("break", "break") }
    func test_english_restore_return() { assertRestore("return", "return") }
    func test_english_restore_import() { assertRestore("import", "import") }
    func test_english_restore_export() { assertRestore("export", "export") }
    func test_english_restore_false() { assertRestore("false", "false") }
    func test_english_restore_true() { assertRestore("true", "true") }
    func test_english_restore_commit() { assertRestore("commit", "commit") }
    func test_english_restore_branch() { assertRestore("branch", "branch") }
    func test_english_restore_merge() { assertRestore("merge", "merge") }
    func test_english_restore_push() { assertRestore("push", "push") }
    func test_english_restore_pull() { assertRestore("pull", "pull") }
    func test_english_restore_fetch() { assertRestore("fetch", "fetch") }
    func test_english_restore_clone() { assertRestore("clone", "clone") }
    func test_english_restore_status() { assertRestore("status", "status") }
    func test_english_restore_diff() { assertRestore("diff", "diff") }
    func test_english_restore_text() { assertRestore("text", "text") }
    func test_english_restore_test() { assertRestore("test", "test") }
    func test_english_restore_cost() { assertRestore("cost", "cost") }
    func test_english_restore_most() { assertRestore("most", "most") }
    func test_english_restore_fast() { assertRestore("fast", "fast") }
    func test_english_restore_broadcast() { assertRestore("broadcast", "broadcast") }
    func test_english_restore_terminal() { assertRestore("terminal", "terminal") }
    func test_english_restore_command() { assertRestore("command", "command") }
    func test_english_restore_buffer() { assertRestore("buffer", "buffer") }
    
    // MARK: - Illegal Stop Coda with Non-Sắc/Nặng Tones (15 tests)
    func test_illegal_stop_coda_bacf() { assertRestore("bacf", "bacf") }
    func test_illegal_stop_coda_bacr() { assertRestore("bacr", "bacr") }
    func test_illegal_stop_coda_bacx() { assertRestore("bacx", "bacx") }
    func test_illegal_stop_coda_totf() { assertRestore("totf", "totf") }
    func test_illegal_stop_coda_totr() { assertRestore("totr", "totr") }
    func test_illegal_stop_coda_totx() { assertRestore("totx", "totx") }
    func test_illegal_stop_coda_lapf() { assertRestore("lapf", "lapf") }
    func test_illegal_stop_coda_lapr() { assertRestore("lapr", "lapr") }
    func test_illegal_stop_coda_lapx() { assertRestore("lapx", "lapx") }
    func test_illegal_stop_coda_thichf() { assertRestore("thichf", "thichf") }
    func test_illegal_stop_coda_thichr() { assertRestore("thichr", "thichr") }
    func test_illegal_stop_coda_thichx() { assertRestore("thichx", "thichx") }
    func test_illegal_stop_coda_hopf() { assertRestore("hopf", "hopf") }
    func test_illegal_stop_coda_hopr() { assertRestore("hopr", "hopr") }
    func test_illegal_stop_coda_hopx() { assertRestore("hopx", "hopx") }
    
    // MARK: - Illegal Consonant Clusters (15 tests)
    func test_illegal_cluster_brand() { assertRestore("brand", "brand") }
    func test_illegal_cluster_crack() { assertRestore("crack", "crack") }
    func test_illegal_cluster_drop() { assertRestore("drop", "drop") }
    func test_illegal_cluster_fresh() { assertRestore("fresh", "fresh") }
    func test_illegal_cluster_grand() { assertRestore("grand", "grand") }
    func test_illegal_cluster_press() { assertRestore("press", "press") }
    func test_illegal_cluster_scale() { assertRestore("scale", "scale") }
    func test_illegal_cluster_skill() { assertRestore("skill", "skill") }
    func test_illegal_cluster_sleep() { assertRestore("sleep", "sleep") }
    func test_illegal_cluster_smart() { assertRestore("smart", "smart") }
    func test_illegal_cluster_snake() { assertRestore("snake", "snake") }
    func test_illegal_cluster_space() { assertRestore("space", "space") }
    func test_illegal_cluster_stand() { assertRestore("stand", "stand") }
    func test_illegal_cluster_swift() { assertRestore("swift", "swift") }
    func test_illegal_cluster_flash() { assertRestore("flash", "flash") }
    
    // MARK: - English Bypass Latch Persistence & Space Boundary Reset (10 tests)
    func test_bypass_latch_subsequent_keys() {
        engine.reset()
        // Typing 'code' breaks composition into bypass latch
        let (_, buffer1) = typeSequence("code", into: engine)
        XCTAssertEqual(buffer1, "code")
        // Typing 's' subsequent inside the word does not add accent!
        let (_, buffer2) = typeSequence("base", into: engine)
        XCTAssertEqual(buffer2, "codebase")
    }
    
    func test_bypass_latch_reset_on_space() {
        engine.reset()
        // English word 'code' followed by space
        let (_, b1) = typeSequence("code ", into: engine)
        XCTAssertEqual(b1, "code ")
        // New syllable after space should be processed normally
        let (_, b2) = typeSequence("vieetj", into: engine)
        XCTAssertEqual(b2, "việt")
    }
    
    func test_bypass_latch_reset_on_newline() {
        engine.reset()
        let (_, b1) = typeSequence("post\n", into: engine)
        XCTAssertEqual(b1, "post\n")
        let (_, b2) = typeSequence("toans", into: engine)
        XCTAssertEqual(b2, "toán")
    }
    
    func test_bypass_word_apple() { assertRestore("apple", "apple") }
    func test_bypass_word_google() { assertRestore("google", "google") }
    func test_bypass_word_microsoft() { assertRestore("microsoft", "microsoft") }
    func test_bypass_word_github() { assertRestore("github", "github") }
    func test_bypass_word_docker() { assertRestore("docker", "docker") }
    func test_bypass_word_rust() { assertRestore("rust", "rust") }
    func test_bypass_word_golang() { assertRestore("golang", "golang") }
    
    // MARK: - Registration of all tests
    public override var allTests: [(name: String, test: TestMethod)] {
        return [
            ("test_english_restore_code", test_english_restore_code),
            ("test_english_restore_post", test_english_restore_post),
            ("test_english_restore_view", test_english_restore_view),
            ("test_english_restore_format", test_english_restore_format),
            ("test_english_restore_string", test_english_restore_string),
            ("test_english_restore_struct", test_english_restore_struct),
            ("test_english_restore_print", test_english_restore_print),
            ("test_english_restore_while", test_english_restore_while),
            ("test_english_restore_class", test_english_restore_class),
            ("test_english_restore_filter", test_english_restore_filter),
            ("test_english_restore_clear", test_english_restore_clear),
            ("test_english_restore_create", test_english_restore_create),
            ("test_english_restore_system", test_english_restore_system),
            ("test_english_restore_window", test_english_restore_window),
            ("test_english_restore_document", test_english_restore_document),
            ("test_english_restore_switch", test_english_restore_switch),
            ("test_english_restore_break", test_english_restore_break),
            ("test_english_restore_return", test_english_restore_return),
            ("test_english_restore_import", test_english_restore_import),
            ("test_english_restore_export", test_english_restore_export),
            ("test_english_restore_false", test_english_restore_false),
            ("test_english_restore_true", test_english_restore_true),
            ("test_english_restore_commit", test_english_restore_commit),
            ("test_english_restore_branch", test_english_restore_branch),
            ("test_english_restore_merge", test_english_restore_merge),
            ("test_english_restore_push", test_english_restore_push),
            ("test_english_restore_pull", test_english_restore_pull),
            ("test_english_restore_fetch", test_english_restore_fetch),
            ("test_english_restore_clone", test_english_restore_clone),
            ("test_english_restore_status", test_english_restore_status),
            ("test_english_restore_diff", test_english_restore_diff),
            ("test_english_restore_text", test_english_restore_text),
            ("test_english_restore_test", test_english_restore_test),
            ("test_english_restore_cost", test_english_restore_cost),
            ("test_english_restore_most", test_english_restore_most),
            ("test_english_restore_fast", test_english_restore_fast),
            ("test_english_restore_broadcast", test_english_restore_broadcast),
            ("test_english_restore_terminal", test_english_restore_terminal),
            ("test_english_restore_command", test_english_restore_command),
            ("test_english_restore_buffer", test_english_restore_buffer),
            
            ("test_illegal_stop_coda_bacf", test_illegal_stop_coda_bacf),
            ("test_illegal_stop_coda_bacr", test_illegal_stop_coda_bacr),
            ("test_illegal_stop_coda_bacx", test_illegal_stop_coda_bacx),
            ("test_illegal_stop_coda_totf", test_illegal_stop_coda_totf),
            ("test_illegal_stop_coda_totr", test_illegal_stop_coda_totr),
            ("test_illegal_stop_coda_totx", test_illegal_stop_coda_totx),
            ("test_illegal_stop_coda_lapf", test_illegal_stop_coda_lapf),
            ("test_illegal_stop_coda_lapr", test_illegal_stop_coda_lapr),
            ("test_illegal_stop_coda_lapx", test_illegal_stop_coda_lapx),
            ("test_illegal_stop_coda_thichf", test_illegal_stop_coda_thichf),
            ("test_illegal_stop_coda_thichr", test_illegal_stop_coda_thichr),
            ("test_illegal_stop_coda_thichx", test_illegal_stop_coda_thichx),
            ("test_illegal_stop_coda_hopf", test_illegal_stop_coda_hopf),
            ("test_illegal_stop_coda_hopr", test_illegal_stop_coda_hopr),
            ("test_illegal_stop_coda_hopx", test_illegal_stop_coda_hopx),
            
            ("test_illegal_cluster_brand", test_illegal_cluster_brand),
            ("test_illegal_cluster_crack", test_illegal_cluster_crack),
            ("test_illegal_cluster_drop", test_illegal_cluster_drop),
            ("test_illegal_cluster_fresh", test_illegal_cluster_fresh),
            ("test_illegal_cluster_grand", test_illegal_cluster_grand),
            ("test_illegal_cluster_press", test_illegal_cluster_press),
            ("test_illegal_cluster_scale", test_illegal_cluster_scale),
            ("test_illegal_cluster_skill", test_illegal_cluster_skill),
            ("test_illegal_cluster_sleep", test_illegal_cluster_sleep),
            ("test_illegal_cluster_smart", test_illegal_cluster_smart),
            ("test_illegal_cluster_snake", test_illegal_cluster_snake),
            ("test_illegal_cluster_space", test_illegal_cluster_space),
            ("test_illegal_cluster_stand", test_illegal_cluster_stand),
            ("test_illegal_cluster_swift", test_illegal_cluster_swift),
            ("test_illegal_cluster_flash", test_illegal_cluster_flash),
            
            ("test_bypass_latch_subsequent_keys", test_bypass_latch_subsequent_keys),
            ("test_bypass_latch_reset_on_space", test_bypass_latch_reset_on_space),
            ("test_bypass_latch_reset_on_newline", test_bypass_latch_reset_on_newline),
            ("test_bypass_word_apple", test_bypass_word_apple),
            ("test_bypass_word_google", test_bypass_word_google),
            ("test_bypass_word_microsoft", test_bypass_word_microsoft),
            ("test_bypass_word_github", test_bypass_word_github),
            ("test_bypass_word_docker", test_bypass_word_docker),
            ("test_bypass_word_rust", test_bypass_word_rust),
            ("test_bypass_word_golang", test_bypass_word_golang),
        ]
    }
}
