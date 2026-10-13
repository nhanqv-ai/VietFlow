//
//  HotkeyStateMachineTests.swift
//  VietFlowEventTapTests
//
//  Comprehensive test suite for ModifierChordStateMachine:
//  - Pure 4-state finite state machine (idle, primed, triggered, cancelled)
//  - Order-independent modifier chord detection
//  - Elimination of arbitrary duration timeouts (unlimited hold duration)
//  - Intervening key down and mouse click chord cancellation
//  - Extraneous modifier rejection
//  - Multi-chord presets (.controlShift, .commandShift, .optionShift, .option)
//  - Bitmask isolation (ignoring CapsLock, Fn, and device flags)
//

import Foundation
import CoreGraphics
import VietFlowState
import VietFlowEventTap
import VietFlowEngineTests

public final class HotkeyStateMachineTests: TestCase {
    private var stateMachine: ModifierChordStateMachine!
    private var triggerCount: Int = 0
    
    public override func setUp() {
        super.setUp()
        triggerCount = 0
        stateMachine = ModifierChordStateMachine(shortcut: .controlShift) { [weak self] in
            self?.triggerCount += 1
        }
    }
    
    public override func tearDown() {
        stateMachine = nil
        super.tearDown()
    }
    
    // MARK: - Test 1: Initial State
    func test_01_initial_state_is_idle() {
        XCTAssertEqual(stateMachine.state, .idle)
        XCTAssertEqual(stateMachine.currentState, .idle)
        XCTAssertEqual(stateMachine.shortcut, .controlShift)
        XCTAssertEqual(triggerCount, 0)
    }
    
    // MARK: - Test 2: Idle to Primed
    func test_02_idle_to_primed_on_matching_chord() {
        let flags: CGEventFlags = [.maskControl, .maskShift]
        let triggered = stateMachine.handleFlagsChanged(flags)
        
        XCTAssertFalse(triggered)
        XCTAssertEqual(stateMachine.state, .primed)
        XCTAssertEqual(triggerCount, 0)
    }
    
    // MARK: - Test 3: Primed to Triggered on Simultaneous Release
    func test_03_primed_to_idle_on_simultaneous_release() {
        let chordFlags: CGEventFlags = [.maskControl, .maskShift]
        stateMachine.handleFlagsChanged(chordFlags)
        XCTAssertEqual(stateMachine.state, .primed)
        
        let releaseFlags: CGEventFlags = []
        let triggered = stateMachine.handleFlagsChanged(releaseFlags)
        
        XCTAssertTrue(triggered)
        XCTAssertEqual(stateMachine.state, .idle)
        XCTAssertEqual(triggerCount, 1)
    }
    
    // MARK: - Test 4: Primed to Triggered on Partial Release (Shift released first)
    func test_04_primed_to_triggered_on_partial_release_shift_first() {
        let chordFlags: CGEventFlags = [.maskControl, .maskShift]
        stateMachine.handleFlagsChanged(chordFlags)
        XCTAssertEqual(stateMachine.state, .primed)
        
        // Release Shift while still holding Control
        let partialRelease: CGEventFlags = [.maskControl]
        let triggered = stateMachine.handleFlagsChanged(partialRelease)
        
        XCTAssertTrue(triggered)
        XCTAssertEqual(stateMachine.state, .triggered)
        XCTAssertEqual(triggerCount, 1)
        
        // Releasing remaining Control modifier transitions back to idle
        let fullRelease: CGEventFlags = []
        let secondTriggered = stateMachine.handleFlagsChanged(fullRelease)
        
        XCTAssertFalse(secondTriggered)
        XCTAssertEqual(stateMachine.state, .idle)
        XCTAssertEqual(triggerCount, 1) // Must not trigger again
    }
    
    // MARK: - Test 5: Primed to Triggered on Partial Release (Control released first)
    func test_05_primed_to_triggered_on_partial_release_control_first() {
        let chordFlags: CGEventFlags = [.maskControl, .maskShift]
        stateMachine.handleFlagsChanged(chordFlags)
        XCTAssertEqual(stateMachine.state, .primed)
        
        // Release Control while still holding Shift
        let partialRelease: CGEventFlags = [.maskShift]
        let triggered = stateMachine.handleFlagsChanged(partialRelease)
        
        XCTAssertTrue(triggered)
        XCTAssertEqual(stateMachine.state, .triggered)
        XCTAssertEqual(triggerCount, 1)
        
        // Releasing remaining Shift transitions back to idle
        let fullRelease: CGEventFlags = []
        let secondTriggered = stateMachine.handleFlagsChanged(fullRelease)
        
        XCTAssertFalse(secondTriggered)
        XCTAssertEqual(stateMachine.state, .idle)
        XCTAssertEqual(triggerCount, 1)
    }
    
