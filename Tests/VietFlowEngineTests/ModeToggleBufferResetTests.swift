//
//  ModeToggleBufferResetTests.swift
//  VietFlowEngineTests
//
//  Comprehensive test suite verifying that switching input modes and calling engine.reset():
//  - Completely flushes activePreedit, committedPrefix, and wordRawKeys
//  - Flushes syllable transform state (standalone 'w', diacritic undo, tone undo, bypass latch)
//  - Ensures subsequent English or Vietnamese keystrokes produce zero stale backspaces
//  - Verifies AppStateManager.toggleInputMode() synchronous engine flush linkage
//

import Foundation
import VietFlowEngine
import VietFlowState

public typealias TestCase = VietFlowTestCase

public final class ModeToggleBufferResetTests: TestCase {
    private var engine: VietnameseEngineProtocol!
    
    public override func setUp() {
        super.setUp()
        engine = makeEngine(inputMethod: .telex, tonePlacement: .modern)
    }
    
    public override func tearDown() {
        engine = nil
        super.tearDown()
    }
    
    // MARK: - Test 1: Reset Flushes Current Syllable
    func test_01_reset_flushes_current_syllable() {
        let _ = typeSequence("viet", into: engine)
        XCTAssertEqual(engine.currentSyllable, "viet")
        
        engine.reset()
        XCTAssertEqual(engine.currentSyllable, "")
    }
    
    // MARK: - Test 2: Zero Stale Backspaces on Subsequent English Typing
    func test_02_subsequent_english_keystrokes_after_vietnamese_partial_produce_zero_backspaces() {
        // User typed partial Vietnamese syllable "viê"
        let _ = typeSequence("viee", into: engine)
        XCTAssertEqual(engine.currentSyllable, "viê")
        
        // Mode switch occurs: buffer is reset
        engine.reset()
        XCTAssertEqual(engine.currentSyllable, "")
        
        // In English mode, user types "hello"
        let (deltas, output) = typeSequence("hello", into: engine)
        
        // Verify no backspaces were emitted that would delete the previously typed "viê"
        for delta in deltas {
            XCTAssertEqual(delta.backspaces, 0, "Stale backspace detected after mode toggle reset!")
        }
        XCTAssertEqual(output, "hello")
    }
    
    // MARK: - Test 3: No Stale Diacritic Attachment After Reset
    func test_03_subsequent_vietnamese_typing_after_reset_has_no_stale_diacritic() {
        // User typed "toan"
        let _ = typeSequence("toan", into: engine)
        XCTAssertEqual(engine.currentSyllable, "toan")
        
        // Reset happens on mode flip
        engine.reset()
        XCTAssertEqual(engine.currentSyllable, "")
        
        // User presses 's' (which is acute tone in Telex)
        let (_, output) = typeSequence("s", into: engine)
        
        // 's' must NOT turn the previous syllable into "toán"
        XCTAssertEqual(output, "s")
        XCTAssertEqual(engine.currentSyllable, "s")
    }
    
    // MARK: - Test 4: Reset Flushes English Bypass Latch
    func test_04_reset_flushes_english_bypass_latch() {
        // Type English keyword "table" which triggers auto-restore / bypass latch
        let _ = typeSequence("table", into: engine)
        
        // Mode toggle / reset occurs
        engine.reset()
        XCTAssertEqual(engine.currentSyllable, "")
        
        // Now type Vietnamese "dd" -> must produce "đ"
        let (_, output) = typeSequence("dd", into: engine)
        XCTAssertEqual(output, "đ")
        XCTAssertEqual(engine.currentSyllable, "đ")
    }
    
    // MARK: - Test 5: Reset Flushes Standalone 'w' State
    func test_05_reset_flushes_standalone_w_state() {
        // Standalone 'w' in Telex produces 'ư'
        let (_, out1) = typeSequence("w", into: engine)
        XCTAssertEqual(out1, "ư")
        
        // Reset occurs
        engine.reset()
        
        // A second 'w' after reset must be a new standalone 'w' producing 'ư', NOT double-w undo to 'w'
        let (_, out2) = typeSequence("w", into: engine)
        XCTAssertEqual(out2, "ư")
    }
    
    // MARK: - Test 6: Reset Flushes Double-Press Tone Undo State
    func test_06_reset_flushes_double_press_tone_undo_state() {
        // Type "ba" + "s" -> "bá"
        let _ = typeSequence("bas", into: engine)
        XCTAssertEqual(engine.currentSyllable, "bá")
        
        // Reset occurs
        engine.reset()
        
        // Typing 's' must NOT undo "bá" to "bas"; it is a new syllable starting with 's'
        let (_, out) = typeSequence("s", into: engine)
        XCTAssertEqual(out, "s")
    }
    
    // MARK: - Test 7: Reset Flushes Double-Press Diacritic Undo State
    func test_07_reset_flushes_double_press_diacritic_undo_state() {
        // Type "aa" -> "â"
        let _ = typeSequence("aa", into: engine)
        XCTAssertEqual(engine.currentSyllable, "â")
        
        // Reset occurs
        engine.reset()
        
        // Typing 'a' must produce 'a', NOT undo "â" to "aa"
        let (_, out) = typeSequence("a", into: engine)
        XCTAssertEqual(out, "a")
    }
    
