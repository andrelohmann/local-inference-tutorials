#!/bin/bash

# Quick test script to verify GPU and user configuration

echo "🔍 System Configuration Check"
echo "============================="

# Load environment variables from .env file and set SANDBOX_USER_ID
if [ -f .env ]; then
    source .env
    export SANDBOX_USER_ID=$(id -u)
    echo "✅ Environment variables loaded from .env"
    echo "🔐 SANDBOX_USER_ID set to: ${SANDBOX_USER_ID}"
else
    echo "❌ Error: .env file not found"
    exit 1
fi

# Define Docker image (using a known working version since CUDA_VERSION is not in .env)
CUDA_IMAGE="nvidia/cuda:12.6.0-base-ubuntu24.04"

# Check NVIDIA runtime
echo "1. NVIDIA Runtime Test:"
echo "   Testing with: ${CUDA_IMAGE}"
if docker run --rm --runtime=nvidia "${CUDA_IMAGE}" nvidia-smi > /dev/null 2>&1; then
    echo "   ✅ NVIDIA runtime working"
else
    echo "   ❌ NVIDIA runtime not available"
    echo "   💡 Try using --gpus all instead of --runtime=nvidia"
    # Test with --gpus all as fallback
    if docker run --rm --gpus all "${CUDA_IMAGE}" nvidia-smi > /dev/null 2>&1; then
        echo "   ✅ GPU access works with --gpus all flag"
    else
        echo "   ❌ GPU access failed with both --runtime=nvidia and --gpus all"
    fi
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
echo "   CUDA Docker Image: ${CUDA_IMAGE}"
echo "   CUDA_DOCKER_ARCH: ${CUDA_DOCKER_ARCH}"
echo "   NVIDIA_VISIBLE_DEVICES: ${NVIDIA_VISIBLE_DEVICES}"
echo "   NVIDIA_DRIVER_CAPABILITIES: ${NVIDIA_DRIVER_CAPABILITIES:-compute,utility}"
echo "   LLAMA_ARG_N_GPU_LAYERS: ${LLAMA_ARG_N_GPU_LAYERS}"

# Check user ID
echo "4. User Configuration:"
echo "   Current User ID: $(id -u)"
echo "   SANDBOX_USER_ID: ${SANDBOX_USER_ID}"
if [ -z "${SANDBOX_USER_ID}" ]; then
    echo "   ⚠️  SANDBOX_USER_ID not set - use start.sh script or set in .env"
elif [ "${SANDBOX_USER_ID}" != "$(id -u)" ]; then
    echo "   ⚠️  SANDBOX_USER_ID (${SANDBOX_USER_ID}) doesn't match current user ($(id -u))"
else
    echo "   ✅ SANDBOX_USER_ID correctly configured"
fi

# Check directory permissions
echo "   Directory permissions:"
for dir in "openhands-logs" "workspace"; do
    if [ -d "$dir" ]; then
        dir_owner=$(stat -c "%U" "$dir" 2>/dev/null || stat -f "%Su" "$dir" 2>/dev/null || echo "unknown")
        if [ "$dir_owner" = "$(whoami)" ]; then
            echo "     ✅ $dir owned by $(whoami)"
        else
            echo "     ❌ $dir owned by $dir_owner (should be $(whoami))"
        fi
    else
        echo "     ⚠️  $dir directory doesn't exist"
    fi
done

# Check model configuration
echo "5. Model Configuration:"
echo "   MODEL_NAME: ${MODEL_NAME}"
echo "   MODEL_DIR: ${MODEL_DIR}"
echo "   MODEL_URL: ${MODEL_URL}"
model_path="${MODEL_DIR}/${MODEL_NAME}"
# Expand tilde in path
model_path_expanded="${model_path/#\~/$HOME}"
if [ -f "${model_path_expanded}" ]; then
    model_size=$(stat -c%s "${model_path_expanded}" 2>/dev/null || stat -f%z "${model_path_expanded}" 2>/dev/null || echo "0")
    echo "   Model Status: ✅ Found ($(numfmt --to=iec-i --suffix=B ${model_size} 2>/dev/null || echo "${model_size} bytes"))"
else
    echo "   Model Status: ❌ Not found at ${model_path_expanded}"
fi

# Check OpenHands configuration
echo "6. OpenHands Configuration:"
echo "   OPENHANDS_IMAGE: ${OPENHANDS_IMAGE}"
echo "   OPENHANDS_VERSION: ${OPENHANDS_VERSION}"
echo "   OPENHANDS_RUNTIME_IMAGE: ${OPENHANDS_RUNTIME_IMAGE}"
echo "   OPENHANDS_RUNTIME_VERSION: ${OPENHANDS_RUNTIME_VERSION}"
echo "   OPENHANDS_PORT: ${OPENHANDS_PORT}"
echo "   OPENHANDS_CONTAINER_NAME: ${OPENHANDS_CONTAINER_NAME}"