    // MARK: - Test 6: Order Independence (Control then Shift)
    func test_06_order_independence_control_then_shift() {
        // Step 1: Press Control alone
        let ctrlOnly: CGEventFlags = [.maskControl]
        let t1 = stateMachine.handleFlagsChanged(ctrlOnly)
        XCTAssertFalse(t1)
        XCTAssertEqual(stateMachine.state, .idle)
        
        // Step 2: Press Shift while Control is held
        let both: CGEventFlags = [.maskControl, .maskShift]
        let t2 = stateMachine.handleFlagsChanged(both)
        XCTAssertFalse(t2)
        XCTAssertEqual(stateMachine.state, .primed)
        
        // Step 3: Release both
        let release: CGEventFlags = []
        let t3 = stateMachine.handleFlagsChanged(release)
        XCTAssertTrue(t3)
        XCTAssertEqual(stateMachine.state, .idle)
        XCTAssertEqual(triggerCount, 1)
    }
    
    // MARK: - Test 7: Order Independence (Shift then Control)
    func test_07_order_independence_shift_then_control() {
        // Step 1: Press Shift alone
        let shiftOnly: CGEventFlags = [.maskShift]
        let t1 = stateMachine.handleFlagsChanged(shiftOnly)
        XCTAssertFalse(t1)
        XCTAssertEqual(stateMachine.state, .idle)
        
        // Step 2: Press Control while Shift is held
        let both: CGEventFlags = [.maskControl, .maskShift]
        let t2 = stateMachine.handleFlagsChanged(both)
        XCTAssertFalse(t2)
        XCTAssertEqual(stateMachine.state, .primed)
        
        // Step 3: Release both
        let release: CGEventFlags = []
        let t3 = stateMachine.handleFlagsChanged(release)
        XCTAssertTrue(t3)
        XCTAssertEqual(stateMachine.state, .idle)
        XCTAssertEqual(triggerCount, 1)
    }
    
    // MARK: - Test 8: Arbitrary Hold Duration (Eliminates old 0.5s timeout)
    func test_08_arbitrary_hold_duration_does_not_drop_toggle() {
        let chordFlags: CGEventFlags = [.maskControl, .maskShift]
        stateMachine.handleFlagsChanged(chordFlags)
        XCTAssertEqual(stateMachine.state, .primed)
        
        // Simulate repeated flagsChanged calls over extended hold time (e.g. 1s, 2s, 5s)
        for _ in 0..<50 {
            let stayPrimed = stateMachine.handleFlagsChanged(chordFlags)
            XCTAssertFalse(stayPrimed)
            XCTAssertEqual(stateMachine.state, .primed)
        }
        
        // When finally released, the chord triggers reliably
        let releaseFlags: CGEventFlags = []
        let triggered = stateMachine.handleFlagsChanged(releaseFlags)
        XCTAssertTrue(triggered)
        XCTAssertEqual(stateMachine.state, .idle)
        XCTAssertEqual(triggerCount, 1)
    }
    
    // MARK: - Test 9: Intervening Key Down Cancels Primed Chord
    func test_09_intervening_keydown_cancels_chord() {
        let chordFlags: CGEventFlags = [.maskControl, .maskShift]
        stateMachine.handleFlagsChanged(chordFlags)
        XCTAssertEqual(stateMachine.state, .primed)
        
        // Intervening character or command keydown (e.g. user pressed Ctrl+Shift+F)
        stateMachine.handleKeyDown()
        XCTAssertEqual(stateMachine.state, .cancelled)
        
        // Releasing modifiers while cancelled MUST NOT trigger toggle
        let releaseFlags: CGEventFlags = []
        let triggered = stateMachine.handleFlagsChanged(releaseFlags)
        XCTAssertFalse(triggered)
        XCTAssertEqual(stateMachine.state, .idle)
        XCTAssertEqual(triggerCount, 0)
    }
    
