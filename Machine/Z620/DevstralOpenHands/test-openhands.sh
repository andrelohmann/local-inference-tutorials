#!/bin/bash

# OpenHands Container Test Script
# Simple container management for OpenHands development environment

set -e

# Function to show usage
show_usage() {
    echo "🤖 OpenHands Container Test Script"
    echo "=================================="
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  up      Start OpenHands container"
    echo "  down    Stop and remove container"
    echo "  logs    Show container logs"
    echo "  status  Show container status"
    echo "  test    Test OpenHands web interface"
    echo "  help    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 up       # Start container"
    echo "  $0 down     # Stop container"
    echo "  $0 logs     # View logs"
    echo "  $0 status   # Check status"
    echo "  $0 test     # Test web interface"
    echo ""
    echo "Configuration (Fixed Parameters):"
    echo "  • Container Name: openhands-test"
    echo "  • Port: 3000"
    echo "  • Workspace: ~/workspace"
    echo "  • OpenHands Config: ~/.openhands"
    echo "  • Docker Socket: /var/run/docker.sock"
    echo "  • Image: docker.all-hands.dev/all-hands-ai/openhands:0.49"
    echo "  • Runtime: docker.all-hands.dev/all-hands-ai/runtime:0.49-nikolaik"
    echo ""
    echo "LLM Configuration:"
    echo "  • Model: openai/devstral-2507"
    echo "  • Base URL: http://host.docker.internal:11434"
    echo "  • API Version: v1"
    echo "  • Auto-configured for local llama.cpp server"
    echo ""
    echo "Web Interface:"
    echo "  • URL: http://localhost:3000"
    echo "  • Development environment for AI agents"
    echo "  • Access to workspace and Docker"
    echo ""
    exit 0
}

# Function to start OpenHands container
start_container() {
    echo "🚀 Starting OpenHands Container"
    echo "==============================="
    
    CONTAINER_NAME="openhands-test"
    OPENHANDS_IMAGE="docker.all-hands.dev/all-hands-ai/openhands:0.49"
    RUNTIME_IMAGE="docker.all-hands.dev/all-hands-ai/runtime:0.49-nikolaik"
    
    # Check if container is already running
    if docker ps -q --filter "name=$CONTAINER_NAME" | grep -q .; then
        echo "⚠️  Container is already running"
        show_status
        return 0
    fi
    
    # Remove existing container if it exists
    if docker ps -aq --filter "name=$CONTAINER_NAME" | grep -q .; then
        echo "🗑️  Removing existing container..."
        docker rm $CONTAINER_NAME
    fi

    # Create required directories
    mkdir -p ~/workspace
    mkdir -p ~/.openhands

    echo "🔄 Starting OpenHands container..."
    echo "📝 Container Configuration:"
    echo "  • Image: $OPENHANDS_IMAGE"
    echo "  • Runtime: $RUNTIME_IMAGE"
    echo "  • Port: 3000"
    echo "  • Workspace: ~/workspace"
    echo "  • Config: ~/.openhands"
    echo "  • LLM Model: openai/devstral-2507"
    echo "  • LLM Base URL: http://host.docker.internal:11434"
    echo "  • Docker Socket: Mounted"
    echo ""
    
    # Pull the latest image
    echo "📦 Pulling OpenHands image..."
    docker pull $OPENHANDS_IMAGE
    
    # Start container with official OpenHands parameters
    CONTAINER_ID=$(docker run -d \
        --name $CONTAINER_NAME \
        --pull=always \
        -e SANDBOX_RUNTIME_CONTAINER_IMAGE=$RUNTIME_IMAGE \
        -e LOG_ALL_EVENTS=true \
        -e LLM_MODEL=openai/devstral-2507 \
        -e LLM_BASE_URL=http://host.docker.internal:11434 \
        -e LLM_API_KEY=dummy \
        -e LLM_API_VERSION=v1 \
        -e LLM_DROP_PARAMS=true \
        -e WORKSPACE_BASE=/workspace \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v ~/.openhands:/.openhands \
        -v ~/workspace:/workspace \
        -p 3000:3000 \
        --add-host host.docker.internal:host-gateway \
        $OPENHANDS_IMAGE)
    
    echo "✅ Container started with ID: $CONTAINER_ID"
    echo "⏳ Waiting 15 seconds for container to initialize..."
    sleep 15
    
    # Check if container is still running after startup
    if ! docker ps -q --filter "name=$CONTAINER_NAME" | grep -q .; then
        echo "❌ Container stopped during startup"
        echo "🔍 Container logs:"
        docker logs $CONTAINER_NAME
        echo ""
        echo "🔍 Container status:"
        docker ps -a --filter "name=$CONTAINER_NAME"
        echo ""
        echo "❌ Container startup failed"
        exit 1
    fi
    
    # Wait for web interface to be ready
    echo "⏳ Waiting for OpenHands web interface to be ready..."
    for i in {1..30}; do
        if curl -s http://localhost:3000 >/dev/null 2>&1; then
            echo "✅ OpenHands web interface is ready!"
            break
        fi
        
        # Check if container is still running
        if ! docker ps -q --filter "name=$CONTAINER_NAME" | grep -q .; then
            echo "❌ Container stopped unexpectedly"
            echo "🔍 Container logs:"
            docker logs --tail 20 $CONTAINER_NAME
            echo ""
            echo "🔍 Container status:"
            docker ps -a --filter "name=$CONTAINER_NAME"
            exit 1
        fi
        
        if [ $i -eq 30 ]; then
            echo "❌ Web interface failed to start within 30 seconds"
            echo "🔍 Container logs:"
            docker logs --tail 20 $CONTAINER_NAME
            echo ""
            echo "🔍 Container status:"
            docker ps -a --filter "name=$CONTAINER_NAME"
            exit 1
        fi
        
        echo "⏳ Attempt $i/30 - waiting for web interface..."
        sleep 1
    done
    
    echo ""
    echo "🎉 OpenHands container is running successfully!"
    echo "  • Container: $CONTAINER_NAME"
    echo "  • Web Interface: http://localhost:3000"
    echo "  • Workspace: ~/workspace"
    echo "  • Config: ~/.openhands"
    echo "  • LLM: devstral-2507 via llama.cpp (port 11434)"
    echo ""
    echo "🧪 Run './test-openhands.sh test' to test the web interface"
    echo "🌐 Open http://localhost:3000 in your browser to access OpenHands"
    echo ""
    echo "💡 Prerequisites:"
    echo "  • llama.cpp server running on port 11434"
    echo "  • Run './test-llama-cpp.sh up' if not already running"
}

