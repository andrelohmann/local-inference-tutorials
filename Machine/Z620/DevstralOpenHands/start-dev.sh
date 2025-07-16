#!/bin/bash

# Devstral + OpenHands Development Docker Compose Startup Script
# This script handles model download and container startup for CPU-only development

set -e

echo "🚀 Starting Devstral + OpenHands Development Setup (CPU-only)..."
echo "================================================================="

# Load environment variables
if [ -f .env ]; then
    source .env
    echo "✅ Environment variables loaded"
else
    echo "❌ Error: .env file not found"
    exit 1
fi

# Set dynamic SANDBOX_USER_ID
export SANDBOX_USER_ID=$(id -u)
echo "🔐 Setting SANDBOX_USER_ID to: ${SANDBOX_USER_ID}"

echo ""
echo "📋 Development Configuration Summary:"
echo "  • Mode: CPU-only (Development)"
echo "  • Model: ${MODEL_NAME}"
echo "  • llama.cpp Port: ${LLAMA_ARG_PORT}"
echo "  • OpenHands Version: ${OPENHANDS_VERSION}"
echo "  • OpenHands Port: ${OPENHANDS_PORT}"
echo "  • Context Window: ${LLAMA_ARG_CTX_SIZE} tokens"
echo "  • GPU Layers: 0 (CPU-only)"
echo "  • Parallel Streams: 1 (optimized for CPU)"
echo "  • Sandbox User ID: ${SANDBOX_USER_ID}"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running. Please start Docker first."
    exit 1
fi

# Create necessary directories
echo "📁 Creating required directories..."
mkdir -p ~/.models workspace ~/.openhands

# Check if model exists
MODEL_PATH="${MODEL_DIR}/${MODEL_NAME}"
# Expand tilde to full path for compatibility
EXPANDED_MODEL_PATH=$(eval echo $MODEL_PATH)

if [ ! -f "$EXPANDED_MODEL_PATH" ]; then
    echo "⬇️  Model not found at: $EXPANDED_MODEL_PATH"
    echo "   Downloading model..."
    
    # Create model directory if it doesn't exist
    mkdir -p $(dirname "$EXPANDED_MODEL_PATH")
    
    # Download with resumable support
    wget --continue --progress=bar:force:noscroll \
         -O "$EXPANDED_MODEL_PATH" \
         "$MODEL_URL"
    
    if [ $? -eq 0 ]; then
        echo "✅ Model downloaded successfully"
    else
        echo "❌ Error: Model download failed"
        exit 1
    fi
else
    echo "✅ Model already exists at: $EXPANDED_MODEL_PATH"
fi

# Build and start containers
echo "🏗️  Building and starting containers..."
docker compose -f docker-compose.dev.yml build
docker compose -f docker-compose.dev.yml up -d

echo ""
echo "🎉 Development setup complete!"
echo "=================================================="
echo "📊 Services:"
echo "  • OpenHands UI: http://localhost:${OPENHANDS_PORT}"
echo "  • llama.cpp API: http://localhost:${LLAMA_ARG_PORT}"
echo ""
echo "🔍 Monitor services:"
echo "  • View logs: docker compose -f docker-compose.dev.yml logs -f"
echo "  • Check status: docker compose -f docker-compose.dev.yml ps"
echo "  • Monitor health: ./monitor-health.sh"
echo ""
echo "🛑 Stop services:"
echo "  • Stop: docker compose -f docker-compose.dev.yml down"
echo "  • Cleanup: docker compose -f docker-compose.dev.yml down -v --remove-orphans"
