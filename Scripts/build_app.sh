#!/usr/bin/env bash
#
# Scripts/build_app.sh
# Universal 2 (arm64 + x86_64) Builder and Packager for VietFlow.app
#

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# 1. Select proper macOS SDK
if [ -d "/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk" ]; then
    SDK_PATH="/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk"
elif [ -d "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk" ]; then
    SDK_PATH="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"
else
    SDK_PATH="$(xcrun --show-sdk-path 2>/dev/null || true)"
fi

SDK_FLAG="-sdk $SDK_PATH"
MIN_MACOS="13.0"

BUILD_DIR="$REPO_ROOT/build"
STAGE_ARM64="$BUILD_DIR/arm64"
STAGE_X86_64="$BUILD_DIR/x86_64"
APP_DIR="$BUILD_DIR/VietFlow.app"

rm -rf "$STAGE_ARM64" "$STAGE_X86_64" "$BUILD_DIR/universal"
mkdir -p "$STAGE_ARM64" "$STAGE_X86_64"

echo "================================================================================"
echo " Building VietFlow Universal 2 (macOS $MIN_MACOS+ | arm64 + x86_64)"
echo "================================================================================"

# Function to compile a single architecture
build_arch() {
    local ARCH="$1"
    local TARGET="${ARCH}-apple-macos${MIN_MACOS}"
    local OUT_DIR="$2"
    
    echo "==> [${ARCH}] Step 1: Compiling VietFlowEngine..."
    swiftc $SDK_FLAG -target "$TARGET" -O -emit-library -static \
        -module-name VietFlowEngine \
        -emit-module -emit-module-path "$OUT_DIR/VietFlowEngine.swiftmodule" \
        Sources/VietFlowEngine/*.swift \
        -o "$OUT_DIR/libVietFlowEngine.a"

    echo "==> [${ARCH}] Step 2: Compiling VietFlowState..."
    swiftc $SDK_FLAG -target "$TARGET" -O -emit-library -static \
        -module-name VietFlowState \
        -I "$OUT_DIR" \
        -emit-module -emit-module-path "$OUT_DIR/VietFlowState.swiftmodule" \
        Sources/VietFlowState/*.swift \
        -o "$OUT_DIR/libVietFlowState.a"

    echo "==> [${ARCH}] Step 3: Compiling VietFlowEventTap..."
    swiftc $SDK_FLAG -target "$TARGET" -O -emit-library -static \
        -module-name VietFlowEventTap \
        -I "$OUT_DIR" \
        -emit-module -emit-module-path "$OUT_DIR/VietFlowEventTap.swiftmodule" \
        Sources/VietFlowEventTap/*.swift \
        -o "$OUT_DIR/libVietFlowEventTap.a"

    echo "==> [${ARCH}] Step 4: Compiling VietFlow App Binary..."
    swiftc $SDK_FLAG -target "$TARGET" -O \
        -I "$OUT_DIR" \
        "$OUT_DIR/libVietFlowEngine.a" \
        "$OUT_DIR/libVietFlowState.a" \
        "$OUT_DIR/libVietFlowEventTap.a" \
        Sources/VietFlowApp/*.swift \
        -o "$OUT_DIR/VietFlow"
}

# Build for Apple Silicon (M1/M2/M3/M4)
build_arch "arm64" "$STAGE_ARM64"

# Build for Intel (MacBook Pro 2020)
build_arch "x86_64" "$STAGE_X86_64"

echo "==> Assembling Universal 2 Fat Binary via lipo..."
mkdir -p "$BUILD_DIR/universal"
lipo -create \
    "$STAGE_ARM64/VietFlow" \
    "$STAGE_X86_64/VietFlow" \
    -output "$BUILD_DIR/universal/VietFlow"

echo "==> Verifying Universal Binary architectures:"
lipo -info "$BUILD_DIR/universal/VietFlow"

echo "==> Packaging VietFlow.app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy binary
cp "$BUILD_DIR/universal/VietFlow" "$APP_DIR/Contents/MacOS/VietFlow"
chmod +x "$APP_DIR/Contents/MacOS/VietFlow"

# Copy Info.plist
cp "$REPO_ROOT/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"

# Generate and Copy AppIcon.icns if needed
if [ ! -f "$REPO_ROOT/AppIcon.icns" ]; then
    echo "==> Generating AppIcon.icns..."
    swift -sdk "$SDK_PATH" "$REPO_ROOT/Scripts/generate_app_icon.swift"
fi
cp "$REPO_ROOT/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"

echo "==> Signing VietFlow.app bundle (ad-hoc)..."
codesign --force --deep --sign - "$APP_DIR"

echo "================================================================================"
echo " VietFlow.app successfully built at: $APP_DIR"
echo " Architectures: $(lipo -archs "$APP_DIR/Contents/MacOS/VietFlow")"
echo " Code signature: $(codesign -v "$APP_DIR" && echo 'Valid')"
echo "================================================================================"
