//
//  AdaptiveLearningTests.swift
//  VietFlowTests
//
//  Comprehensive test suite for Backspace Error Logger & Self-Learning Adaptive Correction.
//  Verifies:
//  - Backspace error detection and classification (imeFriction vs personalTypo)
//  - Filtering out unrelated word replacements
//  - Secure Event Input protection
//  - JSON persistence and reloading
//  - Threshold count >= 3 activation
//  - Hybrid application: real-time zero-flicker for imeFriction & word-boundary for personalTypo
//  - Prefix word preservation (e.g. "tehran")
//  - Self-healing demotion upon backspacing an automatic correction
//  - AppStateManager persistence and resetToDefaults()
//  - Typing throughput benchmark with 142,500 characters
//

import Foundation
import CoreGraphics
import VietFlowEngine
import VietFlowState
import VietFlowEngineTests
import VietFlowEventTap

public final class AdaptiveLearningTests: TestCase {

    private var tempFileURL: URL!
    private var learner: AdaptiveLearningManager!
    private var engine: BambooEngine!

    public override func setUp() {
        super.setUp()
        let uniqueName = "test_typing_error_log_\(UUID().uuidString).json"
        tempFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(uniqueName)
        learner = AdaptiveLearningManager(fileURL: tempFileURL, isSecureEventInputActive: { false })
        engine = BambooEngine(config: EngineConfig(inputMethod: .telex, tonePlacement: .modern), adaptiveLearner: learner)
    }

    public override func tearDown() {
        try? FileManager.default.removeItem(at: tempFileURL)
        super.tearDown()
    }

    // MARK: - Helper Methods
    private func typeString(_ str: String, into engine: BambooEngine) -> (output: String, deltas: [TextDelta]) {
        var screen = ""
        var deltas: [TextDelta] = []
        for char in str {
            if let delta = engine.processKey(char) {
                deltas.append(delta)
                if delta.backspaces > 0 {
                    let drop = min(delta.backspaces, screen.count)
                    screen = String(screen.dropLast(drop))
                }
                screen.append(delta.insertText)
            } else {
                screen.append(char)
            }
        }
        return (screen, deltas)
    }

    // MARK: - Test 1: Classification of imeFriction and personalTypo
    func test_01_classification_ime_friction_and_personal_typo() {
        // imeFriction: user typed Vietnamese diacritic but committed raw English/Romaji
        let ime1 = AdaptiveLearningManager.classifyCorrection(
            rawKeysBeforeBackspace: "game",
            displayedBeforeBackspace: "gạme",
            finalCommittedText: "game"
        )
        XCTAssertNotNil(ime1)
        XCTAssertEqual(ime1?.category, .imeFriction)
        XCTAssertEqual(ime1?.trigger, "game")
        XCTAssertTrue(ime1?.isBypass == true)

        let ime2 = AdaptiveLearningManager.classifyCorrection(
            rawKeysBeforeBackspace: "origin",
            displayedBeforeBackspace: "orígin",
            finalCommittedText: "origin"
        )
        XCTAssertNotNil(ime2)
        XCTAssertEqual(ime2?.category, .imeFriction)
        XCTAssertTrue(ime2?.isBypass == true)

        let ime3 = AdaptiveLearningManager.classifyCorrection(
            rawKeysBeforeBackspace: "tar",
            displayedBeforeBackspace: "tả",
            finalCommittedText: "tar"
        )
        XCTAssertNotNil(ime3)
        XCTAssertEqual(ime3?.category, .imeFriction)
        XCTAssertTrue(ime3?.isBypass == true)

        // imeFriction: auto-restored English word corrected to force Vietnamese diacritics
        let ime4 = AdaptiveLearningManager.classifyCorrection(
            rawKeysBeforeBackspace: "view",
            displayedBeforeBackspace: "view",
            finalCommittedText: "viêu",
            wasBypassedBeforeBackspace: true
        )
        XCTAssertNotNil(ime4)
        XCTAssertEqual(ime4?.category, .imeFriction)
        XCTAssertTrue(ime4?.isPreserve == true)

        // personalTypo: mistyped English sequence
        let typo1 = AdaptiveLearningManager.classifyCorrection(
            rawKeysBeforeBackspace: "teh",
            displayedBeforeBackspace: "teh",
            finalCommittedText: "the"
        )
        XCTAssertNotNil(typo1)
        XCTAssertEqual(typo1?.category, .personalTypo)
        XCTAssertEqual(typo1?.trigger, "teh")
        XCTAssertEqual(typo1?.replacement, "the")

        // personalTypo: mistyped Vietnamese syllable
        let typo2 = AdaptiveLearningManager.classifyCorrection(
            rawKeysBeforeBackspace: "hjoc",
            displayedBeforeBackspace: "hjoc",
            finalCommittedText: "học"
        )
        XCTAssertNotNil(typo2)
        XCTAssertEqual(typo2?.category, .personalTypo)
        XCTAssertEqual(typo2?.trigger, "hjoc")
        XCTAssertEqual(typo2?.replacement, "học")
    }

