# Container to build multi-architecture wine builds, by Yulian Kuncheff
# https://github.com/daegalus/wine-builder
# 
# Building old multilib Wine is possible with Debian 11
# Do not change to Debian 12 or later release
# Copy recent Linux NTsync header file (included)
#
FROM debian:11-slim

ARG USERNAME=wine-builder
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Install 32-bit Architecture
RUN dpkg --add-architecture i386

# Enable bullseye-backports
RUN echo "deb http://archive.debian.org/debian bullseye-backports main" > /etc/apt/sources.list.d/bullseye-backports.list

# Make sure everythng is up to date
RUN apt update && apt upgrade -y && apt autoremove -y

# Create a non-root user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME

# Install core system packages
RUN sudo apt install -y --no-install-recommends \
    bison \
    ca-certificates \
    curl \
    flex \
    gettext \
    gnupg \
    perl \
    lib32z1 \
    libz1 \
    libjson-perl \
    libvkd3d1:i386 \
    libvkd3d1 \
    libvulkan1:i386 \
    libvulkan1 \
    ocl-icd-libopencl1:i386 \
    ocl-icd-libopencl1 \
    spirv-headers \
    vkd3d-compiler \
    build-essential:amd64

# Install Necessary and Recommended 64-bit Dependencies
RUN sudo apt install -y --no-install-recommends \
    gcc-multilib \
    g++-multilib \
    gcc-mingw-w64 \
    libasound2-dev \
    libpulse-dev \
    libdbus-1-dev \
    libfontconfig-dev \
    libfreetype6-dev \
    libgettextpo-dev \
    libgnutls28-dev \
    libgl-dev \
    libglu1-mesa-dev \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libosmesa6-dev \
    libsdl2-dev \
    libudev-dev \
    libunwind-dev \
    libvulkan-dev \
    libwayland-dev \
    libx11-dev \
    libxcomposite-dev \
    libxcursor-dev \
    libxfixes-dev \
    libxi-dev \
    libxinerama-dev \
    libxkbregistry-dev \
    libxrandr-dev \
    libxrender-dev \
    libxext-dev

# Install Optional 64-bit Dependencies
RUN sudo apt install -y --no-install-recommends \
    libavcodec-dev \
    libavformat-dev \
    libavfilter-dev \
    libswresample-dev \
    libavutil-dev \
    libswscale-dev \
    libcapi20-dev \
    libcups2-dev \
    libgphoto2-dev \
    libjpeg-dev \
    liblcms2-dev \
    libncurses-dev \
    libpcsclite-dev \
    libpng-dev \
    libsane-dev \
    libtiff-dev \
    libkrb5-dev \
    samba-dev \
    unixodbc-dev \
    ocl-icd-opencl-dev \
    libpcap-dev \
    libusb-1.0-0-dev \
    libv4l-dev \
    libxml2-dev \
    libxslt1-dev

# Install Necessary and Recommended 32-bit Dependencies
RUN sudo apt install -y --no-install-recommends \
    gcc-multilib:i386 \
    g++-multilib:i386 \
    libasound2-dev:i386 \
    libpulse-dev:i386 \
    libdbus-1-dev:i386 \
    libfontconfig-dev:i386 \
    libfreetype6-dev:i386 \
    libgettextpo-dev:i386 \
    libgnutls28-dev:i386 \
    libgl-dev:i386 \
    libglu1-mesa-dev:i386 \
    libgstreamer1.0-dev:i386 \
    libgstreamer-plugins-base1.0-dev:i386 \
    libosmesa6-dev:i386 \
    libsdl2-dev:i386 \
    libudev-dev:i386 \
    libunwind-dev:i386 \
    libvulkan-dev:i386 \
    libwayland-dev:i386 \
    libx11-dev:i386 \
    libxcomposite-dev:i386 \
    libxcursor-dev:i386 \
    libxfixes-dev:i386 \
    libxi-dev:i386 \
    libxinerama-dev:i386 \
    libxkbregistry-dev:i386 \
    libxrandr-dev:i386 \
    libxrender-dev:i386 \
    libxext-dev:i386

# Install Optional 32-bit Dependencies
RUN sudo apt install -y --no-install-recommends \
    libavcodec-dev:i386 \
    libavformat-dev:i386 \
    libavfilter-dev:i386 \
    libswresample-dev:i386 \
    libavutil-dev:i386 \
    libswscale-dev:i386 \
    libcapi20-dev:i386 \
    libcups2-dev:i386 \
    libgphoto2-dev:i386 \
    libjpeg-dev:i386 \
    liblcms2-dev:i386 \
    libncurses-dev:i386 \
    libpcsclite-dev:i386 \
    libpng-dev:i386 \
    libsane-dev:i386 \
    libtiff-dev:i386 \
    libkrb5-dev:i386 \
    samba-dev:i386 \
    unixodbc-dev:i386 \
    ocl-icd-opencl-dev:i386 \
    libpcap-dev:i386 \
    libusb-1.0-0-dev:i386 \
    libv4l-dev:i386 \
    libxml2-dev:i386 \
    libxslt1-dev:i386

COPY --chown=$USER_UID:$USER_GID build-wine.sh /build-wine.sh
RUN sudo chmod 777 /build-wine.sh

WORKDIR /wine-builder
RUN sudo chown $USER_UID:$USER_GID /wine-builder
RUN sudo chmod 777 /wine-builder

RUN sudo apt install -y build-essential flex bison lib32z1 gcc-multilib g++-multilib

# Copy recent Linux "/usr/linux/ntsync.h" header file
# This is done after installing packages so not overwritten
COPY --chown=root:root ntsync.h /usr/include/linux/ntsync.h
RUN sudo chmod 644 /usr/include/linux/ntsync.h

ENTRYPOINT [ "/build-wine.sh" ]