    // MARK: - Test 10: Intervening Mouse Down Cancels Primed Chord
    func test_10_intervening_mousedown_cancels_chord() {
        let chordFlags: CGEventFlags = [.maskControl, .maskShift]
        stateMachine.handleFlagsChanged(chordFlags)
        XCTAssertEqual(stateMachine.state, .primed)
        
        // Intervening mouse click during chord hold
        stateMachine.handleMouseDown()
        XCTAssertEqual(stateMachine.state, .cancelled)
        
        // Releasing modifiers MUST NOT trigger toggle
        let releaseFlags: CGEventFlags = []
        let triggered = stateMachine.handleFlagsChanged(releaseFlags)
        XCTAssertFalse(triggered)
        XCTAssertEqual(stateMachine.state, .idle)
        XCTAssertEqual(triggerCount, 0)
    }
    
    // MARK: - Test 11: Extraneous Modifier Rejection (Command added)
    func test_11_extraneous_modifier_command_cancels_chord() {
        let chordFlags: CGEventFlags = [.maskControl, .maskShift]
        stateMachine.handleFlagsChanged(chordFlags)
        XCTAssertEqual(stateMachine.state, .primed)
        
        // User accidentally presses Command in addition to Ctrl+Shift
        let extraneousFlags: CGEventFlags = [.maskControl, .maskShift, .maskCommand]
        let triggered = stateMachine.handleFlagsChanged(extraneousFlags)
        
        XCTAssertFalse(triggered)
        XCTAssertEqual(stateMachine.state, .cancelled)
        
        // Releasing all modifiers returns to idle with zero triggers
        let releaseFlags: CGEventFlags = []
        let finalTriggered = stateMachine.handleFlagsChanged(releaseFlags)
        XCTAssertFalse(finalTriggered)
        XCTAssertEqual(stateMachine.state, .idle)
        XCTAssertEqual(triggerCount, 0)
    }
    
    // MARK: - Test 12: Extraneous Modifier Rejection (Option added)
    func test_12_extraneous_modifier_option_cancels_chord() {
        let chordFlags: CGEventFlags = [.maskControl, .maskShift]
        stateMachine.handleFlagsChanged(chordFlags)
        XCTAssertEqual(stateMachine.state, .primed)
        
        // User presses Option in addition to Ctrl+Shift
        let extraneousFlags: CGEventFlags = [.maskControl, .maskShift, .maskAlternate]
        let triggered = stateMachine.handleFlagsChanged(extraneousFlags)
        
        XCTAssertFalse(triggered)
        XCTAssertEqual(stateMachine.state, .cancelled)
        
        // Releasing returns to idle
        let releaseFlags: CGEventFlags = []
        stateMachine.handleFlagsChanged(releaseFlags)
        XCTAssertEqual(stateMachine.state, .idle)
        XCTAssertEqual(triggerCount, 0)
    }
    
    // MARK: - Test 13: Extraneous Modifier from Idle Does Not Prime
    func test_13_extraneous_modifier_from_idle_does_not_prime() {
        // Press Command+Control+Shift while shortcut is Control+Shift
        let flags: CGEventFlags = [.maskCommand, .maskControl, .maskShift]
        let triggered = stateMachine.handleFlagsChanged(flags)
        
        XCTAssertFalse(triggered)
        XCTAssertEqual(stateMachine.state, .cancelled)
        
        stateMachine.handleFlagsChanged([])
        XCTAssertEqual(stateMachine.state, .idle)
        XCTAssertEqual(triggerCount, 0)
    }
    
    // MARK: - Test 14: Command+Shift Chord Preset
    func test_14_command_shift_chord() {
        stateMachine.shortcut = .commandShift
        XCTAssertEqual(stateMachine.shortcut, .commandShift)
        XCTAssertEqual(stateMachine.state, .idle)
        
        // Press Command+Shift
        let chordFlags: CGEventFlags = [.maskCommand, .maskShift]
        stateMachine.handleFlagsChanged(chordFlags)
        XCTAssertEqual(stateMachine.state, .primed)
        
        // Release
        let triggered = stateMachine.handleFlagsChanged([])
        XCTAssertTrue(triggered)
        XCTAssertEqual(stateMachine.state, .idle)
        XCTAssertEqual(triggerCount, 1)
    }
    
    // MARK: - Test 15: Option+Shift Chord Preset
    func test_15_option_shift_chord() {
        stateMachine.shortcut = .optionShift
        XCTAssertEqual(stateMachine.shortcut, .optionShift)
        
        // Press Option+Shift
        let chordFlags: CGEventFlags = [.maskAlternate, .maskShift]
        stateMachine.handleFlagsChanged(chordFlags)
        XCTAssertEqual(stateMachine.state, .primed)
        
        // Release
        let triggered = stateMachine.handleFlagsChanged([])
        XCTAssertTrue(triggered)
        XCTAssertEqual(stateMachine.state, .idle)
        XCTAssertEqual(triggerCount, 1)
    }
    
