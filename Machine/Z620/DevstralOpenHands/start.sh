#!/bin/bash

# Devstral + OpenHands Docker Compose Management Script
# This script handles model download, container startup, and management

set -e

# Function to show usage
show_usage() {
    echo "🚀 Devstral + OpenHands Management Script"
    echo "=========================================="
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start     Start all services"
    echo "  stop      Stop and remove all containers"
    echo "  restart   Restart all services"
    echo "  logs      Show container logs"
    echo "  status    Show container status"
    echo "  health    Show detailed health status"
    echo "  help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start    # Start all services"
    echo "  $0 stop     # Stop all services"
    echo "  $0 logs     # View logs from all services"
    echo "  $0 status   # Check status of all services"
    echo "  $0 health   # Detailed health check"
    echo ""
    echo "Configuration:"
    echo "  • llama.cpp Server: Port ${LLAMA_ARG_PORT:-11434}"
    echo "  • OpenHands: Port ${OPENHANDS_PORT:-3000}"
    echo "  • OpenWebUI: Port ${OPENWEBUI_PORT:-8080}"
    echo "  • Model: ${MODEL_NAME:-devstral-q4_k_m.gguf}"
    echo "  • CUDA Architecture: ${CUDA_DOCKER_ARCH:-61}"
    echo ""
    echo "Web Interfaces:"
    echo "  • OpenHands: http://localhost:${OPENHANDS_PORT:-3000}"
    echo "  • OpenWebUI: http://localhost:${OPENWEBUI_PORT:-8080}"
    echo "  • llama.cpp API: http://localhost:${LLAMA_ARG_PORT:-11434}"
    echo ""
    exit 0
}

