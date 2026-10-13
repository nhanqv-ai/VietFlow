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

echo "==> Step 2: Compiling VietFlowEngineTests module..."
swiftc $SDK_FLAG \
    -O \
    -emit-library \
    -emit-module \
    -module-name VietFlowEngineTests \
    -I "$BUILD_DIR" -L "$BUILD_DIR" -lVietFlowEngine \
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
    -o "$BUILD_DIR/libVietFlowEngineTests.dylib"

echo "==> Step 3: Compiling VietFlowTerminalBufferTests module..."
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

echo "==> Step 4: Compiling TestRunner executable..."
TEST_BINARY="$BUILD_DIR/vietflow_test_runner"
swiftc $SDK_FLAG \
    -O \
    -parse-as-library \
    -I "$BUILD_DIR" -L "$BUILD_DIR" \
    -lVietFlowEngine -lVietFlowEngineTests -lVietFlowTerminalBufferTests \
    -Xlinker -rpath -Xlinker "@loader_path" \
    -Xlinker -rpath -Xlinker "$BUILD_DIR" \
    Tests/TestRunnerMain.swift \
    -o "$TEST_BINARY"

echo "==> Compilation successful: $TEST_BINARY"
echo "==> Executing test runner..."
"$TEST_BINARY" "$@"
