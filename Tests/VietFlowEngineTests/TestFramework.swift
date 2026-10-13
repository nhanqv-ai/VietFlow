//
//  TestFramework.swift
//  VietFlowEngineTests
//
//  Universal Test Framework providing XCTest-compatible API and standalone CLI test runner support.
//

import Foundation
import VietFlowEngine

#if canImport(XCTest)
import XCTest
#endif

// MARK: - Assertion Context & Counters

public final class TestExecutionState: @unchecked Sendable {
    public static let shared = TestExecutionState()
    
    public var currentTestName: String = ""
    public var currentSuiteName: String = ""
    public var currentTestFailed: Bool = false
    public var currentTestFailureMessages: [String] = []
    
    public var totalTests: Int = 0
    public var passedTests: Int = 0
    public var failedTests: Int = 0
    public var failedTestDetails: [(suite: String, test: String, message: String)] = []
    
    public func reset() {
        currentTestName = ""
        currentSuiteName = ""
        currentTestFailed = false
        currentTestFailureMessages = []
        totalTests = 0
        passedTests = 0
        failedTests = 0
        failedTestDetails = []
    }
}

// MARK: - Assertion Functions

public func XCTAssertEqual<T: Equatable>(
    _ expression1: @autoclosure () throws -> T,
    _ expression2: @autoclosure () throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) {
    do {
        let val1 = try expression1()
        let val2 = try expression2()
        if val1 != val2 {
            let customMsg = message()
            let msg = "Assertion Failure: '\(val1)' is not equal to '\(val2)'" + (customMsg.isEmpty ? "" : " - \(customMsg)")
            recordFailure(msg, file: file, line: line)
        }
    } catch {
        recordFailure("Assertion threw error: \(error)", file: file, line: line)
    }
}

public func XCTAssertNotEqual<T: Equatable>(
    _ expression1: @autoclosure () throws -> T,
    _ expression2: @autoclosure () throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) {
    do {
        let val1 = try expression1()
        let val2 = try expression2()
        if val1 == val2 {
            let customMsg = message()
            let msg = "Assertion Failure: '\(val1)' is equal to '\(val2)'" + (customMsg.isEmpty ? "" : " - \(customMsg)")
            recordFailure(msg, file: file, line: line)
        }
    } catch {
        recordFailure("Assertion threw error: \(error)", file: file, line: line)
    }
}

public func XCTAssertTrue(
    _ expression: @autoclosure () throws -> Bool,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) {
    do {
        let val = try expression()
        if !val {
            let customMsg = message()
            let msg = "Assertion Failure: Expression is false" + (customMsg.isEmpty ? "" : " - \(customMsg)")
            recordFailure(msg, file: file, line: line)
        }
    } catch {
        recordFailure("Assertion threw error: \(error)", file: file, line: line)
    }
}

public func XCTAssertFalse(
    _ expression: @autoclosure () throws -> Bool,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) {
    do {
        let val = try expression()
        if val {
            let customMsg = message()
            let msg = "Assertion Failure: Expression is true" + (customMsg.isEmpty ? "" : " - \(customMsg)")
            recordFailure(msg, file: file, line: line)
        }
    } catch {
        recordFailure("Assertion threw error: \(error)", file: file, line: line)
    }
}

public func XCTAssertNil(
    _ expression: @autoclosure () throws -> Any?,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) {
    do {
        let val = try expression()
        if val != nil {
            let customMsg = message()
            let msg = "Assertion Failure: Expected nil but got \(String(describing: val))" + (customMsg.isEmpty ? "" : " - \(customMsg)")
            recordFailure(msg, file: file, line: line)
        }
    } catch {
        recordFailure("Assertion threw error: \(error)", file: file, line: line)
    }
}

public func XCTAssertNotNil(
    _ expression: @autoclosure () throws -> Any?,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) {
    do {
        let val = try expression()
        if val == nil {
            let customMsg = message()
            let msg = "Assertion Failure: Expected non-nil value but got nil" + (customMsg.isEmpty ? "" : " - \(customMsg)")
            recordFailure(msg, file: file, line: line)
        }
    } catch {
        recordFailure("Assertion threw error: \(error)", file: file, line: line)
    }
}

public func XCTFail(
    _ message: String = "",
    file: StaticString = #file,
    line: UInt = #line
) {
    recordFailure("Explicit failure: \(message)", file: file, line: line)
}

