//
//  TerminalCompatibilityTests.swift
//  VietFlowTerminalBufferTests
//
//  Terminal Raw-Mode PTY Buffer Compatibility Suite (>= 80 test cases)
//  Verifies that every keystroke sequence (backspaces + replacement text)
//  precisely transforms the buffer without missing or surplus characters.
//

import Foundation
import VietFlowEngine
import VietFlowEngineTests

public final class TerminalCompatibilityTests: VietFlowTestCase {
    private var simulator: TerminalBufferSimulator!
    private var telexEngine: VietnameseEngineProtocol!
    private var vniEngine: VietnameseEngineProtocol!
    
    public override func setUp() {
        super.setUp()
        simulator = TerminalBufferSimulator()
        telexEngine = makeEngine(inputMethod: .telex, tonePlacement: .modern, autoCorrectEnglish: true)
        vniEngine = makeEngine(inputMethod: .vni, tonePlacement: .modern)
    }
    
    private func assertTerminalSequence(
        input: String,
        expected: String,
        engine: VietnameseEngineProtocol,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        simulator.reset()
        engine.reset()
        
        let events = simulator.typeString(input, engine: engine)
        
        // Invariant 1: No step failed (no underrun)
        for (idx, event) in events.enumerated() {
            XCTAssertTrue(event.isSuccess, "Step \(idx) ('\(event.keyTyped)') caused terminal buffer underrun!", file: file, line: line)
        }
        
        // Invariant 2: Buffer precisely matches expected string
        XCTAssertEqual(simulator.currentBuffer, expected, "Terminal buffer mismatch for '\(input)'", file: file, line: line)
        
        // Invariant 3: Zero surplus characters
        XCTAssertEqual(simulator.currentBuffer.count, expected.count, "Surplus/missing characters in terminal buffer!", file: file, line: line)
    }
    
    // MARK: - Basic Telex in Terminal (20 tests)
    func test_term_telex_viet() { assertTerminalSequence(input: "vieetj", expected: "việt", engine: telexEngine) }
    func test_term_telex_nam() { assertTerminalSequence(input: "nam", expected: "nam", engine: telexEngine) }
    func test_term_telex_toan() { assertTerminalSequence(input: "toans", expected: "toán", engine: telexEngine) }
    func test_term_telex_tieng() { assertTerminalSequence(input: "tieengs", expected: "tiếng", engine: telexEngine) }
    func test_term_telex_hoc() { assertTerminalSequence(input: "hojc", expected: "học", engine: telexEngine) }
    func test_term_telex_dat() { assertTerminalSequence(input: "ddaats", expected: "đất", engine: telexEngine) }
    func test_term_telex_duoc() { assertTerminalSequence(input: "dduwowjc", expected: "được", engine: telexEngine) }
    func test_term_telex_nguoi() { assertTerminalSequence(input: "nguowfi", expected: "người", engine: telexEngine) }
    func test_term_telex_truong() { assertTerminalSequence(input: "truwowfng", expected: "trường", engine: telexEngine) }
    func test_term_telex_nuoc() { assertTerminalSequence(input: "nuowcs", expected: "nước", engine: telexEngine) }
    func test_term_telex_buoc() { assertTerminalSequence(input: "buwowsc", expected: "bước", engine: telexEngine) }
    func test_term_telex_muon() { assertTerminalSequence(input: "muwownj", expected: "mượn", engine: telexEngine) }
    func test_term_telex_dong() { assertTerminalSequence(input: "ddoofng", expected: "đồng", engine: telexEngine) }
    func test_term_telex_som() { assertTerminalSequence(input: "sowms", expected: "sớm", engine: telexEngine) }
    func test_term_telex_toi() { assertTerminalSequence(input: "toois", expected: "tối", engine: telexEngine) }
    func test_term_telex_pho() { assertTerminalSequence(input: "phoos", expected: "phố", engine: telexEngine) }
    func test_term_telex_nha() { assertTerminalSequence(input: "nhaf", expected: "nhà", engine: telexEngine) }
    func test_term_telex_me() { assertTerminalSequence(input: "mej", expected: "mẹ", engine: telexEngine) }
    func test_term_telex_bo() { assertTerminalSequence(input: "boos", expected: "bố", engine: telexEngine) }
    func test_term_telex_con() { assertTerminalSequence(input: "con", expected: "con", engine: telexEngine) }
    
