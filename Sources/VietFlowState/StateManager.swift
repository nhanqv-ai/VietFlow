//
//  StateManager.swift
//  VietFlowState
//
//  Manages application settings, per-app input mode tracking,
//  blacklist atomic bypass, and keyboard shortcuts.
//

import Foundation
import Combine
import AppKit
import CoreGraphics
import ServiceManagement
import VietFlowEngine

public enum InputMode: String, CaseIterable, Codable, Sendable {
    case vietnamese = "V"
    case english = "E"
    
    public var title: String {
        switch self {
        case .vietnamese: return "Tiếng Việt"
        case .english: return "English"
        }
    }
}

public enum ModifierChordShortcut: String, CaseIterable, Codable, Sendable {
    case controlShift = "controlShift"
    case commandShift = "commandShift"
    case optionShift = "optionShift"
    case option = "option"
    
    public var title: String {
        switch self {
        case .controlShift: return "Control + Shift"
        case .commandShift: return "Command + Shift"
        case .optionShift: return "Option + Shift"
        case .option: return "Option (Phím Alt)"
        }
    }
    
    public var displayTitle: String { title }
    
    public var targetMask: CGEventFlags {
        switch self {
        case .controlShift: return [.maskControl, .maskShift]
        case .commandShift: return [.maskCommand, .maskShift]
        case .optionShift: return [.maskAlternate, .maskShift]
        case .option: return [.maskAlternate]
        }
    }
    
    public init?(rawValue: String) {
        switch rawValue.lowercased().replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "+", with: "") {
        case "controlshift", "ctrlshift":
            self = .controlShift
        case "commandshift", "cmdshift":
            self = .commandShift
        case "optionshift", "altshift":
            self = .optionShift
        case "option", "alt", "option(phímalt)":
            self = .option
        default:
            return nil
        }
    }
}

public typealias ToggleShortcut = ModifierChordShortcut

public enum ShortcutType: String, CaseIterable, Codable, Sendable {
    case modifierChord = "modifierChord"
    case customKeyCombo = "customKeyCombo"
}

public struct CustomKeyCombo: Codable, Equatable, Sendable {
    public var keyCode: UInt32
    public var carbonModifiers: UInt32
    public var displayString: String
    
    public init(keyCode: UInt32 = 49, carbonModifiers: UInt32 = 4096, displayString: String = "⌃Space") {
        self.keyCode = keyCode
        self.carbonModifiers = carbonModifiers
        self.displayString = displayString
    }
}

public struct AppSettings: Codable, Equatable, Sendable {
    public var inputMode: InputMode
    public var inputMethod: InputMethod
    public var tonePlacement: TonePlacementStyle
    public var autoRestoreEnglish: Bool
    public var escapeByDoubleKey: Bool
    public var shortcutType: ShortcutType
    public var modifierChord: ModifierChordShortcut
    public var customKeyCombo: CustomKeyCombo
    public var launchAtLogin: Bool
    public var perAppInputMode: Bool
    public var blacklistedBundleIdentifiers: [String]
    
    public static let `default` = AppSettings()
    
    public init(
        inputMode: InputMode = .vietnamese,
        inputMethod: InputMethod = .telex,
        tonePlacement: TonePlacementStyle = .modern,
        autoRestoreEnglish: Bool = true,
        escapeByDoubleKey: Bool = true,
        shortcutType: ShortcutType = .modifierChord,
        modifierChord: ModifierChordShortcut = .controlShift,
        customKeyCombo: CustomKeyCombo = CustomKeyCombo(),
        launchAtLogin: Bool = false,
        perAppInputMode: Bool = true,
        blacklistedBundleIdentifiers: [String] = [
            "com.valvesoftware.steam",
            "com.riotgames.leagueoflegends"
        ]
    ) {
        self.inputMode = inputMode
        self.inputMethod = inputMethod
        self.tonePlacement = tonePlacement
        self.autoRestoreEnglish = autoRestoreEnglish
        self.escapeByDoubleKey = escapeByDoubleKey
        self.shortcutType = shortcutType
        self.modifierChord = modifierChord
        self.customKeyCombo = customKeyCombo
        self.launchAtLogin = launchAtLogin
        self.perAppInputMode = perAppInputMode
        self.blacklistedBundleIdentifiers = blacklistedBundleIdentifiers
    }
    