private func recordFailure(_ message: String, file: StaticString, line: UInt) {
    let state = TestExecutionState.shared
    state.currentTestFailed = true
    let fullMsg = "\(file):\(line): \(message)"
    state.currentTestFailureMessages.append(fullMsg)
}

// MARK: - Test Case Base Class & Runner

open class VietFlowTestCase {
    public required init() {}
    
    open func setUp() {}
    open func tearDown() {}
    
    public typealias TestMethod = () throws -> Void
    
    open var allTests: [(name: String, test: TestMethod)] {
        return []
    }
    
    public func runTest(name: String, method: TestMethod) -> Bool {
        let state = TestExecutionState.shared
        state.currentTestName = name
        state.currentTestFailed = false
        state.currentTestFailureMessages = []
        state.totalTests += 1
        
        setUp()
        do {
            try method()
        } catch {
            recordFailure("Uncaught error: \(error)", file: #file, line: #line)
        }
        tearDown()
        
        if state.currentTestFailed {
            state.failedTests += 1
            for msg in state.currentTestFailureMessages {
                state.failedTestDetails.append((suite: state.currentSuiteName, test: name, message: msg))
            }
            return false
        } else {
            state.passedTests += 1
            return true
        }
    }
}

// MARK: - Test Suite Registry

public final class TestRegistry: @unchecked Sendable {
    public static let shared = TestRegistry()
    
    public var suites: [(name: String, factory: () -> VietFlowTestCase)] = []
    
    public func register(name: String, factory: @escaping () -> VietFlowTestCase) {
        suites.append((name: name, factory: factory))
    }
    
    public func runAll(verbose: Bool = false) -> Bool {
        let state = TestExecutionState.shared
        state.reset()
        
        print("================================================================================")
        print(" VietFlow Automated Test Suite Runner")
        print("================================================================================")
        
        let startTime = Date()
        
        for (suiteName, factory) in suites {
            state.currentSuiteName = suiteName
            let instance = factory()
            let tests = instance.allTests
            
            print("\nRunning Suite: \(suiteName) (\(tests.count) tests)")
            var suitePassed = 0
            var suiteFailed = 0
            
            for (testName, testMethod) in tests {
                let passed = instance.runTest(name: testName, method: testMethod)
                if passed {
                    suitePassed += 1
                    if verbose {
                        print("  [PASS] \(testName)")
                    }
                } else {
                    suiteFailed += 1
                    print("  [FAIL] \(testName)")
                    for detail in state.currentTestFailureMessages {
                        print("         -> \(detail)")
                    }
                }
            }
            print("  Suite Result: \(suitePassed) passed, \(suiteFailed) failed")
        }
        
        let duration = Date().timeIntervalSince(startTime)
        print("\n================================================================================")
        print(" Test Execution Summary")
        print("================================================================================")
        print(" Total Suites:     \(suites.count)")
        print(" Total Test Cases: \(state.totalTests)")
        print(" Passed:           \(state.passedTests)")
        print(" Failed:           \(state.failedTests)")
        print(String(format: " Duration:         %.3f seconds", duration))
        print("================================================================================")
        
        if state.failedTests > 0 {
            print("\nFailures:")
            for detail in state.failedTestDetails {
                print("  - [\(detail.suite)] \(detail.test):")
                print("    \(detail.message)")
            }
            return false
        }
        
        return true
    }
}

// MARK: - Engine Test Helpers

public func makeEngine(
    inputMethod: InputMethod = .telex,
    tonePlacement: TonePlacementStyle = .modern,
    autoCorrectEnglish: Bool = true,
    freeTonePlacement: Bool = true,
    escapeByDoubleKey: Bool = true
) -> VietnameseEngineProtocol {
    let config = EngineConfig(
        inputMethod: inputMethod,
        tonePlacement: tonePlacement,
        autoCorrectEnglish: autoCorrectEnglish,
        freeTonePlacement: freeTonePlacement,
        escapeByDoubleKey: escapeByDoubleKey
    )
    return BambooEngine(config: config)
}

public func typeSequence(
    _ input: String,
    into engine: VietnameseEngineProtocol
) -> (deltas: [TextDelta], buffer: String) {
    var buffer = engine.currentSyllable
    var deltas: [TextDelta] = []
    for char in input {
        if let delta = engine.processKey(char) {
            deltas.append(delta)
            if delta.backspaces > 0 {
                let dropCount = min(delta.backspaces, buffer.count)
                buffer = String(buffer.dropLast(dropCount))
            }
            buffer.append(delta.insertText)
        } else {
            buffer.append(char)
        }
    }
    return (deltas, buffer)
}
