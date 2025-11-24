#!/bin/bash
# Quick Setup Script for Optimized Kernel Build
# Run this after copying files to a new environment

set -x

echo "🚀 Setting up optimized Linux kernel build environment..."

# Check required tools
echo "Checking required tools..."
REQUIRED_TOOLS=("clang" "ccache" "make" "git")
MISSING_TOOLS=()

for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" > /dev/null 2>&1; then
        MISSING_TOOLS+=("$tool")
    fi
done

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    echo "❌ Missing tools: ${MISSING_TOOLS[*]}"
    echo "Install with:"
    echo "  Fedora/RHEL/CentOS: sudo dnf install ${MISSING_TOOLS[*]}"
    echo "  Ubuntu/Debian: sudo apt install ${MISSING_TOOLS[*]}"
    exit 1
fi

echo "✅ All required tools found"

# Setup ccache
echo "Setting up ccache..."
mkdir -p ~/.ccache
export CCACHE_DIR=~/.ccache
export CCACHE_COMPRESS=1
export CCACHE_COMPRESSLEVEL=6
export CCACHE_MAXSIZE="4G"

# Check available space
AVAILABLE_SPACE=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$AVAILABLE_SPACE" -lt 50 ]; then
    echo "⚠️  Warning: Only ${AVAILABLE_SPACE}GB available. 50GB+ recommended for kernel builds."
fi

# Check available memory
AVAILABLE_MEM=$(free -G | awk '/^Mem:/ {print $7}')
if [ "$AVAILABLE_MEM" -lt 8 ]; then
    echo "⚠️  Warning: Only ${AVAILABLE_MEM}GB memory available. 16GB+ recommended for parallel builds."
fi

echo "✅ Environment check complete"
echo ""
echo "📋 Next steps:"
echo "1. Download Linux kernel source:"
echo "   git clone https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git linux-6.17.8"
echo "   cd linux-6.17.8"
echo ""
echo "2. Copy optimized configuration:"
echo "   cp path/to/github/kernel_config_optimized .config"
echo ""
echo "3. Choose your build:"
echo "   ./build_dev.sh     # Fastest compilation"
echo "   ./build_prod.sh    # Maximum performance"
echo "   ./build_conservative.sh  # Thermal-aware"
echo ""
echo "4. Monitor build:"
echo "   htop    # CPU and memory"
echo "   iotop   # Disk I/O"
echo "   sensors # Temperature"
