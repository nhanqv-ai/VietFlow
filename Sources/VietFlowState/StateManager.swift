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

public enum ToggleShortcut: String, CaseIterable, Codable, Sendable {
    case controlShift = "Control + Shift"
    case commandShift = "Command + Shift"
    case option = "Option (Phím Alt)"
    case optionShift = "Option + Shift"
}

public final class AppStateManager: ObservableObject, @unchecked Sendable {
    public static let shared = AppStateManager()
    
    // MARK: - Published Properties
    @Published public var currentInputMode: InputMode = .vietnamese {
        didSet {
            saveCurrentModeForActiveApp()
            NotificationCenter.default.post(name: .vietFlowInputModeChanged, object: currentInputMode)
        }
    }
    
    @Published public var currentInputMethod: InputMethod = .telex {
        didSet {
            saveSettings()
            engineConfig.inputMethod = currentInputMethod
        }
    }
    
    @Published public var currentTonePlacement: TonePlacementStyle = .modern {
        didSet {
            saveSettings()
            engineConfig.tonePlacement = currentTonePlacement
        }
    }
    
    @Published public var autoRestoreEnglish: Bool = true {
        didSet {
            saveSettings()
            engineConfig.autoCorrectEnglish = autoRestoreEnglish
        }
    }
    
    @Published public var escapeByDoubleKey: Bool = true {
        didSet {
            saveSettings()
            engineConfig.escapeByDoubleKey = escapeByDoubleKey
        }
    }
    
    @Published public var toggleShortcut: ToggleShortcut = .controlShift {
        didSet { saveSettings() }
    }
    
    @Published public var launchAtLogin: Bool = false {
        didSet {
            setLaunchAtLogin(launchAtLogin)
            saveSettings()
        }
    }
    
    @Published public var perAppInputMode: Bool = true {
        didSet { saveSettings() }
    }
    
    @Published public var blacklistedBundleIdentifiers: [String] = [
        "com.valvesoftware.steam",
        "com.riotgames.leagueoflegends"
    ] {
        didSet {
            updateBlacklistCache()
            saveSettings()
        }
    }
    
    @Published public var activeAppBundleId: String = ""
    @Published public var activeAppName: String = ""
    
    // MARK: - High-Performance In-Memory Caches for EventTap
    public private(set) var isBlacklistActive: Bool = false
    public var engineConfig: EngineConfig = EngineConfig()
    
    private let userDefaults = UserDefaults.standard
    private var perAppModes: [String: InputMode] = [:]
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
    
    // MARK: - Toggle Input Mode
    public func toggleInputMode() {
        currentInputMode = (currentInputMode == .vietnamese) ? .english : .vietnamese
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
    
    private func handleActiveAppChanged(bundleId: String, appName: String) {
        self.activeAppBundleId = bundleId
        self.activeAppName = appName
        self.isBlacklistActive = isApplicationBlacklisted(bundleId: bundleId)
        
        if perAppInputMode {
            if let savedMode = perAppModes[bundleId] {
                if self.currentInputMode != savedMode {
                    self.currentInputMode = savedMode
                }
            } else {
                // If it's a code editor or terminal, default to English for developer productivity
                if isDeveloperApp(bundleId: bundleId) {
                    self.currentInputMode = .english
                }
            }
        }
    }
    
    private func isDeveloperApp(bundleId: String) -> Bool {
        let devApps = [
            "com.apple.Terminal",
            "com.googlecode.iterm2",
            "dev.warp.Warp-Stable",
            "io.alacritty",
            "net.kovidgoyal.kitty",
            "com.microsoft.VSCode",
            "com.sublimetext.4",
            "com.jetbrains.intellij"
        ]
        return devApps.contains(bundleId)
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
    private func saveSettings() {
        userDefaults.set(currentInputMode.rawValue, forKey: "currentInputMode")
        userDefaults.set(currentInputMethod.rawValue, forKey: "currentInputMethod")
        userDefaults.set(currentTonePlacement.rawValue, forKey: "currentTonePlacement")
        userDefaults.set(autoRestoreEnglish, forKey: "autoRestoreEnglish")
        userDefaults.set(escapeByDoubleKey, forKey: "escapeByDoubleKey")
        userDefaults.set(toggleShortcut.rawValue, forKey: "toggleShortcut")
        userDefaults.set(perAppInputMode, forKey: "perAppInputMode")
        userDefaults.set(blacklistedBundleIdentifiers, forKey: "blacklistedBundleIdentifiers")
    }
    
    private func loadSettings() {
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
        if let shortcutStr = userDefaults.string(forKey: "toggleShortcut"),
           let shortcut = ToggleShortcut(rawValue: shortcutStr) {
            toggleShortcut = shortcut
        }
        if userDefaults.object(forKey: "perAppInputMode") != nil {
            perAppInputMode = userDefaults.bool(forKey: "perAppInputMode")
        }
        if let blacklist = userDefaults.stringArray(forKey: "blacklistedBundleIdentifiers") {
            blacklistedBundleIdentifiers = blacklist
        }
        
        if #available(macOS 13.0, *) {
            launchAtLogin = (SMAppService.mainApp.status == .enabled)
        }
        
        engineConfig = EngineConfig(
            inputMethod: currentInputMethod,
            tonePlacement: currentTonePlacement,
            autoCorrectEnglish: autoRestoreEnglish,
            escapeByDoubleKey: escapeByDoubleKey
        )
    }
    
    public func resetToDefaults() {
        currentInputMode = .vietnamese
        currentInputMethod = .telex
        currentTonePlacement = .modern
        autoRestoreEnglish = true
        escapeByDoubleKey = true
        toggleShortcut = .controlShift
        perAppInputMode = true
        blacklistedBundleIdentifiers = [
            "com.valvesoftware.steam",
            "com.riotgames.leagueoflegends"
        ]
        saveSettings()
    }
}

public extension Notification.Name {
    static let vietFlowInputModeChanged = Notification.Name("vietFlowInputModeChanged")
}
