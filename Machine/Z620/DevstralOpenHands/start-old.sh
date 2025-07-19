#!/bin/bash

# Simplified Devstral + OpenHands Docker Compose Startup Script
# Based on test script learnings - streamlined for essential functionality

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

# Set dynamic SANDBOX_USER_ID (learned from test scripts)
export SANDBOX_USER_ID=$(id -u)
echo "🔐 Setting SANDBOX_USER_ID to: ${SANDBOX_USER_ID}"

echo ""
echo "📋 Configuration Summary:"
echo "  • CUDA Architecture: ${CUDA_DOCKER_ARCH}"
echo "  • Model: ${MODEL_NAME}"
echo "  • llama.cpp Port: ${LLAMA_ARG_PORT}"
echo "  • OpenHands Version: ${OPENHANDS_VERSION}"
echo "  • OpenHands Port: ${OPENHANDS_PORT}"
echo "  • OpenWebUI Port: ${OPENWEBUI_PORT}"
echo "  • User ID: ${SANDBOX_USER_ID}"
echo "  • Context Window: ${LLAMA_ARG_CTX_SIZE} tokens"
echo "  • GPU Layers: ${LLAMA_ARG_N_GPU_LAYERS}"
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

# Create necessary directories (simplified from test scripts)
echo "📁 Creating required directories..."
mkdir -p ~/.models workspace openhands-logs openwebui-data ~/.openhands ~/.openhands/workspace

# Create OpenHands configuration (learned from test-openhands.sh)
echo "🔧 Creating OpenHands configuration files..."
cat > ~/.openhands/settings.json << EOF
{"language":"en","agent":"CodeActAgent","max_iterations":null,"security_analyzer":null,"confirmation_mode":false,"llm_model":"openai/devstral-small-2507","llm_api_key":"DEVSTRAL","llm_base_url":"http://llama-cpp-server:11434","remote_runtime_resource_factor":1,"secrets_store":{"provider_tokens":{}},"enable_default_condenser":true,"enable_sound_notifications":false,"enable_proactive_conversation_starters":false,"user_consents_to_analytics":false,"sandbox_base_container_image":null,"sandbox_runtime_container_image":null,"mcp_config":{"sse_servers":[],"stdio_servers":[],"shttp_servers":[]},"search_api_key":"","sandbox_api_key":null,"max_budget_per_task":null,"email":null,"email_verified":null}
EOF

cat > ~/.openhands/config.toml << EOF
[llm]
model = "openai/devstral-small-2507"
base_url = "http://llama-cpp-server:11434"
api_key = "dummy"
api_version = "v1"
custom_llm_provider = "openai"
drop_params = true
EOF

echo "✅ OpenHands configuration files created"
    rm -f workspace/test-write
    echo "   ✅ workspace write test passed"
fi

if [ "$PERMISSION_OK" = "true" ]; then
    echo "✅ Write permissions verified"
else
    echo "⚠️  Some permission issues detected, but continuing..."
    echo "   OpenHands may have trouble creating session files"
    echo "   Use './debug-permissions.sh' for detailed troubleshooting"
fi

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
docker pull docker.all-hands.dev/all-hands-ai/runtime:${OPENHANDS_RUNTIME_VERSION}

echo ""
echo "🔧 Building and starting containers..."
SANDBOX_USER_ID=${SANDBOX_USER_ID} docker compose up --build -d

echo ""
echo "⏳ Waiting for services to become ready..."

