//
//  SettingsView.swift
//  VietFlowApp
//
//  Modern native macOS Settings View matching SuperClip design language.
//  Features:
//  - Top Tab Bar with SF Symbols placed above labels
//  - Rounded card container styling (RoundedRectangle(cornerRadius: 10))
//  - Interactive Hotkey Recorder with NSEvent local monitoring
//  - Blacklist application manager with NSOpenPanel
//  - Universal 2 architecture indicator & reset confirmation
//  - STRICT ZERO EMOJIS: strictly 0 emojis across all titles, labels, and dialogs
//

import SwiftUI
import AppKit
import Carbon
import UniformTypeIdentifiers
import VietFlowEngine
import VietFlowState
import VietFlowEventTap

// MARK: - Settings Tab Definition
public enum SettingsTab: String, CaseIterable, Identifiable {
    case keyboard = "Bàn phím"
    case shortcuts = "Phím tắt"
    case applications = "Ứng dụng"
    case about = "Thông tin"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .keyboard: return "keyboard"
        case .shortcuts: return "command"
        case .applications: return "app.badge"
        case .about: return "info.circle"
        }
    }
}

// MARK: - Blacklisted App Representation
public struct BlacklistedAppItem: Identifiable, Hashable {
    public let bundleIdentifier: String
    public var id: String { bundleIdentifier }

    public var displayName: String {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier),
           let bundle = Bundle(url: url) {
            let localizedName = (bundle.localizedInfoDictionary?["CFBundleDisplayName"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let name = (bundle.infoDictionary?["CFBundleDisplayName"] as? String) ?? (bundle.infoDictionary?["CFBundleName"] as? String)
            if let ln = localizedName, !ln.isEmpty { return ln }
            if let n = name, !n.isEmpty { return n }
        }
        let parts = bundleIdentifier.split(separator: ".")
        if let last = parts.last {
            return String(last).capitalized
        }
        return bundleIdentifier
    }

    public var icon: NSImage {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return NSWorkspace.shared.icon(for: .application)
    }
}

// MARK: - SettingsView
public struct SettingsView: View {
    @ObservedObject public var stateManager: AppStateManager
    @ObservedObject public var accessibilityService: AccessibilityService
    @ObservedObject public var updateManager: UpdateManager
    public var onClose: (() -> Void)?

    @State private var selectedTab: SettingsTab = .keyboard
    @State private var isRecordingHotKey: Bool = false
    @State private var localKeyMonitor: Any? = nil
    @State private var hotKeyWarningMessage: String? = nil
    @State private var selectedBlacklistId: String? = nil
    @State private var showingResetConfirmation: Bool = false

    public init(
        stateManager: AppStateManager = .shared,
        accessibilityService: AccessibilityService = .shared,
        updateManager: UpdateManager = .shared,
        initialTab: SettingsTab = .keyboard,
        onClose: (() -> Void)? = nil
    ) {
        self.stateManager = stateManager
        self.accessibilityService = accessibilityService
        self.updateManager = updateManager
        self._selectedTab = State(initialValue: initialTab)
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 0) {
            topTabBar
            Divider()
            if updateManager.shouldShowBanner {
                updateBannerView
            }
            contentArea
            Divider()
            footerBar
        }
        .frame(width: 520, height: 520)
        .background(Color(nsColor: .windowBackgroundColor))
        .onDisappear {
            stopRecordingHotKey()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { _ in
            stopRecordingHotKey()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willResignActiveNotification)) { _ in
            stopRecordingHotKey()
        }
        .alert("Khôi phục cài đặt gốc?", isPresented: $showingResetConfirmation) {
            Button("Hủy", role: .cancel) {}
            Button("Khôi phục", role: .destructive) {
                resetAllSettings()
            }
        } message: {
            Text("Toàn bộ cấu hình kiểu gõ, phím tắt và danh sách ứng dụng loại trừ sẽ được đưa về mặc định ban đầu.")
        }
    }

