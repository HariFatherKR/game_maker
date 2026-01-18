#!/bin/bash
# =============================================================================
# IdleFarm Roguelike - Steam Upload Script
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
BUILD_DIR="$PROJECT_ROOT/build/steam"
STEAMCMD_DIR="$PROJECT_ROOT/tools/steamcmd"

# Steam configuration
STEAM_APP_ID="YOUR_APP_ID"  # Replace with your Steam App ID
DEPOT_ID_WINDOWS="YOUR_DEPOT_ID_WINDOWS"
DEPOT_ID_LINUX="YOUR_DEPOT_ID_LINUX"
DEPOT_ID_MACOS="YOUR_DEPOT_ID_MACOS"

# Defaults
BRANCH="beta"
DESCRIPTION=""

# =============================================================================
# Functions
# =============================================================================

print_header() {
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${BLUE}  IdleFarm Roguelike - Steam Upload${NC}"
    echo -e "${BLUE}=================================================${NC}"
}

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --branch NAME    Steam branch to upload to (default: beta)"
    echo "  --description    Build description"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --branch beta --description \"v0.1.0 Beta\""
    echo "  $0 --branch default --description \"Release v1.0.0\""
}

check_steamcmd() {
    if [ ! -f "$STEAMCMD_DIR/steamcmd.sh" ]; then
        echo -e "${YELLOW}SteamCMD not found. Downloading...${NC}"
        mkdir -p "$STEAMCMD_DIR"

        case "$(uname -s)" in
            Darwin*)
                curl -o "$STEAMCMD_DIR/steamcmd_osx.tar.gz" "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_osx.tar.gz"
                tar -xvf "$STEAMCMD_DIR/steamcmd_osx.tar.gz" -C "$STEAMCMD_DIR"
                ;;
            Linux*)
                curl -o "$STEAMCMD_DIR/steamcmd_linux.tar.gz" "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"
                tar -xvf "$STEAMCMD_DIR/steamcmd_linux.tar.gz" -C "$STEAMCMD_DIR"
                ;;
            *)
                echo -e "${RED}Unsupported platform for SteamCMD${NC}"
                exit 1
                ;;
        esac

        echo -e "${GREEN}SteamCMD installed${NC}"
    fi
}

check_builds() {
    echo -e "${YELLOW}Checking builds...${NC}"

    local platforms=("windows" "linux" "macos")
    local found=0

    for platform in "${platforms[@]}"; do
        if [ -d "$BUILD_DIR/$platform" ]; then
            echo -e "${GREEN}Found: $platform${NC}"
            found=$((found + 1))
        else
            echo -e "${YELLOW}Missing: $platform${NC}"
        fi
    done

    if [ $found -eq 0 ]; then
        echo -e "${RED}Error: No builds found. Run build_steam.sh first.${NC}"
        exit 1
    fi
}

create_vdf_files() {
    echo -e "${YELLOW}Creating VDF files...${NC}"

    local vdf_dir="$BUILD_DIR/vdf"
    mkdir -p "$vdf_dir"

    # App build VDF
    cat > "$vdf_dir/app_build.vdf" << EOF
"appbuild"
{
    "appid" "$STEAM_APP_ID"
    "desc" "$DESCRIPTION"
    "buildoutput" "$BUILD_DIR/output"
    "contentroot" "$BUILD_DIR"
    "setlive" "$BRANCH"

    "depots"
    {
EOF

    # Add depots for each platform
    if [ -d "$BUILD_DIR/windows" ]; then
        cat >> "$vdf_dir/app_build.vdf" << EOF
        "$DEPOT_ID_WINDOWS" "$vdf_dir/depot_windows.vdf"
EOF
        # Windows depot VDF
        cat > "$vdf_dir/depot_windows.vdf" << EOF
"DepotBuildConfig"
{
    "DepotID" "$DEPOT_ID_WINDOWS"
    "contentroot" "$BUILD_DIR/windows"
    "FileMapping"
    {
        "LocalPath" "*"
        "DepotPath" "."
        "recursive" "1"
    }
    "FileExclusion" "*.pdb"
}
EOF
    fi

    if [ -d "$BUILD_DIR/linux" ]; then
        cat >> "$vdf_dir/app_build.vdf" << EOF
        "$DEPOT_ID_LINUX" "$vdf_dir/depot_linux.vdf"
EOF
        # Linux depot VDF
        cat > "$vdf_dir/depot_linux.vdf" << EOF
"DepotBuildConfig"
{
    "DepotID" "$DEPOT_ID_LINUX"
    "contentroot" "$BUILD_DIR/linux"
    "FileMapping"
    {
        "LocalPath" "*"
        "DepotPath" "."
        "recursive" "1"
    }
}
EOF
    fi

    if [ -d "$BUILD_DIR/macos" ]; then
        cat >> "$vdf_dir/app_build.vdf" << EOF
        "$DEPOT_ID_MACOS" "$vdf_dir/depot_macos.vdf"
EOF
        # macOS depot VDF
        cat > "$vdf_dir/depot_macos.vdf" << EOF
"DepotBuildConfig"
{
    "DepotID" "$DEPOT_ID_MACOS"
    "contentroot" "$BUILD_DIR/macos"
    "FileMapping"
    {
        "LocalPath" "*"
        "DepotPath" "."
        "recursive" "1"
    }
}
EOF
    fi

    # Close app build VDF
    cat >> "$vdf_dir/app_build.vdf" << EOF
    }
}
EOF

    echo -e "${GREEN}VDF files created${NC}"
}

upload_to_steam() {
    echo -e "${YELLOW}Uploading to Steam...${NC}"

    # Prompt for Steam credentials
    echo -e "${BLUE}Enter your Steam Partner credentials:${NC}"
    read -p "Username: " STEAM_USERNAME
    read -s -p "Password: " STEAM_PASSWORD
    echo ""

    # Run SteamCMD
    "$STEAMCMD_DIR/steamcmd.sh" \
        +login "$STEAM_USERNAME" "$STEAM_PASSWORD" \
        +run_app_build "$BUILD_DIR/vdf/app_build.vdf" \
        +quit

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Upload successful!${NC}"
    else
        echo -e "${RED}Upload failed!${NC}"
        exit 1
    fi
}

# =============================================================================
# Main
# =============================================================================

print_header

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --branch)
            BRANCH="$2"
            shift 2
            ;;
        --description)
            DESCRIPTION="$2"
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

# Set default description
if [ -z "$DESCRIPTION" ]; then
    DESCRIPTION="Build $(date +%Y%m%d_%H%M%S)"
fi

echo "Branch: $BRANCH"
echo "Description: $DESCRIPTION"
echo ""

check_steamcmd
check_builds
create_vdf_files
upload_to_steam

echo ""
echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}  Steam Upload Complete!${NC}"
echo -e "${GREEN}=================================================${NC}"
echo ""
echo "Branch: $BRANCH"
echo "Description: $DESCRIPTION"
echo ""
echo "Check your build status at:"
echo "https://partner.steamgames.com/apps/builds/$STEAM_APP_ID"