# Function to start all services
start_services() {
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

# Set dynamic SANDBOX_USER_ID
export SANDBOX_USER_ID=$(id -u)
echo "🔐 Setting SANDBOX_USER_ID to: ${SANDBOX_USER_ID}"

echo ""
echo "📋 Configuration Summary:"
echo "  • CUDA Architecture: ${CUDA_DOCKER_ARCH}"
echo "  • GPU Configuration: ${NVIDIA_VISIBLE_DEVICES}"
echo "  • Model: ${MODEL_NAME}"
echo "  • llama.cpp Port: ${LLAMA_ARG_PORT}"
echo "  • OpenHands Version: ${OPENHANDS_VERSION}"
echo "  • OpenHands Port: ${OPENHANDS_PORT}"
echo "  • OpenWebUI Port: ${OPENWEBUI_PORT}"
echo "  • User ID: ${SANDBOX_USER_ID}"
echo "  • Context Window: ${LLAMA_ARG_CTX_SIZE} tokens"
echo "  • GPU Layers: ${LLAMA_ARG_N_GPU_LAYERS}"
echo "  • Parallel Streams: ${LLAMA_ARG_PARALLEL}"
echo "  • Sandbox User ID: ${SANDBOX_USER_ID}"
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
mkdir -p ~/.models workspace openhands-logs openwebui-data

# Create OpenHands configuration directory with proper permissions
echo "🔧 Setting up OpenHands directories..."
mkdir -p ~/.openhands

# Set permissions (allow failures if already correct)
chmod 755 ~/.openhands 2>/dev/null || echo "   ℹ️  ~/.openhands permissions already set or cannot be changed"
chmod 755 workspace 2>/dev/null || echo "   ℹ️  workspace permissions already set or cannot be changed"
chmod 755 openhands-logs 2>/dev/null || echo "   ℹ️  openhands-logs permissions already set or cannot be changed"
chmod 755 openwebui-data 2>/dev/null || echo "   ℹ️  openwebui-data permissions already set or cannot be changed"

# Ensure current user owns the directories (allow failures)
chown -R $(id -u):$(id -g) ~/.openhands 2>/dev/null || echo "   ℹ️  ~/.openhands ownership already correct or cannot be changed"
chown -R $(id -u):$(id -g) workspace 2>/dev/null || echo "   ℹ️  workspace ownership already correct or cannot be changed"
chown -R $(id -u):$(id -g) openhands-logs 2>/dev/null || echo "   ℹ️  openhands-logs ownership already correct or cannot be changed"
chown -R $(id -u):$(id -g) openwebui-data 2>/dev/null || echo "   ℹ️  openwebui-data ownership already correct or cannot be changed"

echo "✅ Directory permissions configured for user ID: $(id -u)"

# Verify directory structure
echo "📋 Directory structure verification:"
echo "   • ~/.openhands: $(ls -ld ~/.openhands | awk '{print $1, $3, $4}')"
echo "   • workspace: $(ls -ld workspace | awk '{print $1, $3, $4}')"
echo "   • openhands-logs: $(ls -ld openhands-logs | awk '{print $1, $3, $4}')"
echo "   • openwebui-data: $(ls -ld openwebui-data | awk '{print $1, $3, $4}')"

# Test write permissions
echo "🔍 Testing write permissions..."
PERMISSION_OK=true

if ! touch ~/.openhands/test-write 2>/dev/null; then
    echo "   ⚠️  Warning: Cannot write to ~/.openhands directory"
    echo "      Current permissions: $(ls -ld ~/.openhands 2>/dev/null || echo 'unknown')"
    echo "      Try: sudo chown -R $(id -u):$(id -g) ~/.openhands"
    PERMISSION_OK=false
else
    rm -f ~/.openhands/test-write
    echo "   ✅ ~/.openhands write test passed"
fi

if ! touch workspace/test-write 2>/dev/null; then
    echo "   ⚠️  Warning: Cannot write to workspace directory"
    echo "      Current permissions: $(ls -ld workspace 2>/dev/null || echo 'unknown')"
    echo "      Try: sudo chown -R $(id -u):$(id -g) workspace"
    PERMISSION_OK=false
else
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

# Create OpenHands configuration files (from test-openhands.sh)
echo ""
echo "🔧 Creating OpenHands LLM configuration files..."
mkdir -p ~/.openhands/workspace

cat > ~/.openhands/settings.json << EOF
{"language":"en","agent":"CodeActAgent","max_iterations":null,"security_analyzer":null,"confirmation_mode":false,"llm_model":"openai/devstral-small-2507","llm_api_key":"DEVSTRAL","llm_base_url":"http://host.docker.internal:11434","remote_runtime_resource_factor":1,"secrets_store":{"provider_tokens":{}},"enable_default_condenser":true,"enable_sound_notifications":false,"enable_proactive_conversation_starters":false,"user_consents_to_analytics":false,"sandbox_base_container_image":null,"sandbox_runtime_container_image":null,"mcp_config":{"sse_servers":[],"stdio_servers":[],"shttp_servers":[]},"search_api_key":"","sandbox_api_key":null,"max_budget_per_task":null,"email":null,"email_verified":null}
EOF

cat > ~/.openhands/config.toml << EOF
[llm]
model = "openai/devstral-small-2507"
base_url = "http://host.docker.internal:11434"
api_key = "dummy"
api_version = "v1"
custom_llm_provider = "openai"
drop_params = true
EOF

echo "✅ OpenHands configuration files created:"
echo "   • ~/.openhands/settings.json (UI settings with LLM config)"
echo "   • ~/.openhands/config.toml (LLM backend config)"
echo "   • LLM Model: openai/devstral-small-2507"
echo "   • LLM Base URL: http://host.docker.internal:11434"

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
echo "🛑 To stop: ./start.sh stop"
}

# Function to stop all services
stop_services() {
    echo "🛑 Stopping Devstral + OpenHands Services"
    echo "========================================="
    
    # Load environment variables for container names
    if [ -f .env ]; then
        source .env
    fi
    
    echo "🔄 Stopping Docker Compose services..."
    if docker compose ps -q | grep -q .; then
        docker compose down
        echo "✅ All services stopped"
    else
        echo "ℹ️  No services were running"
    fi
    
    echo ""
    echo "📊 Final Status:"
    echo "  • llama.cpp server: Stopped"
    echo "  • OpenHands: Stopped"  
    echo "  • OpenWebUI: Stopped"
    echo ""
    echo "📁 Data preserved:"
    echo "  • Model: ~/.models/${MODEL_NAME:-devstral-q4_k_m.gguf}"
    echo "  • OpenHands config: ~/.openhands/"
    echo "  • OpenWebUI data: ~/.openwebui/"
    echo "  • Workspace: ./workspace/"
    echo ""
    echo "🚀 To restart: ./start.sh start"
}

