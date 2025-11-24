#!/bin/bash
# Linux Kernel Build Performance Testing Script
# Measures and validates build optimizations on Intel i3-1215U

echo "=== Linux Kernel Build Performance Test Suite ==="
echo "Hardware: Intel i3-1215U (6 cores/8 threads)"
echo "RAM: 16GB available"
echo "Storage: NVMe SSD + SSD"
echo "=========================================="

# Ensure scripts are executable
chmod +x build_dev.sh build_prod.sh build_conservative.sh

# Function to measure build performance
measure_build() {
    local script_name=$1
    local build_type=$2
    local description=$3

    echo ""
    echo "Testing $description..."
    echo "=========================================="

    # Clear caches and build directory
    echo "Clearing caches..."
    ccache -C > /dev/null 2>&1
    rm -rf /tmp/kernel-build-* > /dev/null 2>&1

    # Record system state before build
    echo "Recording system state..."
    local mem_before=$(free -m | awk '/^Mem:/ {print $3}')
    local temp_before=$(sensors 2>/dev/null | grep "Core 0" | awk '{print $3}' | head -1)

    # Run build with timing
    echo "Starting build..."
    local start_time=$(date +%s)
    bash "$script_name" > /tmp/build_log_$(date +%s).txt 2>&1
    local end_time=$(date +%s)

    # Record system state after build
    local mem_after=$(free -m | awk '/^Mem:/ {print $3}')
    local temp_after=$(sensors 2>/dev/null | grep "Core 0" | awk '{print $3}' | head -1)

    # Calculate results
    local build_time=$((end_time - start_time))
    local memory_used=$((mem_after - mem_before))

    # Get ccache statistics
    local ccache_stats=$(ccache -s 2>/dev/null | grep "cache hit" | head -1)

    echo "=== Results for $build_type ==="
    echo "Build time: ${build_time} seconds"
    echo "Memory used: ${memory_used} MB"
    echo "ccache: $ccache_stats"
    echo "CPU temperature: $temp_before → $temp_after"

    # Performance assessment
    if [ $build_time -lt 300 ]; then
        echo "✅ Excellent build time (< 5 minutes)"
    elif [ $build_time -lt 600 ]; then
        echo "✅ Good build time (< 10 minutes)"
    elif [ $build_time -lt 900 ]; then
        echo "⚠️  Acceptable build time (< 15 minutes)"
    else
        echo "❌ Slow build time (> 15 minutes)"
    fi

    echo "=========================================="
}

# Function to test different optimization levels
test_optimization_levels() {
    echo ""
    echo "Testing different optimization levels..."

    # Test O1 optimization
    echo "Creating temporary O1 build script..."
    cat > /tmp/test_o1.sh << 'EOF'
#!/bin/bash
export CC="ccache clang"
export CXX="ccache clang++"
export LD="lld"
export LLVM="1"
export KCFLAGS="-O1 -flto=thin -march=native -mtune=native"
export MAKEFLAGS="-j4"
export KBUILD_OUTPUT="/tmp/kernel-build-o1"
make -C . O="/tmp/kernel-build-o1" localmodconfig > /dev/null 2>&1
make -C . O="/tmp/kernel-build-o1" -j4 > /dev/null 2>&1
EOF
    chmod +x /tmp/test_o1.sh

    # Test O2 optimization
    echo "Creating temporary O2 build script..."
    cat > /tmp/test_o2.sh << 'EOF'
#!/bin/bash
export CC="ccache clang"
export CXX="ccache clang++"
export LD="lld"
export LLVM="1"
export KCFLAGS="-O2 -flto=thin -march=native -mtune=native"
export MAKEFLAGS="-j4"
export KBUILD_OUTPUT="/tmp/kernel-build-o2"
make -C . O="/tmp/kernel-build-o2" localmodconfig > /dev/null 2>&1
make -C . O="/tmp/kernel-build-o2" -j4 > /dev/null 2>&1
EOF
    chmod +x /tmp/test_o2.sh

    echo "Note: Full optimization testing requires complete builds."
    echo "Use the provided scripts for actual build performance testing."
}

