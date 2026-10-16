# VietFlow Makefile
# macOS Universal 2 (arm64 + x86_64) Build & Test Automation

SHELL := /bin/bash
BUILD_DIR := .build
VERSION ?= 1.2.97

.PHONY: all test app build package install clean help

all: test app

## test: Compile and execute the full test suite
test:
	@chmod +x Scripts/run_tests.sh
	@./Scripts/run_tests.sh $(ARGS)

## app: Build complete VietFlow.app Universal 2 bundle (arm64 + x86_64)
app:
	@chmod +x Scripts/build_app.sh
	@./Scripts/build_app.sh

## build: Build complete VietFlow.app Universal 2 bundle (alias for app)
build: app

## package: Package Universal 2 VietFlow.app into distributable zip archive
package: app
	@echo "==> Packaging VietFlow-v$(VERSION).zip..."
	@rm -f build/VietFlow-v$(VERSION).zip
	@ditto -c -k --sequesterRsrc --keepParent build/VietFlow.app build/VietFlow-v$(VERSION).zip
	@ls -lh build/VietFlow-v$(VERSION).zip
	@shasum -a 256 build/VietFlow-v$(VERSION).zip

## install: Install VietFlow.app into /Applications
install: app
	@echo "==> Installing VietFlow.app into /Applications..."
	@rm -rf /Applications/VietFlow.app
	@cp -R build/VietFlow.app /Applications/VietFlow.app
	@echo "==> VietFlow.app successfully installed in /Applications!"

## clean: Remove all build artifacts
clean:
	@rm -rf $(BUILD_DIR) build AppIcon.iconset
	@echo "Cleaned build artifacts."

## help: Display this help message
help:
	@echo "VietFlow Build & Test Targets:"
	@echo "  make test      - Compile and run 1,499 test cases across 17 suites"
	@echo "  make app       - Build Universal 2 VietFlow.app bundle (arm64 + x86_64)"
	@echo "  make package   - Package Universal 2 VietFlow-v$(VERSION).zip release archive"
	@echo "  make install   - Build and install VietFlow.app into /Applications"
	@echo "  make clean     - Clean build directories"
	@echo "  make help      - Show this help message"