    // MARK: - Test 8: Reset Flushes Backspace State
    func test_08_reset_flushes_backspace_state() {
        let _ = typeSequence("viett", into: engine)
        let didBS = engine.handleBackspace()
        XCTAssertTrue(didBS)
        
        engine.reset()
        XCTAssertEqual(engine.currentSyllable, "")
        
        let (_, out) = typeSequence("nam", into: engine)
        XCTAssertEqual(out, "nam")
    }
    
    // MARK: - Test 9: Rapid Word Isolation Across Resets
    func test_09_rapid_word_isolation_across_resets() {
        let words = [
            ("xin", "xin"),
            ("chaof", "chào"),
            ("vieetj", "việt"),
            ("nam", "nam")
        ]
        
        for (input, expected) in words {
            engine.reset()
            let (_, output) = typeSequence(input, into: engine)
            XCTAssertEqual(output, expected, "Failed for word: \(input)")
        }
    }
    
    // MARK: - Test 10: AppStateManager Linkage Flushes Engine on Toggle
    func test_10_app_state_manager_linkage_flushes_engine_on_toggle() {
        guard let bamboo = engine as? BambooEngine else {
            XCTFail("Engine is not BambooEngine")
            return
        }
        
        let stateManager = AppStateManager.shared
        stateManager.engine = bamboo
        
        let _ = typeSequence("dduowng", into: engine)
        XCTAssertEqual(engine.currentSyllable, "đương")
        
        // Toggle input mode via AppStateManager
        stateManager.toggleInputMode()
        
        // Engine buffer must be instantly empty
        XCTAssertEqual(engine.currentSyllable, "")
        
        // Subsequent keystrokes produce clean output without backspaces
        let (deltas, out) = typeSequence("hello", into: engine)
        for delta in deltas {
            XCTAssertEqual(delta.backspaces, 0)
        }
        XCTAssertEqual(out, "hello")
        
        // Clean up linkage
        stateManager.engine = nil
    }
    
    // MARK: - Test 11: Consecutive Mode Toggles Preserve Clean State
    func test_11_consecutive_mode_toggles_preserve_clean_state() {
        guard let bamboo = engine as? BambooEngine else {
            XCTFail("Engine is not BambooEngine")
            return
        }
        
        let stateManager = AppStateManager.shared
        stateManager.engine = bamboo
        
        // Toggle V -> E -> V -> E -> V
        for _ in 0..<4 {
            stateManager.toggleInputMode()
            XCTAssertEqual(engine.currentSyllable, "")
        }
        
        let (_, out) = typeSequence("hojc", into: engine)
        XCTAssertEqual(out, "học")
        
        stateManager.engine = nil
    }
    
    // MARK: - Test 12: Reset on Empty Engine is Safe No-Op
    func test_12_reset_on_empty_engine_is_safe_noop() {
        XCTAssertEqual(engine.currentSyllable, "")
        for _ in 0..<10 {
            engine.reset()
            XCTAssertEqual(engine.currentSyllable, "")
        }
        
        let (_, out) = typeSequence("an", into: engine)
        XCTAssertEqual(out, "an")
    }
    
    // MARK: - Test Registry Registration
    public override var allTests: [(name: String, test: () throws -> Void)] {
        return [
            ("test_01_reset_flushes_current_syllable", test_01_reset_flushes_current_syllable),
            ("test_02_subsequent_english_keystrokes_after_vietnamese_partial_produce_zero_backspaces", test_02_subsequent_english_keystrokes_after_vietnamese_partial_produce_zero_backspaces),
            ("test_03_subsequent_vietnamese_typing_after_reset_has_no_stale_diacritic", test_03_subsequent_vietnamese_typing_after_reset_has_no_stale_diacritic),
            ("test_04_reset_flushes_english_bypass_latch", test_04_reset_flushes_english_bypass_latch),
            ("test_05_reset_flushes_standalone_w_state", test_05_reset_flushes_standalone_w_state),
            ("test_06_reset_flushes_double_press_tone_undo_state", test_06_reset_flushes_double_press_tone_undo_state),
            ("test_07_reset_flushes_double_press_diacritic_undo_state", test_07_reset_flushes_double_press_diacritic_undo_state),
            ("test_08_reset_flushes_backspace_state", test_08_reset_flushes_backspace_state),
            ("test_09_rapid_word_isolation_across_resets", test_09_rapid_word_isolation_across_resets),
            ("test_10_app_state_manager_linkage_flushes_engine_on_toggle", test_10_app_state_manager_linkage_flushes_engine_on_toggle),
            ("test_11_consecutive_mode_toggles_preserve_clean_state", test_11_consecutive_mode_toggles_preserve_clean_state),
            ("test_12_reset_on_empty_engine_is_safe_noop", test_12_reset_on_empty_engine_is_safe_noop),
        ]
    }
}