    // MARK: - VNI in Terminal (15 tests)
    func test_term_vni_viet() { assertTerminalSequence(input: "vie65t", expected: "việt", engine: vniEngine) }
    func test_term_vni_toan() { assertTerminalSequence(input: "toan1", expected: "toán", engine: vniEngine) }
    func test_term_vni_tieng() { assertTerminalSequence(input: "tie6ng1", expected: "tiếng", engine: vniEngine) }
    func test_term_vni_hoc() { assertTerminalSequence(input: "ho5c", expected: "học", engine: vniEngine) }
    func test_term_vni_duoc() { assertTerminalSequence(input: "d9u7o75c", expected: "được", engine: vniEngine) }
    func test_term_vni_nguoi() { assertTerminalSequence(input: "ngu7o7i2", expected: "người", engine: vniEngine) }
    func test_term_vni_truong() { assertTerminalSequence(input: "tru7o7ng2", expected: "trường", engine: vniEngine) }
    func test_term_vni_nuoc() { assertTerminalSequence(input: "nu7o71c", expected: "nước", engine: vniEngine) }
    func test_term_vni_dong() { assertTerminalSequence(input: "d9o62ng", expected: "đồng", engine: vniEngine) }
    func test_term_vni_nha() { assertTerminalSequence(input: "nha2", expected: "nhà", engine: vniEngine) }
    func test_term_vni_me() { assertTerminalSequence(input: "me5", expected: "mẹ", engine: vniEngine) }
    func test_term_vni_pho() { assertTerminalSequence(input: "pho61", expected: "phố", engine: vniEngine) }
    func test_term_vni_so() { assertTerminalSequence(input: "so71", expected: "sớ", engine: vniEngine) }
    func test_term_vni_chuc() { assertTerminalSequence(input: "chu1c", expected: "chúc", engine: vniEngine) }
    func test_term_vni_mung() { assertTerminalSequence(input: "mu72ng", expected: "mừng", engine: vniEngine) }
    
    // MARK: - Shell Commands with Vietnamese Text (15 tests)
    func test_term_cmd_git_commit_1() {
        assertTerminalSequence(
            input: "git commit -m \"theem tisnh nawng mowsi\"",
            expected: "git commit -m \"thêm tính năng mới\"",
            engine: telexEngine
        )
    }
    
    func test_term_cmd_git_commit_2() {
        assertTerminalSequence(
            input: "git commit -m \"suwra looix\"",
            expected: "git commit -m \"sửa lỗi\"",
            engine: telexEngine
        )
    }
    
    func test_term_cmd_echo_hello() {
        assertTerminalSequence(
            input: "echo \"Xin chafo Vieejt Nam\"",
            expected: "echo \"Xin chào Việt Nam\"",
            engine: telexEngine
        )
    }
    
    func test_term_cmd_mkdir_folder() {
        assertTerminalSequence(
            input: "mkdir thuw_mucj",
            expected: "mkdir thư_mục",
            engine: telexEngine
        )
    }
    
    func test_term_cmd_touch_report() {
        assertTerminalSequence(
            input: "touch baos_caos.txt",
            expected: "touch báo_cáo.txt",
            engine: telexEngine
        )
    }
    
    func test_term_cmd_vim_file() {
        assertTerminalSequence(
            input: "vim teejp_tin.swift",
            expected: "vim tệp_tin.swift",
            engine: telexEngine
        )
    }
    
