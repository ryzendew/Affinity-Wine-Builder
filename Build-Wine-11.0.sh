#!/bin/bash
#
# Build-Wine-11.0.sh
# Simplified Wine build script for GitHub Actions
# Patches, builds, and packages Wine 11.0
#
# This script assumes:
#   - All build dependencies are already installed (handled by GitHub Actions)
#   - Wine source code is in the current directory (or will be downloaded)
#   - Patches are in patches/wine-11.0/
#
# Usage:
#   ./Build-Wine-11.0.sh
#
# Environment variables:
#   BUILD_THREADS    - Number of build threads (default: nproc)
#   CFLAGS           - Compiler flags for native build
#   CROSSCFLAGS      - Compiler flags for cross-compilation
#   CROSSCXXFLAGS    - C++ compiler flags for cross-compilation
#   CROSSLDFLAGS     - Linker flags for cross-compilation
#   INSTALL_PREFIX  - Installation directory (default: ./wine-install)

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Wine version
WINE_VERSION="11.0"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Set defaults
BUILD_THREADS="${BUILD_THREADS:-$(nproc 2>/dev/null || echo 4)}"
# Use ElementalWarrior-wine-11.0 as the directory name for proper packaging
INSTALL_PREFIX="${INSTALL_PREFIX:-$SCRIPT_DIR/ElementalWarrior-wine-11.0}"

# Build flags (matching GitHub Actions workflow)
CFLAGS="${CFLAGS:--O2 -std=gnu17 -pipe -ffat-lto-objects -Wno-discarded-qualifiers -Wno-format -Wno-maybe-uninitialized -Wno-misleading-indentation}"
CROSSCFLAGS="${CROSSCFLAGS:--O2 -std=gnu17 -pipe -Wno-discarded-qualifiers -Wno-format -Wno-maybe-uninitialized -Wno-misleading-indentation}"
CROSSCXXFLAGS="${CROSSCXXFLAGS:--O2 -std=gnu17 -pipe -Wno-discarded-qualifiers -Wno-format -Wno-maybe-uninitialized -Wno-misleading-indentation}"
CROSSLDFLAGS="${CROSSLDFLAGS:--Wl,-O1}"

export CFLAGS CROSSCFLAGS CROSSCXXFLAGS CROSSLDFLAGS

# Print header
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}${BOLD}Wine 11.0 Build Script${NC}"
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BOLD}Configuration:${NC}"
echo -e "  ${BOLD}Wine Version:${NC}     ${GREEN}$WINE_VERSION${NC}"
echo -e "  ${BOLD}Build Threads:${NC}   ${GREEN}$BUILD_THREADS${NC}"
echo -e "  ${BOLD}Install Prefix:${NC}  ${GREEN}$INSTALL_PREFIX${NC}"
echo ""

# Check if Wine source exists
WINE_SRC_DIR=""
if [ -f "./configure" ]; then
  WINE_SRC_DIR="."
  echo -e "${GREEN}✓${NC} Wine source found in current directory"
elif [ -d "./wine-$WINE_VERSION" ] && [ -f "./wine-$WINE_VERSION/configure" ]; then
  WINE_SRC_DIR="./wine-$WINE_VERSION"
  echo -e "${GREEN}✓${NC} Wine source found in ./wine-$WINE_VERSION"
