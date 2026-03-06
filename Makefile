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
	@echo "  release BUMP=patch         Bump version, validate, tag, and push"
	@echo "                             BUMP = patch | minor | major"
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

BUMP ?= patch

.PHONY: release
release:
	@if [ -z "$(VERSION)" ]; then echo "Error: could not read version from pubspec.yaml"; exit 1; fi
	@MAJOR=$$(echo "$(VERSION)" | cut -d. -f1); \
	MINOR=$$(echo "$(VERSION)" | cut -d. -f2); \
	PATCH=$$(echo "$(VERSION)" | cut -d. -f3); \
	case "$(BUMP)" in \
		major) MAJOR=$$((MAJOR + 1)); MINOR=0; PATCH=0 ;; \
		minor) MINOR=$$((MINOR + 1)); PATCH=0 ;; \
		patch) PATCH=$$((PATCH + 1)) ;; \
		*) echo "Error: BUMP must be patch, minor, or major (got '$(BUMP)')"; exit 1 ;; \
	esac; \
	NEW_VERSION="$$MAJOR.$$MINOR.$$PATCH"; \
	echo "Bumping $(VERSION) → $$NEW_VERSION ($(BUMP))"; \
	echo ""; \
	echo "Updating pubspec.yaml..."; \
	sed -i '' "s/^version: $(VERSION)/version: $$NEW_VERSION/" pubspec.yaml; \
	echo "Updating ios/encore.podspec..."; \
	sed -i '' "s/s\.version *= *'[^']*'/s.version          = '$$NEW_VERSION'/" ios/encore.podspec; \
	echo "Updating android/build.gradle..."; \
	sed -i '' "s/^version = \"[^\"]*\"/version = \"$$NEW_VERSION\"/" android/build.gradle; \
	echo "Updating CHANGELOG.md..."; \
	printf "## $$NEW_VERSION\n\n* TODO: Add release notes.\n\n" | cat - CHANGELOG.md > CHANGELOG.tmp && mv CHANGELOG.tmp CHANGELOG.md; \
	echo ""; \
	echo "Committing version bump..."; \
	git add pubspec.yaml ios/encore.podspec android/build.gradle CHANGELOG.md; \
	git commit -m "release v$$NEW_VERSION"; \
	echo ""; \
	echo "Running dry-run validation..."; \
	flutter pub publish --dry-run || { \
		echo ""; \
		echo "Error: dry-run failed. Rolling back commit..."; \
		git reset --soft HEAD~1; \
		git checkout -- pubspec.yaml ios/encore.podspec android/build.gradle CHANGELOG.md; \
		exit 1; \
	}; \
	echo ""; \
	echo "Dry-run passed. Tagging and pushing v$$NEW_VERSION..."; \
	git tag "v$$NEW_VERSION"; \
	git push origin HEAD "v$$NEW_VERSION"; \
	echo ""; \
	echo "Released v$$NEW_VERSION. Workflow will run at:"; \
	echo "  https://github.com/EncoreKit/encore-flutter-sdk/actions"
