//
//  InputSourceSynchronizationTests.swift
//  VietFlowEventTapTests
//
//  Comprehensive automated test suite for macOS Input Source synchronization:
//  - Auto-suspend to English when switching ABC -> Japanese / Foreign IME
//  - Flushing engine buffer upon IME transitions
//  - Romaji keystroke pass-through without interception
//  - Auto-restore to saved pre-foreign mode (Vietnamese or English) upon returning to ABC
//  - One-step manual toggle from Japanese [E] -> ABC [V] invoking selectLatinInputSource()
//  - Synchronous input source polling before EventTap key interception
//  - Strict zero emoji compliance
//

import Foundation
import CoreGraphics
import VietFlowEngine
import VietFlowState
import VietFlowEventTap
import VietFlowEngineTests

public final class InputSourceSynchronizationTests: TestCase {
    private var mockSourceManager: MockInputSourceManager!
    private var stateManager: AppStateManager!
    private var engine: BambooEngine!
    private var eventTapManager: EventTapManager!
    
    public override func setUp() {
        super.setUp()
        mockSourceManager = MockInputSourceManager(
            initialSourceID: "com.apple.keylayout.ABC",
            initialSourceType: "TISTypeKeyboardLayout",
            isForeign: false
        )
        stateManager = AppStateManager(inputSourceManager: mockSourceManager)
        stateManager.resetToDefaults()
        stateManager.inputSourceManager = mockSourceManager
        
        engine = BambooEngine()
        eventTapManager = EventTapManager(
            engine: engine,
            stateManager: stateManager
        )
    }
    
    public override func tearDown() {
        stateManager.resetToDefaults()
        mockSourceManager = nil
        eventTapManager = nil
        engine = nil
        stateManager = nil
        super.tearDown()
    }
    
