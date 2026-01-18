#!/bin/bash
# =============================================================================
# IdleFarm Roguelike - Godot Library Build for Mobile
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
GODOT_DIR="$PROJECT_ROOT/godot"
BUILD_DIR="$PROJECT_ROOT/build/mobile"
MOBILE_DIR="$PROJECT_ROOT/mobile"

# Defaults
PLATFORM=""
GODOT_PATH="godot"
ARCH="arm64"

# =============================================================================
# Functions
# =============================================================================

print_header() {
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${BLUE}  IdleFarm Roguelike - Mobile Library Build${NC}"
    echo -e "${BLUE}=================================================${NC}"
}

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --platform       Target platform (ios, android)"
    echo "  --arch           Architecture (arm64, x86_64)"
    echo "  --godot PATH     Path to Godot executable"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --platform ios"
    echo "  $0 --platform android --arch arm64"
}

check_godot() {
    if ! command -v "$GODOT_PATH" &> /dev/null; then
        echo -e "${RED}Error: Godot not found at '$GODOT_PATH'${NC}"
        exit 1
    fi
    echo -e "${GREEN}Using Godot: $GODOT_PATH${NC}"
}

setup_directories() {
    echo -e "${YELLOW}Setting up build directories...${NC}"
    mkdir -p "$BUILD_DIR/$PLATFORM"
}

export_pck() {
    echo -e "${YELLOW}Exporting PCK file...${NC}"

    cd "$GODOT_DIR"

    local pck_path="$BUILD_DIR/$PLATFORM/game.pck"

    # Export resources only (PCK)
    "$GODOT_PATH" --headless --export-pack "Mobile" "$pck_path"

    if [ -f "$pck_path" ]; then
        echo -e "${GREEN}PCK exported: $pck_path${NC}"
        local size=$(du -h "$pck_path" | cut -f1)
        echo "Size: $size"
    else
        echo -e "${RED}PCK export failed!${NC}"
        exit 1
    fi
}

build_ios() {
    echo -e "${YELLOW}Building iOS library...${NC}"

    # Check for Xcode
    if ! command -v xcodebuild &> /dev/null; then
        echo -e "${RED}Error: Xcode command line tools not found${NC}"
        exit 1
    fi

    export_pck

    # Copy PCK to mobile project
    local dest="$MOBILE_DIR/ios/assets"
    mkdir -p "$dest"
    cp "$BUILD_DIR/ios/game.pck" "$dest/"

    echo -e "${GREEN}iOS library ready${NC}"
    echo "PCK copied to: $dest/game.pck"
    echo ""
    echo "Next steps:"
    echo "1. cd $MOBILE_DIR"
    echo "2. pnpm ios"
}

build_android() {
    echo -e "${YELLOW}Building Android library...${NC}"

    # Check for Android SDK
    if [ -z "$ANDROID_HOME" ]; then
        echo -e "${RED}Error: ANDROID_HOME not set${NC}"
        exit 1
    fi

    export_pck

    # Copy PCK to mobile project
    local dest="$MOBILE_DIR/android/app/src/main/assets"
    mkdir -p "$dest"
    cp "$BUILD_DIR/android/game.pck" "$dest/"

    echo -e "${GREEN}Android library ready${NC}"
    echo "PCK copied to: $dest/game.pck"
    echo ""
    echo "Next steps:"
    echo "1. cd $MOBILE_DIR"
    echo "2. pnpm android"
}

# =============================================================================
# Main
# =============================================================================

print_header

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        --arch)
            ARCH="$2"
            shift 2
            ;;
        --godot)
            GODOT_PATH="$2"
            shift 2
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            print_usage
            exit 1
            ;;
    esac
done

# Validate platform
if [ -z "$PLATFORM" ]; then
    echo -e "${RED}Error: Platform required. Use --platform ios or --platform android${NC}"
    print_usage
    exit 1
fi

check_godot
setup_directories

case "$PLATFORM" in
    ios)
        build_ios
        ;;
    android)
        build_android
        ;;
    *)
        echo -e "${RED}Error: Unknown platform '$PLATFORM'${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}  Mobile Library Build Complete!${NC}"
echo -e "${GREEN}=================================================${NC}"