# Function to show container logs
show_logs() {
    echo "📋 Container Logs"
    echo "================="
    
    if ! docker compose ps -q | grep -q .; then
        echo "❌ No containers are running"
        echo "💡 Run './start.sh start' to start services"
        exit 1
    fi
    
    echo "🔍 Showing logs from all services..."
    echo "📝 Use Ctrl+C to exit log viewing"
    echo ""
    
    # Show logs with timestamps and follow
    docker compose logs --timestamps --follow
}

# Function to show container status
show_status() {
    echo "📊 Service Status"
    echo "================="
    
    # Load environment variables
    if [ -f .env ]; then
        source .env
    fi
    
    # Check if any containers are running
    if ! docker compose ps -q | grep -q .; then
        echo "❌ No services are running"
        echo "💡 Run './start.sh start' to start services"
        echo ""
        echo "📋 Available Services:"
        echo "  • llama.cpp-server (Port: ${LLAMA_ARG_PORT:-11434})"
        echo "  • openhands (Port: ${OPENHANDS_PORT:-3000})"
        echo "  • openwebui (Port: ${OPENWEBUI_PORT:-8080})"
        return
    fi
    
    echo "🔍 Docker Compose Services:"
    docker compose ps
    echo ""
    
    # Check individual service status
    echo "🔍 Service Health Status:"
    echo "------------------------"
    
    # Check llama.cpp server
    if docker compose ps --services --filter "status=running" | grep -q "llama-cpp-server"; then
        if curl -s http://localhost:${LLAMA_ARG_PORT:-11434}/health >/dev/null 2>&1; then
            echo "✅ llama.cpp server: Running and healthy"
        else
            echo "⚠️  llama.cpp server: Running but not responding"
        fi
    else
        echo "❌ llama.cpp server: Not running"
    fi
    
    # Check OpenHands
    if docker compose ps --services --filter "status=running" | grep -q "openhands"; then
        if curl -s http://localhost:${OPENHANDS_PORT:-3000} >/dev/null 2>&1; then
            echo "✅ OpenHands: Running and accessible"
        else
            echo "⚠️  OpenHands: Running but not responding"
        fi
    else
        echo "❌ OpenHands: Not running"
    fi
    
    # Check OpenWebUI
    if docker compose ps --services --filter "status=running" | grep -q "openwebui"; then
        if curl -s http://localhost:${OPENWEBUI_PORT:-8080} >/dev/null 2>&1; then
            echo "✅ OpenWebUI: Running and accessible"
        else
            echo "⚠️  OpenWebUI: Running but not responding"
        fi
    else
        echo "❌ OpenWebUI: Not running"
    fi
    
    echo ""
    echo "🌐 Access URLs:"
    echo "  • OpenHands: http://localhost:${OPENHANDS_PORT:-3000}"
    echo "  • OpenWebUI: http://localhost:${OPENWEBUI_PORT:-8080}"
    echo "  • llama.cpp API: http://localhost:${LLAMA_ARG_PORT:-11434}"
}

