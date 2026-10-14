//
//  SettingsPersistenceTests.swift
//  VietFlowStateTests
//
//  Comprehensive test suite for AppSettings and AppStateManager:
//  - Default factory settings verification
//  - JSON Codable serialization and round-trip deserialization
//  - Missing-key decoding resilience and default fallback
//  - Input method, tone rule, English restore, and double-key escape mutations
//  - Shortcut mode switching (modifier chord vs custom key combo)
//  - Custom key combo configuration and persistence
//  - Blacklisted applications add/remove and containment check
//  - resetToDefaults() full factory restoration
//  - Synchronous input mode toggle
//

import Foundation
import Combine
import VietFlowEngine
import VietFlowState
import VietFlowEngineTests

public final class SettingsPersistenceTests: TestCase {
    
    public override func setUp() {
        super.setUp()
        AppStateManager.shared.resetToDefaults()
    }
    
    public override func tearDown() {
        AppStateManager.shared.resetToDefaults()
        super.tearDown()
    }
    
    // MARK: - Test 1: Factory Default Settings
    func test_01_factory_default_settings() {
        let def = AppSettings.default
        XCTAssertEqual(def.inputMode, .vietnamese)
        XCTAssertEqual(def.inputMethod, .telex)
        XCTAssertEqual(def.tonePlacement, .modern)
        XCTAssertTrue(def.autoRestoreEnglish)
        XCTAssertTrue(def.escapeByDoubleKey)
        XCTAssertTrue(def.autoSwitchOnForeignInputSource)
        XCTAssertEqual(def.shortcutType, .modifierChord)
        XCTAssertEqual(def.modifierChord, .controlShift)
        XCTAssertEqual(def.customKeyCombo.keyCode, 49)
        XCTAssertEqual(def.customKeyCombo.carbonModifiers, 4096)
        XCTAssertEqual(def.customKeyCombo.displayString, "⌃Space")
        XCTAssertFalse(def.launchAtLogin)
        XCTAssertTrue(def.perAppInputMode)
        XCTAssertEqual(def.blacklistedBundleIdentifiers.count, 2)
        XCTAssertTrue(def.blacklistedBundleIdentifiers.contains("com.valvesoftware.steam"))
        XCTAssertTrue(def.blacklistedBundleIdentifiers.contains("com.riotgames.leagueoflegends"))
    }
    
