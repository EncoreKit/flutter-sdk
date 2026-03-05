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
	@echo "  release                    Tag and push to trigger release workflow"
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
	@if [ -z "$(VERSION)" ]; then echo "Error: could not read version from pubspec.yaml"; exit 1; fi
	@echo "Releasing v$(VERSION)..."
	@if git tag --list | grep -q "^v$(VERSION)$$"; then \
		echo "Error: tag v$(VERSION) already exists. Bump the version in pubspec.yaml first."; \
		exit 1; \
	fi
	git tag v$(VERSION)
	git push origin v$(VERSION)
	@echo "Tagged and pushed v$(VERSION). Release workflow will run at:"
	@echo "  https://github.com/EncoreKit/encore-flutter-sdk/actions"
