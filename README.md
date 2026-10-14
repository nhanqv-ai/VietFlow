<p align="center">
  <img src="Assets/AppIcon.png" alt="VietFlow App Icon" width="128" height="128" />
</p>

<h1 align="center">VietFlow</h1>

<p align="center">
  <strong>Ultra-Lightweight, Zero-Latency Native macOS Vietnamese Input Method</strong><br>
  <strong>Purpose-Built for Seamless Vietnamese &harr; Japanese &harr; English Workflows</strong><br>
  <em>Swift &bull; SwiftUI &bull; Bamboo Phonotactics Engine &bull; Minimal Diff (LCP) &bull; Universal 2 &bull; Japanese IME Coexistence</em>
</p>

<p align="center">
  <a href="#english">English</a> &bull; <a href="#tiếng-việt">Tiếng Việt</a>
</p>

<p align="center">
  <a href="https://github.com/nhanqv-ai/VietFlow/releases"><img src="https://img.shields.io/github/v/release/nhanqv-ai/VietFlow?style=flat-square&color=blue" alt="Release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green.svg?style=flat-square" alt="License"></a>
  <img src="https://img.shields.io/badge/platform-macOS%2013%2B%20%7C%20Sonoma%2014.6%2B%20%7C%20Sequoia%2015%2B-lightgrey.svg?style=flat-square" alt="Platform">
  <img src="https://img.shields.io/badge/architecture-Universal%202%20(arm64%20%2B%20x86__64)-blue.svg?style=flat-square" alt="Architecture">
  <img src="https://img.shields.io/badge/tests-1%2C470%2B%20passed%20(100%25)-success.svg?style=flat-square" alt="Tests">
  <img src="https://img.shields.io/badge/Swift-6.0-orange.svg?style=flat-square" alt="Swift">
</p>

---

<a name="english"></a>
## English

**VietFlow** is an ultra-lightweight, zero-latency native macOS Vietnamese input method built from the ground up with Swift and SwiftUI. Designed specifically for **bilingual and trilingual users who constantly switch between Vietnamese, Japanese (`あ Japanese`), and English**, VietFlow combines a formal **Bamboo CVC Phonotactics Engine** with a low-level **`CGEventTap`** interceptor, **Longest Common Prefix (LCP) Minimal Diff** injection, and **real-time Carbon Input Source synchronization**. It eliminates the underlined-preedit glitches, swallowed keystrokes, duplicated characters (`tiếeng`), terminal cursor jumps, and Japanese Romaji conflicts found in Apple's built-in IME and legacy input tools.

### Why VietFlow is Ideal for Vietnamese &harr; Japanese Users

If you work in a **Vietnamese &ndash; Japanese &ndash; English** environment (Software Engineers, BrSE, Translators, Communicators, JLPT Learners), traditional Vietnamese input methods clash with macOS's Japanese IME (`Kotoeri` / Google Japanese Input) because Telex keys (`s, f, r, x, j, w, aa, ee, oo, dd`) corrupt Romaji input (`watashi` $\rightarrow$ `ưatáhi`, `nihongo` $\rightarrow$ `nihongô`, `tsu` $\rightarrow$ `tú`). VietFlow solves this completely:

1. **One-Key Bidirectional Ping-Pong (`あ Japanese` $\leftrightarrow$ `ABC [V]`)**:
   - While typing in **Japanese (`あ`)**, press VietFlow's shortcut (default `Control + Shift` or click the Menu Bar icon) $\rightarrow$ VietFlow **remembers your Japanese input source**, switches macOS to `ABC`, and activates **Vietnamese `[V]`** in one step.
   - Press `Control + Shift` **again** to turn off Vietnamese $\rightarrow$ VietFlow **automatically restores macOS back to `あ Japanese`** and suspends itself to **`[E]`**! You can alternate between Japanese and Vietnamese all day using a single shortcut.
2. **Auto-Suspend & Auto-Restore on macOS Input Source Switch**:
   - Switching macOS from `ABC` to `あ Japanese` (Hiragana / Katakana) flushes the active buffer and automatically suspends VietFlow to **`[E]`** so Romaji/Kana/Kanji typing works with zero interference.
   - Switching macOS back to `ABC` (or Kotoeri Alphanumeric `A`) automatically restores your previous **`[V]`** / **`[E]`** mode.