    // MARK: - Test 16: Option Single Modifier Preset
    func test_16_option_single_modifier() {
        stateMachine.shortcut = .option
        XCTAssertEqual(stateMachine.shortcut, .option)
        
        // Press Option
        let chordFlags: CGEventFlags = [.maskAlternate]
        stateMachine.handleFlagsChanged(chordFlags)
        XCTAssertEqual(stateMachine.state, .primed)
        
        // Release Option
        let triggered = stateMachine.handleFlagsChanged([])
        XCTAssertTrue(triggered)
        XCTAssertEqual(stateMachine.state, .idle)
        XCTAssertEqual(triggerCount, 1)
    }
    
    // MARK: - Test 17: Option Preset Extraneous Modifier Rejection
    func test_17_option_preset_extraneous_modifier_rejection() {
        stateMachine.shortcut = .option
        
        // Press Option
        stateMachine.handleFlagsChanged([.maskAlternate])
        XCTAssertEqual(stateMachine.state, .primed)
        
        // Press Shift while Option is held -> cancels chord
        stateMachine.handleFlagsChanged([.maskAlternate, .maskShift])
        XCTAssertEqual(stateMachine.state, .cancelled)
        
        // Release -> no trigger
        let triggered = stateMachine.handleFlagsChanged([])
        XCTAssertFalse(triggered)
        XCTAssertEqual(triggerCount, 0)
    }
    
    // MARK: - Test 18: Masking Out Device & CapsLock Flags
    func test_18_device_and_capslock_flags_ignored() {
        // Real macOS events often include CapsLock (.maskAlphaShift) or device-specific bits
        let rawWithCapsLock: CGEventFlags = [.maskControl, .maskShift, .maskAlphaShift]
        stateMachine.handleFlagsChanged(rawWithCapsLock)
        XCTAssertEqual(stateMachine.state, .primed)
        
        // Release modifiers while CapsLock remains on
        let releaseWithCapsLock: CGEventFlags = [.maskAlphaShift]
        let triggered = stateMachine.handleFlagsChanged(releaseWithCapsLock)
        XCTAssertTrue(triggered)
        XCTAssertEqual(stateMachine.state, .idle)
        XCTAssertEqual(triggerCount, 1)
    }
    
    // MARK: - Test 19: Multiple Consecutive Toggle Cycles
    func test_19_multiple_consecutive_toggle_cycles() {
        let chordFlags: CGEventFlags = [.maskControl, .maskShift]
        let emptyFlags: CGEventFlags = []
        
        for cycle in 1...5 {
            // Press
            stateMachine.handleFlagsChanged(chordFlags)
            XCTAssertEqual(stateMachine.state, .primed)
            
            // Release
            let triggered = stateMachine.handleFlagsChanged(emptyFlags)
            XCTAssertTrue(triggered)
            XCTAssertEqual(stateMachine.state, .idle)
            XCTAssertEqual(triggerCount, cycle)
        }
    }
    
    // MARK: - Test 20: Reset Clears Primed State to Idle
    func test_20_reset_clears_primed_state() {
        stateMachine.handleFlagsChanged([.maskControl, .maskShift])
        XCTAssertEqual(stateMachine.state, .primed)
        
        stateMachine.reset()
        XCTAssertEqual(stateMachine.state, .idle)
        
        // Subsequent release does not trigger
        let triggered = stateMachine.handleFlagsChanged([])
        XCTAssertFalse(triggered)
        XCTAssertEqual(triggerCount, 0)
    }
    
    // MARK: - Test 21: Changing Shortcut Resets Machine
    func test_21_changing_shortcut_resets_machine() {
        stateMachine.handleFlagsChanged([.maskControl, .maskShift])
        XCTAssertEqual(stateMachine.state, .primed)
        
        stateMachine.shortcut = .commandShift
        XCTAssertEqual(stateMachine.state, .idle)
        
        // Releasing old Ctrl+Shift does nothing
        stateMachine.handleFlagsChanged([])
        XCTAssertEqual(triggerCount, 0)
        
        // New shortcut works
        stateMachine.handleFlagsChanged([.maskCommand, .maskShift])
        XCTAssertEqual(stateMachine.state, .primed)
        let triggered = stateMachine.handleFlagsChanged([])
        XCTAssertTrue(triggered)
        XCTAssertEqual(triggerCount, 1)
    }
    
