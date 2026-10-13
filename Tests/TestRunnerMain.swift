//
//  TestRunnerMain.swift
//  VietFlowTests
//
//  Standalone CLI Test Runner Entry Point for VietFlow Test Suite.
//  Executes all 500+ test cases across all test suites and reports summary.
//

import Foundation
import VietFlowEngine
import VietFlowEngineTests
import VietFlowTerminalBufferTests

@main
struct TestRunnerMain {
    static func main() {
        let registry = TestRegistry.shared
        
        // Register all test suites
        registry.register(name: "BasicTelexTests") { BasicTelexTests() }
        registry.register(name: "SimpleTelexTests") { SimpleTelexTests() }
        registry.register(name: "VNITests") { VNITests() }
        registry.register(name: "TonePlacementTests") { TonePlacementTests() }
        registry.register(name: "DiacriticUndoTests") { DiacriticUndoTests() }
        registry.register(name: "EnglishRestoreTests") { EnglishRestoreTests() }
        registry.register(name: "RapidTypingTests") { RapidTypingTests() }
        registry.register(name: "MinimalDiffTests") { MinimalDiffTests() }
        registry.register(name: "TerminalCompatibilityTests") { TerminalCompatibilityTests() }
        
        let args = CommandLine.arguments
        let verbose = args.contains("--verbose") || args.contains("-v")
        
        let success = registry.runAll(verbose: verbose)
        exit(success ? 0 : 1)
    }
}
