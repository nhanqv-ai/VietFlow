//
//  AppDelegate.swift
//  VietFlowApp
//
//  Application delegate managing lifecycle and Accessibility authorization.
//

import AppKit
import ApplicationServices
import UserNotifications
import VietFlowEventTap
import VietFlowState

public final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var statusBarController: StatusBarController?
    private var permissionTimer: Timer?
    private var accessibilityObserver: NSObjectProtocol?
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. Immediately initialize EventTapManager & shortcut monitors (Local + Global + Carbon)
        // so Ctrl+Shift and custom shortcuts work unconditionally from launch!
        _ = EventTapManager.shared
        EventTapManager.shared.startShortcutMonitors()
        EventTapManager.shared.updateShortcutConfiguration()
        
        // 2. Initialize Menu Bar item
        statusBarController = StatusBarController(stateManager: .shared)
        
        // 3. Observe Accessibility permission changes to start CGEventTap immediately when granted
        accessibilityObserver = NotificationCenter.default.addObserver(
            forName: .vietFlowAccessibilityStatusChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            if AccessibilityService.shared.isAccessibilityTrusted {
                self?.startEventTap()
            }
        }
        
        // 4. Check and request Accessibility permissions (auto-flushing stale ad-hoc TCC cache if needed)
        checkAccessibilityPermissions()
        
        // 5. Wire native macOS notifications (UNUserNotificationCenter)
        if Bundle.main.bundleIdentifier != nil {
            let center = UNUserNotificationCenter.current()
            center.delegate = self
        }
        
        // 6. Initialize auto-updater & background checks
        UpdateManager.shared.checkOnStartupIfNeeded(stateManager: .shared)
        UpdateManager.shared.startPeriodicCheck(stateManager: .shared)
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        UpdateManager.shared.stopPeriodicCheck()
        permissionTimer?.invalidate()
        if let observer = accessibilityObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if Bundle.main.bundleIdentifier != nil {
            let center = UNUserNotificationCenter.current()
            center.removeAllPendingNotificationRequests()
            center.removeAllDeliveredNotifications()
        }
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Background agent remains running in Menu Bar
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if #available(macOS 11.0, *) {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        if identifier.hasPrefix("com.nhanqv.vietflow.update") {
            SettingsWindowController.shared.showSettings(tab: .about)
        }
        completionHandler()
    }
    
    private func checkAccessibilityPermissions() {
        if AccessibilityService.shared.isAccessibilityTrusted {
            startEventTap()
        } else {
            // Flush stale TCC entry if this is a freshly compiled ad-hoc binary
            _ = AccessibilityService.shared.handleStartupTCCResetIfNeeded()
            
            // Prompt user with native macOS Accessibility permission dialog
            _ = AccessibilityService.shared.requestAccessibilityPermission()
            
            // Poll every 1.0 second until user grants permission in System Settings
            permissionTimer?.invalidate()
            permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                AccessibilityService.shared.refresh()
                if AccessibilityService.shared.isAccessibilityTrusted {
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
            permissionTimer?.invalidate()
            permissionTimer = nil
            AccessibilityService.shared.refresh()
            NSLog("VietFlow: EventTap successfully started.")
        } else {
            NSLog("VietFlow: EventTap failed to start.")
        }
    }
}