    public mutating func resetToDefaults() {
        self = AppSettings()
    }
    
    private enum CodingKeys: String, CodingKey {
        case inputMode
        case inputMethod
        case tonePlacement
        case autoRestoreEnglish
        case escapeByDoubleKey
        case shortcutType
        case modifierChord
        case customKeyCombo
        case launchAtLogin
        case perAppInputMode
        case blacklistedBundleIdentifiers
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.inputMode = try container.decodeIfPresent(InputMode.self, forKey: .inputMode) ?? .vietnamese
        self.inputMethod = try container.decodeIfPresent(InputMethod.self, forKey: .inputMethod) ?? .telex
        self.tonePlacement = try container.decodeIfPresent(TonePlacementStyle.self, forKey: .tonePlacement) ?? .modern
        self.autoRestoreEnglish = try container.decodeIfPresent(Bool.self, forKey: .autoRestoreEnglish) ?? true
        self.escapeByDoubleKey = try container.decodeIfPresent(Bool.self, forKey: .escapeByDoubleKey) ?? true
        self.shortcutType = try container.decodeIfPresent(ShortcutType.self, forKey: .shortcutType) ?? .modifierChord
        self.modifierChord = try container.decodeIfPresent(ModifierChordShortcut.self, forKey: .modifierChord) ?? .controlShift
        self.customKeyCombo = try container.decodeIfPresent(CustomKeyCombo.self, forKey: .customKeyCombo) ?? CustomKeyCombo()
        self.launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        self.perAppInputMode = try container.decodeIfPresent(Bool.self, forKey: .perAppInputMode) ?? true
        self.blacklistedBundleIdentifiers = try container.decodeIfPresent([String].self, forKey: .blacklistedBundleIdentifiers) ?? [
            "com.valvesoftware.steam",
            "com.riotgames.leagueoflegends"
        ]
    }
}

public final class AppStateManager: ObservableObject, @unchecked Sendable {
    public static let shared = AppStateManager()
    
    // MARK: - Published Properties
    @Published public var settings: AppSettings = AppSettings()
    
    @Published public var currentInputMode: InputMode = .vietnamese {
        didSet {
            settings.inputMode = currentInputMode
            if isVietFlowUIActive {
                perAppModes.removeAll()
            }
            saveCurrentModeForActiveApp()
            saveSettings()
            engine?.reset()
            NotificationCenter.default.post(name: .vietFlowInputModeChanged, object: currentInputMode)
        }
    }
    
    @Published public var currentInputMethod: InputMethod = .telex {
        didSet {
            settings.inputMethod = currentInputMethod
            saveSettings()
            engineConfig.inputMethod = currentInputMethod
            syncEngineConfig()
        }
    }
    
    @Published public var currentTonePlacement: TonePlacementStyle = .modern {
        didSet {
            settings.tonePlacement = currentTonePlacement
            saveSettings()
            engineConfig.tonePlacement = currentTonePlacement
            syncEngineConfig()
        }
    }
    
    @Published public var autoRestoreEnglish: Bool = true {
        didSet {
            settings.autoRestoreEnglish = autoRestoreEnglish
            saveSettings()
            engineConfig.autoCorrectEnglish = autoRestoreEnglish
            syncEngineConfig()
        }
    }
    
    @Published public var escapeByDoubleKey: Bool = true {
        didSet {
            settings.escapeByDoubleKey = escapeByDoubleKey
            saveSettings()
            engineConfig.escapeByDoubleKey = escapeByDoubleKey
            syncEngineConfig()
        }
    }
    
