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
    public private(set) var statusItem: NSStatusItem!
    public let stateManager: AppStateManager
    private var cancellables = Set<AnyCancellable>()
    
    public init(stateManager: AppStateManager = .shared) {
        self.stateManager = stateManager
        super.init()
        
        setupStatusItem()
        observeState()
        updateIcon()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: 26)
        
        guard let button = statusItem.button else { return }
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleNone
        button.target = self
        button.action = #selector(handleStatusBarClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }
    
    private func observeState() {
        Publishers.CombineLatest(stateManager.$currentInputMode, stateManager.$isSuspendedByForeignIME)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mode, isSuspended in
                self?.updateStatus(mode: mode, isSuspended: isSuspended)
            }
            .store(in: &cancellables)
    }
    
    public func updateIcon() {
        updateStatus(mode: stateManager.currentInputMode, isSuspended: stateManager.isSuspendedByForeignIME)
    }
    
    private func updateStatus(mode: InputMode, isSuspended: Bool) {
        guard let button = statusItem.button else { return }
        let image = renderVectorStatusIcon(mode: mode)
        button.image = image
        if isSuspended {
            button.toolTip = "VietFlow — Chế độ: Tạm ngưng — Đang nhường bộ gõ Ngoại ngữ [E] (Click để kích hoạt Tiếng Việt)"
        } else {
            button.toolTip = "VietFlow — \(mode.title) (Click trái để chuyển, Click phải để mở menu)"
        }
    }
    
    // MARK: - Vector Status Glyphs (Large Tactile Keycap Squircle)
    public func renderVectorStatusIcon(mode: InputMode) -> NSImage {
        let size = NSSize(width: 22, height: 22)
        let image = NSImage(size: size)
        image.lockFocus()
        
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return image
        }
        
        ctx.clear(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        
        if mode == .vietnamese {
            // Active Vietnamese mode: Large solid filled keycap (19.5 x 19.5pt) with knocked-out bold "V"
            let boxRect = CGRect(x: 1.25, y: 1.25, width: 19.5, height: 19.5)
            let boxPath = CGPath(roundedRect: boxRect, cornerWidth: 4.6, cornerHeight: 4.6, transform: nil)
            
            ctx.saveGState()
            ctx.addPath(boxPath)
            ctx.setFillColor(NSColor.black.cgColor)
            ctx.fillPath()
            
            ctx.setBlendMode(.destinationOut)
            drawCenteredGlyph("V", fontSize: 14.2, weight: .black, in: boxRect, context: ctx)
            ctx.restoreGState()
        } else {
            // English mode: Large outlined keycap (18.8 x 18.8pt stroke center -> 20.4pt outer) with bold "E"
            let boxRect = CGRect(x: 1.6, y: 1.6, width: 18.8, height: 18.8)
            let boxPath = CGPath(roundedRect: boxRect, cornerWidth: 4.6, cornerHeight: 4.6, transform: nil)
            
            ctx.saveGState()
            ctx.addPath(boxPath)
            ctx.setStrokeColor(NSColor.black.cgColor)
            ctx.setLineWidth(1.65)
            ctx.strokePath()
            
            drawCenteredGlyph("E", fontSize: 13.8, weight: .heavy, in: boxRect, context: ctx)
            ctx.restoreGState()
        }
        
        image.unlockFocus()
        image.isTemplate = true // macOS automatically renders white in Dark Mode, dark in Light Mode
        return image
    }
    
    private func drawCenteredGlyph(
        _ string: String,
        fontSize: CGFloat,
        weight: NSFont.Weight,
        in rect: CGRect,
        context ctx: CGContext
    ) {
        let baseFont = NSFont.systemFont(ofSize: fontSize, weight: weight)
        let font: NSFont
        if let roundedDesc = baseFont.fontDescriptor.withDesign(.rounded),
           let roundedFont = NSFont(descriptor: roundedDesc, size: fontSize) {
            font = roundedFont
        } else {
            font = baseFont
        }
        
        let attrString = NSAttributedString(
            string: string,
            attributes: [
                .font: font,
                .foregroundColor: NSColor.black
            ]
        )
        let line = CTLineCreateWithAttributedString(attrString)
        let glyphBounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
        
        let tx = rect.midX - glyphBounds.midX
        let ty = rect.midY - glyphBounds.midY
        
        ctx.saveGState()
        ctx.textMatrix = .identity
        ctx.translateBy(x: tx, y: ty)
        CTLineDraw(line, ctx)
        ctx.restoreGState()
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
    
    private func inputMethodTitle(_ method: InputMethod) -> String {
        switch method {
        case .telex: return "Telex (Tiêu chuẩn)"
        case .simpleTelex: return "Simple Telex"
        case .vni: return "VNI"
        }
    }
    
    public func buildContextMenu() -> NSMenu {
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
        let modeHeaderTitle: String
        if stateManager.isSuspendedByForeignIME {
            modeHeaderTitle = "Chế độ: Tạm ngưng — Đang nhường bộ gõ Ngoại ngữ [E]"
        } else {
            modeHeaderTitle = "Chế độ: \(stateManager.currentInputMode.title) [\(stateManager.currentInputMode.rawValue)] — \(activeShortcutLabel)"
        }
        let modeItem = NSMenuItem(
            title: modeHeaderTitle,
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
                title: inputMethodTitle(method),
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
        
        // Check for updates
        let updateItem = NSMenuItem(
            title: "Kiểm tra cập nhật...",
            action: #selector(checkForUpdatesMenuAction),
            keyEquivalent: ""
        )
        updateItem.target = self
        if #available(macOS 11.0, *) {
            updateItem.image = NSImage(systemSymbolName: "arrow.triangle.2.circlepath", accessibilityDescription: nil)
        }
        menu.addItem(updateItem)
        
        // Quit
        let quitItem = NSMenuItem(
            title: "Thoát VietFlow",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        return menu
    }
    
    private func showContextMenu() {
        let menu = buildContextMenu()
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
    
    @objc public func checkForUpdatesMenuAction() {
        SettingsWindowController.shared.showSettings(tab: .about)
        UpdateManager.shared.checkForUpdates(userInitiated: true)
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