    func test_term_cmd_git_branch() {
        assertTerminalSequence(
            input: "git checkout -b tisnh_nawng_mowsi",
            expected: "git checkout -b tính_năng_mới",
            engine: telexEngine
        )
    }
    
    func test_term_cmd_grep() {
        assertTerminalSequence(
            input: "grep \"tieengs Vieejt\" file.txt",
            expected: "grep \"tiếng Việt\" file.txt",
            engine: telexEngine
        )
    }
    
    func test_term_cmd_cat() {
        assertTerminalSequence(
            input: "cat max_nguoonf.py",
            expected: "cat mã_nguồn.py",
            engine: telexEngine
        )
    }
    
    func test_term_cmd_nano() {
        assertTerminalSequence(
            input: "nano huwowngs_daanx.md",
            expected: "nano hướng_dẫn.md",
            engine: telexEngine
        )
    }
    
    func test_term_cmd_curl() {
        assertTerminalSequence(
            input: "curl -X POST https://api.vn/duwx_lieeju",
            expected: "curl -X POST https://api.vn/dữ_liệu",
            engine: telexEngine
        )
    }
    
    func test_term_cmd_find() {
        assertTerminalSequence(
            input: "find . -name \"*tafi_lieeju*\"",
            expected: "find . -name \"*tài_liệu*\"",
            engine: telexEngine
        )
    }
    
    func test_term_cmd_tar() {
        assertTerminalSequence(
            input: "tar -czf luwu_truwx.tar.gz src/",
            expected: "tar -czf lưu_trữ.tar.gz src/",
            engine: telexEngine
        )
    }
    
    func test_term_cmd_ssh() {
        assertTerminalSequence(
            input: "ssh user@mays_chur.local",
            expected: "ssh user@máy_chủ.local",
            engine: telexEngine
        )
    }
    
    func test_term_cmd_make() {
        assertTerminalSequence(
            input: "make kieerm_thuwr",
            expected: "make kiểm_thử",
            engine: telexEngine
        )
    }
    
    // MARK: - Developer English Keywords in Terminal (15 tests)
    func test_term_cmd_code_dot() {
        assertTerminalSequence(input: "code .", expected: "code .", engine: telexEngine)
    }
    
    func test_term_cmd_git_status() {
        assertTerminalSequence(input: "git status", expected: "git status", engine: telexEngine)
    }
    
    func test_term_cmd_git_diff() {
        assertTerminalSequence(input: "git diff", expected: "git diff", engine: telexEngine)
    }
    
    func test_term_cmd_git_push() {
        assertTerminalSequence(input: "git push origin main", expected: "git push origin main", engine: telexEngine)
    }
    
    func test_term_cmd_git_pull() {
        assertTerminalSequence(input: "git pull", expected: "git pull", engine: telexEngine)
    }
    
    func test_term_cmd_view_file() {
        assertTerminalSequence(input: "view report.md", expected: "view report.md", engine: telexEngine)
    }
    
    func test_term_cmd_clear() {
        assertTerminalSequence(input: "clear", expected: "clear", engine: telexEngine)
    }
    
    func test_term_cmd_cargo_test() {
        assertTerminalSequence(input: "cargo test", expected: "cargo test", engine: telexEngine)
    }
    
    func test_term_cmd_swift_build() {
        assertTerminalSequence(input: "swift build", expected: "swift build", engine: telexEngine)
    }
    
    func test_term_cmd_npm_start() {
        assertTerminalSequence(input: "npm start", expected: "npm start", engine: telexEngine)
    }
    
    func test_term_cmd_docker_ps() {
        assertTerminalSequence(input: "docker ps", expected: "docker ps", engine: telexEngine)
    }
    
    func test_term_cmd_python_main() {
        assertTerminalSequence(input: "python main.py", expected: "python main.py", engine: telexEngine)
    }
    
