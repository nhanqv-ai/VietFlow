<p align="center">
  <img src="Assets/AppIcon.png" alt="VietFlow App Icon" width="128" height="128" />
</p>

<h1 align="center">VietFlow</h1>

<p align="center">
  <strong>Ultra-Lightweight, Zero-Latency Native macOS Vietnamese Input Method</strong><br>
  <em>Swift &bull; SwiftUI &bull; Bamboo Phonotactics Engine &bull; Minimal Diff (LCP) &bull; Universal 2 &bull; Foreign IME Coexistence</em>
</p>

<p align="center">
  <a href="#english">English</a> &bull; <a href="#tiếng-việt">Tiếng Việt</a>
</p>

<p align="center">
  <a href="https://github.com/nhanqv-ai/VietFlow/releases"><img src="https://img.shields.io/github/v/release/nhanqv-ai/VietFlow?style=flat-square&color=blue" alt="Release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green.svg?style=flat-square" alt="License"></a>
  <img src="https://img.shields.io/badge/platform-macOS%2013%2B%20%7C%20Sonoma%2014.6%2B%20%7C%20Sequoia%2015%2B-lightgrey.svg?style=flat-square" alt="Platform">
  <img src="https://img.shields.io/badge/architecture-Universal%202%20(arm64%20%2B%20x86__64)-blue.svg?style=flat-square" alt="Architecture">
  <img src="https://img.shields.io/badge/tests-1%2C317%20passed%20(100%25)-success.svg?style=flat-square" alt="Tests">
  <img src="https://img.shields.io/badge/Swift-6.0-orange.svg?style=flat-square" alt="Swift">
</p>

---

<a name="english"></a>
## English

**VietFlow** is an ultra-lightweight, zero-latency native macOS Vietnamese input method built from the ground up with Swift and SwiftUI. Combining a formal **Bamboo CVC Phonotactics Engine** with a low-level **`CGEventTap`** interceptor and **Longest Common Prefix (LCP) Minimal Diff** injection, VietFlow eliminates the underlined-preedit glitches, swallowed keystrokes, duplicated characters (`tiếeng`), and terminal cursor desynchronization found in Apple's built-in IME and legacy input tools.

### Highlights

- **Bamboo CVC Phonotactics Engine & Free-Order Typing**:
  - Full support for **Telex**, **Simple Telex**, and **VNI**, plus both **Modern (`hòa, thúy`)** and **Traditional (`hoà, thuý`)** tone placement rules.
  - Natural **free-order diacritic and tone placement** at the start, middle, or end of a syllable (e.g., `moiws` / `mowis` / `mowsi` $\rightarrow$ `mới`, `swar` / `suwar` / `suawr` $\rightarrow$ `sửa`, `thuowr` $\rightarrow$ `thuở`, `gixw` $\rightarrow$ `giữ`, `howacj` / `hoawcj` / `hoacwj` $\rightarrow$ `hoặc`, `dods` $\rightarrow$ `đó`).
- **Seamless Multi-Backspace & Cross-Space Word Editing**:
  - Synchronizes canonical keystroke state with on-screen NFC characters (`1 Backspace = 1 displayed character`), allowing effortless mid-word corrections and backspacing across spaces (`spaceHistory` up to 16 words) without ghost characters or buffer desynchronization.
- **Smart English Auto-Restoration**:
  - Automatically detects and restores single- and multi-syllable English words (`code`, `view`, `window`, `pattern`, `server`, `service`, `version`, `target`, `market`, `container`, `router`, `work`, `task`, `book`, `tool`, etc.) and invalid Vietnamese phonotactic structures without screen flicker.
- **Minimal Diff ($LCP$) Terminal Compatibility**:
  - Computes the Longest Common Prefix between the current screen buffer and transformed syllable, emitting the minimum possible virtual Backspaces (e.g., transforming `tiên` $\rightarrow$ `tiến` emits only 2 Backspaces instead of 4). Works flawlessly in **Terminal.app, iTerm2, Warp, Alacritty, Kitty, tmux, Vim, and zsh**.
