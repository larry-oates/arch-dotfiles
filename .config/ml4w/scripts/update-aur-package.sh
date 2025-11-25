#!/bin/bash

# This script automates version bumping, updating PKGBUILDs, creating Git tags,
# and committing changes for one or more related AUR packages and the main repository.
#
# Usage: ./update-aur-packages.sh <MAIN_REPO_DIR> <AUR_DIR_1> [AUR_DIR_2] ...
# Example: ./update-aur-packages.sh my-app my-app-aur my-app-bin
# Example: ./update-aur-packages.sh my-app my-app-git-only

set -e

# --- Configuration & Setup ---

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check for required arguments (Main Repo + at least one AUR directory)
if [ "$#" -lt 2 ]; then
    echo -e "${RED}Usage: $0 <MAIN_REPO_DIR> <AUR_DIR_1> [AUR_DIR_2] ...${NC}"
    echo "Requires the main repository directory and at least one AUR directory."
    exit 1
fi

# Assign arguments to variables
MAIN_REPO_DIR="$1"
# All subsequent arguments (from $2 onwards) are AUR directories
AUR_DIRS=("${@:2}")
CANONICAL_AUR_DIR="${AUR_DIRS[0]}"

echo -e "${GREEN}Configuration:${NC}"
echo -e " - Main Repository: ${YELLOW}$MAIN_REPO_DIR${NC}"
echo -e " - AUR Directories (${#AUR_DIRS[@]} total):${NC}"
for aur_dir in "${AUR_DIRS[@]}"; do
    echo -e "   - ${YELLOW}$aur_dir${NC}"
done
echo ""

# --- Helper Functions ---

# Function to extract version from PKGBUILD
get_version() {
    local pkgbuild_path="$1/PKGBUILD"
    if [ ! -f "$pkgbuild_path" ]; then
        # Use stderr for error output to keep stdout clean for version parsing
        echo -e "${RED}Error: $pkgbuild_path not found.${NC}" >&2
        exit 1
    fi
    # Extracts the value of pkgver=
    grep "^pkgver=" "$pkgbuild_path" | cut -d'=' -f2 | tr -d ' '
}

# Function to update version in PKGBUILD
update_pkgbuild() {
    local pkgbuild_dir="$1"
    local new_version="$2"
    local pkgbuild_path="$pkgbuild_dir/PKGBUILD"

    echo -e "Updating ${YELLOW}$pkgbuild_path${NC} to v$new_version..."

    # Update pkgver
    sed -i "s/^pkgver=.*/pkgver=$new_version/" "$pkgbuild_path"
    
    # Reset pkgrel to 1 (Arch convention for a new upstream release)
    sed -i "s/^pkgrel=.*/pkgrel=1/" "$pkgbuild_path"
}

# --- Pre-Checks ---

# Check if main repository directory exists
if [ ! -d "$MAIN_REPO_DIR" ]; then
    echo -e "${RED}Error: Main repository directory '$MAIN_REPO_DIR' not found.${NC}"
    exit 1
fi

# Check if AUR directories exist and contain PKGBUILD
for aur_dir in "${AUR_DIRS[@]}"; do
    if [ ! -d "$aur_dir" ]; then
        echo -e "${RED}Error: AUR directory '$aur_dir' not found.${NC}"
        exit 1
    fi
    if [ ! -f "$aur_dir/PKGBUILD" ]; then
        echo -e "${RED}Error: PKGBUILD not found in '$aur_dir'.${NC}"
        exit 1
    fi
done

# --- Version Extraction ---

echo -e "${GREEN}Reading current versions...${NC}"
# Use the version from the first provided AUR directory as the canonical source
aur_version=$(get_version "$CANONICAL_AUR_DIR")

echo -e "Canonical version (from $CANONICAL_AUR_DIR/PKGBUILD): ${YELLOW}$aur_version${NC}"

# Check all other AUR packages for consistency (optional but good practice)
for aur_dir in "${AUR_DIRS[@]:1}"; do
    current_ver=$(get_version "$aur_dir")
    echo -e "Current version in $aur_dir/PKGBUILD: ${YELLOW}$current_ver${NC}"
    if [ "$current_ver" != "$aur_version" ]; then
        echo -e "${YELLOW}Warning: $aur_dir PKGBUILD version ($current_ver) differs from canonical version ($aur_version). All packages will be updated to the new canonical version.${NC}"
    fi
done


# --- Version Bumping Logic (MAJOR.MINOR.PATCH) ---

# Parse version
IFS='.' read -ra VERSION_PARTS <<< "$aur_version"
major="${VERSION_PARTS[0]}"
minor="${VERSION_PARTS[1]}"
patch="${VERSION_PARTS[2]}"

echo ""
echo "--- Version Bumping ---"
echo "Which version component should be updated?"
echo "1) Major (currently: $major)"
echo "2) Minor (currently: $minor)"
echo "3) Patch (currently: $patch)"
read -p "Enter choice (1/2/3): " choice

case $choice in
    1)
        major=$((major + 1))
        minor=0
        patch=0
        ;;
    2)
        minor=$((minor + 1))
        patch=0
        ;;
    3)
        patch=$((patch + 1))
        ;;
    *)
        echo -e "${RED}Invalid choice. Aborting.${NC}"
        exit 1
        ;;
esac

new_version="$major.$minor.$patch"
echo -e "${GREEN}New version set to: ${YELLOW}$new_version${NC}"
read -p "Confirm version bump and proceed with Git tagging/pushing? (y/n): " confirm

if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Aborted by user."
    exit 0
fi

# --- Main Repository Tagging ---

echo -e "${GREEN}--- 1. Tagging $MAIN_REPO_DIR repository ---${NC}"
cd "$MAIN_REPO_DIR"
if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    git tag -a "v$new_version" -m "Release version $new_version"
    echo -e "${GREEN}Created tag v$new_version.${NC}"
    echo -e "${GREEN}Pushing tag v$new_version to remote...${NC}"
    # Using '|| true' to prevent script exit if push fails (e.g., if tag already exists)
    git push origin "v$new_version" || true
else
    echo -e "${YELLOW}Warning: '$MAIN_REPO_DIR' is not a git repository. Skipping tagging.${NC}"
fi
cd ..

# --- AUR Package Updates Loop ---

for i in "${!AUR_DIRS[@]}"; do
    aur_dir="${AUR_DIRS[$i]}"
    # Start counting from 2 (1 was main tagging)
    step_num=$((i + 2)) 

    echo -e "${GREEN}--- $step_num. Updating $aur_dir package ---${NC}"
    
    update_pkgbuild "$aur_dir" "$new_version"

    echo -e "Generating $aur_dir/.SRCINFO and committing...${NC}"
    cd "$aur_dir"
    makepkg --printsrcinfo > .SRCINFO
    git add PKGBUILD .SRCINFO
    git commit -m "Update to version $new_version"
    echo -e "${GREEN}Pushing $aur_dir changes to remote...${NC}"
    git push
    cd ..
done

echo ""
echo -e "${GREEN}✓ All repositories successfully updated to version $new_version${NC}"