    @Published public var shortcutType: ShortcutType = .modifierChord {
        didSet {
            settings.shortcutType = shortcutType
            saveSettings()
        }
    }
    
    @Published public var modifierChord: ModifierChordShortcut = .controlShift {
        didSet {
            settings.modifierChord = modifierChord
            if toggleShortcut != modifierChord {
                toggleShortcut = modifierChord
            }
            saveSettings()
        }
    }
    
    @Published public var customKeyCombo: CustomKeyCombo = CustomKeyCombo() {
        didSet {
            settings.customKeyCombo = customKeyCombo
            saveSettings()
        }
    }
    
    @Published public var toggleShortcut: ModifierChordShortcut = .controlShift {
        didSet {
            if modifierChord != toggleShortcut {
                modifierChord = toggleShortcut
            }
            saveSettings()
        }
    }
    
    @Published public var launchAtLogin: Bool = false {
        didSet {
            settings.launchAtLogin = launchAtLogin
            setLaunchAtLogin(launchAtLogin)
            saveSettings()
        }
    }
    
    @Published public var perAppInputMode: Bool = true {
        didSet {
            settings.perAppInputMode = perAppInputMode
            if perAppInputMode && !activeAppBundleId.isEmpty {
                perAppModes[activeAppBundleId] = currentInputMode
            }
            saveSettings()
        }
    }
    
    @Published public var blacklistedBundleIdentifiers: [String] = [
        "com.valvesoftware.steam",
        "com.riotgames.leagueoflegends"
    ] {
        didSet {
            settings.blacklistedBundleIdentifiers = blacklistedBundleIdentifiers
            updateBlacklistCache()
            saveSettings()
        }
    }
    
    @Published public var activeAppBundleId: String = ""
    @Published public var activeAppName: String = ""
    
    // MARK: - Engine Linkage
    public weak var engine: BambooEngine? {
        didSet {
            syncEngineConfig()
        }
    }
    public var onToggleInputMode: (() -> Void)?
    
    // MARK: - High-Performance In-Memory Caches for EventTap
    public private(set) var isBlacklistActive: Bool = false
    public var engineConfig: EngineConfig = EngineConfig() {
        didSet {
            engine?.config = engineConfig
        }
    }
    
    private let userDefaults = UserDefaults.standard
    private var perAppModes: [String: InputMode] = [:]
    private var isVietFlowUIActive: Bool = false
    private var workspaceObserver: NSObjectProtocol?
    
    public init() {
        loadSettings()
        setupWorkspaceObserver()
        updateBlacklistCache()
        checkInitialApp()
    }
    
    deinit {
        if let observer = workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }
    
    // MARK: - Engine Config Synchronization
    public func syncEngineConfig() {
        let updated = EngineConfig(
            inputMethod: currentInputMethod,
            tonePlacement: currentTonePlacement,
            autoCorrectEnglish: autoRestoreEnglish,
            escapeByDoubleKey: escapeByDoubleKey
        )
        engineConfig = updated
        engine?.config = updated
        engine?.reset()
    }
    
    // MARK: - Toggle Input Mode
    public func toggleInputMode() {
        let newMode: InputMode = (currentInputMode == .vietnamese) ? .english : .vietnamese
        currentInputMode = newMode
        engine?.reset()
        onToggleInputMode?()
    }
    
    // MARK: - Blacklist Fast Path
    public func isApplicationBlacklisted(bundleId: String) -> Bool {
        return blacklistedBundleIdentifiers.contains(bundleId)
    }
    
    public func addBlacklistApp(bundleId: String) {
        if !blacklistedBundleIdentifiers.contains(bundleId) {
            blacklistedBundleIdentifiers.append(bundleId)
        }
    }
    
    public func removeBlacklistApp(bundleId: String) {
        blacklistedBundleIdentifiers.removeAll { $0 == bundleId }
    }
    
    private func updateBlacklistCache() {
        isBlacklistActive = isApplicationBlacklisted(bundleId: activeAppBundleId)
    }
    