3. **Inline Japanese Romaji, English & IT Recognition While Staying in `[V]` Mode**:
   - Even without leaving `[V]` mode, you can type Japanese Romaji words and proper nouns inline (`osaka`, `tokyo`, `kyoto`, `shinjuku`, `shibuya`, `asakusa`, `okinawa`, `hiroshima`, `sushi`, `sashimi`, `wasabi`, `tempura`, `ramen`, `matcha`, `wagyu`, `sensei`, `senpai`, `arigatou`, `konnichiwa`, `sumimasen`, `kawaii`, `oishii`, `tanoshii`, `muzukashii`, `nihongo`, `kanji`, `hiragana`, `katakana`, `romaji`, `emoji`, `tsunami`, `sakura`...), `camelCase` identifiers (`macOS`, `iOS`, `useState`, `VietFlow`), and Japanese/global domains (`nhk.or.jp`, `yahoo.co.jp`, `example.us`, `shopee.tw`) without accidental Vietnamese tones!

### Highlights

- **Bamboo CVC Phonotactics Engine & Free-Order Typing**:
  - Full support for **Telex**, **Simple Telex**, and **VNI**, plus both **Modern (`hòa, thúy`)** and **Traditional (`hoà, thuý`)** tone placement rules.
  - Natural **free-order diacritic and tone placement** at the start, middle, or end of a syllable (e.g., `moiws` / `mowis` / `mowsi` $\rightarrow$ `mới`, `swar` / `suwar` / `suawr` $\rightarrow$ `sửa`, `thuowr` $\rightarrow$ `thuở`, `gixw` $\rightarrow$ `giữ`, `howacj` / `hoawcj` / `hoacwj` $\rightarrow$ `hoặc`, `dods` $\rightarrow$ `đó`).
- **Seamless Multi-Backspace & Cross-Space Word Editing**:
  - Synchronizes canonical keystroke state with on-screen NFC characters (`1 Backspace = 1 displayed character`), allowing effortless mid-word corrections and backspacing across spaces (`spaceHistory` up to 16 words) without ghost characters or buffer desynchronization.
- **Smart English, CamelCase, Domain & Japanese Romaji Auto-Restoration**:
  - Automatically detects and preserves English vocabulary (`user`, `case`, `base`, `house`, `focus`, `status`, `next`, `text`, `year`, `hear`, `near`, `our`, `tour`, `new`, `down`, `server`, `service`, `version`, `container`, `router`, etc.), `camelCase`/`PascalCase` tokens (`macOS`, `iOS`, `useState`, `SwiftUI`), dotted domains/paths (`nhk.or.jp`, `readme.md`, `index.ts`), and Japanese Romaji words while strictly preserving valid Vietnamese short words (`cả`, `bả`, `tả`, `mô tả`, `sẽ`, `mã`, `nơ`, `hơ`, `hải`).
- **Minimal Diff ($LCP$) Terminal Compatibility**:
  - Computes the Longest Common Prefix between the current screen buffer and transformed syllable, emitting the minimum possible virtual Backspaces (e.g., transforming `tiên` $\rightarrow$ `tiến` emits only 2 Backspaces instead of 4). Works flawlessly in **Terminal.app, iTerm2, Warp, Alacritty, Kitty, tmux, Vim, and zsh**.
- **Per-App Input Mode & Application Blacklist**:
  - Remembers `[V]` or `[E]` independently for each application (`perAppInputMode`), and completely bypasses blacklisted apps or games (`blacklistedBundleIdentifiers`).
  - Automatically bypasses macOS **Secure Event Input** fields (password prompts, Touch ID, `sudo`, 1Password).
- **Universal 2 Architecture & Zero Emojis Design**:
  - Compiled as a native Mach-O fat binary supporting both Apple Silicon (`arm64`: M1/M2/M3/M4) and Intel (`x86_64`: MacBook Pro 2020 and earlier) on macOS 13.0 (Ventura), macOS 14.6+ (Sonoma), and macOS 15+ (Sequoia).
  - Native login item management via `SMAppService`, crisp CoreGraphics vector Menu Bar keycap glyphs (`V` / `E`), and a 4-tab SwiftUI Settings window adhering strictly to a 0-emoji professional design.

### Keyboard Shortcuts & Interactions

