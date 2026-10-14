#!/usr/bin/env bash
#
# Scripts/run_tests.sh
# Automated CLI Test Runner for VietFlow (macOS arm64 / x86_64)
#

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# 1. Determine Appropriate macOS SDK
if [ -d "/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk" ]; then
    SDK_PATH="/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk"
elif [ -d "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk" ]; then
    SDK_PATH="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"
else
    SDK_PATH="$(xcrun --show-sdk-path 2>/dev/null || true)"
fi

SDK_FLAG=""
if [ -n "$SDK_PATH" ] && [ -d "$SDK_PATH" ]; then
    SDK_FLAG="-sdk $SDK_PATH"
fi

BUILD_DIR="$REPO_ROOT/.build"
mkdir -p "$BUILD_DIR"

echo "==> Step 1: Compiling VietFlowEngine module..."
swiftc $SDK_FLAG \
    -O \
    -emit-library \
    -emit-module \
    -module-name VietFlowEngine \
    -emit-module-path "$BUILD_DIR/VietFlowEngine.swiftmodule" \
    Sources/VietFlowEngine/*.swift \
    -o "$BUILD_DIR/libVietFlowEngine.dylib"

echo "==> Step 2: Compiling VietFlowState module..."
swiftc $SDK_FLAG \
    -O \
    -emit-library \
    -emit-module \
    -module-name VietFlowState \
    -I "$BUILD_DIR" -L "$BUILD_DIR" -lVietFlowEngine \
    -emit-module-path "$BUILD_DIR/VietFlowState.swiftmodule" \
    Sources/VietFlowState/*.swift \
    -o "$BUILD_DIR/libVietFlowState.dylib"

echo "==> Step 3: Compiling VietFlowEventTap module..."
swiftc $SDK_FLAG \
    -O \
    -emit-library \
    -emit-module \
    -module-name VietFlowEventTap \
    -I "$BUILD_DIR" -L "$BUILD_DIR" -lVietFlowEngine -lVietFlowState \
    -emit-module-path "$BUILD_DIR/VietFlowEventTap.swiftmodule" \
    Sources/VietFlowEventTap/*.swift \
    -o "$BUILD_DIR/libVietFlowEventTap.dylib"

echo "==> Step 3b: Compiling VietFlowApp module..."
swiftc $SDK_FLAG \
    -O \
    -emit-library \
    -emit-module \
    -module-name VietFlowApp \
    -I "$BUILD_DIR" -L "$BUILD_DIR" -lVietFlowEngine -lVietFlowState -lVietFlowEventTap \
    -emit-module-path "$BUILD_DIR/VietFlowApp.swiftmodule" \
    Sources/VietFlowApp/AccessibilityService.swift \
    Sources/VietFlowApp/KeyCombinationHelper.swift \
    Sources/VietFlowApp/PreferencesView.swift \
    Sources/VietFlowApp/PreferencesWindowController.swift \
    Sources/VietFlowApp/SettingsView.swift \
    Sources/VietFlowApp/SettingsWindowController.swift \
    Sources/VietFlowApp/StatusBarController.swift \
    Sources/VietFlowApp/AppDelegate.swift \
    -o "$BUILD_DIR/libVietFlowApp.dylib"

echo "==> Step 4: Compiling VietFlowEngineTests module..."
swiftc $SDK_FLAG \
    -O \
    -emit-library \
    -emit-module \
    -module-name VietFlowEngineTests \
    -I "$BUILD_DIR" -L "$BUILD_DIR" -lVietFlowEngine -lVietFlowState \
    -emit-module-path "$BUILD_DIR/VietFlowEngineTests.swiftmodule" \
    Tests/VietFlowEngineTests/TestFramework.swift \
    Tests/VietFlowEngineTests/BasicTelexTests.swift \
    Tests/VietFlowEngineTests/SimpleTelexTests.swift \
    Tests/VietFlowEngineTests/VNITests.swift \
    Tests/VietFlowEngineTests/TonePlacementTests.swift \
    Tests/VietFlowEngineTests/DiacriticUndoTests.swift \
    Tests/VietFlowEngineTests/EnglishRestoreTests.swift \
    Tests/VietFlowEngineTests/RapidTypingTests.swift \
    Tests/VietFlowEngineTests/MinimalDiffTests.swift \
    Tests/VietFlowEngineTests/ModeToggleBufferResetTests.swift \
    Tests/VietFlowEngineTests/RealWorldTypingAndBackspaceTests.swift \
    -o "$BUILD_DIR/libVietFlowEngineTests.dylib"

echo "==> Step 5: Compiling VietFlowTerminalBufferTests module..."
swiftc $SDK_FLAG \
    -O \
    -emit-library \
    -emit-module \
    -module-name VietFlowTerminalBufferTests \
    -I "$BUILD_DIR" -L "$BUILD_DIR" -lVietFlowEngine -lVietFlowEngineTests \
    -emit-module-path "$BUILD_DIR/VietFlowTerminalBufferTests.swiftmodule" \
    Tests/VietFlowTerminalBufferTests/TerminalBufferSimulator.swift \
    Tests/VietFlowTerminalBufferTests/TerminalCompatibilityTests.swift \
    -o "$BUILD_DIR/libVietFlowTerminalBufferTests.dylib"

echo "==> Step 6: Compiling VietFlowStateTests module..."
swiftc $SDK_FLAG \
    -O \
    -emit-library \
    -emit-module \
    -module-name VietFlowStateTests \
    -I "$BUILD_DIR" -L "$BUILD_DIR" -lVietFlowEngine -lVietFlowState -lVietFlowEngineTests \
    -emit-module-path "$BUILD_DIR/VietFlowStateTests.swiftmodule" \
    Tests/VietFlowStateTests/SettingsPersistenceTests.swift \
    -o "$BUILD_DIR/libVietFlowStateTests.dylib"

echo "==> Step 7: Compiling VietFlowEventTapTests module..."
swiftc $SDK_FLAG \
    -O \
    -emit-library \
    -emit-module \
    -module-name VietFlowEventTapTests \
    -I "$BUILD_DIR" -L "$BUILD_DIR" -lVietFlowEngine -lVietFlowState -lVietFlowEventTap -lVietFlowEngineTests \
    -emit-module-path "$BUILD_DIR/VietFlowEventTapTests.swiftmodule" \
    Tests/VietFlowEventTapTests/HotkeyStateMachineTests.swift \
    Tests/VietFlowEventTapTests/InputSourceSynchronizationTests.swift \
    -o "$BUILD_DIR/libVietFlowEventTapTests.dylib"

echo "==> Step 7b: Compiling SettingsLayoutTests module..."
swiftc $SDK_FLAG \
    -O \
    -emit-library \
    -emit-module \
    -module-name SettingsLayoutTests \
    -I "$BUILD_DIR" -L "$BUILD_DIR" \
    -lVietFlowEngine -lVietFlowState -lVietFlowEventTap -lVietFlowApp -lVietFlowEngineTests \
    -emit-module-path "$BUILD_DIR/SettingsLayoutTests.swiftmodule" \
    Tests/SettingsLayoutTests.swift \
    -o "$BUILD_DIR/libSettingsLayoutTests.dylib"

echo "==> Step 8: Compiling TestRunner executable..."
TEST_BINARY="$BUILD_DIR/vietflow_test_runner"
swiftc $SDK_FLAG \
    -O \
    -parse-as-library \
    -I "$BUILD_DIR" -L "$BUILD_DIR" \
    -lVietFlowEngine -lVietFlowState -lVietFlowEventTap -lVietFlowApp \
    -lVietFlowEngineTests -lVietFlowTerminalBufferTests \
    -lVietFlowStateTests -lVietFlowEventTapTests -lSettingsLayoutTests \
    -Xlinker -rpath -Xlinker "@loader_path" \
    -Xlinker -rpath -Xlinker "$BUILD_DIR" \
    Tests/TestRunnerMain.swift \
    -o "$TEST_BINARY"

echo "==> Compilation successful: $TEST_BINARY"
echo "==> Executing test runner..."
"$TEST_BINARY" "$@"
