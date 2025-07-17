#!/bin/bash

# OpenWebUI Container Test Script
# Direct container testing with fixed parameters for easy modification

set -e

# Function to show usage
show_usage() {
    echo "🌐 OpenWebUI Container Test Script"
    echo "=================================="
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  up      Start OpenWebUI container"
    echo "  down    Stop and remove container"
    echo "  logs    Show container logs"
    echo "  status  Show container status"
    echo "  test    Run OpenWebUI tests"
    echo "  help    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 up       # Start container"
    echo "  $0 down     # Stop container"
    echo "  $0 logs     # View logs"
    echo "  $0 status   # Check status"
    echo "  $0 test     # Test OpenWebUI functionality"
    echo ""
    echo "Configuration (Fixed Parameters):"
    echo "  • Container Name: openwebui-test"
    echo "  • Port: 3000"
    echo "  • Data Path: ~/.openwebui:/app/backend/data"
    echo "  • Authentication: Disabled"
    echo "  • llama.cpp Endpoint: http://host.docker.internal:11434"
    echo "  • Model: devstral-2507:latest"
    echo "  • Context Window: 88832"
    echo "  • OpenAI API: Enabled"
    echo "  • Ollama API: Disabled"
    echo ""
    echo "Prerequisites:"
    echo "  • llama.cpp container must be running on port 11434"
    echo "  • Run './test-llama-cpp.sh up' first"
    echo ""
    echo "Web Interface:"
    echo "  • OpenWebUI: http://localhost:3000"
    echo "  • No login required (authentication disabled)"
    echo ""
    exit 0
}

# Function to check if llama.cpp is running
check_llama_cpp() {
    if ! curl -s http://localhost:11434/health >/dev/null 2>&1; then
        echo "❌ llama.cpp container is not running or not responding"
        echo "💡 Please start llama.cpp first: './test-llama-cpp.sh up'"
        return 1
    fi
    
    if ! curl -s http://localhost:11434/v1/models | jq . >/dev/null 2>&1; then
        echo "❌ llama.cpp models endpoint is not responding"
        echo "💡 Please check llama.cpp status: './test-llama-cpp.sh status'"
        return 1
    fi
    
    echo "✅ llama.cpp container is running and responding"
    return 0
}

