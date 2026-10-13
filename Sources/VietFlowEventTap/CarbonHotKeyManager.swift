//
//  CarbonHotKeyManager.swift
//  VietFlowEventTap
//
//  Carbon RegisterEventHotKey wrapper for global key combination shortcuts.
//  Adapted from SuperClip reference implementation with clean lifecycle management.
//

import Carbon
import AppKit
import VietFlowState

public protocol HotKeyManaging: AnyObject {
    var onTrigger: (() -> Void)? { get set }
    func register(keyCode: UInt32, modifiers: UInt32)
    func unregister()
}

public final class CarbonHotKeyManager: HotKeyManaging, @unchecked Sendable {
    public static let shared = CarbonHotKeyManager()
    public var onTrigger: (() -> Void)?
    
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private let signature: OSType = 0x5654464C // 'VTFL' (VietFlow)
    
    public var isRegistered: Bool {
        return hotKeyRef != nil
    }
    
    public init() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, _, userData) -> OSStatus in
                guard let userData = userData else { return noErr }
                let mgr = Unmanaged<CarbonHotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                mgr.onTrigger?()
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &handlerRef
        )
    }
    
    public func register(keyCode: UInt32, modifiers: UInt32) {
        unregister()
        let hotKeyID = EventHotKeyID(signature: signature, id: 1)
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        if status != noErr {
            NSLog("VietFlow: RegisterEventHotKey failed with status \(status)")
        }
    }
    
    public func register(combo: CustomKeyCombo) {
        register(keyCode: combo.keyCode, modifiers: combo.carbonModifiers)
    }
    
    public func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }
    
    deinit {
        unregister()
        if let hRef = handlerRef {
            RemoveEventHandler(hRef)
            handlerRef = nil
        }
    }
}
