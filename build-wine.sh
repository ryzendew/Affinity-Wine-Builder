#!/bin/bash
#
# Wine Build Script
# Builds Wine from source with automatic patch application
# Professional, user-friendly interactive build system
#
# Features:
#   - Interactive menu to select Wine version (from available patches)
#   - Automatic download of Wine source code
#   - Automatic patch application
#   - Multi-distro support (Arch, Fedora, Debian/Ubuntu/Mint/Zorin)
#   - Auto-detects CPU threads and package manager
#   - User-friendly prompts and dependency management
#
# Usage:
#   ./build-wine.sh                           # Interactive menu to select version
#   WINE_VERSION=10.1 ./build-wine.sh        # Build specific version (skip menu)
#   BUILD_THREADS=8 ./build-wine.sh           # Use 8 threads
#   BUILD_DEBUG=1 ./build-wine.sh             # Build with debug symbols
#   BUILD_WAYLAND=0 ./build-wine.sh           # Disable Wayland support
#

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Print banner
print_banner() {
  clear
  echo -e "${CYAN}${BOLD}"
  echo "╔════════════════════════════════════════════════════════════════╗"
  echo "║                                                                ║"
  echo "║           Wine Build Script - Professional Edition             ║"
  echo "║                                                                ║"
  echo "║     Automated Wine compilation with patch support              ║"
  echo "║                                                                ║"
  echo "╚════════════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
}

# Detect distribution information
detect_distribution() {
  local distro_id=""
  local distro_name=""
  local distro_version=""
  local distro_pretty=""
  
  if [ -f /etc/os-release ]; then
    distro_id=$(grep "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')
    distro_name=$(grep "^NAME=" /etc/os-release | cut -d= -f2 | tr -d '"')
    distro_version=$(grep "^VERSION_ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
    distro_pretty=$(grep "^PRETTY_NAME=" /etc/os-release | cut -d= -f2 | tr -d '"')
  fi
  
  # Map common distro IDs to friendly names
  case "$distro_id" in
    ubuntu)
      distro_name="Ubuntu"
      ;;
    linuxmint|mint)
      distro_name="Linux Mint"
      ;;
    zorin)
      distro_name="Zorin OS"
      ;;
    debian)
      distro_name="Debian"
      ;;
    fedora)
      distro_name="Fedora"
      ;;
    arch|archlinux)
      distro_name="Arch Linux"
      ;;
    pikaos)
      distro_name="PikaOS"
      ;;
  esac
  
  echo "$distro_name|$distro_version|$distro_pretty"
}

# Display system information
display_system_info() {
  local distro_info=$(detect_distribution)
  local distro_name=$(echo "$distro_info" | cut -d'|' -f1)
  local distro_version=$(echo "$distro_info" | cut -d'|' -f2)
  local distro_pretty=$(echo "$distro_info" | cut -d'|' -f3)
  
  # Auto-detect CPU threads
  if command -v nproc >/dev/null 2>&1; then
    DETECTED_THREADS=$(nproc)
  elif [ -f /proc/cpuinfo ]; then
    DETECTED_THREADS=$(grep -c processor /proc/cpuinfo)
  else
    DETECTED_THREADS=4
  fi
  
  BUILD_THREADS="${BUILD_THREADS:-$DETECTED_THREADS}"
  
  echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}${BOLD}System Information:${NC}"
  echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "  ${BOLD}Distribution:${NC}     ${GREEN}${distro_pretty:-${distro_name} ${distro_version}}${NC}"
  echo -e "  ${BOLD}Package Manager:${NC} ${GREEN}${PKG_MGR}${NC}"
  echo -e "  ${BOLD}CPU Threads:${NC}     ${GREEN}${DETECTED_THREADS} (using ${BUILD_THREADS} for build)${NC}"
  echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

# Prompt for yes/no
prompt_yes_no() {
  local prompt_text="$1"
  local default="${2:-n}"
  local response
  
  while true; do
    if [ "$default" = "y" ]; then
      echo -ne "${YELLOW}${prompt_text} [Y/n]: ${NC}"
    else
      echo -ne "${YELLOW}${prompt_text} [y/N]: ${NC}"
    fi
    read -r response
    response=${response:-$default}
    case "$response" in
      [Yy]|[Yy][Ee][Ss])
        return 0
        ;;
      [Nn]|[Nn][Oo])
        return 1
        ;;
      *)
        echo -e "${RED}Please answer yes or no.${NC}"
        ;;
    esac
  done
}

