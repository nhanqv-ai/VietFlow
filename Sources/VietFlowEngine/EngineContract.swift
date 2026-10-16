//
//  EngineContract.swift
//  VietFlowEngine
//
//  Interface contract defining public types and protocols for VietFlowEngine.
//

import Foundation

public enum InputMethod: String, Codable, CaseIterable, Sendable {
    case telex
    case simpleTelex
    case vni
}

public enum TonePlacementStyle: String, Codable, CaseIterable, Sendable {
    case modern      // hòa, thúy
    case traditional // hoà, thuý
}

public struct EngineConfig: Codable, Equatable, Sendable {
    public var inputMethod: InputMethod
    public var tonePlacement: TonePlacementStyle
    public var autoCorrectEnglish: Bool
    public var freeTonePlacement: Bool
    public var escapeByDoubleKey: Bool

    public init(
        inputMethod: InputMethod = .telex,
        tonePlacement: TonePlacementStyle = .modern,
        autoCorrectEnglish: Bool = true,
        freeTonePlacement: Bool = true,
        escapeByDoubleKey: Bool = true
    ) {
        self.inputMethod = inputMethod
        self.tonePlacement = tonePlacement
        self.autoCorrectEnglish = autoCorrectEnglish
        self.freeTonePlacement = freeTonePlacement
        self.escapeByDoubleKey = escapeByDoubleKey
    }
}

public struct TextDelta: Equatable, Sendable {
    public let backspaces: Int
    public let insertText: String

    public init(backspaces: Int, insertText: String) {
        self.backspaces = backspaces
        self.insertText = insertText
    }
}

public protocol VietnameseEngineProtocol: AnyObject, Sendable {
    var config: EngineConfig { get set }
    var currentSyllable: String { get }
    func processKey(_ character: Character) -> TextDelta?
    func handleBackspace() -> Bool
    func handleBackspaceWithRevertDelta() -> TextDelta?
    func reset()
}

public extension VietnameseEngineProtocol {
    func handleBackspaceWithRevertDelta() -> TextDelta? {
        return nil
    }
}