# Check if OpenHands configuration files exist
if [ -f ~/.openhands/settings.json ]; then
    echo "   ✅ OpenHands settings.json exists"
    LLM_MODEL=$(jq -r '.llm_model // empty' ~/.openhands/settings.json 2>/dev/null || echo "")
    LLM_BASE_URL=$(jq -r '.llm_base_url // empty' ~/.openhands/settings.json 2>/dev/null || echo "")
    echo "   LLM Model (from settings.json): ${LLM_MODEL}"
    echo "   LLM Base URL (from settings.json): ${LLM_BASE_URL}"
else
    echo "   ⚠️  OpenHands settings.json not found (will be created by start.sh)"
fi

if [ -f ~/.openhands/config.toml ]; then
    echo "   ✅ OpenHands config.toml exists"
else
    echo "   ⚠️  OpenHands config.toml not found (will be created by start.sh)"
fi

# Check llama.cpp performance settings
echo "7. llama.cpp Performance Configuration:"
echo "   LLAMA_ARG_CTX_SIZE: ${LLAMA_ARG_CTX_SIZE} tokens"
echo "   LLAMA_ARG_THREADS: ${LLAMA_ARG_THREADS}"
echo "   LLAMA_ARG_BATCH_SIZE: ${LLAMA_ARG_BATCH_SIZE}"
echo "   LLAMA_ARG_UBATCH_SIZE: ${LLAMA_ARG_UBATCH_SIZE}"
echo "   LLAMA_ARG_PARALLEL: ${LLAMA_ARG_PARALLEL}"
echo "   LLAMA_ARG_FLASH_ATTN: ${LLAMA_ARG_FLASH_ATTN}"
echo "   LLAMA_ARG_CONT_BATCHING: ${LLAMA_ARG_CONT_BATCHING}"

# Check Docker info
echo "8. Docker Runtime Support:"
docker info | grep -A5 -B5 "nvidia" || echo "   ❌ No nvidia runtime found"

# Test GPU access with current configuration
echo "9. GPU Access Test:"
if [ "${NVIDIA_VISIBLE_DEVICES}" = "none" ]; then
    echo "   ⚠️  GPU disabled (NVIDIA_VISIBLE_DEVICES=none)"
else
    echo "   Testing GPU access with NVIDIA_VISIBLE_DEVICES=${NVIDIA_VISIBLE_DEVICES}"
    echo "   Using image: ${CUDA_IMAGE}"
    
    # Try --gpus all first (more modern approach)
    if docker run --rm --gpus all -e NVIDIA_VISIBLE_DEVICES="${NVIDIA_VISIBLE_DEVICES}" "${CUDA_IMAGE}" nvidia-smi -L > /dev/null 2>&1; then
        echo "   ✅ GPU access working with --gpus all flag"
        docker run --rm --gpus all -e NVIDIA_VISIBLE_DEVICES="${NVIDIA_VISIBLE_DEVICES}" "${CUDA_IMAGE}" nvidia-smi -L | sed 's/^/     /'
    # Fallback to --runtime=nvidia
    elif docker run --rm --runtime=nvidia -e NVIDIA_VISIBLE_DEVICES="${NVIDIA_VISIBLE_DEVICES}" "${CUDA_IMAGE}" nvidia-smi -L > /dev/null 2>&1; then
        echo "   ✅ GPU access working with --runtime=nvidia"
        docker run --rm --runtime=nvidia -e NVIDIA_VISIBLE_DEVICES="${NVIDIA_VISIBLE_DEVICES}" "${CUDA_IMAGE}" nvidia-smi -L | sed 's/^/     /'
    else
        echo "   ❌ GPU access failed with current configuration"
        echo "   💡 Check NVIDIA Container Toolkit installation"
        echo "   💡 Verify Docker daemon configuration includes nvidia runtime"
    fi
fi

# Configuration validation
echo "10. Configuration Validation:"
validation_errors=0

# Check CUDA architecture
case "${CUDA_DOCKER_ARCH}" in
    "61") echo "   ✅ CUDA architecture: Pascal (GTX 10xx, Quadro P series)" ;;
    "75") echo "   ✅ CUDA architecture: Turing (RTX 20xx, GTX 16xx)" ;;
    "86") echo "   ✅ CUDA architecture: Ampere (RTX 30xx, A40, A100)" ;;
    "89") echo "   ✅ CUDA architecture: Ada (RTX 40xx)" ;;
    "90") echo "   ✅ CUDA architecture: Hopper (H100, H200)" ;;
    *) echo "   ⚠️  Unknown CUDA architecture: ${CUDA_DOCKER_ARCH}" ;;
esac

# Check if ports are available
if command -v netstat > /dev/null 2>&1; then
    if netstat -tuln | grep -q ":${LLAMA_ARG_PORT}"; then
        echo "   ⚠️  Port ${LLAMA_ARG_PORT} is already in use"
        validation_errors=$((validation_errors + 1))
    fi
    if netstat -tuln | grep -q ":${OPENHANDS_PORT}"; then
        echo "   ⚠️  Port ${OPENHANDS_PORT} is already in use"
        validation_errors=$((validation_errors + 1))
    fi
fi

if [ $validation_errors -eq 0 ]; then
    echo "   ✅ Configuration validation passed"
else
    echo "   ❌ Found ${validation_errors} configuration issue(s)"
fi

echo ""
echo "💡 If any tests fail, check the troubleshooting section in README.md"