- **Seamless Coexistence with macOS Japanese & Foreign Input Sources (`ABC` $\leftrightarrow$ `あ Japanese`)**:
  - Real-time Carbon `TISCopyCurrentKeyboardInputSource` and `kTISNotifySelectedKeyboardInputSourceChanged` integration.
  - **Auto-Suspend**: Switching macOS Input Source from `ABC` to `あ Japanese` (or Chinese, Korean, etc.) flushes the buffer and automatically switches VietFlow to `[E]` so romaji/kana/kanji composition works with zero interference.
  - **Auto-Restore**: Switching macOS back to `ABC` automatically restores your previous `[V]` / `[E]` state.
  - **One-Step Direct Switch (`Japanese` $\rightarrow$ `Vietnamese`)**: Pressing VietFlow's shortcut or clicking its Menu Bar icon while in `Japanese` automatically switches macOS Input Source back to `ABC` and enables `[V]` in a single action.
- **Per-App Input Mode & Application Blacklist**:
  - Remembers `[V]` or `[E]` independently for each application (`perAppInputMode`), and completely bypasses blacklisted apps or games (`blacklistedBundleIdentifiers`).
  - Automatically bypasses macOS **Secure Event Input** fields (password prompts, Touch ID, `sudo`, 1Password).
- **Universal 2 Architecture**:
  - Compiled as a native Mach-O fat binary supporting both Apple Silicon (`arm64`: M1/M2/M3/M4) and Intel (`x86_64`: MacBook Pro 2020 and earlier) on macOS 13.0 (Ventura), macOS 14.6+ (Sonoma), and macOS 15+ (Sequoia).
- **Launch at Login & Zero Emojis Invariant**:
  - Native login item management via `SMAppService`, crisp CoreGraphics vector Menu Bar keycap glyphs (`V` / `E`), and a 4-tab SwiftUI Settings window adhering strictly to a 0-emoji professional design.

### Keyboard Shortcuts & Interactions

| Shortcut / Action | Description | Scope |
| :--- | :--- | :--- |
| `Control + Shift` (Default) | Toggle between Vietnamese (`[V]`) and English (`[E]`) — or switch directly from `Japanese` to `ABC [V]` | Global |
| `Command + Shift` / `Option + Shift` / `Option` | Alternative modifier-chord shortcuts selectable in Settings | Global |
| `Custom Key Combo` (e.g., `⌃Space`, `⌥Z`) | User-recordable custom global hotkey via Carbon `RegisterEventHotKey` | Global |
| `Left-Click Menu Bar Icon` | Instantly toggle `[V]` / `[E]` mode | Menu Bar |
| `Right-Click Menu Bar Icon` | Open quick context menu (Input Method, Tone Style, Settings, Quit) | Menu Bar |
| `Double-Press Diacritic / Tone Key` | Undo transformation and restore literal ASCII key (`aa`, `ww`, `ss`, `dd`) | While Typing |
| `z` (Telex) / `0` (VNI) | Explicitly strip tone mark from the current syllable | While Typing |

### System Requirements

- macOS 13.0 (Ventura), macOS 14.6+ (Sonoma), macOS 15+ (Sequoia), or newer
- Apple Silicon Mac (`arm64`) or Intel Mac (`x86_64`, e.g. MacBook Pro 2020)

### Installation