    // MARK: - Test 2: Filtering Out Ordinary Unrelated Word Rewrites
    func test_02_filter_unrelated_word_rewrites() {
        // Completely unrelated words (banana -> computer, apple -> orange) must be ignored
        let unrelated1 = AdaptiveLearningManager.classifyCorrection(
            rawKeysBeforeBackspace: "banana",
            displayedBeforeBackspace: "banana",
            finalCommittedText: "computer"
        )
        XCTAssertNil(unrelated1, "Banana -> computer has low similarity and must be filtered out")

        let unrelated2 = AdaptiveLearningManager.classifyCorrection(
            rawKeysBeforeBackspace: "apple",
            displayedBeforeBackspace: "apple",
            finalCommittedText: "orange"
        )
        XCTAssertNil(unrelated2, "Apple -> orange has low similarity and must be filtered out")

        // Short words with edit distance 2 (completely disjoint) must also be filtered out
        let unrelatedShort1 = AdaptiveLearningManager.classifyCorrection(
            rawKeysBeforeBackspace: "car",
            displayedBeforeBackspace: "car",
            finalCommittedText: "man"
        )
        XCTAssertNil(unrelatedShort1, "Car -> man has edit distance 2 and must be filtered out")

        let unrelatedShort2 = AdaptiveLearningManager.classifyCorrection(
            rawKeysBeforeBackspace: "an",
            displayedBeforeBackspace: "an",
            finalCommittedText: "to"
        )
        XCTAssertNil(unrelatedShort2, "An -> to has edit distance 2 and must be filtered out")

        // Identical before and after is not an error
        let identical = AdaptiveLearningManager.classifyCorrection(
            rawKeysBeforeBackspace: "the",
            displayedBeforeBackspace: "the",
            finalCommittedText: "the"
        )
        XCTAssertNil(identical, "Identical strings must not be classified as errors")
    }

    // MARK: - Test 3: Secure Event Input Suppression
    func test_03_secure_event_input_suppression() {
        let secureLearner = AdaptiveLearningManager(fileURL: tempFileURL, isSecureEventInputActive: { true })
        let result = secureLearner.recordCorrection(
            rawKeysBeforeBackspace: "teh",
            displayedBeforeBackspace: "teh",
            finalCommittedText: "the"
        )
        XCTAssertNil(result, "No logging or learning should occur when Secure Event Input is enabled")
        XCTAssertEqual(secureLearner.loggedPatternsCount, 0)
    }

    // MARK: - Test 4: JSON Persistence and Reloading
    func test_04_json_persistence_and_reloading() {
        learner.recordCorrection(
            rawKeysBeforeBackspace: "teh",
            displayedBeforeBackspace: "teh",
            finalCommittedText: "the"
        )
        learner.recordCorrection(
            rawKeysBeforeBackspace: "game",
            displayedBeforeBackspace: "gạme",
            finalCommittedText: "game"
        )
        learner.flushSync()

        XCTAssertTrue(FileManager.default.fileExists(atPath: tempFileURL.path), "Log file must exist at tempFileURL")

        // Verify JSON contents is human-readable and valid
        guard let data = try? Data(contentsOf: tempFileURL),
              let jsonString = String(data: data, encoding: .utf8) else {
            XCTFail("Failed to read JSON string from log file")
            return
        }
        XCTAssertTrue(jsonString.contains("personalTypo"))
        XCTAssertTrue(jsonString.contains("imeFriction"))
        XCTAssertTrue(jsonString.contains("\"version\" : 1") || jsonString.contains("\"version\": 1"))

        // Reload into a separate manager instance
        let reloadedLearner = AdaptiveLearningManager(fileURL: tempFileURL, isSecureEventInputActive: { false })
        XCTAssertEqual(reloadedLearner.loggedPatternsCount, 2, "Reloaded manager must contain 2 entries")
        let entries = reloadedLearner.allEntries
        XCTAssertTrue(entries.contains(where: { $0.finalCommittedText == "the" }))
        XCTAssertTrue(entries.contains(where: { $0.finalCommittedText == "game" }))
    }

    // MARK: - Test 5: Activation Threshold (Count < 3 No-op, Count >= 3 Active)
    func test_05_activation_threshold_strictly_at_three() {
        // Occurrence 1: logged, rule not active
        let entry1 = learner.recordCorrection(
            rawKeysBeforeBackspace: "teh",
            displayedBeforeBackspace: "teh",
            finalCommittedText: "the"
        )
        XCTAssertEqual(entry1?.count, 1)
        XCTAssertNil(learner.replacementForPersonalTypo(word: "teh"))
        XCTAssertEqual(learner.activeRulesCount, 0)

        // Occurrence 2: logged, count=2, rule still not active
        let entry2 = learner.recordCorrection(
            rawKeysBeforeBackspace: "teh",
            displayedBeforeBackspace: "teh",
            finalCommittedText: "the"
        )
        XCTAssertEqual(entry2?.count, 2)
        XCTAssertNil(learner.replacementForPersonalTypo(word: "teh"))
        XCTAssertEqual(learner.activeRulesCount, 0)

        // Occurrence 3: logged, count=3, rule becomes ACTIVE!
        let entry3 = learner.recordCorrection(
            rawKeysBeforeBackspace: "teh",
            displayedBeforeBackspace: "teh",
            finalCommittedText: "the"
        )
        XCTAssertEqual(entry3?.count, 3)
        XCTAssertEqual(learner.replacementForPersonalTypo(word: "teh"), "the")
        XCTAssertEqual(learner.activeRulesCount, 1)
    }

    // MARK: - Test 6: imeFriction Real-Time Zero-Flicker Adaptation
    func test_06_ime_friction_realtime_zero_flicker_adaptation() {
        // Train "tar" as an English word to bypass (3 times)
        for _ in 1...3 {
            learner.recordCorrection(
                rawKeysBeforeBackspace: "tar",
                displayedBeforeBackspace: "tả",
                finalCommittedText: "tar"
            )
        }
        XCTAssertTrue(learner.shouldBypassForImeFriction(word: "tar"))

        // Now user types "tar" into the engine:
        // Normally in Telex, 't' + 'a' + 'r' produces 'tả'
        // With learned bypass, 'tar' must be emitted without 'tả' diacritic transform!
        engine.reset()
        let (output, _) = typeString("tar ", into: engine)
        XCTAssertEqual(output, "tar ", "Learned imeFriction bypass rule must preserve raw 'tar ' without transforming into 'tả '")
    }

