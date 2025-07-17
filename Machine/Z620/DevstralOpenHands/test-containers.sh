#!/bin/bash

# Direct llama.cpp + OpenWebUI container testing script
# This runs the llama.cpp container directly without docker-compose for parameter testing

set -e

# Function to show usage
show_usage() {
    echo "🚀 llama.cpp + OpenWebUI Test Script"
    echo "====================================="
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  up         Start llama.cpp and OpenWebUI containers"
    echo "  down       Stop and remove both containers and volumes"
    echo "  logs       Show container logs"
    echo "  status     Show container status"
    echo "  test       Run API endpoint tests (chat and generate)"
    echo "  basic-test Test basic container functionality"
    echo "  help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 up       # Start both containers"
    echo "  $0 down     # Stop and remove both containers"
    echo "  $0 logs     # View container logs"
    echo "  $0 status   # Check container status"
    echo "  $0 test     # Test both chat and generate endpoints"
    echo ""
    echo "Configuration:"
    echo "  • llama.cpp Container: llama-cpp-test (port 11434)"
    echo "  • OpenWebUI Container: openwebui-test (port 8080)"
    echo "  • Model: devstral-q4_k_m.gguf"
    echo "  • GPU Layers: 41"
    echo "  • Context Size: 88832"
    echo "  • Model Alias: devstral-2507:latest"
    echo "  • Authentication: Disabled"
    echo ""
    echo "Interfaces:"
    echo "  • llama.cpp API: http://localhost:11434"
    echo "  • OpenWebUI: http://localhost:8080"
    echo ""
    exit 0
}