    private func createKeyDownEvent(character: Character) -> CGEvent {
        let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)!
        var unichar = UniChar(character.utf16.first!)
        event.keyboardSetUnicodeString(stringLength: 1, unicodeString: &unichar)
        return event
    }
    
    private func createBackspaceEvent() -> CGEvent {
        let event = CGEvent(keyboardEventSource: nil, virtualKey: 51, keyDown: true)!
        return event
    }
    
    // MARK: - Test 1: ABC [V] -> Japanese Auto-Suspend & Romaji Pass-Through
    func test_01_abc_v_to_japanese_auto_switches_to_english_and_passes_romaji_keystrokes_untouched() {
        // Initial state: ABC Latin layout, VietFlow in Vietnamese mode [V]
        stateManager.currentInputMode = .vietnamese
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        XCTAssertFalse(stateManager.isSuspendedByForeignIME)
        
        // Type some characters to ensure buffer is active
        _ = engine.processKey("t")
        _ = engine.processKey("i")
        XCTAssertFalse(engine.currentSyllable.isEmpty)
        
        // macOS switches from ABC to Japanese IME
        mockSourceManager.simulateInputSourceChange(to: "com.apple.inputmethod.Kotoeri.Japanese")
        
        // VietFlow must auto-suspend to [E], reset buffer, and mark suspended
        XCTAssertEqual(stateManager.currentInputMode, .english, "VietFlow must auto-switch to .english on Japanese IME")
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        XCTAssertEqual(stateManager.savedPreForeignMode, .vietnamese, "Pre-foreign mode must be saved as .vietnamese")
        XCTAssertEqual(engine.currentSyllable, "", "Active syllable buffer must be flushed on foreign IME switch")
        
        // Verify all romaji keystrokes specified in R4 pass through completely untouched
        let testWords = ["watashi", "nihongo", "ka", "shi", "tsu"]
        for word in testWords {
            for char in word {
                let event = createKeyDownEvent(character: char)
                let handled = eventTapManager.handleEvent(type: .keyDown, event: event)
                XCTAssertNotNil(handled, "Keystroke '\(char)' in '\(word)' must pass through untouched to Japanese IME")
                XCTAssertEqual(engine.currentSyllable, "", "Engine must not intercept romaji keystrokes while in Japanese IME")
            }
        }
    }
    
    // MARK: - Test 2: Japanese [E] -> ABC Auto-Restore to [V]
    func test_02_japanese_e_to_abc_restores_vietnamese_mode() {
        // Start in ABC [V]
        stateManager.currentInputMode = .vietnamese
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        
        // Switch to Japanese IME -> auto-suspends to [E]
        mockSourceManager.simulateInputSourceChange(to: "com.apple.inputmethod.Kotoeri.Japanese")
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        
        // Switch back to ABC
        mockSourceManager.simulateInputSourceChange(to: "com.apple.keylayout.ABC")
        
        // VietFlow must auto-restore to [V]
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese, "VietFlow must auto-restore to .vietnamese when returning to ABC")
        XCTAssertFalse(stateManager.isSuspendedByForeignIME)
        XCTAssertEqual(engine.currentSyllable, "", "Active syllable buffer must be flushed on return to ABC")
        
        // Verify Vietnamese typing resumes immediately
        for char in "tieengs" {
            _ = engine.processKey(char)
        }
        XCTAssertEqual(engine.currentSyllable, "tiếng", "Vietnamese typing must resume properly upon restoring to ABC")
    }
    
    // MARK: - Test 3: ABC [E] -> Japanese [E] -> ABC Preserves [E]
    func test_03_abc_e_to_japanese_to_abc_preserves_english_mode() {
        // User was already in [E] while on ABC
        stateManager.currentInputMode = .english
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertEqual(stateManager.savedPreForeignMode, .english)
        
        // Switch to Japanese IME
        mockSourceManager.simulateInputSourceChange(to: "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese")
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        XCTAssertEqual(stateManager.savedPreForeignMode, .english)
        
        // Switch back to ABC
        mockSourceManager.simulateInputSourceChange(to: "com.apple.keylayout.ABC")
        
        // Mode must remain [E] (does NOT force [V])
        XCTAssertEqual(stateManager.currentInputMode, .english, "VietFlow must preserve .english mode when returning to ABC if user was already in English")
        XCTAssertFalse(stateManager.isSuspendedByForeignIME)
        XCTAssertEqual(stateManager.savedPreForeignMode, .english)
    }
    
    // MARK: - Test 4: One-Step Direct Switch from Japanese [E] to ABC [V]
    func test_04_manual_toggle_in_japanese_invokes_select_latin_and_activates_vietnamese() {
        // In Japanese IME, auto-suspended in [E]
        stateManager.currentInputMode = .vietnamese
        mockSourceManager.simulateInputSourceChange(to: "com.apple.inputmethod.Kotoeri.Japanese")
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(mockSourceManager.isCurrentSourceForeign)
        XCTAssertFalse(mockSourceManager.selectLatinCalled)
        
        // User triggers mode toggle (via menu bar click, shortcut, or hotkey)
        stateManager.toggleInputMode()
        
        // 1. Programmatically selects Latin input source (ABC)
        XCTAssertTrue(mockSourceManager.selectLatinCalled, "Manual toggle in Japanese must call selectLatinInputSource()")
        XCTAssertEqual(mockSourceManager.selectLatinCallCount, 1)
        XCTAssertEqual(mockSourceManager.currentInputSourceID, "com.apple.keylayout.ABC")
        XCTAssertFalse(mockSourceManager.isCurrentSourceForeign)
        
        // 2. Activates Vietnamese mode [V] and updates remembered pre-foreign mode
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese, "Manual toggle in Japanese must activate .vietnamese mode")
        XCTAssertEqual(stateManager.savedPreForeignMode, .vietnamese, "Remembered pre-foreign mode must be updated to .vietnamese")
        XCTAssertFalse(stateManager.isSuspendedByForeignIME)
        XCTAssertEqual(engine.currentSyllable, "", "Active syllable buffer must be clean")
    }
    
    // MARK: - Test 5: Manual Toggle via EventTapManager in Japanese
    func test_05_event_tap_manager_toggle_synchronously_in_japanese() {
        stateManager.currentInputMode = .vietnamese
        mockSourceManager.simulateInputSourceChange(to: "com.google.inputmethod.Japanese.Roman")
        XCTAssertEqual(stateManager.currentInputMode, .english)
        
        // Trigger via EventTapManager toggleModeSynchronously (hotkey/chord handler)
        eventTapManager.toggleModeSynchronously()
        
        XCTAssertTrue(mockSourceManager.selectLatinCalled)
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        XCTAssertEqual(mockSourceManager.currentInputSourceID, "com.apple.keylayout.ABC")
    }
    
    // MARK: - Test 6: Disabled Setting Ignores Foreign IME Transitions
    func test_06_disabled_setting_leaves_mode_unchanged() {
        stateManager.autoSwitchOnForeignInputSource = false
        stateManager.currentInputMode = .vietnamese
        
        // Switch to Japanese IME while setting is disabled
        mockSourceManager.simulateInputSourceChange(to: "com.apple.inputmethod.Kotoeri.Japanese")
        
        // Mode remains .vietnamese
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        XCTAssertFalse(stateManager.isSuspendedByForeignIME)
    }
    
    // MARK: - Test 7: Startup While in Foreign IME
    func test_07_startup_in_foreign_ime_auto_suspends_and_restores_on_abc() {
        let foreignMock = MockInputSourceManager(
            initialSourceID: "com.apple.inputmethod.Kotoeri.Japanese",
            initialSourceType: "TISTypeKeyboardInputMode",
            isForeign: true
        )
        let startupManager = AppStateManager(inputSourceManager: foreignMock)
        
        // On startup with foreign IME, VietFlow immediately suspends to .english
        XCTAssertEqual(startupManager.currentInputMode, .english)
        XCTAssertTrue(startupManager.isSuspendedByForeignIME)
        XCTAssertEqual(startupManager.savedPreForeignMode, .vietnamese)
        
        // Switching to ABC restores to .vietnamese
        foreignMock.simulateInputSourceChange(to: "com.apple.keylayout.ABC")
        XCTAssertEqual(startupManager.currentInputMode, .vietnamese)
        XCTAssertFalse(startupManager.isSuspendedByForeignIME)
    }
    
    // MARK: - Test 8: InputSourceClassifier Coverage
    func test_08_classifier_identifies_all_foreign_and_latin_sources() {
        // Latin layouts
        XCTAssertTrue(InputSourceClassifier.isLatinKeyboardLayout(sourceID: "com.apple.keylayout.ABC", sourceType: "TISTypeKeyboardLayout"))
        XCTAssertTrue(InputSourceClassifier.isLatinKeyboardLayout(sourceID: "com.apple.keylayout.US", sourceType: "TISTypeKeyboardLayout"))
        XCTAssertTrue(InputSourceClassifier.isLatinKeyboardLayout(sourceID: "com.apple.keylayout.British", sourceType: "TISTypeKeyboardLayout"))
        XCTAssertTrue(InputSourceClassifier.isLatinKeyboardLayout(sourceID: "com.apple.keylayout.Dvorak", sourceType: "TISTypeKeyboardLayout"))
        XCTAssertFalse(InputSourceClassifier.isForeignInputSource(sourceID: "com.apple.keylayout.ABC", sourceType: "TISTypeKeyboardLayout"))
        XCTAssertFalse(InputSourceClassifier.isForeignInputSource(sourceID: "com.apple.keylayout.US", sourceType: "TISTypeKeyboardLayout"))
        
        // Japanese IMEs
        XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: "com.apple.inputmethod.Kotoeri.Japanese"))
        XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese"))
        XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: "com.apple.inputmethod.Japanese"))
        XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: "com.google.inputmethod.Japanese.Roman"))
        XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: "com.justsystems.inputmethod.atok2023"))
        XCTAssertFalse(InputSourceClassifier.isLatinKeyboardLayout(sourceID: "com.apple.inputmethod.Kotoeri.Japanese"))
        
        // Chinese & Korean IMEs
        XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: "com.apple.inputmethod.SCIM"))
        XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: "com.apple.inputmethod.TCIM"))
        XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: "com.apple.inputmethod.Cangjie"))
        XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: "com.apple.inputmethod.Korean"))
        XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: "com.sogou.inputmethod.sogouinput"))
        
        // Input Method Type flag
        XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: "custom.foreign", sourceType: "TISTypeKeyboardInputMode"))
        XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: "custom.foreign", sourceType: "TISTypeKeyboardInputMethodModeEnabled"))
        
        // Third-party IMEs (Rime, Squirrel, Chewing, ATOK, Mozc, Wubi, Quick, Hanja)
        XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: "im.rime.inputmethod.Squirrel"))
        XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: "org.chewing.inputmethod.chewing"))
        XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: "com.justsystems.inputmethod.atok2023"))
        XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: "org.mozc.inputmethod.Japanese"))
        XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: "com.apple.inputmethod.wubixing"))
        XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: "com.apple.inputmethod.quick"))
        XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: "com.apple.inputmethod.Korean.Hanja"))
        
        // Non-Latin physical keyboard layouts must be classified as foreign and NOT Latin layouts
        let nonLatinSources = [
            "com.apple.keylayout.Russian",
            "com.apple.keylayout.Greek",
            "com.apple.keylayout.Arabic",
            "com.apple.keylayout.Hebrew",
            "com.apple.keylayout.Thai",
            "com.apple.keylayout.Hindi",
            "com.apple.keylayout.Ukrainian",
            "com.apple.keylayout.Bulgarian",
            "com.apple.keylayout.Persian"
        ]
        for source in nonLatinSources {
            XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: source, sourceType: "TISTypeKeyboardLayout"), "\(source) must be classified as foreign/non-Latin")
            XCTAssertFalse(InputSourceClassifier.isLatinKeyboardLayout(sourceID: source, sourceType: "TISTypeKeyboardLayout"), "\(source) must NOT be classified as Latin layout")
        }
        
        // Non-keyboard palette and utility sources must NOT be Latin keyboard layouts
        XCTAssertFalse(InputSourceClassifier.isLatinKeyboardLayout(sourceID: "com.apple.CharacterPaletteIM", sourceType: "TISTypeCharacterPalette"))
        XCTAssertFalse(InputSourceClassifier.isLatinKeyboardLayout(sourceID: "com.apple.PressAndHold", sourceType: "TISTypeCharacterPalette"))
        XCTAssertFalse(InputSourceClassifier.isLatinKeyboardLayout(sourceID: "", sourceType: ""))
        
        // Custom third-party Latin layouts (Colemak, Neo, Dvorak)
        XCTAssertTrue(InputSourceClassifier.isLatinKeyboardLayout(sourceID: "org.sil.ukelele.keyboardlayout.colemak.colemak", sourceType: "TISTypeKeyboardLayout"))
        XCTAssertTrue(InputSourceClassifier.isLatinKeyboardLayout(sourceID: "de.neo-layout.keyboardlayout.neo", sourceType: "TISTypeKeyboardLayout"))
        XCTAssertTrue(InputSourceClassifier.isLatinKeyboardLayout(sourceID: "com.custom.colemak", sourceType: ""))
        XCTAssertTrue(InputSourceClassifier.isLatinKeyboardLayout(sourceID: "my.custom.keyboardlayout.dvorak", sourceType: ""))
    }
    
    // MARK: - Test 9: Synchronous Polling in EventTapManager handleEvent
    func test_09_synchronous_polling_in_event_tap_manager() {
        stateManager.currentInputMode = .vietnamese
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        
        // Directly mutate mock state without notifying observers (simulates notification lag)
        mockSourceManager.currentInputSourceID = "com.apple.inputmethod.Kotoeri.Japanese"
        mockSourceManager.isCurrentSourceForeign = true
        
        // First key event arrives
        let event = createKeyDownEvent(character: "w")
        let handled = eventTapManager.handleEvent(type: .keyDown, event: event)
        
        // Synchronous check inside handleEvent must have caught the change!
        XCTAssertNotNil(handled, "Key 'w' must pass through untouched")
        XCTAssertEqual(stateManager.currentInputMode, .english, "Synchronous check must have updated state to .english")
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
    }
    
    // MARK: - Test 10: Per-App Mode Preservation Across Foreign IME Transitions
    func test_10_per_app_mode_preservation_across_foreign_ime_transitions() {
        stateManager.perAppInputMode = true
        
        // Notes is Vietnamese
        stateManager.handleActiveAppChanged(bundleId: "com.apple.Notes")
        stateManager.currentInputMode = .vietnamese
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        
        // Safari is English
        stateManager.handleActiveAppChanged(bundleId: "com.apple.Safari")
        stateManager.currentInputMode = .english
        XCTAssertEqual(stateManager.currentInputMode, .english)
        
        // While in Safari, macOS switches to Japanese IME -> auto-suspends to [E]
        mockSourceManager.simulateInputSourceChange(to: "com.apple.inputmethod.Kotoeri.Japanese")
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        
        // User switches to Notes while macOS is STILL on Japanese IME
        stateManager.handleActiveAppChanged(bundleId: "com.apple.Notes")
        XCTAssertEqual(stateManager.currentInputMode, .english, "Must remain .english while macOS is on Japanese IME")
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        
        // User switches macOS back to ABC while in Notes
        mockSourceManager.simulateInputSourceChange(to: "com.apple.keylayout.ABC")
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese, "Notes must restore to .vietnamese when returning to ABC")
        XCTAssertFalse(stateManager.isSuspendedByForeignIME)
        
        // User switches to Safari -> Safari must still have its saved English mode
        stateManager.handleActiveAppChanged(bundleId: "com.apple.Safari")
        XCTAssertEqual(stateManager.currentInputMode, .english, "Safari must preserve .english mode")
        
        // User switches back to Notes -> Notes must still be Vietnamese
        stateManager.handleActiveAppChanged(bundleId: "com.apple.Notes")
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese, "Notes must preserve .vietnamese mode")
    }
    
    // MARK: - Test 11: Palette and Utility Sources Rejection
    func test_11_palette_and_utility_sources_rejection() {
        XCTAssertFalse(InputSourceClassifier.isLatinKeyboardLayout(sourceID: "com.apple.CharacterPaletteIM", sourceType: "TISTypeCharacterPalette"))
        XCTAssertFalse(InputSourceClassifier.isLatinKeyboardLayout(sourceID: "com.apple.PressAndHold", sourceType: "TISTypeCharacterPalette"))
        XCTAssertFalse(InputSourceClassifier.isLatinKeyboardLayout(sourceID: "com.apple.ink.inkinputmethod", sourceType: "TISTypeInk"))
        XCTAssertFalse(InputSourceClassifier.isLatinKeyboardLayout(sourceID: "", sourceType: ""))
    }
    
    // MARK: - Test 12: Manual Mode Toggle Synchronously Queries Stale Input Source
    func test_12_manual_mode_toggle_synchronously_queries_stale_input_source() {
        stateManager.currentInputMode = .vietnamese
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        
        // Simulate notification latency: state was updated behind the scenes but no notification posted
        mockSourceManager.currentInputSourceID = "com.apple.inputmethod.Kotoeri.Japanese"
        mockSourceManager.isCurrentSourceForeign = true
        
        // User immediately triggers mode toggle
        stateManager.toggleInputMode()
        
        // toggleInputMode must have refreshed synchronously, detected Japanese, and called selectLatinInputSource()
        XCTAssertTrue(mockSourceManager.selectLatinCalled)
        XCTAssertEqual(mockSourceManager.currentInputSourceID, "com.apple.keylayout.ABC")
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        XCTAssertFalse(stateManager.isSuspendedByForeignIME)
    }
    
    // MARK: - Test 13: Non-Latin Layout Auto-Suspends and Restores
    func test_13_non_latin_layout_auto_suspends_and_restores() {
        stateManager.currentInputMode = .vietnamese
        _ = engine.processKey("v")
        _ = engine.processKey("i")
        XCTAssertFalse(engine.currentSyllable.isEmpty)
        
        // User switches macOS to Russian Cyrillic layout
        mockSourceManager.simulateInputSourceChange(to: "com.apple.keylayout.Russian", sourceType: "TISTypeKeyboardLayout")
        
        // Must auto-suspend to English, flush syllable buffer, and preserve saved Vietnamese mode
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        XCTAssertEqual(stateManager.savedPreForeignMode, .vietnamese)
        XCTAssertEqual(engine.currentSyllable, "")
        
        // Cyrillic keystrokes pass through untouched
        let event = createKeyDownEvent(character: "ф")
        let handled = eventTapManager.handleEvent(type: .keyDown, event: event)
        XCTAssertNotNil(handled)
        XCTAssertEqual(engine.currentSyllable, "")
        
        // User switches back to ABC Latin layout
        mockSourceManager.simulateInputSourceChange(to: "com.apple.keylayout.ABC", sourceType: "TISTypeKeyboardLayout")
        
        // VietFlow restores to Vietnamese
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        XCTAssertFalse(stateManager.isSuspendedByForeignIME)
        XCTAssertEqual(engine.currentSyllable, "")
    }
    
    // MARK: - Test 14: Settings UI Active Under Foreign IME Does Not Wipe Per-App Modes
    func test_14_settings_ui_active_under_foreign_ime_does_not_wipe_per_app_modes() {
        stateManager.perAppInputMode = true
        
        // Set Notes to Vietnamese and Safari to English
        stateManager.handleActiveAppChanged(bundleId: "com.apple.Notes")
        stateManager.currentInputMode = .vietnamese
        stateManager.handleActiveAppChanged(bundleId: "com.apple.Safari")
        stateManager.currentInputMode = .english
        
        // VietFlow Settings window is activated
        stateManager.handleActiveAppChanged(bundleId: "com.nhanqv.VietFlow")
        
        // macOS switches to Japanese IME while VietFlow Settings is open
        mockSourceManager.simulateInputSourceChange(to: "com.apple.inputmethod.Kotoeri.Japanese")
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        
        // Closing settings and switching back to Safari under Japanese IME
        stateManager.handleActiveAppChanged(bundleId: "com.apple.Safari")
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        
        // Returning to ABC restores Safari's saved English mode
        mockSourceManager.simulateInputSourceChange(to: "com.apple.keylayout.ABC")
        XCTAssertEqual(stateManager.currentInputMode, .english, "Safari must preserve its saved English mode")
        
        // Switching to Notes restores Notes' saved Vietnamese mode
        stateManager.handleActiveAppChanged(bundleId: "com.apple.Notes")
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese, "Notes must preserve its saved Vietnamese mode")
    }
    
    // MARK: - Test 15: One-Step Toggle From Japanese With Saved English Mode
    func test_15_one_step_toggle_from_japanese_with_saved_english_mode() {
        stateManager.perAppInputMode = true
        stateManager.handleActiveAppChanged(bundleId: "com.apple.Safari")
        stateManager.currentInputMode = .english
        XCTAssertEqual(stateManager.currentInputMode, .english)
        
        // Switch to Japanese IME
        mockSourceManager.simulateInputSourceChange(to: "com.apple.inputmethod.Kotoeri.Japanese")
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        
        // Trigger one-step manual toggle
        stateManager.toggleInputMode()
        
        // Must cleanly activate Vietnamese, update saved pre-foreign mode, and select Latin layout
        XCTAssertTrue(mockSourceManager.selectLatinCalled)
        XCTAssertEqual(mockSourceManager.currentInputSourceID, "com.apple.keylayout.ABC")
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        XCTAssertEqual(stateManager.savedPreForeignMode, .vietnamese)
        XCTAssertFalse(stateManager.isSuspendedByForeignIME)
        
        // Syllable buffer clean and ready for Vietnamese typing
        XCTAssertEqual(engine.currentSyllable, "")
    }
    
    // MARK: - Test 16: Disabled Auto Switch Bypasses Synchronous Refresh Overhead
    func test_16_disabled_auto_switch_bypasses_synchronous_refresh_overhead() {
        stateManager.autoSwitchOnForeignInputSource = false
        stateManager.currentInputMode = .vietnamese
        
        // Even if input source is mutated behind the scenes, checkInputSourceSynchronously returns early
        mockSourceManager.currentInputSourceID = "com.apple.inputmethod.Kotoeri.Japanese"
        mockSourceManager.isCurrentSourceForeign = true
        
        stateManager.checkInputSourceSynchronously()
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        XCTAssertFalse(stateManager.isSuspendedByForeignIME)
    }

    // MARK: - Test 17: Reset to Defaults Under Foreign IME Preserves Suspended State
    func test_17_reset_to_defaults_under_foreign_ime_preserves_suspended_state() {
        stateManager.currentInputMode = .vietnamese
        mockSourceManager.simulateInputSourceChange(to: "com.apple.inputmethod.Kotoeri.Japanese")
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        XCTAssertEqual(stateManager.savedPreForeignMode, .vietnamese)
        
        // User resets settings to defaults while system is still in Japanese IME
        stateManager.resetToDefaults()
        
        // Mode must remain .english, isSuspendedByForeignIME must remain true, and savedPreForeignMode must be .vietnamese
        XCTAssertEqual(stateManager.currentInputMode, .english, "Must remain suspended in .english when resetting while on Japanese IME")
        XCTAssertTrue(stateManager.isSuspendedByForeignIME, "isSuspendedByForeignIME must remain true")
        XCTAssertEqual(stateManager.savedPreForeignMode, .vietnamese, "savedPreForeignMode must be .vietnamese")
        
        // When system returns to ABC, mode restores to .vietnamese
        mockSourceManager.simulateInputSourceChange(to: "com.apple.keylayout.ABC")
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese, "Must restore to .vietnamese upon returning to ABC")
        XCTAssertFalse(stateManager.isSuspendedByForeignIME)
    }
    
    // MARK: - Test 18: One-Step Toggle Failure Rolls Back Safely
    func test_18_one_step_toggle_failure_rolls_back_safely() {
        stateManager.currentInputMode = .vietnamese
        mockSourceManager.simulateInputSourceChange(to: "com.apple.inputmethod.Kotoeri.Japanese")
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        
        // Simulate selectLatinInputSource failure (e.g. system permission or API error)
        mockSourceManager.shouldSelectLatinSucceed = false
        
        // User attempts manual toggle
        stateManager.toggleInputMode()
        
        // Must roll back to suspended .english mode instead of leaving an inconsistent state
        XCTAssertTrue(mockSourceManager.selectLatinCalled)
        XCTAssertEqual(stateManager.currentInputMode, .english, "Must roll back to .english when selectLatinInputSource fails")
        XCTAssertTrue(stateManager.isSuspendedByForeignIME, "isSuspendedByForeignIME must remain true")
        XCTAssertEqual(stateManager.savedPreForeignMode, .vietnamese)
    }
    
    // MARK: - Test 19: Switching Between Two Foreign IMEs Preserves Saved Mode
    func test_19_switching_between_two_foreign_imes_preserves_saved_mode() {
        stateManager.currentInputMode = .vietnamese
        
        // 1. ABC [V] -> Japanese [E]
        mockSourceManager.simulateInputSourceChange(to: "com.apple.inputmethod.Kotoeri.Japanese")
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        XCTAssertEqual(stateManager.savedPreForeignMode, .vietnamese)
        
        // 2. Japanese [E] -> Chinese SCIM [E] (foreign to foreign)
        mockSourceManager.simulateInputSourceChange(to: "com.apple.inputmethod.SCIM")
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        XCTAssertEqual(stateManager.savedPreForeignMode, .vietnamese, "Saved mode must not be overwritten when switching between foreign IMEs")
        
        // 3. Chinese SCIM [E] -> Korean [E]
        mockSourceManager.simulateInputSourceChange(to: "com.apple.inputmethod.Korean")
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        XCTAssertEqual(stateManager.savedPreForeignMode, .vietnamese)
        
        // 4. Korean [E] -> ABC
        mockSourceManager.simulateInputSourceChange(to: "com.apple.keylayout.ABC")
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese, "Must restore to .vietnamese when finally returning to ABC")
        XCTAssertFalse(stateManager.isSuspendedByForeignIME)
    }
    
    // MARK: - Test 20: Extended Non-Latin Layouts and Third-Party IMEs Classifier
    func test_20_extended_non_latin_layouts_and_third_party_imes_classifier() {
        let nonLatin = [
            "com.apple.keylayout.Kazakh",
            "com.apple.keylayout.Mongolian",
            "com.apple.keylayout.Uyghur",
            "com.apple.keylayout.Yiddish",
            "com.apple.keylayout.Punjabi",
            "com.apple.keylayout.Odia",
            "com.apple.keylayout.Assamese",
            "com.apple.keylayout.Amharic"
        ]
        for src in nonLatin {
            XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: src, sourceType: "TISTypeKeyboardLayout"))
            XCTAssertFalse(InputSourceClassifier.isLatinKeyboardLayout(sourceID: src, sourceType: "TISTypeKeyboardLayout"))
        }
        
        // Gureum Korean IME, AquaSKK, Dayi
        XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: "org.youknowone.Gureum"))
        XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: "jp.sourceforge.inputmethod.aquaskk"))
        XCTAssertTrue(InputSourceClassifier.isForeignInputSource(sourceID: "com.apple.inputmethod.Dayi"))
        
        // Alternative Latin layouts (Workman, Bepo, Halmak, Norman)
        XCTAssertTrue(InputSourceClassifier.isLatinKeyboardLayout(sourceID: "org.sil.ukelele.keyboardlayout.workman.workman"))
        XCTAssertTrue(InputSourceClassifier.isLatinKeyboardLayout(sourceID: "fr.bepo.keyboardlayout.bepo"))
        XCTAssertTrue(InputSourceClassifier.isLatinKeyboardLayout(sourceID: "com.custom.halmak"))
        XCTAssertTrue(InputSourceClassifier.isLatinKeyboardLayout(sourceID: "com.custom.norman"))
    }
    
    // MARK: - Test 21: Transient Nil Source Does Not Clear Cached Source ID
    func test_21_transient_nil_source_does_not_clear_cached_source_id() {
        XCTAssertFalse(mockSourceManager.currentInputSourceID.isEmpty)
        let initialID = mockSourceManager.currentInputSourceID
        let (refreshedID, _) = mockSourceManager.refreshCurrentInputSource()
        XCTAssertEqual(refreshedID, initialID)
    }

    // MARK: - Test 22: Bidirectional Foreign IME Memory Toggle Ping-Pong
    func test_22_bidirectional_foreign_ime_memory_toggle_ping_pong() {
        // Start in Japanese IME: auto-suspended to [E]
        mockSourceManager.simulateInputSourceChange(to: "com.apple.inputmethod.Kotoeri.Japanese")
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        XCTAssertNil(stateManager.rememberedForeignSourceID)
        
        // 1st toggle: from Japanese [E] -> ABC [V]
        stateManager.toggleInputMode()
        
        XCTAssertTrue(mockSourceManager.selectLatinCalled)
        XCTAssertEqual(mockSourceManager.currentInputSourceID, "com.apple.keylayout.ABC")
        XCTAssertFalse(mockSourceManager.isCurrentSourceForeign)
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        XCTAssertFalse(stateManager.isSuspendedByForeignIME)
        XCTAssertEqual(stateManager.rememberedForeignSourceID, "com.apple.inputmethod.Kotoeri.Japanese")
        
        // 2nd toggle: from ABC [V] -> restores Japanese [E]
        stateManager.toggleInputMode()
        
        XCTAssertEqual(mockSourceManager.selectInputSourceCalledWithID, "com.apple.inputmethod.Kotoeri.Japanese")
        XCTAssertEqual(mockSourceManager.selectInputSourceCallCount, 1)
        XCTAssertEqual(mockSourceManager.currentInputSourceID, "com.apple.inputmethod.Kotoeri.Japanese")
        XCTAssertTrue(mockSourceManager.isCurrentSourceForeign)
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        XCTAssertEqual(stateManager.savedPreForeignMode, .vietnamese)
        XCTAssertNil(stateManager.rememberedForeignSourceID)
        
        // 3rd toggle: from Japanese [E] -> ABC [V] (infinite ping-pong)
        stateManager.toggleInputMode()
        
        XCTAssertEqual(mockSourceManager.currentInputSourceID, "com.apple.keylayout.ABC")
        XCTAssertFalse(mockSourceManager.isCurrentSourceForeign)
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        XCTAssertFalse(stateManager.isSuspendedByForeignIME)
        XCTAssertEqual(stateManager.rememberedForeignSourceID, "com.apple.inputmethod.Kotoeri.Japanese")
        
        // 4th toggle: from ABC [V] -> restores Japanese [E] again
        stateManager.toggleInputMode()
        
        XCTAssertEqual(mockSourceManager.selectInputSourceCallCount, 2)
        XCTAssertEqual(mockSourceManager.currentInputSourceID, "com.apple.inputmethod.Kotoeri.Japanese")
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        XCTAssertNil(stateManager.rememberedForeignSourceID)
    }

    // MARK: - Test 23: Normal ABC Toggle Unaffected When No Foreign Source Remembered
    func test_23_normal_abc_toggle_unaffected_when_no_foreign_source_remembered() {
        // Start in standard ABC Latin layout
        mockSourceManager.simulateInputSourceChange(to: "com.apple.keylayout.ABC")
        stateManager.currentInputMode = .vietnamese
        XCTAssertNil(stateManager.rememberedForeignSourceID)
        
        // Toggle OFF Vietnamese -> switches to English
        stateManager.toggleInputMode()
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertFalse(stateManager.isSuspendedByForeignIME)
        XCTAssertEqual(mockSourceManager.selectInputSourceCallCount, 0, "selectInputSource must not be called when no foreign source is remembered")
        XCTAssertEqual(mockSourceManager.currentInputSourceID, "com.apple.keylayout.ABC")
        
        // Toggle ON Vietnamese -> switches to Vietnamese
        stateManager.toggleInputMode()
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        XCTAssertFalse(stateManager.isSuspendedByForeignIME)
        XCTAssertEqual(mockSourceManager.selectInputSourceCallCount, 0)
        XCTAssertEqual(mockSourceManager.currentInputSourceID, "com.apple.keylayout.ABC")
    }

    // MARK: - Test 24: Manual Input Source Change Outside Toggle Clears Remembered Foreign Source
    func test_24_manual_input_source_change_outside_toggle_clears_remembered_foreign_source() {
        // Switch to Japanese, then toggle to Vietnamese
        mockSourceManager.simulateInputSourceChange(to: "com.apple.inputmethod.Kotoeri.Japanese")
        stateManager.toggleInputMode()
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        XCTAssertEqual(stateManager.rememberedForeignSourceID, "com.apple.inputmethod.Kotoeri.Japanese")
        
        // User manually changes input source in macOS outside of toggle (e.g. to US layout)
        mockSourceManager.simulateInputSourceChange(to: "com.apple.keylayout.US")
        
        // Remembered foreign source must be cleared
        XCTAssertNil(stateManager.rememberedForeignSourceID, "Manual input source change outside toggle must clear rememberedForeignSourceID")
        
        // Subsequent toggle now performs normal Vietnamese -> English toggle
        stateManager.toggleInputMode()
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertEqual(mockSourceManager.selectInputSourceCallCount, 0)
    }

    // MARK: - Test 25: Foreign Restore Failure Falls Back to Standard English Mode
    func test_25_foreign_restore_failure_falls_back_to_standard_english_mode() {
        mockSourceManager.simulateInputSourceChange(to: "com.apple.inputmethod.Kotoeri.Japanese")
        stateManager.toggleInputMode()
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        XCTAssertEqual(stateManager.rememberedForeignSourceID, "com.apple.inputmethod.Kotoeri.Japanese")
        
        // Simulate failure in selecting foreign input source
        mockSourceManager.shouldSelectForeignSucceed = false
        
        // Toggle OFF Vietnamese
        stateManager.toggleInputMode()
        
        // Must call selectInputSource, fail, and gracefully fall back to English
        XCTAssertEqual(mockSourceManager.selectInputSourceCalledWithID, "com.apple.inputmethod.Kotoeri.Japanese")
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertNil(stateManager.rememberedForeignSourceID)
    }

    // MARK: - Test 26: EventTapManager Synchronous Ping-Pong Toggle
    func test_26_event_tap_manager_synchronous_ping_pong_toggle() {
        mockSourceManager.simulateInputSourceChange(to: "com.apple.inputmethod.Kotoeri.Japanese")
        XCTAssertEqual(stateManager.currentInputMode, .english)
        
        // Trigger toggle via EventTapManager
        eventTapManager.toggleModeSynchronously()
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        XCTAssertEqual(mockSourceManager.currentInputSourceID, "com.apple.keylayout.ABC")
        XCTAssertEqual(stateManager.rememberedForeignSourceID, "com.apple.inputmethod.Kotoeri.Japanese")
        
        // Trigger toggle again via EventTapManager
        eventTapManager.toggleModeSynchronously()
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertEqual(mockSourceManager.currentInputSourceID, "com.apple.inputmethod.Kotoeri.Japanese")
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        XCTAssertNil(stateManager.rememberedForeignSourceID)
    }

    // MARK: - Test 27: Japanese Romaji Typing Toggle, Typing Words Preserves Foreign Source and Restores Japanese
    func test_27_japanese_romaji_typing_toggle_typing_words_preserves_foreign_source_and_restores_japanese() {
        let japaneseID = "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese"
        mockSourceManager.simulateInputSourceChange(to: japaneseID)
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        XCTAssertNil(stateManager.rememberedForeignSourceID)
        
        // --- Cycle 1 ---
        // 1. Toggle ON: switches to ABC and [V] and remembers Japanese
        eventTapManager.toggleModeSynchronously()
        XCTAssertTrue(mockSourceManager.selectLatinCalled)
        XCTAssertEqual(mockSourceManager.currentInputSourceID, "com.apple.keylayout.ABC")
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        XCTAssertFalse(stateManager.isSuspendedByForeignIME)
        XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        
        // 2. Late/duplicate notification from macOS RunLoop must not clear rememberedForeignSourceID
        mockSourceManager.onInputSourceChanged?("com.apple.keylayout.ABC", false)
        XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        
        // 3. Type Vietnamese words "xin chào các bạn " through EventTapManager.handleEvent
        // In Telex: x-i-n-space, c-h-a-o-f-space, c-a-c-s-space, b-a-n-j-space
        let wordsKeystrokes = "xin chaof cacs banj "
        for ch in wordsKeystrokes {
            let event = createKeyDownEvent(character: ch)
            _ = eventTapManager.handleEvent(type: .keyDown, event: event)
            XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID,
                           "Typing character '\(ch)' must preserve rememberedForeignSourceID")
            XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        }
        
        // 4. Press Backspace multiple times
        for _ in 0..<3 {
            let backspaceEvent = createBackspaceEvent()
            _ = eventTapManager.handleEvent(type: .keyDown, event: backspaceEvent)
            XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID,
                           "Backspace must preserve rememberedForeignSourceID")
        }
        
        // 5. Switching active applications must preserve rememberedForeignSourceID
        stateManager.handleActiveAppChanged(bundleId: "com.apple.Safari", appName: "Safari")
        XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID,
                       "App switch to Safari must preserve rememberedForeignSourceID")
        
        stateManager.handleActiveAppChanged(bundleId: "com.apple.Notes", appName: "Notes")
        XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID,
                       "App switch to Notes must preserve rememberedForeignSourceID")
        
        // 6. Type another word in Notes
        let moreKeystrokes = "vieetj "
        for ch in moreKeystrokes {
            let event = createKeyDownEvent(character: ch)
            _ = eventTapManager.handleEvent(type: .keyDown, event: event)
            XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        }
        
        // 7. Toggle OFF: reliably restores Japanese input source
        eventTapManager.toggleModeSynchronously()
        XCTAssertEqual(mockSourceManager.selectInputSourceCalledWithID, japaneseID)
        XCTAssertEqual(mockSourceManager.currentInputSourceID, japaneseID)
        XCTAssertTrue(mockSourceManager.isCurrentSourceForeign)
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        XCTAssertNil(stateManager.rememberedForeignSourceID)
        
        // --- Cycle 2 ---
        eventTapManager.toggleModeSynchronously()
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        
        let cycle2Keys = "thaafnh coong "
        for ch in cycle2Keys {
            let event = createKeyDownEvent(character: ch)
            _ = eventTapManager.handleEvent(type: .keyDown, event: event)
            XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        }
        
        eventTapManager.toggleModeSynchronously()
        XCTAssertEqual(mockSourceManager.selectInputSourceCalledWithID, japaneseID)
        XCTAssertEqual(mockSourceManager.currentInputSourceID, japaneseID)
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        XCTAssertNil(stateManager.rememberedForeignSourceID)
        
        // --- Cycle 3 ---
        eventTapManager.toggleModeSynchronously()
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        
        stateManager.handleActiveAppChanged(bundleId: "com.google.Chrome", appName: "Chrome")
        XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        
        eventTapManager.toggleModeSynchronously()
        XCTAssertEqual(mockSourceManager.selectInputSourceCalledWithID, japaneseID)
        XCTAssertEqual(mockSourceManager.currentInputSourceID, japaneseID)
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        XCTAssertNil(stateManager.rememberedForeignSourceID)
    }

    // MARK: - Test 28: Delayed TIS Notification Does Not Clear Remembered Foreign Source or Revert Mode
    func test_28_delayed_tis_notification_does_not_clear_remembered_foreign_source_or_revert_mode() {
        let japaneseID = "com.apple.inputmethod.Kotoeri.Japanese"
        mockSourceManager.simulateInputSourceChange(to: japaneseID)
        XCTAssertEqual(stateManager.currentInputMode, .english)
        
        // Toggle ON to Vietnamese
        stateManager.toggleInputMode()
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        
        // Simulate repeated delayed/duplicate TIS notifications on main RunLoop
        for _ in 0..<5 {
            mockSourceManager.onInputSourceChanged?("com.apple.keylayout.ABC", false)
            XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID,
                           "Delayed notification for ABC must not clear rememberedForeignSourceID")
            XCTAssertEqual(stateManager.currentInputMode, .vietnamese,
                           "Delayed notification for ABC must not revert input mode")
        }
        
        // Synchronous polling must also be a safe no-op
        for _ in 0..<5 {
            stateManager.checkInputSourceSynchronously()
            XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID,
                           "Synchronous polling must not clear rememberedForeignSourceID")
            XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        }
        
        // Toggle OFF successfully restores Japanese
        stateManager.toggleInputMode()
        XCTAssertEqual(mockSourceManager.selectInputSourceCalledWithID, japaneseID)
        XCTAssertEqual(mockSourceManager.currentInputSourceID, japaneseID)
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        XCTAssertNil(stateManager.rememberedForeignSourceID)
    }

    // MARK: - Test 29: Manual Different Latin Switch Clears Remembered Foreign Source Even After Typing
    func test_29_manual_different_latin_switch_clears_remembered_foreign_source_even_after_typing() {
        let japaneseID = "com.apple.inputmethod.Kotoeri.Japanese"
        mockSourceManager.simulateInputSourceChange(to: japaneseID)
        
        // Toggle ON to Vietnamese
        stateManager.toggleInputMode()
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        
        // Type some words
        let keys = "xinchao "
        for ch in keys {
            let event = createKeyDownEvent(character: ch)
            _ = eventTapManager.handleEvent(type: .keyDown, event: event)
            XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        }
        
        let selectCountBefore = mockSourceManager.selectInputSourceCallCount
        
        // User manually switches to a different Latin layout (e.g. US) outside of toggle
        mockSourceManager.simulateInputSourceChange(to: "com.apple.keylayout.US")
        
        // Remembered foreign source MUST be cleared
        XCTAssertNil(stateManager.rememberedForeignSourceID,
                     "Manual switch to different Latin layout US must clear rememberedForeignSourceID")
        
        // Subsequent toggle now performs standard Vietnamese -> English toggle (no Japanese restore)
        stateManager.toggleInputMode()
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertEqual(mockSourceManager.selectInputSourceCallCount, selectCountBefore,
                       "selectInputSource must not be called when foreign source was cleared")
    }

    // MARK: - Test 30: Per-App Mode With Foreign IME Restore and Cross-App Typing
    func test_30_per_app_mode_with_foreign_ime_restore_and_cross_app_typing() {
        stateManager.perAppInputMode = true
        let japaneseID = "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese"
        mockSourceManager.simulateInputSourceChange(to: japaneseID)
        
        // Active in Safari
        stateManager.handleActiveAppChanged(bundleId: "com.apple.Safari", appName: "Safari")
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        XCTAssertNil(stateManager.rememberedForeignSourceID)
        
        // Toggle ON to Vietnamese in Safari
        eventTapManager.toggleModeSynchronously()
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        XCTAssertEqual(mockSourceManager.currentInputSourceID, "com.apple.keylayout.ABC")
        
        // Type in Safari
        let safariKeys = "xinchao "
        for ch in safariKeys {
            let event = createKeyDownEvent(character: ch)
            _ = eventTapManager.handleEvent(type: .keyDown, event: event)
            XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        }
        
        // Switch to Notes
        stateManager.handleActiveAppChanged(bundleId: "com.apple.Notes", appName: "Notes")
        XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        
        // Type in Notes
        let notesKeys = "vietflow "
        for ch in notesKeys {
            let event = createKeyDownEvent(character: ch)
            _ = eventTapManager.handleEvent(type: .keyDown, event: event)
            XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        }
        
        // Switch back to Safari
        stateManager.handleActiveAppChanged(bundleId: "com.apple.Safari", appName: "Safari")
        XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        
        // Toggle OFF in Safari: restores Japanese!
        eventTapManager.toggleModeSynchronously()
        XCTAssertEqual(mockSourceManager.selectInputSourceCalledWithID, japaneseID)
        XCTAssertEqual(mockSourceManager.currentInputSourceID, japaneseID)
        XCTAssertTrue(mockSourceManager.isCurrentSourceForeign)
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        XCTAssertNil(stateManager.rememberedForeignSourceID)
    }

    // MARK: - Test 31: Multiple Foreign IMEs and Non-Latin Layouts Bidirectional Restore
    func test_31_multiple_foreign_imes_and_non_latin_layouts_bidirectional_restore() {
        // 1. Russian Cyrillic physical keyboard layout
        let russianID = "com.apple.keylayout.Russian"
        mockSourceManager.simulateInputSourceChange(to: russianID)
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        
        eventTapManager.toggleModeSynchronously()
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        XCTAssertEqual(stateManager.rememberedForeignSourceID, russianID)
        XCTAssertEqual(mockSourceManager.currentInputSourceID, "com.apple.keylayout.ABC")
        
        let keys1 = "tiengviet "
        for ch in keys1 {
            let event = createKeyDownEvent(character: ch)
            _ = eventTapManager.handleEvent(type: .keyDown, event: event)
            XCTAssertEqual(stateManager.rememberedForeignSourceID, russianID)
        }
        
        eventTapManager.toggleModeSynchronously()
        XCTAssertEqual(mockSourceManager.selectInputSourceCalledWithID, russianID)
        XCTAssertEqual(mockSourceManager.currentInputSourceID, russianID)
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertNil(stateManager.rememberedForeignSourceID)
        
        // 2. Korean 2-Set Hangul IME
        let koreanID = "com.apple.inputmethod.Korean.2SetKorean"
        mockSourceManager.simulateInputSourceChange(to: koreanID)
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        
        eventTapManager.toggleModeSynchronously()
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        XCTAssertEqual(stateManager.rememberedForeignSourceID, koreanID)
        
        let keys2 = "hanoi "
        for ch in keys2 {
            let event = createKeyDownEvent(character: ch)
            _ = eventTapManager.handleEvent(type: .keyDown, event: event)
            XCTAssertEqual(stateManager.rememberedForeignSourceID, koreanID)
        }
        
        eventTapManager.toggleModeSynchronously()
        XCTAssertEqual(mockSourceManager.selectInputSourceCalledWithID, koreanID)
        XCTAssertEqual(mockSourceManager.currentInputSourceID, koreanID)
        XCTAssertNil(stateManager.rememberedForeignSourceID)
        
        // 3. Traditional Chinese Zhuyin IME
        let tcimID = "com.apple.inputmethod.TCIM.Zhuyin"
        mockSourceManager.simulateInputSourceChange(to: tcimID)
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        
        eventTapManager.toggleModeSynchronously()
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        XCTAssertEqual(stateManager.rememberedForeignSourceID, tcimID)
        
        eventTapManager.toggleModeSynchronously()
        XCTAssertEqual(mockSourceManager.selectInputSourceCalledWithID, tcimID)
        XCTAssertEqual(mockSourceManager.currentInputSourceID, tcimID)
        XCTAssertNil(stateManager.rememberedForeignSourceID)
    }

    // MARK: - Test 32: Rapid Toggle Interleaved With Typing and Delayed TIS Notifications
    func test_32_rapid_toggle_interleaved_with_typing_and_delayed_tis_notifications() {
        let japaneseID = "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese"
        mockSourceManager.simulateInputSourceChange(to: japaneseID)
        
        for _ in 0..<5 {
            // Rapid toggle ON
            eventTapManager.toggleModeSynchronously()
            XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
            XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
            
            // Late notification for ABC
            mockSourceManager.onInputSourceChanged?("com.apple.keylayout.ABC", false)
            XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
            XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
            
            // Keystroke
            let event1 = createKeyDownEvent(character: "a")
            _ = eventTapManager.handleEvent(type: .keyDown, event: event1)
            XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
            
            // Rapid toggle OFF
            eventTapManager.toggleModeSynchronously()
            XCTAssertEqual(stateManager.currentInputMode, .english)
            XCTAssertEqual(mockSourceManager.currentInputSourceID, japaneseID)
            XCTAssertNil(stateManager.rememberedForeignSourceID)
            
            // Late notification for Japanese
            mockSourceManager.onInputSourceChanged?(japaneseID, true)
            XCTAssertEqual(stateManager.currentInputMode, .english)
            XCTAssertTrue(stateManager.isSuspendedByForeignIME)
            XCTAssertNil(stateManager.rememberedForeignSourceID)
        }
    }

    // MARK: - Test 33: Non-ABC Target Latin Layout (US Layout) Preserves Foreign Source
    func test_33_non_abc_target_latin_layout_preserves_foreign_source() {
        mockSourceManager.defaultLatinSourceID = "com.apple.keylayout.US"
        let japaneseID = "com.apple.inputmethod.Kotoeri.Japanese"
        mockSourceManager.simulateInputSourceChange(to: japaneseID)
        
        // Toggle ON: selects US layout instead of ABC
        eventTapManager.toggleModeSynchronously()
        XCTAssertEqual(mockSourceManager.currentInputSourceID, "com.apple.keylayout.US")
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        
        // Delayed notification for US layout must not clear rememberedForeignSourceID
        mockSourceManager.onInputSourceChanged?("com.apple.keylayout.US", false)
        XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        
        // Keystrokes must preserve rememberedForeignSourceID
        let keys = "vietnam "
        for ch in keys {
            let event = createKeyDownEvent(character: ch)
            _ = eventTapManager.handleEvent(type: .keyDown, event: event)
            XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        }
        
        // Toggle OFF: restores Japanese
        eventTapManager.toggleModeSynchronously()
        XCTAssertEqual(mockSourceManager.selectInputSourceCalledWithID, japaneseID)
        XCTAssertEqual(mockSourceManager.currentInputSourceID, japaneseID)
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertNil(stateManager.rememberedForeignSourceID)
    }

    // MARK: - Test 34: Setting autoSwitchOnForeignInputSource to False Clears Remembered Foreign Source
    func test_34_setting_auto_switch_on_foreign_input_source_to_false_clears_remembered_foreign_source() {
        let japaneseID = "com.apple.inputmethod.Kotoeri.Japanese"
        mockSourceManager.simulateInputSourceChange(to: japaneseID)
        
        // Toggle ON to Vietnamese
        stateManager.toggleInputMode()
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        
        // User turns OFF autoSwitchOnForeignInputSource in settings
        stateManager.autoSwitchOnForeignInputSource = false
        XCTAssertNil(stateManager.rememberedForeignSourceID,
                     "Disabling autoSwitchOnForeignInputSource must clear rememberedForeignSourceID")
        
        // Subsequent toggle performs standard Vietnamese -> English toggle without restoring Japanese
        let countBefore = mockSourceManager.selectInputSourceCallCount
        stateManager.toggleInputMode()
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertEqual(mockSourceManager.selectInputSourceCallCount, countBefore,
                       "selectInputSource must not be called when auto-switch is disabled")
    }

    // MARK: - Test 35: Asynchronous Selection Delay Where System Temporarily Returns Japanese Before ABC
    func test_35_asynchronous_delay_where_system_temporarily_returns_japanese_before_abc_typing_words_preserves_foreign_memory() {
        let japaneseID = "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese"
        mockSourceManager.simulateInputSourceChange(to: japaneseID)
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        
        // Enable asynchronous delay simulation: selectLatinInputSource succeeds but does NOT immediately update mock's source ID
        mockSourceManager.simulateAsyncSelectionDelay = true
        
        // Toggle ON to Vietnamese
        eventTapManager.toggleModeSynchronously()
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        // System source is still Japanese during the delay window
        XCTAssertEqual(mockSourceManager.currentInputSourceID, japaneseID)
        
        // User types words while system source still temporarily reports Japanese
        // EventTapManager calls checkInputSourceSynchronously on every keystroke
        let words = "xin chaof "
        for ch in words {
            let event = createKeyDownEvent(character: ch)
            _ = eventTapManager.handleEvent(type: .keyDown, event: event)
            XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID,
                           "Synchronous check while system still reports Japanese must NOT clear rememberedForeignSourceID")
            XCTAssertEqual(stateManager.currentInputMode, .vietnamese,
                           "Typing character '\(ch)' must stay in Vietnamese mode")
        }
        
        // macOS finally finishes switching to ABC
        mockSourceManager.flushPendingInputSourceChange()
        XCTAssertEqual(mockSourceManager.currentInputSourceID, "com.apple.keylayout.ABC")
        
        // Delayed TIS notification for ABC arrives
        mockSourceManager.onInputSourceChanged?("com.apple.keylayout.ABC", false)
        XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        
        // Type more words in ABC mode
        let moreWords = "cacs banj "
        for ch in moreWords {
            let event = createKeyDownEvent(character: ch)
            _ = eventTapManager.handleEvent(type: .keyDown, event: event)
            XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        }
        
        // Backspace
        let bs = createBackspaceEvent()
        _ = eventTapManager.handleEvent(type: .keyDown, event: bs)
        XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        
        // Toggle OFF: restores Japanese
        eventTapManager.toggleModeSynchronously()
        XCTAssertEqual(mockSourceManager.selectInputSourceCalledWithID, japaneseID)
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        
        // Delayed notification for ABC arriving after toggle OFF must NOT revert mode back to Vietnamese
        mockSourceManager.onInputSourceChanged?("com.apple.keylayout.ABC", false)
        XCTAssertEqual(stateManager.currentInputMode, .english,
                       "Delayed Latin notification after toggle OFF must not re-activate Vietnamese")
        
        // Flush pending Japanese selection
        mockSourceManager.flushPendingInputSourceChange()
        XCTAssertEqual(mockSourceManager.currentInputSourceID, japaneseID)
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        XCTAssertNil(stateManager.rememberedForeignSourceID)
    }

    // MARK: - Test 36: Late Foreign Notification Arriving After Toggle Does Not Suspend Or Wipe Memory
    func test_36_late_foreign_notification_arriving_after_toggle_does_not_suspend_or_wipe_memory() {
        let japaneseID = "com.apple.inputmethod.Kotoeri.Japanese"
        mockSourceManager.simulateInputSourceChange(to: japaneseID)
        
        // Toggle ON to Vietnamese
        eventTapManager.toggleModeSynchronously()
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        
        // Stale late notification for Japanese arriving on main RunLoop after toggle
        mockSourceManager.onInputSourceChanged?(japaneseID, true)
        XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID,
                       "Late Japanese notification must not clear rememberedForeignSourceID")
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese,
                       "Late Japanese notification must not revert input mode to English")
        XCTAssertFalse(stateManager.isSuspendedByForeignIME)
        
        // Typing works and preserves memory
        let event = createKeyDownEvent(character: "a")
        _ = eventTapManager.handleEvent(type: .keyDown, event: event)
        XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        
        // Toggle OFF restores Japanese
        eventTapManager.toggleModeSynchronously()
        XCTAssertEqual(mockSourceManager.selectInputSourceCalledWithID, japaneseID)
        XCTAssertEqual(mockSourceManager.currentInputSourceID, japaneseID)
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        XCTAssertNil(stateManager.rememberedForeignSourceID)
    }

    // MARK: - Test 37: Cross-App Switching With Async Selection Delay Preserves Foreign Memory
    func test_37_cross_app_switching_with_async_delay_preserves_foreign_memory() {
        let japaneseID = "com.apple.inputmethod.Kotoeri.Japanese"
        mockSourceManager.simulateInputSourceChange(to: japaneseID)
        mockSourceManager.simulateAsyncSelectionDelay = true
        
        // Toggle ON to Vietnamese
        eventTapManager.toggleModeSynchronously()
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        
        // App switch to Safari while system source is still temporarily reported as Japanese
        stateManager.handleActiveAppChanged(bundleId: "com.apple.Safari", appName: "Safari")
        XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID,
                       "App switch during async delay must preserve rememberedForeignSourceID")
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese,
                       "App switch during async delay must stay in Vietnamese")
        
        // App switch to Notes
        stateManager.handleActiveAppChanged(bundleId: "com.apple.Notes", appName: "Notes")
        XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        
        // Flush pending switch to ABC
        mockSourceManager.flushPendingInputSourceChange()
        XCTAssertEqual(mockSourceManager.currentInputSourceID, "com.apple.keylayout.ABC")
        
        // Toggle OFF restores Japanese
        eventTapManager.toggleModeSynchronously()
        XCTAssertEqual(mockSourceManager.selectInputSourceCalledWithID, japaneseID)
        mockSourceManager.flushPendingInputSourceChange()
        XCTAssertEqual(mockSourceManager.currentInputSourceID, japaneseID)
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        XCTAssertNil(stateManager.rememberedForeignSourceID)
    }

    // MARK: - Test 38: Non-ABC Latin Layout With Async Delay Preserves Foreign Memory
    func test_38_non_abc_latin_layout_with_async_delay_preserves_foreign_memory() {
        let usLayoutID = "com.apple.keylayout.US"
        let japaneseID = "com.apple.inputmethod.Kotoeri.Japanese"
        mockSourceManager.defaultLatinSourceID = usLayoutID
        mockSourceManager.simulateInputSourceChange(to: japaneseID)
        mockSourceManager.simulateAsyncSelectionDelay = true
        
        // Toggle ON: initiates async switch to US layout
        eventTapManager.toggleModeSynchronously()
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        
        // Keystroke during async delay while system still reports Japanese
        let eventA = createKeyDownEvent(character: "a")
        _ = eventTapManager.handleEvent(type: .keyDown, event: eventA)
        XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        
        // WindowServer completes switch to US layout
        mockSourceManager.flushPendingInputSourceChange()
        XCTAssertEqual(mockSourceManager.currentInputSourceID, usLayoutID)
        XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID,
                       "Completion of async switch to non-ABC Latin layout must preserve rememberedForeignSourceID")
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        
        // Type words on US layout
        let words = "xin chaof "
        for ch in words {
            let event = createKeyDownEvent(character: ch)
            _ = eventTapManager.handleEvent(type: .keyDown, event: event)
            XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        }
        
        // Toggle OFF: restores Japanese
        eventTapManager.toggleModeSynchronously()
        XCTAssertEqual(mockSourceManager.selectInputSourceCalledWithID, japaneseID)
        mockSourceManager.flushPendingInputSourceChange()
        XCTAssertEqual(mockSourceManager.currentInputSourceID, japaneseID)
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        XCTAssertNil(stateManager.rememberedForeignSourceID)
    }

    // MARK: - Test 39: Manual Switch To Same Foreign IME After Typing Suspends VietFlow
    func test_39_manual_switch_to_same_foreign_ime_after_typing_suspends_vietflow() {
        let japaneseID = "com.apple.inputmethod.Kotoeri.Japanese"
        mockSourceManager.simulateInputSourceChange(to: japaneseID)
        
        // Toggle ON to Vietnamese
        eventTapManager.toggleModeSynchronously()
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        
        // Type Vietnamese word
        let keys = "chao "
        for ch in keys {
            let event = createKeyDownEvent(character: ch)
            _ = eventTapManager.handleEvent(type: .keyDown, event: event)
            XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
            XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        }
        
        // User manually switches back to Japanese via macOS menu bar outside VietFlow toggle
        mockSourceManager.simulateInputSourceChange(to: japaneseID)
        
        // VietFlow must suspend to English so Japanese IME is not corrupted
        XCTAssertTrue(stateManager.isSuspendedByForeignIME,
                      "Manual switch to Japanese after typing must suspend VietFlow")
        XCTAssertEqual(stateManager.currentInputMode, .english,
                      "Input mode must switch to English when foreign IME is manually selected")
        
        // Keystroke in Japanese mode must remain unintercepted
        let jpKey = createKeyDownEvent(character: "k")
        _ = eventTapManager.handleEvent(type: .keyDown, event: jpKey)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        XCTAssertEqual(stateManager.currentInputMode, .english)
        
        // User toggles ON again: switches to ABC and activates Vietnamese
        eventTapManager.toggleModeSynchronously()
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        XCTAssertFalse(stateManager.isSuspendedByForeignIME)
        
        // User toggles OFF: restores Japanese
        eventTapManager.toggleModeSynchronously()
        XCTAssertEqual(mockSourceManager.selectInputSourceCalledWithID, japaneseID)
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        XCTAssertNil(stateManager.rememberedForeignSourceID)
    }

    // MARK: - Test 40: App Switch To Foreign IME App After Typing Suspends VietFlow
    func test_40_app_switch_to_foreign_ime_app_after_typing_suspends_vietflow() {
        let japaneseID = "com.apple.inputmethod.Kotoeri.Japanese"
        mockSourceManager.simulateInputSourceChange(to: japaneseID)
        
        // Toggle ON in Safari
        stateManager.handleActiveAppChanged(bundleId: "com.apple.Safari", appName: "Safari")
        eventTapManager.toggleModeSynchronously()
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        
        // Type in Safari
        let keys = "viet "
        for ch in keys {
            let event = createKeyDownEvent(character: ch)
            _ = eventTapManager.handleEvent(type: .keyDown, event: event)
        }
        
        // Switch to Dictionary app where macOS input source is Japanese
        mockSourceManager.simulateInputSourceChange(to: japaneseID)
        stateManager.handleActiveAppChanged(bundleId: "com.apple.Dictionary", appName: "Dictionary")
        
        XCTAssertTrue(stateManager.isSuspendedByForeignIME,
                      "Switching to app with active Japanese IME must suspend VietFlow")
        XCTAssertEqual(stateManager.currentInputMode, .english)
        
        // Switch back to Safari where macOS input source is ABC
        mockSourceManager.simulateInputSourceChange(to: "com.apple.keylayout.ABC")
        stateManager.handleActiveAppChanged(bundleId: "com.apple.Safari", appName: "Safari")
        
        XCTAssertFalse(stateManager.isSuspendedByForeignIME,
                       "Switching back to Safari on ABC must un-suspend VietFlow")
        XCTAssertEqual(stateManager.currentInputMode, .vietnamese)
        XCTAssertEqual(stateManager.rememberedForeignSourceID, japaneseID)
        
        // Toggle OFF in Safari restores Japanese
        eventTapManager.toggleModeSynchronously()
        XCTAssertEqual(mockSourceManager.selectInputSourceCalledWithID, japaneseID)
        XCTAssertEqual(stateManager.currentInputMode, .english)
        XCTAssertTrue(stateManager.isSuspendedByForeignIME)
        XCTAssertNil(stateManager.rememberedForeignSourceID)
    }

    // MARK: - Test Registry Registration
    public override var allTests: [(name: String, test: () throws -> Void)] {
        return [
            ("test_01_abc_v_to_japanese_auto_switches_to_english_and_passes_romaji_keystrokes_untouched", test_01_abc_v_to_japanese_auto_switches_to_english_and_passes_romaji_keystrokes_untouched),
            ("test_02_japanese_e_to_abc_restores_vietnamese_mode", test_02_japanese_e_to_abc_restores_vietnamese_mode),
            ("test_03_abc_e_to_japanese_to_abc_preserves_english_mode", test_03_abc_e_to_japanese_to_abc_preserves_english_mode),
            ("test_04_manual_toggle_in_japanese_invokes_select_latin_and_activates_vietnamese", test_04_manual_toggle_in_japanese_invokes_select_latin_and_activates_vietnamese),
            ("test_05_event_tap_manager_toggle_synchronously_in_japanese", test_05_event_tap_manager_toggle_synchronously_in_japanese),
            ("test_06_disabled_setting_leaves_mode_unchanged", test_06_disabled_setting_leaves_mode_unchanged),
            ("test_07_startup_in_foreign_ime_auto_suspends_and_restores_on_abc", test_07_startup_in_foreign_ime_auto_suspends_and_restores_on_abc),
            ("test_08_classifier_identifies_all_foreign_and_latin_sources", test_08_classifier_identifies_all_foreign_and_latin_sources),
            ("test_09_synchronous_polling_in_event_tap_manager", test_09_synchronous_polling_in_event_tap_manager),
            ("test_10_per_app_mode_preservation_across_foreign_ime_transitions", test_10_per_app_mode_preservation_across_foreign_ime_transitions),
            ("test_11_palette_and_utility_sources_rejection", test_11_palette_and_utility_sources_rejection),
            ("test_12_manual_mode_toggle_synchronously_queries_stale_input_source", test_12_manual_mode_toggle_synchronously_queries_stale_input_source),
            ("test_13_non_latin_layout_auto_suspends_and_restores", test_13_non_latin_layout_auto_suspends_and_restores),
            ("test_14_settings_ui_active_under_foreign_ime_does_not_wipe_per_app_modes", test_14_settings_ui_active_under_foreign_ime_does_not_wipe_per_app_modes),
            ("test_15_one_step_toggle_from_japanese_with_saved_english_mode", test_15_one_step_toggle_from_japanese_with_saved_english_mode),
            ("test_16_disabled_auto_switch_bypasses_synchronous_refresh_overhead", test_16_disabled_auto_switch_bypasses_synchronous_refresh_overhead),
            ("test_17_reset_to_defaults_under_foreign_ime_preserves_suspended_state", test_17_reset_to_defaults_under_foreign_ime_preserves_suspended_state),
            ("test_18_one_step_toggle_failure_rolls_back_safely", test_18_one_step_toggle_failure_rolls_back_safely),
            ("test_19_switching_between_two_foreign_imes_preserves_saved_mode", test_19_switching_between_two_foreign_imes_preserves_saved_mode),
            ("test_20_extended_non_latin_layouts_and_third_party_imes_classifier", test_20_extended_non_latin_layouts_and_third_party_imes_classifier),
            ("test_21_transient_nil_source_does_not_clear_cached_source_id", test_21_transient_nil_source_does_not_clear_cached_source_id),
            ("test_22_bidirectional_foreign_ime_memory_toggle_ping_pong", test_22_bidirectional_foreign_ime_memory_toggle_ping_pong),
            ("test_23_normal_abc_toggle_unaffected_when_no_foreign_source_remembered", test_23_normal_abc_toggle_unaffected_when_no_foreign_source_remembered),
            ("test_24_manual_input_source_change_outside_toggle_clears_remembered_foreign_source", test_24_manual_input_source_change_outside_toggle_clears_remembered_foreign_source),
            ("test_25_foreign_restore_failure_falls_back_to_standard_english_mode", test_25_foreign_restore_failure_falls_back_to_standard_english_mode),
            ("test_26_event_tap_manager_synchronous_ping_pong_toggle", test_26_event_tap_manager_synchronous_ping_pong_toggle),
            ("test_27_japanese_romaji_typing_toggle_typing_words_preserves_foreign_source_and_restores_japanese", test_27_japanese_romaji_typing_toggle_typing_words_preserves_foreign_source_and_restores_japanese),
            ("test_28_delayed_tis_notification_does_not_clear_remembered_foreign_source_or_revert_mode", test_28_delayed_tis_notification_does_not_clear_remembered_foreign_source_or_revert_mode),
            ("test_29_manual_different_latin_switch_clears_remembered_foreign_source_even_after_typing", test_29_manual_different_latin_switch_clears_remembered_foreign_source_even_after_typing),
            ("test_30_per_app_mode_with_foreign_ime_restore_and_cross_app_typing", test_30_per_app_mode_with_foreign_ime_restore_and_cross_app_typing),
            ("test_31_multiple_foreign_imes_and_non_latin_layouts_bidirectional_restore", test_31_multiple_foreign_imes_and_non_latin_layouts_bidirectional_restore),
            ("test_32_rapid_toggle_interleaved_with_typing_and_delayed_tis_notifications", test_32_rapid_toggle_interleaved_with_typing_and_delayed_tis_notifications),
            ("test_33_non_abc_target_latin_layout_preserves_foreign_source", test_33_non_abc_target_latin_layout_preserves_foreign_source),
            ("test_34_setting_auto_switch_on_foreign_input_source_to_false_clears_remembered_foreign_source", test_34_setting_auto_switch_on_foreign_input_source_to_false_clears_remembered_foreign_source),
            ("test_35_asynchronous_delay_where_system_temporarily_returns_japanese_before_abc_typing_words_preserves_foreign_memory", test_35_asynchronous_delay_where_system_temporarily_returns_japanese_before_abc_typing_words_preserves_foreign_memory),
            ("test_36_late_foreign_notification_arriving_after_toggle_does_not_suspend_or_wipe_memory", test_36_late_foreign_notification_arriving_after_toggle_does_not_suspend_or_wipe_memory),
            ("test_37_cross_app_switching_with_async_delay_preserves_foreign_memory", test_37_cross_app_switching_with_async_delay_preserves_foreign_memory),
            ("test_38_non_abc_latin_layout_with_async_delay_preserves_foreign_memory", test_38_non_abc_latin_layout_with_async_delay_preserves_foreign_memory),
            ("test_39_manual_switch_to_same_foreign_ime_after_typing_suspends_vietflow", test_39_manual_switch_to_same_foreign_ime_after_typing_suspends_vietflow),
            ("test_40_app_switch_to_foreign_ime_app_after_typing_suspends_vietflow", test_40_app_switch_to_foreign_ime_app_after_typing_suspends_vietflow),
        ]
    }
}