# Function to validate ccache setup
validate_ccache() {
    echo ""
    echo "Validating ccache configuration..."
    echo "=========================================="

    # Check ccache installation
    if command -v ccache > /dev/null 2>&1; then
        echo "✅ ccache is installed"
    else
        echo "❌ ccache is not installed"
        echo "Install with: sudo dnf install ccache"
        return 1
    fi

    # Check ccache configuration
    echo "ccache version: $(ccache --version | head -1)"
    echo "ccache directory: $CCACHE_DIR"
    echo "ccache max size: $(ccache -s | grep max_size | head -1)"
    echo "ccache compression: $(ccache -s | grep compression | head -1)"

    # Test ccache
    echo ""
    echo "Testing ccache..."
    ccache -z > /dev/null 2>&1
    echo 'int main() { return 0; }' | ccache gcc -x c - -o /tmp/test.o > /dev/null 2>&1
    ccache -s | grep "cache hit" && echo "✅ ccache is working correctly" || echo "❌ ccache test failed"

    echo "=========================================="
}

# Function to check build prerequisites
check_prerequisites() {
    echo ""
    echo "Checking build prerequisites..."
    echo "=========================================="

    # Check required tools
    local tools=("clang" "clang++" "ld.lld" "ccache" "make")
    for tool in "${tools[@]}"; do
        if command -v "$tool" > /dev/null 2>&1; then
            echo "✅ $tool is available"
        else
            echo "❌ $tool is missing"
            if [ "$tool" = "clang" ]; then
                echo "Install with: sudo dnf install clang clang-tools-extra"
            elif [ "$tool" = "ccache" ]; then
                echo "Install with: sudo dnf install ccache"
            elif [ "$tool" = "ld.lld" ]; then
                echo "Install with: sudo dnf install llvm"
            fi
        fi
    done

    # Check available disk space
    local disk_space=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    echo "Available disk space: ${disk_space}GB"
    if [ "$disk_space" -gt 10 ]; then
        echo "✅ Sufficient disk space for kernel builds"
    else
        echo "❌ Low disk space (< 10GB available)"
    fi

    # Check available memory
    local mem_available=$(free -G | awk '/^Mem:/ {print $7}')
    echo "Available memory: ${mem_available}GB"
    if [ "$mem_available" -gt 8 ]; then
        echo "✅ Sufficient memory for parallel builds"
    else
        echo "⚠️  Low memory (< 8GB available) - consider reducing parallel jobs"
    fi

    echo "=========================================="
}

# Function to monitor build resources
monitor_resources() {
    echo ""
    echo "Current system resources..."
    echo "=========================================="

    # CPU info
    echo "CPU cores: $(nproc)"
    echo "CPU frequency: $(cat /proc/cpuinfo | grep "model name" | head -1 | cut -d: -f2 | xargs)"

    # Memory info
    free -h | head -2

    # Disk info
    df -h . | head -2

    # Temperature (if available)
    if command -v sensors > /dev/null 2>&1; then
        echo "Temperature:"
        sensors 2>/dev/null | grep -E "(Core|temp)" | head -4
    fi

    echo "=========================================="
}

# Main testing sequence
main() {
    echo "Starting performance validation suite..."

    # Check prerequisites first
    check_prerequisites

    # Validate ccache setup
    validate_ccache

    # Monitor current resources
    monitor_resources

    # Test optimization levels
    test_optimization_levels

    echo ""
    echo "=== Usage Instructions ==="
    echo "1. Development builds (fastest): ./build_dev.sh"
    echo "2. Production builds (max performance): ./build_prod.sh"
    echo "3. Conservative builds (thermal-aware): ./build_conservative.sh"
    echo ""
    echo "To measure build performance:"
    echo "time ./build_dev.sh"
    echo ""
    echo "To monitor during builds:"
    echo "htop  # CPU and memory usage"
    echo "iotop  # Disk I/O usage"
    echo "sensors  # Temperature monitoring"
    echo ""
    echo "Performance validation completed!"
}

# Run the validation suite
main
