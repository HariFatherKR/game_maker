#!/bin/bash
# =============================================================================
# IdleFarm Roguelike - Steam Build Script
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
GODOT_DIR="$PROJECT_ROOT/godot"
BUILD_DIR="$PROJECT_ROOT/build"
EXPORT_DIR="$BUILD_DIR/steam"

# Defaults
BUILD_MODE="debug"
PLATFORM=""
GODOT_PATH="godot"

# =============================================================================
# Functions
# =============================================================================

print_header() {
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${BLUE}  IdleFarm Roguelike - Steam Build${NC}"
    echo -e "${BLUE}=================================================${NC}"
}

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --debug          Build debug version (default)"
    echo "  --release        Build release version"
    echo "  --platform       Target platform (windows, linux, macos)"
    echo "  --godot PATH     Path to Godot executable"
    echo "  --clean          Clean build directory before building"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --debug --platform windows"
    echo "  $0 --release --platform linux --godot /usr/local/bin/godot"
}

detect_platform() {
    case "$(uname -s)" in
        Darwin*)  PLATFORM="macos";;
        Linux*)   PLATFORM="linux";;
        CYGWIN*|MINGW*|MSYS*) PLATFORM="windows";;
        *)        PLATFORM="unknown";;
    esac
    echo -e "${YELLOW}Detected platform: $PLATFORM${NC}"
}

check_godot() {
    if ! command -v "$GODOT_PATH" &> /dev/null; then
        echo -e "${RED}Error: Godot not found at '$GODOT_PATH'${NC}"
        echo "Please install Godot or specify path with --godot"
        exit 1
    fi

    local version=$("$GODOT_PATH" --version 2>/dev/null || echo "unknown")
    echo -e "${GREEN}Godot version: $version${NC}"
}

setup_directories() {
    echo -e "${YELLOW}Setting up build directories...${NC}"
    mkdir -p "$EXPORT_DIR/$PLATFORM"
}

clean_build() {
    echo -e "${YELLOW}Cleaning build directory...${NC}"
    rm -rf "$EXPORT_DIR"
    echo -e "${GREEN}Clean complete${NC}"
}

get_export_preset() {
    local mode=$1
    local platform=$2

    case "$platform" in
        windows)
            if [ "$mode" == "release" ]; then
                echo "Windows Desktop"
            else
                echo "Windows Desktop Debug"
            fi
            ;;
        linux)
            if [ "$mode" == "release" ]; then
                echo "Linux/X11"
            else
                echo "Linux/X11 Debug"
            fi
            ;;
        macos)
            if [ "$mode" == "release" ]; then
                echo "macOS"
            else
                echo "macOS Debug"
            fi
            ;;
        *)
            echo ""
            ;;
    esac
}

get_output_file() {
    local platform=$1

    case "$platform" in
        windows)  echo "IdleFarmRoguelike.exe";;
        linux)    echo "IdleFarmRoguelike.x86_64";;
        macos)    echo "IdleFarmRoguelike.app";;
        *)        echo "IdleFarmRoguelike";;
    esac
}

build_game() {
    local preset=$(get_export_preset "$BUILD_MODE" "$PLATFORM")
    local output_file=$(get_output_file "$PLATFORM")
    local output_path="$EXPORT_DIR/$PLATFORM/$output_file"

    if [ -z "$preset" ]; then
        echo -e "${RED}Error: Unknown platform '$PLATFORM'${NC}"
        exit 1
    fi

    echo -e "${YELLOW}Building for $PLATFORM ($BUILD_MODE)...${NC}"
    echo "Preset: $preset"
    echo "Output: $output_path"

    cd "$GODOT_DIR"

    # Export
    if [ "$BUILD_MODE" == "release" ]; then
        "$GODOT_PATH" --headless --export-release "$preset" "$output_path"
    else
        "$GODOT_PATH" --headless --export-debug "$preset" "$output_path"
    fi

    # Check result
    if [ -e "$output_path" ]; then
        echo -e "${GREEN}Build successful!${NC}"
        echo "Output: $output_path"

        # Show file size
        local size=$(du -h "$output_path" | cut -f1)
        echo "Size: $size"
    else
        echo -e "${RED}Build failed!${NC}"
        exit 1
    fi
}

copy_steam_files() {
    echo -e "${YELLOW}Copying Steam files...${NC}"

    local steam_api=""
    case "$PLATFORM" in
        windows)  steam_api="steam_api64.dll";;
        linux)    steam_api="libsteam_api.so";;
        macos)    steam_api="libsteam_api.dylib";;
    esac

    if [ -f "$GODOT_DIR/$steam_api" ]; then
        cp "$GODOT_DIR/$steam_api" "$EXPORT_DIR/$PLATFORM/"
        echo -e "${GREEN}Copied $steam_api${NC}"
    else
        echo -e "${YELLOW}Warning: $steam_api not found (Steam features will be disabled)${NC}"
    fi

    # Copy steam_appid.txt
    if [ -f "$GODOT_DIR/steam_appid.txt" ]; then
        cp "$GODOT_DIR/steam_appid.txt" "$EXPORT_DIR/$PLATFORM/"
        echo -e "${GREEN}Copied steam_appid.txt${NC}"
    fi
}

create_archive() {
    echo -e "${YELLOW}Creating distribution archive...${NC}"

    local archive_name="IdleFarmRoguelike-$PLATFORM-$BUILD_MODE"
    local archive_path="$BUILD_DIR/$archive_name"

    cd "$EXPORT_DIR"

    case "$PLATFORM" in
        windows)
            zip -r "$archive_path.zip" "$PLATFORM/"
            echo -e "${GREEN}Created: $archive_path.zip${NC}"
            ;;
        linux|macos)
            tar -czvf "$archive_path.tar.gz" "$PLATFORM/"
            echo -e "${GREEN}Created: $archive_path.tar.gz${NC}"
            ;;
    esac
}

# =============================================================================
# Main
# =============================================================================

print_header

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            BUILD_MODE="debug"
            shift
            ;;
        --release)
            BUILD_MODE="release"
            shift
            ;;
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        --godot)
            GODOT_PATH="$2"
            shift 2
            ;;
        --clean)
            clean_build
            shift
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

# Auto-detect platform if not specified
if [ -z "$PLATFORM" ]; then
    detect_platform
fi

# Validate platform
if [ "$PLATFORM" == "unknown" ]; then
    echo -e "${RED}Error: Could not detect platform. Please specify with --platform${NC}"
    exit 1
fi

# Run build steps
check_godot
setup_directories
build_game
copy_steam_files
create_archive

echo ""
echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}  Build Complete!${NC}"
echo -e "${GREEN}=================================================${NC}"
echo ""
echo "Platform: $PLATFORM"
echo "Mode: $BUILD_MODE"
echo "Output: $EXPORT_DIR/$PLATFORM/"
