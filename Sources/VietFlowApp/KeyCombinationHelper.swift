//
//  KeyCombinationHelper.swift
//  VietFlowApp
//
//  Carbon key mapping, modifier formatting, and shortcut validation helpers.
//  Adapted from SuperClip reference implementation.
//  Strictly Apple SF Symbols & standard typography with 0 emojis.
//

import AppKit
import Carbon

/// Model representing a selectable Carbon keyboard key.
public struct CarbonKeyItem: Identifiable, Hashable, Sendable {
    public let id: UInt32
    public let code: UInt32
    public let name: String

    public init(code: UInt32, name: String) {
        self.id = code
        self.code = code
        self.name = name
    }
}

/// Helper utilities for formatting and validating global hotkey combinations.
public struct KeyCombinationHelper {
    public static let standardKeys: [CarbonKeyItem] = [
        CarbonKeyItem(code: 0, name: "A"),
        CarbonKeyItem(code: 11, name: "B"),
        CarbonKeyItem(code: 8, name: "C"),
        CarbonKeyItem(code: 2, name: "D"),
        CarbonKeyItem(code: 14, name: "E"),
        CarbonKeyItem(code: 3, name: "F"),
        CarbonKeyItem(code: 5, name: "G"),
        CarbonKeyItem(code: 4, name: "H"),
        CarbonKeyItem(code: 34, name: "I"),
        CarbonKeyItem(code: 38, name: "J"),
        CarbonKeyItem(code: 40, name: "K"),
        CarbonKeyItem(code: 37, name: "L"),
        CarbonKeyItem(code: 46, name: "M"),
        CarbonKeyItem(code: 45, name: "N"),
        CarbonKeyItem(code: 31, name: "O"),
        CarbonKeyItem(code: 35, name: "P"),
        CarbonKeyItem(code: 12, name: "Q"),
        CarbonKeyItem(code: 15, name: "R"),
        CarbonKeyItem(code: 1, name: "S"),
        CarbonKeyItem(code: 17, name: "T"),
        CarbonKeyItem(code: 32, name: "U"),
        CarbonKeyItem(code: 9, name: "V"),
        CarbonKeyItem(code: 13, name: "W"),
        CarbonKeyItem(code: 7, name: "X"),
        CarbonKeyItem(code: 16, name: "Y"),
        CarbonKeyItem(code: 6, name: "Z"),
        CarbonKeyItem(code: 29, name: "0"),
        CarbonKeyItem(code: 18, name: "1"),
        CarbonKeyItem(code: 19, name: "2"),
        CarbonKeyItem(code: 20, name: "3"),
        CarbonKeyItem(code: 21, name: "4"),
        CarbonKeyItem(code: 23, name: "5"),
        CarbonKeyItem(code: 22, name: "6"),
        CarbonKeyItem(code: 26, name: "7"),
        CarbonKeyItem(code: 28, name: "8"),
        CarbonKeyItem(code: 25, name: "9"),
        CarbonKeyItem(code: 49, name: "Space"),
        CarbonKeyItem(code: 36, name: "Return"),
        CarbonKeyItem(code: 48, name: "Tab"),
        CarbonKeyItem(code: 53, name: "Escape"),
        CarbonKeyItem(code: 50, name: "`")
    ]

    public static func modifierDescription(for modifiers: UInt32) -> String {
        var parts: [String] = []
        if (modifiers & UInt32(controlKey)) != 0 { parts.append("Control") }
        if (modifiers & UInt32(optionKey)) != 0 { parts.append("Option") }
        if (modifiers & UInt32(shiftKey)) != 0 { parts.append("Shift") }
        if (modifiers & UInt32(cmdKey)) != 0 { parts.append("Command") }
        return parts.joined(separator: " + ")
    }

    public static func modifierSymbols(for modifiers: UInt32) -> String {
        var syms = ""
        if (modifiers & UInt32(controlKey)) != 0 { syms += "⌃" }
        if (modifiers & UInt32(optionKey)) != 0 { syms += "⌥" }
        if (modifiers & UInt32(shiftKey)) != 0 { syms += "⇧" }
        if (modifiers & UInt32(cmdKey)) != 0 { syms += "⌘" }
        return syms
    }

    public static func keyName(for code: UInt32) -> String {
        if let match = standardKeys.first(where: { $0.code == code }) {
            return match.name
        }
        return "Key \(code)"
    }

    public static func formattedShortcut(keyCode: UInt32, modifiers: UInt32) -> String {
        let modStr = modifierDescription(for: modifiers)
        let key = keyName(for: keyCode)
        if modStr.isEmpty {
            return key
        }
        return "\(modStr) + \(key)"
    }

    public static func formattedSymbolShortcut(keyCode: UInt32, modifiers: UInt32) -> String {
        let syms = modifierSymbols(for: modifiers)
        let key = keyName(for: keyCode)
        if syms.isEmpty {
            return key
        }
        return "\(syms) \(key)"
    }

    public static func isValidHotKey(modifiers: UInt32) -> Bool {
        let meaningful = modifiers & (UInt32(cmdKey) | UInt32(optionKey) | UInt32(controlKey))
        return meaningful != 0
    }
}
