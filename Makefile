# FocusApp — a standalone Apple Watch focus timer
#
#   make setup   generate the Xcode project
#   make run     build + launch in the watch simulator
#
# NOTE ON THE BUILD DIRECTORY
# This repo lives under ~/Documents, which is iCloud-synced on macOS. iCloud's
# file provider stamps com.apple.FinderInfo onto files it touches, and codesign
# refuses to sign any bundle carrying Finder info ("resource fork, Finder
# information, or similar detritus not allowed"). Clearing the attributes
# doesn't help — they come straight back. So DERIVED must stay outside any
# synced folder.

SIM ?= Apple Watch Series 11 (46mm)
SCHEME = FocusAppWatch
BUNDLE_ID = com.ismail.focusapp.watchkitapp
DERIVED = $(HOME)/Library/Developer/Xcode/DerivedData/FocusApp-cli
APP = $(DERIVED)/Build/Products/Debug-watchsimulator/FocusAppWatch.app

.PHONY: help setup generate build run open clean doctor

help:
	@echo "make setup  - install XcodeGen and generate the project"
	@echo "make run    - build and launch in the watch simulator"
	@echo "make build  - build only"
	@echo "make open   - open in Xcode"
	@echo "make doctor - check the toolchain"

setup: generate
	@echo "Ready. Run 'make run'."

generate:
	@command -v xcodegen >/dev/null 2>&1 || brew install xcodegen
	@test -f Local.xcconfig || cp Local.xcconfig.example Local.xcconfig
	xcodegen generate

build: generate
	xcodebuild \
		-scheme "$(SCHEME)" \
		-configuration Debug \
		-destination "platform=watchOS Simulator,name=$(SIM)" \
		-derivedDataPath "$(DERIVED)" \
		build

run: build
	-xcrun simctl boot "$(SIM)"
	open -a Simulator
	xcrun simctl install "$(SIM)" "$(APP)"
	xcrun simctl launch "$(SIM)" $(BUNDLE_ID)

open: generate
	open FocusApp.xcodeproj

clean:
	rm -rf "$(DERIVED)" FocusApp.xcodeproj

doctor:
	@if xcodebuild -version >/dev/null 2>&1; then \
		echo "Xcode:    $$(xcodebuild -version | head -1)"; \
	else \
		echo "Xcode:    NOT INSTALLED - install Xcode from the App Store"; \
	fi
	@echo "XcodeGen: $$(xcodegen --version 2>/dev/null || echo 'not installed - run make setup')"
	@echo "watchOS SDK: $$(xcodebuild -showsdks 2>/dev/null | grep watchos | head -1 | xargs || echo unknown)"
