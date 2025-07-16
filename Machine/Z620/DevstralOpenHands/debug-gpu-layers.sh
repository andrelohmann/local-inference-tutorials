#!/bin/bash

# GPU Layer Debugging Script
# This script helps debug GPU layer offloading issues

echo "🔍 GPU Layer Debugging"
echo "====================="

# Load environment variables
if [ -f .env ]; then
    source .env
    echo "✅ Environment variables loaded"
else
    echo "❌ Error: .env file not found"
    exit 1
fi

echo ""
echo "📋 Current Configuration:"
echo "  LLAMA_ARG_N_GPU_LAYERS: ${LLAMA_ARG_N_GPU_LAYERS}"
echo "  NVIDIA_VISIBLE_DEVICES: ${NVIDIA_VISIBLE_DEVICES}"
echo "  CUDA_DOCKER_ARCH: ${CUDA_DOCKER_ARCH}"

echo ""
echo "🔧 Testing GPU Layer Settings:"

# Test with explicit layer count
echo "  Testing with 40 layers (all layers for Devstral)..."
echo "  Command: LLAMA_ARG_N_GPU_LAYERS=40 docker compose up --build -d"

# Test with reduced layers to see if memory is the issue
echo "  Testing with 20 layers (half the model)..."
echo "  Command: LLAMA_ARG_N_GPU_LAYERS=20 docker compose up --build -d"

echo ""
echo "💾 GPU Memory Available:"
if command -v nvidia-smi > /dev/null 2>&1; then
    nvidia-smi --query-gpu=index,name,memory.total,memory.free,memory.used --format=csv,noheader,nounits | while read line; do
        echo "  GPU $line"
    done
else
    echo "  ❌ nvidia-smi not available"
fi

echo ""
echo "📊 Model Information:"
model_path="${MODEL_DIR}/${MODEL_NAME}"
model_path_expanded="${model_path/#\~/$HOME}"
if [ -f "${model_path_expanded}" ]; then
    model_size=$(stat -c%s "${model_path_expanded}" 2>/dev/null || stat -f%z "${model_path_expanded}" 2>/dev/null || echo "0")
    echo "  Model Size: $(numfmt --to=iec-i --suffix=B ${model_size} 2>/dev/null || echo "${model_size} bytes")"
    echo "  Model Path: ${model_path_expanded}"
else
    echo "  ❌ Model not found at ${model_path_expanded}"
fi

echo ""
echo "🚀 Quick Fixes to Try:"
echo "  1. Set explicit layer count: LLAMA_ARG_N_GPU_LAYERS=40"
echo "  2. Reduce layers if memory limited: LLAMA_ARG_N_GPU_LAYERS=20"
echo "  3. Try with single GPU: NVIDIA_VISIBLE_DEVICES=0"
echo "  4. Check container logs: docker compose logs llama-cpp-server"

echo ""
echo "🔍 Debug Container Startup:"
echo "  docker compose up --build -d"
echo "  docker compose logs -f llama-cpp-server | grep -E '(offload|GPU|CUDA|layers)'"
