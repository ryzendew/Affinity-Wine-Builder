#!/bin/bash
#
# Wine Build Script
# Builds 64-bit Wine from source with automatic patch application (OpenCL required)
# Can be run standalone (without containers) or in a container environment
#
# Features:
#   - Interactive menu to select Wine version (from available patches)
#   - Automatic download of Wine source code
#   - Automatic patch application
#   - Multi-distro support (Arch, Fedora, Debian/Ubuntu)
#   - Auto-detects CPU threads and package manager
#
# Usage:
#   ./build-wine.sh                           # Interactive menu to select version
#   WINE_VERSION=10.1 ./build-wine.sh        # Build specific version (skip menu)
#   BUILD_THREADS=8 ./build-wine.sh           # Use 8 threads
#   BUILD_DEBUG=1 ./build-wine.sh             # Build with debug symbols
#   BUILD_WAYLAND=0 ./build-wine.sh           # Disable Wayland support
#

# Auto-detect CPU threads
if command -v nproc >/dev/null 2>&1; then
  DETECTED_THREADS=$(nproc)
elif [ -f /proc/cpuinfo ]; then
  DETECTED_THREADS=$(grep -c processor /proc/cpuinfo)
else
  DETECTED_THREADS=4
fi

BUILD_THREADS="${BUILD_THREADS:-$DETECTED_THREADS}"
echo "Using $BUILD_THREADS threads for build (detected: $DETECTED_THREADS)."

BUILD_DEBUG="${BUILD_DEBUG:-0}"
if [ "$BUILD_DEBUG" = "1" ]; then
  echo "The build will produce debugging information."
fi

BUILD_WAYLAND="${BUILD_WAYLAND:-1}"
if [ "$BUILD_WAYLAND" = "0" ]; then
  echo "The build will skip the Wine Wayland driver."
fi

# Detect package manager and distribution
detect_package_manager() {
  if command -v apt >/dev/null 2>&1; then
    echo "apt"
  elif command -v dnf >/dev/null 2>&1; then
    echo "dnf"
  elif command -v pacman >/dev/null 2>&1; then
    echo "pacman"
  else
    echo "unknown"
  fi
}

# Detect if we're on PikaOS (Ubuntu-based)
is_pikaos() {
  if [ -f /etc/os-release ]; then
    grep -qi "pikaos" /etc/os-release 2>/dev/null
  else
    return 1
  fi
}

PKG_MGR=$(detect_package_manager)
echo "Detected package manager: $PKG_MGR"

# Check if OpenCL headers are available (mandatory)
check_opencl_headers() {
  if [ -f "/usr/include/CL/cl.h" ] || [ -f "/usr/local/include/CL/cl.h" ]; then
    return 0
  fi
  return 1
}

# Check if a package is installed (for apt)
check_package_installed_apt() {
  dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}

# Check if a package is installed (for dnf)
check_package_installed_dnf() {
  rpm -q "$1" >/dev/null 2>&1
}

# Check if a package is installed (for pacman)
check_package_installed_pacman() {
  pacman -Q "$1" >/dev/null 2>&1
}

