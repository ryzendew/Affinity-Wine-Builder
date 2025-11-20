# Build old Wine release

This is a fairly generic wine builder for building old releases.
It should be able to build any wine directory.

## Standalone Building (Recommended)

The script can be run directly without containers on Arch Linux, Fedora, or Debian/Ubuntu systems.

### Prerequisites

- Wine source code (download from https://www.winehq.org/download)
- Build dependencies (the script will install them automatically)
- Patches directory (included in this repository)

### Quick Start

1. Download and extract the Wine source code
2. Run the build script from the wine source directory or its parent:

```sh
# Option 1: Run from within the wine source directory
cd /path/to/wine-10.1/
/path/to/old-wine-builder/build-wine.sh

# Option 2: Run from parent directory (wine source in ./wine-src/)
cd /path/to/
/path/to/old-wine-builder/build-wine.sh

# Option 3: Run from the repository directory (wine source in ../wine-src/)
cd /path/to/old-wine-builder/
./build-wine.sh
```

The script will:
- Auto-detect your CPU threads and use all available cores
- Auto-detect your package manager (apt/dnf/pacman)
- Auto-apply matching patches from the `patches/` directory
- Build both 32-bit and 64-bit Wine
- Install to `wine-install/` in the wine source directory

### Build Options

Control the build with environment variables:

```sh
# Use 8 threads (defaults to all available CPU cores)
BUILD_THREADS=8 ./build-wine.sh

# Build with debug symbols
BUILD_DEBUG=1 ./build-wine.sh

# Disable Wayland support
BUILD_WAYLAND=0 ./build-wine.sh

# Combine options
BUILD_THREADS=8 BUILD_DEBUG=1 BUILD_WAYLAND=0 ./build-wine.sh
```

### After Building

The built Wine will be in `wine-install/` directory. You can move it to a final location:

```sh
# Move to your home directory with version suffix
mv wine-install $HOME/.wine-install-10.1

# Set your Wine prefix to this path
export WINEPREFIX=$HOME/.wine-install-10.1
wineboot -u
```

## Container Building (Alternative)

If you prefer to use containers, you can build and run the container image:

### Build the Container Image

```sh
podman build -t old-wine-builder -f Containerfile

# clear dangling images
podman system prune
```

### Run in Container

1. Download the wine src, either official or various forks.
   Choose Wine 10.1 if unsure which version.
2. Extract and navigate to the folder.
3. Run the docker image in the folder, using bind mount.

```sh
cd path-to/wine-source-folder/

# you can use `docker` instead of `podman`
podman run --rm --init -it -v ./:/wine-builder/wine-src old-wine-builder

# With options
podman run --rm --init -it -e BUILD_THREADS=8 -e BUILD_DEBUG=1 \
  -v ./:/wine-builder/wine-src old-wine-builder
```

If you are on Fedora or any distro using SELinux, append a `:Z` to the bind mount:

```sh
podman run --rm --init -it -v ./:/wine-builder/wine-src:Z old-wine-builder
```

### Information

_This GitHub repo is not intended for Wine bug fixes. Please refer to upstream support._

The motivation for this project is wanting to run an older Wine release.

[📜 FAQ](/FAQ.md)

[📜 Wine Patches](/patches)

[📜 Patch Origin](https://gitlab.winehq.org/ElementalWarrior/wine/-/commits/affinity-photo3-wine9.13-part3)

[📜 Legacy NTsync patch for Wine v9.22](https://github.com/Frogging-Family/wine-tkg-git/pull/1348/)

[📜 Credits](/Credits.md)

