//
//  StatusBarController.swift
//  VietFlowApp
//
//  AppKit Menu Bar Status Item Controller.
//  Renders dynamic CoreGraphics vector glyphs (V/E) with zero emoji.
//

import AppKit
import Combine
import VietFlowEngine
import VietFlowState

public final class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private let stateManager: AppStateManager
    private var cancellables = Set<AnyCancellable>()
    private var preferencesWindowController: PreferencesWindowController?
    
    public init(stateManager: AppStateManager = .shared) {
        self.stateManager = stateManager
        super.init()
        
        setupStatusItem()
        observeState()
        updateIcon()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(handleStatusBarClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }
    
    private func observeState() {
        stateManager.$currentInputMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateIcon()
            }
            .store(in: &cancellables)
    }
    
    private func updateIcon() {
        guard let button = statusItem.button else { return }
        let mode = stateManager.currentInputMode
        let image = renderVectorStatusIcon(mode: mode)
        button.image = image
        button.toolTip = "VietFlow — \(mode.title) (Click trái để chuyển, Click phải để mở menu)"
    }
    
    // MARK: - Vector Status Glyphs (No Emoji, Dark/Light Mode Template)
    private func renderVectorStatusIcon(mode: InputMode) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()
        
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return image
        }
        
        ctx.clear(CGRect(x: 0, y: 0, width: 18, height: 18))
        
        let letter = mode.rawValue // "V" or "E"
        let font = NSFont.systemFont(ofSize: 13, weight: .bold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black // In template mode, macOS automatically inverts in dark mode
        ]
        
        let attrString = NSAttributedString(string: letter, attributes: attributes)
        let strSize = attrString.size()
        let x = (18 - strSize.width) / 2
        let y = (18 - strSize.height) / 2 + 0.5
        
        attrString.draw(at: NSPoint(x: x, y: y))
        
        image.unlockFocus()
        image.isTemplate = true // Allows automatic macOS system dark/light accenting
        return image
    }
    
    // MARK: - Click Handling
    @objc private func handleStatusBarClick(_ sender: NSStatusBarButton) {
        guard let currentEvent = NSApp.currentEvent else { return }
        
        if currentEvent.type == .rightMouseUp || currentEvent.modifierFlags.contains(.control) {
            // Right-click: Open Menu
            showContextMenu()
        } else {
            // Left-click: Toggle V/E
            stateManager.toggleInputMode()
        }
    }
    
    private func showContextMenu() {
        let menu = NSMenu(title: "VietFlow Menu")
        
        // Mode header
        let modeItem = NSMenuItem(
            title: "Chế độ: \(stateManager.currentInputMode.title) (\(stateManager.currentInputMode.rawValue))",
            action: #selector(toggleModeMenuAction),
            keyEquivalent: ""
        )
        modeItem.target = self
        menu.addItem(modeItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Input Method Submenu
        let methodMenu = NSMenu(title: "Kiểu gõ")
        for method in InputMethod.allCases {
            let item = NSMenuItem(
                title: method.rawValue,
                action: #selector(selectInputMethod(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = method
            item.state = (stateManager.currentInputMethod == method) ? NSControl.StateValue.on : NSControl.StateValue.off
            methodMenu.addItem(item)
        }
        let methodSubmenuItem = NSMenuItem(title: "Kiểu gõ", action: nil, keyEquivalent: "")
        methodSubmenuItem.submenu = methodMenu
        menu.addItem(methodSubmenuItem)
        
        // Tone Style Submenu
        let toneMenu = NSMenu(title: "Kiểu bỏ dấu")
        for tone in TonePlacementStyle.allCases {
            let title = (tone == .modern) ? "Dấu Mới (hòa, thúy)" : "Dấu Cũ (hoà, thuý)"
            let item = NSMenuItem(
                title: title,
                action: #selector(selectToneStyle(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = tone
            item.state = (stateManager.currentTonePlacement == tone) ? NSControl.StateValue.on : NSControl.StateValue.off
            toneMenu.addItem(item)
        }
        let toneSubmenuItem = NSMenuItem(title: "Quy tắc dấu", action: nil, keyEquivalent: "")
        toneSubmenuItem.submenu = toneMenu
        menu.addItem(toneSubmenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Preferences
        let prefItem = NSMenuItem(
            title: "Cài đặt (Preferences)...",
            action: #selector(openPreferences),
            keyEquivalent: ","
        )
        prefItem.target = self
        menu.addItem(prefItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(
            title: "Thoát VietFlow",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil // Restore click detection
    }
    
    @objc private func toggleModeMenuAction() {
        stateManager.toggleInputMode()
    }
    
    @objc private func selectInputMethod(_ sender: NSMenuItem) {
        if let method = sender.representedObject as? InputMethod {
            stateManager.currentInputMethod = method
        }
    }
    
    @objc private func selectToneStyle(_ sender: NSMenuItem) {
        if let tone = sender.representedObject as? TonePlacementStyle {
            stateManager.currentTonePlacement = tone
        }
    }
    
    @objc public func openPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController(stateManager: stateManager)
        }
        preferencesWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
