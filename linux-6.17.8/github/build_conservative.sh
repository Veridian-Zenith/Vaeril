#!/bin/bash
# Linux Kernel Conservative Build Script - Thermal-Aware
# For stable builds on Intel i3-1215U with thermal management

set -x CC "ccache clang"
set -x CXX "ccache clang++"
set -x LD lld
set -x LLVM 1

# Conservative optimization for thermal management and stability
set -x KCFLAGS "-O2 -flto=thin -march=native -mtune=native -fno-semantic-interposition"
set -x KCPPFLAGS "-O2 -flto=thin -march=native -mtune=native -fno-semantic-interposition"

# Conservative parallel builds - use P-cores only (2 cores/4 threads)
set -x MAKEFLAGS "-j4"

# ccache optimization
set -x CCACHE_DIR /home/dae/.ccache
set -x CCACHE_COMPRESS 1
set -x CCACHE_COMPRESSLEVEL 6
set -x CCACHE_MAXSIZE "4G"
set -x CCACHE_SLOPPINESS "file_macro,time_macros"

# Build directory on NVMe for speed
set -x KBUILD_OUTPUT "/tmp/kernel-build-conservative-$(date +%s)"

echo "=== Conservative Build Configuration ==="
echo "Compiler: Clang with ccache"
echo "Optimization: -O2 (balanced performance/stability)"
echo "Parallel jobs: 4 (P-cores only for thermal management)"
echo "Build directory: $KBUILD_OUTPUT"
echo "ccache max size: 4GB"
echo "Thermal-aware: Optimized for laptop use"
echo "=========================================="

# Create build directory
mkdir -p "$KBUILD_OUTPUT"

# Conservative build - use localmodconfig
echo "Configuring kernel..."
make -C . O="$KBUILD_OUTPUT" localmodconfig

echo "Starting conservative build..."
time make -C . O="$KBUILD_OUTPUT" -j4

echo "Build completed! Output directory: $KBUILD_OUTPUT"
echo "ccache statistics:"
ccache -s

echo "Conservative build completed successfully!"
