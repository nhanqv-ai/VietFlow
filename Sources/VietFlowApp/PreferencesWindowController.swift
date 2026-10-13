//
//  PreferencesWindowController.swift
//  VietFlowApp
//
//  Window controller hosting the SwiftUI PreferencesView.
//

import AppKit
import SwiftUI
import VietFlowState

public final class PreferencesWindowController: NSWindowController {
    public init(stateManager: AppStateManager = .shared) {
        let preferencesView = PreferencesView(stateManager: stateManager)
        let hostingController = NSHostingController(rootView: preferencesView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 480),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Cài đặt VietFlow"
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
