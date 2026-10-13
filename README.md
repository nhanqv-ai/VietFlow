# VietFlow — Bộ Gõ Tiếng Việt Thế Hệ Mới Cho macOS

[![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue?logo=apple)](https://www.apple.com/macos/)
[![Architecture](https://img.shields.io/badge/Architecture-Universal%202%20(arm64%20%2B%20x86__64)-purple)]()
[![Tests](https://img.shields.io/badge/Tests-840%20passed%20(100%25)-success)]()
[![License](https://img.shields.io/badge/License-GPL%20v3-green)](LICENSE)

**VietFlow** là bộ gõ tiếng Việt hiệu năng cao dành riêng cho macOS, được xây dựng hoàn toàn bằng **Swift Native**, kết hợp lõi thuật toán ngữ âm hiện đại **Bamboo Engine** và kiến trúc bắt phím mức thấp **`CGEventTap`**.

VietFlow ra đời nhằm giải quyết dứt điểm các lỗi kinh điển mà người dùng macOS thường xuyên gặp phải trên **bộ gõ mặc định của Apple** và các bộ gõ đời cũ (như **GoTiengViet, UniKey**).

---

## 💡 Đặt Vấn Đề: Vì Sao Bộ Gõ Mặc Định & Bộ Gõ Cũ Bị Lỗi?

### 1. Nhược điểm của Bộ gõ mặc định macOS
Apple sử dụng kiến trúc **InputMethodKit (IMK)** với cơ chế đệm gạch chân (`marked text`). Khi người dùng gõ vào các ứng dụng không tuân thủ hoàn hảo chuẩn IMK của Apple (điển hình là **Google Chrome, Safari URL bar, VS Code, Slack, Discord, Notion**):
- Xảy ra bất đồng bộ giữa IME Server và Client, dẫn đến hiện tượng **nuốt chữ, mất phím khi gõ nhanh**.
- **Lặp từ / nhân đôi ký tự**: Gõ `tiếng` bị nhảy thành `tiếeng` hoặc lặp vần `aâ`.
- Xung đột vùng đệm gạch chân khi tìm kiếm trực tiếp trên thanh địa chỉ hoặc form web.

### 2. Nhược điểm của GoTiengViet / UniKey cũ trên Terminal
Trong các ứng dụng dòng lệnh (**Terminal.app, iTerm2, Warp, Alacritty, Vim, Nano**):
- GoTiengViet và UniKey sử dụng thuật toán cổ điển: khi thêm dấu, bộ gõ gửi một chuỗi phím ảo xóa lùi toàn bộ từ rồi chèn lại từ mới (ví dụ từ `tiên` sang `tiến` phải gửi tới 4 phím Backspace).
- Shell (zsh/bash với autocomplete và syntax-highlighting) không kịp xử lý chuỗi Backspace ảo dồn dập, dẫn đến **lệch con trỏ chuột, mất dấu hoặc văng ký tự rác**.

---

## 🚀 Giải Pháp Đột Phá Của VietFlow

1. **Lõi Bamboo Engine (Swift Native)**:
   - Ứng dụng ma trận ngữ âm học chính quy CVC (Phụ âm đầu - Vần - Phụ âm cuối).
   - Hỗ trợ đầy đủ các kiểu gõ phổ biến: **Telex, Simple Telex, VNI**.
   - Chuyển đổi linh hoạt giữa quy tắc dấu thanh **Mới (`hòa, thúy`)** và **Cũ (`hoà, thuý`)**.
   - Nhận diện ngữ cảnh và **tự động khôi phục từ tiếng Anh** (`code`, `view`, `post`, `format`, `reset`...) mà không gây nhấp nháy chữ.

2. **Thuật toán Khác Biệt Tối Thiểu (Minimal Diff - $LCP$)**:
   - So sánh tiền tố chung dài nhất (Longest Common Prefix) giữa từ đang hiển thị và từ kết quả.
   - Khi đổi từ `tiên` sang `tiến`: VietFlow phát hiện tiền tố `ti` đã có sẵn, **chỉ gửi 2 phím Backspace thay vì 4**. Cắt giảm hơn 50% số phím ảo, **triệt tiêu hoàn toàn lỗi lệch con trỏ trong Terminal**.

3. **Hạ tầng Bắt Phím `CGEventTap` Toàn Hệ Thống**:
   - Bắt phím ở tầng phần cứng thấp nhất (`.cghidEventTap`), nuốt phím kích hoạt và chèn chuỗi ký tự **Unicode NFC đơn (Precomposed Characters)**.
   - Cơ chế cờ đánh dấu **Loop Guard (`0x564E4B59`)** chống 100% vòng lặp sự kiện vô tận và không gây tốn CPU.
   - Tự động tạm dừng (pass-through) an toàn khi gặp các trường nhập mật khẩu bảo mật (**Secure Input** như `sudo`, Touch ID, 1Password).

4. **Quản Lý Trạng Thái Thông Minh (Per-App State & Blacklist)**:
   - Tự động ghi nhớ chế độ gõ riêng cho từng cửa sổ ứng dụng: Khi bạn chuyển sang Terminal hoặc VS Code, VietFlow tự động chuyển về tiếng Anh; khi chuyển về Slack/Trình duyệt, tự động bật lại tiếng Việt.
   - Cung cấp danh sách loại trừ (**Blacklist**) cho các ứng dụng hoặc tựa game không muốn can thiệp phím.

5. **Thiết Kế macOS Human Interface Guidelines (Strictly No Emoji)**:
   - Ứng dụng chạy ngầm trên Menu Bar (**Agent mode: `LSUIElement = true`**), không chiếm chỗ trên thanh Dock.
   - Biểu tượng Menu Bar là ký tự typography vector **`V`** / **`E`**, tự động thích ứng với cả Dark Mode và Light Mode.
   - App Icon được thiết kế vector chuyên nghiệp dạng phím bấm cách điệu chữ `V` và dấu thanh thanh lịch (file `AppIcon.icns` chứa đầy đủ 10 độ phân giải từ 16x16 đến 1024x1024 Retina).
   - Cửa sổ Cài đặt (Preferences) 4 tab chuẩn phong cách macOS System Settings với hệ thống SF Symbols vector tinh tế.

6. **Hỗ trợ Universal 2 Binary (Apple Silicon M4 & Intel 2020)**:
   - Biên dịch dưới dạng **Universal 2 Binary**, chứa cả 2 kiến trúc `arm64` (M1/M2/M3/M4) và `x86_64` (MacBook Pro Intel).
   - Chạy **Native 100%**, tiêu thụ cực ít RAM (< 30MB) và 0% CPU khi không gõ phím.

---

## 🧪 Chất Lượng & Kiểm Thử Tự Động (840/840 Tests Pass)

Dự án được xây dựng cùng bộ kiểm thử tự động khổng lồ gồm **840 ca test** (vượt 68% tiêu chuẩn nghiệm thu ban đầu) chạy chỉ trong **0.032 giây**:

```
================================================================================
 VietFlow Automated Test Suite Runner
================================================================================
 Running Suite: BasicTelexTests (171 tests)         -> 171 passed, 0 failed
 Running Suite: SimpleTelexTests (84 tests)         -> 84 passed,  0 failed
 Running Suite: VNITests (129 tests)                -> 129 passed, 0 failed
 Running Suite: TonePlacementTests (86 tests)       -> 86 passed,  0 failed
 Running Suite: DiacriticUndoTests (80 tests)       -> 80 passed,  0 failed
 Running Suite: EnglishRestoreTests (80 tests)      -> 80 passed,  0 failed
 Running Suite: RapidTypingTests (70 tests)         -> 70 passed,  0 failed
 Running Suite: MinimalDiffTests (60 tests)         -> 60 passed,  0 failed
 Running Suite: TerminalCompatibilityTests (80 tests)-> 80 passed,  0 failed
================================================================================
 Total Suites: 9 | Total Cases: 840 | Passed: 840 (100%) | Failed: 0
================================================================================
```

---

## 🛠️ Cài Đặt & Sử Dụng

### Yêu cầu hệ thống
* macOS 13.0 (Ventura), macOS 14 (Sonoma), macOS 15 (Sequoia) trở lên.
* Tương thích: **MacBook chip Intel** (MacBook Pro 2020...) và **MacBook Apple Silicon** (M1, M2, M3, M4...).

### 1. Build & Cài đặt tự động bằng Makefile
Mở Terminal trong thư mục dự án và chạy:

```bash
# Chạy bộ test kiểm thử tự động
make test

# Đóng gói bản dựng Universal 2 (VietFlow.app)
make app

# Cài đặt trực tiếp vào thư mục /Applications
make install
```

### 2. Cấp quyền Trợ năng (Accessibility)
Do sử dụng cơ chế `CGEventTap` mức thấp để xử lý phím không gián đoạn:
1. Khi khởi động lần đầu, macOS sẽ hiển thị hộp thoại yêu cầu cấp quyền Trợ năng.
2. Vào **System Settings > Privacy & Security > Accessibility** (Cài đặt hệ thống > Quyền riêng tư & Bảo mật > Trợ năng).
3. Bật gạt cho phép **VietFlow**.
4. VietFlow sẽ lập tức kích hoạt bộ gõ mà không cần khởi động lại ứng dụng.

### 3. Phím tắt thao tác nhanh
* **Click chuột trái** vào biểu tượng Menu Bar: Chuyển đổi nhanh giữa Tiếng Việt (**V**) và Tiếng Anh (**E**).
* **Click chuột phải** vào biểu tượng Menu Bar: Mở menu chọn nhanh kiểu gõ, quy tắc dấu hoặc vào cửa sổ Cài đặt.
* **Phím tắt toàn hệ thống**: Mặc định là `Control + Shift` (có thể tùy chỉnh thành `Command + Shift` hoặc `Option` trong Cài đặt).

---

## 📂 Cấu Trúc Mã Nguồn

```
VietFlow/
├── Sources/
│   ├── VietFlowEngine/        # Lõi Bamboo Engine: ma trận âm tiết, Telex/VNI, LCP diff
│   ├── VietFlowState/         # Quản lý cài đặt, per-app state, blacklist, hotkeys
│   ├── VietFlowEventTap/      # CGEventTap mức thấp, loop guard, key injection
│   └── VietFlowApp/           # Menu Bar item (AppKit), Cài đặt SwiftUI, AppDelegate
├── Tests/
│   ├── VietFlowEngineTests/   # 8 bộ test chuyên sâu về ngữ âm và gõ phím
│   ├── VietFlowTerminalBufferTests/ # Bộ giả lập Terminal PTY Raw-Mode Simulator
│   └── TestRunnerMain.swift   # Trình chạy CLI Test Runner độc lập
├── Scripts/
│   ├── run_tests.sh           # Script chạy tự động 840 test cases
│   └── build_app.sh           # Script đóng gói Universal 2 VietFlow.app bundle
├── Resources/
│   └── Info.plist             # Cấu hình Bundle Agent (LSUIElement = true)
├── AppIcon.icns               # Icon ứng dụng vector chuẩn Apple HIG (No Emoji)
└── Makefile                   # Tự động hóa build, test, install
```

---

## 👤 Tác Giả & Bản Quyền
* **Tác giả**: Quách Văn Nhân ([@nhanqv-ai](https://github.com/nhanqv-ai))
* **Email**: 25052403@vnu.edu.vn
* **Kho lưu trữ**: [https://github.com/nhanqv-ai/VietFlow](https://github.com/nhanqv-ai/VietFlow)
