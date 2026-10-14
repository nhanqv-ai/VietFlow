//
//  AccessibilityService.swift
//  VietFlowApp
//
//  Manages macOS Accessibility authorization detection, TCC reset,
//  and System Settings coordination. Strictly 0 emojis.
//

import AppKit
import ApplicationServices
import Combine

public extension Notification.Name {
    static let vietFlowAccessibilityStatusChanged = Notification.Name("vietFlowAccessibilityStatusChanged")
}

public final class AccessibilityService: ObservableObject, @unchecked Sendable {
    public static let shared = AccessibilityService()

    @Published public private(set) var isTrusted: Bool = false

    /// Current accessibility status via AXIsProcessTrusted.
    public var isAccessibilityTrusted: Bool {
        return accessibilityChecker()
    }

    private var cancellables = Set<AnyCancellable>()
    private var notificationObservers: [NSObjectProtocol] = []
    public let bundleIdentifier: String

    // Dependency-injected closures for unit testing and headless execution
    public var accessibilityChecker: () -> Bool
    public var accessibilityPrompter: () -> Bool
    public var accessibilityResetter: () -> Bool
    public var settingsOpener: () -> Void
    public let dispatchQueue: DispatchQueue

    public init(
        bundleIdentifier: String = Bundle.main.bundleIdentifier ?? "com.nhanqv.VietFlow",
        accessibilityChecker: @escaping () -> Bool = { AXIsProcessTrusted() },
        accessibilityPrompter: @escaping () -> Bool = {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            return AXIsProcessTrustedWithOptions(options)
        },
        accessibilityResetter: @escaping () -> Bool = {
            let bundleId = Bundle.main.bundleIdentifier ?? "com.nhanqv.VietFlow"
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
            process.arguments = ["reset", "Accessibility", bundleId]
            do {
                try process.run()
                process.waitUntilExit()
                return process.terminationStatus == 0
            } catch {
                return false
            }
        },
        settingsOpener: @escaping () -> Void = {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"),
               NSWorkspace.shared.open(url) {
                return
            }
            if let fallbackURL = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
                NSWorkspace.shared.open(fallbackURL)
            }
        },
        dispatchQueue: DispatchQueue = .main
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.accessibilityChecker = accessibilityChecker
        self.accessibilityPrompter = accessibilityPrompter
        self.accessibilityResetter = accessibilityResetter
        self.settingsOpener = settingsOpener
        self.dispatchQueue = dispatchQueue
        self.isTrusted = accessibilityChecker()

        setupNotificationObservers()
    }

    private func setupNotificationObservers() {
        // Re-check when app becomes active or key window
        let activeObs = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.refresh()
        }
        notificationObservers.append(activeObs)

        let keyObs = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.refresh()
        }
        notificationObservers.append(keyObs)

        // Listen to system-wide accessibility API permission changes
        let distObs = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.accessibility.api"),
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.dispatchQueue.asyncAfter(deadline: .now() + 0.1) {
                self?.refresh()
            }
        }
        notificationObservers.append(distObs)
    }

    deinit {
        for obs in notificationObservers {
            NotificationCenter.default.removeObserver(obs)
            DistributedNotificationCenter.default().removeObserver(obs)
        }
    }

    /// Live refresh of AXIsProcessTrusted status
    public func refresh() {
        dispatchQueue.async { [weak self] in
            guard let self = self else { return }
            let current = self.accessibilityChecker()
            if self.isTrusted != current {
                self.isTrusted = current
                NotificationCenter.default.post(name: .vietFlowAccessibilityStatusChanged, object: self)
            }
        }
    }

    /// Evaluates whether the process has macOS Accessibility permission.
    public func checkAccessibilityPermission() -> Bool {
        return accessibilityChecker()
    }

    /// Triggers system accessibility permission prompt dialog.
    @discardableResult
    public func requestAccessibilityPermission() -> Bool {
        return accessibilityPrompter()
    }

    /// Resets TCC accessibility approval cache entry for VietFlow bundle ID.
    @discardableResult
    public func resetAccessibilityPermission() -> Bool {
        return accessibilityResetter()
    }

    /// Flushes stale TCC cache entry for VietFlow, opens System Settings -> Accessibility,
    /// and triggers fresh system authorization prompt.
    @discardableResult
    public func resetAndRequestAccessibilityPermission() -> Bool {
        _ = resetAccessibilityPermission()
        openAccessibilitySettings()
        let requested = requestAccessibilityPermission()
        for delay in [0.5, 1.0, 2.0, 3.0] {
            dispatchQueue.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.refresh()
            }
        }
        return requested
    }

    /// Opens macOS System Settings directly to Privacy & Security -> Accessibility.
    public func openAccessibilitySettings() {
        settingsOpener()
    }

    /// Computes a unique signature for the current executable binary (modification timestamp + size + version)
    /// so ad-hoc re-signed builds are reliably detected even when CFBundleVersion stays constant.
    public static func currentBinarySignature() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1.2.0"
        if let execURL = Bundle.main.executableURL,
           let attrs = try? FileManager.default.attributesOfItem(atPath: execURL.path) {
            let mtime = (attrs[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0
            let size = (attrs[.size] as? NSNumber)?.uint64Value ?? 0
            return "\(version)-\(Int64(mtime))-\(size)"
        }
        return version
    }

    /// Handles stale ad-hoc CDHash TCC state on startup once per binary signature.
    @discardableResult
    public func handleStartupTCCResetIfNeeded(signatureOverride: String? = nil) -> Bool {
        if !isAccessibilityTrusted {
            let defaultsKey = "VietFlowLastTCCResetBuild"
            let currentSig = signatureOverride ?? Self.currentBinarySignature()
            let lastReset = UserDefaults.standard.string(forKey: defaultsKey)
            if lastReset != currentSig {
                let didReset = resetAccessibilityPermission()
                UserDefaults.standard.set(currentSig, forKey: defaultsKey)
                return didReset
            }
        }
        return false
    }
}

public typealias AccessibilityPermissionHelper = AccessibilityService