    // MARK: - Test 7: imeFriction Vietnamese Diacritic Preservation
    func test_07_ime_friction_vietnamese_diacritic_preservation() {
        // Train "viêu" to preserve Vietnamese (e.g. user backspaced "view" auto-restore 3 times)
        for _ in 1...3 {
            learner.recordCorrection(
                rawKeysBeforeBackspace: "view",
                displayedBeforeBackspace: "view",
                finalCommittedText: "viêu",
                wasBypassedBeforeBackspace: true
            )
        }
        XCTAssertTrue(learner.shouldPreserveVietnameseForImeFriction(word: "viêu"))
        XCTAssertTrue(learner.shouldPreserveVietnameseForImeFriction(word: "view"))

        // Train "cót" (from "cost" auto-restore) 3 times
        for _ in 1...3 {
            learner.recordCorrection(
                rawKeysBeforeBackspace: "cost",
                displayedBeforeBackspace: "cost",
                finalCommittedText: "cót",
                wasBypassedBeforeBackspace: true
            )
        }
        XCTAssertTrue(learner.shouldPreserveVietnameseForImeFriction(word: "cost"))

        // Now user types "cost " into the engine:
        // Normally, EnglishRestoreDetector restores "cót" to English "cost" because it's in the keyword dictionary.
        // With learned preservation, the Vietnamese diacritic "cót " must be preserved!
        engine.reset()
        let (output, _) = typeString("cost ", into: engine)
        XCTAssertEqual(output, "cót ", "Learned imeFriction rule must preserve Vietnamese diacritics for 'cót ' instead of auto-restoring to 'cost '")
    }

    // MARK: - Test 8: personalTypo Word Boundary Replacement & Prefix Preservation
    func test_08_personal_typo_word_boundary_and_prefix_preservation() {
        // Train "teh" -> "the" 3 times
        for _ in 1...3 {
            learner.recordCorrection(
                rawKeysBeforeBackspace: "teh",
                displayedBeforeBackspace: "teh",
                finalCommittedText: "the"
            )
        }
        XCTAssertEqual(learner.replacementForPersonalTypo(word: "teh"), "the")

        // 1. Longer prefix word "tehran" must NOT be prematurely replaced mid-word!
        engine.reset()
        let (outputTehran, _) = typeString("tehran ", into: engine)
        XCTAssertEqual(outputTehran, "tehran ", "Prefix word 'tehran' must not be replaced by 'the'")

        // 2. Standalone typo "teh" followed by Space must be replaced with "the "
        engine.reset()
        let (outputThe, deltas) = typeString("teh ", into: engine)
        XCTAssertEqual(outputThe, "the ", "Typing 'teh ' must auto-correct to 'the ' on Space delimiter")
        XCTAssertFalse(deltas.isEmpty, "Delta must be produced to replace 'teh' with 'the '")

        // 3. Typo followed by punctuation must also be replaced
        engine.reset()
        let (outputPunct, _) = typeString("teh.", into: engine)
        XCTAssertEqual(outputPunct, "the.", "Typing 'teh.' must auto-correct to 'the.' on punctuation delimiter")

        // 4. Capitalized typo "Teh " preserves capitalization
        engine.reset()
        let (outputCaps, _) = typeString("Teh ", into: engine)
        XCTAssertEqual(outputCaps, "The ", "Capitalized 'Teh ' must auto-correct to 'The '")
    }

    // MARK: - Test 9: Self-Healing Feedback Loop Demotion
    func test_09_self_healing_demotion_on_backspace() {
        // Train "teh" -> "the" to count = 3
        for _ in 1...3 {
            learner.recordCorrection(
                rawKeysBeforeBackspace: "teh",
                displayedBeforeBackspace: "teh",
                finalCommittedText: "the"
            )
        }
        XCTAssertEqual(learner.activeRulesCount, 1)
        XCTAssertEqual(learner.replacementForPersonalTypo(word: "teh"), "the")

        // User types "teh " -> auto-corrects to "the "
        engine.reset()
        _ = typeString("teh ", into: engine)

        // User immediately presses Backspace to reject the automatic correction
        let handled = engine.handleBackspace()
        XCTAssertTrue(handled, "Backspace immediately after correction must trigger self-healing undo")

        // Verify rule is demoted: count decremented to 2, disabled, activeRulesCount back to 0
        XCTAssertEqual(learner.activeRulesCount, 0, "Demoted rule must no longer be active")
        XCTAssertNil(learner.replacementForPersonalTypo(word: "teh"), "Demoted rule must return nil replacement")

        // Subsequent typing of "teh " must NOT auto-correct
        engine.reset()
        let (outputUncorrected, _) = typeString("teh ", into: engine)
        XCTAssertEqual(outputUncorrected, "teh ", "After demotion, 'teh ' must remain 'teh ' without auto-correction")
    }

    // MARK: - Test 10: AppStateManager Persistence and Reset
    func test_10_app_state_manager_persistence_and_reset() {
        let state = AppStateManager.shared
        state.resetToDefaults()

        // Default value must be true
        XCTAssertTrue(state.adaptiveLearningEnabled)
        XCTAssertTrue(state.settings.adaptiveLearningEnabled)

        // Toggle to false
        state.adaptiveLearningEnabled = false
        XCTAssertFalse(state.adaptiveLearningEnabled)
        XCTAssertFalse(state.settings.adaptiveLearningEnabled)

        // Reset to defaults must restore to true
        state.resetToDefaults()
        XCTAssertTrue(state.adaptiveLearningEnabled, "resetToDefaults() must restore adaptiveLearningEnabled to true")
        XCTAssertTrue(state.settings.adaptiveLearningEnabled)
    }