else
  echo -e "${YELLOW}⚠ Wine source not found. Attempting to download...${NC}"
  
  # Download Wine source
  local v_maj=$(echo "$WINE_VERSION" | cut -d'.' -f1)
  local v_min=$(echo "$WINE_VERSION" | cut -s -d'.' -f2)
  local url_subdir
  if [ -z "$v_min" ] || [ "$v_min" = "0" ]; then
    url_subdir="$v_maj.0"
  else
    url_subdir="$v_maj.x"
  fi
  WINE_URL="https://dl.winehq.org/wine/source/$url_subdir/wine-${WINE_VERSION}.tar.xz"
  WINE_FILE="wine-${WINE_VERSION}.tar.xz"
  
  echo -e "${CYAN}Downloading Wine $WINE_VERSION...${NC}"
  if command -v wget >/dev/null 2>&1; then
    wget --progress=bar:force:noscroll "$WINE_URL" -O "$WINE_FILE" || {
      echo -e "${RED}${BOLD}❌ ERROR: Failed to download Wine source.${NC}"
      exit 1
    }
  elif command -v curl >/dev/null 2>&1; then
    curl -L --progress-bar --fail -o "$WINE_FILE" "$WINE_URL" || {
      echo -e "${RED}${BOLD}❌ ERROR: Failed to download Wine source.${NC}"
      exit 1
    }
  else
    echo -e "${RED}${BOLD}❌ ERROR: Neither wget nor curl found.${NC}"
    exit 1
  fi
  
  echo -e "${CYAN}Extracting Wine source...${NC}"
  tar -xf "$WINE_FILE" || {
    echo -e "${RED}${BOLD}❌ ERROR: Failed to extract Wine source.${NC}"
    exit 1
  }
  
  # Clean up downloaded source file
  rm -f "$WINE_FILE"
  echo -e "${CYAN}Cleaned up downloaded source file${NC}"
  
  # Handle nested directory structure
  if [ -d "wine-$WINE_VERSION" ]; then
    WINE_SRC_DIR="./wine-$WINE_VERSION"
  else
    echo -e "${RED}${BOLD}❌ ERROR: Could not find extracted Wine directory.${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}✓${NC} Wine source downloaded and extracted"
fi

# Convert to absolute path
WINE_SRC_DIR="$(cd "$WINE_SRC_DIR" && pwd)"
cd "$SCRIPT_DIR"

# Verify configure script exists
if [ ! -f "$WINE_SRC_DIR/configure" ]; then
  echo -e "${RED}${BOLD}❌ ERROR: configure script not found in $WINE_SRC_DIR${NC}"
  exit 1
fi

echo -e "${GREEN}✓${NC} Using Wine source: ${CYAN}$WINE_SRC_DIR${NC}"
echo ""

# Apply patches
echo -e "${CYAN}${BOLD}Step 1: Applying Patches${NC}"
echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

PATCH_DIR="$SCRIPT_DIR/patches/wine-$WINE_VERSION"
if [ ! -d "$PATCH_DIR" ]; then
  echo -e "${RED}${BOLD}❌ ERROR: Patch directory not found: $PATCH_DIR${NC}"
  exit 1
fi

# Find all patch files and sort them to ensure correct order
PATCH_FILES=($(find "$PATCH_DIR" -maxdepth 1 -name "*.patch" -type f | sort))

