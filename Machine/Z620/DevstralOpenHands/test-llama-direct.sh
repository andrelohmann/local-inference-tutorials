#!/bin/bash

# Direct llama.cpp container testing script
# This runs the llama.cpp container directly without docker-compose for parameter testing

set -e

echo "🚀 Starting Direct llama.cpp Container Test"
echo "=========================================="

# Fixed configuration values
CONTAINER_NAME="llama-cpp-test"
HOST_PORT="11434"
CONTAINER_PORT="11434"
MODEL_DIR="$HOME/.models"
MODEL_FILE="devstral-q4_k_m.gguf"
MODEL_PATH="$MODEL_DIR/$MODEL_FILE"

# llama.cpp server parameters
LLAMA_ARG_HOST="0.0.0.0"
LLAMA_ARG_PORT="11434"
LLAMA_ARG_MODEL="/models/$MODEL_FILE"
LLAMA_ARG_CTX_SIZE="88832"
LLAMA_ARG_N_GPU_LAYERS="41"
LLAMA_ARG_THREADS="12"
LLAMA_ARG_BATCH_SIZE="1024"
LLAMA_ARG_UBATCH_SIZE="512"
LLAMA_ARG_FLASH_ATTN="1"
LLAMA_ARG_CONT_BATCHING="1"
LLAMA_ARG_PARALLEL="1"
MODEL_ALIAS="devstral-2507:latest"

# CUDA/GPU settings
CUDA_DOCKER_ARCH="61"
NVIDIA_VISIBLE_DEVICES="all"
NVIDIA_DRIVER_CAPABILITIES="compute,utility"

echo "📋 Configuration:"
echo "  • Container: $CONTAINER_NAME"
echo "  • Port: $HOST_PORT"
echo "  • Model: $MODEL_FILE"
echo "  • Model Path: $MODEL_PATH"
echo "  • GPU Layers: $LLAMA_ARG_N_GPU_LAYERS"
echo "  • Context Size: $LLAMA_ARG_CTX_SIZE"
echo "  • CPU Threads: $LLAMA_ARG_THREADS"
echo "  • Model Alias: $MODEL_ALIAS"
echo ""

# Check if model exists
if [ ! -f "$MODEL_PATH" ]; then
    echo "❌ Error: Model file not found at $MODEL_PATH"
    echo "   Please ensure the model is downloaded"
    exit 1
fi

echo "✅ Model file found: $MODEL_PATH"

# Stop and remove existing container if it exists
if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
    echo "🔄 Stopping existing container..."
    docker stop $CONTAINER_NAME >/dev/null 2>&1 || true
    docker rm $CONTAINER_NAME >/dev/null 2>&1 || true
fi

# Build the image first
echo "🔧 Building llama.cpp image..."
docker build \
    --target server \
    --build-arg CUDA_DOCKER_ARCH=$CUDA_DOCKER_ARCH \
    --build-arg CUDA_VERSION=12.6.0 \
    --build-arg UBUNTU_VERSION=24.04 \
    -t llama-cpp-test \
    .

echo "🚀 Starting container..."

# Run the container
docker run -d \
    --name $CONTAINER_NAME \
    --runtime nvidia \
    --gpus all \
    -p $HOST_PORT:$CONTAINER_PORT \
    -v "$MODEL_DIR:/models" \
    -e LLAMA_ARG_HOST="$LLAMA_ARG_HOST" \
    -e LLAMA_ARG_PORT="$LLAMA_ARG_PORT" \
    -e LLAMA_ARG_MODEL="$LLAMA_ARG_MODEL" \
    -e LLAMA_ARG_CTX_SIZE="$LLAMA_ARG_CTX_SIZE" \
    -e LLAMA_ARG_N_GPU_LAYERS="$LLAMA_ARG_N_GPU_LAYERS" \
    -e LLAMA_ARG_THREADS="$LLAMA_ARG_THREADS" \
    -e LLAMA_ARG_BATCH_SIZE="$LLAMA_ARG_BATCH_SIZE" \
    -e LLAMA_ARG_UBATCH_SIZE="$LLAMA_ARG_UBATCH_SIZE" \
    -e LLAMA_ARG_FLASH_ATTN="$LLAMA_ARG_FLASH_ATTN" \
    -e LLAMA_ARG_CONT_BATCHING="$LLAMA_ARG_CONT_BATCHING" \
    -e LLAMA_ARG_PARALLEL="$LLAMA_ARG_PARALLEL" \
    -e MODEL_ALIAS="$MODEL_ALIAS" \
    -e MODEL_FILE="$MODEL_FILE" \
    -e NVIDIA_VISIBLE_DEVICES="$NVIDIA_VISIBLE_DEVICES" \
    -e NVIDIA_DRIVER_CAPABILITIES="$NVIDIA_DRIVER_CAPABILITIES" \
    llama-cpp-test

echo "⏳ Waiting for container to start..."
sleep 5

# Show container status
echo "📊 Container Status:"
docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Wait for server to be ready
echo "⏳ Waiting for llama.cpp server to be ready..."
max_attempts=30
attempt=0

while [ $attempt -lt $max_attempts ]; do
    if curl -s http://localhost:$HOST_PORT/health >/dev/null 2>&1; then
        echo "✅ Server is ready!"
        break
    fi
    
    attempt=$((attempt + 1))
    echo "   Attempt $attempt/$max_attempts..."
    sleep 2
done

if [ $attempt -eq $max_attempts ]; then
    echo "❌ Server failed to start within timeout"
    echo "📋 Container logs:"
    docker logs $CONTAINER_NAME
    exit 1
fi

echo ""
echo "🎉 Container started successfully!"
echo "=========================================="
echo "🌐 Server URL: http://localhost:$HOST_PORT"
echo "🔗 Health Check: http://localhost:$HOST_PORT/health"
echo "📋 Models API: http://localhost:$HOST_PORT/v1/models"
echo ""
echo "📝 Test commands:"
echo "   • Check health: curl http://localhost:$HOST_PORT/health"
echo "   • List models: curl http://localhost:$HOST_PORT/v1/models | jq ."
echo "   • Test chat: curl -X POST http://localhost:$HOST_PORT/v1/chat/completions \\"
echo "                     -H 'Content-Type: application/json' \\"
echo "                     -d '{\"model\":\"$MODEL_ALIAS\",\"messages\":[{\"role\":\"user\",\"content\":\"Hello!\"}],\"stream\":false}'"
echo ""
echo "📊 Monitor commands:"
echo "   • Container logs: docker logs -f $CONTAINER_NAME"
echo "   • Container stats: docker stats $CONTAINER_NAME"
echo "   • GPU usage: nvidia-smi"
echo ""
echo "🛑 To stop: docker stop $CONTAINER_NAME && docker rm $CONTAINER_NAME"
