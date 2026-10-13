//
//  ModifierChordStateMachine.swift
//  VietFlowEventTap
//
//  Pure 4-state finite state machine for deterministic modifier chord detection.
//  Zero wall-clock timeouts, strict bitmasking, order-independent.
//

import Foundation
import AppKit
import CoreGraphics
import VietFlowState

public final class ModifierChordStateMachine: @unchecked Sendable {
    public enum State: Equatable, Sendable {
        /// No modifier chord sequence in progress
        case idle
        /// Target modifiers are currently held down; no intervening key or mouse event has occurred
        case primed
        /// Target chord was released cleanly; waiting for all modifier keys to be released before returning to idle
        case triggered
        /// An intervening key, mouse click, or extraneous modifier occurred; chord is cancelled until all modifiers are released
        case cancelled
    }
    
    public typealias ModifierChordState = State
    public typealias ChordPreset = ModifierChordShortcut
    
    /// Strict mask of relevant modifier bits: Control, Shift, Option (Alternate), and Command.
    /// Strips device-specific flags, CapsLock, Fn, and other secondary flags.
    public static let relevantModifierMask: CGEventFlags = [
        .maskControl,
        .maskShift,
        .maskAlternate,
        .maskCommand
    ]
    
    public private(set) var state: State = .idle
    public var currentState: State { state }
    private var lastModifiers: CGEventFlags = []
    
    public var shortcut: ModifierChordShortcut {
        didSet {
            reset()
        }
    }
    
    public var currentPreset: ModifierChordShortcut {
        get { shortcut }
        set { shortcut = newValue }
    }
    
    public var onTrigger: (() -> Void)?
    
    public init(shortcut: ModifierChordShortcut = .controlShift, onTrigger: (() -> Void)? = nil) {
        self.shortcut = shortcut
        self.onTrigger = onTrigger
    }
    
    public convenience init(preset: ModifierChordShortcut, onTrigger: (() -> Void)? = nil) {
        self.init(shortcut: preset, onTrigger: onTrigger)
    }
    
    /// Converts NSEvent.ModifierFlags into CGEventFlags for unified chord detection.
    public static func cgFlags(from nsFlags: NSEvent.ModifierFlags) -> CGEventFlags {
        var flags: CGEventFlags = []
        if nsFlags.contains(.control) { flags.insert(.maskControl) }
        if nsFlags.contains(.shift) { flags.insert(.maskShift) }
        if nsFlags.contains(.option) { flags.insert(.maskAlternate) }
        if nsFlags.contains(.command) { flags.insert(.maskCommand) }
        return flags
    }
    
    /// Handles an NSEvent.ModifierFlags change by converting to CGEventFlags.
    @discardableResult
    public func handleNSEventFlagsChanged(_ nsFlags: NSEvent.ModifierFlags) -> Bool {
        return handleFlagsChanged(Self.cgFlags(from: nsFlags))
    }
    
    /// Handles a flagsChanged event with strict modifier bitmasking.
    /// Returns true if the modifier chord was cleanly released, triggering the action.
    @discardableResult
    public func handleFlagsChanged(_ rawFlags: CGEventFlags) -> Bool {
        let activeMods = rawFlags.intersection(Self.relevantModifierMask)
        lastModifiers = activeMods
        let target = shortcut.targetMask
        
        switch state {
        case .idle:
            if activeMods == target {
                state = .primed
            } else if (activeMods.rawValue & ~target.rawValue) != 0 {
                state = .cancelled
            }
            return false
            
        case .primed:
            if activeMods == target {
                // Modifiers are still held down
                return false
            } else if (activeMods.rawValue & ~target.rawValue) != 0 {
                // User pressed an extraneous modifier (e.g. Command added while holding Ctrl+Shift)
                state = .cancelled
                return false
            } else {
                // One or both chord keys were released cleanly with no intervening key or mouse click.
                // Trigger instantaneous action!
                state = activeMods.isEmpty ? .idle : .triggered
                onTrigger?()
                return true
            }
            
        case .triggered, .cancelled:
            if activeMods.isEmpty {
                state = .idle
            }
            return false
        }
    }
    
    /// Safeguard: Any key down event cancels a primed chord to prevent false triggers during typing or keyboard shortcuts.
    public func handleKeyDown() {
        if state == .primed || !lastModifiers.isEmpty {
            state = .cancelled
        }
    }
    
    /// Safeguard: Any mouse click event cancels a primed chord to prevent false triggers during cursor repositioning.
    public func handleMouseDown() {
        if state == .primed || !lastModifiers.isEmpty {
            state = .cancelled
        }
    }
    
    /// Resets the state machine back to idle.
    public func reset() {
        state = .idle
        lastModifiers = []
    }
}
