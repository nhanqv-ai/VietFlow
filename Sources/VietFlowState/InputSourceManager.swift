//
//  InputSourceManager.swift
//  VietFlowState
//
//  macOS Input Source (Keyboard Layout / IME) detection and switching abstraction.
//  Provides seamless coexistence with Japanese, Chinese, Korean, and other non-Latin IMEs.
//

import Foundation
import Carbon

public enum InputSourceClassifier {
    private static let foreignIMESubstrings: [String] = [
        "kotoeri", "japanese", "scim", "tcim", "korean", "cangjie", "sucheng",
        "pinyin", "zhuyin", "bopomofo", "hangul", "hangeul", "hanja", "atok",
        "rime", "squirrel", "chewing", "mozc", "wubi", "quick", "gureum",
        "skk", "dayi", "array30"
    ]
    
    private static let nonLatinLayoutSubstrings: [String] = [
        "russian", "cyrillic", "ukrainian", "byelorussian", "belarusian", "bulgarian", "serbian", "macedonian",
        "greek", "arabic", "persian", "urdu", "hebrew", "thai", "lao", "khmer", "myanmar", "burmese",
        "hindi", "devanagari", "bengali", "tamil", "telugu", "kannada", "malayalam", "gujarati", "gurmukhi",
        "marathi", "sanskrit", "tibetan", "cherokee", "inuktitut", "georgian", "armenian", "sinhala", "dhivehi",
        "kazakh", "mongolian", "uyghur", "yiddish", "punjabi", "oriya", "odia", "assamese", "amharic", "ethiopic",
        "tigrinya", "syriac", "thaana"
    ]
    
    public static func isForeignInputSource(sourceID: String, sourceType: String = "") -> Bool {
        guard !sourceID.isEmpty else { return false }
        let lowerID = sourceID.lowercased()
        let lowerType = sourceType.lowercased()
        
        // 1. Explicit multi-stage IME identifiers
        for sub in foreignIMESubstrings {
            if lowerID.contains(sub) {
                return true
            }
        }
        
        // 2. Generic inputmethod in ID (covers third-party IMEs like Sogou, Baidu, Google IME)
        if lowerID.contains("inputmethod") {
            return true
        }
        
        // 3. Source type indicates an input method mode rather than a static keyboard layout
        if !sourceType.isEmpty && sourceType != (kTISTypeKeyboardLayout as String) {
            if lowerType.contains("inputmode") || lowerType.contains("inputmethod") {
                return true
            }
        }
        
        // 4. Non-Latin physical keyboard layouts (Russian Cyrillic, Greek, Arabic, Hebrew, Thai, Indic, etc.)
        for sub in nonLatinLayoutSubstrings {
            if lowerID.contains(sub) {
                return true
            }
        }
        
        return false
    }
    
    public static func isLatinKeyboardLayout(sourceID: String, sourceType: String = "") -> Bool {
        guard !sourceID.isEmpty else { return false }
        if isForeignInputSource(sourceID: sourceID, sourceType: sourceType) {
            return false
        }
        // Palette, ink, or other non-keyboard layout sources cannot be Latin keyboard layouts
        if !sourceType.isEmpty && sourceType != (kTISTypeKeyboardLayout as String) {
            return false
        }
        let lowerID = sourceID.lowercased()
        for sub in nonLatinLayoutSubstrings {
            if lowerID.contains(sub) {
                return false
            }
        }
        if sourceType == (kTISTypeKeyboardLayout as String) {
            return true
        }
        if sourceID.hasPrefix("com.apple.keylayout.") {
            return true
        }
        if sourceID.contains("ABC") || sourceID.contains("US") {
            return true
        }
        if lowerID.contains("colemak") ||
           lowerID.contains("dvorak") ||
           lowerID.contains("neo") ||
           lowerID.contains("qwerty") ||
           lowerID.contains("qwertz") ||
           lowerID.contains("azerty") ||
           lowerID.contains("workman") ||
           lowerID.contains("halmak") ||
           lowerID.contains("norman") ||
           lowerID.contains("bepo") ||
           lowerID.contains("keyboardlayout") {
            return true
        }
        return false
    }
}

public protocol InputSourceManaging: AnyObject, Sendable {
    /// Identifier of the currently active input source (e.g. "com.apple.keylayout.ABC", "com.apple.inputmethod.Kotoeri.Japanese")
    var currentInputSourceID: String { get }
    
    /// Type of the currently active input source (e.g. "TISTypeKeyboardLayout", "TISTypeKeyboardInputMode")
    var currentInputSourceType: String { get }
    
    /// True if the current input source is a foreign / multi-stage IME (Japanese, Chinese, Korean, etc.)
    var isCurrentSourceForeign: Bool { get }
    