    // MARK: - Test 11: End-to-End Typing Flow With Backspaces in Engine
    func test_11_end_to_end_backspace_typing_flow() {
        engine.reset()
        // Simulate: user types "teh", presses Backspace twice, types "he", then Space
        _ = typeString("teh", into: engine)
        _ = engine.handleBackspace()
        _ = engine.handleBackspace()
        _ = typeString("he ", into: engine)

        learner.flushSync()
        XCTAssertEqual(learner.loggedPatternsCount, 1, "One pattern should be logged after backspace correction and commit")
    }

    // MARK: - Test 12: Typing Throughput Performance Benchmark (142,500 characters)
    func test_12_typing_throughput_benchmark_142500_chars() {
        // Benchmark baseline corpus: 285 characters
        let sample = "haf nooji muaf thu caay cowm nguooji vangf caay bangf las ddor, nawmf keef been nhau phoos xuwa nhaf coor mais ngois thaam naau tooi gox thwr thajat nhieeuf pattern khacs nhau maf nguoiwf vieetj hay gox, vaf twf dods ddeef xuaats cachs fix toois uwu nhaats "
        let repetitions = 142500 / sample.count // 500 repetitions = 142,500 characters
        let totalChars = sample.count * repetitions

        // 1. Benchmark without learned rules
        let cleanEngine = BambooEngine(
            config: EngineConfig(inputMethod: .telex, tonePlacement: .modern),
            adaptiveLearner: learner
        )

        // Warm-up pass
        for _ in 0..<2 {
            for ch in sample {
                _ = cleanEngine.processKey(ch)
            }
        }
        cleanEngine.reset()

        let startEmpty = CFAbsoluteTimeGetCurrent()
        for _ in 0..<repetitions {
            for ch in sample {
                _ = cleanEngine.processKey(ch)
            }
        }
        let durationEmpty = CFAbsoluteTimeGetCurrent() - startEmpty
        let charsPerSecEmpty = Double(totalChars) / durationEmpty
        let usPerKeyEmpty = (durationEmpty / Double(totalChars)) * 1_000_000.0

        // 2. Train several active learned rules (both imeFriction and personalTypo)
        for _ in 1...3 {
            learner.recordCorrection(rawKeysBeforeBackspace: "teh", displayedBeforeBackspace: "teh", finalCommittedText: "the")
            learner.recordCorrection(rawKeysBeforeBackspace: "tar", displayedBeforeBackspace: "tả", finalCommittedText: "tar")
            learner.recordCorrection(rawKeysBeforeBackspace: "wierd", displayedBeforeBackspace: "wierd", finalCommittedText: "weird")
        }
        learner.flushSync()
        XCTAssertEqual(learner.activeRulesCount, 3)

        // 3. Benchmark WITH active learned rules
        let activeEngine = BambooEngine(
            config: EngineConfig(inputMethod: .telex, tonePlacement: .modern),
            adaptiveLearner: learner
        )

        // Warm-up pass
        for _ in 0..<2 {
            for ch in sample {
                _ = activeEngine.processKey(ch)
            }
        }
        activeEngine.reset()

        let startActive = CFAbsoluteTimeGetCurrent()
        for _ in 0..<repetitions {
            for ch in sample {
                _ = activeEngine.processKey(ch)
            }
        }
        let durationActive = CFAbsoluteTimeGetCurrent() - startActive
        let charsPerSecActive = Double(totalChars) / durationActive
        let usPerKeyActive = (durationActive / Double(totalChars)) * 1_000_000.0

        print(String(format: "==> Benchmark (Empty/Disabled): %d chars in %.2f ms (%.2f µs/key, %.0f chars/sec)",
                     totalChars, durationEmpty * 1000.0, usPerKeyEmpty, charsPerSecEmpty))
        print(String(format: "==> Benchmark (Active Rules):   %d chars in %.2f ms (%.2f µs/key, %.0f chars/sec)",
                     totalChars, durationActive * 1000.0, usPerKeyActive, charsPerSecActive))

        // Assert throughput exceeds target criteria (>60,000 chars/sec, <20 µs/key) and remains within ~5-10% of baseline
        let ratio = charsPerSecActive / charsPerSecEmpty
        XCTAssertTrue(ratio >= 0.90, "Active throughput must remain within ~5-10% of empty baseline (ratio: \(ratio))")
        XCTAssertTrue(charsPerSecEmpty > 60_000, "Empty throughput must be > 60,000 chars/sec (measured: \(charsPerSecEmpty))")
        XCTAssertTrue(charsPerSecActive > 60_000, "Active throughput must be > 60,000 chars/sec (measured: \(charsPerSecActive))")
        XCTAssertTrue(usPerKeyActive < 20.0, "Latency per keystroke must be < 20 µs/key (measured: \(usPerKeyActive) µs)")
    }

