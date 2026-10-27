# FocusApp — developer entrypoints
#
# Two commands to a running app:
#   make setup
#   make demo

SIM ?= iPhone 17
SCHEME_DEMO = FocusApp (Demo)
SCHEME_REAL = FocusApp (Real)
BUNDLE_ID = com.ismail.focusapp
DERIVED = build
APP = $(DERIVED)/Build/Products/Demo-iphonesimulator/FocusApp.app

.PHONY: help setup generate demo build-demo build test open clean doctor

help:
	@echo "make setup   - install XcodeGen, generate the Xcode project"
	@echo "make demo    - build + run Demo Mode in the simulator (no account needed)"
	@echo "make build   - build the real configuration (needs paid account + entitlement)"
	@echo "make open    - open the generated project in Xcode"
	@echo "make doctor  - check your toolchain"

setup: generate
	@test -f Local.xcconfig || (cp Local.xcconfig.example Local.xcconfig && echo "Created Local.xcconfig — add your DEVELOPMENT_TEAM for real builds")
	@echo "Ready. Run 'make demo'."

generate:
	@command -v xcodegen >/dev/null 2>&1 || brew install xcodegen
	@test -f Local.xcconfig || cp Local.xcconfig.example Local.xcconfig
	xcodegen generate

build-demo: generate
	xcodebuild \
		-scheme "$(SCHEME_DEMO)" \
		-configuration Demo \
		-destination "platform=iOS Simulator,name=$(SIM)" \
		-derivedDataPath $(DERIVED) \
		CODE_SIGNING_ALLOWED=NO \
		build

demo: build-demo
	-xcrun simctl boot "$(SIM)"
	open -a Simulator
	xcrun simctl install booted "$(APP)"
	xcrun simctl launch booted $(BUNDLE_ID)

build: generate
	xcodebuild \
		-scheme "$(SCHEME_REAL)" \
		-configuration Debug \
		-destination "generic/platform=iOS" \
		build

test: generate
	@echo "No tests yet — spike stage."

open: generate
	open FocusApp.xcodeproj

clean:
	rm -rf $(DERIVED) FocusApp.xcodeproj

doctor:
	@if xcodebuild -version >/dev/null 2>&1; then \
		echo "Xcode:    $$(xcodebuild -version | head -1)"; \
	else \
		echo "Xcode:    NOT INSTALLED (Command Line Tools only) — install Xcode from the App Store"; \
	fi
	@echo "XcodeGen: $$(xcodegen --version 2>/dev/null || echo 'not installed — run make setup')"
	@echo "Team ID:  $$(grep DEVELOPMENT_TEAM Local.xcconfig 2>/dev/null || echo 'no Local.xcconfig (fine for demo mode)')"
