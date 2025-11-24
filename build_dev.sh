#!/bin/bash
# Linux Kernel Development Build Script - Optimized for Speed
# For faster iteration builds on Intel i3-1215U

set -x CC "ccache clang"
set -x CXX "ccache clang++"
set -x LD lld
set -x LLVM 1

# Optimized for development (faster builds, O1 optimization)
set -x KCFLAGS "-O1 -flto=thin -march=native -mtune=native -fno-semantic-interposition"
set -x KCPPFLAGS "-O1 -flto=thin -march=native -mtune=native -fno-semantic-interposition"

# Parallel builds - use all 8 threads
set -x MAKEFLAGS "-j$(nproc)"

# ccache optimization
set -x CCACHE_DIR /home/dae/.ccache
set -x CCACHE_COMPRESS 1
set -x CCACHE_COMPRESSLEVEL 6
set -x CCACHE_MAXSIZE "4G"
set -x CCACHE_SLOPPINESS "file_macro,time_macros"

# Build directory on NVMe for speed
set -x KBUILD_OUTPUT "/tmp/kernel-build-$(date +%s)"

echo "=== Development Build Configuration ==="
echo "Compiler: Clang with ccache"
echo "Optimization: -O1 (faster builds)"
echo "Parallel jobs: $(nproc)"
echo "Build directory: $KBUILD_OUTPUT"
echo "ccache max size: 4GB"
echo "=========================================="

# Create build directory
mkdir -p "$KBUILD_OUTPUT"

# Development build - use localmodconfig for faster config
echo "Configuring kernel..."
make -C . O="$KBUILD_OUTPUT" localmodconfig

echo "Starting development build..."
time make -C . O="$KBUILD_OUTPUT" -j$(nproc)

echo "Build completed! Output directory: $KBUILD_OUTPUT"
echo "ccache statistics:"
ccache -s
