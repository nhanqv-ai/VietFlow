//
//  SettingsWindowController.swift
//  VietFlowApp
//
//  Window controller managing presentation and lifecycle of VietFlow Settings modal.
//  Adapted from SuperClip reference implementation.
//

import AppKit
import SwiftUI
import VietFlowState

public final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    public static let shared = SettingsWindowController()

    public let stateManager: AppStateManager
    private var hasBeenCentered: Bool = false

    public init(stateManager: AppStateManager = .shared) {
        self.stateManager = stateManager

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 490),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "VietFlow Settings"
        window.isReleasedWhenClosed = false
        window.level = .normal
        window.setContentSize(NSSize(width: 520, height: 490))
        window.setFrameAutosaveName("VietFlowSettingsWindow")

        super.init(window: window)
        window.delegate = self
        setupContentView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setupContentView() {
        guard let window = self.window else { return }
        let settingsView = SettingsView(
            stateManager: stateManager,
            onClose: { [weak self] in
                self?.close()
            }
        )
        let hostingController = NSHostingController(rootView: settingsView)
        hostingController.preferredContentSize = NSSize(width: 520, height: 490)
        window.contentViewController = hostingController
    }

    public func showSettings() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.showSettings()
            }
            return
        }
        guard let window = self.window else { return }
        if !hasBeenCentered && !window.isVisible {
            window.center()
            hasBeenCentered = true
        }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    public func windowWillClose(_ notification: Notification) {
        setupContentView()
    }
}