    // MARK: - Test 13: Exact Screen Buffer Reversion on Backspace Delta
    func test_13_revert_delta_exact_screen_restoration() {
        // Train "teh" -> "the" to count = 3
        for _ in 1...3 {
            learner.recordCorrection(
                rawKeysBeforeBackspace: "teh",
                displayedBeforeBackspace: "teh",
                finalCommittedText: "the"
            )
        }
        XCTAssertEqual(learner.activeRulesCount, 1)

        // 1. Test space delimiter: "teh " -> "the "
        engine.reset()
        var screen = ""
        for char in "teh " {
            if let delta = engine.processKey(char) {
                if delta.backspaces > 0 {
                    screen = String(screen.dropLast(min(delta.backspaces, screen.count)))
                }
                screen.append(delta.insertText)
            } else {
                screen.append(char)
            }
        }
        XCTAssertEqual(screen, "the ", "Screen must have auto-corrected to 'the '")

        // User hits Backspace immediately to revert
        guard let revertDelta = engine.handleBackspaceWithRevertDelta() else {
            XCTFail("handleBackspaceWithRevertDelta must return a non-nil delta immediately after correction")
            return
        }

        // Apply revert delta to screen
        if revertDelta.backspaces > 0 {
            screen = String(screen.dropLast(min(revertDelta.backspaces, screen.count)))
        }
        screen.append(revertDelta.insertText)

        // The screen MUST be cleanly reverted to "teh" (not "the" or "theh"!)
        XCTAssertEqual(screen, "teh", "Applying revertDelta must cleanly restore screen to the original typo 'teh'")
        XCTAssertEqual(learner.activeRulesCount, 0, "Self-healing must demote active rule count to 0")

        // 2. Test punctuation delimiter: "teh." -> "the."
        // Re-train to count = 3
        learner.recordCorrection(rawKeysBeforeBackspace: "teh", displayedBeforeBackspace: "teh", finalCommittedText: "the")
        XCTAssertEqual(learner.activeRulesCount, 1)

        engine.reset()
        screen = ""
        for char in "teh." {
            if let delta = engine.processKey(char) {
                if delta.backspaces > 0 {
                    screen = String(screen.dropLast(min(delta.backspaces, screen.count)))
                }
                screen.append(delta.insertText)
            } else {
                screen.append(char)
            }
        }
        XCTAssertEqual(screen, "the.", "Screen must have auto-corrected to 'the.'")

        guard let revertPunctDelta = engine.handleBackspaceWithRevertDelta() else {
            XCTFail("handleBackspaceWithRevertDelta must return a non-nil delta after punctuation boundary correction")
            return
        }

        if revertPunctDelta.backspaces > 0 {
            screen = String(screen.dropLast(min(revertPunctDelta.backspaces, screen.count)))
        }
        screen.append(revertPunctDelta.insertText)
        XCTAssertEqual(screen, "teh", "Applying revertDelta after punctuation must cleanly restore screen to 'teh'")
    }

    // MARK: - Test 14: Subsequent Character Clears Reversion Window
    func test_14_subsequent_character_clears_reversion() {
        for _ in 1...3 {
            learner.recordCorrection(
                rawKeysBeforeBackspace: "teh",
                displayedBeforeBackspace: "teh",
                finalCommittedText: "the"
            )
        }

        // User types "teh " -> "the "
        engine.reset()
        _ = typeString("teh ", into: engine)

        // User types another space (or a letter)
        _ = engine.processKey(" ")

        // Now user presses Backspace -> should NOT revert "the " to "teh"!
        let revertDelta = engine.handleBackspaceWithRevertDelta()
        XCTAssertNil(revertDelta, "Typing another character after boundary must clear reversion window")
    }

    // MARK: - Test 15: Space History Boundary Isolation
    func test_15_space_history_boundary_isolation() {
        engine.reset()
        // Type "hello world", backspace past 'world' into 'hello'
        _ = typeString("hello world", into: engine)
        // 5 backspaces to delete 'world'
        for _ in 0..<5 {
            _ = engine.handleBackspace()
        }
        // One more backspace pops spaceHistory into 'hello'
        _ = engine.handleBackspace()

        // Finish typing " world "
        _ = typeString("world ", into: engine)
        learner.flushSync()

        // No corrupted typo should have been logged across the space boundary
        let entries = learner.allEntries
        XCTAssertFalse(entries.contains(where: { $0.displayedBeforeBackspace.contains("world") && $0.finalCommittedText.contains("hello") }))
    }

    // MARK: - Test 16: Backspace Correction Committed on Period Punctuation
    func test_16_backspace_correction_committed_on_period_delimiter() {
        engine.reset()
        // Simulate: user types "teh", backspaces twice, types "he", then commits with period "."
        _ = typeString("teh", into: engine)
        _ = engine.handleBackspace()
        _ = engine.handleBackspace()
        _ = typeString("he.", into: engine)

        learner.flushSync()
        XCTAssertEqual(learner.loggedPatternsCount, 1, "Pattern should be logged when backspace correction commits on period '.' delimiter")
        let entry = learner.allEntries.first
        XCTAssertEqual(entry?.rawKeysBeforeBackspace, "teh")
        XCTAssertEqual(entry?.finalCommittedText, "the")

        // Subsequent word must not be polluted by previous snapshot
        _ = typeString("apple ", into: engine)
        learner.flushSync()
        XCTAssertEqual(learner.loggedPatternsCount, 1, "Subsequent clean word must not log spurious errors")
    }

    // MARK: - Test 17: Space History Traversal Into Corrected Word
    func test_17_space_history_traversal_into_corrected_word() {
        for _ in 1...3 {
            learner.recordCorrection(rawKeysBeforeBackspace: "teh", displayedBeforeBackspace: "teh", finalCommittedText: "the")
        }
        XCTAssertEqual(learner.activeRulesCount, 1)

        engine.reset()
        var screen = ""

        func feedString(_ s: String) {
            for ch in s {
                if let delta = engine.processKey(ch) {
                    if delta.backspaces > 0 {
                        screen = String(screen.dropLast(min(delta.backspaces, screen.count)))
                    }
                    screen.append(delta.insertText)
                } else {
                    screen.append(ch)
                }
            }
        }

        func feedBackspace() {
            if engine.handleBackspace() {
                if !screen.isEmpty {
                    screen.removeLast()
                }
            }
        }

        // Type "teh " -> auto-corrects to "the "
        feedString("teh ")
        XCTAssertEqual(screen, "the ")

        // Type another word: "dog "
        feedString("dog ")
        XCTAssertEqual(screen, "the dog ")

        // Backspace 4 times to erase "dog "
        for _ in 0..<4 {
            feedBackspace()
        }
        XCTAssertEqual(screen, "the ")

        // One more backspace to cross into the space after "the"
        feedBackspace()
        XCTAssertEqual(screen, "the")

        // Next backspace deletes 'e' from "the", leaving "th"
        feedBackspace()
        XCTAssertEqual(screen, "th")

        // Type "em "
        feedString("em ")
        XCTAssertEqual(screen, "them ", "Backspacing into auto-corrected word and editing it should yield 'them '")
    }