# Initialize variables
BUILD_DEBUG="${BUILD_DEBUG:-0}"
BUILD_WAYLAND="${BUILD_WAYLAND:-1}"

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

# Detect package manager
PKG_MGR=$(detect_package_manager)

# Show banner and system info
print_banner
display_system_info

# Welcome message and confirmation
echo -e "${CYAN}${BOLD}Welcome to the Wine Build Script!${NC}"
echo ""
echo -e "This script will help you build Wine from source with the following features:"
echo -e "  • Automatic dependency detection and installation"
echo -e "  • Wine version selection from available patches"
echo -e "  • Automatic patch application"
echo -e "  • Optimized build configuration"
echo ""

if ! prompt_yes_no "Do you wish to continue?" "y"; then
  echo -e "${YELLOW}Build cancelled by user.${NC}"
  exit 0
fi
echo ""

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
  echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}${BOLD}Checking Build Dependencies${NC}"
  echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  local packages_to_install=()
  local missing_packages=()
  
  case "$PKG_MGR" in
    apt)
      # Detect Ubuntu/Debian-based distributions (Ubuntu, Mint, Zorin, Debian, PikaOS, etc.)
      local distro_name=""
      local distro_version=""
      if [ -f /etc/os-release ]; then
        distro_name=$(grep "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')
        distro_version=$(grep "^VERSION_ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
      fi
      
      echo "Detected distribution: ${distro_name:-unknown} ${distro_version:-unknown}"
      
      # Enable multiarch for 32-bit packages (required for Wine 32-bit support)
      if ! dpkg --print-architecture | grep -q i386 2>/dev/null; then
        echo "Enabling i386 architecture for 32-bit Wine support..."
        sudo dpkg --add-architecture i386 2>/dev/null || true
        sudo apt update 2>/dev/null || true
      fi
      
      # First, try to use apt build-dep which automatically installs all build dependencies
      # This works on Ubuntu, Debian, Mint, Zorin and other Debian-based distros
      echo "Attempting to install Wine build dependencies using 'apt build-dep wine'..."
      if sudo apt build-dep -y wine 2>/dev/null; then
        echo "  ✓ Wine build dependencies installed via build-dep"
        # Still need to ensure MinGW cross-compiler is installed
        if ! check_package_installed_apt "gcc-mingw-w64"; then
          echo "  Installing MinGW cross-compiler..."
          sudo apt install -y gcc-mingw-w64 2>/dev/null || true
        fi
        # Verify critical packages are actually installed (sometimes build-dep misses some)
        local critical_packages=("libfreetype6-dev" "libfontconfig1-dev" "pkg-config")
        local missing_critical=()
        for pkg in "${critical_packages[@]}"; do
          if ! check_package_installed_apt "$pkg"; then
            echo -e "  ${YELLOW}⚠ $pkg not found after build-dep, installing...${NC}"
            missing_critical+=("$pkg")
          fi
        done
        if [ ${#missing_critical[@]} -gt 0 ]; then
          echo "  Installing missing critical packages: ${missing_critical[*]}"
          sudo apt install -y "${missing_critical[@]}" 2>/dev/null || true
        fi
      else
        echo "  Note: 'apt build-dep wine' failed or wine package not available, installing packages manually..."
        local required_packages=(
          # Essential build tools (works on all Ubuntu/Debian variants)
          "build-essential"
          "gcc"
          "g++"
          "make"
          "bison"
          "flex"
          "gettext"
          "perl"
          "pkg-config"
          
          # MinGW cross-compilers (for PE binaries)
          "gcc-mingw-w64"
          "mingw-w64"
          
          # Core Wine dependencies - 64-bit versions
          # Note: samba-dev may not exist on all distros, Wine uses libsamba-dev or samba-libs-dev
          # We'll try samba-dev first, fallback handled by apt
          "samba-dev"
          "libsamba-dev"
          "libcups2-dev"
          "ocl-icd-opencl-dev"
          "opencl-headers"
          
          # Audio libraries - 64-bit
          "libasound2-dev"
          "libpulse-dev"
          
          # Font libraries - 64-bit
          "libfontconfig1-dev"
          "libfreetype6-dev"
          
          # X11 libraries - 64-bit
          "libx11-dev"
          "libxext-dev"
          "libxrender-dev"
          "libxrandr-dev"
          "libxinerama-dev"
          "libxi-dev"
          "libxcursor-dev"
          "libxfixes-dev"
          "libxcomposite-dev"
          "libxdamage-dev"
          "libxxf86vm-dev"
          "x11proto-dev"
          "x11proto-xinerama-dev"
          "x11proto-xf86vidmode-dev"
          
          # XKB support
          "libxkbcommon-dev"
          "libxkbcommon-x11-dev"
          
          # Graphics libraries - 64-bit
          # libgl1-mesa-dev is the correct package (libgl-dev is a virtual package)
          "libgl1-mesa-dev"
          "libglu1-mesa-dev"
          "mesa-common-dev"
          "libosmesa6-dev"
          
          # Vulkan support
          # vulkan-dev may not exist, libvulkan-dev is the standard package
          "libvulkan-dev"
          "vulkan-tools"
          "vulkan-validationlayers-dev"
          
          # Wayland support
          "libwayland-dev"
          "wayland-protocols"
          "libwayland-egl1-mesa-dev"
          
          # GStreamer - 64-bit
          "libgstreamer1.0-dev"
          "libgstreamer-plugins-base1.0-dev"
          "gstreamer1.0-plugins-base"
          
          # SDL - 64-bit
          "libsdl2-dev"
          
          # System libraries - 64-bit
          "libdbus-1-dev"
          "libudev-dev"
          "libunwind-dev"
          "libsystemd-dev"
          
          # GnuTLS for secure connections
          "libgnutls28-dev"
          
          # Optional but recommended - 64-bit
          "libxml2-dev"
          "libxslt1-dev"
          # JPEG support (libjpeg-turbo8-dev is preferred, libjpeg-dev is fallback)
          "libjpeg-turbo8-dev"
          "libjpeg-dev"
          "libpng-dev"
          # TIFF support (version may vary by distro)
          "libtiff-dev"
          "libtiff5-dev"
          "libtiffxx5"
          "liblcms2-dev"
          "libusb-1.0-0-dev"
          # pcap support (libpcap0.8-dev is the standard package)
          "libpcap0.8-dev"
          "libpcap-dev"
          # ncurses support (libncurses5-dev is standard, libncurses-dev is virtual)
          "libncurses5-dev"
          "libncurses-dev"
          "libncursesw5-dev"
          "libkrb5-dev"
          "unixodbc-dev"
          "libv4l-dev"
          "v4l-utils"
          "libgphoto2-dev"
          "libsane-dev"
          "libpcsclite-dev"
          "libgsm1-dev"
          "libmpg123-dev"
          "libopenal-dev"
          "libopenal1"
          
          # Multimedia libraries (optional)
          "libavcodec-dev"
          "libavformat-dev"
          "libavutil-dev"
          "libswscale-dev"
          "libswresample-dev"
          "libavfilter-dev"
          
          # ISDN support (optional, may not be available on all distros)
          "libcapi20-dev"
        )
        
        # Add 32-bit (i386) packages for Wine 32-bit support
        # These are required when building with --enable-archs=i386,x86_64
        local required_packages_i386=(
          "libasound2-dev:i386"
          "libpulse-dev:i386"
          "libdbus-1-dev:i386"
          "libfontconfig1-dev:i386"
          "libfreetype6-dev:i386"
          "libgnutls28-dev:i386"
          "libgl1-mesa-dev:i386"
          "libglu1-mesa-dev:i386"
          "libunwind-dev:i386"
          "libx11-dev:i386"
          "libxcomposite-dev:i386"
          "libxcursor-dev:i386"
          "libxfixes-dev:i386"
          "libxi-dev:i386"
          "libxrandr-dev:i386"
          "libxrender-dev:i386"
          "libxext-dev:i386"
          "libxinerama-dev:i386"
          "libgstreamer1.0-dev:i386"
          "libgstreamer-plugins-base1.0-dev:i386"
          "libosmesa6-dev:i386"
          "libsdl2-dev:i386"
          "libudev-dev:i386"
          "libvulkan-dev:i386"
          "libcapi20-dev:i386"
          "libcups2-dev:i386"
          "libgphoto2-dev:i386"
          "libsane-dev:i386"
          "libkrb5-dev:i386"
          "libpcap-dev:i386"
          "libusb-1.0-0-dev:i386"
          "ocl-icd-opencl-dev:i386"
        )
        
        # Check and collect missing 64-bit packages
        for pkg in "${required_packages[@]}"; do
          if check_package_installed_apt "$pkg"; then
            echo -e "  ${GREEN}✓${NC} $pkg ${GREEN}(installed)${NC}"
          else
            echo -e "  ${RED}✗${NC} $pkg ${YELLOW}(missing)${NC}"
            packages_to_install+=("$pkg")
            missing_packages+=("$pkg")
          fi
        done
        
        # Check and collect missing 32-bit packages
        for pkg in "${required_packages_i386[@]}"; do
          if check_package_installed_apt "$pkg"; then
            echo -e "  ${GREEN}✓${NC} $pkg ${GREEN}(installed)${NC}"
          else
            echo -e "  ${RED}✗${NC} $pkg ${YELLOW}(missing - 32-bit)${NC}"
            packages_to_install+=("$pkg")
            missing_packages+=("$pkg")
          fi
        done
        
        if [ ${#packages_to_install[@]} -gt 0 ]; then
          echo ""
          echo -e "${YELLOW}${BOLD}The following packages will be installed:${NC}"
          echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
          local count=1
          for pkg in "${missing_packages[@]}"; do
            printf "  %3d. %s\n" "$count" "$pkg"
            ((count++))
          done
          echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
          echo -e "${YELLOW}Total packages to install: ${#packages_to_install[@]}${NC}"
          echo ""
          
          if ! prompt_yes_no "Do you want to install these dependencies now? (sudo required)" "y"; then
            echo -e "${RED}Dependency installation cancelled. Cannot proceed without dependencies.${NC}"
            exit 1
          fi
          
          echo ""
          echo -e "${CYAN}Installing packages...${NC}"
          # Try to install all packages, some may fail if not available
          if sudo apt install -y "${packages_to_install[@]}" 2>/dev/null || \
             sudo apt install -y --fix-missing "${packages_to_install[@]}" 2>/dev/null; then
            echo -e "${GREEN}✓ Package installation completed successfully${NC}"
          else
            echo -e "${YELLOW}⚠ Some packages may have failed to install, but continuing...${NC}"
          fi
        else
          echo ""
          echo -e "${GREEN}${BOLD}✓ All required packages are already installed${NC}"
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
    echo -e "${RED}Error: No patch directories found. Cannot determine available Wine versions.${NC}"
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
    echo -e "${YELLOW}Warning: WINE_VERSION=$WINE_VERSION not found in patches. Available versions: ${versions[*]}${NC}" >&2
  fi
  
  # Output menu to stderr so it displays even when function output is captured
  echo "" >&2
  echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" >&2
  echo -e "${CYAN}${BOLD}Wine Version Selection${NC}" >&2
  echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" >&2
  echo "" >&2
  echo -e "${BOLD}Available Wine versions (with patches):${NC}" >&2
  echo "" >&2
  local i=1
  for version in "${versions[@]}"; do
    printf "  ${GREEN}%2d${NC}) ${CYAN}Wine version %s${NC}\n" "$i" "$version" >&2
    ((i++))
  done
  printf "  ${RED}%2d${NC}) ${YELLOW}Exit${NC}\n" "$i" >&2
  echo "" >&2
  echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" >&2
  echo "" >&2
  
  while true; do
    echo -ne "${YELLOW}Select Wine version to build [1-$i]: ${NC}" >&2
    read choice
    
    if [ "$choice" = "$i" ] || [ -z "$choice" ]; then
      echo -e "${YELLOW}Exiting.${NC}" >&2
      exit 0
    fi
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -lt "$i" ]; then
      local selected_version="${versions[$((choice-1))]}"
      echo "" >&2
      echo -e "${GREEN}${BOLD}✓ Selected: Wine version $selected_version${NC}" >&2
      echo "" >&2
      # Output version to stdout for capture
      echo "$selected_version"
      return
    else
      echo -e "${RED}Invalid choice. Please enter a number between 1 and $i.${NC}" >&2
    fi
  done
}

# Show build options menu
show_build_options_menu() {
  echo ""
  echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}${BOLD}Build Configuration Options${NC}"
  echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "${BOLD}Current Configuration:${NC}"
  echo -e "  ${BOLD}Wine Version:${NC}     ${GREEN}${SELECTED_VERSION:-Not selected}${NC}"
  echo -e "  ${BOLD}Build Threads:${NC}   ${GREEN}${BUILD_THREADS}${NC}"
  echo -e "  ${BOLD}Debug Symbols:${NC}   ${GREEN}$([ "$BUILD_DEBUG" = "1" ] && echo "Yes" || echo "No")${NC}"
  echo -e "  ${BOLD}Wayland Support:${NC} ${GREEN}$([ "$BUILD_WAYLAND" = "0" ] && echo "Disabled" || echo "Enabled")${NC}"
  echo -e "  ${BOLD}Install Prefix:${NC}   ${GREEN}${INSTALL_PREFIX}${NC}"
  echo ""
  echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  if prompt_yes_no "Proceed with build using these settings?" "y"; then
    return 0
  else
    echo -e "${YELLOW}Build cancelled by user.${NC}"
    exit 0
  fi
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

# Determine install prefix early (needed for build options menu)
INSTALL_PREFIX="$HOME/Documents/ElementalWarrior-wine"
if [ -d "/wine-builder" ]; then
  INSTALL_PREFIX="/wine-builder/wine-src/wine-install"
fi

# If wine source not found, show menu and download
if [ -z "$WINE_SRC_DIR" ]; then
  echo ""
  echo -e "${CYAN}${BOLD}Wine Source Code${NC}"
  echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${YELLOW}Wine source directory not found.${NC}"
  echo ""
  
  # Show version selection menu
  SELECTED_VERSION=$(select_wine_version)
  
  if [ -z "$SELECTED_VERSION" ]; then
    echo -e "${RED}No version selected. Exiting.${NC}"
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
echo -e "${GREEN}✓${NC} Using Wine source directory: ${CYAN}$WINE_SRC_DIR${NC}"

# If we downloaded a version, use it for patch matching
if [ -n "$SELECTED_VERSION" ]; then
  echo -e "${GREEN}✓${NC} Building Wine version: ${CYAN}${SELECTED_VERSION}${NC}"
fi

# Prepare the build environment - create all necessary directories
echo ""
echo -e "${CYAN}${BOLD}Preparing Build Environment${NC}"
echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Creating build directories..."
mkdir -p wine64-build
mkdir -p "$WINE_SRC_DIR/wine-install"
echo -e "${GREEN}✓${NC} Build directories created"

# Delete old log files for fresh start
rm -f wine-build.log wine64-build.log wine32-build.log Affinity.log 2>/dev/null || true

# Initialize build failure flag
BUILD_FAILED=0

# Store original directory for cleanup
ORIGINAL_DIR="$(pwd)"

# Cleanup function for build failures
cleanup_on_failure() {
  if [ "${BUILD_FAILED:-0}" = "1" ]; then
    echo ""
    echo -e "${YELLOW}${BOLD}Cleaning up build directories...${NC}"
    
    # Return to original directory
    cd "$ORIGINAL_DIR" 2>/dev/null || true
    
    # Remove wine64-build directory
    if [ -d "wine64-build" ]; then
      echo -e "${YELLOW}  Removing wine64-build directory...${NC}"
      rm -rf wine64-build
      echo -e "${GREEN}  ✓ wine64-build removed${NC}"
    fi
    
    # Remove wine-src directory
    if [ -d "wine-src" ]; then
      echo -e "${YELLOW}  Removing wine-src directory...${NC}"
      rm -rf wine-src
      echo -e "${GREEN}  ✓ wine-src removed${NC}"
    fi
    
    # Also check parent directory for wine-src
    if [ -d "../wine-src" ]; then
      echo -e "${YELLOW}  Removing ../wine-src directory...${NC}"
      rm -rf ../wine-src
      echo -e "${GREEN}  ✓ ../wine-src removed${NC}"
    fi
    
    echo -e "${GREEN}${BOLD}✓ Cleanup complete${NC}"
    echo ""
  fi
}

# Apply patches before building
echo ""
echo -e "${CYAN}${BOLD}Applying Patches${NC}"
echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
apply_patches "$WINE_SRC_DIR"
echo ""

# Install packages (may require sudo password) - BEFORE build options menu
echo ""
install_packages_64bit
echo ""

# Show build options menu before proceeding with build
show_build_options_menu

###############################################################################
# Build Wine (64-bit)
###############################################################################
echo ""
echo -e "${CYAN}${BOLD}Starting Wine Build${NC}"
echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Ensure build directory exists
mkdir -p wine64-build
cd wine64-build || { echo -e "${RED}Error: Failed to change to wine64-build directory${NC}"; exit 1; }

# Install prefix is already set above

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
    echo -e "${RED}❌ ERROR: OpenCL headers still not found after installation!${NC}"
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
    BUILD_FAILED=1
    cleanup_on_failure
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
    echo -e "${RED}❌ ERROR: i386 PE cross-compiler still not found after installation!${NC}"
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
    BUILD_FAILED=1
    cleanup_on_failure
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
    echo -e "${RED}❌ ERROR: x86_64 PE cross-compiler still not found after installation!${NC}"
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
    BUILD_FAILED=1
    cleanup_on_failure
    exit 1
  fi
fi

echo "✓ x86_64 PE cross-compiler found (x86_64-w64-mingw32-gcc)"

# Check for FreeType development files (required for font support)
check_freetype() {
  # Check for FreeType headers
  if [ -f "/usr/include/freetype2/freetype/freetype.h" ] || \
     [ -f "/usr/include/freetype/freetype.h" ] || \
     [ -f "/usr/local/include/freetype2/freetype/freetype.h" ]; then
    return 0
  fi
  # Also check if pkg-config can find it
  if pkg-config --exists freetype2 2>/dev/null; then
    return 0
  fi
  return 1
}

if ! check_freetype; then
  echo ""
  echo -e "${YELLOW}⚠ Warning: FreeType development files not found!${NC}"
  echo "FreeType is required for font support in Wine."
  echo ""
  echo "Attempting to install FreeType development packages..."
  
  case "$PKG_MGR" in
    apt)
      if ! check_package_installed_apt "libfreetype6-dev"; then
        echo "  Installing libfreetype6-dev..."
        sudo apt install -y libfreetype6-dev 2>/dev/null || true
      fi
      # Also ensure pkg-config is available
      if ! command -v pkg-config >/dev/null 2>&1; then
        echo "  Installing pkg-config..."
        sudo apt install -y pkg-config 2>/dev/null || true
      fi
      ;;
    dnf)
      if ! check_package_installed_dnf "freetype-devel"; then
        echo "  Installing freetype-devel..."
        sudo dnf install -y freetype-devel 2>/dev/null || true
      fi
      ;;
    pacman)
      if ! check_package_installed_pacman "freetype2"; then
        echo "  Installing freetype2..."
        sudo pacman -S --noconfirm freetype2 2>/dev/null || true
      fi
      ;;
  esac
  
  # Check again after installation
  if ! check_freetype; then
    echo ""
    echo -e "${RED}❌ ERROR: FreeType development files still not found after installation!${NC}"
    echo "Please install FreeType development packages manually:"
    case "$PKG_MGR" in
      dnf)
        echo "  sudo dnf install freetype-devel"
        ;;
      pacman)
        echo "  sudo pacman -S freetype2"
        ;;
      apt)
        echo "  sudo apt install libfreetype6-dev pkg-config"
        ;;
    esac
    BUILD_FAILED=1
    cleanup_on_failure
    exit 1
  fi