#### Pre-built Release
1. Download the latest `VietFlow-v1.0.0.zip` from [Releases](https://github.com/nhanqv-ai/VietFlow/releases).
2. Unzip and drag `VietFlow.app` into your `/Applications` folder.
3. Open `VietFlow.app`. The `V` / `E` keycap icon will appear on your macOS menu bar.

> [!NOTE]
> **First-Time Launch (macOS Gatekeeper)**:
> Since VietFlow is an independent open-source project without paid Apple Developer ID notarization, macOS may display a verification prompt (*"VietFlow" Not Opened*). You can open it easily via any of these methods:
> - **Terminal (Recommended)**: Run `xattr -cr /Applications/VietFlow.app` (or on the unzipped path).
> - **System Settings**: Go to **System Settings** $\rightarrow$ **Privacy & Security** $\rightarrow$ scroll down to **Security** $\rightarrow$ click **Open Anyway**.
> - **Finder**: Right-click (or `Control` + click) `VietFlow.app` $\rightarrow$ choose **Open** $\rightarrow$ click **Open**.

> [!TIP]
> **Accessibility Permission (`CGEventTap` & TCC Cache Refresh)**:
> VietFlow intercepts and injects Unicode characters at the system event level, which requires macOS Accessibility permission.
> - **Quick Setup**: In VietFlow **Settings** $\rightarrow$ **Bàn phím (Keyboard)**, click **Cấp quyền Trợ năng** (Grant Accessibility Permission).
> - **macOS Sonoma / Ventura / Sequoia Cache Fix**: If you previously installed an older build of VietFlow and System Settings retains a stale CDHash entry, click **Cấp quyền Trợ năng** inside VietFlow (which automatically runs `tccutil reset` to flush stale TCC cache), or go to **System Settings** $\rightarrow$ **Privacy & Security** $\rightarrow$ **Accessibility**, select `VietFlow`, click the minus (`-`) button to remove the old entry, and toggle it back on.
> - **Terminal Shortcut**: You can also run `tccutil reset Accessibility com.nhanqv.VietFlow` to immediately clear stale permission cache.

#### Build from Source
```bash
git clone https://github.com/nhanqv-ai/VietFlow.git
cd VietFlow
make app
make install
open /Applications/VietFlow.app
```

### Development & Testing

```bash
# Compile and execute all 15 automated test suites (1,317 tests, 100% pass)
make test

# Build Universal 2 VietFlow.app bundle (arm64 + x86_64)
make app

# Package distributable Universal 2 zip archive (build/VietFlow-v1.0.0.zip)
make package

# Install VietFlow.app into /Applications
make install

# Clean build artifacts
make clean
```

---

<a name="tiếng-việt"></a>
## Tiếng Việt

**VietFlow** là bộ gõ tiếng Việt gốc (native), siêu nhẹ và độ trễ bằng không dành cho macOS, được xây dựng hoàn toàn bằng **Swift** và **SwiftUI**. Kết hợp lõi thuật toán ngữ âm **Bamboo CVC Engine** với kiến trúc bắt phím mức thấp **`CGEventTap`** và thuật toán chèn ký tự tối thiểu **Minimal Diff ($LCP$)**, VietFlow giải quyết triệt để lỗi gạch chân (`marked text`), nuốt chữ, nhân đôi ký tự (`tiếeng`) trên trình duyệt và lỗi nhảy con trỏ trong Terminal của bộ gõ mặc định macOS cũng như các bộ gõ đời cũ.

### Tính năng nổi bật

- **Lõi Bamboo Engine & Gõ Dấu Tự Do (Free-Order Typing)**:
  - Hỗ trợ đầy đủ 3 kiểu gõ: **Telex**, **Simple Telex**, **VNI** cùng 2 quy tắc đặt dấu thanh **Dấu Mới (`hòa, thúy`)** và **Dấu Cũ (`hoà, thuý`)**.
  - Cho phép bỏ dấu thanh và dấu mũ/móc ở **bất kỳ vị trí nào** (đầu, giữa hoặc cuối âm tiết): `moiws` / `mowis` / `mowsi` $\rightarrow$ `mới`, `swar` / `suwar` / `suawr` $\rightarrow$ `sửa`, `thuowr` $\rightarrow$ `thuở`, `gixw` $\rightarrow$ `giữ`, `howacj` / `hoawcj` / `hoacwj` $\rightarrow$ `hoặc`, `dods` $\rightarrow$ `đó`.
- **Xóa Backspace Chính Xác & Sửa Lỗi Xuyên Khoảng Trắng**:
  - Đồng bộ 1-1 giữa ký tự Unicode NFC hiển thị trên màn hình và trạng thái phím nội bộ (`1 Backspace = xóa đúng 1 chữ trên màn hình`), hỗ trợ nhấn Backspace liên hoàn giữa từ hoặc lùi qua nhiều khoảng trắng (`spaceHistory` lưu tới 16 từ) để sửa lại từ trước đó mà không bao giờ bị văng ký tự rác.
- **Tự Động Khôi Phục Từ Tiếng Anh Thông Minh**:
  - Tự động nhận diện và trả về nguyên gốc các từ tiếng Anh đơn âm tiết và đa âm tiết (`code`, `view`, `window`, `pattern`, `server`, `service`, `version`, `target`, `market`, `container`, `router`, `work`, `task`, `book`, `tool`...) ngay khi phát hiện cấu trúc âm tiết nằm ngoài ngữ âm tiếng Việt.
- **Thuật Toán Khác Biệt Tối Thiểu (Minimal Diff - $LCP$) Cho Terminal**:
  - Tính toán tiền tố chung dài nhất (Longest Common Prefix) giữa chuỗi đang hiển thị và chuỗi mới để gửi số lượng phím Backspace ảo ít nhất (ví dụ chuyển `tiên` $\rightarrow$ `tiến` chỉ gửi 2 phím Backspace thay vì 4), giúp gõ tiếng Việt mượt mà tuyệt đối trên **Terminal.app, iTerm2, Warp, Alacritty, Kitty, tmux, Vim, zsh**.
- **Tương Thích Hoàn Hảo Với Bộ Gõ Tiếng Nhật & Ngoại Ngữ Của macOS (`ABC` $\leftrightarrow$ `あ Japanese`)**:
  - Tích hợp thời gian thực với Carbon `TISCopyCurrentKeyboardInputSource` và `kTISNotifySelectedKeyboardInputSourceChanged`.
  - **Tự động tạm ngưng**: Khi bạn chuyển bộ gõ macOS từ `ABC` sang `あ Japanese` (hoặc Tiếng Trung, Tiếng Hàn...), VietFlow tự động xóa bộ đệm và chuyển sang chế độ **`[E]`** để bạn gõ Romaji/Hiragana/Kanji hoàn toàn không bị xung đột.
  - **Tự động khôi phục**: Khi chuyển macOS từ `あ Japanese` về lại `ABC`, VietFlow tự động khôi phục lại đúng trạng thái **`[V]`** / **`[E]`** trước đó.
  - **Chuyển thẳng 1 bước từ Nhật sang Việt (`あ Japanese` $\rightarrow$ `ABC [V]`)**: Khi đang ở bộ gõ `Japanese`, chỉ cần bấm phím tắt của VietFlow (ví dụ `Control + Shift`) hoặc click chuột trái vào icon VietFlow trên Menu Bar, VietFlow sẽ tự động chuyển macOS về lại `ABC` đồng thời bật `[V]`.
- **Ghi Nhớ Theo Từng Ứng Dụng & Danh Sách Loại Trừ (Blacklist)**:
  - Tự động ghi nhớ chế độ `[V]` / `[E]` riêng cho từng ứng dụng (`perAppInputMode`) và tự động bỏ qua các ứng dụng/game nằm trong danh sách loại trừ (`blacklistedBundleIdentifiers`).
  - Tự động nhường phím an toàn tại các ô nhập mật khẩu bảo mật (**Secure Event Input** như `sudo`, Touch ID, 1Password).
- **Kiến Trúc Universal 2 & Thiết Kế Chuẩn Apple HIG (0 Emojis)**:
  - Biên dịch dưới dạng Mach-O fat binary hỗ trợ gốc cả chip Apple Silicon (`arm64`: M1/M2/M3/M4) và chip Intel (`x86_64`: MacBook Pro 2020) trên macOS 13.0 (Ventura), macOS 14.6+ (Sonoma) và macOS 15+ (Sequoia).
  - Biểu tượng Menu Bar dạng keycap vector sắc nét (`V` / `E`), hỗ trợ khởi động cùng hệ thống qua `SMAppService` và tuân thủ quy chuẩn **0 Emojis**.

### Bảng phím tắt thông dụng

| Phím tắt / Thao tác | Chức năng | Phạm vi |
| :--- | :--- | :--- |
| `Control + Shift` (Mặc định) | Chuyển đổi nhanh Tiếng Việt (`[V]`) / Tiếng Anh (`[E]`) — hoặc chuyển thẳng từ `Japanese` về `ABC [V]` | Toàn hệ thống |
| `Command + Shift` / `Option + Shift` / `Option` | Các tổ hợp phím bổ trợ thay thế chọn trong Cài đặt | Toàn hệ thống |
| `Tổ hợp phím tùy chỉnh` (VD: `⌃Space`, `⌥Z`) | Tự ghi nhận phím tắt bất kỳ qua Carbon `RegisterEventHotKey` | Toàn hệ thống |
| `Click chuột trái vào icon Menu Bar` | Chuyển đổi tức thì chế độ `[V]` / `[E]` | Thanh Menu |
| `Click chuột phải vào icon Menu Bar` | Mở menu chọn nhanh Kiểu gõ, Quy tắc dấu, Cài đặt, Thoát | Thanh Menu |
| `Gõ lặp 2 lần phím dấu` (`aa`, `ww`, `ss`, `dd`) | Hoàn tác dấu vừa bỏ và trả về ký tự ASCII nguyên gốc | Khi đang gõ |
| `z` (Telex) / `0` (VNI) | Xóa dấu thanh của âm tiết hiện tại | Khi đang gõ |

### Yêu cầu hệ thống

- macOS 13.0 (Ventura), macOS 14.6+ (Sonoma), macOS 15+ (Sequoia) trở lên
- Hỗ trợ gốc trên cả chip Apple Silicon (`arm64`) và chip Intel (`x86_64`, ví dụ MacBook Pro 2020)

### Hướng dẫn cài đặt

#### Tải bản đóng gói sẵn
1. Tải bản phát hành mới nhất `VietFlow-v1.0.0.zip` tại mục [Releases](https://github.com/nhanqv-ai/VietFlow/releases).
2. Giải nén và kéo file `VietFlow.app` vào thư mục `/Applications` (Ứng dụng).
3. Mở `VietFlow.app`. Biểu tượng chữ `V` trên khung vuông sẽ xuất hiện trên thanh menu macOS.

> [!NOTE]
> **Mở ứng dụng lần đầu (macOS Gatekeeper)**:
> Do VietFlow là phần mềm mã nguồn mở độc lập (chưa đăng ký chứng chỉ Apple Developer có phí), macOS có thể hiển thị thông báo bảo vệ (*"VietFlow" Not Opened*). Bạn có thể mở ứng dụng dễ dàng bằng một trong các cách:
> - **Dùng Terminal (Nhanh nhất)**: Chạy lệnh `xattr -cr /Applications/VietFlow.app` (hoặc đường dẫn file vừa giải nén).
> - **Dùng Cài đặt hệ thống**: Vào **System Settings** $\rightarrow$ **Privacy & Security** $\rightarrow$ cuộn xuống mục **Security** $\rightarrow$ chọn **Open Anyway** (Vẫn mở).
> - **Dùng chuột phải**: Nhấp chuột phải (hoặc giữ phím `Control` + click) vào `VietFlow.app` $\rightarrow$ chọn **Open** (Mở) $\rightarrow$ chọn **Open**.

> [!TIP]
> **Cấp quyền Trợ năng (`CGEventTap` & Làm mới cache TCC)**:
> VietFlow xử lý và chèn ký tự tiếng Việt ở tầng sự kiện hệ thống nên cần quyền Trợ năng (Accessibility) của macOS.
> - **Cấp quyền nhanh**: Vào VietFlow **Cài đặt** $\rightarrow$ tab **Bàn phím** $\rightarrow$ bấm nút **Cấp quyền Trợ năng**.
> - **Xử lý kẹt cache trên macOS Sonoma / Ventura / Sequoia**: Nếu trước đó bạn đã cài phiên bản cũ và Cài đặt hệ thống lưu cache TCC cũ, hãy bấm nút **Cấp quyền Trợ năng** trong VietFlow (ứng dụng sẽ tự động dọn sạch cache kẹt), hoặc vào **System Settings** $\rightarrow$ **Privacy & Security** $\rightarrow$ **Accessibility**, chọn `VietFlow`, nhấn nút dấu trừ (`-`) để xóa mục cũ rồi bật cấp quyền lại.
> - **Lệnh Terminal tiện lợi**: Bạn cũng có thể chạy lệnh `tccutil reset Accessibility com.nhanqv.VietFlow` để dọn sạch cache kẹt ngay lập tức.

#### Biên dịch từ mã nguồn
```bash
git clone https://github.com/nhanqv-ai/VietFlow.git
cd VietFlow
make app
make install
open /Applications/VietFlow.app
```

### Lệnh phát triển & Kiểm thử (1.317/1.317 Tests Pass)

```bash
# Chạy toàn bộ 15 bộ kiểm thử tự động (1.317 test cases, pass 100%)
make test

# Đóng gói bản dựng Universal 2 (build/VietFlow.app)
make app

# Đóng gói file nén zip phân phối Universal 2 (build/VietFlow-v1.0.0.zip)
make package

# Cài đặt trực tiếp vào thư mục /Applications
make install

# Dọn dẹp thư mục build
make clean
```

```text
================================================================================
 VietFlow Automated Test Suite Runner
================================================================================
 Running Suite: BasicTelexTests (171 tests)                  -> 171 passed, 0 failed
 Running Suite: SimpleTelexTests (84 tests)                  -> 84 passed,  0 failed
 Running Suite: VNITests (129 tests)                         -> 129 passed, 0 failed
 Running Suite: TonePlacementTests (86 tests)                -> 86 passed,  0 failed
 Running Suite: DiacriticUndoTests (80 tests)                -> 80 passed,  0 failed
 Running Suite: EnglishRestoreTests (80 tests)               -> 80 passed,  0 failed
 Running Suite: RapidTypingTests (70 tests)                  -> 70 passed,  0 failed
 Running Suite: MinimalDiffTests (60 tests)                  -> 60 passed,  0 failed
 Running Suite: TerminalCompatibilityTests (80 tests)        -> 80 passed,  0 failed
 Running Suite: HotkeyStateMachineTests (26 tests)           -> 26 passed,  0 failed
 Running Suite: SettingsPersistenceTests (24 tests)          -> 24 passed,  0 failed
 Running Suite: ModeToggleBufferResetTests (12 tests)        -> 12 passed,  0 failed
 Running Suite: SettingsLayoutTests (10 tests)               -> 10 passed,  0 failed
 Running Suite: RealWorldTypingAndBackspaceTests (385 tests) -> 385 passed, 0 failed
 Running Suite: InputSourceSynchronizationTests (20 tests)   -> 20 passed,  0 failed
================================================================================
 Total Suites: 15 | Total Test Cases: 1317 | Passed: 1317 (100%) | Failed: 0
================================================================================
```

### Giấy phép (License)

Dự án được phân phối dưới giấy phép [MIT License](LICENSE).