    /// True if the current input source is a Latin keyboard layout (ABC, US, etc.)
    var isCurrentSourceLatin: Bool { get }
    
    /// Callback invoked when the active input source changes
    var onInputSourceChanged: ((_ newSourceID: String, _ isForeign: Bool) -> Void)? { get set }
    
    /// Programmatically select the primary Latin input source (ABC or US)
    @discardableResult
    func selectLatinInputSource() -> Bool
    
    /// Programmatically select an input source by its unique ID (e.g. "com.apple.inputmethod.Kotoeri.Japanese")
    @discardableResult
    func selectInputSource(byID sourceID: String) -> Bool
    
    /// Synchronously check and refresh the current input source from the system
    @discardableResult
    func refreshCurrentInputSource() -> (sourceID: String, isForeign: Bool)
    
    /// Start listening to system-wide input source change notifications
    func startObserving()
    
    /// Stop listening to system-wide input source change notifications
    func stopObserving()
}

public final class SystemInputSourceManager: InputSourceManaging, @unchecked Sendable {
    public static let shared = SystemInputSourceManager()
    
    public private(set) var currentInputSourceID: String = ""
    public private(set) var currentInputSourceType: String = ""
    public private(set) var isCurrentSourceForeign: Bool = false
    
    public var isCurrentSourceLatin: Bool {
        return !isCurrentSourceForeign
    }
    
    public var onInputSourceChanged: ((_ newSourceID: String, _ isForeign: Bool) -> Void)?
    
    private var isObserving: Bool = false
    private let lock = NSLock()
    
    public init() {
        _ = refreshCurrentInputSource()
        startObserving()
    }
    
    deinit {
        stopObserving()
    }
    
