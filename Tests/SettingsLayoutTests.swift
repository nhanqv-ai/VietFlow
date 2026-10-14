//
//  SettingsLayoutTests.swift
//  VietFlowTests
//
//  Automated programmatic layout and offscreen bitmap verification test suite.
//  Verifies fittingSize <= 520 across all states and zero pixel clipping in margin strips.
//

import AppKit
import SwiftUI
import Carbon
import VietFlowEngine
import VietFlowState
import VietFlowEventTap
import VietFlowApp
import VietFlowEngineTests

public final class SettingsLayoutTests: TestCase {

    private let fixedWindowSize = NSSize(width: 520, height: 520)

    public override func setUp() {
        super.setUp()
        AppStateManager.shared.resetToDefaults()
        UpdateManager.shared.status = .idle
        UpdateManager.shared.hasPendingUpdate = false
        UpdateManager.shared.isBannerDismissedForSession = false
    }

    public override func tearDown() {
        UpdateManager.shared.status = .idle
        UpdateManager.shared.hasPendingUpdate = false
        UpdateManager.shared.isBannerDismissedForSession = false
        AppStateManager.shared.resetToDefaults()
        super.tearDown()
    }

    // MARK: - Test 1: fittingSize <= 520 Across All Tabs & Sub-Modes
    func test_01_fitting_size_across_all_tabs_and_submodes() {
        let state = AppStateManager.shared

        // Tab 1: Keyboard
        assertTabFittingSize(tab: .keyboard, state: state)

        // Tab 2: Shortcuts (modifierChord)
        state.shortcutType = .modifierChord
        assertTabFittingSize(tab: .shortcuts, state: state)

        // Tab 2: Shortcuts (customKeyCombo)
        state.shortcutType = .customKeyCombo
        assertTabFittingSize(tab: .shortcuts, state: state)

        // Tab 3: Applications
        assertTabFittingSize(tab: .applications, state: state)

        // Tab 4: About
        assertTabFittingSize(tab: .about, state: state)
    }

    private func assertTabFittingSize(tab: SettingsTab, state: AppStateManager) {
        let view = SettingsView(stateManager: state, initialTab: tab)
        let hc = NSHostingController(rootView: view)
        let targetView = hc.view
        targetView.frame = NSRect(origin: .zero, size: fixedWindowSize)
        targetView.layoutSubtreeIfNeeded()

        let fitting = targetView.fittingSize
        XCTAssertTrue(fitting.width <= 520.0, "Tab \(tab.rawValue) fittingSize.width (\(fitting.width)) exceeds 520pt!")
        XCTAssertTrue(fitting.height <= 520.0, "Tab \(tab.rawValue) fittingSize.height (\(fitting.height)) exceeds 520pt!")
    }

    // MARK: - Test 2: Internal ScrollView Content Does Not Overflow
    func test_02_internal_scrollviews_do_not_overflow() {
        let state = AppStateManager.shared

        for tab in SettingsTab.allCases {
            let view = SettingsView(stateManager: state, initialTab: tab)
            let hc = NSHostingController(rootView: view)
            let targetView = hc.view
            targetView.frame = NSRect(origin: .zero, size: fixedWindowSize)
            targetView.layoutSubtreeIfNeeded()

            func checkScrollViews(_ v: NSView) {
                if let sv = v as? NSScrollView {
                    XCTAssertTrue(sv.frame.width <= 520.0, "ScrollView in \(tab.rawValue) has frame width \(sv.frame.width) > 520.0")
                    if let doc = sv.documentView {
                        XCTAssertTrue(doc.frame.width <= 520.0, "ScrollView documentView in \(tab.rawValue) has width \(doc.frame.width) > 520.0")
                    }
                }
                for sub in v.subviews {
                    checkScrollViews(sub)
                }
            }
            checkScrollViews(targetView)
        }
    }