fi

echo -e "${GREEN}✓${NC} FreeType development files found"

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
  echo -e "${RED}❌ ERROR: Wine configure failed!${NC}"
  cleanup_on_failure
  exit 1
fi

echo -e "${CYAN}${BOLD}Building Wine${NC}"
echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}This may take a while... Would you like to play Tetris while waiting?${NC}"
echo ""

# Check for available Tetris games and auto-install if needed
find_tetris_game() {
  local games=("vitetris" "bastet" "tetris" "tint" "ntris")
  for game in "${games[@]}"; do
    if command -v "$game" >/dev/null 2>&1; then
      echo "$game"
      return 0
    fi
  done
  return 1
}

install_tetris_game() {
  echo -e "${CYAN}Installing Tetris game for your entertainment...${NC}"
  case "$PKG_MGR" in
    apt)
      # Try vitetris first, fallback to bastet
      if sudo apt install -y vitetris 2>/dev/null; then
        echo "vitetris"
        return 0
      elif sudo apt install -y bastet 2>/dev/null; then
        echo "bastet"
        return 0
      fi
      ;;
    dnf)
      if sudo dnf install -y vitetris 2>/dev/null; then
        echo "vitetris"
        return 0
      elif sudo dnf install -y bastet 2>/dev/null; then
        echo "bastet"
        return 0
      fi
      ;;
    pacman)
      if sudo pacman -S --noconfirm vitetris 2>/dev/null; then
        echo "vitetris"
        return 0
      elif sudo pacman -S --noconfirm bastet 2>/dev/null; then
        echo "bastet"
        return 0
      fi
      ;;
  esac
  return 1
}