    // MARK: - Test 22: Convenience Initializer & currentPreset Alias
    func test_22_convenience_init_and_preset_alias() {
        let sm = ModifierChordStateMachine(preset: .optionShift)
        XCTAssertEqual(sm.currentPreset, .optionShift)
        XCTAssertEqual(sm.shortcut, .optionShift)
        
        sm.currentPreset = .option
        XCTAssertEqual(sm.shortcut, .option)
        XCTAssertEqual(sm.state, .idle)
    }
    
    // MARK: - Test 23: Extraneous Cmd+Ctrl+Shift Sequential Release Does Not Trigger
    func test_23_extraneous_cmd_ctrl_shift_sequential_release_does_not_trigger() {
        // Step 1: Cmd+Ctrl+Shift pressed when target is Ctrl+Shift
        let chordWithCmd: CGEventFlags = [.maskCommand, .maskControl, .maskShift]
        let t1 = stateMachine.handleFlagsChanged(chordWithCmd)
        XCTAssertFalse(t1)
        XCTAssertEqual(stateMachine.state, .cancelled)
        
        // Step 2: Cmd released first while holding Ctrl+Shift
        let ctrlShiftRemaining: CGEventFlags = [.maskControl, .maskShift]
        let t2 = stateMachine.handleFlagsChanged(ctrlShiftRemaining)
        XCTAssertFalse(t2)
        XCTAssertEqual(stateMachine.state, .cancelled)
        
        // Step 3: Ctrl+Shift released
        let empty: CGEventFlags = []
        let t3 = stateMachine.handleFlagsChanged(empty)
        XCTAssertFalse(t3)
        XCTAssertEqual(stateMachine.state, .idle)
        XCTAssertEqual(triggerCount, 0)
        
        // Verify subsequent clean chord still works
        stateMachine.handleFlagsChanged([.maskControl, .maskShift])
        XCTAssertEqual(stateMachine.state, .primed)
        let tClean = stateMachine.handleFlagsChanged([])
        XCTAssertTrue(tClean)
        XCTAssertEqual(triggerCount, 1)
    }
    
    // MARK: - Test 24: Extraneous Option+Ctrl+Shift Sequential Release Does Not Trigger
    func test_24_extraneous_opt_ctrl_shift_sequential_release_does_not_trigger() {
        // Step 1: Option+Ctrl+Shift pressed when target is Ctrl+Shift
        let chordWithOpt: CGEventFlags = [.maskAlternate, .maskControl, .maskShift]
        let t1 = stateMachine.handleFlagsChanged(chordWithOpt)
        XCTAssertFalse(t1)
        XCTAssertEqual(stateMachine.state, .cancelled)
        
        // Step 2: Option released first while holding Ctrl+Shift
        let ctrlShiftRemaining: CGEventFlags = [.maskControl, .maskShift]
        let t2 = stateMachine.handleFlagsChanged(ctrlShiftRemaining)
        XCTAssertFalse(t2)
        XCTAssertEqual(stateMachine.state, .cancelled)
        
        // Step 3: Ctrl+Shift released
        let empty: CGEventFlags = []
        let t3 = stateMachine.handleFlagsChanged(empty)
        XCTAssertFalse(t3)
        XCTAssertEqual(stateMachine.state, .idle)
        XCTAssertEqual(triggerCount, 0)
    }
    
    // MARK: - Test 25: macOS Screenshot Workflow (Cmd+Ctrl+Shift+4)
    func test_25_macos_screenshot_shortcut_with_keydown_and_sequential_release() {
        // Step 1: Cmd+Ctrl+Shift pressed
        let chordWithCmd: CGEventFlags = [.maskCommand, .maskControl, .maskShift]
        stateMachine.handleFlagsChanged(chordWithCmd)
        XCTAssertEqual(stateMachine.state, .cancelled)
        
        // Step 2: '4' key pressed (via handleKeyDown)
        stateMachine.handleKeyDown()
        XCTAssertEqual(stateMachine.state, .cancelled)
        
        // Step 3: Cmd released first
        let ctrlShiftRemaining: CGEventFlags = [.maskControl, .maskShift]
        let tCmdReleased = stateMachine.handleFlagsChanged(ctrlShiftRemaining)
        XCTAssertFalse(tCmdReleased)
        XCTAssertEqual(stateMachine.state, .cancelled)
        
        // Step 4: Ctrl+Shift released
        let tAllReleased = stateMachine.handleFlagsChanged([])
        XCTAssertFalse(tAllReleased)
        XCTAssertEqual(stateMachine.state, .idle)
        XCTAssertEqual(triggerCount, 0)
    }