    // MARK: - Test 3: Offscreen Bitmap Margin Strip Verification (cacheDisplay)
    func test_03_offscreen_bitmap_margin_strips_zero_violations() {
        let state = AppStateManager.shared

        let testConfigurations: [(tab: SettingsTab, shortcut: ShortcutType)] = [
            (.keyboard, .modifierChord),
            (.shortcuts, .modifierChord),
            (.shortcuts, .customKeyCombo),
            (.applications, .modifierChord),
            (.about, .modifierChord)
        ]

        for config in testConfigurations {
            state.shortcutType = config.shortcut
            let view = SettingsView(stateManager: state, initialTab: config.tab)
            let hc = NSHostingController(rootView: view)
            let targetView = hc.view
            targetView.frame = NSRect(origin: .zero, size: fixedWindowSize)
            targetView.layoutSubtreeIfNeeded()

            guard let rep = targetView.bitmapImageRepForCachingDisplay(in: NSRect(origin: .zero, size: fixedWindowSize)) else {
                XCTFail("Failed to allocate NSBitmapImageRep for \(config.tab.rawValue)")
                continue
            }
            targetView.cacheDisplay(in: NSRect(origin: .zero, size: fixedWindowSize), to: rep)

            let scale = CGFloat(rep.pixelsWide) / 520.0
            guard let bg = rep.colorAt(x: Int(2 * scale), y: Int(100 * scale)) else {
                XCTFail("Failed to sample background color for \(config.tab.rawValue)")
                continue
            }

            var leftViolations = 0
            var rightViolations = 0

            let yStart = Int(60 * scale)
            let yEnd = Int(460 * scale)
            let leftLimit = Int(12 * scale)
            let rightStart = Int(508 * scale)
            let rightLimit = rep.pixelsWide

            for y in yStart..<yEnd {
                for x in 0..<leftLimit {
                    if let c = rep.colorAt(x: x, y: y) {
                        let diff = abs(c.redComponent - bg.redComponent) + abs(c.greenComponent - bg.greenComponent) + abs(c.blueComponent - bg.blueComponent)
                        if diff > 0.08 { leftViolations += 1 }
                    }
                }
                for x in rightStart..<rightLimit {
                    if let c = rep.colorAt(x: x, y: y) {
                        let diff = abs(c.redComponent - bg.redComponent) + abs(c.greenComponent - bg.greenComponent) + abs(c.blueComponent - bg.blueComponent)
                        if diff > 0.08 { rightViolations += 1 }
                    }
                }
            }

            XCTAssertEqual(leftViolations, 0, "Left margin strip (0..<12px) contains \(leftViolations) clipped pixel violations in tab \(config.tab.rawValue)")
            XCTAssertEqual(rightViolations, 0, "Right margin strip (508..<520px) contains \(rightViolations) clipped pixel violations in tab \(config.tab.rawValue)")
        }

        // Test 4-modifier custom key combination (Control + Option + Shift + Command + Space)
        state.shortcutType = .customKeyCombo
        state.customKeyCombo = CustomKeyCombo(
            keyCode: 49,
            carbonModifiers: UInt32(controlKey | optionKey | shiftKey | cmdKey),
            displayString: "Control + Option + Shift + Command + Space"
        )
        let view4Mod = SettingsView(stateManager: state, initialTab: .shortcuts)
        let hc4Mod = NSHostingController(rootView: view4Mod)
        let targetView4Mod = hc4Mod.view
        targetView4Mod.frame = NSRect(origin: .zero, size: fixedWindowSize)
        targetView4Mod.layoutSubtreeIfNeeded()
        if let rep4 = targetView4Mod.bitmapImageRepForCachingDisplay(in: NSRect(origin: .zero, size: fixedWindowSize)) {
            targetView4Mod.cacheDisplay(in: NSRect(origin: .zero, size: fixedWindowSize), to: rep4)
            let scale = CGFloat(rep4.pixelsWide) / 520.0
            if let bg = rep4.colorAt(x: Int(2 * scale), y: Int(100 * scale)) {
                var leftViolations = 0
                var rightViolations = 0
                let yStart = Int(60 * scale)
                let yEnd = Int(460 * scale)
                let leftLimit = Int(12 * scale)
                let rightStart = Int(508 * scale)
                let rightLimit = rep4.pixelsWide

                for y in yStart..<yEnd {
                    for x in 0..<leftLimit {
                        if let c = rep4.colorAt(x: x, y: y) {
                            let diff = abs(c.redComponent - bg.redComponent) + abs(c.greenComponent - bg.greenComponent) + abs(c.blueComponent - bg.blueComponent)
                            if diff > 0.08 { leftViolations += 1 }
                        }
                    }
                    for x in rightStart..<rightLimit {
                        if let c = rep4.colorAt(x: x, y: y) {
                            let diff = abs(c.redComponent - bg.redComponent) + abs(c.greenComponent - bg.greenComponent) + abs(c.blueComponent - bg.blueComponent)
                            if diff > 0.08 { rightViolations += 1 }
                        }
                    }
                }
                XCTAssertEqual(leftViolations, 0, "4-modifier shortcut: left margin strip contains \(leftViolations) violations")
                XCTAssertEqual(rightViolations, 0, "4-modifier shortcut: right margin strip contains \(rightViolations) violations")
            }
        }
        // Optional: Save PNG snapshots when VIETFLOW_SNAPSHOT_DIR is provided
        if let snapshotDir = ProcessInfo.processInfo.environment["VIETFLOW_SNAPSHOT_DIR"], !snapshotDir.isEmpty {
            saveSettingsSnapshots(to: snapshotDir)
        }
    }