# Function to show detailed health status
show_health() {
    echo "🏥 Detailed Health Check"
    echo "========================"
    
    # Load environment variables
    if [ -f .env ]; then
        source .env
    fi
    
    # Check if any containers are running
    if ! docker compose ps -q | grep -q .; then
        echo "❌ No services are running"
        echo "💡 Run './start.sh start' to start services"
        return
    fi
    
    echo "🔍 Container Health Details:"
    echo ""
    
    # Detailed llama.cpp check
    echo "🔍 llama.cpp Server Health:"
    echo "---------------------------"
    if docker compose ps --services --filter "status=running" | grep -q "llama-cpp-server"; then
        CONTAINER_STATUS=$(docker inspect --format='{{.State.Health.Status}}' llama-cpp-devstral 2>/dev/null || echo "no-healthcheck")
        echo "  • Container Status: Running"
        echo "  • Health Status: $CONTAINER_STATUS"
        
        # Test API endpoints
        echo "  • Testing /health endpoint..."
        if curl -s http://localhost:${LLAMA_ARG_PORT:-11434}/health; then
            echo "    ✅ Health endpoint responding"
        else
            echo "    ❌ Health endpoint not responding"
        fi
        
        echo "  • Testing /v1/models endpoint..."
        if curl -s http://localhost:${LLAMA_ARG_PORT:-11434}/v1/models >/dev/null 2>&1; then
            echo "    ✅ Models endpoint responding"
            MODEL_COUNT=$(curl -s http://localhost:${LLAMA_ARG_PORT:-11434}/v1/models | jq -r '.data | length' 2>/dev/null || echo "unknown")
            echo "    📊 Available models: $MODEL_COUNT"
        else
            echo "    ❌ Models endpoint not responding"
        fi
    else
        echo "  ❌ Container not running"
    fi
    echo ""
    
    # Detailed OpenHands check
    echo "🔍 OpenHands Health:"
    echo "-------------------"
    if docker compose ps --services --filter "status=running" | grep -q "openhands"; then
        echo "  • Container Status: Running"
        echo "  • Testing web interface..."
        
        HTTP_STATUS=$(curl -s -w "%{http_code}" -o /dev/null http://localhost:${OPENHANDS_PORT:-3000} 2>/dev/null || echo "000")
        if [ "$HTTP_STATUS" = "200" ]; then
            echo "    ✅ Web interface responding (HTTP $HTTP_STATUS)"
        else
            echo "    ⚠️  Web interface status: HTTP $HTTP_STATUS"
        fi
        
        # Check configuration files
        if [ -f ~/.openhands/settings.json ]; then
            echo "    ✅ Settings configuration exists"
        else
            echo "    ❌ Settings configuration missing"
        fi
        
        if [ -f ~/.openhands/config.toml ]; then
            echo "    ✅ LLM configuration exists"
        else
            echo "    ❌ LLM configuration missing"
        fi
    else
        echo "  ❌ Container not running"
    fi
    echo ""
    
    # Detailed OpenWebUI check
    echo "🔍 OpenWebUI Health:"
    echo "-------------------"
    if docker compose ps --services --filter "status=running" | grep -q "openwebui"; then
        echo "  • Container Status: Running"
        echo "  • Testing web interface..."
        
        HTTP_STATUS=$(curl -s -w "%{http_code}" -o /dev/null http://localhost:${OPENWEBUI_PORT:-8080} 2>/dev/null || echo "000")
        if [ "$HTTP_STATUS" = "200" ]; then
            echo "    ✅ Web interface responding (HTTP $HTTP_STATUS)"
        else
            echo "    ⚠️  Web interface status: HTTP $HTTP_STATUS"
        fi
        
        # Check data directory
        if [ -d ~/.openwebui ]; then
            DATA_SIZE=$(du -sh ~/.openwebui 2>/dev/null | cut -f1)
            echo "    📁 Data directory size: $DATA_SIZE"
        else
            echo "    ❌ Data directory not found"
        fi
    else
        echo "  ❌ Container not running"
    fi
    echo ""
    
    # Resource usage
    echo "🔍 Resource Usage:"
    echo "------------------"
    if docker compose ps -q | grep -q .; then
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
    else
        echo "  ℹ️  No containers running"
    fi
    echo ""
    
    echo "📊 System Status Summary:"
    echo "========================"
    RUNNING_SERVICES=$(docker compose ps --services --filter "status=running" | wc -l)
    TOTAL_SERVICES=3
    echo "  • Services Running: $RUNNING_SERVICES/$TOTAL_SERVICES"
    
    if [ "$RUNNING_SERVICES" -eq "$TOTAL_SERVICES" ]; then
        echo "  • Overall Status: ✅ All systems operational"
    elif [ "$RUNNING_SERVICES" -gt 0 ]; then
        echo "  • Overall Status: ⚠️  Partial deployment"
    else
        echo "  • Overall Status: ❌ No services running"
    fi
}

# Function to restart all services
restart_services() {
    echo "🔄 Restarting Devstral + OpenHands Services"
    echo "==========================================="
    
    echo "🛑 Stopping services..."
    stop_services
    
    echo ""
    echo "⏳ Waiting 5 seconds before restart..."
    sleep 5
    
    echo ""
    echo "🚀 Starting services..."
    start_services
}

# Load environment variables for usage display
if [ -f .env ]; then
    source .env
fi

# Main script logic
case "${1:-}" in
    "start")
        start_services
        ;;
    "stop")
        stop_services
        ;;
    "restart")
        restart_services
        ;;
    "logs")
        show_logs
        ;;
    "status")
        show_status
        ;;
    "health")
        show_health
        ;;
    "help"|"-h"|"--help"|"")
        show_usage
        ;;
    *)
        echo "❌ Unknown command: $1"
        echo ""
        show_usage
        ;;
esac