    // MARK: - Test 18: Sentence-Start Capitalized Personal Typo Normalization
    func test_18_sentence_start_capitalized_personal_typo_normalization() {
        // User mistypes at sentence start: "Teh" -> backspaces -> "The"
        for _ in 1...3 {
            learner.recordCorrection(rawKeysBeforeBackspace: "Teh", displayedBeforeBackspace: "Teh", finalCommittedText: "The")
        }
        XCTAssertEqual(learner.activeRulesCount, 1)

        // 1. Mid-sentence lowercase "teh " should produce lowercase "the "
        engine.reset()
        let (outputLower, _) = typeString("teh ", into: engine)
        XCTAssertEqual(outputLower, "the ", "Mid-sentence 'teh ' must auto-correct to lowercase 'the ', not capitalized 'The '")

        // 2. Sentence-start "Teh " should produce capitalized "The "
        engine.reset()
        let (outputUpper, _) = typeString("Teh ", into: engine)
        XCTAssertEqual(outputUpper, "The ", "Sentence-start 'Teh ' must auto-correct to capitalized 'The '")

        // 3. Proper noun intentional capitalization: "vietnam" -> "Việt Nam"
        for _ in 1...3 {
            learner.recordCorrection(rawKeysBeforeBackspace: "vietnam", displayedBeforeBackspace: "vietnam", finalCommittedText: "Việt Nam")
        }
        engine.reset()
        let (outputProper, _) = typeString("vietnam ", into: engine)
        XCTAssertEqual(outputProper, "Việt Nam ", "Intentional proper noun capitalization must be preserved even if typed lowercase")
    }

    // MARK: - Test 19: EventTapManager Backspace Does Not Double Delete
    func test_19_event_tap_backspace_single_deletion() {
        let eventTap = EventTapManager(engine: engine, stateManager: .shared)
        _ = engine.processKey("x")
        _ = engine.processKey("i")
        _ = engine.processKey("n")
        XCTAssertEqual(engine.currentSyllable, "xin")

        let bsEvent = CGEvent(keyboardEventSource: nil, virtualKey: 51, keyDown: true)!
        bsEvent.flags = []
        _ = eventTap.handleEvent(type: .keyDown, event: bsEvent)

        // Must delete exactly 1 character from preedit ('n'), leaving "xi" (NOT "x"!)
        XCTAssertEqual(engine.currentSyllable, "xi", "Backspace event must delete exactly one character in engine, not double-backspace")
    }

    // MARK: - Test 20: clearData Cancels Pending Save and Prevents Resurrection
    func test_20_clear_data_cancels_pending_save_and_prevents_resurrection() {
        // Trigger a background async save
        learner.recordCorrection(rawKeysBeforeBackspace: "teh", displayedBeforeBackspace: "teh", finalCommittedText: "the")
        XCTAssertEqual(learner.loggedPatternsCount, 1)

        // Immediately clear data
        learner.clearData()
        XCTAssertEqual(learner.loggedPatternsCount, 0)
        XCTAssertEqual(learner.activeRulesCount, 0)

        // Wait past debounce window to ensure background worker did not resurrect data
        Thread.sleep(forTimeInterval: 0.25)
        learner.loadFromFile()

        XCTAssertEqual(learner.loggedPatternsCount, 0, "Cleared data must not be resurrected by pending background save")
        XCTAssertEqual(learner.activeRulesCount, 0)
    }

    // MARK: - Test 21: Proper Noun Sentence-Start Capitalization Preservation
    func test_21_proper_noun_capitalization_preservation() {
        // Correcting a proper noun with internal capitalization at sentence start: "Vietj Nam" -> "Việt Nam"
        let classification = AdaptiveLearningManager.classifyCorrection(
            rawKeysBeforeBackspace: "Vietj Nam",
            displayedBeforeBackspace: "Vietj Nam",
            finalCommittedText: "Việt Nam"
        )
        XCTAssertNotNil(classification)
        XCTAssertEqual(classification?.replacement, "Việt Nam", "Proper noun with internal capital letters must retain capitalization and not be lowercased")
    }

    // MARK: - Test 22: Short Word and Casing Normalization
    func test_22_single_character_casing_normalization() {
        // Train short typo replacement: "im" -> "in" (distance 1, length 2, similarity 0.5)
        for _ in 1...3 {
            learner.recordCorrection(rawKeysBeforeBackspace: "im", displayedBeforeBackspace: "im", finalCommittedText: "in")
        }
        XCTAssertEqual(learner.replacementForPersonalTypo(word: "im"), "in")

        engine.reset()
        let (outputLower, _) = typeString("im ", into: engine)
        XCTAssertEqual(outputLower, "in ", "Lowercase 'im ' must auto-correct to 'in '")

        engine.reset()
        let (outputUpper, _) = typeString("Im ", into: engine)
        XCTAssertEqual(outputUpper, "In ", "Titlecase 'Im ' must auto-correct to 'In '")

        engine.reset()
        let (outputAllCaps, _) = typeString("IM ", into: engine)
        XCTAssertEqual(outputAllCaps, "IN ", "Uppercase 'IM ' must auto-correct to 'IN '")
    }