    private func saveSettingsSnapshots(to directory: String) {
        let state = AppStateManager.shared
        state.resetToDefaults()
        let snapshots: [(filename: String, tab: SettingsTab, shortcut: ShortcutType)] = [
            ("Settings_Tab1_Keyboard.png", .keyboard, .modifierChord),
            ("Settings_Tab2_Shortcuts_Chord.png", .shortcuts, .modifierChord),
            ("Settings_Tab2_Shortcuts_Custom.png", .shortcuts, .customKeyCombo),
            ("Settings_Tab3_Applications.png", .applications, .modifierChord),
            ("Settings_Tab4_About.png", .about, .modifierChord)
        ]

        for item in snapshots {
            state.shortcutType = item.shortcut
            let view = SettingsView(stateManager: state, initialTab: item.tab)
            let hc = NSHostingController(rootView: view)
            let targetView = hc.view
            targetView.appearance = NSAppearance(named: .darkAqua)
            targetView.frame = NSRect(origin: .zero, size: fixedWindowSize)
            targetView.layoutSubtreeIfNeeded()

            if let rep = targetView.bitmapImageRepForCachingDisplay(in: NSRect(origin: .zero, size: fixedWindowSize)) {
                targetView.cacheDisplay(in: NSRect(origin: .zero, size: fixedWindowSize), to: rep)
                if let pngData = rep.representation(using: .png, properties: [:]) {
                    let url = URL(fileURLWithPath: directory).appendingPathComponent(item.filename)
                    try? pngData.write(to: url)
                }
            }
        }
    }

    // MARK: - Test 4: SettingsWindowController Fixed Geometry Enforcement
    func test_04_settings_window_controller_fixed_geometry() {
        let controller = SettingsWindowController.shared
        guard let window = controller.window else {
            XCTFail("SettingsWindowController window is nil")
            return
        }

        let contentRect = window.contentRect(forFrameRect: window.frame)
        XCTAssertEqual(contentRect.size.width, 520.0, "Window content width must be exactly 520pt")
        XCTAssertEqual(contentRect.size.height, 520.0, "Window content height must be exactly 520pt")
        XCTAssertEqual(window.minSize.width, 520.0, "Window minSize.width must be locked to 520pt")
        XCTAssertEqual(window.minSize.height, 520.0, "Window minSize.height must be locked to 520pt")
        XCTAssertEqual(window.maxSize.width, 520.0, "Window maxSize.width must be locked to 520pt")
        XCTAssertEqual(window.maxSize.height, 520.0, "Window maxSize.height must be locked to 520pt")

        // Verify programmatic resize rejection
        window.setContentSize(NSSize(width: 300, height: 300))
        let afterSmall = window.contentRect(forFrameRect: window.frame).size
        XCTAssertEqual(afterSmall.width, 520.0, "Content width must remain 520pt after setContentSize(300, 300)")
        XCTAssertEqual(afterSmall.height, 520.0, "Content height must remain 520pt after setContentSize(300, 300)")

        window.setContentSize(NSSize(width: 800, height: 800))
        let afterLarge = window.contentRect(forFrameRect: window.frame).size
        XCTAssertEqual(afterLarge.width, 520.0, "Content width must remain 520pt after setContentSize(800, 800)")
        XCTAssertEqual(afterLarge.height, 520.0, "Content height must remain 520pt after setContentSize(800, 800)")

        window.setFrame(NSRect(origin: window.frame.origin, size: NSSize(width: 400, height: 400)), display: true)
        let afterFrame = window.contentRect(forFrameRect: window.frame).size
        XCTAssertEqual(afterFrame.width, 520.0, "Content width must remain 520pt after setFrame(400, 400)")
        XCTAssertEqual(afterFrame.height, 520.0, "Content height must remain 520pt after setFrame(400, 400)")

        let willResizeResult = controller.windowWillResize(window, to: NSSize(width: 300, height: 300))
        let expectedFrameSize = window.frameRect(forContentRect: NSRect(origin: .zero, size: SettingsWindowController.fixedSize)).size
        XCTAssertEqual(willResizeResult.width, expectedFrameSize.width, "windowWillResize must return fixed frame width")
        XCTAssertEqual(willResizeResult.height, expectedFrameSize.height, "windowWillResize must return fixed frame height")
    }

