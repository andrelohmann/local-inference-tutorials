#!/bin/bash

# Quick test script to verify GPU and user configuration

echo "🔍 System Configuration Check"
echo "============================="

# Check NVIDIA runtime
echo "1. NVIDIA Runtime Test:"
if docker run --rm --runtime=nvidia nvidia/cuda:12.6.0-base-ubuntu24.04 nvidia-smi > /dev/null 2>&1; then
    echo "   ✅ NVIDIA runtime working"
else
    echo "   ❌ NVIDIA runtime not available"
fi

# Check GPU visibility
echo "2. GPU Visibility:"
if command -v nvidia-smi > /dev/null 2>&1; then
    echo "   ✅ nvidia-smi available"
    echo "   Available GPUs:"
    nvidia-smi --query-gpu=index,name,memory.total --format=csv,noheader,nounits | while read line; do
        echo "     GPU $line MB"
    done
else
    echo "   ❌ nvidia-smi not found"
fi

# Check GPU configuration
echo "3. GPU Configuration:"
source .env 2>/dev/null || echo "   ⚠️  .env file not found"
echo "   NVIDIA_VISIBLE_DEVICES: ${NVIDIA_VISIBLE_DEVICES:-not set}"
echo "   NVIDIA_DRIVER_CAPABILITIES: ${NVIDIA_DRIVER_CAPABILITIES:-not set}"

# Check user ID
echo "4. User Configuration:"
echo "   User ID: $(id -u)"
echo "   SANDBOX_USER_ID: ${SANDBOX_USER_ID:-not set}"

# Check Docker info
echo "5. Docker Runtime Support:"
docker info | grep -A5 -B5 "nvidia" || echo "   ❌ No nvidia runtime found"

# Test GPU access with current configuration
echo "6. GPU Access Test:"
if [ -f .env ]; then
    source .env
    if [ "${NVIDIA_VISIBLE_DEVICES}" = "none" ]; then
        echo "   ⚠️  GPU disabled (NVIDIA_VISIBLE_DEVICES=none)"
    else
        echo "   Testing GPU access with NVIDIA_VISIBLE_DEVICES=${NVIDIA_VISIBLE_DEVICES}"
        if docker run --rm --runtime=nvidia -e NVIDIA_VISIBLE_DEVICES="${NVIDIA_VISIBLE_DEVICES}" nvidia/cuda:12.6.0-base-ubuntu24.04 nvidia-smi -L > /dev/null 2>&1; then
            echo "   ✅ GPU access working with current configuration"
            docker run --rm --runtime=nvidia -e NVIDIA_VISIBLE_DEVICES="${NVIDIA_VISIBLE_DEVICES}" nvidia/cuda:12.6.0-base-ubuntu24.04 nvidia-smi -L | sed 's/^/     /'
        else
            echo "   ❌ GPU access failed with current configuration"
        fi
    fi
else
    echo "   ⚠️  .env file not found, cannot test GPU configuration"
fi

echo ""
echo "💡 If any tests fail, check the troubleshooting section in README.md"
