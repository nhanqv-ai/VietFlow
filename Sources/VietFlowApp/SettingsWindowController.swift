//
//  SettingsWindowController.swift
//  VietFlowApp
//
//  Window controller managing presentation and lifecycle of VietFlow Settings modal.
//  Strictly enforces 520x520 pt geometry and eliminates stale autosave frames.
//

import AppKit
import SwiftUI
import VietFlowState

/// Custom NSWindow that strictly locks its content geometry to 520x520 pt.
public final class SettingsWindow: NSWindow {
    public override func setFrame(_ frameRect: NSRect, display flag: Bool) {
        var clampedRect = frameRect
        let targetSize = self.frameRect(forContentRect: NSRect(origin: .zero, size: SettingsWindowController.fixedSize)).size
        clampedRect.size = targetSize
        super.setFrame(clampedRect, display: flag)
    }

    public override func setFrame(_ frameRect: NSRect, display flag: Bool, animate: Bool) {
        var clampedRect = frameRect
        let targetSize = self.frameRect(forContentRect: NSRect(origin: .zero, size: SettingsWindowController.fixedSize)).size
        clampedRect.size = targetSize
        super.setFrame(clampedRect, display: flag, animate: animate)
    }

    public override func setContentSize(_ size: NSSize) {
        super.setContentSize(SettingsWindowController.fixedSize)
    }
}

public final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    public static let shared = SettingsWindowController()

    public static let fixedSize = NSSize(width: 520, height: 520)
    public static let autosaveKey = "VietFlowSettingsWindow"
    private static let userDefaultsFrameKey = "NSWindow Frame VietFlowSettingsWindow"

    public let stateManager: AppStateManager
    private var hasBeenCentered: Bool = false

    public init(stateManager: AppStateManager = .shared) {
        self.stateManager = stateManager

        // Purge any stale narrower autosaved frame from UserDefaults
        UserDefaults.standard.removeObject(forKey: Self.userDefaultsFrameKey)

        let window = SettingsWindow(
            contentRect: NSRect(origin: .zero, size: Self.fixedSize),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "VietFlow Settings"
        window.isReleasedWhenClosed = false
        window.level = .normal
        window.setContentSize(Self.fixedSize)
        window.minSize = Self.fixedSize
        window.maxSize = Self.fixedSize
        window.setFrameAutosaveName(Self.autosaveKey)

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
        hostingController.preferredContentSize = Self.fixedSize
        window.contentViewController = hostingController
        window.setContentSize(Self.fixedSize)
    }

    public func showSettings() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.showSettings()
            }
            return
        }
        guard let window = self.window else { return }

        // Enforce fixed 520x520 geometry on presentation
        window.setContentSize(Self.fixedSize)

        if !hasBeenCentered && !window.isVisible {
            window.center()
            hasBeenCentered = true
        }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    public func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        guard let window = self.window else { return frameSize }
        return window.frameRect(forContentRect: NSRect(origin: .zero, size: Self.fixedSize)).size
    }

    public func windowWillClose(_ notification: Notification) {
        setupContentView()
    }
}
