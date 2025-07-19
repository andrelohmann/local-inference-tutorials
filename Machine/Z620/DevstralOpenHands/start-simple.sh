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

# Model download (simplified from test scripts)
echo ""
echo "📥 Checking model availability..."
MODEL_PATH_EXPANDED="${MODEL_DIR/#\~/$HOME}/${MODEL_NAME}"

if [ ! -f "$MODEL_PATH_EXPANDED" ]; then
    echo "📥 Downloading model: ${MODEL_NAME}"
    echo "🔗 URL: ${MODEL_URL}"
    echo "📁 Destination: ${MODEL_PATH_EXPANDED}"
    echo ""
    
    if ! wget --continue --progress=bar:force:noscroll \
            --user-agent="Mozilla/5.0 (compatible; wget)" \
            -O "${MODEL_PATH_EXPANDED}.tmp" \
            "${MODEL_URL}"; then
        echo "❌ Download failed!"
        rm -f "${MODEL_PATH_EXPANDED}.tmp"
        exit 1
    fi
    
    mv "${MODEL_PATH_EXPANDED}.tmp" "$MODEL_PATH_EXPANDED"
    echo "✅ Model download completed!"
else
    echo "✅ Model already exists: $MODEL_PATH_EXPANDED"
fi

# Pull runtime container
echo ""
echo "📦 Pulling OpenHands runtime container..."
docker pull docker.all-hands.dev/all-hands-ai/runtime:${OPENHANDS_RUNTIME_VERSION}

# Start containers
echo ""
echo "🔧 Building and starting containers..."
SANDBOX_USER_ID=${SANDBOX_USER_ID} docker compose up --build -d

# Wait for services (simplified)
echo ""
echo "⏳ Waiting for services to become ready..."

# Wait for llama.cpp server
echo "   • Waiting for llama.cpp server..."
for i in {1..60}; do
    if curl -s http://localhost:${LLAMA_ARG_PORT}/health >/dev/null 2>&1; then
        echo "   ✅ llama.cpp server is ready!"
        break
    fi
    if [ $i -eq 60 ]; then
        echo "   ❌ Timeout waiting for llama.cpp server"
        exit 1
    fi
    sleep 5
done

# Wait for OpenHands
echo "   • Waiting for OpenHands..."
for i in {1..30}; do
    if curl -s http://localhost:${OPENHANDS_PORT} >/dev/null 2>&1; then
        echo "   ✅ OpenHands is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "   ❌ Timeout waiting for OpenHands"
        exit 1
    fi
    sleep 5
done

# Wait for OpenWebUI
echo "   • Waiting for OpenWebUI..."
for i in {1..20}; do
    if curl -s http://localhost:${OPENWEBUI_PORT} >/dev/null 2>&1; then
        echo "   ✅ OpenWebUI is ready!"
        break
    fi
    if [ $i -eq 20 ]; then
        echo "   ⚠️  OpenWebUI timeout (continuing anyway)"
        break
    fi
    sleep 3
done

echo ""
echo "🎉 Setup Complete!"
echo "=================================================="
echo "🌐 OpenHands Interface: http://localhost:${OPENHANDS_PORT}"
echo "🌐 OpenWebUI Interface: http://localhost:${OPENWEBUI_PORT}" 
echo "🔗 llama.cpp Server: http://localhost:${LLAMA_ARG_PORT}"
echo ""
echo "📝 Configuration:"
echo "   • User ID: $(id -u) (set in containers)"
echo "   • OpenHands config: ~/.openhands/config.toml"
echo "   • Workspace: ./workspace"
echo ""
echo "🛑 To stop: docker compose down"
