# VietFlow Makefile
# macOS Universal 2 (arm64 + x86_64) Build & Test Automation

SHELL := /bin/bash
BUILD_DIR := .build

.PHONY: all test app install clean help

all: test app

## test: Compile and execute the full 840 test suite and terminal simulator
test:
	@chmod +x Scripts/run_tests.sh
	@./Scripts/run_tests.sh $(ARGS)

## app: Build complete VietFlow.app Universal 2 bundle (arm64 + x86_64)
app:
	@chmod +x Scripts/build_app.sh
	@./Scripts/build_app.sh

## demo: Launch interactive Terminal real-time typing demo
demo:
	@./build/vietflow_cli

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
	@echo "  make test      - Compile and run 840 test cases via CLI test runner"
	@echo "  make app       - Build Universal 2 VietFlow.app bundle (arm64 + x86_64)"
	@echo "  make install   - Build and install VietFlow.app into /Applications"
	@echo "  make clean     - Clean build directories"
	@echo "  make help      - Show this help message"
