//
//  PreferencesWindowController.swift
//  VietFlowApp
//
//  Backward-compatible presenter and alias for SettingsWindowController.
//

import AppKit
import SwiftUI
import VietFlowState

public final class PreferencesWindowController: NSWindowController {
    public static var shared: SettingsWindowController {
        SettingsWindowController.shared
    }

    public let stateManager: AppStateManager

    public init(stateManager: AppStateManager = .shared) {
        self.stateManager = stateManager
        super.init(window: SettingsWindowController.shared.window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func showSettings() {
        SettingsWindowController.shared.showSettings()
    }

    public override func showWindow(_ sender: Any?) {
        SettingsWindowController.shared.showSettings()
    }
}