    // MARK: - Top Tab Bar
    private var topTabBar: some View {
        HStack(spacing: 20) {
            ForEach(SettingsTab.allCases) { tab in
                Button(action: {
                    hotKeyWarningMessage = nil
                    stopRecordingHotKey()
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 2) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: tab.iconName)
                                .font(.system(size: 18, weight: .regular))
                                .frame(height: 22)

                            if tab == .about && updateManager.hasPendingUpdate {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 6, height: 6)
                                    .offset(x: 4, y: -2)
                            }
                        }
                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: selectedTab == tab ? .semibold : .regular))
                            .lineLimit(1)
                    }
                    .foregroundColor(selectedTab == tab ? .primary : .secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(selectedTab == tab ? Color.secondary.opacity(0.15) : Color.clear)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Content Area
    @ViewBuilder
    private var contentArea: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 12) {
                switch selectedTab {
                case .keyboard:
                    keyboardTabContent
                case .shortcuts:
                    shortcutsTabContent
                case .applications:
                    applicationsTabContent
                case .about:
                    aboutTabContent
                }
            }
            .frame(maxWidth: 488)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(width: 520)
    }

    // MARK: - Card Container Helper
    private func cardView<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color(nsColor: .separatorColor).opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Tab 1: Keyboard Tab Content
    private var keyboardTabContent: some View {
        VStack(spacing: 12) {
            accessibilityStatusCard

            // Card 1: Input method & Tone rule
            cardView {
                Text("Kiểu gõ & Dấu thanh")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Text("Kiểu gõ chính:")
                            .font(.system(size: 12))
                            .frame(width: 140, alignment: .leading)

                        Picker("", selection: $stateManager.currentInputMethod) {
                            Text("Telex (Tiêu chuẩn)").tag(InputMethod.telex)
                            Text("Simple Telex").tag(InputMethod.simpleTelex)
                            Text("VNI").tag(InputMethod.vni)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 180)
                    }

                    HStack(spacing: 12) {
                        Text("Quy tắc đặt dấu:")
                            .font(.system(size: 12))
                            .frame(width: 140, alignment: .leading)

                        Picker("", selection: $stateManager.currentTonePlacement) {
                            Text("Dấu Mới (hòa, thúy)").tag(TonePlacementStyle.modern)
                            Text("Dấu Cũ (hoà, thuý)").tag(TonePlacementStyle.traditional)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 180)
                    }
                }

                Text("Kiểu gõ và quy tắc bỏ dấu được xử lý theo thuật toán Bamboo Engine với độ chính xác cao.")
                    .font(.system(size: 10.5))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Card 2: Advanced Typing Options
            cardView {
                Text("Tùy chọn nâng cao khi soạn thảo")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Toggle("Tự động khôi phục từ tiếng Anh khi gõ sai âm tiết", isOn: $stateManager.autoRestoreEnglish)
                            .toggleStyle(.checkbox)
                            .font(.system(size: 12))

                        Text("Tránh làm biến dạng các từ tiếng Anh (ví dụ: 'post', 'view', 'chat') khi đang bật tiếng Việt.")
                            .font(.system(size: 10.5))
                            .foregroundColor(.secondary)
                            .padding(.leading, 18)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Toggle("Gõ lặp phím dấu để thoát tiếng Việt (ví dụ: 'ss' -> 's')", isOn: $stateManager.escapeByDoubleKey)
                            .toggleStyle(.checkbox)
                            .font(.system(size: 12))

                        Text("Cho phép gõ hai lần phím dấu liên tiếp để giữ nguyên ký tự gốc mà không áp dụng dấu tiếng Việt.")
                            .font(.system(size: 10.5))
                            .foregroundColor(.secondary)
                            .padding(.leading, 18)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Toggle("Tự động nhường phím khi dùng bộ gõ ngoại ngữ khác (Nhật, Trung, Hàn...)", isOn: $stateManager.autoSwitchOnForeignInputSource)
                            .toggleStyle(.checkbox)
                            .font(.system(size: 12))

                        Text("Tự động chuyển sang [E] khi chọn bộ gõ tiếng Nhật trên macOS và khôi phục lại [V] khi quay về bàn phím ABC.")
                            .font(.system(size: 10.5))
                            .foregroundColor(.secondary)
                            .padding(.leading, 18)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            // Card 3: Adaptive Learning from Backspace
            cardView {
                Text("Tự học từ lỗi xóa Backspace")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Toggle("Tự học từ lỗi xóa Backspace", isOn: $stateManager.adaptiveLearningEnabled)
                            .toggleStyle(.checkbox)
                            .font(.system(size: 12))

                        Text("Ghi nhận các lần sửa phím bằng Backspace để tự động thích ứng với thói quen gõ và từ khóa riêng của bạn.")
                            .font(.system(size: 10.5))
                            .foregroundColor(.secondary)
                            .padding(.leading, 18)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Đã ghi nhận \(stateManager.adaptiveLoggedPatternsCount) mẫu lỗi, \(stateManager.adaptiveActiveRulesCount) quy tắc đang kích hoạt.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            Button("Mở file log") {
                                stateManager.openTypingErrorLog()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .font(.system(size: 11))

                            Button("Xóa dữ liệu học") {
                                stateManager.clearAdaptiveLearningData()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .font(.system(size: 11))
                        }
                    }
                    .padding(.leading, 18)
                }
            }
        }
        .onAppear {
            stateManager.refreshAdaptiveLearningCounts()
        }
    }

    // MARK: - Live Accessibility Status Card
    private var accessibilityStatusCard: some View {
        cardView {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: accessibilityService.isTrusted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(accessibilityService.isTrusted ? .green : .orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text(accessibilityService.isTrusted ? "Quyền Trợ năng: Đã kích hoạt" : "Quyền Trợ năng: Chưa cấp")
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(accessibilityService.isTrusted
                        ? "VietFlow có đủ quyền để ghi nhận và chuyển đổi phím tiếng Việt."
                        : "Cần cấp quyền Trợ năng để bộ gõ hoạt động trong các ứng dụng khác.")
                        .font(.system(size: 10.5))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                if accessibilityService.isTrusted {
                    Button("Kiểm tra lại") {
                        accessibilityService.refresh()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .font(.system(size: 11))
                } else {
                    HStack(spacing: 6) {
                        Button("Kiểm tra lại") {
                            accessibilityService.refresh()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .font(.system(size: 11))

                        Button("Cấp quyền Trợ năng") {
                            accessibilityService.resetAndRequestAccessibilityPermission()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .font(.system(size: 11))
                    }
                }
            }
        }
    }

    // MARK: - Tab 2: Shortcuts Tab Content
    private var shortcutsTabContent: some View {
        VStack(spacing: 10) {
            // Card 1: Shortcut Type Selection
            cardView {
                Text("Phương thức phím tắt chuyển đổi")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                Text("Chọn phương thức để chuyển đổi tức thời giữa Tiếng Việt [V] và English [E]:")
                    .font(.system(size: 11.5))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Picker("Loại phím tắt:", selection: $stateManager.shortcutType) {
                    Text("Chùm phím bổ trợ").tag(ShortcutType.modifierChord)
                    Text("Phím tắt tùy chỉnh").tag(ShortcutType.customKeyCombo)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: .infinity)
            }

            // Card 2: Shortcut Configuration
            if stateManager.shortcutType == .modifierChord {
                modifierChordCard
            } else {
                customKeyComboCard
            }

            // Card 3: Current Input Status Preview
            cardView {
                HStack(spacing: 10) {
                    Image(systemName: stateManager.currentInputMode == .vietnamese ? "checkmark.circle.fill" : "globe")
                        .font(.system(size: 14))
                        .foregroundColor(stateManager.currentInputMode == .vietnamese ? .accentColor : .secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Chế độ đang kích hoạt:")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text(stateManager.currentInputMode.title)
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    Button(action: {
                        stateManager.toggleInputMode()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.system(size: 10))
                            Text("Chuyển chế độ")
                                .font(.system(size: 11))
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
    }

    // MARK: - Modifier Chord Card
    private var modifierChordCard: some View {
        cardView {
            Text("Cấu hình chùm phím bổ trợ")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)

            Text("Nhấn giữ đồng thời các phím bổ trợ rồi nhả ra để chuyển đổi chế độ tức thời:")
                .font(.system(size: 11.5))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(ModifierChordShortcut.allCases, id: \.self) { chord in
                    let isSelected = (stateManager.modifierChord == chord)
                    Button(action: {
                        stateManager.modifierChord = chord
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                                .font(.system(size: 12))
                                .foregroundColor(isSelected ? .accentColor : .secondary)

                            Text(chordTitle(chord))
                                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                                .foregroundColor(.primary)

                            Spacer()

                            if chord == .controlShift {
                                Text("Mặc định")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.12))
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("Trạng thái phím bổ trợ được xử lý bằng máy trạng thái 4 pha tại EventTap, độc lập hoàn toàn với thứ tự bấm và không có độ trễ.")
                .font(.system(size: 10.5))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func chordTitle(_ chord: ModifierChordShortcut) -> String {
        switch chord {
        case .controlShift: return "Control + Shift"
        case .commandShift: return "Command + Shift"
        case .optionShift: return "Option + Shift"
        case .option: return "Option (Phím Alt)"
        }
    }

    // MARK: - Custom Key Combo Card
    private var customKeyComboCard: some View {
        cardView {
            Text("Bộ ghi nhận phím tắt tùy chỉnh")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text("Phím tắt:")
                        .font(.system(size: 12))
                        .lineLimit(1)
                        .fixedSize()

                    hotkeyRecorderButton

                    if stateManager.customKeyCombo.keyCode != 49 || stateManager.customKeyCombo.carbonModifiers != UInt32(controlKey) {
                        Button(action: {
                            resetCustomKeyComboToDefault()
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 10.5))
                        }
                        .buttonStyle(.borderless)
                        .help("Đặt lại phím tắt mặc định (Control + Space)")
                        .disabled(isRecordingHotKey)
                    }

                    Spacer()

                    quickPresetsMenu
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if isRecordingHotKey {
                    Text("Đang ghi nhận: Bấm tổ hợp phím mong muốn (phải có Control, Option, hoặc Command). Bấm Escape để hủy.")
                        .font(.system(size: 10.5))
                        .foregroundColor(.accentColor)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Nhấp vào khung trên để ghi nhận phím mới. Phím tắt sẽ được đăng ký toàn hệ thống qua Carbon HotKey API.")
                        .font(.system(size: 10.5))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let warning = hotKeyWarningMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text(warning)
                            .font(.system(size: 10.5))
                            .foregroundColor(.orange)
                    }
                }
            }
        }
    }

    // MARK: - Hotkey Recorder Button
    private var hotkeyRecorderButton: some View {
        Button(action: {
            if isRecordingHotKey {
                hotKeyWarningMessage = nil
                stopRecordingHotKey()
            } else {
                startRecordingHotKey()
            }
        }) {
            HStack(spacing: 6) {
                if isRecordingHotKey {
                    Image(systemName: "record.circle")
                        .font(.system(size: 11))
                        .foregroundColor(.accentColor)

                    Text("Nhấn tổ hợp phím...")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(.accentColor)

                    Button(action: {
                        hotKeyWarningMessage = nil
                        stopRecordingHotKey()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Hủy ghi nhận")
                } else {
                    Text(KeyCombinationHelper.formattedSymbolShortcut(
                        keyCode: stateManager.customKeyCombo.keyCode,
                        modifiers: stateManager.customKeyCombo.carbonModifiers
                    ))
                    .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                    .foregroundColor(.primary)
                }
            }
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(5)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(isRecordingHotKey ? Color.accentColor : Color(nsColor: .separatorColor), lineWidth: isRecordingHotKey ? 1.5 : 0.8)
            )
        }
        .buttonStyle(.plain)
        .help(isRecordingHotKey ? "Bấm Escape hoặc nút X để hủy" : "Nhấp để ghi nhận phím tắt mới (\(KeyCombinationHelper.formattedShortcut(keyCode: stateManager.customKeyCombo.keyCode, modifiers: stateManager.customKeyCombo.carbonModifiers)))")
    }

    // MARK: - Quick Presets Menu
    private var quickPresetsMenu: some View {
        Menu("Phím mẫu") {
            Button("Control + Space (Khuyên dùng)") {
                applyCustomKeyCombo(keyCode: 49, modifiers: UInt32(controlKey))
            }
            Button("Option + Space") {
                applyCustomKeyCombo(keyCode: 49, modifiers: UInt32(optionKey))
            }
            Button("Command + Shift + V") {
                applyCustomKeyCombo(keyCode: 9, modifiers: UInt32(cmdKey | shiftKey))
            }
            Button("Option + V") {
                applyCustomKeyCombo(keyCode: 9, modifiers: UInt32(optionKey))
            }
        }
        .menuStyle(.borderedButton)
        .controlSize(.small)
        .fixedSize()
        .disabled(isRecordingHotKey)
    }

    // MARK: - Hotkey Recorder Actions
    private func startRecordingHotKey() {
        stopRecordingHotKey()
        hotKeyWarningMessage = nil
        isRecordingHotKey = true
        EventTapManager.shared.isRecordingCustomShortcut = true

        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // Escape
                hotKeyWarningMessage = nil
                stopRecordingHotKey()
                return nil
            }

            let mods = event.modifierFlags
            var carbonFlags: UInt32 = 0
            if mods.contains(.command) { carbonFlags |= UInt32(cmdKey) }
            if mods.contains(.option) { carbonFlags |= UInt32(optionKey) }
            if mods.contains(.control) { carbonFlags |= UInt32(controlKey) }
            if mods.contains(.shift) { carbonFlags |= UInt32(shiftKey) }

            if KeyCombinationHelper.isValidHotKey(modifiers: carbonFlags) {
                let code = UInt32(event.keyCode)
                applyCustomKeyCombo(keyCode: code, modifiers: carbonFlags)
                stopRecordingHotKey()
                return nil
            } else {
                hotKeyWarningMessage = "Cần ít nhất một phím bổ trợ (Control, Option, hoặc Command)."
                return nil
            }
        }
    }

    private func stopRecordingHotKey() {
        if let monitor = localKeyMonitor {
            NSEvent.removeMonitor(monitor)
            localKeyMonitor = nil
        }
        isRecordingHotKey = false
        EventTapManager.shared.isRecordingCustomShortcut = false
    }

    private func applyCustomKeyCombo(keyCode: UInt32, modifiers: UInt32) {
        stopRecordingHotKey()
        guard KeyCombinationHelper.isValidHotKey(modifiers: modifiers) else {
            hotKeyWarningMessage = "Cần ít nhất một phím bổ trợ (Control, Option, hoặc Command)."
            return
        }
        hotKeyWarningMessage = nil
        let formatted = KeyCombinationHelper.formattedShortcut(keyCode: keyCode, modifiers: modifiers)
        stateManager.customKeyCombo = CustomKeyCombo(keyCode: keyCode, carbonModifiers: modifiers, displayString: formatted)
        stateManager.shortcutType = .customKeyCombo
    }

    private func resetCustomKeyComboToDefault() {
        applyCustomKeyCombo(keyCode: 49, modifiers: UInt32(controlKey))
    }

    // MARK: - Tab 3: Applications Tab Content
    private var applicationsTabContent: some View {
        VStack(spacing: 12) {
            // Card 1: Per-App Memory Toggle
            cardView {
                Text("Quản lý trạng thái theo ứng dụng")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                Toggle("Ghi nhớ chế độ gõ độc lập cho từng ứng dụng", isOn: $stateManager.perAppInputMode)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 12))

                Text("Tự động lưu và khôi phục chế độ gõ (Việt / Anh) riêng biệt khi chuyển đổi giữa các cửa sổ ứng dụng (Terminal, VS Code, Trình duyệt...).")
                    .font(.system(size: 10.5))
                    .foregroundColor(.secondary)
                    .padding(.leading, 18)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Card 2: Blacklist Applications Management
            cardView {
                Text("Danh sách ứng dụng loại trừ (Blacklist)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                Text("VietFlow sẽ tự động tạm dừng hoàn toàn và không can thiệp phím khi bạn sử dụng các ứng dụng trong danh sách này:")
                    .font(.system(size: 11.5))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 6) {
                    if stateManager.blacklistedBundleIdentifiers.isEmpty {
                        emptyBlacklistView
                    } else {
                        blacklistScrollView
                    }

                    HStack(spacing: 8) {
                        Button(action: { openAppSelectionPanel() }) {
                            Image(systemName: "plus")
                                .frame(width: 18, height: 18)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .help("Thêm ứng dụng từ thư mục Applications")

                        Button(action: { removeSelectedBlacklistApp() }) {
                            Image(systemName: "minus")
                                .frame(width: 18, height: 18)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(selectedBlacklistId == nil || !stateManager.blacklistedBundleIdentifiers.contains(selectedBlacklistId!))
                        .help("Xóa ứng dụng được chọn")

                        Spacer()
                    }
                }
            }
        }
    }

    private var emptyBlacklistView: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(Color(nsColor: .textBackgroundColor))
            .frame(height: 120)
            .overlay(
                VStack(spacing: 6) {
                    Image(systemName: "app.badge")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                    Text("Chưa có ứng dụng nào trong danh sách loại trừ")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(.secondary)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 0.8)
            )
    }

    private var blacklistScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(stateManager.blacklistedBundleIdentifiers, id: \.self) { bundleId in
                    blacklistRow(BlacklistedAppItem(bundleIdentifier: bundleId))
                }
            }
            .padding(4)
        }
        .frame(height: 120)
        .background(Color(nsColor: .textBackgroundColor))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.8)
        )
    }

    private func blacklistRow(_ app: BlacklistedAppItem) -> some View {
        let isSelected = (selectedBlacklistId == app.bundleIdentifier)
        return HStack(spacing: 8) {
            Image(nsImage: app.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)

            Text(app.displayName)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer()

            Text(app.bundleIdentifier)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            selectedBlacklistId = app.bundleIdentifier
        }
    }

    private func openAppSelectionPanel() {
        NSApp.activate(ignoringOtherApps: true)
        let panel = NSOpenPanel()
        panel.title = "Chọn ứng dụng loại trừ"
        panel.prompt = "Chọn"
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        if #available(macOS 11.0, *) {
            panel.allowedContentTypes = [.applicationBundle, .application]
        } else {
            panel.allowedFileTypes = ["app"]
        }
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.treatsFilePackagesAsDirectories = false

        if panel.runModal() == .OK {
            for url in panel.urls {
                if let bundle = Bundle(url: url), let bundleId = bundle.bundleIdentifier {
                    stateManager.addBlacklistApp(bundleId: bundleId)
                } else {
                    let fallback = url.deletingPathExtension().lastPathComponent
                    stateManager.addBlacklistApp(bundleId: fallback)
                }
            }
        }
    }

    private func removeSelectedBlacklistApp() {
        guard let id = selectedBlacklistId else { return }
        stateManager.removeBlacklistApp(bundleId: id)
        selectedBlacklistId = nil
    }

    // MARK: - Update Banner View
    private var updateBannerView: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                .foregroundColor(.accentColor)
                .font(.system(size: 13))

            VStack(alignment: .leading, spacing: 1) {
                switch updateManager.status {
                case .readyToRestart:
                    Text("Sẵn sàng khởi động lại")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary)

                case .downloading(let progress):
                    Text("Đang tải bản cập nhật... \(Int(progress * 100))%")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary)

                case .updateAvailable(let release):
                    Text("Có bản mới v\(release.versionString)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary)

                case .error(let msg):
                    Text(msg)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.red)
                        .lineLimit(1)

                default:
                    EmptyView()
                }
            }

            Spacer()

            switch updateManager.status {
            case .readyToRestart(let release):
                Button(action: {
                    NSWorkspace.shared.open(release.htmlURL)
                }) {
                    Text("Xem thay đổi")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)

                Button(action: {
                    updateManager.dismissBannerForSession()
                }) {
                    Text("Để sau")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)

                Button(action: {
                    updateManager.restartApp()
                }) {
                    Text("Khởi động lại")
                        .font(.system(size: 10, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

            case .downloading:
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.6)

            case .updateAvailable(let release):
                Button(action: {
                    NSWorkspace.shared.open(release.htmlURL)
                }) {
                    Text("Xem thay đổi")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)

                Button(action: {
                    updateManager.dismissBannerForSession()
                }) {
                    Text("Để sau")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)

                Button(action: {
                    updateManager.startDownloadAndInstall(release: release)
                }) {
                    Text("Cập nhật ngay")
                        .font(.system(size: 10, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

            case .error:
                if let release = updateManager.latestRelease {
                    Button(action: {
                        NSWorkspace.shared.open(release.htmlURL)
                    }) {
                        Text("Xem thay đổi")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }

                Button(action: {
                    updateManager.dismissBannerForSession()
                }) {
                    Text("Để sau")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)

                if let release = updateManager.latestRelease {
                    Button(action: {
                        updateManager.startDownloadAndInstall(release: release)
                    }) {
                        Text("Cập nhật ngay")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }

            default:
                EmptyView()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: 488)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.accentColor.opacity(0.1))
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    // MARK: - Tab 4: About Tab Content
    private var aboutTabContent: some View {
        VStack(spacing: 10) {
            // App Identity Header Card
            cardView {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.75)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)

                        Text("V")
                            .font(.system(size: 21, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text("VietFlow")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.primary)

                            Text("v\(updateManager.currentVersion) (Build 2026.10)")
                                .font(.system(size: 10.5, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.12))
                                .cornerRadius(4)
                        }

                        Text("Bộ gõ Tiếng Việt gốc hiệu năng cao dành cho macOS")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            }

            // Card 1: Architecture & System Information
            cardView {
                Text("Kiến trúc & Hệ thống")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                VStack(spacing: 6) {
                    HStack {
                        Label("Kiến trúc nhị phân:", systemImage: "cpu")
                            .font(.system(size: 11.5))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Universal 2 (Apple Silicon M4 & Intel)")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(.primary)
                    }

                    HStack {
                        Label("Lõi xử lý âm tiết:", systemImage: "keyboard.badge.ellipsis")
                            .font(.system(size: 11.5))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Bamboo Engine (Swift Native) • CGEventTap")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(.primary)
                    }

                    HStack {
                        Label("Mã định danh:", systemImage: "app.badge")
                            .font(.system(size: 11.5))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("com.nhanqv.VietFlow")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.primary)
                    }

                    Divider()

                    Toggle("Tự động khởi động cùng macOS khi đăng nhập", isOn: $stateManager.launchAtLogin)
                        .toggleStyle(.checkbox)
                        .font(.system(size: 11.5))
                }
            }

            // Card 2: Software Updates
            cardView {
                Text("Cập nhật phần mềm")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Tự động kiểm tra cập nhật mỗi ngày", isOn: $stateManager.automaticallyCheckForUpdates)
                        .toggleStyle(.checkbox)
                        .font(.system(size: 11.5))

                    Divider()

                    HStack(spacing: 10) {
                        Button(action: {
                            updateManager.checkForUpdates(userInitiated: true)
                        }) {
                            HStack(spacing: 4) {
                                if case .checking = updateManager.status {
                                    ProgressView()
                                        .controlSize(.small)
                                        .scaleEffect(0.6)
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 11))
                                }
                                Text("Kiểm tra cập nhật")
                                    .font(.system(size: 11.5, weight: .medium))
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(updateManager.isBusy)

                        Spacer()

                        updateStatusLabel
                    }
                }
            }

            // Card 2: Author & License
            cardView {
                Text("Tác giả & Bản quyền")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                VStack(spacing: 6) {
                    HStack {
                        Label("Tác giả:", systemImage: "person.crop.circle")
                            .font(.system(size: 11.5))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Nhan Quach (@nhanqv-ai)")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(.primary)
                    }

                    HStack {
                        Label("Giấy phép:", systemImage: "doc.text")
                            .font(.system(size: 11.5))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("MIT License")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(.primary)
                    }

                    HStack {
                        Label("Kho lưu trữ:", systemImage: "network")
                            .font(.system(size: 11.5))
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: {
                            if let url = URL(string: "https://github.com/nhanqv-ai/VietFlow") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text("nhanqv-ai/VietFlow")
                                    .font(.system(size: 11.5, weight: .medium))
                                Image(systemName: "arrow.up.forward.square")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Card 3: Reset to Defaults
            cardView {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Khôi phục cấu hình")
                            .font(.system(size: 12.5, weight: .semibold))
                        Text("Đưa toàn bộ thiết lập về trạng thái mặc định ban đầu.")
                            .font(.system(size: 10.5))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Button(role: .destructive, action: {
                        showingResetConfirmation = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 11))
                            Text("Khôi phục cài đặt gốc")
                                .font(.system(size: 11))
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
    }

    // MARK: - Update Status Label
    @ViewBuilder
    private var updateStatusLabel: some View {
        switch updateManager.status {
        case .idle:
            EmptyView()
        case .checking:
            Text("Đang kiểm tra...")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        case .upToDate(let ver):
            Text("Đã là phiên bản mới nhất (v\(ver))")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        case .updateAvailable(let release):
            HStack(spacing: 6) {
                Text("Có bản mới v\(release.versionString)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.accentColor)
                Button("Cập nhật ngay") {
                    updateManager.startDownloadAndInstall(release: release)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.mini)
            }
        case .downloading:
            HStack(spacing: 4) {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.6)
                Text("Đang tải bản cập nhật...")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        case .readyToRestart:
            HStack(spacing: 6) {
                Text("Sẵn sàng khởi động lại")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.accentColor)
                Button("Khởi động lại") {
                    updateManager.restartApp()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.mini)
            }
        case .error(let msg):
            Text(msg)
                .font(.system(size: 11))
                .foregroundColor(.red)
                .lineLimit(1)
        }
    }

    private func resetAllSettings() {
        hotKeyWarningMessage = nil
        selectedBlacklistId = nil
        stateManager.resetToDefaults()
    }

    // MARK: - Footer Bar
    private var footerBar: some View {
        HStack {
            Spacer()
            Button("Đóng") {
                onClose?()
            }
            .keyboardShortcut(.defaultAction)
            .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