if [ ${#PATCH_FILES[@]} -eq 0 ]; then
  echo -e "${YELLOW}⚠ Warning: No patch files found in $PATCH_DIR${NC}"
  echo -e "${YELLOW}  Continuing without patches...${NC}"
else
  echo -e "${CYAN}Found ${BOLD}${#PATCH_FILES[@]}${NC} patch file(s) in: ${GREEN}$PATCH_DIR${NC}"
  echo ""
  
  cd "$WINE_SRC_DIR" || exit 1
  
  # Temporarily disable exit on error for patch application (we handle errors manually)
  set +e
  
  PATCH_COUNT=0
  FAILED_PATCHES=()
  
  for patch_file in "${PATCH_FILES[@]}"; do
    PATCH_NAME="$(basename "$patch_file")"
    echo -e "${CYAN}  Applying: ${BOLD}$PATCH_NAME${NC}"
    
    # Try normal apply first
    if patch -p1 --no-backup-if-mismatch -i "$patch_file" >/dev/null 2>&1; then
      ((PATCH_COUNT++))
      echo -e "    ${GREEN}✓${NC} Successfully applied"
    # Try with fuzz if normal apply fails
    elif patch -p1 --no-backup-if-mismatch --fuzz=3 -i "$patch_file" >/dev/null 2>&1; then
      ((PATCH_COUNT++))
      echo -e "    ${GREEN}✓${NC} Successfully applied (with fuzz)"
    # Check if already applied
    else
      PATCH_OUTPUT=$(patch -p1 --dry-run -i "$patch_file" 2>&1)
      if echo "$PATCH_OUTPUT" | grep -q "Reversed (or previously applied)"; then
        ((PATCH_COUNT++))
        echo -e "    ${GREEN}✓${NC} Already applied (skipped)"
      else
        echo -e "    ${RED}✗${NC} Failed to apply"
        FAILED_PATCHES+=("$PATCH_NAME")
      fi
    fi
  done
  
  # Re-enable exit on error
  set -e
  
  cd "$SCRIPT_DIR" || exit 1
  
  echo ""
  if [ ${#FAILED_PATCHES[@]} -gt 0 ]; then
    echo -e "${RED}${BOLD}❌ ERROR: Failed to apply ${#FAILED_PATCHES[@]} patch(es):${NC}"
    for failed in "${FAILED_PATCHES[@]}"; do
      echo -e "  ${RED}  - $failed${NC}"
    done
    exit 1
  elif [ $PATCH_COUNT -eq 0 ]; then
    echo -e "${YELLOW}⚠ Warning: No patches were applied.${NC}"
  else
    echo -e "${GREEN}✓${NC} Successfully applied ${CYAN}$PATCH_COUNT${NC} of ${CYAN}${#PATCH_FILES[@]}${NC} patch(es)"
  fi
fi

echo ""

# Prepare build directory
echo -e "${CYAN}${BOLD}Step 2: Preparing Build Directory${NC}"
echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

mkdir -p wine64-build
mkdir -p "$INSTALL_PREFIX"
echo -e "${GREEN}✓${NC} Build directories created"
echo ""

# Configure Wine
echo -e "${CYAN}${BOLD}Step 3: Configuring Wine${NC}"
echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

cd wine64-build || exit 1

# Check for OpenCL headers
if [ ! -f "/usr/include/CL/cl.h" ] && [ ! -f "/usr/local/include/CL/cl.h" ]; then
  echo -e "${RED}${BOLD}❌ ERROR: OpenCL headers not found!${NC}"
  echo -e "${YELLOW}Please install OpenCL development packages.${NC}"
  exit 1
fi

echo -e "${GREEN}✓${NC} OpenCL headers found"

# Configure Wine (matching GitHub Actions workflow)
echo -e "${CYAN}Configuring Wine...${NC}"
if ! "$WINE_SRC_DIR/configure" \
  --prefix="$INSTALL_PREFIX" \
  --enable-opencl \
  --enable-archs=i386,x86_64 \
  --disable-tests \
  --without-oss \
  >configure.log 2>&1; then
  echo -e "${RED}${BOLD}❌ ERROR: Wine configure failed!${NC}"
  echo -e "${YELLOW}Last 100 lines of configure log:${NC}"
  tail -100 configure.log
  echo ""
  echo -e "${YELLOW}Full configure log saved to: configure.log${NC}"
  exit 1
fi

# Show configure summary (filter out OSS warning)
echo -e "${CYAN}Configure summary:${NC}"
grep -v "configure: OSS sound system found but too old (OSSv4 needed)" configure.log | tail -30 || cat configure.log | tail -30

echo -e "${GREEN}✓${NC} Wine configured successfully"
echo ""

# Build Wine
echo -e "${CYAN}${BOLD}Step 4: Building Wine${NC}"
echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${CYAN}Building Wine with $BUILD_THREADS threads...${NC}"
if ! make -j"$BUILD_THREADS" >wine-build.log 2>&1; then
  echo -e "${RED}${BOLD}❌ ERROR: Wine build failed!${NC}"
  echo -e "${YELLOW}Last 50 lines of build log:${NC}"
  tail -50 wine-build.log
  exit 1
fi

# Filter out parser/sql warnings from output
grep -Ev "(parser|sql)\.y: (warning|note):" wine-build.log || true

echo -e "${GREEN}✓${NC} Wine build completed successfully"
echo ""

# Install Wine
echo -e "${CYAN}${BOLD}Step 5: Installing Wine${NC}"
echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${CYAN}Installing Wine...${NC}"

# Install libraries and DLLs
if ! make install-lib -j"$BUILD_THREADS" >wine-install.log 2>&1; then
  echo -e "${RED}${BOLD}❌ ERROR: Failed to install Wine libraries${NC}"
  tail -50 wine-install.log
  exit 1
fi

# Install development files
make install-dev -j"$BUILD_THREADS" >>wine-install.log 2>&1 || echo -e "${YELLOW}⚠ Warning: make install-dev failed, continuing...${NC}"

# Install programs
for progdir in programs/*/; do
  if [ -d "$progdir" ] && [ -f "$progdir/Makefile" ]; then
    make -C "$progdir" install >>wine-install.log 2>&1 || echo -e "${YELLOW}⚠ Warning: Failed to install $progdir${NC}"
  fi
done

# Install tools
for tooldir in tools/wine tools/widl tools/winebuild tools/winedump tools/winegcc tools/winemaker tools/wmc tools/wrc; do
  if [ -d "$tooldir" ] && [ -f "$tooldir/Makefile" ]; then
    make -C "$tooldir" install >>wine-install.log 2>&1 || echo -e "${YELLOW}⚠ Warning: Failed to install $tooldir${NC}"
  fi
done

# Install loader
if [ -d "loader" ] && [ -f "loader/Makefile" ]; then
  make -C loader install >>wine-install.log 2>&1 || echo -e "${YELLOW}⚠ Warning: Failed to install loader${NC}"
fi

# Install server
if [ -d "server" ] && [ -f "server/Makefile" ]; then
  make -C server install >>wine-install.log 2>&1 || echo -e "${YELLOW}⚠ Warning: Failed to install server${NC}"
fi

# Install fonts and NLS
if [ -d "fonts" ] && [ -f "fonts/Makefile" ]; then
  make -C fonts install >>wine-install.log 2>&1 || echo -e "${YELLOW}⚠ Warning: Failed to install fonts${NC}"
fi

if [ -d "nls" ] && [ -f "nls/Makefile" ]; then
  make -C nls install >>wine-install.log 2>&1 || echo -e "${YELLOW}⚠ Warning: Failed to install nls${NC}"
fi

echo -e "${GREEN}✓${NC} Wine installed successfully"
echo ""

# Package Wine
echo -e "${CYAN}${BOLD}Step 6: Packaging Wine${NC}"
echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Package Wine as .tar.xz
# The tarball should extract to ElementalWarrior-wine-11.0/ with bin, include, lib, share inside
if [ -d "$INSTALL_PREFIX" ]; then
  echo -e "${CYAN}${BOLD}Packaging Wine as .tar.xz...${NC}"
  cd "$(dirname "$INSTALL_PREFIX")" || exit 1
  PACKAGE_NAME="ElementalWarrior-wine-$WINE_VERSION.tar.xz"
  
  # Package with the directory name included
  # This ensures extraction creates ElementalWarrior-wine-11.0/ with bin, include, lib, share inside
  if tar -cJf "$PACKAGE_NAME" "$(basename "$INSTALL_PREFIX")" 2>/dev/null; then
    echo -e "${GREEN}${BOLD}✓ Wine packaged successfully: ${CYAN}$PACKAGE_NAME${NC}"
    echo -e "  ${BOLD}Location:${NC} ${CYAN}$(pwd)/$PACKAGE_NAME${NC}"
    echo -e "  ${BOLD}Size:${NC} ${CYAN}$(du -h "$PACKAGE_NAME" | cut -f1)${NC}"
    echo ""
    echo -e "${CYAN}Package structure:${NC}"
    echo -e "  ${GREEN}ElementalWarrior-wine-11.0/${NC}"
    echo -e "    ${GREEN}bin/${NC}"
    echo -e "    ${GREEN}include/${NC}"
    echo -e "    ${GREEN}lib/${NC}"
    echo -e "    ${GREEN}share/${NC}"
  else
    echo -e "${YELLOW}⚠ Warning: Failed to create package, but Wine is installed at: ${CYAN}$INSTALL_PREFIX${NC}"
    exit 1
  fi
else
  echo -e "${RED}${BOLD}❌ ERROR: Installation directory not found: $INSTALL_PREFIX${NC}"
  exit 1
fi

echo ""

# Final summary
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}${BOLD}✓ BUILD COMPLETE!${NC}"
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BOLD}Summary:${NC}"
echo -e "  ${BOLD}Wine Version:${NC}     ${GREEN}$WINE_VERSION${NC}"
echo -e "  ${BOLD}Install Prefix:${NC}    ${CYAN}$INSTALL_PREFIX${NC}"
echo -e "  ${BOLD}Package:${NC}           ${CYAN}$PACKAGE_NAME${NC}"
echo ""