    public func startObserving() {
        guard !isObserving else { return }
        isObserving = true
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleNotification),
            name: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil,
            suspensionBehavior: .deliverImmediately
        )
    }
    
    public func stopObserving() {
        guard isObserving else { return }
        isObserving = false
        DistributedNotificationCenter.default().removeObserver(
            self,
            name: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil
        )
    }
    
    @objc private func handleNotification() {
        if Thread.isMainThread {
            _ = refreshCurrentInputSource()
        } else {
            DispatchQueue.main.async { [weak self] in
                _ = self?.refreshCurrentInputSource()
            }
        }
    }
    
    @discardableResult
    public func refreshCurrentInputSource() -> (sourceID: String, isForeign: Bool) {
        lock.lock()
        
        guard let currentSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            let id = currentInputSourceID
            let foreign = isCurrentSourceForeign
            lock.unlock()
            return (id, foreign)
        }
        
        var sourceID = ""
        var sourceType = ""
        
        if let idPtr = TISGetInputSourceProperty(currentSource, kTISPropertyInputSourceID) {
            sourceID = Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String
        }
        if let typePtr = TISGetInputSourceProperty(currentSource, kTISPropertyInputSourceType) {
            sourceType = Unmanaged<CFString>.fromOpaque(typePtr).takeUnretainedValue() as String
        }
        
        guard !sourceID.isEmpty else {
            let id = currentInputSourceID
            let foreign = isCurrentSourceForeign
            lock.unlock()
            return (id, foreign)
        }
        
        let foreign = InputSourceClassifier.isForeignInputSource(sourceID: sourceID, sourceType: sourceType)
        let changed = (sourceID != currentInputSourceID || foreign != isCurrentSourceForeign)
        
        currentInputSourceID = sourceID
        currentInputSourceType = sourceType
        isCurrentSourceForeign = foreign
        lock.unlock()
        
        if changed {
            onInputSourceChanged?(sourceID, foreign)
        }
        
        return (sourceID, foreign)
    }
    
    @discardableResult
    public func selectLatinInputSource() -> Bool {
        func findLatin(in list: [TISInputSource]) -> (selected: TISInputSource?, fallback: TISInputSource?) {
            var selectedSource: TISInputSource?
            var fallbackSource: TISInputSource?
            
            for source in list {
                if let capPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsSelectCapable) {
                    let isCap = CFBooleanGetValue(Unmanaged<CFBoolean>.fromOpaque(capPtr).takeUnretainedValue())
                    if !isCap { continue }
                }
                if let catPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceCategory) {
                    let cat = Unmanaged<CFString>.fromOpaque(catPtr).takeUnretainedValue() as String
                    if !cat.isEmpty && cat != (kTISCategoryKeyboardInputSource as String) {
                        continue
                    }
                }
                
                guard let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { continue }
                let id = Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String
                
                // Priority 1: com.apple.keylayout.ABC
                if id == "com.apple.keylayout.ABC" {
                    selectedSource = source
                    break
                }
                // Priority 2: com.apple.keylayout.US
                if id == "com.apple.keylayout.US" {
                    if selectedSource == nil {
                        selectedSource = source
                    }
                    continue
                }
                // Fallback: Any selectable Latin layout
                var type = ""
                if let typePtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceType) {
                    type = Unmanaged<CFString>.fromOpaque(typePtr).takeUnretainedValue() as String
                }
                if fallbackSource == nil && InputSourceClassifier.isLatinKeyboardLayout(sourceID: id, sourceType: type) {
                    fallbackSource = source
                }
            }
            return (selectedSource, fallbackSource)
        }
        
        var target: TISInputSource?
        
        if let list = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] {
            let (selected, fallback) = findLatin(in: list)
            target = selected ?? fallback
        }
        
        if target == nil, let listAll = TISCreateInputSourceList(nil, true)?.takeRetainedValue() as? [TISInputSource] {
            let (selected, fallback) = findLatin(in: listAll)
            target = selected ?? fallback
        }
        
        if target == nil, let enSource = TISCopyInputSourceForLanguage("en" as CFString)?.takeRetainedValue() {
            TISEnableInputSource(enSource)
            target = enSource
        }
        
        guard let finalTarget = target else {
            return false
        }
        
        if let bundleIDPtr = TISGetInputSourceProperty(finalTarget, kTISPropertyBundleID) {
            let bundleID = Unmanaged<CFString>.fromOpaque(bundleIDPtr).takeUnretainedValue() as String
            if !bundleID.isEmpty, let parentList = TISCreateInputSourceList([kTISPropertyBundleID as String: bundleID] as CFDictionary, true)?.takeRetainedValue() as? [TISInputSource] {
                for parent in parentList {
                    TISEnableInputSource(parent)
                }
            }
        }
        TISEnableInputSource(finalTarget)
        var status = TISSelectInputSource(finalTarget)
        if status != noErr {
            TISEnableInputSource(finalTarget)
            status = TISSelectInputSource(finalTarget)
        }
        if status == noErr {
            var targetID = ""
            var targetType = ""
            if let idPtr = TISGetInputSourceProperty(finalTarget, kTISPropertyInputSourceID) {
                targetID = Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String
            }
            if let typePtr = TISGetInputSourceProperty(finalTarget, kTISPropertyInputSourceType) {
                targetType = Unmanaged<CFString>.fromOpaque(typePtr).takeUnretainedValue() as String
            }
            if targetID.isEmpty {
                targetID = "com.apple.keylayout.ABC"
            }
            let foreign = InputSourceClassifier.isForeignInputSource(sourceID: targetID, sourceType: targetType)
            lock.lock()
            let changed = (targetID != currentInputSourceID || foreign != isCurrentSourceForeign)
            currentInputSourceID = targetID
            currentInputSourceType = targetType
            isCurrentSourceForeign = foreign
            lock.unlock()
            if changed {
                onInputSourceChanged?(targetID, foreign)
            }
            return true
        }
        return false
    }
    
    @discardableResult
    public func selectInputSource(byID sourceID: String) -> Bool {
        guard !sourceID.isEmpty else { return false }
        
        func findTarget(in list: [TISInputSource]) -> (exact: TISInputSource?, fallback: TISInputSource?) {
            var exact: TISInputSource?
            var fallback: TISInputSource?
            let isJapaneseRequested = sourceID.contains("Japanese") || sourceID.contains("Kotoeri")
            
            for source in list {
                if let capPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsSelectCapable) {
                    let isCap = CFBooleanGetValue(Unmanaged<CFBoolean>.fromOpaque(capPtr).takeUnretainedValue())
                    if !isCap { continue }
                }
                if let catPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceCategory) {
                    let cat = Unmanaged<CFString>.fromOpaque(catPtr).takeUnretainedValue() as String
                    if !cat.isEmpty && cat != (kTISCategoryKeyboardInputSource as String) {
                        continue
                    }
                }
                guard let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { continue }
                let id = Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String
                
                if id == sourceID {
                    exact = source
                    break
                }
                if isJapaneseRequested && fallback == nil {
                    if id.contains("Japanese") || id.contains("Kotoeri") {
                        fallback = source
                    }
                }
            }
            return (exact, fallback)
        }
        
        var target: TISInputSource?
        
        if let list = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] {
            let (exact, fallback) = findTarget(in: list)
            target = exact ?? fallback
        }
        
        if target == nil, let listAll = TISCreateInputSourceList(nil, true)?.takeRetainedValue() as? [TISInputSource] {
            let (exact, fallback) = findTarget(in: listAll)
            target = exact ?? fallback
        }
        
        guard let finalTarget = target else {
            return false
        }
        
        if let bundleIDPtr = TISGetInputSourceProperty(finalTarget, kTISPropertyBundleID) {
            let bundleID = Unmanaged<CFString>.fromOpaque(bundleIDPtr).takeUnretainedValue() as String
            if !bundleID.isEmpty, let parentList = TISCreateInputSourceList([kTISPropertyBundleID as String: bundleID] as CFDictionary, true)?.takeRetainedValue() as? [TISInputSource] {
                for parent in parentList {
                    TISEnableInputSource(parent)
                }
            }
        }
        TISEnableInputSource(finalTarget)
        var status = TISSelectInputSource(finalTarget)
        if status != noErr {
            TISEnableInputSource(finalTarget)
            status = TISSelectInputSource(finalTarget)
        }
        
        if status == noErr {
            var targetID = sourceID
            var targetType = ""
            if let idPtr = TISGetInputSourceProperty(finalTarget, kTISPropertyInputSourceID) {
                targetID = Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String
            }
            if let typePtr = TISGetInputSourceProperty(finalTarget, kTISPropertyInputSourceType) {
                targetType = Unmanaged<CFString>.fromOpaque(typePtr).takeUnretainedValue() as String
            }
            let foreign = InputSourceClassifier.isForeignInputSource(sourceID: targetID, sourceType: targetType)
            lock.lock()
            let changed = (targetID != currentInputSourceID || foreign != isCurrentSourceForeign)
            currentInputSourceID = targetID
            currentInputSourceType = targetType
            isCurrentSourceForeign = foreign
            lock.unlock()
            if changed {
                onInputSourceChanged?(targetID, foreign)
            }
            return true
        }
        return false
    }
}