TETRIS_GAME=$(find_tetris_game)
PLAY_TETRIS=false

if [ -z "$TETRIS_GAME" ]; then
  echo -e "${YELLOW}No Tetris game found. Auto-installing one for you...${NC}"
  TETRIS_GAME=$(install_tetris_game)
  if [ -n "$TETRIS_GAME" ]; then
    echo -e "${GREEN}✓ Tetris installed: $TETRIS_GAME${NC}"
  else
    echo -e "${YELLOW}⚠ Could not auto-install Tetris, but build will continue${NC}"
  fi
  echo ""
fi

if [ -n "$TETRIS_GAME" ]; then
  if prompt_yes_no "Play Tetris while building? (Game: $TETRIS_GAME)" "y"; then
    PLAY_TETRIS=true
  fi
fi

# Build Wine and capture errors
BUILD_LOG="wine-build.log"

if [ "$PLAY_TETRIS" = "true" ] && [ -n "$TETRIS_GAME" ]; then
  echo ""
  echo -e "${GREEN}Starting build in background...${NC}"
  echo -e "${CYAN}Launching $TETRIS_GAME - enjoy!${NC}"
  echo -e "${YELLOW}When you're done playing, the build will continue...${NC}"
  echo ""
  
  # Start build in background
  (make -j$BUILD_THREADS >"$BUILD_LOG" 2>&1) &
  BUILD_PID=$!
  
  # Launch Tetris
  $TETRIS_GAME 2>/dev/null || true
  
  # Wait for build to complete
  echo ""
  echo -e "${CYAN}Waiting for build to complete...${NC}"
  wait $BUILD_PID
  BUILD_EXIT=$?
  
  if [ $BUILD_EXIT -ne 0 ]; then
    BUILD_FAILED=1
  fi
