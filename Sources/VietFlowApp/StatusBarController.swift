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
    
    // MARK: - Vector Status Glyphs (Pattern A: Tactile Keycap Squircle)
    private func renderVectorStatusIcon(mode: InputMode) -> NSImage {
        let size = NSSize(width: 19, height: 19)
        let image = NSImage(size: size)
        image.lockFocus()
        
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return image
        }
        
        ctx.clear(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        
        let boxRect = CGRect(x: 1.5, y: 1.5, width: 16.0, height: 16.0)
        let boxPath = CGPath(roundedRect: boxRect, cornerWidth: 4.8, cornerHeight: 4.8, transform: nil)
        
        if mode == .vietnamese {
            // Active Vietnamese mode: Solid filled keycap with knocked-out "V"
            ctx.saveGState()
            ctx.addPath(boxPath)
            ctx.setFillColor(NSColor.black.cgColor)
            ctx.fillPath()
            
            ctx.setBlendMode(.destinationOut)
            let font = NSFont.systemFont(ofSize: 11.2, weight: .heavy)
            let text = "V" as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.black
            ]
            let strSize = text.size(withAttributes: attrs)
            text.draw(
                at: CGPoint(
                    x: (size.width - strSize.width) / 2,
                    y: (size.height - strSize.height) / 2 + 0.5
                ),
                withAttributes: attrs
            )
            ctx.restoreGState()
        } else {
            // English mode: Outlined keycap with centered "E"
            ctx.saveGState()
            ctx.addPath(boxPath)
            ctx.setStrokeColor(NSColor.black.cgColor)
            ctx.setLineWidth(1.3)
            ctx.strokePath()
            
            let font = NSFont.systemFont(ofSize: 10.8, weight: .bold)
            let text = "E" as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.black
            ]
            let strSize = text.size(withAttributes: attrs)
            text.draw(
                at: CGPoint(
                    x: (size.width - strSize.width) / 2,
                    y: (size.height - strSize.height) / 2 + 0.5
                ),
                withAttributes: attrs
            )
            ctx.restoreGState()
        }
        
        image.unlockFocus()
        image.isTemplate = true // macOS automatically renders white in Dark Mode, dark in Light Mode
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
    
    private var activeShortcutLabel: String {
        switch stateManager.shortcutType {
        case .modifierChord:
            return stateManager.modifierChord.title
        case .customKeyCombo:
            return KeyCombinationHelper.formattedSymbolShortcut(
                keyCode: stateManager.customKeyCombo.keyCode,
                modifiers: stateManager.customKeyCombo.carbonModifiers
            )
        }
    }
    
    private func showContextMenu() {
        let menu = NSMenu(title: "VietFlow Menu")
        
        if !AccessibilityService.shared.isAccessibilityTrusted {
            let permItem = NSMenuItem(
                title: "Cấp quyền Trợ năng (Cần thiết để gõ tiếng Việt)...",
                action: #selector(grantAccessibilityAction),
                keyEquivalent: ""
            )
            permItem.target = self
            menu.addItem(permItem)
            menu.addItem(NSMenuItem.separator())
        }
        
        // Mode header
        let modeItem = NSMenuItem(
            title: "Chế độ: \(stateManager.currentInputMode.title) [\(stateManager.currentInputMode.rawValue)] — \(activeShortcutLabel)",
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
        
        // Preferences / Settings
        let prefItem = NSMenuItem(
            title: "Cài đặt (Settings)...",
            action: #selector(openSettings),
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
    
    @objc private func grantAccessibilityAction() {
        _ = AccessibilityService.shared.resetAndRequestAccessibilityPermission()
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
    
    @objc public func openSettings() {
        SettingsWindowController.shared.showSettings()
    }
    
    @objc public func openPreferences() {
        SettingsWindowController.shared.showSettings()
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