    // MARK: - Test 26: Interleaved Mouse Click During Extraneous Chord
    func test_26_extraneous_chord_with_mousedown_and_sequential_release() {
        // Step 1: Cmd+Ctrl+Shift pressed
        let chordWithCmd: CGEventFlags = [.maskCommand, .maskControl, .maskShift]
        stateMachine.handleFlagsChanged(chordWithCmd)
        XCTAssertEqual(stateMachine.state, .cancelled)
        
        // Step 2: Mouse clicked
        stateMachine.handleMouseDown()
        XCTAssertEqual(stateMachine.state, .cancelled)
        
        // Step 3: Sequential release of modifiers
        stateMachine.handleFlagsChanged([.maskControl, .maskShift])
        XCTAssertEqual(stateMachine.state, .cancelled)
        
        stateMachine.handleFlagsChanged([])
        XCTAssertEqual(stateMachine.state, .idle)
        XCTAssertEqual(triggerCount, 0)
    }
    
    // MARK: - Test Registry Registration
    public override var allTests: [(name: String, test: () throws -> Void)] {
        return [
            ("test_01_initial_state_is_idle", test_01_initial_state_is_idle),
            ("test_02_idle_to_primed_on_matching_chord", test_02_idle_to_primed_on_matching_chord),
            ("test_03_primed_to_idle_on_simultaneous_release", test_03_primed_to_idle_on_simultaneous_release),
            ("test_04_primed_to_triggered_on_partial_release_shift_first", test_04_primed_to_triggered_on_partial_release_shift_first),
            ("test_05_primed_to_triggered_on_partial_release_control_first", test_05_primed_to_triggered_on_partial_release_control_first),
            ("test_06_order_independence_control_then_shift", test_06_order_independence_control_then_shift),
            ("test_07_order_independence_shift_then_control", test_07_order_independence_shift_then_control),
            ("test_08_arbitrary_hold_duration_does_not_drop_toggle", test_08_arbitrary_hold_duration_does_not_drop_toggle),
            ("test_09_intervening_keydown_cancels_chord", test_09_intervening_keydown_cancels_chord),
            ("test_10_intervening_mousedown_cancels_chord", test_10_intervening_mousedown_cancels_chord),
            ("test_11_extraneous_modifier_command_cancels_chord", test_11_extraneous_modifier_command_cancels_chord),
            ("test_12_extraneous_modifier_option_cancels_chord", test_12_extraneous_modifier_option_cancels_chord),
            ("test_13_extraneous_modifier_from_idle_does_not_prime", test_13_extraneous_modifier_from_idle_does_not_prime),
            ("test_14_command_shift_chord", test_14_command_shift_chord),
            ("test_15_option_shift_chord", test_15_option_shift_chord),
            ("test_16_option_single_modifier", test_16_option_single_modifier),
            ("test_17_option_preset_extraneous_modifier_rejection", test_17_option_preset_extraneous_modifier_rejection),
            ("test_18_device_and_capslock_flags_ignored", test_18_device_and_capslock_flags_ignored),
            ("test_19_multiple_consecutive_toggle_cycles", test_19_multiple_consecutive_toggle_cycles),
            ("test_20_reset_clears_primed_state", test_20_reset_clears_primed_state),
            ("test_21_changing_shortcut_resets_machine", test_21_changing_shortcut_resets_machine),
            ("test_22_convenience_init_and_preset_alias", test_22_convenience_init_and_preset_alias),
            ("test_23_extraneous_cmd_ctrl_shift_sequential_release_does_not_trigger", test_23_extraneous_cmd_ctrl_shift_sequential_release_does_not_trigger),
            ("test_24_extraneous_opt_ctrl_shift_sequential_release_does_not_trigger", test_24_extraneous_opt_ctrl_shift_sequential_release_does_not_trigger),
            ("test_25_macos_screenshot_shortcut_with_keydown_and_sequential_release", test_25_macos_screenshot_shortcut_with_keydown_and_sequential_release),
            ("test_26_extraneous_chord_with_mousedown_and_sequential_release", test_26_extraneous_chord_with_mousedown_and_sequential_release),
        ]
    }
}