# Function to start containers
start_containers() {
    echo "🚀 Starting llama.cpp + OpenWebUI Containers"
    echo "============================================"
    
    CONTAINER_NAME="llama-cpp-test"
    OPENWEBUI_CONTAINER_NAME="openwebui-test"
    
    # Build the llama.cpp container if it doesn't exist
    if ! docker images | grep -q "llama-cpp-devstral"; then
        echo "🔨 Building llama.cpp container..."
        docker build -t llama-cpp-devstral .
    fi
    
    # Check if llama.cpp container is already running
    if docker ps -q --filter "name=$CONTAINER_NAME" | grep -q .; then
        echo "⚠️  llama.cpp container is already running"
    else
        # Remove existing container if it exists
        if docker ps -aq --filter "name=$CONTAINER_NAME" | grep -q .; then
            echo "🗑️  Removing existing llama.cpp container..."
            docker rm $CONTAINER_NAME
        fi

        echo "🔄 Starting llama.cpp container: $CONTAINER_NAME"
        echo "📝 Container arguments:"
        echo "  - Model: /models/devstral-q4_k_m.gguf"
        echo "  - Port: 11434"
        echo "  - Host: 0.0.0.0"
        echo "  - GPU Layers: 41"
        echo "  - Context Size: 88832"
        echo "  - Alias: devstral-2507:latest"
        echo ""
        
        CONTAINER_ID=$(docker run -d \
            --name $CONTAINER_NAME \
            --gpus all \
            -p 11434:11434 \
            -v ~/.models:/models \
            llama-cpp-devstral \
            --model /models/devstral-q4_k_m.gguf \
            --port 11434 \
            --host 0.0.0.0 \
            --n-gpu-layers 41 \
            --ctx-size 88832 \
            --alias devstral-2507:latest)
        
        echo "✅ Container started with ID: $CONTAINER_ID"
        echo "⏳ Waiting 3 seconds for container to initialize..."
        sleep 3
        
        # Check if container is still running after initial startup
        if ! docker ps -q --filter "name=$CONTAINER_NAME" | grep -q .; then
            echo "❌ Container stopped during startup - checking logs..."
            docker logs $CONTAINER_NAME
            echo ""
            echo "🔍 Container status:"
            docker ps -a --filter "name=$CONTAINER_NAME"
            echo ""
            echo "❌ Container startup failed - exiting"
            exit 1
        fi
    fi
    
    # Wait for llama.cpp to be ready
    echo "⏳ Waiting for llama.cpp to be ready..."
    for i in {1..30}; do
        if curl -s http://localhost:11434/health >/dev/null 2>&1; then
            echo "✅ llama.cpp is ready!"
            break
        fi
        
        # Check if container is still running
        if ! docker ps -q --filter "name=$CONTAINER_NAME" | grep -q .; then
            echo "❌ llama.cpp container stopped unexpectedly"
            echo "🔍 Checking container logs for debugging..."
            docker logs --tail 20 $CONTAINER_NAME
            echo ""
            echo "🔍 Checking container status..."
            docker ps -a --filter "name=$CONTAINER_NAME"
            echo ""
            echo "🔄 Attempting to restart container..."
            docker start $CONTAINER_NAME
            sleep 2
        fi
        
        if [ $i -eq 30 ]; then
            echo "❌ llama.cpp failed to start within 30 seconds"
            echo "🔍 Checking container logs for debugging..."
            docker logs --tail 20 $CONTAINER_NAME
            echo ""
            echo "🔍 Checking container status..."
            docker ps -a --filter "name=$CONTAINER_NAME"
            exit 1
        fi
        echo "⏳ Attempt $i/30 - waiting for llama.cpp..."
        sleep 1
    done
    
    # Test the OpenAI API endpoint
    echo "🔍 Testing llama.cpp OpenAI API compatibility..."
    echo "💡 Testing health endpoint first..."
    
    # First test the health endpoint
    HEALTH_RESPONSE=$(curl -s http://localhost:11434/health 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$HEALTH_RESPONSE" ]; then
        echo "✅ Health endpoint responded: $HEALTH_RESPONSE"
    else
        echo "❌ Health endpoint failed - container may not be ready"
        echo "🔍 Checking container logs..."
        docker logs --tail 10 $CONTAINER_NAME
        echo ""
        echo "🔍 Container status:"
        docker ps -a --filter "name=$CONTAINER_NAME"
        exit 1
    fi
    
    # Then test the models endpoint
    if curl -s http://localhost:11434/v1/models | jq . >/dev/null 2>&1; then
        echo "✅ OpenAI API endpoint is working!"
    else
        echo "❌ OpenAI API endpoint test failed"
        echo "🔍 Raw response:"
        curl -s http://localhost:11434/v1/models
        echo ""
        exit 1
    fi
    
    # Check if OpenWebUI container is already running
    if docker ps -q --filter "name=$OPENWEBUI_CONTAINER_NAME" | grep -q .; then
        echo "⚠️  OpenWebUI container is already running"
    else
        # Remove existing OpenWebUI container if it exists
        if docker ps -aq --filter "name=$OPENWEBUI_CONTAINER_NAME" | grep -q .; then
            echo "🗑️  Removing existing OpenWebUI container..."
            docker rm $OPENWEBUI_CONTAINER_NAME
        fi

        # Remove existing volume to ensure fresh start
        echo "🧹 Cleaning OpenWebUI persistent volume..."
        docker volume rm openwebui-test-data >/dev/null 2>&1 || true

        echo "🔄 Starting OpenWebUI container: $OPENWEBUI_CONTAINER_NAME"
        docker run -d \
            --name $OPENWEBUI_CONTAINER_NAME \
            -p 8080:8080 \
            -v openwebui-test-data:/app/backend/data \
            -e WEBUI_AUTH=false \
            -e ENABLE_SIGNUP=false \
            -e ENABLE_LOGIN_FORM=false \
            -e ENABLE_PERSISTENT_CONFIG=false \
            -e RESET_CONFIG_ON_START=true \
            -e ENABLE_OLLAMA_API=false \
            -e ENABLE_OPENAI_API=true \
            -e OPENAI_API_BASE_URL="http://172.17.0.1:11434/v1" \
            -e OPENAI_API_KEY="dummy-key" \
            -e DEFAULT_MODELS="devstral-2507:latest" \
            -e WEBUI_NAME="llama.cpp + OpenWebUI" \
            -e WEBUI_URL="http://localhost:8080" \
            -e CORS_ALLOW_ORIGIN="*" \
            -e ENABLE_MODEL_FILTER=false \
            -e ENABLE_ADMIN_EXPORT=false \
            -e ENABLE_COMMUNITY_SHARING=false \
            -e ENABLE_MESSAGE_RATING=false \
            -e LOG_LEVEL=INFO \
            ghcr.io/open-webui/open-webui:main
    fi
    
    # Wait for OpenWebUI to be ready
    echo "⏳ Waiting for OpenWebUI to be ready..."
    for i in {1..90}; do
        if curl -s http://localhost:8080 >/dev/null 2>&1; then
            echo "✅ OpenWebUI is ready!"
            break
        fi
        if [ $i -eq 90 ]; then
            echo "❌ OpenWebUI failed to start within 90 seconds"
            echo "🔍 Checking OpenWebUI logs for debugging..."
            docker logs --tail 20 $OPENWEBUI_CONTAINER_NAME
            echo ""
            echo "🔍 Checking OpenWebUI status..."
            docker ps -a --filter "name=$OPENWEBUI_CONTAINER_NAME"
            exit 1
        fi
        echo "⏳ Attempt $i/90 - waiting for OpenWebUI..."
        sleep 1
    done
    
    echo "🎉 Both containers are running!"
    echo "  • llama.cpp API: http://localhost:11434"
    echo "  • OpenWebUI: http://localhost:8080"
    echo ""
    echo "🧪 You can now run: ./test-containers.sh test"
}

# Function to stop container
stop_container() {
    echo "🛑 Stopping llama.cpp + OpenWebUI Containers"
    echo "============================================"
    
    CONTAINER_NAME="llama-cpp-test"
    OPENWEBUI_CONTAINER_NAME="openwebui-test"
    
    # Stop and remove llama.cpp container
    if docker ps -q --filter "name=$CONTAINER_NAME" | grep -q .; then
        echo "🔄 Stopping llama.cpp container: $CONTAINER_NAME"
        docker stop $CONTAINER_NAME
    else
        echo "ℹ️  llama.cpp container $CONTAINER_NAME is not running"
    fi

    if docker ps -aq --filter "name=$CONTAINER_NAME" | grep -q .; then
        echo "🗑️  Removing llama.cpp container: $CONTAINER_NAME"
        docker rm $CONTAINER_NAME
    else
        echo "ℹ️  llama.cpp container $CONTAINER_NAME does not exist"
    fi

    # Stop and remove OpenWebUI container
    if docker ps -q --filter "name=$OPENWEBUI_CONTAINER_NAME" | grep -q .; then
        echo "🔄 Stopping OpenWebUI container: $OPENWEBUI_CONTAINER_NAME"
        docker stop $OPENWEBUI_CONTAINER_NAME
    else
        echo "ℹ️  OpenWebUI container $OPENWEBUI_CONTAINER_NAME is not running"
    fi

    if docker ps -aq --filter "name=$OPENWEBUI_CONTAINER_NAME" | grep -q .; then
        echo "🗑️  Removing OpenWebUI container: $OPENWEBUI_CONTAINER_NAME"
        docker rm $OPENWEBUI_CONTAINER_NAME
    else
        echo "ℹ️  OpenWebUI container $OPENWEBUI_CONTAINER_NAME does not exist"
    fi

    # Remove OpenWebUI persistent volume to ensure fresh configuration
    echo "🧹 Cleaning OpenWebUI persistent volume..."
    docker volume rm openwebui-test-data >/dev/null 2>&1 || true
    
    echo "✅ Containers stopped and removed!"
}

# Function to show container logs
show_logs() {
    CONTAINER_NAME="llama-cpp-test"
    OPENWEBUI_CONTAINER_NAME="openwebui-test"
    
    echo "📋 Container Logs"
    echo "================="
    
    # Show llama.cpp logs
    if docker ps -q --filter "name=$CONTAINER_NAME" | grep -q .; then
        echo "🔍 llama.cpp Container Logs (Running):"
        echo "-----------------------------"
        docker logs --tail 50 $CONTAINER_NAME
        echo ""
    elif docker ps -aq --filter "name=$CONTAINER_NAME" | grep -q .; then
        echo "🔍 llama.cpp Container Logs (Stopped):"
        echo "-----------------------------"
        docker logs --tail 50 $CONTAINER_NAME
        echo ""
    else
        echo "❌ llama.cpp container does not exist"
    fi
    
    # Show OpenWebUI logs
    if docker ps -q --filter "name=$OPENWEBUI_CONTAINER_NAME" | grep -q .; then
        echo "🔍 OpenWebUI Container Logs (Running):"
        echo "-----------------------------"
        docker logs --tail 50 $OPENWEBUI_CONTAINER_NAME
        echo ""
    elif docker ps -aq --filter "name=$OPENWEBUI_CONTAINER_NAME" | grep -q .; then
        echo "🔍 OpenWebUI Container Logs (Stopped):"
        echo "-----------------------------"
        docker logs --tail 50 $OPENWEBUI_CONTAINER_NAME
        echo ""
    else
        echo "❌ OpenWebUI container does not exist"
    fi
}

# Function to show container status
show_status() {
    CONTAINER_NAME="llama-cpp-test"
    OPENWEBUI_CONTAINER_NAME="openwebui-test"
    
    echo "📊 Container Status"
    echo "==================="
    
    # Check llama.cpp container
    if docker ps -q --filter "name=$CONTAINER_NAME" | grep -q .; then
        echo "✅ llama.cpp container is running"
        docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        echo "❌ llama.cpp container is not running"
        if docker ps -aq --filter "name=$CONTAINER_NAME" | grep -q .; then
            echo "ℹ️  llama.cpp container exists but is stopped"
        else
            echo "ℹ️  llama.cpp container does not exist"
        fi
    fi

    echo ""
    
    # Check OpenWebUI container
    if docker ps -q --filter "name=$OPENWEBUI_CONTAINER_NAME" | grep -q .; then
        echo "✅ OpenWebUI container is running"
        docker ps --filter "name=$OPENWEBUI_CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        echo "❌ OpenWebUI container is not running"
        if docker ps -aq --filter "name=$OPENWEBUI_CONTAINER_NAME" | grep -q .; then
            echo "ℹ️  OpenWebUI container exists but is stopped"
        else
            echo "ℹ️  OpenWebUI container does not exist"
        fi
    fi

    echo ""
    echo "🌐 Interfaces:"
    echo "  • llama.cpp API: http://localhost:11434"
    echo "  • OpenWebUI Interface: http://localhost:8080"
    echo "  • Health Check: http://localhost:11434/health"
    echo "  • Models API: http://localhost:11434/v1/models"
    echo ""
    echo "🌐 Endpoints:"
    echo "  • Chat: http://localhost:11434/v1/chat/completions"
    echo "  • Generate: http://localhost:11434/v1/completions"
    echo "  • OpenHands Generate (v1): http://localhost:11434/v1/api/generate"
    echo "  • OpenHands Generate: http://localhost:11434/api/generate"
    echo ""
    echo "📊 Quick Test Commands:"
    echo "  curl http://localhost:11434/health"
    echo "  curl http://localhost:11434/v1/models | jq ."
    echo "  # Open OpenWebUI in browser:"
    echo "  open http://localhost:8080"
    echo "  # Chat endpoint test:"
    echo "  curl -X POST http://localhost:11434/v1/chat/completions -H 'Content-Type: application/json' -d '{\"model\":\"devstral-2507:latest\",\"messages\":[{\"role\":\"user\",\"content\":\"Hello!\"}],\"stream\":false}'"
    echo "  # Generate endpoint test:"
    echo "  curl -X POST http://localhost:11434/v1/completions -H 'Content-Type: application/json' -d '{\"model\":\"devstral-2507:latest\",\"prompt\":\"Hello, my name is\",\"max_tokens\":50,\"stream\":false}'"
}

# Function to run API tests
run_api_tests() {
    echo "🧪 Running API Tests"
    echo "==================="
    
    BASE_URL="http://localhost:11434"
    MODEL="devstral-2507:latest"
    
    # Test 1: Health check
    echo "🔍 Test 1: Health Check"
    echo "========================"
    if curl -s "$BASE_URL/health" | jq . 2>/dev/null; then
        echo "✅ Health check passed"
    else
        echo "❌ Health check failed"
        return 1
    fi
    echo ""
    
    # Test 2: Models endpoint
    echo "🔍 Test 2: Models Endpoint"
    echo "=========================="
    if curl -s "$BASE_URL/v1/models" | jq . 2>/dev/null; then
        echo "✅ Models endpoint passed"
    else
        echo "❌ Models endpoint failed"
        return 1
    fi
    echo ""
    
    # Test 3: Chat completion (non-streaming)
    echo "🔍 Test 3: Chat Completion (Non-Streaming)"
    echo "==========================================="
    CHAT_RESPONSE=$(curl -s -X POST "$BASE_URL/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$MODEL\",
            \"messages\": [
                {\"role\": \"user\", \"content\": \"Hello! What is 2+2?\"}
            ],
            \"stream\": false,
            \"max_tokens\": 50
        }")
    
    if echo "$CHAT_RESPONSE" | jq . 2>/dev/null; then
        echo "✅ Chat completion (non-streaming) passed"
    else
        echo "❌ Chat completion (non-streaming) failed"
        echo "Response: $CHAT_RESPONSE"
    fi
    echo ""
    
    # Test 4: Generate completion (non-streaming)
    echo "🔍 Test 4: Generate Completion (Non-Streaming)"
    echo "==============================================="
    GENERATE_RESPONSE=$(curl -s -X POST "$BASE_URL/v1/completions" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$MODEL\",
            \"prompt\": \"The capital of France is\",
            \"max_tokens\": 10,
            \"stream\": false
        }")
    
    if echo "$GENERATE_RESPONSE" | jq . 2>/dev/null; then
        echo "✅ Generate completion (non-streaming) passed"
    else
        echo "❌ Generate completion (non-streaming) failed"
        echo "Response: $GENERATE_RESPONSE"
    fi
    echo ""
    
    # Test 5: Chat completion (streaming)
    echo "🔍 Test 5: Chat Completion (Streaming)"
    echo "======================================"
    STREAM_OUTPUT=$(curl -s -X POST "$BASE_URL/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$MODEL\",
            \"messages\": [
                {\"role\": \"user\", \"content\": \"Count to 5\"}
            ],
            \"stream\": true,
            \"max_tokens\": 50
        }")
    
    if echo "$STREAM_OUTPUT" | grep -q "data:"; then
        echo "✅ Chat completion (streaming) passed"
        echo "Sample streaming response:"
        echo "$STREAM_OUTPUT" | head -3
    else
        echo "❌ Chat completion (streaming) failed"
        echo "Response: $STREAM_OUTPUT"
    fi
    echo ""
    
    # Test 6: Generate completion (streaming)
    echo "🔍 Test 6: Generate Completion (Streaming)"
    echo "=========================================="
    STREAM_OUTPUT=$(curl -s -X POST "$BASE_URL/v1/completions" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$MODEL\",
            \"prompt\": \"List 3 colors:\",
            \"max_tokens\": 30,
            \"stream\": true
        }")
    
    if echo "$STREAM_OUTPUT" | grep -q "data:"; then
        echo "✅ Generate completion (streaming) passed"
        echo "Sample streaming response:"
        echo "$STREAM_OUTPUT" | head -3
    else
        echo "❌ Generate completion (streaming) failed"
        echo "Response: $STREAM_OUTPUT"
    fi
    echo ""
    
    # Test 7: Multi-turn conversation (non-streaming)
    echo "🔍 Test 7: Multi-turn Conversation (Non-Streaming)"
    echo "==================================================="
    MULTI_TURN_RESPONSE=$(curl -s -X POST "$BASE_URL/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$MODEL\",
            \"messages\": [
                {\"role\": \"user\", \"content\": \"My name is Alice\"},
                {\"role\": \"assistant\", \"content\": \"Hello Alice! Nice to meet you.\"},
                {\"role\": \"user\", \"content\": \"What is my name?\"}
            ],
            \"stream\": false,
            \"max_tokens\": 20
        }")
    
    if echo "$MULTI_TURN_RESPONSE" | jq . 2>/dev/null; then
        echo "✅ Multi-turn conversation (non-streaming) passed"
    else
        echo "❌ Multi-turn conversation (non-streaming) failed"
        echo "Response: $MULTI_TURN_RESPONSE"
    fi
    echo ""
    
    # Test 8: Multi-turn conversation (streaming)
    echo "🔍 Test 8: Multi-turn Conversation (Streaming)"
    echo "==============================================="
    MULTI_TURN_STREAM=$(curl -s -X POST "$BASE_URL/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$MODEL\",
            \"messages\": [
                {\"role\": \"user\", \"content\": \"I like pizza\"},
                {\"role\": \"assistant\", \"content\": \"Pizza is delicious! What toppings do you prefer?\"},
                {\"role\": \"user\", \"content\": \"What food did I mention?\"}
            ],
            \"stream\": true,
            \"max_tokens\": 20
        }")
    
    if echo "$MULTI_TURN_STREAM" | grep -q "data:"; then
        echo "✅ Multi-turn conversation (streaming) passed"
        echo "Sample streaming response:"
        echo "$MULTI_TURN_STREAM" | head -3
    else
        echo "❌ Multi-turn conversation (streaming) failed"
        echo "Response: $MULTI_TURN_STREAM"
    fi
    echo ""
    
    # Test 9: System prompt (non-streaming)
    echo "🔍 Test 9: System Prompt (Non-Streaming)"
    echo "========================================"
    SYSTEM_PROMPT_RESPONSE=$(curl -s -X POST "$BASE_URL/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$MODEL\",
            \"messages\": [
                {\"role\": \"system\", \"content\": \"You are a helpful assistant that always responds in exactly 3 words.\"},
                {\"role\": \"user\", \"content\": \"What is the weather like?\"}
            ],
            \"stream\": false,
            \"max_tokens\": 10
        }")
    
    if echo "$SYSTEM_PROMPT_RESPONSE" | jq . 2>/dev/null; then
        echo "✅ System prompt (non-streaming) passed"
    else
        echo "❌ System prompt (non-streaming) failed"
        echo "Response: $SYSTEM_PROMPT_RESPONSE"
    fi
    echo ""
    
    # Test 10: System prompt (streaming)
    echo "🔍 Test 10: System Prompt (Streaming)"
    echo "===================================="
    SYSTEM_PROMPT_STREAM=$(curl -s -X POST "$BASE_URL/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$MODEL\",
            \"messages\": [
                {\"role\": \"system\", \"content\": \"You are a poet who speaks only in rhyme.\"},
                {\"role\": \"user\", \"content\": \"Tell me about the moon\"}
            ],
            \"stream\": true,
            \"max_tokens\": 30
        }")
    
    if echo "$SYSTEM_PROMPT_STREAM" | grep -q "data:"; then
        echo "✅ System prompt (streaming) passed"
        echo "Sample streaming response:"
        echo "$SYSTEM_PROMPT_STREAM" | head -3
    else
        echo "❌ System prompt (streaming) failed"
        echo "Response: $SYSTEM_PROMPT_STREAM"
    fi
    echo ""
    
    # Test 11: Long context (non-streaming)
    echo "🔍 Test 11: Long Context (Non-Streaming)"
    echo "========================================"
    LONG_CONTEXT_RESPONSE=$(curl -s -X POST "$BASE_URL/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$MODEL\",
            \"messages\": [
                {\"role\": \"user\", \"content\": \"I am going to tell you a story. Once upon a time, there was a young wizard named Alex who lived in a tall tower. Alex had three magical pets: a dragon named Fire, a phoenix named Flame, and a unicorn named Sparkle. Every morning, Alex would practice spells in the garden. The dragon would breathe fire, the phoenix would sing beautiful songs, and the unicorn would make flowers bloom. What were the names of Alex's three pets?\"}
            ],
            \"stream\": false,
            \"max_tokens\": 30
        }")
    
    if echo "$LONG_CONTEXT_RESPONSE" | jq . 2>/dev/null; then
        echo "✅ Long context (non-streaming) passed"
    else
        echo "❌ Long context (non-streaming) failed"
        echo "Response: $LONG_CONTEXT_RESPONSE"
    fi
    echo ""
    
    # Test 12: Long context (streaming)
    echo "🔍 Test 12: Long Context (Streaming)"
    echo "==================================="
    LONG_CONTEXT_STREAM=$(curl -s -X POST "$BASE_URL/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$MODEL\",
            \"messages\": [
                {\"role\": \"user\", \"content\": \"Here is a list of items: apple, banana, cherry, date, elderberry, fig, grape, honeydew, kiwi, lemon, mango, nectarine, orange, papaya, quince, raspberry, strawberry, tangerine, ugli fruit, vanilla bean, watermelon, xigua, yellow passion fruit, zucchini. Please tell me what the 5th item in this list is.\"}
            ],
            \"stream\": true,
            \"max_tokens\": 20
        }")
    
    if echo "$LONG_CONTEXT_STREAM" | grep -q "data:"; then
        echo "✅ Long context (streaming) passed"
        echo "Sample streaming response:"
        echo "$LONG_CONTEXT_STREAM" | head -3
    else
        echo "❌ Long context (streaming) failed"
        echo "Response: $LONG_CONTEXT_STREAM"
    fi
    echo ""
    
    # Test 13: OpenHands Generate Endpoint (Reference - may not work)
    echo "🔍 Test 13: OpenHands Generate Endpoint (Reference)"
    echo "================================================="
    echo "⚠️  Note: These endpoints may not exist in llama.cpp"
    echo "    They are included as reference for OpenHands compatibility"
    echo ""
    
    # Test OpenHands v1 generate endpoint
    echo "🔍 Test 13a: OpenHands v1 Generate Endpoint"
    OPENHANDS_V1_RESPONSE=$(curl -s -X POST "$BASE_URL/v1/api/generate" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$MODEL\",
            \"prompt\": \"Hello, my name is\",
            \"stream\": false
        }" 2>/dev/null)
    
    if echo "$OPENHANDS_V1_RESPONSE" | jq . 2>/dev/null; then
        echo "✅ OpenHands v1 generate endpoint passed"
    else
        echo "❌ OpenHands v1 generate endpoint failed (expected)"
        echo "Response: $OPENHANDS_V1_RESPONSE"
    fi
    echo ""
    
    # Test OpenHands generate endpoint
    echo "🔍 Test 13b: OpenHands Generate Endpoint"
    OPENHANDS_RESPONSE=$(curl -s -X POST "$BASE_URL/api/generate" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$MODEL\",
            \"prompt\": \"Hello, my name is\",
            \"stream\": false
        }" 2>/dev/null)
    
    if echo "$OPENHANDS_RESPONSE" | jq . 2>/dev/null; then
        echo "✅ OpenHands generate endpoint passed"
    else
        echo "❌ OpenHands generate endpoint failed (expected)"
        echo "Response: $OPENHANDS_RESPONSE"
    fi
    echo ""
    
    echo "🎯 Test Summary"
    echo "==============="
    echo "✅ Completed comprehensive API testing"
    echo "📝 Both streaming and non-streaming tests included"
    echo "🔄 Multi-turn conversations tested"
    echo "🎭 System prompts tested"
    echo "📚 Long context handling tested"
    echo "🔗 OpenHands compatibility endpoints tested (reference)"
    echo ""
    echo "🌐 Ready to use with OpenWebUI at: http://localhost:8080"
}

# Function to test basic container functionality
test_basic_container() {
    echo "🧪 Testing Basic Container Functionality"
    echo "======================================="
    
    CONTAINER_NAME="llama-cpp-basic-test"
    
    echo "🔄 Starting minimal test container..."
    docker run --rm -d \
        --name $CONTAINER_NAME \
        --gpus all \
        -p 11435:11434 \
        -v ~/.models:/models \
        llama-cpp-devstral \
        --model /models/devstral-q4_k_m.gguf \
        --port 11434 \
        --host 0.0.0.0
    
    echo "⏳ Waiting 10 seconds for basic container to start..."
    sleep 10
    
    echo "🔍 Checking basic container status..."
    if docker ps -q --filter "name=$CONTAINER_NAME" | grep -q .; then
        echo "✅ Basic container is running"
        echo "📋 Container logs:"
        docker logs --tail 20 $CONTAINER_NAME
        echo ""
        echo "🔍 Testing basic health endpoint..."
        if curl -s http://localhost:11435/health >/dev/null 2>&1; then
            echo "✅ Basic health endpoint works!"
        else
            echo "❌ Basic health endpoint failed"
        fi
    else
        echo "❌ Basic container failed to start"
        echo "📋 Container logs:"
        docker logs $CONTAINER_NAME
    fi
    
    echo "🧹 Cleaning up basic test container..."
    docker stop $CONTAINER_NAME >/dev/null 2>&1 || true
    docker rm $CONTAINER_NAME >/dev/null 2>&1 || true
}

# Main script logic
case "${1:-}" in
    "up"|"start")
        start_containers
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
        run_api_tests
        ;;
    "basic-test")
        test_basic_container
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