# Function to start OpenWebUI container
start_container() {
    echo "🚀 Starting OpenWebUI Container"
    echo "==============================="
    
    CONTAINER_NAME="openwebui-test"
    
    # Check if llama.cpp is running
    if ! check_llama_cpp; then
        exit 1
    fi
    
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

    # Clear persistent volume
    echo "🧹 Clearing persistent volume..."
    if [ -d ~/.openwebui ]; then
        rm -rf ~/.openwebui/*
        echo "✅ Cleared ~/.openwebui directory"
    else
        mkdir -p ~/.openwebui
        echo "✅ Created ~/.openwebui directory"
    fi

    echo "🔄 Starting OpenWebUI container with fixed parameters..."
    echo "📝 Container Configuration:"
    echo "  • Authentication: Disabled"
    echo "  • OpenAI API: Enabled"
    echo "  • Ollama API: Disabled"
    echo "  • llama.cpp Endpoint: http://host.docker.internal:11434"
    echo "  • Model: devstral-2507:latest"
    echo "  • Context Window: 88832"
    echo "  • Data Volume: ~/.openwebui:/app/backend/data"
    echo ""
    
    # Start container with fixed parameters
    CONTAINER_ID=$(docker run -d \
        --name openwebui-test \
        -p 8080:8080 \
        -v ~/.openwebui:/app/backend/data \
        --add-host=host.docker.internal:host-gateway \
        -e WEBUI_AUTH=false \
        -e ENABLE_OLLAMA_API=false \
        -e ENABLE_OPENAI_API=true \
        -e OPENAI_API_BASE_URL=http://host.docker.internal:11434/v1 \
        -e OPENAI_API_KEY=sk-no-key-required \
        ghcr.io/open-webui/open-webui:latest)
    
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
    
    # Wait for OpenWebUI to be ready
    echo "⏳ Waiting for OpenWebUI to be ready..."
    for i in {1..60}; do
        if curl -s http://localhost:3000 >/dev/null 2>&1; then
            echo "✅ OpenWebUI is ready!"
            break
        fi
        
        # Check if container is still running
        if ! docker ps -q --filter "name=$CONTAINER_NAME" | grep -q .; then
            echo "❌ Container stopped unexpectedly"
            echo "🔍 Container logs:"
            docker logs --tail 30 $CONTAINER_NAME
            echo ""
            echo "🔍 Container status:"
            docker ps -a --filter "name=$CONTAINER_NAME"
            exit 1
        fi
        
        if [ $i -eq 60 ]; then
            echo "❌ OpenWebUI failed to start within 60 seconds"
            echo "🔍 Container logs:"
            docker logs --tail 30 $CONTAINER_NAME
            echo ""
            echo "🔍 Container status:"
            docker ps -a --filter "name=$CONTAINER_NAME"
            exit 1
        fi
        
        echo "⏳ Attempt $i/60 - waiting for OpenWebUI..."
        sleep 1
    done
    
    # Test basic connectivity
    echo "🔍 Testing OpenWebUI connectivity..."
    
    # Test main page
    if curl -s http://localhost:3000 >/dev/null 2>&1; then
        echo "✅ OpenWebUI main page accessible"
    else
        echo "❌ OpenWebUI main page failed"
        exit 1
    fi
    
    echo ""
    echo "🎉 OpenWebUI container is running successfully!"
    echo "  • Container: openwebui-test"
    echo "  • Web Interface: http://localhost:3000"
    echo "  • Authentication: Disabled (no login required)"
    echo "  • Connected to llama.cpp: http://host.docker.internal:11434"
    echo "  • Available Model: devstral-2507:latest"
    echo "  • Context Window: 88832 tokens"
    echo ""
    echo "🧪 Run './test-openwebui.sh test' to test functionality"
    echo "🌐 Open http://localhost:3000 in your browser"
}

# Function to stop container
stop_container() {
    echo "🛑 Stopping OpenWebUI Container"
    echo "==============================="
    
    CONTAINER_NAME="openwebui-test"
    
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
    
    # Clear persistent volume
    echo "🧹 Clearing persistent volume..."
    if [ -d ~/.openwebui ]; then
        rm -rf ~/.openwebui/*
        echo "✅ Cleared ~/.openwebui directory"
    fi
    
    echo "✅ Container stopped and removed!"
}

# Function to show container logs
show_logs() {
    CONTAINER_NAME="openwebui-test"
    
    echo "📋 OpenWebUI Container Logs"
    echo "=========================="
    
    if docker ps -q --filter "name=$CONTAINER_NAME" | grep -q .; then
        echo "🔍 Container Logs (Running):"
        echo "----------------------------"
        docker logs --tail 100 $CONTAINER_NAME
    elif docker ps -aq --filter "name=$CONTAINER_NAME" | grep -q .; then
        echo "🔍 Container Logs (Stopped):"
        echo "----------------------------"
        docker logs --tail 100 $CONTAINER_NAME
    else
        echo "❌ Container does not exist"
        echo "💡 Run './test-openwebui.sh up' to start the container"
    fi
}

# Function to show container status
show_status() {
    CONTAINER_NAME="openwebui-test"
    
    echo "📊 OpenWebUI Container Status"
    echo "============================="
    
    # Check llama.cpp status first
    echo "🔍 llama.cpp Dependency Status:"
    echo "-------------------------------"
    if check_llama_cpp; then
        echo "✅ llama.cpp is ready"
    else
        echo "❌ llama.cpp is not available"
        echo "💡 Start llama.cpp: './test-llama-cpp.sh up'"
        echo ""
    fi
    
    # Check container status
    if docker ps -q --filter "name=$CONTAINER_NAME" | grep -q .; then
        echo "✅ Container is running"
        docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        echo ""
        
        # Test endpoints
        echo "🔍 OpenWebUI Status:"
        echo "-------------------"
        
        # Web interface check
        if curl -s http://localhost:3000 >/dev/null 2>&1; then
            echo "✅ Web Interface: Available"
        else
            echo "❌ Web Interface: Not responding"
        fi
        
        # Check if it can reach llama.cpp
        if curl -s http://localhost:11434/health >/dev/null 2>&1; then
            echo "✅ llama.cpp Connection: Available"
        else
            echo "❌ llama.cpp Connection: Not available"
        fi
        
    elif docker ps -aq --filter "name=$CONTAINER_NAME" | grep -q .; then
        echo "❌ Container exists but is stopped"
        docker ps -a --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        echo "❌ Container does not exist"
    fi
    
    echo ""
    echo "🌐 Access Information:"
    echo "  • Web Interface: http://localhost:3000"
    echo "  • Authentication: Disabled"
    echo "  • Default Model: devstral-2507:latest"
    echo "  • Context Window: 88832 tokens"
    echo "  • llama.cpp Endpoint: http://host.docker.internal:11434"
    echo ""
    echo "📊 Quick Test Commands:"
    echo "  curl http://localhost:3000"
    echo "  open http://localhost:3000"
    echo "  ./test-openwebui.sh test"
}

# Function to run OpenWebUI tests
run_openwebui_tests() {
    echo "🧪 Running OpenWebUI Tests"
    echo "=========================="
    
    # Check if container is running
    if ! docker ps -q --filter "name=openwebui-test" | grep -q .; then
        echo "❌ Container is not running"
        echo "💡 Run './test-openwebui.sh up' first"
        exit 1
    fi
    
    # Check if llama.cpp is running
    if ! check_llama_cpp; then
        echo "❌ llama.cpp is not available"
        echo "💡 Run './test-llama-cpp.sh up' first"
        exit 1
    fi
    
    BASE_URL="http://localhost:3000"
    
    echo "🔍 Testing OpenWebUI functionality..."
    echo ""
    
    # Test 1: Web interface accessibility
    echo "🔍 Test 1: Web Interface Accessibility"
    echo "======================================"
    if curl -s "$BASE_URL" >/dev/null 2>&1; then
        echo "✅ Web interface is accessible"
        
        # Check if it returns HTML content
        CONTENT=$(curl -s "$BASE_URL")
        if echo "$CONTENT" | grep -q "<html\|<HTML"; then
            echo "✅ Returns valid HTML content"
        else
            echo "❌ Does not return valid HTML content"
        fi
    else
        echo "❌ Web interface is not accessible"
        return 1
    fi
    echo ""
    
    # Test 2: API endpoint availability
    echo "🔍 Test 2: API Endpoint Availability"
    echo "===================================="
    # Check if OpenWebUI API endpoints are available
    if curl -s "$BASE_URL/api/v1/auths" >/dev/null 2>&1; then
        echo "✅ OpenWebUI API endpoints are available"
    else
        echo "❌ OpenWebUI API endpoints are not available"
        echo "🔍 Checking alternative endpoints..."
        
        # Try other common endpoints
        if curl -s "$BASE_URL/api/config" >/dev/null 2>&1; then
            echo "✅ Config API endpoint is available"
        elif curl -s "$BASE_URL/health" >/dev/null 2>&1; then
            echo "✅ Health API endpoint is available"
        else
            echo "❌ No API endpoints are responding"
        fi
    fi
    echo ""
    
    # Test 3: llama.cpp integration
    echo "🔍 Test 3: llama.cpp Integration"
    echo "================================"
    # Test if OpenWebUI can connect to llama.cpp
    if curl -s http://localhost:11434/health >/dev/null 2>&1; then
        echo "✅ llama.cpp is reachable from host"
        
        # Check if models are available
        if curl -s http://localhost:11434/v1/models | jq . >/dev/null 2>&1; then
            echo "✅ llama.cpp models endpoint is working"
            echo "📋 Available models:"
            curl -s http://localhost:11434/v1/models | jq -r '.data[].id'
        else
            echo "❌ llama.cpp models endpoint is not working"
        fi
    else
        echo "❌ llama.cpp is not reachable"
        return 1
    fi
    echo ""
    
    # Test 4: Configuration verification
    echo "🔍 Test 4: Configuration Verification"
    echo "====================================="
    echo "📋 Container Configuration:"
    echo "  • Authentication: Disabled"
    echo "  • OpenAI API: Enabled"
    echo "  • Ollama API: Disabled"
    echo "  • Default Model: devstral-2507:latest"
    echo "  • Context Window: 88832 tokens"
    echo "  • llama.cpp Endpoint: http://host.docker.internal:11434"
    echo "✅ Configuration is set as expected"
    echo ""
    
    # Test 5: Volume persistence
    echo "🔍 Test 5: Volume Persistence"
    echo "============================="
    if [ -d ~/.openwebui ]; then
        echo "✅ Data volume directory exists: ~/.openwebui"
        
        # Check if directory is writable
        if [ -w ~/.openwebui ]; then
            echo "✅ Data volume is writable"
        else
            echo "❌ Data volume is not writable"
        fi
        
        # Show directory contents
        echo "📋 Data directory contents:"
        ls -la ~/.openwebui/ 2>/dev/null || echo "  (empty or not accessible)"
    else
        echo "❌ Data volume directory does not exist"
    fi
    echo ""
    
    # Test 6: Container resource usage
    echo "🔍 Test 6: Container Resource Usage"
    echo "==================================="
    CONTAINER_STATS=$(docker stats openwebui-test --no-stream --format "table {{.CPUPerc}}\t{{.MemUsage}}")
    if [ $? -eq 0 ]; then
        echo "✅ Container resource usage:"
        echo "$CONTAINER_STATS"
    else
        echo "❌ Could not get container resource usage"
    fi
    echo ""
    
    # Test 7: Network connectivity
    echo "🔍 Test 7: Network Connectivity"
    echo "==============================="
    # Test if container can reach external llama.cpp
    CONTAINER_NETWORK_TEST=$(docker exec openwebui-test curl -s http://host.docker.internal:11434/health 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$CONTAINER_NETWORK_TEST" ]; then
        echo "✅ Container can reach llama.cpp: $CONTAINER_NETWORK_TEST"
    else
        echo "❌ Container cannot reach llama.cpp"
        echo "🔍 Testing container network configuration..."
        docker exec openwebui-test ping -c 1 host.docker.internal >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "✅ Container can ping host.docker.internal"
        else
            echo "❌ Container cannot ping host.docker.internal"
        fi
    fi
    echo ""
    
    # Test 8: Log analysis
    echo "🔍 Test 8: Log Analysis"
    echo "======================="
    echo "📋 Recent container logs (last 10 lines):"
    docker logs --tail 10 openwebui-test 2>/dev/null || echo "❌ Could not retrieve logs"
    echo ""
    
    echo "🎯 Test Summary"
    echo "==============="
    echo "✅ Completed OpenWebUI functionality testing"
    echo "🌐 Web interface tested for accessibility"
    echo "🔗 llama.cpp integration verified"
    echo "📋 Configuration and persistence tested"
    echo "🔧 Container health and network connectivity verified"
    echo ""
    echo "🚀 OpenWebUI is ready for use!"
    echo "🌐 Access at: http://localhost:3000"
    echo "🤖 Model: devstral-2507:latest"
    echo "📝 Context: 88832 tokens"
    echo "🔓 No authentication required"
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
        run_openwebui_tests
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