# Function to stop container
stop_container() {
    echo "🛑 Stopping OpenHands Container"
    echo "==============================="
    
    CONTAINER_NAME="openhands-test"
    
    # Stop container
    if docker ps -q --filter "name=$CONTAINER_NAME" | grep -q .; then
        echo "🔄 Stopping container: $CONTAINER_NAME"
        docker stop $CONTAINER_NAME
    else
        echo "ℹ️  Container is not running"
    fi

    # Remove container
    if docker ps -aq --filter "name=$CONTAINER_NAME" | grep -q .; then
        echo "🗑️  Removing container: $CONTAINER_NAME"
        docker rm $CONTAINER_NAME
    else
        echo "ℹ️  Container does not exist"
    fi
    
    echo "✅ Container stopped and removed!"
    echo "📁 Workspace data preserved in ~/workspace"
    echo "⚙️  Configuration preserved in ~/.openhands"
}

# Function to show container logs
show_logs() {
    CONTAINER_NAME="openhands-test"
    
    echo "📋 OpenHands Container Logs"
    echo "=========================="
    
    if docker ps -q --filter "name=$CONTAINER_NAME" | grep -q .; then
        echo "🔍 Container Logs (Running):"
        echo "----------------------------"
        docker logs --tail 50 $CONTAINER_NAME
    elif docker ps -aq --filter "name=$CONTAINER_NAME" | grep -q .; then
        echo "🔍 Container Logs (Stopped):"
        echo "----------------------------"
        docker logs --tail 50 $CONTAINER_NAME
    else
        echo "❌ Container does not exist"
        echo "💡 Run './test-openhands.sh up' to start the container"
    fi
}

# Function to show container status
show_status() {
    CONTAINER_NAME="openhands-test"
    
    echo "📊 OpenHands Container Status"
    echo "============================="
    
    # Check container status
    if docker ps -q --filter "name=$CONTAINER_NAME" | grep -q .; then
        echo "✅ Container is running"
        docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        echo ""
        
        # Test web interface
        echo "🔍 Web Interface Status:"
        echo "----------------------"
        
        # Web interface check
        if curl -s http://localhost:3000 >/dev/null 2>&1; then
            echo "✅ Web Interface: Available"
        else
            echo "❌ Web Interface: Not responding"
        fi
        
        # Check llama.cpp dependency
        echo ""
        echo "🔍 Dependencies:"
        echo "---------------"
        if curl -s http://localhost:11434/health >/dev/null 2>&1; then
            echo "✅ llama.cpp server: Running (port 11434)"
        else
            echo "❌ llama.cpp server: Not running (port 11434)"
            echo "💡 Run './test-llama-cpp.sh up' to start llama.cpp"
        fi
        
    elif docker ps -aq --filter "name=$CONTAINER_NAME" | grep -q .; then
        echo "❌ Container exists but is stopped"
        docker ps -a --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        echo "❌ Container does not exist"
    fi
    
    echo ""
    echo "🌐 Access Points:"
    echo "  • Web Interface: http://localhost:3000"
    echo "  • Workspace: ~/workspace"
    echo "  • Config: ~/.openhands"
    echo ""
    echo "📊 Quick Test Commands:"
    echo "  curl -I http://localhost:3000"
    echo "  ./test-openhands.sh test"
}