public final class MockInputSourceManager: InputSourceManaging, @unchecked Sendable {
    public var currentInputSourceID: String
    public var currentInputSourceType: String
    public var isCurrentSourceForeign: Bool
    public var shouldSelectLatinSucceed: Bool = true
    public var shouldSelectForeignSucceed: Bool = true
    public var defaultLatinSourceID: String = "com.apple.keylayout.ABC"
    public var simulateAsyncSelectionDelay: Bool = false
    public var pendingSourceID: String? = nil
    
    public var isCurrentSourceLatin: Bool {
        return !isCurrentSourceForeign
    }
    
    public var onInputSourceChanged: ((_ newSourceID: String, _ isForeign: Bool) -> Void)?
    public var selectLatinCalled: Bool = false
    public var selectLatinCallCount: Int = 0
    public var selectInputSourceCalledWithID: String? = nil
    public var selectInputSourceCallCount: Int = 0
    
    public init(
        initialSourceID: String = "com.apple.keylayout.ABC",
        initialSourceType: String = "TISTypeKeyboardLayout",
        isForeign: Bool = false
    ) {
        self.currentInputSourceID = initialSourceID
        self.currentInputSourceType = initialSourceType
        self.isCurrentSourceForeign = isForeign
    }
    
    public func simulateInputSourceChange(to sourceID: String, sourceType: String = "") {
        let type = sourceType.isEmpty ? (sourceID.contains("keylayout") ? "TISTypeKeyboardLayout" : "TISTypeKeyboardInputMode") : sourceType
        let foreign = InputSourceClassifier.isForeignInputSource(sourceID: sourceID, sourceType: type)
        self.currentInputSourceID = sourceID
        self.currentInputSourceType = type
        self.isCurrentSourceForeign = foreign
        onInputSourceChanged?(sourceID, foreign)
    }
    
    public func flushPendingInputSourceChange() {
        if let pending = pendingSourceID {
            pendingSourceID = nil
            let type = pending.contains("keylayout") ? "TISTypeKeyboardLayout" : "TISTypeKeyboardInputMode"
            simulateInputSourceChange(to: pending, sourceType: type)
        }
    }
    
    @discardableResult
    public func selectLatinInputSource() -> Bool {
        selectLatinCalled = true
        selectLatinCallCount += 1
        guard shouldSelectLatinSucceed else {
            return false
        }
        if simulateAsyncSelectionDelay {
            pendingSourceID = defaultLatinSourceID
            return true
        }
        simulateInputSourceChange(to: defaultLatinSourceID, sourceType: "TISTypeKeyboardLayout")
        return true
    }
    
    @discardableResult
    public func selectInputSource(byID sourceID: String) -> Bool {
        selectInputSourceCalledWithID = sourceID
        selectInputSourceCallCount += 1
        guard shouldSelectForeignSucceed else {
            return false
        }
        if simulateAsyncSelectionDelay {
            pendingSourceID = sourceID
            return true
        }
        let type = sourceID.contains("keylayout") ? "TISTypeKeyboardLayout" : "TISTypeKeyboardInputMode"
        simulateInputSourceChange(to: sourceID, sourceType: type)
        return true
    }
    
    @discardableResult
    public func refreshCurrentInputSource() -> (sourceID: String, isForeign: Bool) {
        return (currentInputSourceID, isCurrentSourceForeign)
    }
    
    public func startObserving() {}
    public func stopObserving() {}
}