# Wait for llama.cpp server to be healthy
echo "   • Waiting for llama.cpp server..."
TIMEOUT=300  # 5 minute timeout
START_TIME=$(date +%s)

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    
    if [ $ELAPSED -gt $TIMEOUT ]; then
        echo "   ❌ Timeout waiting for llama.cpp server (${TIMEOUT}s)"
        echo "   Check logs: docker compose logs llama-cpp-server"
        exit 1
    fi
    
    # Check if container is running
    if docker compose ps --services --filter "status=running" | grep -q "llama-cpp-server"; then
        # Try to get health status from docker inspect
        HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' llama-cpp-devstral 2>/dev/null || echo "unknown")
        
        # If health check is available and healthy, we're good
        if [[ "$HEALTH_STATUS" == "healthy" ]]; then
            echo "   ✅ llama.cpp server is ready!"
            break
        # If no health check or health check not yet available, try API directly
        elif [[ "$HEALTH_STATUS" == "unknown" ]] || [[ "$HEALTH_STATUS" == "none" ]]; then
            if docker exec llama-cpp-devstral curl -sf http://localhost:11434/health > /dev/null 2>&1; then
                echo "   ✅ llama.cpp server is responding!"
                break
            else
                echo "   ⏳ llama.cpp server starting up... (${ELAPSED}s)"
            fi
        else
            echo "   ⏳ llama.cpp server health: $HEALTH_STATUS (${ELAPSED}s)"
        fi
    else
        echo "   ⏳ Starting llama.cpp server... (${ELAPSED}s)"
    fi
    
    sleep 5
done

# Wait for OpenHands to be healthy
echo "   • Waiting for OpenHands..."
TIMEOUT=120  # 2 minute timeout for OpenHands
START_TIME=$(date +%s)

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    
    if [ $ELAPSED -gt $TIMEOUT ]; then
        echo "   ❌ Timeout waiting for OpenHands (${TIMEOUT}s)"
        echo "   Check logs: docker compose logs openhands"
        exit 1
    fi
    
    if docker compose ps --services --filter "status=running" | grep -q "openhands"; then
        # OpenHands doesn't have health checks, so just check if it's running and responding
        if docker exec openhands curl -sf http://localhost:3000 > /dev/null 2>&1; then
            echo "   ✅ OpenHands is ready!"
            break
        else
            echo "   ⏳ OpenHands starting up... (${ELAPSED}s)"
        fi
    else
        echo "   ⏳ Starting OpenHands... (${ELAPSED}s)"
    fi
    
    sleep 5
done

# Wait for OpenWebUI to be healthy
echo "   • Waiting for OpenWebUI..."
TIMEOUT=60  # 1 minute timeout for OpenWebUI
START_TIME=$(date +%s)

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    
    if [ $ELAPSED -gt $TIMEOUT ]; then
        echo "   ❌ Timeout waiting for OpenWebUI (${TIMEOUT}s)"
        echo "   Check logs: docker compose logs openwebui"
        break  # Continue even if OpenWebUI fails
    fi
    
    if docker compose ps --services --filter "status=running" | grep -q "openwebui"; then
        # Check if OpenWebUI is responding
        if docker exec openwebui curl -sf http://localhost:8080 > /dev/null 2>&1; then
            echo "   ✅ OpenWebUI is ready!"
            break
        else
            echo "   ⏳ OpenWebUI starting up... (${ELAPSED}s)"
        fi
    else
        echo "   ⏳ Starting OpenWebUI... (${ELAPSED}s)"
    fi
    
    sleep 5
done

echo ""
echo "🎉 Setup Complete!"
echo "=================================================="
echo "🌐 OpenHands Interface: http://localhost:${OPENHANDS_PORT}"
echo "🌐 OpenWebUI Interface: http://localhost:${OPENWEBUI_PORT}"
echo "🔗 llama.cpp Server: http://localhost:${LLAMA_ARG_PORT}"
echo ""
echo "📚 Available tools:"
echo "   • ./monitor-health.sh - Health status monitoring"
echo "   • ./debug-permissions.sh - Permission troubleshooting"
echo "   • docker compose logs -f - Full container logs"
echo ""
echo "📝 User Configuration:"
echo "   • User ID: $(id -u) (automatically set in containers)"
echo "   • OpenHands data: ~/.openhands (host) -> /.openhands (container)"
echo "   • OpenWebUI data: ./openwebui-data (host) -> /app/backend/data (container)"
echo "   • Workspace: ./workspace (host) -> /workspace (container)"
echo ""
echo "🛑 To stop: docker compose down"
