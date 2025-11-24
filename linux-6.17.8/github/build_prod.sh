#!/bin/bash
# Linux Kernel Production Build Script - Maximum Optimization
# For final optimized builds on Intel i3-1215U

set -x CC "ccache clang"
set -x CXX "ccache clang++"
set -x LD lld
set -x LLVM 1

# Optimized for final builds (maximum runtime performance)
set -x KCFLAGS "-O3 -flto=thin -march=native -mtune=native -fno-semantic-interposition"
set -x KCPPFLAGS "-O3 -flto=thin -march=native -mtune=native -fno-semantic-interposition"

# Parallel builds - use all 8 threads
set -x MAKEFLAGS "-j$(nproc)"

# ccache optimization
set -x CCACHE_DIR /home/dae/.ccache
set -x CCACHE_COMPRESS 1
set -x CCACHE_COMPRESSLEVEL 6
set -x CCACHE_MAXSIZE "4G"
set -x CCACHE_SLOPPINESS "file_macro,time_macros"

# Build directory on NVMe for speed
set -x KBUILD_OUTPUT "/tmp/kernel-build-prod-$(date +%s)"

# CPU scaling for maximum build performance
echo "Setting CPU to performance mode..."
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null 2>&1 || echo "Warning: Could not set CPU governor (may need sudo)"

echo "=== Production Build Configuration ==="
echo "Compiler: Clang with ccache"
echo "Optimization: -O3 (maximum runtime performance)"
echo "Parallel jobs: $(nproc)"
echo "Build directory: $KBUILD_OUTPUT"
echo "CPU governor: performance"
echo "ccache max size: 4GB"
echo "=========================================="

# Create build directory
mkdir -p "$KBUILD_OUTPUT"

# Production build - use localmodconfig for relevant config
echo "Configuring kernel..."
make -C . O="$KBUILD_OUTPUT" localmodconfig

echo "Starting production build..."
time make -C . O="$KBUILD_OUTPUT" -j$(nproc)

# Build kernel packages (optional - for distribution)
if [ -d "scripts/package" ]; then
    echo "Building kernel packages..."
    make -C . O="$KBUILD_OUTPUT" deb-pkg
fi

echo "Build completed! Output directory: $KBUILD_OUTPUT"
echo "ccache statistics:"
ccache -s

# Restore power management
echo "Restoring CPU to powersave mode..."
echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null 2>&1 || echo "Warning: Could not restore CPU governor (may need sudo)"

echo "Production build completed successfully!"