# Function to test OpenHands web interface
test_web_interface() {
    echo "🧪 Testing OpenHands Web Interface"
    echo "=================================="
    
    # Check if container is running
    if ! docker ps -q --filter "name=openhands-test" | grep -q .; then
        echo "❌ Container is not running"
        echo "💡 Run './test-openhands.sh up' first"
        exit 1
    fi
    
    BASE_URL="http://localhost:3000"
    
    echo "🔍 Testing web interface accessibility..."
    echo ""
    
    # Test 1: Web interface response
    echo "🔍 Test 1: Web Interface Response"
    echo "=================================="
    
    HTTP_RESPONSE=$(curl -s -I "$BASE_URL" 2>/dev/null)
    if [ $? -eq 0 ] && echo "$HTTP_RESPONSE" | grep -q "200 OK"; then
        echo "✅ Web interface is accessible"
        echo "📋 Response headers:"
        echo "$HTTP_RESPONSE" | head -3
    else
        echo "❌ Web interface is not accessible"
        echo "📋 Response: $HTTP_RESPONSE"
        return 1
    fi
    echo ""
    
    # Test 2: Container health
    echo "🔍 Test 2: Container Health"
    echo "==========================="
    
    if docker ps --filter "name=openhands-test" --format "{{.Status}}" | grep -q "Up"; then
        echo "✅ Container is running and healthy"
        UPTIME=$(docker ps --filter "name=openhands-test" --format "{{.Status}}")
        echo "📊 Container status: $UPTIME"
    else
        echo "❌ Container is not healthy"
        return 1
    fi
    echo ""
    
    # Test 3: Workspace access
    echo "🔍 Test 3: Workspace Access"
    echo "==========================="
    
    if [ -d ~/workspace ]; then
        echo "✅ Workspace directory exists"
        WORKSPACE_SIZE=$(du -sh ~/workspace 2>/dev/null | cut -f1)
        echo "📁 Workspace size: $WORKSPACE_SIZE"
        
        # Test write access
        TEST_FILE="~/workspace/.openhands-test-$(date +%s)"
        if touch "$TEST_FILE" 2>/dev/null; then
            echo "✅ Workspace is writable"
            rm -f "$TEST_FILE"
        else
            echo "❌ Workspace is not writable"
        fi
    else
        echo "❌ Workspace directory does not exist"
    fi
    echo ""
    
    # Test 4: Configuration directory
    echo "🔍 Test 4: Configuration Directory"
    echo "=================================="
    
    if [ -d ~/.openhands ]; then
        echo "✅ OpenHands config directory exists"
        CONFIG_SIZE=$(du -sh ~/.openhands 2>/dev/null | cut -f1)
        echo "⚙️  Config size: $CONFIG_SIZE"
    else
        echo "❌ OpenHands config directory does not exist"
    fi
    echo ""
    
    # Test 5: LLM Backend Connection
    echo "🔍 Test 5: LLM Backend Connection"
    echo "================================="
    
    if curl -s http://localhost:11434/health >/dev/null 2>&1; then
        echo "✅ llama.cpp server is accessible"
        
        # Test models endpoint
        if curl -s http://localhost:11434/v1/models | jq -r '.data[].id' | grep -q "devstral"; then
            echo "✅ Devstral model is available"
        else
            echo "⚠️  Devstral model may not be loaded"
        fi
    else
        echo "❌ llama.cpp server is not accessible"
        echo "💡 Run './test-llama-cpp.sh up' to start llama.cpp server"
    fi
    echo ""
    
    # Test 6: Docker socket access
    echo "🔍 Test 6: Docker Socket Access"
    echo "==============================="
    
    DOCKER_ACCESS=$(docker exec openhands-test docker --version 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "✅ Docker socket is accessible from container"
        echo "🐳 Docker version: $DOCKER_ACCESS"
    else
        echo "❌ Docker socket is not accessible from container"
        echo "📋 This may affect agent capabilities"
    fi
    echo ""
    
    echo "🎯 Test Summary"
    echo "==============="
    echo "✅ Completed OpenHands web interface testing"
    echo "🌐 Web interface accessible at http://localhost:3000"
    echo "📁 Workspace available at ~/workspace"
    echo "⚙️  Configuration stored in ~/.openhands"
    echo "🤖 OpenHands AI development environment is ready"
    echo ""
    echo "🔗 Integration Status:"
    if curl -s http://localhost:11434/health >/dev/null 2>&1; then
        echo "  ✅ llama.cpp backend: Connected"
    else
        echo "  ❌ llama.cpp backend: Not connected"
    fi
    echo ""
    echo "🚀 Access OpenHands in your browser: http://localhost:3000"
}

# Main script logic
case "${1:-}" in
    "up"|"start")
        start_container
        ;;
    "down"|"stop")
        stop_container
        ;;
    "logs")
        show_logs
        ;;
    "status")
        show_status
        ;;
    "test")
        test_web_interface
        ;;
    "help"|"-h"|"--help")
        show_usage
        ;;
    "")
        show_usage
        ;;
    *)
        echo "❌ Unknown command: $1"
        echo ""
        show_usage
        ;;
esac
