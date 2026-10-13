//
//  PreferencesView.swift
//  VietFlowApp
//
//  Native macOS System Settings style Preferences window.
//  Strictly uses Apple SF Symbols, zero emojis.
//

import SwiftUI
import VietFlowEngine
import VietFlowState

public enum PreferencesTab: String, CaseIterable, Identifiable {
    case keyboard = "Bàn phím"
    case general = "Hệ thống"
    case applications = "Ứng dụng"
    case advanced = "Nâng cao"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .keyboard: return "keyboard"
        case .general: return "gearshape"
        case .applications: return "square.stack.3d.up"
        case .advanced: return "slider.horizontal.3"
        }
    }
}

public struct PreferencesView: View {
    @ObservedObject var stateManager: AppStateManager
    @State private var selectedTab: PreferencesTab = .keyboard
    @State private var showingResetConfirmation = false
    
    public init(stateManager: AppStateManager = .shared) {
        self.stateManager = stateManager
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Segmented Tab Bar with SF Symbols
            Picker("Tabs", selection: $selectedTab) {
                ForEach(PreferencesTab.allCases) { tab in
                    Label(tab.rawValue, systemImage: tab.iconName).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            
            Divider()
            
            // Tab Contents
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedTab {
                    case .keyboard:
                        KeyboardTab(stateManager: stateManager)
                    case .general:
                        GeneralTab(stateManager: stateManager)
                    case .applications:
                        ApplicationsTab(stateManager: stateManager)
                    case .advanced:
                        AdvancedTab(stateManager: stateManager, showingReset: $showingResetConfirmation)
                    }
                }
                .padding(24)
            }
        }
        .frame(width: 640, height: 480)
        .alert("Khôi phục cài đặt gốc?", isPresented: $showingResetConfirmation) {
            Button("Hủy", role: .cancel) {}
            Button("Khôi phục", role: .destructive) {
                stateManager.resetToDefaults()
            }
        } message: {
            Text("Toàn bộ cấu hình kiểu gõ, phím tắt và danh sách ứng dụng loại trừ sẽ được đưa về mặc định ban đầu.")
        }
    }
}

// MARK: - Tab 1: Keyboard Tab
struct KeyboardTab: View {
    @ObservedObject var stateManager: AppStateManager
    
    var body: some View {
        Form {
            Section(header: Text("Kiểu gõ & Dấu thanh").font(.headline)) {
                Picker("Kiểu gõ chính:", selection: $stateManager.currentInputMethod) {
                    ForEach(InputMethod.allCases, id: \.self) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                
                Picker("Quy tắc đặt dấu thanh:", selection: $stateManager.currentTonePlacement) {
                    Text("Dấu Mới (hòa, thúy)").tag(TonePlacementStyle.modern)
                    Text("Dấu Cũ (hoà, thuý)").tag(TonePlacementStyle.traditional)
                }
            }
            
            Section(header: Text("Tùy chọn nâng cao khi soạn thảo").font(.headline)) {
                Toggle("Tự động khôi phục từ tiếng Anh khi gõ sai âm tiết", isOn: $stateManager.autoRestoreEnglish)
                Text("Tránh làm biến dạng các từ tiếng Anh (ví dụ: 'post', 'view', 'chat') khi đang bật tiếng Việt.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Toggle("Gõ lặp phím dấu để thoát tiếng Việt (ví dụ: 'ss' -> 's')", isOn: $stateManager.escapeByDoubleKey)
            }
        }
    }
}

// MARK: - Tab 2: General Tab
struct GeneralTab: View {
    @ObservedObject var stateManager: AppStateManager
    
    var body: some View {
        Form {
            Section(header: Text("Phím tắt chuyển đổi").font(.headline)) {
                Picker("Phím tắt chuyển Việt / Anh:", selection: $stateManager.toggleShortcut) {
                    ForEach(ToggleShortcut.allCases, id: \.self) { shortcut in
                        Text(shortcut.rawValue).tag(shortcut)
                    }
                }
            }
            
            Section(header: Text("Khởi động & Hệ thống").font(.headline)) {
                Toggle("Tự động khởi động cùng macOS khi đăng nhập", isOn: $stateManager.launchAtLogin)
                
                HStack {
                    Text("Chế độ đang kích hoạt:")
                    Spacer()
                    Text(stateManager.currentInputMode.title)
                        .fontWeight(.semibold)
                        .foregroundColor(stateManager.currentInputMode == .vietnamese ? .accentColor : .secondary)
                }
            }
        }
    }
}

// MARK: - Tab 3: Applications Tab
struct ApplicationsTab: View {
    @ObservedObject var stateManager: AppStateManager
    @State private var newBundleId: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("Quản lý trạng thái theo ứng dụng").font(.headline)) {
                Toggle("Ghi nhớ chế độ gõ độc lập cho từng ứng dụng", isOn: $stateManager.perAppInputMode)
                Text("Tự động lưu và phục hồi chế độ gõ (Việt / Anh) riêng biệt khi chuyển đổi giữa các cửa sổ ứng dụng (Terminal, VS Code, Browser...).")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("Danh sách ứng dụng loại trừ (Blacklist)").font(.headline)) {
                Text("VietFlow sẽ tự động tạm dừng hoàn toàn, không can thiệp phím khi bạn sử dụng các ứng dụng trong danh sách này:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                List {
                    ForEach(stateManager.blacklistedBundleIdentifiers, id: \.self) { bundleId in
                        HStack {
                            Image(systemName: "app.badge.checkmark")
                                .foregroundColor(.secondary)
                            Text(bundleId)
                                .font(.system(.body, design: .monospaced))
                            Spacer()
                            Button(action: {
                                stateManager.removeBlacklistApp(bundleId: bundleId)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(height: 120)
                
                HStack {
                    TextField("Nhập Bundle ID (ví dụ: com.riotgames.leagueoflegends)", text: $newBundleId)
                        .textFieldStyle(.roundedBorder)
                    Button("Thêm") {
                        let trimmed = newBundleId.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            stateManager.addBlacklistApp(bundleId: trimmed)
                            newBundleId = ""
                        }
                    }
                    .disabled(newBundleId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Tab 4: Advanced Tab
struct AdvancedTab: View {
    @ObservedObject var stateManager: AppStateManager
    @Binding var showingReset: Bool
    
    var body: some View {
        Form {
            Section(header: Text("Kiến trúc & Tương thích").font(.headline)) {
                HStack {
                    Label("Lõi xử lý âm tiết:", systemImage: "cpu")
                    Spacer()
                    Text("Bamboo Engine (Swift Native)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Label("Hạ tầng bắt phím:", systemImage: "keyboard.badge.ellipsis")
                    Spacer()
                    Text("macOS CGEventTap (Low-Level HID)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Label("Kiến trúc nhị phân:", systemImage: "macmini")
                    Spacer()
                    Text("Universal 2 (Apple Silicon & Intel)")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Khôi phục cài đặt").font(.headline)) {
                Button(role: .destructive, action: {
                    showingReset = true
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Khôi phục toàn bộ cài đặt về mặc định")
                    }
                }
            }
        }
    }
}