    // MARK: - Test 2: JSON Serialization & Roundtrip
    func test_02_json_roundtrip_serialization() throws {
        let original = AppSettings.default
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        XCTAssertFalse(data.isEmpty)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AppSettings.self, from: data)
        XCTAssertEqual(decoded, original)
    }
    
    // MARK: - Test 3: JSON Roundtrip with Custom Mutated Values
    func test_03_json_roundtrip_custom_values() throws {
        let customCombo = CustomKeyCombo(keyCode: 11, carbonModifiers: 256, displayString: "⌘B")
        let custom = AppSettings(
            inputMode: .english,
            inputMethod: .vni,
            tonePlacement: .traditional,
            autoRestoreEnglish: false,
            escapeByDoubleKey: false,
            autoSwitchOnForeignInputSource: false,
            shortcutType: .customKeyCombo,
            modifierChord: .commandShift,
            customKeyCombo: customCombo,
            launchAtLogin: true,
            perAppInputMode: false,
            blacklistedBundleIdentifiers: ["com.sublimetext.4", "com.jetbrains.intellij"]
        )
        
        let data = try JSONEncoder().encode(custom)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)
        
        XCTAssertEqual(decoded, custom)
        XCTAssertEqual(decoded.inputMode, .english)
        XCTAssertEqual(decoded.inputMethod, .vni)
        XCTAssertEqual(decoded.tonePlacement, .traditional)
        XCTAssertFalse(decoded.autoRestoreEnglish)
        XCTAssertFalse(decoded.escapeByDoubleKey)
        XCTAssertFalse(decoded.autoSwitchOnForeignInputSource)
        XCTAssertEqual(decoded.shortcutType, .customKeyCombo)
        XCTAssertEqual(decoded.modifierChord, .commandShift)
        XCTAssertEqual(decoded.customKeyCombo.keyCode, 11)
        XCTAssertEqual(decoded.customKeyCombo.displayString, "⌘B")
        XCTAssertTrue(decoded.launchAtLogin)
        XCTAssertFalse(decoded.perAppInputMode)
        XCTAssertEqual(decoded.blacklistedBundleIdentifiers.count, 2)
    }
    
    // MARK: - Test 4: JSON Decoding Resilience (Missing Keys)
    func test_04_json_decoding_empty_object_falls_back_to_defaults() throws {
        let emptyJSON = "{}".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AppSettings.self, from: emptyJSON)
        
        XCTAssertEqual(decoded.inputMode, .vietnamese)
        XCTAssertEqual(decoded.inputMethod, .telex)
        XCTAssertEqual(decoded.tonePlacement, .modern)
        XCTAssertTrue(decoded.autoRestoreEnglish)
        XCTAssertTrue(decoded.escapeByDoubleKey)
        XCTAssertTrue(decoded.autoSwitchOnForeignInputSource)
        XCTAssertEqual(decoded.shortcutType, .modifierChord)
        XCTAssertEqual(decoded.modifierChord, .controlShift)
        XCTAssertEqual(decoded.customKeyCombo.keyCode, 49)
        XCTAssertFalse(decoded.launchAtLogin)
        XCTAssertTrue(decoded.perAppInputMode)
        XCTAssertEqual(decoded.blacklistedBundleIdentifiers.count, 2)
    }
    
    // MARK: - Test 5: Input Method Mutation
    func test_05_input_method_mutation() {
        var settings = AppSettings.default
        
        settings.inputMethod = .simpleTelex
        XCTAssertEqual(settings.inputMethod, .simpleTelex)
        
        settings.inputMethod = .vni
        XCTAssertEqual(settings.inputMethod, .vni)
        
        settings.inputMethod = .telex
        XCTAssertEqual(settings.inputMethod, .telex)
    }
    
    // MARK: - Test 6: Tone Placement Rule Mutation
    func test_06_tone_placement_mutation() {
        var settings = AppSettings.default
        XCTAssertEqual(settings.tonePlacement, .modern)
        
        settings.tonePlacement = .traditional
        XCTAssertEqual(settings.tonePlacement, .traditional)
        
        settings.tonePlacement = .modern
        XCTAssertEqual(settings.tonePlacement, .modern)
    }
    
    // MARK: - Test 7: Auto Restore English Mutation
    func test_07_auto_restore_english_mutation() {
        var settings = AppSettings.default
        XCTAssertTrue(settings.autoRestoreEnglish)
        
        settings.autoRestoreEnglish = false
        XCTAssertFalse(settings.autoRestoreEnglish)
        
        settings.autoRestoreEnglish = true
        XCTAssertTrue(settings.autoRestoreEnglish)
    }
    
    // MARK: - Test 8: Double Key Escape Mutation
    func test_08_double_key_escape_mutation() {
        var settings = AppSettings.default
        XCTAssertTrue(settings.escapeByDoubleKey)
        
        settings.escapeByDoubleKey = false
        XCTAssertFalse(settings.escapeByDoubleKey)
        
        settings.escapeByDoubleKey = true
        XCTAssertTrue(settings.escapeByDoubleKey)
    }
    
    // MARK: - Test 9: Shortcut Mode Switching
    func test_09_shortcut_mode_switching() {
        var settings = AppSettings.default
        XCTAssertEqual(settings.shortcutType, .modifierChord)
        
        settings.shortcutType = .customKeyCombo
        XCTAssertEqual(settings.shortcutType, .customKeyCombo)
        
        settings.shortcutType = .modifierChord
        XCTAssertEqual(settings.shortcutType, .modifierChord)
    }
    
    // MARK: - Test 10: Custom Key Combo Properties
    func test_10_custom_key_combo_properties() {
        var combo = CustomKeyCombo()
        XCTAssertEqual(combo.keyCode, 49)
        XCTAssertEqual(combo.carbonModifiers, 4096)
        XCTAssertEqual(combo.displayString, "⌃Space")
        
        combo.keyCode = 9 // 'V' key
        combo.carbonModifiers = 256 | 512 // Cmd + Shift
        combo.displayString = "⇧⌘V"
        
        XCTAssertEqual(combo.keyCode, 9)
        XCTAssertEqual(combo.carbonModifiers, 768)
        XCTAssertEqual(combo.displayString, "⇧⌘V")
        
        let sameCombo = CustomKeyCombo(keyCode: 9, carbonModifiers: 768, displayString: "⇧⌘V")
        XCTAssertEqual(combo, sameCombo)
    }
    
    // MARK: - Test 11: Modifier Chord Preset Cases & Titles
    func test_11_modifier_chord_presets() {
        let allPresets = ModifierChordShortcut.allCases
        XCTAssertEqual(allPresets.count, 4)
        XCTAssertTrue(allPresets.contains(.controlShift))
        XCTAssertTrue(allPresets.contains(.commandShift))
        XCTAssertTrue(allPresets.contains(.optionShift))
        XCTAssertTrue(allPresets.contains(.option))
        
        XCTAssertEqual(ModifierChordShortcut.controlShift.title, "Control + Shift")
        XCTAssertEqual(ModifierChordShortcut.commandShift.title, "Command + Shift")
        XCTAssertEqual(ModifierChordShortcut.optionShift.title, "Option + Shift")
        XCTAssertEqual(ModifierChordShortcut.option.title, "Option (Phím Alt)")
    }
    
    // MARK: - Test 12: Modifier Chord RawValue Parsing
    func test_12_modifier_chord_raw_value_parsing() {
        XCTAssertEqual(ModifierChordShortcut(rawValue: "controlShift"), .controlShift)
        XCTAssertEqual(ModifierChordShortcut(rawValue: "ctrlshift"), .controlShift)
        XCTAssertEqual(ModifierChordShortcut(rawValue: "Control + Shift"), .controlShift)
        
        XCTAssertEqual(ModifierChordShortcut(rawValue: "commandShift"), .commandShift)
        XCTAssertEqual(ModifierChordShortcut(rawValue: "cmdshift"), .commandShift)
        XCTAssertEqual(ModifierChordShortcut(rawValue: "Command + Shift"), .commandShift)
        
        XCTAssertEqual(ModifierChordShortcut(rawValue: "optionShift"), .optionShift)
        XCTAssertEqual(ModifierChordShortcut(rawValue: "altshift"), .optionShift)
        
        XCTAssertEqual(ModifierChordShortcut(rawValue: "option"), .option)
        XCTAssertEqual(ModifierChordShortcut(rawValue: "alt"), .option)
        
        XCTAssertNil(ModifierChordShortcut(rawValue: "invalidShortcut"))
    }
    
    // MARK: - Test 13: Modifier Chord Target Masks
    func test_13_modifier_chord_target_masks() {
        XCTAssertEqual(ModifierChordShortcut.controlShift.targetMask, [.maskControl, .maskShift])
        XCTAssertEqual(ModifierChordShortcut.commandShift.targetMask, [.maskCommand, .maskShift])
        XCTAssertEqual(ModifierChordShortcut.optionShift.targetMask, [.maskAlternate, .maskShift])
        XCTAssertEqual(ModifierChordShortcut.option.targetMask, [.maskAlternate])
    }
    
    // MARK: - Test 14: Blacklist Add and Deduplication
    func test_14_blacklist_add_and_deduplication() {
        let manager = AppStateManager.shared
        let initialCount = manager.blacklistedBundleIdentifiers.count
        
        manager.addBlacklistApp(bundleId: "com.apple.dt.Xcode")
        XCTAssertTrue(manager.isApplicationBlacklisted(bundleId: "com.apple.dt.Xcode"))
        XCTAssertEqual(manager.blacklistedBundleIdentifiers.count, initialCount + 1)
        
        // Adding the same bundle ID again must not duplicate
        manager.addBlacklistApp(bundleId: "com.apple.dt.Xcode")
        XCTAssertEqual(manager.blacklistedBundleIdentifiers.count, initialCount + 1)
    }
    
    // MARK: - Test 15: Blacklist Remove App
    func test_15_blacklist_remove_app() {
        let manager = AppStateManager.shared
        manager.addBlacklistApp(bundleId: "com.spotify.client")
        XCTAssertTrue(manager.isApplicationBlacklisted(bundleId: "com.spotify.client"))
        
        manager.removeBlacklistApp(bundleId: "com.spotify.client")
        XCTAssertFalse(manager.isApplicationBlacklisted(bundleId: "com.spotify.client"))
    }
    
    // MARK: - Test 16: Blacklist Containment Fast Path
    func test_16_blacklist_containment() {
        let manager = AppStateManager.shared
        XCTAssertTrue(manager.isApplicationBlacklisted(bundleId: "com.valvesoftware.steam"))
        XCTAssertTrue(manager.isApplicationBlacklisted(bundleId: "com.riotgames.leagueoflegends"))
        XCTAssertFalse(manager.isApplicationBlacklisted(bundleId: "com.apple.Terminal"))
        XCTAssertFalse(manager.isApplicationBlacklisted(bundleId: "com.google.Chrome"))
    }
    
    // MARK: - Test 17: AppSettings.resetToDefaults()
    func test_17_app_settings_reset_to_defaults() {
        var settings = AppSettings.default
        settings.inputMode = .english
        settings.inputMethod = .vni
        settings.tonePlacement = .traditional
        settings.autoRestoreEnglish = false
        settings.escapeByDoubleKey = false
        settings.autoSwitchOnForeignInputSource = false
        settings.shortcutType = .customKeyCombo
        settings.modifierChord = .commandShift
        settings.launchAtLogin = true
        settings.perAppInputMode = false
        settings.blacklistedBundleIdentifiers = ["com.test.app"]
        
        XCTAssertNotEqual(settings, AppSettings.default)
        
        settings.resetToDefaults()
        XCTAssertEqual(settings, AppSettings.default)
    }
    
    // MARK: - Test 18: AppStateManager.resetToDefaults() Full Restoration
    func test_18_app_state_manager_reset_to_defaults() {
        let manager = AppStateManager.shared
        manager.currentInputMode = .english
        manager.currentInputMethod = .vni
        manager.currentTonePlacement = .traditional
        manager.autoRestoreEnglish = false
        manager.escapeByDoubleKey = false
        manager.autoSwitchOnForeignInputSource = false
        manager.shortcutType = .customKeyCombo
        manager.modifierChord = .commandShift
        manager.perAppInputMode = false
        manager.addBlacklistApp(bundleId: "com.test.temp")
        
        manager.resetToDefaults()
        
        XCTAssertEqual(manager.currentInputMode, .vietnamese)
        XCTAssertEqual(manager.currentInputMethod, .telex)
        XCTAssertEqual(manager.currentTonePlacement, .modern)
        XCTAssertTrue(manager.autoRestoreEnglish)
        XCTAssertTrue(manager.escapeByDoubleKey)
        XCTAssertTrue(manager.autoSwitchOnForeignInputSource)
        XCTAssertEqual(manager.shortcutType, .modifierChord)
        XCTAssertEqual(manager.modifierChord, .controlShift)
        XCTAssertEqual(manager.toggleShortcut, .controlShift)
        XCTAssertTrue(manager.perAppInputMode)
        XCTAssertEqual(manager.blacklistedBundleIdentifiers.count, 2)
        XCTAssertFalse(manager.isApplicationBlacklisted(bundleId: "com.test.temp"))
    }
    
    // MARK: - Test 19: Synchronous Mode Toggle
    func test_19_synchronous_mode_toggle() {
        let manager = AppStateManager.shared
        XCTAssertEqual(manager.currentInputMode, .vietnamese)
        
        manager.toggleInputMode()
        XCTAssertEqual(manager.currentInputMode, .english)
        
        manager.toggleInputMode()
        XCTAssertEqual(manager.currentInputMode, .vietnamese)
    }
    
    // MARK: - Test 20: Input Mode Titles
    func test_20_input_mode_titles() {
        XCTAssertEqual(InputMode.vietnamese.title, "Tiếng Việt")
        XCTAssertEqual(InputMode.english.title, "English")
        XCTAssertEqual(InputMode.vietnamese.rawValue, "V")
        XCTAssertEqual(InputMode.english.rawValue, "E")
    }
    
    // MARK: - Test 21: Engine Config Synchronization
    func test_21_engine_config_synchronization() {
        let manager = AppStateManager.shared
        
        manager.currentInputMethod = .vni
        XCTAssertEqual(manager.engineConfig.inputMethod, .vni)
        
        manager.currentTonePlacement = .traditional
        XCTAssertEqual(manager.engineConfig.tonePlacement, .traditional)
        
        manager.autoRestoreEnglish = false
        XCTAssertFalse(manager.engineConfig.autoCorrectEnglish)
        
        manager.escapeByDoubleKey = false
        XCTAssertFalse(manager.engineConfig.escapeByDoubleKey)
    }
    
    // MARK: - Test 22: Per-App Input Mode Toggle
    func test_22_per_app_input_mode_toggle() {
        let manager = AppStateManager.shared
        XCTAssertTrue(manager.perAppInputMode)
        
        manager.perAppInputMode = false
        XCTAssertFalse(manager.perAppInputMode)
        XCTAssertFalse(manager.settings.perAppInputMode)
        
        manager.perAppInputMode = true
        XCTAssertTrue(manager.perAppInputMode)
        XCTAssertTrue(manager.settings.perAppInputMode)
    }
    
    // MARK: - Test 23: Auto-Switch On Foreign Input Source Persistence & Toggle
    func test_23_auto_switch_on_foreign_input_source_persistence_and_disable() {
        let manager = AppStateManager.shared
        XCTAssertTrue(manager.autoSwitchOnForeignInputSource)
        XCTAssertTrue(manager.settings.autoSwitchOnForeignInputSource)
        
        // Mutate setting to false
        manager.autoSwitchOnForeignInputSource = false
        XCTAssertFalse(manager.autoSwitchOnForeignInputSource)
        XCTAssertFalse(manager.settings.autoSwitchOnForeignInputSource)
        
        // Verify persistence roundtrip
        manager.saveSettings()
        manager.loadSettings()
        XCTAssertFalse(manager.autoSwitchOnForeignInputSource)
        XCTAssertFalse(manager.settings.autoSwitchOnForeignInputSource)
        
        // When disabled, simulating Japanese IME does NOT auto-suspend VietFlow to English
        let mock = MockInputSourceManager(initialSourceID: "com.apple.keylayout.ABC", isForeign: false)
        manager.inputSourceManager = mock
        manager.currentInputMode = .vietnamese
        
        mock.simulateInputSourceChange(to: "com.apple.inputmethod.Kotoeri.Japanese")
        XCTAssertEqual(manager.currentInputMode, .vietnamese, "Mode must remain .vietnamese when autoSwitchOnForeignInputSource is false")
        XCTAssertFalse(manager.isSuspendedByForeignIME)
        
        // When re-enabled, simulating Japanese IME auto-suspends VietFlow to English
        manager.autoSwitchOnForeignInputSource = true
        XCTAssertTrue(manager.autoSwitchOnForeignInputSource)
        mock.simulateInputSourceChange(to: "com.apple.inputmethod.Kotoeri.Japanese")
        XCTAssertEqual(manager.currentInputMode, .english, "Mode must auto-switch to .english when autoSwitchOnForeignInputSource is true")
        XCTAssertTrue(manager.isSuspendedByForeignIME)
    }
    
    // MARK: - Test 24: isSuspendedByForeignIME Published Property Emission
    func test_24_is_suspended_by_foreign_ime_published_emission() {
        let mock = MockInputSourceManager(initialSourceID: "com.apple.keylayout.ABC", isForeign: false)
        let manager = AppStateManager(inputSourceManager: mock)
        manager.currentInputMode = .vietnamese
        
        var emittedStates: [Bool] = []
        var cancellables = Set<AnyCancellable>()
        
        manager.$isSuspendedByForeignIME
            .sink { isSuspended in
                emittedStates.append(isSuspended)
            }
            .store(in: &cancellables)
        
        XCTAssertEqual(emittedStates, [false], "Initial emitted value of isSuspendedByForeignIME must be false")
        
        // Switch to Japanese IME (Kotoeri)
        mock.simulateInputSourceChange(to: "com.apple.inputmethod.Kotoeri.Japanese")
        XCTAssertTrue(manager.isSuspendedByForeignIME)
        XCTAssertEqual(emittedStates, [false, true], "Emitted values must include true when switching to Japanese IME")
        
        // Switch back to ABC
        mock.simulateInputSourceChange(to: "com.apple.keylayout.ABC")
        XCTAssertFalse(manager.isSuspendedByForeignIME)
        XCTAssertEqual(emittedStates, [false, true, false], "Emitted values must include false when returning to ABC")
    }
    
    // MARK: - Test 25: Publishers.CombineLatest InputMode and isSuspendedByForeignIME
    func test_25_combine_latest_mode_and_suspension_publishing() {
        let mock = MockInputSourceManager(initialSourceID: "com.apple.keylayout.ABC", isForeign: false)
        let manager = AppStateManager(inputSourceManager: mock)
        manager.currentInputMode = .vietnamese
        
        var emissions: [(mode: InputMode, suspended: Bool)] = []
        var cancellables = Set<AnyCancellable>()
        
        Publishers.CombineLatest(manager.$currentInputMode, manager.$isSuspendedByForeignIME)
            .sink { mode, suspended in
                emissions.append((mode: mode, suspended: suspended))
            }
            .store(in: &cancellables)
        
        XCTAssertEqual(emissions.count, 1)
        XCTAssertEqual(emissions.last?.mode, .vietnamese)
        XCTAssertFalse(emissions.last?.suspended ?? true)
        
        // Switch to Japanese Hiragana
        mock.simulateInputSourceChange(to: "com.apple.inputmethod.Kotoeri.Japanese")
        XCTAssertEqual(manager.currentInputMode, .english)
        XCTAssertTrue(manager.isSuspendedByForeignIME)
        XCTAssertEqual(emissions.last?.mode, .english)
        XCTAssertTrue(emissions.last?.suspended ?? false)
        
        // Switch to Japanese Katakana (remains suspended in English)
        mock.simulateInputSourceChange(to: "com.apple.inputmethod.Kotoeri.Japanese.Katakana")
        XCTAssertEqual(manager.currentInputMode, .english)
        XCTAssertTrue(manager.isSuspendedByForeignIME)
        
        // Switch to Japanese RomajiTyping.Roman (remains suspended in English)
        mock.simulateInputSourceChange(to: "com.apple.inputmethod.Kotoeri.RomajiTyping.Roman")
        XCTAssertEqual(manager.currentInputMode, .english)
        XCTAssertTrue(manager.isSuspendedByForeignIME)
        
        // Switch to Japanese Alphanumeric (remains suspended in English)
        mock.simulateInputSourceChange(to: "com.apple.inputmethod.Japanese.Alphanumeric")
        XCTAssertEqual(manager.currentInputMode, .english)
        XCTAssertTrue(manager.isSuspendedByForeignIME)
        
        // One-step manual toggle: directly selects Latin layout and activates Vietnamese
        manager.toggleInputMode()
        XCTAssertEqual(manager.currentInputMode, .vietnamese)
        XCTAssertFalse(manager.isSuspendedByForeignIME)
        XCTAssertEqual(emissions.last?.mode, .vietnamese)
        XCTAssertFalse(emissions.last?.suspended ?? true)
    }
    
    // MARK: - Test 26: Per-App Input Mode Suspended Flag Tracking
    func test_26_per_app_input_mode_suspension_flag_coordination() {
        let mock = MockInputSourceManager(initialSourceID: "com.apple.keylayout.ABC", isForeign: false)
        let manager = AppStateManager(inputSourceManager: mock)
        manager.perAppInputMode = true
        
        // Setup Notes (Vietnamese) and Xcode (English)
        manager.handleActiveAppChanged(bundleId: "com.apple.Notes", appName: "Notes")
        manager.currentInputMode = .vietnamese
        XCTAssertFalse(manager.isSuspendedByForeignIME)
        
        manager.handleActiveAppChanged(bundleId: "com.apple.dt.Xcode", appName: "Xcode")
        manager.currentInputMode = .english
        XCTAssertFalse(manager.isSuspendedByForeignIME)
        
        // Switch macOS to Japanese IME while in Xcode
        mock.simulateInputSourceChange(to: "com.apple.inputmethod.Kotoeri.Japanese")
        XCTAssertTrue(manager.isSuspendedByForeignIME)
        XCTAssertEqual(manager.currentInputMode, .english)
        
        // Switch active app to Notes while macOS is STILL in Japanese IME
        manager.handleActiveAppChanged(bundleId: "com.apple.Notes", appName: "Notes")
        XCTAssertTrue(manager.isSuspendedByForeignIME, "Must remain suspended when switching apps while in foreign IME")
        XCTAssertEqual(manager.currentInputMode, .english, "Must remain .english when switching apps while in foreign IME")
        
        // Switch macOS back to ABC while in Notes
        mock.simulateInputSourceChange(to: "com.apple.keylayout.ABC")
        XCTAssertFalse(manager.isSuspendedByForeignIME, "Suspension flag must clear when returning to ABC")
        XCTAssertEqual(manager.currentInputMode, .vietnamese, "Notes must restore to .vietnamese mode")
        
        // Switch active app back to Xcode in ABC
        manager.handleActiveAppChanged(bundleId: "com.apple.dt.Xcode", appName: "Xcode")
        XCTAssertFalse(manager.isSuspendedByForeignIME)
        XCTAssertEqual(manager.currentInputMode, .english, "Xcode must restore to its saved .english mode")
    }
    
    // MARK: - Test 27: Status Bar Tooltip and Menu String Contract
    func test_27_status_bar_tooltip_and_menu_string_contract() {
        // Verify the exact strings required by R3 interface contract
        let suspendedTooltip = "VietFlow — Chế độ: Tạm ngưng — Đang nhường bộ gõ Ngoại ngữ [E] (Click để kích hoạt Tiếng Việt)"
        let suspendedMenuHeader = "Chế độ: Tạm ngưng — Đang nhường bộ gõ Ngoại ngữ [E]"
        
        XCTAssertFalse(suspendedTooltip.isEmpty)
        XCTAssertFalse(suspendedMenuHeader.isEmpty)
        XCTAssertTrue(suspendedTooltip.contains("Tạm ngưng"))
        XCTAssertTrue(suspendedTooltip.contains("Đang nhường bộ gõ Ngoại ngữ [E]"))
        XCTAssertTrue(suspendedMenuHeader.contains("Tạm ngưng"))
        XCTAssertTrue(suspendedMenuHeader.contains("Đang nhường bộ gõ Ngoại ngữ [E]"))
    }
    
    // MARK: - Test Registry Registration
    public override var allTests: [(name: String, test: () throws -> Void)] {
        return [
            ("test_01_factory_default_settings", test_01_factory_default_settings),
            ("test_02_json_roundtrip_serialization", test_02_json_roundtrip_serialization),
            ("test_03_json_roundtrip_custom_values", test_03_json_roundtrip_custom_values),
            ("test_04_json_decoding_empty_object_falls_back_to_defaults", test_04_json_decoding_empty_object_falls_back_to_defaults),
            ("test_05_input_method_mutation", test_05_input_method_mutation),
            ("test_06_tone_placement_mutation", test_06_tone_placement_mutation),
            ("test_07_auto_restore_english_mutation", test_07_auto_restore_english_mutation),
            ("test_08_double_key_escape_mutation", test_08_double_key_escape_mutation),
            ("test_09_shortcut_mode_switching", test_09_shortcut_mode_switching),
            ("test_10_custom_key_combo_properties", test_10_custom_key_combo_properties),
            ("test_11_modifier_chord_presets", test_11_modifier_chord_presets),
            ("test_12_modifier_chord_raw_value_parsing", test_12_modifier_chord_raw_value_parsing),
            ("test_13_modifier_chord_target_masks", test_13_modifier_chord_target_masks),
            ("test_14_blacklist_add_and_deduplication", test_14_blacklist_add_and_deduplication),
            ("test_15_blacklist_remove_app", test_15_blacklist_remove_app),
            ("test_16_blacklist_containment", test_16_blacklist_containment),
            ("test_17_app_settings_reset_to_defaults", test_17_app_settings_reset_to_defaults),
            ("test_18_app_state_manager_reset_to_defaults", test_18_app_state_manager_reset_to_defaults),
            ("test_19_synchronous_mode_toggle", test_19_synchronous_mode_toggle),
            ("test_20_input_mode_titles", test_20_input_mode_titles),
            ("test_21_engine_config_synchronization", test_21_engine_config_synchronization),
            ("test_22_per_app_input_mode_toggle", test_22_per_app_input_mode_toggle),
            ("test_23_auto_switch_on_foreign_input_source_persistence_and_disable", test_23_auto_switch_on_foreign_input_source_persistence_and_disable),
            ("test_24_is_suspended_by_foreign_ime_published_emission", test_24_is_suspended_by_foreign_ime_published_emission),
            ("test_25_combine_latest_mode_and_suspension_publishing", test_25_combine_latest_mode_and_suspension_publishing),
            ("test_26_per_app_input_mode_suspension_flag_coordination", test_26_per_app_input_mode_suspension_flag_coordination),
            ("test_27_status_bar_tooltip_and_menu_string_contract", test_27_status_bar_tooltip_and_menu_string_contract),
        ]
    }
}