    // MARK: - Test 5: AccessibilityService Live and Dependency Injected Behavior
    func test_05_accessibility_service_live_and_mocked() {
        var checkerState = false
        var resetCount = 0
        var promptCalled = false
        var settingsOpened = false

        let mockService = AccessibilityService(
            bundleIdentifier: "com.nhanqv.VietFlow.test",
            accessibilityChecker: { checkerState },
            accessibilityPrompter: {
                promptCalled = true
                return checkerState
            },
            accessibilityResetter: {
                resetCount += 1
                return true
            },
            settingsOpener: {
                settingsOpened = true
            }
        )

        // Initial untrusted state
        XCTAssertFalse(mockService.isTrusted)
        XCTAssertFalse(mockService.isAccessibilityTrusted)
        XCTAssertFalse(mockService.checkAccessibilityPermission())

        // Test combined reset and request
        let requested = mockService.resetAndRequestAccessibilityPermission()
        XCTAssertFalse(requested)
        XCTAssertEqual(resetCount, 1, "resetAccessibilityPermission() should be called once")
        XCTAssertTrue(promptCalled, "requestAccessibilityPermission() was not called")
        XCTAssertTrue(settingsOpened, "openAccessibilitySettings() was not called")

        // Test startup TCC reset logic: runs once per binary signature when untrusted
        let sig1 = "1.0.0-test-sig-A"
        XCTAssertTrue(mockService.handleStartupTCCResetIfNeeded(signatureOverride: sig1), "First startup with sig1 should trigger TCC reset")
        XCTAssertEqual(resetCount, 2)
        XCTAssertFalse(mockService.handleStartupTCCResetIfNeeded(signatureOverride: sig1), "Second startup with same sig1 must not re-reset TCC")
        XCTAssertEqual(resetCount, 2)

        // Changing binary signature (e.g. ad-hoc rebuild) triggers TCC reset again
        let sig2 = "1.0.0-test-sig-B"
        XCTAssertTrue(mockService.handleStartupTCCResetIfNeeded(signatureOverride: sig2), "New binary signature sig2 must trigger TCC reset")
        XCTAssertEqual(resetCount, 3)

        // Test state flip when checker returns true
        checkerState = true
        XCTAssertTrue(mockService.isAccessibilityTrusted)
        mockService.refresh()

        // Test rapid state transitions remain synchronized
        var currentStressState = false
        let stressService = AccessibilityService(
            bundleIdentifier: "com.nhanqv.VietFlow.stress",
            accessibilityChecker: { currentStressState }
        )
        for i in 0..<1000 {
            currentStressState = (i % 2 == 1)
            stressService.refresh()
            if i % 100 == 0 {
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.001))
            }
        }
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
        XCTAssertEqual(stressService.isTrusted, currentStressState, "Final isTrusted must match currentStressState after rapid flips")
    }

    // MARK: - Test 6: Strict 0-Emoji Compliance
    func test_06_strict_zero_emoji_compliance() {
        let emojiPattern = try! NSRegularExpression(pattern: "[\\x{1F600}-\\x{1F64F}|\\x{1F300}-\\x{1F5FF}|\\x{1F680}-\\x{1F6FF}|\\x{1F1E0}-\\x{1F1FF}|\\x{2600}-\\x{26FF}|\\x{2700}-\\x{27BF}]")

        let stringsToCheck = [
            SettingsTab.keyboard.rawValue,
            SettingsTab.shortcuts.rawValue,
            SettingsTab.applications.rawValue,
            SettingsTab.about.rawValue,
            "Chùm phím bổ trợ",
            "Phím tắt tùy chỉnh",
            "Quyền Trợ năng: Đã kích hoạt",
            "Quyền Trợ năng: Chưa cấp",
            "Kiểm tra lại",
            "Cấp quyền Trợ năng",
            "Khôi phục cài đặt gốc",
            "Kiểm tra cập nhật...",
            "Tự động kiểm tra cập nhật mỗi ngày",
            "Kiểm tra cập nhật",
            "Xem thay đổi",
            "Để sau",
            "Cập nhật ngay",
            "Khởi động lại",
            "Đang kiểm tra...",
            "Đã là phiên bản mới nhất",
            "Có bản mới",
            "Đang tải bản cập nhật...",
            "Sẵn sàng khởi động lại",
            "Cập nhật phần mềm"
        ]

        for s in stringsToCheck {
            let range = NSRange(location: 0, length: s.utf16.count)
            let matches = emojiPattern.matches(in: s, range: range)
            XCTAssertEqual(matches.count, 0, "Emoji detected in string: \(s)")
        }
    }

    // MARK: - Test 7: R2 Unconditional Shortcut Monitors, Deduplication & Recording Guard
    func test_07_unconditional_shortcut_monitors_and_deduplication() {
        let state = AppStateManager.shared
        let manager = EventTapManager.shared
        state.resetToDefaults()
        state.currentInputMode = .english
        manager.simulateEventTapActiveForTesting = false
        manager.isRecordingCustomShortcut = false
        manager.startShortcutMonitors()

        // 1. Monitors are unconditionally installed even without CGEventTap
        XCTAssertTrue(manager.areShortcutMonitorsInstalled, "Local and global NSEvent shortcut monitors must be unconditionally installed")

        // 2. Local monitor flagsChanged toggles mode (English -> Vietnamese)
        XCTAssertEqual(state.currentInputMode, .english)
        let ctrlFlags = ModifierChordStateMachine.cgFlags(from: [.control])
        let ctrlShiftFlags = ModifierChordStateMachine.cgFlags(from: [.control, .shift])
        manager.processFlagsChanged(ctrlFlags, source: .localMonitor)
        manager.processFlagsChanged(ctrlShiftFlags, source: .localMonitor)
        manager.processFlagsChanged([], source: .localMonitor)
        XCTAssertEqual(state.currentInputMode, .vietnamese, "Ctrl+Shift via .localMonitor must toggle mode to .vietnamese")

        // 3. Cross-source deduplication: immediate .globalMonitor event within 40ms must NOT double-toggle back to .english
        manager.processFlagsChanged(ctrlFlags, source: .globalMonitor)
        manager.processFlagsChanged(ctrlShiftFlags, source: .globalMonitor)
        manager.processFlagsChanged([], source: .globalMonitor)
        XCTAssertEqual(state.currentInputMode, .vietnamese, "Duplicate .globalMonitor chord within 40ms must be deduplicated")

        // 4. When CGEventTap is active, .localMonitor and .globalMonitor defer to .eventTap (zero double-triggering)
        manager.simulateEventTapActiveForTesting = true
        manager.processFlagsChanged(ctrlFlags, source: .localMonitor)
        manager.processFlagsChanged(ctrlShiftFlags, source: .localMonitor)
        manager.processFlagsChanged([], source: .localMonitor)
        XCTAssertEqual(state.currentInputMode, .vietnamese, "When CGEventTap is active, .localMonitor must defer to .eventTap")

        // .eventTap source triggers cleanly after cross-source deduplication window (40ms)
        Thread.sleep(forTimeInterval: 0.045)
        manager.processFlagsChanged(ctrlFlags, source: .eventTap)
        manager.processFlagsChanged(ctrlShiftFlags, source: .eventTap)
        manager.processFlagsChanged([], source: .eventTap)
        XCTAssertEqual(state.currentInputMode, .english, "Ctrl+Shift via .eventTap must toggle mode back to .english")
        manager.simulateEventTapActiveForTesting = false

        // 5. While recording a custom shortcut in SettingsView, modifier chords must NOT toggle input mode
        manager.isRecordingCustomShortcut = true
        manager.processFlagsChanged(ctrlFlags, source: .localMonitor)
        manager.processFlagsChanged(ctrlShiftFlags, source: .localMonitor)
        manager.processFlagsChanged([], source: .localMonitor)
        XCTAssertEqual(state.currentInputMode, .english, "Modifier chord must not toggle mode while isRecordingCustomShortcut is true")
        manager.isRecordingCustomShortcut = false
    }

    // MARK: - Test 8: R3 Engine Config Sync & Vietnamese Typing Transformation (Telex & VNI)
    func test_08_engine_config_sync_and_vietnamese_typing_e2e() {
        let state = AppStateManager.shared
        let manager = EventTapManager.shared
        state.resetToDefaults()
        state.currentInputMode = .vietnamese

        // Verify initial Telex sync
        XCTAssertEqual(manager.engine.config.inputMethod, .telex)
        manager.engine.reset()
        for ch in "tieengs" {
            _ = manager.engine.processKey(ch)
        }
        XCTAssertEqual(manager.engine.currentSyllable, "tiếng", "Telex 'tieengs' must compose 'tiếng'")

        // Mutate AppStateManager settings and verify immediate propagation to BambooEngine.config
        state.currentInputMethod = .vni
        state.currentTonePlacement = .traditional
        state.autoRestoreEnglish = false
        state.escapeByDoubleKey = false

        XCTAssertEqual(manager.engine.config.inputMethod, .vni, "Changing currentInputMethod on AppStateManager must immediately sync to BambooEngine.config")
        XCTAssertEqual(manager.engine.config.tonePlacement, .traditional, "Changing currentTonePlacement on AppStateManager must immediately sync to BambooEngine.config")
        XCTAssertFalse(manager.engine.config.autoCorrectEnglish)
        XCTAssertFalse(manager.engine.config.escapeByDoubleKey)

        manager.engine.reset()
        for ch in "tie6ng1" {
            _ = manager.engine.processKey(ch)
        }
        XCTAssertEqual(manager.engine.currentSyllable, "tiếng", "VNI 'tie6ng1' must compose 'tiếng'")
    }

    // MARK: - Test 9: R3 Per-App Mode Preserves Vietnamese When Switching From Settings to Target Apps
    func test_09_per_app_mode_preserves_vietnamese_from_settings_to_target_apps() {
        let state = AppStateManager.shared
        state.resetToDefaults()
        state.currentInputMode = .english

        // 1. User starts in Terminal in English mode
        state.handleActiveAppChanged(bundleId: "com.apple.Terminal", appName: "Terminal")
        XCTAssertEqual(state.currentInputMode, .english)

        // 2. User opens VietFlow Settings window (com.nhanqv.VietFlow becomes frontmost) and selects Tiếng Việt
        state.handleActiveAppChanged(bundleId: "com.nhanqv.VietFlow", appName: "VietFlow")
        state.currentInputMode = .vietnamese
        XCTAssertEqual(state.currentInputMode, .vietnamese)

        // 3. User clicks back into Terminal, VS Code, or Safari -> mode MUST remain .vietnamese!
        state.handleActiveAppChanged(bundleId: "com.apple.Terminal", appName: "Terminal")
        XCTAssertEqual(state.currentInputMode, .vietnamese, "Switching from VietFlow Settings back to Terminal must preserve .vietnamese mode")

        state.handleActiveAppChanged(bundleId: "com.microsoft.VSCode", appName: "Code")
        XCTAssertEqual(state.currentInputMode, .vietnamese, "Switching to VS Code must preserve .vietnamese mode (no forced .english override)")

        state.handleActiveAppChanged(bundleId: "com.apple.Safari", appName: "Safari")
        XCTAssertEqual(state.currentInputMode, .vietnamese, "Switching to Safari must preserve .vietnamese mode")
    }

    // MARK: - Test 10: Enlarged Status Bar Icon Verification & Preview Export
    func test_10_status_bar_enlarged_icon_dimensions_and_rendering() {
        let controller = StatusBarController(stateManager: .shared)
        let vIcon = controller.renderVectorStatusIcon(mode: .vietnamese)
        let eIcon = controller.renderVectorStatusIcon(mode: .english)

        XCTAssertEqual(vIcon.size.width, 22.0, "Status bar V icon width must be 22pt")
        XCTAssertEqual(vIcon.size.height, 22.0, "Status bar V icon height must be 22pt")
        XCTAssertTrue(vIcon.isTemplate, "Status bar V icon must be template image")

        XCTAssertEqual(eIcon.size.width, 22.0, "Status bar E icon width must be 22pt")
        XCTAssertEqual(eIcon.size.height, 22.0, "Status bar E icon height must be 22pt")
        XCTAssertTrue(eIcon.isTemplate, "Status bar E icon must be template image")

        if let snapshotDir = ProcessInfo.processInfo.environment["VIETFLOW_SNAPSHOT_DIR"], !snapshotDir.isEmpty {
            let previewView = HStack(spacing: 32) {
                VStack(spacing: 8) {
                    HStack(spacing: 16) {
                        Image(nsImage: vIcon)
                            .foregroundColor(.white)
                            .scaleEffect(2.2)
                            .frame(width: 56, height: 56)
                        Image(nsImage: eIcon)
                            .foregroundColor(.white)
                            .scaleEffect(2.2)
                            .frame(width: 56, height: 56)
                    }
                    Text("Dark Menu Bar (V / E — 22×22pt)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.14)))

                VStack(spacing: 8) {
                    HStack(spacing: 16) {
                        Image(nsImage: vIcon)
                            .foregroundColor(.black)
                            .scaleEffect(2.2)
                            .frame(width: 56, height: 56)
                        Image(nsImage: eIcon)
                            .foregroundColor(.black)
                            .scaleEffect(2.2)
                            .frame(width: 56, height: 56)
                    }
                    Text("Light Menu Bar (V / E — 22×22pt)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.black.opacity(0.8))
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.93)))
            }
            .padding(20)
            .background(Color(white: 0.08))

            let hc = NSHostingController(rootView: previewView)
            let size = NSSize(width: 480, height: 150)
            hc.view.frame = NSRect(origin: .zero, size: size)
            hc.view.layoutSubtreeIfNeeded()
            if let rep = hc.view.bitmapImageRepForCachingDisplay(in: NSRect(origin: .zero, size: size)) {
                hc.view.cacheDisplay(in: NSRect(origin: .zero, size: size), to: rep)
                if let png = rep.representation(using: .png, properties: [:]) {
                    let url = URL(fileURLWithPath: snapshotDir).appendingPathComponent("StatusBar_Enlarged_Preview.png")
                    try? png.write(to: url)
                }
            }
        }
    }

    // MARK: - Test 11: Zero Clipping and Fitting Size with Update Banner Visible
    func test_11_layout_with_update_banner_visible_across_all_tabs() {
        let state = AppStateManager.shared
        let updateMgr = UpdateManager.shared
        let release = ReleaseInfo(
            tagName: "v1.2.0",
            name: "VietFlow 1.2.0",
            releaseNotes: "Test release notes",
            htmlURL: URL(string: "https://github.com/nhanqv-ai/VietFlow")!
        )
        for bannerStatus in [UpdateStatus.updateAvailable(release), UpdateStatus.readyToRestart(release)] {
            updateMgr.status = bannerStatus
            updateMgr.hasPendingUpdate = true
            updateMgr.isBannerDismissedForSession = false
            XCTAssertTrue(updateMgr.shouldShowBanner)

            for tab in SettingsTab.allCases {
                // Verify fitting size remains <= 520
                let view = SettingsView(stateManager: state, updateManager: updateMgr, initialTab: tab)
                let hc = NSHostingController(rootView: view)
                let targetView = hc.view
                targetView.frame = NSRect(origin: .zero, size: fixedWindowSize)
                targetView.layoutSubtreeIfNeeded()

                let fitting = targetView.fittingSize
                XCTAssertTrue(fitting.width <= 520.0, "Banner \(bannerStatus): Tab \(tab.rawValue) fittingSize.width (\(fitting.width)) > 520")
                XCTAssertTrue(fitting.height <= 520.0, "Banner \(bannerStatus): Tab \(tab.rawValue) fittingSize.height (\(fitting.height)) > 520")

            // Verify offscreen bitmap margin strips (0..<12 and 508..<520) have 0 clipping violations
            guard let rep = targetView.bitmapImageRepForCachingDisplay(in: NSRect(origin: .zero, size: fixedWindowSize)) else {
                XCTFail("Failed to allocate NSBitmapImageRep for \(tab.rawValue) with banner")
                continue
            }
            targetView.cacheDisplay(in: NSRect(origin: .zero, size: fixedWindowSize), to: rep)

            let scale = CGFloat(rep.pixelsWide) / 520.0
            guard let bg = rep.colorAt(x: Int(2 * scale), y: Int(100 * scale)) else {
                XCTFail("Failed to sample background color for \(tab.rawValue) with banner")
                continue
            }

            var leftViolations = 0
            var rightViolations = 0

            let yStart = Int(60 * scale)
            let yEnd = Int(460 * scale)
            let leftLimit = Int(12 * scale)
            let rightStart = Int(508 * scale)
            let rightLimit = rep.pixelsWide

            for y in yStart..<yEnd {
                for x in 0..<leftLimit {
                    if let c = rep.colorAt(x: x, y: y) {
                        let diff = abs(c.redComponent - bg.redComponent) + abs(c.greenComponent - bg.greenComponent) + abs(c.blueComponent - bg.blueComponent)
                        if diff > 0.08 { leftViolations += 1 }
                    }
                }
                for x in rightStart..<rightLimit {
                    if let c = rep.colorAt(x: x, y: y) {
                        let diff = abs(c.redComponent - bg.redComponent) + abs(c.greenComponent - bg.greenComponent) + abs(c.blueComponent - bg.blueComponent)
                        if diff > 0.08 { rightViolations += 1 }
                    }
                }
            }

            XCTAssertEqual(leftViolations, 0, "Banner \(bannerStatus): Left margin strip contains \(leftViolations) violations in \(tab.rawValue)")
            XCTAssertEqual(rightViolations, 0, "Banner \(bannerStatus): Right margin strip contains \(rightViolations) violations in \(tab.rawValue)")
        }
        }
    }

    // MARK: - Test Registry Registration
    public override var allTests: [(name: String, test: () throws -> Void)] {
        return [
            ("test_01_fitting_size_across_all_tabs_and_submodes", test_01_fitting_size_across_all_tabs_and_submodes),
            ("test_02_internal_scrollviews_do_not_overflow", test_02_internal_scrollviews_do_not_overflow),
            ("test_03_offscreen_bitmap_margin_strips_zero_violations", test_03_offscreen_bitmap_margin_strips_zero_violations),
            ("test_04_settings_window_controller_fixed_geometry", test_04_settings_window_controller_fixed_geometry),
            ("test_05_accessibility_service_live_and_mocked", test_05_accessibility_service_live_and_mocked),
            ("test_06_strict_zero_emoji_compliance", test_06_strict_zero_emoji_compliance),
            ("test_07_unconditional_shortcut_monitors_and_deduplication", test_07_unconditional_shortcut_monitors_and_deduplication),
            ("test_08_engine_config_sync_and_vietnamese_typing_e2e", test_08_engine_config_sync_and_vietnamese_typing_e2e),
            ("test_09_per_app_mode_preserves_vietnamese_from_settings_to_target_apps", test_09_per_app_mode_preserves_vietnamese_from_settings_to_target_apps),
            ("test_10_status_bar_enlarged_icon_dimensions_and_rendering", test_10_status_bar_enlarged_icon_dimensions_and_rendering),
            ("test_11_layout_with_update_banner_visible_across_all_tabs", test_11_layout_with_update_banner_visible_across_all_tabs),
        ]
    }
}
