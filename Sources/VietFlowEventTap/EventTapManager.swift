//
//  EventTapManager.swift
//  VietFlowEventTap
//
//  Low-level macOS EventTap keyboard interceptor and injector.
//

import Cocoa
import Carbon
import ApplicationServices
import VietFlowEngine
import VietFlowState

public enum EventLoopGuard {
    public static let magicMarker: Int64 = 0x564E4B59 // 'VNKY'
}

public final class EventTapManager: @unchecked Sendable {
    public static let shared = EventTapManager()
    
    private var machPort: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var watchdogTimer: DispatchSourceTimer?
    private let eventSource: CGEventSource
    
    public let engine: BambooEngine
    public let stateManager: AppStateManager
    
    // Modifier-only shortcut state machine
    private var lastModifierFlags: CGEventFlags = []
    private var modifierKeyDownTime: Date?
    private var interveningKeyDuringModifiers: Bool = false
    
    public init(engine: BambooEngine = BambooEngine(), stateManager: AppStateManager = .shared) {
        self.engine = engine
        self.stateManager = stateManager
        
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            fatalError("VietFlow: Unable to initialize CGEventSource")
        }
        source.userData = EventLoopGuard.magicMarker
        self.eventSource = source
    }
    
    // MARK: - Lifecycle
    public func start() -> Bool {
        guard AXIsProcessTrusted() else {
            return false
        }
        
        if machPort != nil {
            return true
        }
        
        let mask: CGEventMask =
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue) |
            (1 << CGEventType.leftMouseDown.rawValue) |
            (1 << CGEventType.rightMouseDown.rawValue) |
            (1 << CGEventType.otherMouseDown.rawValue)
        
        let selfPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        guard let port = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: eventTapCallbackBridge,
            userInfo: selfPointer
        ) else {
            return false
        }
        
        self.machPort = port
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: port, enable: true)
        
        startWatchdog()
        return true
    }
    
    public func stop() {
        watchdogTimer?.cancel()
        watchdogTimer = nil
        
        if let port = machPort {
            CGEvent.tapEnable(tap: port, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            }
        }
        machPort = nil
        runLoopSource = nil
    }
    
    private func startWatchdog() {
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer.schedule(deadline: .now() + 1.0, repeating: 1.0)
        timer.setEventHandler { [weak self] in
            guard let self = self, let port = self.machPort else { return }
            if !CGEvent.tapIsEnabled(tap: port) {
                CGEvent.tapEnable(tap: port, enable: true)
            }
        }
        timer.resume()
        self.watchdogTimer = timer
    }
    
    // MARK: - Event Tap Callback
    fileprivate func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // 1. Reactive Timeout & Disablement Handling
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let port = machPort {
                CGEvent.tapEnable(tap: port, enable: true)
            }
            return nil
        }
        
        // 2. Prevent Infinite Loop: Ignore our own synthetic events
        let userData = event.getIntegerValueField(.eventSourceUserData)
        if userData == EventLoopGuard.magicMarker {
            return Unmanaged.passRetained(event)
        }
        
        // 3. Secure Input Bypass (Passwords, TouchID, Terminal sudo)
        if IsSecureEventInputEnabled() {
            engine.reset()
            return Unmanaged.passRetained(event)
        }
        
        // 4. Mouse click boundary: caret repositioned, reset buffer
        if type == .leftMouseDown || type == .rightMouseDown || type == .otherMouseDown {
            engine.reset()
            return Unmanaged.passRetained(event)
        }
        
        // 5. Modifier flags changed (Global V/E Toggle Shortcut Detection)
        if type == .flagsChanged {
            handleFlagsChanged(event: event)
            return Unmanaged.passRetained(event)
        }
        
        // 6. Key Up handling
        if type == .keyUp {
            return Unmanaged.passRetained(event)
        }
        
        // 7. Key Down processing
        guard type == .keyDown else {
            return Unmanaged.passRetained(event)
        }
        
        interveningKeyDuringModifiers = true
        
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        
        // Check for command shortcuts (Cmd+C, Cmd+V, Cmd+A, etc.) or Ctrl combinations
        if flags.contains(.maskCommand) || flags.contains(.maskControl) {
            engine.reset()
            return Unmanaged.passRetained(event)
        }
        
        // Check for navigation / editing boundaries
        switch keyCode {
        case 36, 76: // Return, Enter
            engine.reset()
            return Unmanaged.passRetained(event)
        case 48: // Tab
            engine.reset()
            return Unmanaged.passRetained(event)
        case 53: // Escape
            engine.reset()
            return Unmanaged.passRetained(event)
        case 123, 124, 125, 126: // Arrow keys
            engine.reset()
            return Unmanaged.passRetained(event)
        case 115, 116, 119, 121: // Home, PageUp, End, PageDown
            engine.reset()
            return Unmanaged.passRetained(event)
        case 51: // Backspace (Delete)
            if stateManager.currentInputMode == .vietnamese && !stateManager.isBlacklistActive {
                _ = engine.handleBackspace()
            }
            return Unmanaged.passRetained(event)
        default:
            break
        }
        
        // If mode is English or active app is blacklisted, pass key through immediately
        guard stateManager.currentInputMode == .vietnamese, !stateManager.isBlacklistActive else {
            return Unmanaged.passRetained(event)
        }
        
        // Extract Unicode character from event
        var length = 0
        event.keyboardGetUnicodeString(maxStringLength: 0, actualStringLength: &length, unicodeString: nil)
        guard length > 0 else {
            return Unmanaged.passRetained(event)
        }
        
        var buffer = [UniChar](repeating: 0, count: length)
        event.keyboardGetUnicodeString(maxStringLength: length, actualStringLength: &length, unicodeString: &buffer)
        let typedString = String(utf16CodeUnits: buffer, count: length)
        
        guard let typedChar = typedString.first, typedString.count == 1 else {
            engine.reset()
            return Unmanaged.passRetained(event)
        }
        
        // Process through BambooEngine
        if let delta = engine.processKey(typedChar) {
            applyDelta(delta)
            return nil // Swallow the triggering key!
        }
        
        // No transformation: let the original key down event pass through to client app
        return Unmanaged.passRetained(event)
    }
    
    // MARK: - Key Injection
    private func applyDelta(_ delta: TextDelta) {
        // 1. Post Virtual Backspaces
        for _ in 0..<delta.backspaces {
            postVirtualKey(keyCode: 51, unicodeChar: nil)
        }
        
        // 2. Post Precomposed Unicode Replacement Characters
        let precomposedText = delta.insertText.precomposedStringWithCanonicalMapping
        for char in precomposedText.utf16 {
            postVirtualKey(keyCode: 0, unicodeChar: char)
        }
    }
    
    private func postVirtualKey(keyCode: CGKeyCode, unicodeChar: UniChar?) {
        guard let down = CGEvent(keyboardEventSource: eventSource, virtualKey: keyCode, keyDown: true),
              let up = CGEvent(keyboardEventSource: eventSource, virtualKey: keyCode, keyDown: false) else {
            return
        }
        
        if var char = unicodeChar {
            down.keyboardSetUnicodeString(stringLength: 1, unicodeString: &char)
            up.keyboardSetUnicodeString(stringLength: 1, unicodeString: &char)
        }
        
        down.setIntegerValueField(.eventSourceUserData, value: EventLoopGuard.magicMarker)
        up.setIntegerValueField(.eventSourceUserData, value: EventLoopGuard.magicMarker)
        
        down.flags = []
        up.flags = []
        
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }
    
    // MARK: - Shortcut Detection
    private func handleFlagsChanged(event: CGEvent) {
        let currentFlags = event.flags
        let previousFlags = lastModifierFlags
        lastModifierFlags = currentFlags
        
        let shortcut = stateManager.toggleShortcut
        
        // Match modifier key down
        let matchesDown: Bool
        switch shortcut {
        case .controlShift:
            matchesDown = currentFlags.contains(.maskControl) && currentFlags.contains(.maskShift)
        case .commandShift:
            matchesDown = currentFlags.contains(.maskCommand) && currentFlags.contains(.maskShift)
        case .option:
            matchesDown = currentFlags.contains(.maskAlternate) && !currentFlags.contains(.maskCommand) && !currentFlags.contains(.maskControl)
        case .optionShift:
            matchesDown = currentFlags.contains(.maskAlternate) && currentFlags.contains(.maskShift)
        }
        
        if matchesDown && modifierKeyDownTime == nil {
            modifierKeyDownTime = Date()
            interveningKeyDuringModifiers = false
        }
        
        // Match modifier key release (clean tap without intervening keys within 500ms)
        let matchesUp: Bool
        switch shortcut {
        case .controlShift:
            matchesUp = previousFlags.contains(.maskControl) && previousFlags.contains(.maskShift) && (!currentFlags.contains(.maskControl) || !currentFlags.contains(.maskShift))
        case .commandShift:
            matchesUp = previousFlags.contains(.maskCommand) && previousFlags.contains(.maskShift) && (!currentFlags.contains(.maskCommand) || !currentFlags.contains(.maskShift))
        case .option:
            matchesUp = previousFlags.contains(.maskAlternate) && !currentFlags.contains(.maskAlternate)
        case .optionShift:
            matchesUp = previousFlags.contains(.maskAlternate) && previousFlags.contains(.maskShift) && (!currentFlags.contains(.maskAlternate) || !currentFlags.contains(.maskShift))
        }
        
        if matchesUp, let downTime = modifierKeyDownTime {
            let duration = Date().timeIntervalSince(downTime)
            if duration < 0.5 && !interveningKeyDuringModifiers {
                DispatchQueue.main.async { [weak self] in
                    self?.stateManager.toggleInputMode()
                }
            }
            modifierKeyDownTime = nil
            interveningKeyDuringModifiers = false
        }
    }
}

// C-bridge function pointer
private func eventTapCallbackBridge(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon = refcon else {
        return Unmanaged.passRetained(event)
    }
    let manager = Unmanaged<EventTapManager>.fromOpaque(refcon).takeUnretainedValue()
    return manager.handleEvent(proxy: proxy, type: type, event: event)
}
