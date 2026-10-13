#!/usr/bin/env bash
#
# Scripts/build_universal.sh
# Universal 2 (arm64 + x86_64) Binary Builder for VietFlowEngine
# Target deployment: macOS 13.0+
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

BUILD_DIR="$REPO_ROOT/build"
ARM64_DIR="$BUILD_DIR/arm64"
X86_64_DIR="$BUILD_DIR/x86_64"
UNIVERSAL_DIR="$BUILD_DIR/universal"

mkdir -p "$ARM64_DIR" "$X86_64_DIR" "$UNIVERSAL_DIR"

echo "==> Step 1: Compiling arm64 slice (macOS 13.0+)..."
swiftc $SDK_FLAG \
    -target arm64-apple-macosx13.0 \
    -O \
    -emit-library \
    -emit-module \
    -module-name VietFlowEngine \
    -emit-module-path "$ARM64_DIR/VietFlowEngine.swiftmodule" \
    Sources/VietFlowEngine/*.swift \
    -o "$ARM64_DIR/libVietFlowEngine.dylib"

echo "==> Step 2: Compiling x86_64 slice (macOS 13.0+)..."
swiftc $SDK_FLAG \
    -target x86_64-apple-macosx13.0 \
    -O \
    -emit-library \
    -emit-module \
    -module-name VietFlowEngine \
    -emit-module-path "$X86_64_DIR/VietFlowEngine.swiftmodule" \
    Sources/VietFlowEngine/*.swift \
    -o "$X86_64_DIR/libVietFlowEngine.dylib"

echo "==> Step 3: Creating Universal 2 fat binary via lipo..."
UNIVERSAL_DYLIB="$UNIVERSAL_DIR/libVietFlowEngine.dylib"
lipo -create \
    "$ARM64_DIR/libVietFlowEngine.dylib" \
    "$X86_64_DIR/libVietFlowEngine.dylib" \
    -output "$UNIVERSAL_DYLIB"

echo "==> Step 4: Merging Swift module interfaces..."
UNIVERSAL_MODULE_DIR="$UNIVERSAL_DIR/VietFlowEngine.swiftmodule"
mkdir -p "$UNIVERSAL_MODULE_DIR"
cp -r "$ARM64_DIR/VietFlowEngine.swiftmodule"/* "$UNIVERSAL_MODULE_DIR/" 2>/dev/null || cp "$ARM64_DIR/VietFlowEngine.swiftmodule" "$UNIVERSAL_MODULE_DIR/arm64-apple-macos.swiftmodule"
cp -r "$X86_64_DIR/VietFlowEngine.swiftmodule"/* "$UNIVERSAL_MODULE_DIR/" 2>/dev/null || cp "$X86_64_DIR/VietFlowEngine.swiftmodule" "$UNIVERSAL_MODULE_DIR/x86_64-apple-macos.swiftmodule"

echo "==> Universal 2 Binary created successfully at: $UNIVERSAL_DYLIB"
echo "==> Binary inspection via lipo:"
lipo -info "$UNIVERSAL_DYLIB"