| Shortcut / Action | Description | Scope |
| :--- | :--- | :--- |
| `Control + Shift` (Default) | Toggle `[V]` &harr; `[E]` on `ABC` — **or ping-pong 2-way between `あ Japanese` &harr; `ABC [V]`** | Global |
| `Command + Shift` / `Option + Shift` / `Option` | Alternative modifier-chord shortcuts selectable in Settings | Global |
| `Custom Key Combo` (e.g., `⌃Space`, `⌥Z`) | User-recordable custom global hotkey via Carbon `RegisterEventHotKey` | Global |
| `Left-Click Menu Bar Icon` | Instantly toggle `[V]` / `[E]` (or switch `あ Japanese` &harr; `ABC [V]`) | Menu Bar |
| `Right-Click Menu Bar Icon` | Open quick context menu (Status, Input Method, Tone Style, Settings, Quit) | Menu Bar |
| `Double-Press Diacritic / Tone Key` | Undo transformation and restore literal ASCII key (`aa`, `ww`, `ss`, `dd`, `carr`, `sexx`) | While Typing |
| `z` (Telex) / `0` (VNI) | Explicitly strip tone mark from the current syllable | While Typing |

### System Requirements

- macOS 13.0 (Ventura), macOS 14.6+ (Sonoma), macOS 15+ (Sequoia), or newer
- Apple Silicon Mac (`arm64`) or Intel Mac (`x86_64`, e.g. MacBook Pro 2020)

### Installation

