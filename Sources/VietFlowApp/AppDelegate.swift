//
//  AppDelegate.swift
//  VietFlowApp
//
//  Application delegate managing lifecycle and Accessibility authorization.
//

import AppKit
import ApplicationServices
import VietFlowEventTap
import VietFlowState

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var permissionTimer: Timer?
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize Menu Bar item
        statusBarController = StatusBarController(stateManager: .shared)
        
        // Check and request Accessibility permissions
        checkAccessibilityPermissions()
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Background agent remains running in Menu Bar
    }
    
    private func checkAccessibilityPermissions() {
        if AXIsProcessTrusted() {
            startEventTap()
        } else {
            // Prompt user with native macOS Accessibility permission dialog
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
            
            // Poll every 1.0 second until user grants permission in System Settings
            permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                if AXIsProcessTrusted() {
                    timer.invalidate()
                    self?.permissionTimer = nil
                    self?.startEventTap()
                }
            }
        }
    }
    
    private func startEventTap() {
        let started = EventTapManager.shared.start()
        if started {
            NSLog("VietFlow: EventTap successfully started.")
        } else {
            NSLog("VietFlow: EventTap failed to start.")
        }
    }
}