    // MARK: - Test 23: Open Typing Error Log Defaults to macOS TextEdit.app
    func test_23_open_typing_error_log_defaults_to_textedit() {
        let stateManager = AppStateManager.shared
        let previousOpener = stateManager.logFileOpener
        defer { stateManager.logFileOpener = previousOpener }

        var openedFileURL: URL?
        var openedAppURL: URL?
        stateManager.logFileOpener = { fileURL, appURL in
            openedFileURL = fileURL
            openedAppURL = appURL
        }

        stateManager.openTypingErrorLog()

        XCTAssertEqual(AppStateManager.textEditBundleIdentifier, "com.apple.TextEdit")
        XCTAssertEqual(openedFileURL, AdaptiveLearningManager.shared.fileURL)
        XCTAssertNotNil(openedAppURL)
        XCTAssertTrue(
            openedAppURL?.lastPathComponent == "TextEdit.app",
            "Expected typing_error_log.json to open with TextEdit.app, got: \(openedAppURL?.path ?? "nil")"
        )
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: AdaptiveLearningManager.shared.fileURL.path),
            "openTypingErrorLog() must flush typing_error_log.json to disk before opening in TextEdit"
        )
    }

    // MARK: - Test 24: ALL-CAPS and TitleCase Personal Typo Normalization & Casing Preservation
    func test_24_all_caps_and_titlecase_personal_typo_normalization() {
        // 1. Training with ALL-CAPS: "ADN" -> "AND" must normalize replacement to lowercase "and"
        for _ in 1...3 {
            learner.recordCorrection(rawKeysBeforeBackspace: "ADN", displayedBeforeBackspace: "ADN", finalCommittedText: "AND")
        }
        XCTAssertEqual(learner.replacementForPersonalTypo(word: "adn"), "and", "ALL-CAPS trained typo must be normalized to lowercase 'and'")

        // When user types in lowercase, it must output lowercase
        engine.reset()
        let (outputLower, _) = typeString("adn ", into: engine)
        XCTAssertEqual(outputLower, "and ", "Typing lowercase 'adn ' must auto-correct to lowercase 'and ', not uppercase 'AND '")

        // When user types in TitleCase, it must output TitleCase
        engine.reset()
        let (outputTitle, _) = typeString("Adn ", into: engine)
        XCTAssertEqual(outputTitle, "And ", "Typing TitleCase 'Adn ' must auto-correct to TitleCase 'And '")

        // When user types in ALL-CAPS, it must output ALL-CAPS
        engine.reset()
        let (outputCaps, _) = typeString("ADN ", into: engine)
        XCTAssertEqual(outputCaps, "AND ", "Typing ALL-CAPS 'ADN ' must auto-correct to ALL-CAPS 'AND '")

        // 2. Training with TitleCase: "taht" -> "That" must also normalize to lowercase "that"
        for _ in 1...3 {
            learner.recordCorrection(rawKeysBeforeBackspace: "taht", displayedBeforeBackspace: "taht", finalCommittedText: "That")
        }
        XCTAssertEqual(learner.replacementForPersonalTypo(word: "taht"), "that", "TitleCase trained typo must be normalized to lowercase 'that'")

        engine.reset()
        let (outTahtLower, _) = typeString("taht ", into: engine)
        XCTAssertEqual(outTahtLower, "that ", "Typing lowercase 'taht ' must auto-correct to lowercase 'that '")

        engine.reset()
        let (outTahtTitle, _) = typeString("Taht ", into: engine)
        XCTAssertEqual(outTahtTitle, "That ", "Typing TitleCase 'Taht ' must auto-correct to TitleCase 'That '")

        engine.reset()
        let (outTahtCaps, _) = typeString("TAHT ", into: engine)
        XCTAssertEqual(outTahtCaps, "THAT ", "Typing ALL-CAPS 'TAHT ' must auto-correct to ALL-CAPS 'THAT '")

        // 3. Genuine internal mixed-case proper noun: "iphone" -> "iPhone"
        for _ in 1...3 {
            learner.recordCorrection(rawKeysBeforeBackspace: "iphone", displayedBeforeBackspace: "iphone", finalCommittedText: "iPhone")
        }
        XCTAssertEqual(learner.replacementForPersonalTypo(word: "iphone"), "iPhone", "Proper noun with internal mixed case must be preserved")

        engine.reset()
        let (outPhone, _) = typeString("iphone ", into: engine)
        XCTAssertEqual(outPhone, "iPhone ", "Typing lowercase 'iphone ' must auto-correct to exact mixed-case 'iPhone '")
    }

    // MARK: - Test 25: Step 8 Orthography Restored Syllable Learned Preservation
    func test_25_step8_orthography_restored_syllable_learned_preservation() {
        // "kas" normally produces "kas" due to Step 8 isInvalidKOrZOrthography restore.
        // User types "kas", backspaces 's', types 's' (giving "ká"), and commits with Space ' ' 3 times.
        for _ in 1...3 {
            engine.reset()
            _ = typeString("kas", into: engine)
            _ = engine.handleBackspace() // deletes 's', unlatches bypass
            _ = typeString("s ", into: engine) // types 's' giving "ká", commits with Space
        }

        // Verify rule is learned: trigger "kas", replacement "ká", category .imeFriction, isPreserve true, count == 3
        XCTAssertTrue(learner.shouldPreserveVietnameseForImeFriction(word: "kas"), "Rule trigger 'kas' must be preserved")
        XCTAssertTrue(learner.shouldPreserveVietnameseForImeFriction(word: "ká"), "Replacement 'ká' must be preserved")
        XCTAssertTrue(learner.shouldPreserveVietnameseForImeFriction(word: "ka"), "Unaccented 'ka' must be preserved")

        // 4th time: typing "kas " directly must produce "ká " without Step 8 English restore
        engine.reset()
        let (output4, _) = typeString("kas ", into: engine)
        XCTAssertEqual(output4, "ká ", "Typing 'kas ' must produce 'ká ' in real time with Step 8 restore bypassed")
    }

    // MARK: - Test 26: Real-Time imeFriction Self-Healing Demotion on Backspace
    func test_26_ime_friction_self_healing_demotion_on_backspace() {
        // Learn "kas" -> "ká" 3 times
        for _ in 1...3 {
            engine.reset()
            _ = typeString("kas", into: engine)
            _ = engine.handleBackspace()
            _ = typeString("s ", into: engine)
        }
        XCTAssertTrue(learner.shouldPreserveVietnameseForImeFriction(word: "kas"))

        // User types "kas" -> engine automatically adapts in real time to "ká"
        engine.reset()
        let (outAdapted, _) = typeString("kas", into: engine)
        XCTAssertEqual(outAdapted, "ká", "Real-time adaptation must produce 'ká'")

        // User immediately presses Backspace to reject the adaptation
        let handled = engine.handleBackspace()
        XCTAssertTrue(handled, "Backspace on real-time adapted word must succeed")

        // Verify rule is demoted
        XCTAssertFalse(learner.shouldPreserveVietnameseForImeFriction(word: "kas"), "Rule must be demoted and disabled")

        // Subsequent typing of "kas " into reset engine must revert to normal behavior (restored to "kas ")
        engine.reset()
        let (outNormal, _) = typeString("kas ", into: engine)
        XCTAssertEqual(outNormal, "kas ", "After demotion, 'kas ' must not be adapted to 'ká '")
    }

    // MARK: - Test 27: Backspacing Across Space History Learns Personal Typo
    func test_27_backspace_across_space_history_personal_typo() {
        // User types "việ ", backspaces across space to reopen "việ", types "t ", committing "việt " 3 times
        for _ in 1...3 {
            engine.reset()
            _ = typeString("vieej ", into: engine) // commits "việ "
            _ = engine.handleBackspace() // backspaces across space to reopen "việ"
            _ = typeString("t ", into: engine) // appends 't' to form "việt" and commits with Space
        }

        // Verify personal typo is learned: "việ" -> "việt"
        XCTAssertEqual(learner.replacementForPersonalTypo(word: "việ"), "việt", "Personal typo 'việ' -> 'việt' must be learned after 3 occurrences")

        // Now user types "vieej " into reset engine:
        // On Space delimiter, "việ" should auto-correct to "việt "
        engine.reset()
        let (outCorrected, _) = typeString("vieej ", into: engine)
        XCTAssertEqual(outCorrected, "việt ", "Typing 'vieej ' must auto-correct to 'việt ' on word boundary")
    }

    // MARK: - Registration of All Tests
    public override var allTests: [(name: String, test: TestMethod)] {
        return [
            ("test_01_classification_ime_friction_and_personal_typo", test_01_classification_ime_friction_and_personal_typo),
            ("test_02_filter_unrelated_word_rewrites", test_02_filter_unrelated_word_rewrites),
            ("test_03_secure_event_input_suppression", test_03_secure_event_input_suppression),
            ("test_04_json_persistence_and_reloading", test_04_json_persistence_and_reloading),
            ("test_05_activation_threshold_strictly_at_three", test_05_activation_threshold_strictly_at_three),
            ("test_06_ime_friction_realtime_zero_flicker_adaptation", test_06_ime_friction_realtime_zero_flicker_adaptation),
            ("test_07_ime_friction_vietnamese_diacritic_preservation", test_07_ime_friction_vietnamese_diacritic_preservation),
            ("test_08_personal_typo_word_boundary_and_prefix_preservation", test_08_personal_typo_word_boundary_and_prefix_preservation),
            ("test_09_self_healing_demotion_on_backspace", test_09_self_healing_demotion_on_backspace),
            ("test_10_app_state_manager_persistence_and_reset", test_10_app_state_manager_persistence_and_reset),
            ("test_11_end_to_end_backspace_typing_flow", test_11_end_to_end_backspace_typing_flow),
            ("test_12_typing_throughput_benchmark_142500_chars", test_12_typing_throughput_benchmark_142500_chars),
            ("test_13_revert_delta_exact_screen_restoration", test_13_revert_delta_exact_screen_restoration),
            ("test_14_subsequent_character_clears_reversion", test_14_subsequent_character_clears_reversion),
            ("test_15_space_history_boundary_isolation", test_15_space_history_boundary_isolation),
            ("test_16_backspace_correction_committed_on_period_delimiter", test_16_backspace_correction_committed_on_period_delimiter),
            ("test_17_space_history_traversal_into_corrected_word", test_17_space_history_traversal_into_corrected_word),
            ("test_18_sentence_start_capitalized_personal_typo_normalization", test_18_sentence_start_capitalized_personal_typo_normalization),
            ("test_19_event_tap_backspace_single_deletion", test_19_event_tap_backspace_single_deletion),
            ("test_20_clear_data_cancels_pending_save_and_prevents_resurrection", test_20_clear_data_cancels_pending_save_and_prevents_resurrection),
            ("test_21_proper_noun_capitalization_preservation", test_21_proper_noun_capitalization_preservation),
            ("test_22_single_character_casing_normalization", test_22_single_character_casing_normalization),
            ("test_23_open_typing_error_log_defaults_to_textedit", test_23_open_typing_error_log_defaults_to_textedit),
            ("test_24_all_caps_and_titlecase_personal_typo_normalization", test_24_all_caps_and_titlecase_personal_typo_normalization),
            ("test_25_step8_orthography_restored_syllable_learned_preservation", test_25_step8_orthography_restored_syllable_learned_preservation),
            ("test_26_ime_friction_self_healing_demotion_on_backspace", test_26_ime_friction_self_healing_demotion_on_backspace),
            ("test_27_backspace_across_space_history_personal_typo", test_27_backspace_across_space_history_personal_typo),
        ]
    }
}
