//
//  PreferencesView.swift
//  VietFlowApp
//
//  Backward-compatible wrapper for SettingsView.
//  Strictly uses Apple SF Symbols, zero emojis.
//

import SwiftUI
import VietFlowEngine
import VietFlowState

public typealias PreferencesTab = SettingsTab

public struct PreferencesView: View {
    @ObservedObject var stateManager: AppStateManager
    public var onClose: (() -> Void)?

    public init(stateManager: AppStateManager = .shared, onClose: (() -> Void)? = nil) {
        self.stateManager = stateManager
        self.onClose = onClose
    }

    public var body: some View {
        SettingsView(stateManager: stateManager, onClose: onClose)
    }
}