    func test_term_cmd_cat_post() {
        assertTerminalSequence(input: "cat post.json", expected: "cat post.json", engine: telexEngine)
    }
    
    func test_term_cmd_grep_format() {
        assertTerminalSequence(input: "grep format file.c", expected: "grep format file.c", engine: telexEngine)
    }
    
    func test_term_cmd_curl_post() {
        assertTerminalSequence(input: "curl -X POST http://localhost", expected: "curl -X POST http://localhost", engine: telexEngine)
    }
    
    // MARK: - Interactive Terminal Backspacing Mid-Command (15 tests)
    func test_term_backspace_mid_commit() {
        simulator.reset()
        telexEngine.reset()
        _ = simulator.typeString("git commit -m \"vieet", engine: telexEngine)
        _ = simulator.pressBackspace(engine: telexEngine)
        _ = simulator.pressBackspace(engine: telexEngine)
        _ = simulator.typeString("tj\"", engine: telexEngine)
        XCTAssertEqual(simulator.currentBuffer, "git commit -m \"việt\"")
    }
    
    func test_term_backspace_mid_word_toan() {
        simulator.reset()
        telexEngine.reset()
        _ = simulator.typeString("toans", engine: telexEngine)
        _ = simulator.pressBackspace(engine: telexEngine)
        _ = simulator.typeString("n", engine: telexEngine)
        XCTAssertEqual(simulator.currentBuffer, "toán")
    }
    
    func test_term_backspace_mid_word_hoc() {
        simulator.reset()
        telexEngine.reset()
        _ = simulator.typeString("hojc", engine: telexEngine)
        _ = simulator.pressBackspace(engine: telexEngine)
        _ = simulator.typeString("c", engine: telexEngine)
        XCTAssertEqual(simulator.currentBuffer, "học")
    }
    
    func test_term_backspace_clear_all_line() {
        simulator.reset()
        telexEngine.reset()
        _ = simulator.typeString("echo hello", engine: telexEngine)
        for _ in 0..<10 {
            _ = simulator.pressBackspace(engine: telexEngine)
        }
        XCTAssertEqual(simulator.currentBuffer, "")
    }
    
    func test_term_backspace_empty_terminal() {
        simulator.reset()
        telexEngine.reset()
        let event = simulator.pressBackspace(engine: telexEngine)
        XCTAssertTrue(event.isSuccess)
        XCTAssertEqual(simulator.currentBuffer, "")
    }
    
    func test_term_backspace_undo_tone_s() {
        simulator.reset()
        telexEngine.reset()
        _ = simulator.typeString("bas", engine: telexEngine)
        _ = simulator.typeString("s", engine: telexEngine) // tone undo
        XCTAssertEqual(simulator.currentBuffer, "bas")
    }
    
    func test_term_backspace_undo_mark_a() {
        simulator.reset()
        telexEngine.reset()
        _ = simulator.typeString("aa", engine: telexEngine)
        _ = simulator.typeString("a", engine: telexEngine) // mark undo
        XCTAssertEqual(simulator.currentBuffer, "aa")
    }
    
    func test_term_backspace_clear_z() {
        simulator.reset()
        telexEngine.reset()
        _ = simulator.typeString("toans", engine: telexEngine)
        _ = simulator.typeString("z", engine: telexEngine) // clear tone
        XCTAssertEqual(simulator.currentBuffer, "toan")
    }
    
    func test_term_backspace_retype_word_1() {
        simulator.reset()
        telexEngine.reset()
        _ = simulator.typeString("dduwowj", engine: telexEngine)
        _ = simulator.pressBackspace(engine: telexEngine)
        _ = simulator.typeString("jc", engine: telexEngine)
        XCTAssertEqual(simulator.currentBuffer, "được")
    }
    
