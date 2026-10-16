//
//  main.swift
//  VietFlowCLI
//
//  Interactive Real-Time Terminal Typing Tester for VietFlow.
//  Runs directly inside your Terminal/iTerm2 in raw mode.
//

import Foundation
import Darwin
import VietFlowEngine

// Terminal Raw Mode Controller
struct RawTerminal {
    private var originalTermios = termios()
    
    mutating func enable() {
        tcgetattr(STDIN_FILENO, &originalTermios)
        var raw = originalTermios
        raw.c_lflag &= ~tcflag_t(ECHO | ICANON | ISIG)
        raw.c_cc.16 = 1 // VMIN = 1
        raw.c_cc.17 = 0 // VTIME = 0
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
    }
    
    func disable() {
        var term = originalTermios
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &term)
    }
}

func printHelp() {
    print("""
    ======================================================================
     VietFlow — Terminal Real-Time Interactive Demo
    ======================================================================
     Kiểu gõ hiện tại: Telex (Modern Tone, English Auto-Restore, LCP Diff)
     
     Thử gõ các câu lệnh và từ vựng tiếng Việt trong Terminal:
       - tieengs vieejt         -> tiếng việt
       - dduwowjc khoong        -> được không
       - hoaf / hoas            -> hòa / hóa
       - git commit -m "suwra"  -> git commit -m "sửa"
       - post, code, view       -> giữ nguyên từ tiếng Anh không biến dạng
       - Thử dùng phím Backspace xóa ngược giữa từ
       
     Phím chức năng:
       - [Tab]: Đổi kiểu gõ (Telex <-> VNI)
       - [Ctrl + C] hoặc [Esc]: Thoát khỏi màn hình test
    ======================================================================
    Gõ vào đây > \u{1B}[s
    """, terminator: "")
    fflush(stdout)
}

var term = RawTerminal()
term.enable()

defer {
    term.disable()
    print("\n\nĐã thoát VietFlow Terminal Demo. Chúc bạn gõ phím vui vẻ!\n")
}

printHelp()

let engine = BambooEngine(adaptiveLearner: .shared)
var currentMethod: InputMethod = .telex

var buffer = [UInt8](repeating: 0, count: 16)
var running = true

while running {
    let bytesRead = read(STDIN_FILENO, &buffer, buffer.count)
    guard bytesRead > 0 else { continue }
    
    // Check for Ctrl+C (0x03) or Esc (0x1B)
    if buffer[0] == 3 || buffer[0] == 27 {
        running = false
        break
    }
    
    // Check for Tab (0x09) - Toggle Telex / VNI
    if buffer[0] == 9 {
        currentMethod = (currentMethod == .telex) ? .vni : .telex
        engine.config.inputMethod = currentMethod
        engine.reset()
        print("\n\u{1B}[33m[Đã chuyển sang kiểu gõ: \(currentMethod.rawValue.uppercased())]\u{1B}[0m")
        print("Gõ vào đây > ", terminator: "")
        fflush(stdout)
        continue
    }
    
    // Check for Backspace (0x7F or 0x08)
    if buffer[0] == 127 || buffer[0] == 8 {
        _ = engine.handleBackspace()
        // Send terminal backspace sequence: move back, erase char, move back
        print("\u{08} \u{08}", terminator: "")
        fflush(stdout)
        continue
    }
    
    // Check for Return / Enter (0x0A or 0x0D)
    if buffer[0] == 10 || buffer[0] == 13 {
        engine.reset()
        print("\n\rGõ vào đây > ", terminator: "")
        fflush(stdout)
        continue
    }
    
    // Parse character
    guard let str = String(bytes: buffer[0..<bytesRead], encoding: .utf8),
          let char = str.first else {
        continue
    }
    
    if let delta = engine.processKey(char) {
        // Apply backspaces
        for _ in 0..<delta.backspaces {
            print("\u{08} \u{08}", terminator: "")
        }
        // Apply Unicode insert text
        print(delta.insertText, terminator: "")
        fflush(stdout)
    } else {
        // Passthrough character
        print(str, terminator: "")
        fflush(stdout)
    }
}