# Install packages based on package manager (only missing ones)
install_packages_64bit() {
  echo "Checking required development packages..."
  local packages_to_install=()
  
  case "$PKG_MGR" in
    apt)
      # Check if we're on PikaOS or regular Ubuntu/Debian
      if is_pikaos; then
        echo "Detected PikaOS (Ubuntu-based)"
      fi
      
      # First, try to use apt build-dep which automatically installs all build dependencies
      echo "Attempting to install Wine build dependencies using 'apt build-dep wine'..."
      if sudo apt build-dep -y wine 2>/dev/null; then
        echo "  ✓ Wine build dependencies installed via build-dep"
      else
        echo "  Note: 'apt build-dep wine' failed or wine package not available, installing packages manually..."
        local required_packages=(
          # Build tools
          "build-essential" "gcc" "g++" "make" "bison" "flex" "gettext" "perl"
          # MinGW cross-compilers
          "gcc-mingw-w64"
          # Core development libraries
          "samba-dev" "libcups2-dev" "ocl-icd-opencl-dev" "opencl-headers"
          # Audio libraries
          "libasound2-dev" "libpulse-dev"
          # Font libraries
          "libfontconfig1-dev" "libfreetype6-dev"
          # X11 libraries
          "libx11-dev" "libxext-dev" "libxrender-dev" "libxrandr-dev"
          "libxinerama-dev" "libxi-dev" "libxcursor-dev" "libxfixes-dev"
          "libxcomposite-dev" "libxkbcommon-dev" "x11proto-dev"
          # Graphics libraries
          "libgl-dev" "libglu1-mesa-dev" "vulkan-dev" "libvulkan-dev"
          "libosmesa6-dev"
          # Wayland support
          "libwayland-dev" "wayland-protocols"
          # GStreamer
          "libgstreamer1.0-dev" "libgstreamer-plugins-base1.0-dev"
          # SDL
          "libsdl2-dev"
          # System libraries
          "libdbus-1-dev" "libudev-dev" "libunwind-dev"
          # Optional but recommended
          "libxml2-dev" "libxslt1-dev" "libjpeg-dev" "libpng-dev"
          "libtiff-dev" "liblcms2-dev" "libusb-1.0-0-dev" "libpcap-dev"
          "libncurses5-dev" "libkrb5-dev" "unixodbc-dev" "libv4l-dev"
          "libgphoto2-dev" "libsane-dev" "libpcsclite-dev"
          # Multimedia (optional)
          "libavcodec-dev" "libavformat-dev" "libavutil-dev" "libswscale-dev"
          # ISDN (optional)
          "libcapi20-dev"
        )
        for pkg in "${required_packages[@]}"; do
          if check_package_installed_apt "$pkg"; then
            echo "  ✓ $pkg is already installed"
          else
            echo "  ✗ $pkg is missing"
            packages_to_install+=("$pkg")
          fi
        done
        
        if [ ${#packages_to_install[@]} -gt 0 ]; then
          echo "Installing missing packages: ${packages_to_install[*]}"
          sudo apt install -y "${packages_to_install[@]}"
          echo "  ✓ Package installation complete"
        else
          echo "  ✓ All required packages are already installed"
        fi
      fi
      ;;
    dnf)
      # First, try to use dnf builddep which automatically installs all build dependencies
      # This is the most reliable method as it uses the exact package names from the wine.spec
      echo "Attempting to install Wine build dependencies using 'dnf builddep wine'..."
      if sudo dnf builddep -y wine 2>/dev/null; then
        echo "  ✓ Wine build dependencies installed via builddep"
      else
        echo "  Note: 'dnf builddep wine' failed or wine package not available, installing packages manually..."
        local required_packages=(
          # Build tools
          "gcc" "gcc-c++" "make" "bison" "flex" "gettext" "perl"
          # MinGW cross-compilers
          "mingw32-gcc" "mingw64-gcc"
          # Core development libraries
          "samba-devel" "cups-devel" "ocl-icd-devel" "opencl-headers"
          # Audio libraries
          "alsa-lib-devel" "pulseaudio-libs-devel"
          # Font libraries
          "fontconfig-devel" "freetype-devel"
          # X11 libraries
          "libX11-devel" "libXext-devel" "libXrender-devel" "libXrandr-devel"
          "libXinerama-devel" "libXi-devel" "libXcursor-devel" "libXfixes-devel"
          "libXcomposite-devel" "libxkbcommon-devel" "xorg-x11-proto-devel"
          # Graphics libraries
          "mesa-libGL-devel" "mesa-libGLU-devel" "vulkan-headers" "vulkan-loader-devel"
          "mesa-libOSMesa-devel"
          # Wayland support
          "wayland-devel" "wayland-protocols-devel"
          # GStreamer
          "gstreamer1-devel" "gstreamer1-plugins-base-devel"
          # SDL
          "SDL2-devel"
          # System libraries
          "dbus-devel" "systemd-devel" "libunwind-devel"
          # Optional but recommended
          "libxml2-devel" "libxslt-devel" "libjpeg-turbo-devel" "libpng-devel"
          "libtiff-devel" "lcms2-devel" "libusb-devel" "libpcap-devel"
          "ncurses-devel" "krb5-devel" "unixODBC-devel" "libv4l-devel"
          "gphoto2-devel" "sane-backends-devel" "pcsc-lite-devel"
          # Multimedia (optional)
          "ffmpeg-devel"
          # ISDN (optional)
          "capi20-devel"
        )
        for pkg in "${required_packages[@]}"; do
          if check_package_installed_dnf "$pkg"; then
            echo "  ✓ $pkg is already installed"
          else
            echo "  ✗ $pkg is missing"
            packages_to_install+=("$pkg")
          fi
        done
        
        if [ ${#packages_to_install[@]} -gt 0 ]; then
          echo "Installing missing packages: ${packages_to_install[*]}"
          sudo dnf install -y --allowerasing "${packages_to_install[@]}" 2>/dev/null || \
          sudo dnf install -y --allowerasing "${packages_to_install[@]}"
          echo "  ✓ Package installation complete"
        else
          echo "  ✓ All required packages are already installed"
        fi
      fi
      ;;
    pacman)
      # Arch Linux: Most packages include development files in the base package
      # Note: Arch doesn't have a direct builddep command like dnf/apt
      echo "Installing Wine build dependencies for Arch Linux..."
      echo "  Note: Ensure multilib repository is enabled for 32-bit libraries"
      local required_packages=(
        # Build tools (base-devel includes gcc, make, etc.)
        "base-devel" "bison" "flex" "gettext" "perl"
        # MinGW cross-compilers
        "mingw-w64-gcc"
        # Core development libraries (Arch packages include dev files)
        "samba" "libcups" "opencl-headers" "ocl-icd"
        # Audio libraries
        "alsa-lib" "pulseaudio"
        # Font libraries
        "fontconfig" "freetype2"
        # X11 libraries
        "libx11" "libxext" "libxrender" "libxrandr"
        "libxinerama" "libxi" "libxcursor" "libxfixes"
        "libxcomposite" "libxkbcommon" "xorgproto"
        # Graphics libraries
        "mesa" "libgl" "vulkan-headers" "vulkan-icd-loader"
        "lib32-mesa" "lib32-libgl"
        # Wayland support
        "wayland" "wayland-protocols"
        # GStreamer
        "gstreamer" "gst-plugins-base"
        # SDL
        "sdl2"
        # System libraries
        "dbus" "systemd" "libunwind"
        # Optional but recommended
        "libxml2" "libxslt" "libjpeg-turbo" "libpng"
        "libtiff" "lcms2" "libusb" "libpcap"
        "ncurses" "krb5" "unixodbc" "v4l-utils"
        "libgphoto2" "sane" "pcsc-tools"
        # Multimedia (optional)
        "ffmpeg"
        # ISDN (optional) - may not be available in all repos
        "libcapi"
      )
      for pkg in "${required_packages[@]}"; do
        if check_package_installed_pacman "$pkg"; then
          echo "  ✓ $pkg is already installed"
        else
          echo "  ✗ $pkg is missing"
          packages_to_install+=("$pkg")
        fi
      done
      
      if [ ${#packages_to_install[@]} -gt 0 ]; then
        echo "Installing missing packages: ${packages_to_install[*]}"
        sudo pacman -S --noconfirm "${packages_to_install[@]}" 2>/dev/null || \
        sudo pacman -S --noconfirm "${packages_to_install[@]}"
        echo "  ✓ Package installation complete"
      else
        echo "  ✓ All required packages are already installed"
      fi
      ;;
    *)
      echo "Warning: Unknown package manager. Skipping package installation."
      ;;
  esac
}


# Auto-detect Wine version and apply patches
apply_patches() {
  local wine_src_dir="${1:-../wine-src}"
  
  # Try to detect Wine version from VERSION file or configure.ac
  local wine_version=""
  if [ -f "$wine_src_dir/VERSION" ]; then
    # VERSION file format: "Wine version 10.4" or "wine-10.4"
    wine_version=$(cat "$wine_src_dir/VERSION" | head -n1 | sed -E 's/^(Wine version |wine-)([0-9.]+).*/\2/' | head -n1)
  elif [ -f "$wine_src_dir/configure.ac" ]; then
    # Try to extract from configure.ac - look for WINE_VERSION definition
    wine_version=$(grep -E "^WINE_VERSION=" "$wine_src_dir/configure.ac" | head -n1 | sed -E 's/.*WINE_VERSION=([0-9.]+).*/\1/')
    # If that doesn't work, try AC_INIT
    if [ -z "$wine_version" ]; then
      wine_version=$(grep -E "^AC_INIT.*wine" "$wine_src_dir/configure.ac" | sed -n 's/.*\[\([0-9.]*\)\].*/\1/p' | head -n1)
    fi
  fi
  
  if [ -z "$wine_version" ]; then
    echo "Warning: Could not detect Wine version. Skipping patch application."
    return
  fi
  
  echo "Detected Wine version: $wine_version"
  
  # Find matching patch directory (e.g., wine-10.1, wine-9.22)
  local patch_dir=""
  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local current_dir="$(pwd)"
  
  # Check if patches directory exists relative to script, current directory, or wine source
  if [ -d "$script_dir/patches" ]; then
    local patches_base="$script_dir/patches"
  elif [ -d "$current_dir/patches" ]; then
    local patches_base="$current_dir/patches"
  elif [ -d "$(dirname "$wine_src_dir")/patches" ]; then
    local patches_base="$(dirname "$wine_src_dir")/patches"
  elif [ -d "./patches" ]; then
    local patches_base="./patches"
  elif [ -d "../patches" ]; then
    local patches_base="../patches"
  else
    echo "Warning: Patches directory not found. Skipping patch application."
    return
  fi
  
  # Try to find exact version match first
  if [ -d "$patches_base/wine-$wine_version" ]; then
    patch_dir="$patches_base/wine-$wine_version"
  else
    # Try to find closest version match (e.g., 10.1 matches wine-10.1)
    local major_minor=$(echo "$wine_version" | cut -d'.' -f1,2)
    if [ -d "$patches_base/wine-$major_minor" ]; then
      patch_dir="$patches_base/wine-$major_minor"
    else
      # Try to find any matching directory
      local found_dir=$(find "$patches_base" -maxdepth 1 -type d -name "wine-*" | head -n1)
      if [ -n "$found_dir" ]; then
        patch_dir="$found_dir"
        echo "Using patch directory: $patch_dir (version may not match exactly)"
      fi
    fi
  fi
  
  if [ -z "$patch_dir" ] || [ ! -d "$patch_dir" ]; then
    echo "Warning: No matching patch directory found for version $wine_version. Skipping patch application."
    return
  fi
  
  echo "Applying patches from: $patch_dir"
  
  # Apply all .patch files in the directory (excluding SHA256SUMS.txt)
  local patch_count=0
  local saved_dir="$(pwd)"
  
  # Change to wine source directory to apply patches
  if [ ! -d "$wine_src_dir" ]; then
    echo "Warning: Wine source directory '$wine_src_dir' not found. Skipping patch application."
    return
  fi
  
  cd "$wine_src_dir" || return
  
  # Sort patch files to apply in order
  for patch_file in $(ls "$patch_dir"/*.patch 2>/dev/null | sort); do
    if [ -f "$patch_file" ]; then
      echo "Applying patch: $(basename "$patch_file")"
      # Try normal apply first, then with fuzz if needed
      if patch -p1 --no-backup-if-mismatch -i "$patch_file" >/dev/null 2>&1; then
        ((patch_count++))
        echo "  ✓ Successfully applied"
      elif patch -p1 --no-backup-if-mismatch --fuzz=3 -i "$patch_file" >/dev/null 2>&1; then
        ((patch_count++))
        echo "  ✓ Successfully applied (with fuzz)"
      elif patch -p1 --dry-run -i "$patch_file" 2>&1 | grep -q "Reversed (or previously applied)"; then
        # Patch is already applied (reversed), count as success
        ((patch_count++))
        echo "  ✓ Already applied (skipped)"
      elif patch -p1 --dry-run -i "$patch_file" 2>&1 | grep -q "already exists"; then
        # Files already exist, patch likely already applied
        ((patch_count++))
        echo "  ✓ Already applied (files exist)"
      else
        echo "  ✗ Failed to apply (may already be applied or incompatible)"
      fi
    fi
  done
  
  # Return to original directory
  cd "$saved_dir" || return
  
  if [ $patch_count -eq 0 ]; then
    echo "No patches were applied."
  else
    echo "Applied $patch_count patch(es)."
  fi
}

silent_warnings=(
  "-Wno-discarded-qualifiers"
  "-Wno-format"
  "-Wno-maybe-uninitialized"
  "-Wno-misleading-indentation"
)

# Generic flags for x86-64-v2 compatibility (for native Wine binaries)
# These run on the host Linux system, so they need v2 support for v2+ CPUs
export CFLAGS="-march=x86-64-v2 -mtune=generic -O2 -pipe"
export CXXFLAGS="$CFLAGS"

# Flags for cross-compilation (for Windows PE binaries)
# These don't need v2 flags - they just need correct architecture flags for i386/x86_64
# Using v2 flags here causes build failures with i386 cross-compilation
export CROSSCFLAGS="-O2 -pipe"
export CROSSCXXFLAGS="$CROSSCFLAGS"
# Add -lmingwex to link MinGW extended math library (needed for functions like truncf in GCC 15/MinGW)
# MinGW uses libmingwex.a instead of libm.a for math functions
export CROSSLDFLAGS="-Wl,-O1 -lmingwex"

if [ "$BUILD_DEBUG" = "1" ]; then
  CFLAGS+=" -g"; CXXFLAGS+=" -g"; CROSSCFLAGS+=" -g"; CROSSCXXFLAGS+=" -g"
fi

# Get available Wine versions from patches directory
get_available_versions() {
  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local patches_dir=""
  
  if [ -d "$script_dir/patches" ]; then
    patches_dir="$script_dir/patches"
  elif [ -d "./patches" ]; then
    patches_dir="./patches"
  else
    echo ""
    return
  fi
  
  # Find all wine-* directories and extract version numbers
  find "$patches_dir" -maxdepth 1 -type d -name "wine-*" | \
    sed 's|.*/wine-||' | sort -V
}

# Show version selection menu
select_wine_version() {
  local versions=($(get_available_versions))
  
  if [ ${#versions[@]} -eq 0 ]; then
    echo "Error: No patch directories found. Cannot determine available Wine versions."
    exit 1
  fi
  
  # If WINE_VERSION is set via environment variable, use it
  if [ -n "$WINE_VERSION" ]; then
    # Validate the version exists
    for v in "${versions[@]}"; do
      if [ "$v" = "$WINE_VERSION" ]; then
        echo "$WINE_VERSION"
        return
      fi
    done
    echo "Warning: WINE_VERSION=$WINE_VERSION not found in patches. Available versions: ${versions[*]}" >&2
  fi
  
  # Output menu to stderr so it displays even when function output is captured
  echo "" >&2
  echo "==========================================" >&2
  echo "Available Wine versions (with patches):" >&2
  echo "==========================================" >&2
  echo "" >&2
  local i=1
  for version in "${versions[@]}"; do
    printf "  %d) Wine version %s\n" "$i" "$version" >&2
    ((i++))
  done
  printf "  %d) Exit\n" "$i" >&2
  echo "" >&2
  echo "==========================================" >&2
  echo "" >&2
  echo "Example: Enter '1' to build Wine 9.14, '2' for Wine 9.16, etc." >&2
  echo "" >&2
  
  while true; do
    echo -n "Select Wine version to build [1-$i]: " >&2
    read choice
    
    if [ "$choice" = "$i" ] || [ -z "$choice" ]; then
      echo "Exiting." >&2
      exit 0
    fi
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -lt "$i" ]; then
      local selected_version="${versions[$((choice-1))]}"
      echo "" >&2
      echo "✓ Selected: Wine version $selected_version" >&2
      echo "" >&2
      # Output version to stdout for capture
      echo "$selected_version"
      return
    else
      echo "Invalid choice. Please enter a number between 1 and $i." >&2
    fi
  done
}

# Download Wine source code
download_wine_source() {
  local version="$1"
  local download_dir="${2:-./wine-src}"
  
  # Save current directory
  local original_dir="$(pwd)"
  
  # Convert to absolute path early (before changing directories)
  if [[ "$download_dir" != /* ]]; then
    # Handle relative paths
    if [[ "$download_dir" == ./* ]]; then
      download_dir="$original_dir/$(echo "$download_dir" | sed 's|^\./||')"
    elif [[ "$download_dir" == ../* ]]; then
      download_dir="$(cd "$(dirname "$download_dir")" && pwd)/$(basename "$download_dir")"
    else
      download_dir="$original_dir/$download_dir"
    fi
  fi
  
  local wine_url="https://dl.winehq.org/wine/source/${version%.*}.x/wine-${version}.tar.xz"
  local wine_file="wine-${version}.tar.xz"
  local wine_dir="wine-${version}"
  
  # Check if already downloaded and extracted
  if [ -d "$download_dir" ] && [ -f "$download_dir/configure" ]; then
    echo "Wine source already exists at: $download_dir"
    read -p "Use existing source? [Y/n]: " use_existing
    if [[ ! "$use_existing" =~ ^[Nn]$ ]]; then
      return 0
    fi
    # User wants to re-download, so remove existing directory
    echo "Removing existing $download_dir..."
    rm -rf "$download_dir"
  fi
  
  # Remove target directory if it exists (even without configure, to avoid nested structure)
  if [ -d "$download_dir" ]; then
    echo "Removing existing $download_dir (may be incomplete)..."
    rm -rf "$download_dir"
  fi
  
  # Create download directory parent if needed
  mkdir -p "$(dirname "$download_dir")"
  local temp_dir=$(mktemp -d)
  cd "$temp_dir" || exit 1
  
  echo ""
  echo "Downloading Wine $version..."
  echo "URL: $wine_url"
  echo ""
  echo "Download progress:"
  echo "-------------------"
  
  # Try to download with progress display
  if command -v wget >/dev/null 2>&1; then
    # wget shows progress on stderr, so we need to let it through
    if ! wget --progress=bar:force:noscroll "$wine_url" -O "$wine_file"; then
      echo ""
      echo "Error: Failed to download Wine source."
      cd - >/dev/null || exit 1
      rm -rf "$temp_dir"
      return 1
    fi
  elif command -v curl >/dev/null 2>&1; then
    # curl --progress-bar shows a progress bar
    if ! curl -L --progress-bar --fail -o "$wine_file" "$wine_url"; then
      echo ""
      echo "Error: Failed to download Wine source."
      cd - >/dev/null || exit 1
      rm -rf "$temp_dir"
      return 1
    fi
    echo ""  # New line after curl progress bar
  else
    echo "Error: Neither wget nor curl found. Please install one to download Wine source."
    cd - >/dev/null || exit 1
    rm -rf "$temp_dir"
    return 1
  fi
  
  echo "-------------------"
  echo "Download complete!"
  echo ""
  
  echo ""
  echo "Extracting Wine source..."
  if ! tar -xf "$wine_file"; then
    echo "Error: Failed to extract Wine source."
    cd - >/dev/null || exit 1
    rm -rf "$temp_dir"
    return 1
  fi
  
  # Check what was extracted
  echo "Checking extracted contents..."
  ls -la
  
  # Move extracted directory to target location
  if [ -d "$wine_dir" ]; then
    # Always remove target directory if it exists (even if empty)
    if [ -d "$download_dir" ]; then
      echo "Removing existing $download_dir..."
      rm -rf "$download_dir"
    fi
    
    # Ensure parent directory exists
    mkdir -p "$(dirname "$download_dir")"
    
    # Move the wine directory to the target location
    mv "$wine_dir" "$download_dir"
    echo "Wine source extracted to: $download_dir"
    
    # Verify the move worked and configure exists
    if [ ! -d "$download_dir" ]; then
      echo "Error: Failed to move extracted directory to $download_dir"
      cd - >/dev/null || exit 1
      rm -rf "$temp_dir"
      return 1
    fi
  else
    echo "Error: Extracted directory '$wine_dir' not found."
    echo "Contents of extraction directory:"
    ls -la
    cd - >/dev/null || exit 1
    rm -rf "$temp_dir"
    return 1
  fi
  
  # Cleanup temp directory
  cd - >/dev/null || exit 1
  rm -rf "$temp_dir"
  
  # Verify configure script exists (using absolute path)
  if [ ! -f "$download_dir/configure" ]; then
    # Check if we have a nested structure (wine-src/wine-X.X/)
    local nested_dir=""
    for possible_dir in "$download_dir"/wine-*; do
      if [ -d "$possible_dir" ] && [ -f "$possible_dir/configure" ]; then
        nested_dir="$possible_dir"
        break
      fi
    done
    
    if [ -n "$nested_dir" ]; then
      echo "Found nested directory structure. Fixing..."
      echo "Moving contents from $nested_dir to $download_dir..."
      
      # Create temp location
      local temp_fix=$(mktemp -d)
      mv "$download_dir"/* "$temp_fix/" 2>/dev/null
      rm -rf "$download_dir"
      mv "$temp_fix"/* "$download_dir/" 2>/dev/null
      rmdir "$temp_fix"
      
      # Verify configure now exists
      if [ -f "$download_dir/configure" ]; then
        echo "✓ Fixed nested structure. Configure script found."
      else
        echo "Error: Still could not find configure script after fix attempt."
        return 1
      fi
    else
      echo "Error: configure script not found after extraction."
      echo "Expected at: $download_dir/configure"
      echo "Checking if directory exists:"
      if [ -d "$download_dir" ]; then
        echo "Directory exists. Contents:"
        ls -la "$download_dir" | head -20
      else
        echo "Directory does not exist: $download_dir"
      fi
      return 1
    fi
  fi
  
  echo "✓ Configure script verified at: $download_dir/configure"
  
  return 0
}

# Detect wine source directory or download it
WINE_SRC_DIR=""
SELECTED_VERSION=""

# First, check if wine source already exists
if [ -d "../wine-src" ] && [ -f "../wine-src/configure" ]; then
  WINE_SRC_DIR="../wine-src"
elif [ -d "./wine-src" ] && [ -f "./wine-src/configure" ]; then
  WINE_SRC_DIR="./wine-src"
elif [ -f "./configure" ]; then
  # Wine source is in current directory
  WINE_SRC_DIR="."
elif [ -d "wine-src" ] && [ -f "wine-src/configure" ]; then
  WINE_SRC_DIR="wine-src"
fi

# If wine source not found, show menu and download
if [ -z "$WINE_SRC_DIR" ]; then
  echo ""
  echo "Wine source directory not found."
  echo ""
  
  # Show version selection menu
  SELECTED_VERSION=$(select_wine_version)
  
  if [ -z "$SELECTED_VERSION" ]; then
    echo "No version selected. Exiting."
    exit 1
  fi
  
  # Determine download location (always use ./wine-src relative to current directory)
  download_location="./wine-src"
  
  echo ""
  echo "Preparing to download Wine $SELECTED_VERSION source code..."
  echo "This may take a few minutes depending on your internet connection."
  echo ""
  
  # Download the selected version
  if ! download_wine_source "$SELECTED_VERSION" "$download_location"; then
    echo "Error: Failed to download Wine source. Exiting."
    exit 1
  fi
  
  echo ""
  echo "✓ Wine $SELECTED_VERSION source code downloaded and extracted successfully!"
  echo ""
  
  WINE_SRC_DIR="$download_location"
fi

# Convert to absolute path for consistency
WINE_SRC_DIR="$(cd "$WINE_SRC_DIR" && pwd)"
echo ""
echo "Using Wine source directory: $WINE_SRC_DIR"

# If we downloaded a version, use it for patch matching
if [ -n "$SELECTED_VERSION" ]; then
  echo "Building Wine version: $SELECTED_VERSION"
fi

# Prepare the build environment - create all necessary directories
echo "Creating build directories..."
mkdir -p wine64-build
mkdir -p "$WINE_SRC_DIR/wine-install"
echo "Build directories created"

# Delete old log files for fresh start
rm -f wine-build.log wine64-build.log wine32-build.log Affinity.log 2>/dev/null || true

# Initialize build failure flag
BUILD_FAILED=0

# Apply patches before building
echo
echo "Applying patches to Wine source..."
echo
apply_patches "$WINE_SRC_DIR"

###############################################################################
# Build Wine (64-bit)
###############################################################################
echo
echo "Preparing build environment for Wine..."
echo

# Ensure build directory exists
mkdir -p wine64-build
cd wine64-build || { echo "Error: Failed to change to wine64-build directory"; exit 1; }

# Install packages (may require sudo password)
install_packages_64bit

# Determine install prefix
INSTALL_PREFIX="$HOME/Documents/ElementalWarrior-wine"
if [ -d "/wine-builder" ]; then
  INSTALL_PREFIX="/wine-builder/wine-src/wine-install"
fi

# Check if OpenCL headers are available (mandatory)
if ! check_opencl_headers; then
  echo ""
  echo "❌ ERROR: OpenCL headers not found!"
  echo "OpenCL is required for this build."
  echo ""
  echo "Installing OpenCL headers..."
  echo "  (This may require your sudo password)"
  
  opencl_packages=()
  case "$PKG_MGR" in
    dnf)
      if ! check_package_installed_dnf "opencl-headers"; then
        opencl_packages+=("opencl-headers")
      fi
      if ! check_package_installed_dnf "ocl-icd-devel"; then
        opencl_packages+=("ocl-icd-devel")
      fi
      if [ ${#opencl_packages[@]} -gt 0 ]; then
        echo "  Installing missing OpenCL packages: ${opencl_packages[*]}"
        sudo dnf install -y --allowerasing "${opencl_packages[@]}"
      else
        echo "  ✓ OpenCL packages are already installed"
      fi
      ;;
    pacman)
      if ! check_package_installed_pacman "opencl-headers"; then
        opencl_packages+=("opencl-headers")
      fi
      if [ ${#opencl_packages[@]} -gt 0 ]; then
        echo "  Installing missing OpenCL packages: ${opencl_packages[*]}"
        sudo pacman -S --noconfirm "${opencl_packages[@]}"
      else
        echo "  ✓ OpenCL packages are already installed"
      fi
      ;;
    apt)
      if ! check_package_installed_apt "ocl-icd-opencl-dev"; then
        opencl_packages+=("ocl-icd-opencl-dev")
      fi
      if [ ${#opencl_packages[@]} -gt 0 ]; then
        echo "  Installing missing OpenCL packages: ${opencl_packages[*]}"
        sudo apt install -y "${opencl_packages[@]}"
      else
        echo "  ✓ OpenCL packages are already installed"
      fi
      ;;
  esac
  
  # Check again after installation
  if ! check_opencl_headers; then
    echo ""
    echo "❌ ERROR: OpenCL headers still not found after installation!"
    echo "Please install OpenCL development packages manually:"
    case "$PKG_MGR" in
      dnf)
        echo "  sudo dnf install --allowerasing opencl-headers ocl-icd-devel"
        ;;
      pacman)
        echo "  sudo pacman -S opencl-headers"
        ;;
      apt)
        echo "  sudo apt install ocl-icd-opencl-dev"
        ;;
    esac
    exit 1
  fi
fi

echo "✓ OpenCL headers found, enabling OpenCL support"
OPENCL_FLAG="--enable-opencl"

# Check if PE cross-compilers are available (required for --enable-archs=i386,x86_64)
check_cross_compiler_i386() {
  if command -v i686-w64-mingw32-gcc >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

check_cross_compiler_x86_64() {
  if command -v x86_64-w64-mingw32-gcc >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

# Check and install i386 PE cross-compiler
if ! check_cross_compiler_i386; then
  echo ""
  echo "❌ ERROR: i386 PE cross-compiler (i686-w64-mingw32-gcc) not found!"
  echo "This is required when building with --enable-archs=i386"
  echo ""
  echo "Installing MinGW i386 cross-compiler..."
  echo "  (This may require your sudo password)"
  
  case "$PKG_MGR" in
    dnf)
      if ! check_package_installed_dnf "mingw32-gcc"; then
        echo "  Installing mingw32-gcc..."
        sudo dnf install -y --allowerasing mingw32-gcc
      else
        echo "  ✓ mingw32-gcc package is installed, but compiler not found in PATH"
        echo "  Please ensure mingw32-gcc is properly installed and in your PATH"
      fi
      ;;
    pacman)
      if ! check_package_installed_pacman "mingw-w64-gcc"; then
        echo "  Installing mingw-w64-gcc..."
        sudo pacman -S --noconfirm mingw-w64-gcc
      else
        echo "  ✓ mingw-w64-gcc package is installed, but compiler not found in PATH"
        echo "  Please ensure mingw-w64-gcc is properly installed and in your PATH"
      fi
      ;;
    apt)
      if ! check_package_installed_apt "gcc-mingw-w64"; then
        echo "  Installing gcc-mingw-w64..."
        sudo apt install -y gcc-mingw-w64
      else
        echo "  ✓ gcc-mingw-w64 package is installed, but compiler not found in PATH"
        echo "  Please ensure gcc-mingw-w64 is properly installed and in your PATH"
      fi
      ;;
  esac
  
  # Check again after installation
  if ! check_cross_compiler_i386; then
    echo ""
    echo "❌ ERROR: i386 PE cross-compiler still not found after installation!"
    echo "Please install the MinGW cross-compiler manually:"
    case "$PKG_MGR" in
      dnf)
        echo "  sudo dnf install --allowerasing mingw32-gcc"
        ;;
      pacman)
        echo "  sudo pacman -S mingw-w64-gcc"
        ;;
      apt)
        echo "  sudo apt install gcc-mingw-w64"
        ;;
    esac
    exit 1
  fi
fi

echo "✓ i386 PE cross-compiler found (i686-w64-mingw32-gcc)"

# Check and install x86_64 PE cross-compiler
if ! check_cross_compiler_x86_64; then
  echo ""
  echo "❌ ERROR: x86_64 PE cross-compiler (x86_64-w64-mingw32-gcc) not found!"
  echo "This is required when building with --enable-archs=x86_64"
  echo ""
  echo "Installing MinGW x86_64 cross-compiler..."
  echo "  (This may require your sudo password)"
  
  case "$PKG_MGR" in
    dnf)
      if ! check_package_installed_dnf "mingw64-gcc"; then
        echo "  Installing mingw64-gcc..."
        sudo dnf install -y --allowerasing mingw64-gcc
      else
        echo "  ✓ mingw64-gcc package is installed, but compiler not found in PATH"
        echo "  Please ensure mingw64-gcc is properly installed and in your PATH"
      fi
      ;;
    pacman)
      if ! check_package_installed_pacman "mingw-w64-gcc"; then
        echo "  Installing mingw-w64-gcc..."
        sudo pacman -S --noconfirm mingw-w64-gcc
      else
        echo "  ✓ mingw-w64-gcc package is installed, but compiler not found in PATH"
        echo "  Please ensure mingw-w64-gcc is properly installed and in your PATH"
      fi
      ;;
    apt)
      if ! check_package_installed_apt "gcc-mingw-w64"; then
        echo "  Installing gcc-mingw-w64..."
        sudo apt install -y gcc-mingw-w64
      else
        echo "  ✓ gcc-mingw-w64 package is installed, but compiler not found in PATH"
        echo "  Please ensure gcc-mingw-w64 is properly installed and in your PATH"
      fi
      ;;
  esac
  
  # Check again after installation
  if ! check_cross_compiler_x86_64; then
    echo ""
    echo "❌ ERROR: x86_64 PE cross-compiler still not found after installation!"
    echo "Please install the MinGW cross-compiler manually:"
    case "$PKG_MGR" in
      dnf)
        echo "  sudo dnf install --allowerasing mingw64-gcc"
        ;;
      pacman)
        echo "  sudo pacman -S mingw-w64-gcc"
        ;;
      apt)
        echo "  sudo apt install gcc-mingw-w64"
        ;;
    esac
    exit 1
  fi
fi

echo "✓ x86_64 PE cross-compiler found (x86_64-w64-mingw32-gcc)"

# Run configure and capture exit status
# Note: --disable-tests is required due to truncf linking issues with GCC 15/MinGW
# Test executables try to use truncf from ucrtbase but link against msvcrt instead
if [ "$BUILD_WAYLAND" = "0" ]; then
  "$WINE_SRC_DIR/configure" --prefix="$INSTALL_PREFIX" \
    $OPENCL_FLAG --enable-archs=i386,x86_64 --disable-tests --without-wayland 2>&1 | grep -v "configure: OSS sound system found but too old (OSSv4 needed)"
  CONFIGURE_EXIT=${PIPESTATUS[0]}
else
  "$WINE_SRC_DIR/configure" --prefix="$INSTALL_PREFIX" \
    $OPENCL_FLAG --enable-archs=i386,x86_64 --disable-tests 2>&1 | grep -v "configure: OSS sound system found but too old (OSSv4 needed)"
  CONFIGURE_EXIT=${PIPESTATUS[0]}
  # Silent configure warning; sound support is via ALSA
fi

# Check configure exit status (must check immediately after PIPESTATUS)
if [ "$CONFIGURE_EXIT" -ne 0 ]; then
  BUILD_FAILED=1
  echo "❌ ERROR: Wine configure failed!"
  exit 1
fi

echo "Building Wine (64-bit only)..."
echo

# Build Wine and capture errors
BUILD_LOG="wine-build.log"
if ! make -j$BUILD_THREADS >"$BUILD_LOG" 2>&1; then
  BUILD_FAILED=1
  echo ""
  echo "❌ ERROR: Wine build failed!"
  echo "Build log saved to: $BUILD_LOG"
  echo ""
  echo "Last 20 lines of build log:"
  tail -20 "$BUILD_LOG"
  echo ""
else
  # Filter out parser/sql warnings from output
  grep -Ev "(parser|sql)\.y: (warning|note):" "$BUILD_LOG" || true
  echo "✓ Wine build completed successfully"
fi

# Install Wine (only if build succeeded)
if [ "${BUILD_FAILED:-0}" != "1" ]; then
  echo "Installing Wine (using $BUILD_THREADS threads)..."
  if ! make install -j$BUILD_THREADS >/dev/null 2>&1; then
    BUILD_FAILED=1
    echo "❌ ERROR: Failed to install Wine"
  else
    echo "✓ Wine installed successfully"
    
    # Package Wine as .tar.xz
    if [ -d "$INSTALL_PREFIX" ] && [ "$(basename "$INSTALL_PREFIX")" = "ElementalWarrior-wine" ]; then
      echo ""
      echo "Packaging Wine as .tar.xz..."
      cd "$(dirname "$INSTALL_PREFIX")" || exit 1
      WINE_VERSION="${SELECTED_VERSION:-unknown}"
      PACKAGE_NAME="ElementalWarrior-wine-${WINE_VERSION}.tar.xz"
      if tar -cJf "$PACKAGE_NAME" "$(basename "$INSTALL_PREFIX")" 2>/dev/null; then
        echo "✓ Wine packaged successfully: $PACKAGE_NAME"
        echo "  Location: $(pwd)/$PACKAGE_NAME"
        echo "  Size: $(du -h "$PACKAGE_NAME" | cut -f1)"
      else
        echo "⚠ Warning: Failed to create package, but Wine is installed at: $INSTALL_PREFIX"
      fi
    fi
  fi
fi


echo
if [ "${BUILD_FAILED:-0}" = "1" ]; then
  echo "=========================================="
  echo "❌ BUILD FAILED!"
  echo "=========================================="
  echo ""
  echo "Build logs saved:"
  [ -f "wine-build.log" ] && echo "  - wine-build.log"
  echo ""
  echo "Please check the logs above for error details."
  echo "Common issues:"
  echo "  - Missing development packages (run script again to auto-install)"
  echo "  - OpenCL headers not found (required - install ocl-icd-devel/opencl-headers)"
  echo ""
  exit 1
else
  echo "=========================================="
  echo "✓ BUILD COMPLETE!"
  echo "=========================================="
  echo ""
  echo "Final output is in: $INSTALL_PREFIX"
  echo ""
fi