    func test_term_backspace_retype_word_2() {
        simulator.reset()
        telexEngine.reset()
        _ = simulator.typeString("nguowf", engine: telexEngine)
        _ = simulator.pressBackspace(engine: telexEngine)
        _ = simulator.typeString("fi", engine: telexEngine)
        XCTAssertEqual(simulator.currentBuffer, "người")
    }
    
    func test_term_backspace_retype_word_3() {
        simulator.reset()
        telexEngine.reset()
        _ = simulator.typeString("truwowf", engine: telexEngine)
        _ = simulator.pressBackspace(engine: telexEngine)
        _ = simulator.typeString("fng", engine: telexEngine)
        XCTAssertEqual(simulator.currentBuffer, "trường")
    }
    
    func test_term_backspace_retype_word_4() {
        simulator.reset()
        telexEngine.reset()
        _ = simulator.typeString("nuowc", engine: telexEngine)
        _ = simulator.pressBackspace(engine: telexEngine)
        _ = simulator.typeString("cs", engine: telexEngine)
        XCTAssertEqual(simulator.currentBuffer, "nước")
    }
    
    func test_term_backspace_retype_word_5() {
        simulator.reset()
        telexEngine.reset()
        _ = simulator.typeString("tieeng", engine: telexEngine)
        _ = simulator.pressBackspace(engine: telexEngine)
        _ = simulator.typeString("gs", engine: telexEngine)
        XCTAssertEqual(simulator.currentBuffer, "tiếng")
    }
    
    func test_term_backspace_multiple_spaces() {
        simulator.reset()
        telexEngine.reset()
        _ = simulator.typeString("ls   -la", engine: telexEngine)
        XCTAssertEqual(simulator.currentBuffer, "ls   -la")
    }
    
    func test_term_backspace_semicolon_chain() {
        simulator.reset()
        telexEngine.reset()
        _ = simulator.typeString("cd /tmp; echo \"vieetj\"", engine: telexEngine)
        XCTAssertEqual(simulator.currentBuffer, "cd /tmp; echo \"việt\"")
    }
    