#### Pre-built Release
1. Download the latest `VietFlow-v1.1.0.zip` from [Releases](https://github.com/nhanqv-ai/VietFlow/releases).
2. Unzip and drag `VietFlow.app` into your `/Applications` folder.
3. Open `VietFlow.app`. The `V` / `E` keycap icon will appear on your macOS menu bar.

#### First-Time Launch (macOS Gatekeeper)

Because VietFlow is an open-source application not notarized with an Apple Developer account, macOS Gatekeeper may show a warning on first launch (*"VietFlow" Not Opened*).

You can easily allow it by running this one-line command in Terminal:

```bash
xattr -cr /Applications/VietFlow.app
```

*(Or go to System Settings -> Privacy & Security -> click **Open Anyway**, or right-click VietFlow.app and choose **Open**).*

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
# Compile and execute all 16 automated test suites (1,470+ tests, 100% pass)
make test

# Build Universal 2 VietFlow.app bundle (arm64 + x86_64)
make app

# Package distributable Universal 2 zip archive (build/VietFlow-v1.1.0.zip)
make package

# Install VietFlow.app into /Applications
make install

# Clean build artifacts
make clean
```

---

<a name="tiếng-việt"></a>
## Tiếng Việt

**VietFlow** là bộ gõ tiếng Việt gốc (native), siêu nhẹ và độ trễ bằng không dành cho macOS, được xây dựng hoàn toàn bằng **Swift** và **SwiftUI**. Đặc biệt, VietFlow được **thiết kế chuyên biệt cho những người thường xuyên phải gõ song song giữa Tiếng Việt, Tiếng Nhật (`あ Japanese`) và Tiếng Anh** (kỹ sư phần mềm, BrSE, biên phiên dịch, người học tiếng Nhật và làm việc tại Nhật). Kết hợp lõi thuật toán ngữ âm **Bamboo CVC Engine** với kiến trúc bắt phím mức thấp **`CGEventTap`**, thuật toán chèn ký tự tối thiểu **Minimal Diff ($LCP$)** và bộ đồng bộ **Carbon Input Source thời gian thực**, VietFlow giải quyết triệt để lỗi gạch chân (`marked text`), nuốt chữ, nhân đôi ký tự (`tiếeng`), nhảy con trỏ trong Terminal cũng như xung đột khi gõ Romaji tiếng Nhật.

### Thiết Kế Chuyên Biệt Cho Người Hay Gõ Tiếng Việt &harr; Tiếng Nhật Song Song

Khi sử dụng các bộ gõ tiếng Việt thông thường trên macOS song song với bộ gõ tiếng Nhật (`あ Japanese`), người dùng luôn gặp cảnh quên tắt bộ gõ Việt khiến các âm Romaji bị biến dạng thành dấu tiếng Việt (`watashi` $\rightarrow$ `ưatáhi`, `nihongo` $\rightarrow$ `nihongô`, `shinjuku` $\rightarrow$ `shinụku`, `tsu` $\rightarrow$ `tú`), hoặc phải bấm nhiều tổ hợp phím khác nhau để chuyển qua lại giữa 2 bộ gõ. **VietFlow** giải quyết triệt để bài toán này:

1. **Chuyển Đổi 2 Chiều Có Ghi Nhớ Giữa Tiếng Nhật &harr; Tiếng Việt Chỉ Bằng 1 Phím Tắt (`あ Japanese` $\leftrightarrow$ `ABC [V]`)**:
   - Khi đang ở bộ gõ **Tiếng Nhật (`あ Japanese`)**, bạn chỉ cần nhấn phím tắt của VietFlow (mặc định `Control + Shift` hoặc click icon trên Menu Bar) $\rightarrow$ VietFlow sẽ **ghi nhớ bộ gõ Tiếng Nhật**, tự động chuyển macOS sang bàn phím `ABC` và bật chế độ **Tiếng Việt `[V]`** ngay lập tức.
   - Khi gõ xong tiếng Việt và nhấn `Control + Shift` **thêm lần nữa** để tắt Tiếng Việt $\rightarrow$ VietFlow tự động **khôi phục macOS về lại đúng bộ gõ Tiếng Nhật (`あ Japanese`)** vừa dùng trước đó và chuyển về chế độ nhường phím **`[E]`**!
   - Nhờ vậy, chỉ với **duy nhất 1 phím tắt**, bạn có thể bật/tắt luân phiên qua lại giữa **Tiếng Nhật &harr; Tiếng Việt** suốt cả ngày làm việc mà không cần chạm vào menu ngôn ngữ của macOS.
2. **Tự Động Nhường Phím & Tự Động Khôi Phục Khi Đổi Input Source Của macOS**:
   - Khi chuyển macOS từ `ABC` sang `あ Japanese` (Hiragana / Katakana), VietFlow tự động xóa bộ đệm và tạm ngưng sang **`[E]`** để bạn gõ Romaji/Hiragana/Kanji mượt mà tuyệt đối.
   - Khi chuyển macOS về lại `ABC` (hoặc chế độ gõ chữ Latin `A` của bộ gõ Nhật), VietFlow tự động khôi phục lại đúng trạng thái **`[V]`** / **`[E]`** trước đó.
3. **Gõ Trực Tiếp Từ Vựng Romaji Tiếng Nhật, Tiếng Anh & Thuật Ngữ IT Ngay Trong Chế Độ `[V]`**:
   - Ngay cả khi đang để chế độ Tiếng Việt **`[V]`**, bạn vẫn có thể gõ thẳng các từ vựng, địa danh, ẩm thực, câu giao tiếp tiếng Nhật bằng Romaji (`osaka`, `tokyo`, `kyoto`, `shinjuku`, `shibuya`, `asakusa`, `okinawa`, `hiroshima`, `sushi`, `sashimi`, `wasabi`, `tempura`, `ramen`, `matcha`, `wagyu`, `sensei`, `senpai`, `arigatou`, `konnichiwa`, `sumimasen`, `kawaii`, `oishii`, `tanoshii`, `muzukashii`, `nihongo`, `kanji`, `hiragana`, `katakana`, `romaji`, `emoji`, `tsunami`, `sakura`...), các từ định danh `camelCase` (`macOS`, `iOS`, `useState`, `VietFlow`), và tên miền Nhật/quốc tế (`nhk.or.jp`, `yahoo.co.jp`, `example.us`, `shopee.tw`) mà không sợ bị biến dạng thành dấu tiếng Việt!

### Tính năng nổi bật

- **Lõi Bamboo Engine & Gõ Dấu Tự Do (Free-Order Typing)**:
  - Hỗ trợ đầy đủ 3 kiểu gõ: **Telex**, **Simple Telex**, **VNI** cùng 2 quy tắc đặt dấu thanh **Dấu Mới (`hòa, thúy`)** và **Dấu Cũ (`hoà, thuý`)**.
  - Cho phép bỏ dấu thanh và dấu mũ/móc ở **bất kỳ vị trí nào** (đầu, giữa hoặc cuối âm tiết): `moiws` / `mowis` / `mowsi` $\rightarrow$ `mới`, `swar` / `suwar` / `suawr` $\rightarrow$ `sửa`, `thuowr` $\rightarrow$ `thuở`, `gixw` $\rightarrow$ `giữ`, `howacj` / `hoawcj` / `hoacwj` $\rightarrow$ `hoặc`, `dods` $\rightarrow$ `đó`.
- **Xóa Backspace Chính Xác & Sửa Lỗi Xuyên Khoảng Trắng**:
  - Đồng bộ 1-1 giữa ký tự Unicode NFC hiển thị trên màn hình và trạng thái phím nội bộ (`1 Backspace = xóa đúng 1 chữ trên màn hình`), hỗ trợ nhấn Backspace liên hoàn giữa từ hoặc lùi qua nhiều khoảng trắng (`spaceHistory` lưu tới 16 từ) để sửa lại từ trước đó mà không bao giờ bị văng ký tự rác.
- **Tự Động Khôi Phục Từ Tiếng Anh, `camelCase`, Tên Miền & Romaji Tiếng Nhật Thông Minh**:
  - Tự động nhận diện và giữ nguyên các từ tiếng Anh (`download`, `power`, `user`, `case`, `base`, `house`, `focus`, `status`, `next`, `text`, `year`, `hear`, `near`, `our`, `tour`, `new`, `down`, `server`, `service`, `version`, `container`, `router`...), biến code `camelCase`/`PascalCase` (`macOS`, `iOS`, `useState`, `SwiftUI`), tên miền/đường dẫn (`nhk.or.jp`, `readme.md`, `index.ts`) và từ vựng Romaji tiếng Nhật, đồng thời **bảo toàn tuyệt đối** các từ tiếng Việt ngắn trùng phím (`cả`, `bả`, `tả`, `mô tả`, `sẽ`, `mã`, `nơ`, `hơ`, `hải`).
- **Thuật Toán Khác Biệt Tối Thiểu (Minimal Diff - $LCP$) Cho Terminal**:
  - Tính toán tiền tố chung dài nhất (Longest Common Prefix) giữa chuỗi đang hiển thị và chuỗi mới để gửi số lượng phím Backspace ảo ít nhất (ví dụ chuyển `tiên` $\rightarrow$ `tiến` chỉ gửi 2 phím Backspace thay vì 4), giúp gõ tiếng Việt mượt mà tuyệt đối trên **Terminal.app, iTerm2, Warp, Alacritty, Kitty, tmux, Vim, zsh**.
- **Ghi Nhớ Theo Từng Ứng Dụng & Danh Sách Loại Trừ (Blacklist)**:
  - Tự động ghi nhớ chế độ `[V]` / `[E]` riêng cho từng ứng dụng (`perAppInputMode`) và tự động bỏ qua các ứng dụng/game nằm trong danh sách loại trừ (`blacklistedBundleIdentifiers`).
  - Tự động nhường phím an toàn tại các ô nhập mật khẩu bảo mật (**Secure Event Input** như `sudo`, Touch ID, 1Password).
- **Kiến Trúc Universal 2 & Thiết Kế Chuẩn Apple HIG (0 Emojis)**:
  - Biên dịch dưới dạng Mach-O fat binary hỗ trợ gốc cả chip Apple Silicon (`arm64`: M1/M2/M3/M4) và chip Intel (`x86_64`: MacBook Pro 2020) trên macOS 13.0 (Ventura), macOS 14.6+ (Sonoma) và macOS 15+ (Sequoia).
  - Biểu tượng Menu Bar dạng keycap vector sắc nét (`V` / `E`), hỗ trợ khởi động cùng hệ thống qua `SMAppService` và tuân thủ quy chuẩn **0 Emojis**.

### Bảng phím tắt thông dụng

| Phím tắt / Thao tác | Chức năng | Phạm vi |
| :--- | :--- | :--- |
| `Control + Shift` (Mặc định) | Chuyển đổi `[V]` &harr; `[E]` trên `ABC` — **hoặc bật/tắt luân phiên 2 chiều `あ Japanese` &harr; `ABC [V]`** | Toàn hệ thống |
| `Command + Shift` / `Option + Shift` / `Option` | Các tổ hợp phím bổ trợ thay thế chọn trong Cài đặt | Toàn hệ thống |
| `Tổ hợp phím tùy chỉnh` (VD: `⌃Space`, `⌥Z`) | Tự ghi nhận phím tắt bất kỳ qua Carbon `RegisterEventHotKey` | Toàn hệ thống |
| `Click chuột trái vào icon Menu Bar` | Chuyển đổi tức thì chế độ `[V]` / `[E]` (hoặc chuyển 2 chiều `あ Japanese` &harr; `ABC [V]`) | Thanh Menu |
| `Click chuột phải vào icon Menu Bar` | Mở menu xem trạng thái, chọn nhanh Kiểu gõ, Quy tắc dấu, Cài đặt, Thoát | Thanh Menu |
| `Gõ lặp 2 lần phím dấu` (`aa`, `ww`, `ss`, `dd`, `carr`, `sexx`) | Hoàn tác dấu vừa bỏ và trả về ký tự ASCII nguyên gốc | Khi đang gõ |
| `z` (Telex) / `0` (VNI) | Xóa dấu thanh của âm tiết hiện tại | Khi đang gõ |

### Yêu cầu hệ thống

- macOS 13.0 (Ventura), macOS 14.6+ (Sonoma), macOS 15+ (Sequoia) trở lên
- Hỗ trợ gốc trên cả chip Apple Silicon (`arm64`) và chip Intel (`x86_64`, ví dụ MacBook Pro 2020)

### Hướng dẫn cài đặt

#### Tải bản đóng gói sẵn
1. Tải bản phát hành mới nhất `VietFlow-v1.1.0.zip` tại mục [Releases](https://github.com/nhanqv-ai/VietFlow/releases).
2. Giải nén và kéo file `VietFlow.app` vào thư mục `/Applications` (Ứng dụng).
3. Mở `VietFlow.app`. Biểu tượng chữ `V` trên khung vuông sẽ xuất hiện trên thanh menu macOS.

#### Mở ứng dụng lần đầu (macOS Gatekeeper)

Do VietFlow là ứng dụng mã nguồn mở độc lập (chưa đăng ký chứng chỉ Apple Developer có phí), macOS Gatekeeper có thể hiển thị cảnh báo trong lần mở đầu tiên (*"VietFlow" Not Opened*).

Bạn có thể mở ứng dụng dễ dàng bằng cách chạy câu lệnh 1 dòng này trong Terminal:

```bash
xattr -cr /Applications/VietFlow.app
```

*(Hoặc vào System Settings -> Privacy & Security -> nhấn **Open Anyway**, hoặc click chuột phải vào VietFlow.app và chọn **Open**).*

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

### Lệnh phát triển & Kiểm thử (1.470+ Tests Pass 100%)

```bash
# Chạy toàn bộ 16 bộ kiểm thử tự động (1.470+ test cases, pass 100%)
make test

# Đóng gói bản dựng Universal 2 (build/VietFlow.app)
make app

# Đóng gói file nén zip phân phối Universal 2 (build/VietFlow-v1.1.0.zip)
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
 Running Suite: EnglishRestoreTests (108 tests)              -> 108 passed, 0 failed
 Running Suite: RapidTypingTests (70 tests)                  -> 70 passed,  0 failed
 Running Suite: MinimalDiffTests (60 tests)                  -> 60 passed,  0 failed
 Running Suite: TerminalCompatibilityTests (80 tests)        -> 80 passed,  0 failed
 Running Suite: HotkeyStateMachineTests (26 tests)           -> 26 passed,  0 failed
 Running Suite: InputSourceSynchronizationTests (26 tests)   -> 26 passed,  0 failed
 Running Suite: SettingsPersistenceTests (27 tests)          -> 27 passed,  0 failed
 Running Suite: ModeToggleBufferResetTests (12 tests)        -> 12 passed,  0 failed
 Running Suite: SettingsLayoutTests (10 tests)               -> 10 passed,  0 failed
 Running Suite: RealWorldTypingAndBackspaceTests (385 tests) -> 385 passed, 0 failed
 Running Suite: TrilingualUserExperienceTests (119 tests)    -> 119 passed, 0 failed
================================================================================
 Total Suites: 16 | Total Test Cases: 1473 | Passed: 1473 (100%) | Failed: 0
================================================================================
```

### Giấy phép (License)

Dự án được phân phối dưới giấy phép [MIT License](LICENSE).
