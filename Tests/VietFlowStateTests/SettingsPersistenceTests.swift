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
        ]
    }
}