    // MARK: - Registration of all tests
    public override var allTests: [(name: String, test: TestMethod)] {
        return [
            ("test_term_telex_viet", test_term_telex_viet),
            ("test_term_telex_nam", test_term_telex_nam),
            ("test_term_telex_toan", test_term_telex_toan),
            ("test_term_telex_tieng", test_term_telex_tieng),
            ("test_term_telex_hoc", test_term_telex_hoc),
            ("test_term_telex_dat", test_term_telex_dat),
            ("test_term_telex_duoc", test_term_telex_duoc),
            ("test_term_telex_nguoi", test_term_telex_nguoi),
            ("test_term_telex_truong", test_term_telex_truong),
            ("test_term_telex_nuoc", test_term_telex_nuoc),
            ("test_term_telex_buoc", test_term_telex_buoc),
            ("test_term_telex_muon", test_term_telex_muon),
            ("test_term_telex_dong", test_term_telex_dong),
            ("test_term_telex_som", test_term_telex_som),
            ("test_term_telex_toi", test_term_telex_toi),
            ("test_term_telex_pho", test_term_telex_pho),
            ("test_term_telex_nha", test_term_telex_nha),
            ("test_term_telex_me", test_term_telex_me),
            ("test_term_telex_bo", test_term_telex_bo),
            ("test_term_telex_con", test_term_telex_con),
            
            ("test_term_vni_viet", test_term_vni_viet),
            ("test_term_vni_toan", test_term_vni_toan),
            ("test_term_vni_tieng", test_term_vni_tieng),
            ("test_term_vni_hoc", test_term_vni_hoc),
            ("test_term_vni_duoc", test_term_vni_duoc),
            ("test_term_vni_nguoi", test_term_vni_nguoi),
            ("test_term_vni_truong", test_term_vni_truong),
            ("test_term_vni_nuoc", test_term_vni_nuoc),
            ("test_term_vni_dong", test_term_vni_dong),
            ("test_term_vni_nha", test_term_vni_nha),
            ("test_term_vni_me", test_term_vni_me),
            ("test_term_vni_pho", test_term_vni_pho),
            ("test_term_vni_so", test_term_vni_so),
            ("test_term_vni_chuc", test_term_vni_chuc),
            ("test_term_vni_mung", test_term_vni_mung),
            
            ("test_term_cmd_git_commit_1", test_term_cmd_git_commit_1),
            ("test_term_cmd_git_commit_2", test_term_cmd_git_commit_2),
            ("test_term_cmd_echo_hello", test_term_cmd_echo_hello),
            ("test_term_cmd_mkdir_folder", test_term_cmd_mkdir_folder),
            ("test_term_cmd_touch_report", test_term_cmd_touch_report),
            ("test_term_cmd_vim_file", test_term_cmd_vim_file),
            ("test_term_cmd_git_branch", test_term_cmd_git_branch),
            ("test_term_cmd_grep", test_term_cmd_grep),
            ("test_term_cmd_cat", test_term_cmd_cat),
            ("test_term_cmd_nano", test_term_cmd_nano),
            ("test_term_cmd_curl", test_term_cmd_curl),
            ("test_term_cmd_find", test_term_cmd_find),
            ("test_term_cmd_tar", test_term_cmd_tar),
            ("test_term_cmd_ssh", test_term_cmd_ssh),
            ("test_term_cmd_make", test_term_cmd_make),
            
            ("test_term_cmd_code_dot", test_term_cmd_code_dot),
            ("test_term_cmd_git_status", test_term_cmd_git_status),
            ("test_term_cmd_git_diff", test_term_cmd_git_diff),
            ("test_term_cmd_git_push", test_term_cmd_git_push),
            ("test_term_cmd_git_pull", test_term_cmd_git_pull),
            ("test_term_cmd_view_file", test_term_cmd_view_file),
            ("test_term_cmd_clear", test_term_cmd_clear),
            ("test_term_cmd_cargo_test", test_term_cmd_cargo_test),
            ("test_term_cmd_swift_build", test_term_cmd_swift_build),
            ("test_term_cmd_npm_start", test_term_cmd_npm_start),
            ("test_term_cmd_docker_ps", test_term_cmd_docker_ps),
            ("test_term_cmd_python_main", test_term_cmd_python_main),
            ("test_term_cmd_cat_post", test_term_cmd_cat_post),
            ("test_term_cmd_grep_format", test_term_cmd_grep_format),
            ("test_term_cmd_curl_post", test_term_cmd_curl_post),
            
            ("test_term_backspace_mid_commit", test_term_backspace_mid_commit),
            ("test_term_backspace_mid_word_toan", test_term_backspace_mid_word_toan),
            ("test_term_backspace_mid_word_hoc", test_term_backspace_mid_word_hoc),
            ("test_term_backspace_clear_all_line", test_term_backspace_clear_all_line),
            ("test_term_backspace_empty_terminal", test_term_backspace_empty_terminal),
            ("test_term_backspace_undo_tone_s", test_term_backspace_undo_tone_s),
            ("test_term_backspace_undo_mark_a", test_term_backspace_undo_mark_a),
            ("test_term_backspace_clear_z", test_term_backspace_clear_z),
            ("test_term_backspace_retype_word_1", test_term_backspace_retype_word_1),
            ("test_term_backspace_retype_word_2", test_term_backspace_retype_word_2),
            ("test_term_backspace_retype_word_3", test_term_backspace_retype_word_3),
            ("test_term_backspace_retype_word_4", test_term_backspace_retype_word_4),
            ("test_term_backspace_retype_word_5", test_term_backspace_retype_word_5),
            ("test_term_backspace_multiple_spaces", test_term_backspace_multiple_spaces),
            ("test_term_backspace_semicolon_chain", test_term_backspace_semicolon_chain),
        ]
    }
}