else
  # Normal build without Tetris
  echo -e "${CYAN}Building... (this may take 10-30 minutes)${NC}"
  echo ""
  if ! make -j$BUILD_THREADS >"$BUILD_LOG" 2>&1; then
    BUILD_FAILED=1
  else
    BUILD_FAILED=0
  fi
fi

# Check build result
if [ "${BUILD_FAILED:-0}" = "1" ]; then
  echo ""
  echo -e "${RED}${BOLD}❌ ERROR: Wine build failed!${NC}"
  echo "Build log saved to: $BUILD_LOG"
  echo ""
  echo -e "${YELLOW}Last 20 lines of build log:${NC}"
  tail -20 "$BUILD_LOG"
  echo ""
else
  # Filter out parser/sql warnings from output
  grep -Ev "(parser|sql)\.y: (warning|note):" "$BUILD_LOG" || true
  echo ""
  echo -e "${GREEN}${BOLD}✓ Wine build completed successfully!${NC}"
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
  echo -e "${RED}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${RED}${BOLD}❌ BUILD FAILED!${NC}"
  echo -e "${RED}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Build logs saved:"
  [ -f "wine-build.log" ] && echo "  - wine-build.log"
  echo ""
  echo "Please check the logs above for error details."
  echo "Common issues:"
  echo "  - Missing development packages (run script again to auto-install)"
  echo "  - OpenCL headers not found (required - install ocl-icd-devel/opencl-headers)"
  echo ""
  
  # Cleanup on failure
  cleanup_on_failure
  
  exit 1
else
  echo "=========================================="
  echo "✓ BUILD COMPLETE!"
  echo "=========================================="
  echo ""
  echo "Final output is in: $INSTALL_PREFIX"
  echo ""
fi
