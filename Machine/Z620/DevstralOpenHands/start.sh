#!/bin/bash

# Devstral + OpenHands Docker Compose Startup Script
# This script handles model download and container startup

set -e

echo "🚀 Starting Devstral + OpenHands Setup..."
echo "=================================================="

# Load environment variables
if [ -f .env ]; then
    source .env
    echo "✅ Environment variables loaded"
else
    echo "❌ Error: .env file not found"
    exit 1
fi

echo ""
echo "📋 Configuration Summary:"
echo "  • CUDA Architecture: ${CUDA_DOCKER_ARCH}"
echo "  • Model: ${MODEL_NAME}"
echo "  • llama.cpp Port: ${LLAMA_ARG_PORT}"
echo "  • OpenHands Port: ${OPENHANDS_PORT}"
echo "  • Context Window: ${LLAMA_ARG_CTX_SIZE} tokens"
echo "  • Parallel Streams: ${LLAMA_ARG_PARALLEL}"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running. Please start Docker first."
    exit 1
fi

# Check if NVIDIA Docker runtime is available
if ! docker run --rm --gpus all nvidia/cuda:12.6.0-base-ubuntu24.04 nvidia-smi > /dev/null 2>&1; then
    echo "⚠️  Warning: NVIDIA Docker runtime not available. GPU acceleration will not work."
    echo "   Please install NVIDIA Container Toolkit."
fi

# Create necessary directories
echo "📁 Creating required directories..."
mkdir -p ~/.models workspace ~/.openhands

# Check if model exists
MODEL_PATH="${MODEL_DIR}/${MODEL_NAME}"
# Expand tilde to full path for compatibility
MODEL_PATH_EXPANDED="${MODEL_PATH/#\~/$HOME}"
if [ ! -f "$MODEL_PATH_EXPANDED" ]; then
    echo ""
    echo "📥 Model not found. Starting download..."
    echo "   Source: ${MODEL_URL}"
    echo "   Target: ${MODEL_PATH_EXPANDED}"
    echo "   Size: ~15GB (may take 20-30 minutes with slow internet)"
    echo ""
    
    # Download with progress
    echo "⏳ Downloading model..."
    if ! wget --progress=bar:force:noscroll --show-progress \
            --continue \
            --timeout=30 \
            --tries=3 \
            --user-agent="Mozilla/5.0 (compatible; wget)" \
            -O "${MODEL_PATH_EXPANDED}.tmp" \
            "${MODEL_URL}"; then
        echo "❌ Download failed!"
        rm -f "${MODEL_PATH_EXPANDED}.tmp"
        exit 1
    fi
    
    # Move to final location
    mv "${MODEL_PATH_EXPANDED}.tmp" "$MODEL_PATH_EXPANDED"
    echo "✅ Model download completed!"
else
    echo "✅ Model already exists: $MODEL_PATH_EXPANDED"
fi

# Pull runtime container (required for OpenHands)
echo ""
echo "📦 Pulling OpenHands runtime container..."
docker pull docker.all-hands.dev/all-hands-ai/runtime:0.48-nikolaik

echo ""
echo "🔧 Building and starting containers..."
docker compose up --build -d

echo ""
echo "⏳ Waiting for services to become ready..."

# Wait for llama.cpp server to be healthy
echo "   • Waiting for llama.cpp server..."
while true; do
    if docker compose ps --services --filter "status=running" | grep -q "llama-cpp-server"; then
        HEALTH_STATUS=$(docker compose ps --format "table {{.Service}}\t{{.Status}}" | grep "llama-cpp-server" | awk '{print $2}')
        
        if [[ "$HEALTH_STATUS" == *"healthy"* ]]; then
            echo "   ✅ llama.cpp server is ready!"
            break
        else
            echo "   ⏳ llama.cpp server status: $HEALTH_STATUS"
        fi
    else
        echo "   ⏳ Starting llama.cpp server..."
    fi
    
    sleep 5
done

# Wait for OpenHands to be healthy
echo "   • Waiting for OpenHands..."
while true; do
    if docker compose ps --services --filter "status=running" | grep -q "openhands"; then
        HEALTH_STATUS=$(docker compose ps --format "table {{.Service}}\t{{.Status}}" | grep "openhands" | awk '{print $2}')
        
        if [[ "$HEALTH_STATUS" == *"healthy"* ]] || [[ "$HEALTH_STATUS" == *"running"* ]]; then
            echo "   ✅ OpenHands is ready!"
            break
        else
            echo "   ⏳ OpenHands status: $HEALTH_STATUS"
        fi
    else
        echo "   ⏳ Starting OpenHands..."
    fi
    
    sleep 5
done

echo ""
echo "🎉 Setup Complete!"
echo "=================================================="
echo "🌐 OpenHands Interface: http://localhost:${OPENHANDS_PORT}"
echo "🔗 llama.cpp Server: http://localhost:${LLAMA_ARG_PORT}"
echo ""
echo "📚 Available tools:"
echo "   • ./monitor-health.sh - Health status monitoring"
echo "   • docker compose logs -f - Full container logs"
echo ""
echo "🛑 To stop: docker compose down"