    // MARK: - Workspace Tracking
    private func setupWorkspaceObserver() {
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let bundleId = app.bundleIdentifier else { return }
            
            self.handleActiveAppChanged(bundleId: bundleId, appName: app.localizedName ?? bundleId)
        }
    }
    
    private func checkInitialApp() {
        if let frontApp = NSWorkspace.shared.frontmostApplication,
           let bundleId = frontApp.bundleIdentifier {
            handleActiveAppChanged(bundleId: bundleId, appName: frontApp.localizedName ?? bundleId)
        }
    }
    
    public func handleActiveAppChanged(bundleId: String, appName: String = "") {
        // Ignore VietFlow's own bundle ID so opening VietFlow Settings or clicking the Menu Bar
        // never overwrites the user's active target app or causes mode reversion upon closing Settings.
        if bundleId == "com.nhanqv.VietFlow" || bundleId == Bundle.main.bundleIdentifier {
            isVietFlowUIActive = true
            return
        }
        
        isVietFlowUIActive = false
        self.activeAppBundleId = bundleId
        self.activeAppName = appName.isEmpty ? bundleId : appName
        self.isBlacklistActive = isApplicationBlacklisted(bundleId: bundleId)
        self.engine?.reset()
        
        if perAppInputMode {
            if let savedMode = perAppModes[bundleId] {
                if self.currentInputMode != savedMode {
                    self.currentInputMode = savedMode
                }
            } else {
                perAppModes[bundleId] = self.currentInputMode
            }
        }
    }
    
    private func saveCurrentModeForActiveApp() {
        guard perAppInputMode, !activeAppBundleId.isEmpty else { return }
        perAppModes[activeAppBundleId] = currentInputMode
    }
    
    // MARK: - Launch At Login
    private func setLaunchAtLogin(_ enable: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enable {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
            } catch {
                NSLog("VietFlow: Failed to configure launch at login: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Persistence
    public func saveSettings() {
        userDefaults.set(currentInputMode.rawValue, forKey: "currentInputMode")
        userDefaults.set(currentInputMethod.rawValue, forKey: "currentInputMethod")
        userDefaults.set(currentTonePlacement.rawValue, forKey: "currentTonePlacement")
        userDefaults.set(autoRestoreEnglish, forKey: "autoRestoreEnglish")
        userDefaults.set(escapeByDoubleKey, forKey: "escapeByDoubleKey")
        userDefaults.set(shortcutType.rawValue, forKey: "shortcutType")
        userDefaults.set(modifierChord.rawValue, forKey: "modifierChord")
        userDefaults.set(toggleShortcut.rawValue, forKey: "toggleShortcut")
        userDefaults.set(perAppInputMode, forKey: "perAppInputMode")
        userDefaults.set(blacklistedBundleIdentifiers, forKey: "blacklistedBundleIdentifiers")
        
        userDefaults.set(customKeyCombo.keyCode, forKey: "customKeyComboKeyCode")
        userDefaults.set(customKeyCombo.carbonModifiers, forKey: "customKeyComboModifiers")
        userDefaults.set(customKeyCombo.displayString, forKey: "customKeyComboDisplay")
        
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: "appSettingsData")
        }
    }
    
    public func loadSettings() {
        if let data = userDefaults.data(forKey: "appSettingsData"),
           let loaded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = loaded
            self.currentInputMode = loaded.inputMode
            self.currentInputMethod = loaded.inputMethod
            self.currentTonePlacement = loaded.tonePlacement
            self.autoRestoreEnglish = loaded.autoRestoreEnglish
            self.escapeByDoubleKey = loaded.escapeByDoubleKey
            self.shortcutType = loaded.shortcutType
            self.modifierChord = loaded.modifierChord
            self.customKeyCombo = loaded.customKeyCombo
            self.toggleShortcut = loaded.modifierChord
            self.launchAtLogin = loaded.launchAtLogin
            self.perAppInputMode = loaded.perAppInputMode
            self.blacklistedBundleIdentifiers = loaded.blacklistedBundleIdentifiers
        } else {
            if let modeStr = userDefaults.string(forKey: "currentInputMode"),
               let mode = InputMode(rawValue: modeStr) {
                currentInputMode = mode
            }
            if let methodStr = userDefaults.string(forKey: "currentInputMethod"),
               let method = InputMethod(rawValue: methodStr) {
                currentInputMethod = method
            }
            if let toneStr = userDefaults.string(forKey: "currentTonePlacement"),
               let tone = TonePlacementStyle(rawValue: toneStr) {
                currentTonePlacement = tone
            }
            if userDefaults.object(forKey: "autoRestoreEnglish") != nil {
                autoRestoreEnglish = userDefaults.bool(forKey: "autoRestoreEnglish")
            }
            if userDefaults.object(forKey: "escapeByDoubleKey") != nil {
                escapeByDoubleKey = userDefaults.bool(forKey: "escapeByDoubleKey")
            }
            if let sTypeStr = userDefaults.string(forKey: "shortcutType"),
               let sType = ShortcutType(rawValue: sTypeStr) {
                shortcutType = sType
            }
            if let chordStr = userDefaults.string(forKey: "modifierChord") ?? userDefaults.string(forKey: "toggleShortcut"),
               let chord = ModifierChordShortcut(rawValue: chordStr) {
                modifierChord = chord
                toggleShortcut = chord
            }
            if userDefaults.object(forKey: "customKeyComboKeyCode") != nil {
                let code = UInt32(userDefaults.integer(forKey: "customKeyComboKeyCode"))
                let mods = UInt32(userDefaults.integer(forKey: "customKeyComboModifiers"))
                let disp = userDefaults.string(forKey: "customKeyComboDisplay") ?? "⌃Space"
                customKeyCombo = CustomKeyCombo(keyCode: code, carbonModifiers: mods, displayString: disp)
            }
            if userDefaults.object(forKey: "perAppInputMode") != nil {
                perAppInputMode = userDefaults.bool(forKey: "perAppInputMode")
            }
            if let blacklist = userDefaults.stringArray(forKey: "blacklistedBundleIdentifiers") {
                blacklistedBundleIdentifiers = blacklist
            }
            
            settings = AppSettings(
                inputMode: currentInputMode,
                inputMethod: currentInputMethod,
                tonePlacement: currentTonePlacement,
                autoRestoreEnglish: autoRestoreEnglish,
                escapeByDoubleKey: escapeByDoubleKey,
                shortcutType: shortcutType,
                modifierChord: modifierChord,
                customKeyCombo: customKeyCombo,
                launchAtLogin: launchAtLogin,
                perAppInputMode: perAppInputMode,
                blacklistedBundleIdentifiers: blacklistedBundleIdentifiers
            )
        }
        
        if #available(macOS 13.0, *) {
            launchAtLogin = (SMAppService.mainApp.status == .enabled)
        }
        
        syncEngineConfig()
    }
    
    public func resetToDefaults() {
        perAppModes.removeAll()
        isVietFlowUIActive = false
        settings.resetToDefaults()
        currentInputMode = settings.inputMode
        currentInputMethod = settings.inputMethod
        currentTonePlacement = settings.tonePlacement
        autoRestoreEnglish = settings.autoRestoreEnglish
        escapeByDoubleKey = settings.escapeByDoubleKey
        shortcutType = settings.shortcutType
        modifierChord = settings.modifierChord
        customKeyCombo = settings.customKeyCombo
        toggleShortcut = settings.modifierChord
        launchAtLogin = settings.launchAtLogin
        perAppInputMode = settings.perAppInputMode
        blacklistedBundleIdentifiers = settings.blacklistedBundleIdentifiers
        syncEngineConfig()
        saveSettings()
    }
}

public extension Notification.Name {
    static let vietFlowInputModeChanged = Notification.Name("vietFlowInputModeChanged")
}
