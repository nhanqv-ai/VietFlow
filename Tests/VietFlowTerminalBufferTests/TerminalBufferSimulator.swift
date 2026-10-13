//
//  TerminalBufferSimulator.swift
//  VietFlowTerminalBufferTests
//
//  PTY Raw-Mode Terminal Buffer Simulator
//  Accurately simulates terminal line editing, backspace deletion, and Unicode insertion.
//  Enforces zero surplus and zero missing characters invariant.
//

import Foundation
import VietFlowEngine

public struct TerminalStepEvent: Equatable {
    public let keyTyped: Character
    public let delta: TextDelta?
    public let bufferBefore: String
    public let bufferAfter: String
    public let backspacesEmitted: Int
    public let textInserted: String
    public let isSuccess: Bool
    
    public init(
        keyTyped: Character,
        delta: TextDelta?,
        bufferBefore: String,
        bufferAfter: String,
        backspacesEmitted: Int,
        textInserted: String,
        isSuccess: Bool
    ) {
        self.keyTyped = keyTyped
        self.delta = delta
        self.bufferBefore = bufferBefore
        self.bufferAfter = bufferAfter
        self.backspacesEmitted = backspacesEmitted
        self.textInserted = textInserted
        self.isSuccess = isSuccess
    }
}

public final class TerminalBufferSimulator {
    public private(set) var currentBuffer: String
    public private(set) var history: [TerminalStepEvent]
    
    public init(initialBuffer: String = "") {
        self.currentBuffer = initialBuffer
        self.history = []
    }
    
    public func reset(to buffer: String = "") {
        self.currentBuffer = buffer
        self.history = []
    }
    
    /// Simulates typing a single character into raw mode terminal
    @discardableResult
    public func typeKey(_ char: Character, engine: VietnameseEngineProtocol) -> TerminalStepEvent {
        let before = currentBuffer
        let delta = engine.processKey(char)
        
        var backspacesEmitted = 0
        var textInserted = ""
        var success = true
        
        if let d = delta {
            backspacesEmitted = d.backspaces
            textInserted = d.insertText
            
            // Check buffer underrun invariant:
            // Terminal raw mode cannot backspace past the current buffer length
            if d.backspaces > currentBuffer.count {
                success = false
                currentBuffer = ""
            } else {
                currentBuffer = String(currentBuffer.dropLast(d.backspaces))
            }
            currentBuffer.append(d.insertText)
        } else {
            // Trigger key not swallowed/modified: passed through to PTY directly
            textInserted = String(char)
            currentBuffer.append(char)
        }
        
        // NFC Invariant: The resulting buffer must be strictly NFC
        currentBuffer = currentBuffer.precomposedStringWithCanonicalMapping
        
        let event = TerminalStepEvent(
            keyTyped: char,
            delta: delta,
            bufferBefore: before,
            bufferAfter: currentBuffer,
            backspacesEmitted: backspacesEmitted,
            textInserted: textInserted,
            isSuccess: success
        )
        history.append(event)
        return event
    }
    
    /// Simulates pressing physical Backspace key in terminal
    @discardableResult
    public func pressBackspace(engine: VietnameseEngineProtocol) -> TerminalStepEvent {
        let before = currentBuffer
        _ = engine.handleBackspace()
        var backspacesEmitted = 0
        if !currentBuffer.isEmpty {
            currentBuffer.removeLast()
            backspacesEmitted = 1
        }
        let event = TerminalStepEvent(
            keyTyped: "\u{7F}", // ASCII DEL
            delta: nil,
            bufferBefore: before,
            bufferAfter: currentBuffer,
            backspacesEmitted: backspacesEmitted,
            textInserted: "",
            isSuccess: true
        )
        history.append(event)
        return event
    }
    
    /// Simulates typing an entire string sequence into the terminal
    public func typeString(_ string: String, engine: VietnameseEngineProtocol) -> [TerminalStepEvent] {
        var events: [TerminalStepEvent] = []
        for char in string {
            if char == " " || char == "\n" {
                let before = currentBuffer
                engine.reset()
                currentBuffer.append(char)
                let event = TerminalStepEvent(
                    keyTyped: char,
                    delta: nil,
                    bufferBefore: before,
                    bufferAfter: currentBuffer,
                    backspacesEmitted: 0,
                    textInserted: String(char),
                    isSuccess: true
                )
                history.append(event)
                events.append(event)
            } else {
                events.append(typeKey(char, engine: engine))
            }
        }
        return events
    }
}
