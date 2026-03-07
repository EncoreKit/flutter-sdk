SHELL := /bin/bash
.DEFAULT_GOAL := help

VERSION := $(shell grep '^version:' pubspec.yaml | awk '{print $$2}')

.PHONY: help
help:
	@echo "Encore Flutter SDK"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Development:"
	@echo "  test                       Run Dart unit tests"
	@echo "  analyze                    Run Flutter analyzer"
	@echo "  build-ios                  Build iOS example app"
	@echo "  build-android              Build Android example app"
	@echo ""
	@echo "Release:"
	@echo "  release                    Interactive release: bump version, validate, tag, and push"
	@echo "  dry-run                    Validate package for pub.dev"
	@echo ""
	@echo "Current version: $(VERSION)"

.PHONY: test
test:
	flutter test

.PHONY: analyze
analyze:
	flutter analyze --no-fatal-infos

.PHONY: build-ios
build-ios:
	cd example && flutter build ios --no-codesign

.PHONY: build-android
build-android:
	cd example && flutter build apk --debug

.PHONY: dry-run
dry-run:
	flutter pub publish --dry-run

.PHONY: release
release:
	@bash scripts/release/publish-release.sh
