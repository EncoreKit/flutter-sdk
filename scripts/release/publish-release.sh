#!/bin/bash
# scripts/release/publish-release.sh
# Interactive release script with semantic versioning for Encore Flutter SDK

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Encore Flutter SDK Release Manager${NC}"
echo ""

# Step 1: Check we're on main and up to date
echo -e "${BLUE}📦 Step 1: Checking repository state...${NC}"

CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo -e "${RED}❌ Error: Must be on main branch (currently on $CURRENT_BRANCH)${NC}"
    exit 1
fi

git fetch origin main --tags --force
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u})
if [ "$LOCAL" != "$REMOTE" ]; then
    echo -e "${RED}❌ Error: Local main is out of sync with remote${NC}"
    echo "   Run: git pull origin main"
    exit 1
fi

if ! git diff-index --quiet HEAD --; then
    echo -e "${RED}❌ Error: You have uncommitted changes${NC}"
    echo "   Commit or stash your changes before releasing"
    exit 1
fi

echo -e "${GREEN}✅ Repository is clean and up to date${NC}"
echo ""

# Step 2: Get current version from pubspec.yaml
echo -e "${BLUE}📋 Step 2: Detecting current version...${NC}"

CURRENT_VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')
if [ -z "$CURRENT_VERSION" ]; then
    echo -e "${RED}❌ Error: Could not read version from pubspec.yaml${NC}"
    exit 1
fi

echo -e "   Current version: ${GREEN}v$CURRENT_VERSION${NC}"

CURRENT_MAJOR=$(echo "$CURRENT_VERSION" | cut -d'.' -f1)
CURRENT_MINOR=$(echo "$CURRENT_VERSION" | cut -d'.' -f2)
CURRENT_PATCH=$(echo "$CURRENT_VERSION" | cut -d'.' -f3)

echo ""

# Step 3: Enter new version
echo -e "${BLUE}📊 Step 3: Enter the new version number${NC}"
echo ""
echo -e "   Current version: ${GREEN}v$CURRENT_VERSION${NC}"
echo -e "   Shortcuts:       ${YELLOW}patch${NC} → v${CURRENT_MAJOR}.${CURRENT_MINOR}.$((CURRENT_PATCH + 1))"
echo -e "                    ${YELLOW}minor${NC} → v${CURRENT_MAJOR}.$((CURRENT_MINOR + 1)).0"
echo -e "                    ${YELLOW}major${NC} → v$((CURRENT_MAJOR + 1)).0.0"
echo ""

read -p "Enter version (e.g. 1.4.0) or shortcut (patch/minor/major): " VERSION_INPUT

case $VERSION_INPUT in
    patch)
        NEW_MAJOR=$CURRENT_MAJOR
        NEW_MINOR=$CURRENT_MINOR
        NEW_PATCH=$((CURRENT_PATCH + 1))
        ;;
    minor)
        NEW_MAJOR=$CURRENT_MAJOR
        NEW_MINOR=$((CURRENT_MINOR + 1))
        NEW_PATCH=0
        ;;
    major)
        NEW_MAJOR=$((CURRENT_MAJOR + 1))
        NEW_MINOR=0
        NEW_PATCH=0
        ;;
    *)
        VERSION_INPUT="${VERSION_INPUT#v}"

        if ! echo "$VERSION_INPUT" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
            echo -e "${RED}❌ Invalid format. Expected X.Y.Z (e.g. 1.4.0)${NC}"
            exit 1
        fi

        NEW_MAJOR=$(echo "$VERSION_INPUT" | cut -d'.' -f1)
        NEW_MINOR=$(echo "$VERSION_INPUT" | cut -d'.' -f2)
        NEW_PATCH=$(echo "$VERSION_INPUT" | cut -d'.' -f3)
        ;;
esac

NEW_VERSION="${NEW_MAJOR}.${NEW_MINOR}.${NEW_PATCH}"

CURRENT_WEIGHT=$(( CURRENT_MAJOR * 1000000 + CURRENT_MINOR * 1000 + CURRENT_PATCH ))
NEW_WEIGHT=$(( NEW_MAJOR * 1000000 + NEW_MINOR * 1000 + NEW_PATCH ))

if [ "$NEW_WEIGHT" -le "$CURRENT_WEIGHT" ]; then
    echo -e "${RED}❌ New version v$NEW_VERSION must be greater than current v$CURRENT_VERSION${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Next version: v$NEW_VERSION${NC}"
echo ""

# Step 4: Update version in all files
echo -e "${BLUE}📝 Step 4: Updating version references...${NC}"

echo "   Updating pubspec.yaml..."
sed -i '' "s/^version: $CURRENT_VERSION/version: $NEW_VERSION/" pubspec.yaml

echo "   Updating ios/encore.podspec..."
sed -i '' "s/s\.version *= *'[^']*'/s.version          = '$NEW_VERSION'/" ios/encore.podspec

echo "   Updating android/build.gradle..."
sed -i '' "s/^version = \"[^\"]*\"/version = \"$NEW_VERSION\"/" android/build.gradle

echo "   Updating CHANGELOG.md..."
printf "## $NEW_VERSION\n\n* TODO: Add release notes.\n\n" | cat - CHANGELOG.md > CHANGELOG.tmp && mv CHANGELOG.tmp CHANGELOG.md

echo -e "${GREEN}✅ All files updated${NC}"
echo ""

# Step 5: Commit
echo -e "${BLUE}📦 Step 5: Committing version bump...${NC}"
git add pubspec.yaml ios/encore.podspec android/build.gradle CHANGELOG.md
git commit -m "release v$NEW_VERSION"
echo -e "${GREEN}✅ Committed${NC}"
echo ""

# Step 6: Dry-run validation
echo -e "${BLUE}🧪 Step 6: Running dry-run validation...${NC}"
if ! flutter pub publish --dry-run; then
    echo ""
    echo -e "${RED}❌ Dry-run failed. Rolling back commit...${NC}"
    git reset --soft HEAD~1
    git checkout -- pubspec.yaml ios/encore.podspec android/build.gradle CHANGELOG.md
    exit 1
fi
echo -e "${GREEN}✅ Dry-run passed${NC}"
echo ""

# Step 7: Tag and push
echo -e "${BLUE}🏷️  Step 7: Tagging and pushing v$NEW_VERSION...${NC}"
git tag "v$NEW_VERSION"
git push origin HEAD "v$NEW_VERSION"
echo ""
echo -e "${GREEN}🎉 Released v$NEW_VERSION${NC}"
echo -e "   Workflow will run at:"
echo -e "   ${BLUE}https://github.com/EncoreKit/encore-flutter-sdk/actions${NC}"
