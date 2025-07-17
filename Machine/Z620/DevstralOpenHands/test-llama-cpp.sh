#!/bin/bash

# llama.cpp Container Test Script
# Direct container testing with fixed parameters for easy modification

set -e

# Function to show usage
show_usage() {
    echo "🦙 llama.cpp Container Test Script"
    echo "=================================="
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  up      Start llama.cpp container"
    echo "  down    Stop and remove container"
    echo "  logs    Show container logs"
    echo "  status  Show container status"
    echo "  test    Run API endpoint tests"
    echo "  help    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 up       # Start container"
    echo "  $0 down     # Stop container"
    echo "  $0 logs     # View logs"
    echo "  $0 status   # Check status"
    echo "  $0 test     # Test API endpoints with performance metrics"
    echo ""
    echo "Configuration (Fixed Parameters):"
    echo "  • Container Name: llama-cpp-test"
    echo "  • Port: 11434"
    echo "  • Model: devstral-q4_k_m.gguf"
    echo "  • Model Path: ~/.models:/models"
    echo "  • GPU Layers: 41"
    echo "  • Context Size: 88832"
    echo "  • Threads: 12"
    echo "  • Batch Size: 1024"
    echo "  • Micro-batch Size: 512"
    echo "  • Flash Attention: Enabled"
    echo "  • Continuous Batching: Enabled"
    echo "  • Parallel Slots: 1"
    echo ""
    echo "API Endpoints:"
    echo "  • Health: http://localhost:11434/health"
    echo "  • Models: http://localhost:11434/v1/models"
    echo "  • Chat: http://localhost:11434/v1/chat/completions"
    echo "  • Completions: http://localhost:11434/v1/completions"
    echo ""
    echo "Performance Features:"
    echo "  • Tokens per second (TPS) calculation for all tests"
    echo "  • Token usage statistics (prompt + completion + total)"
    echo "  • Performance benchmark test with detailed metrics"
    echo "  • Response time measurement for all API calls"
    echo ""
    exit 0
}

# Function to start llama.cpp container
start_container() {
    echo "🚀 Starting llama.cpp Container"
    echo "==============================="
    
    CONTAINER_NAME="llama-cpp-test"
    
    # Build the container if it doesn't exist
    if ! docker images | grep -q "llama-cpp-devstral"; then
        echo "🔨 Building llama.cpp container..."
        docker build -t llama-cpp-devstral .
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

    echo "🔄 Starting llama.cpp container with fixed parameters..."
    echo "📝 Container Configuration:"
    echo "  • Model: /models/devstral-q4_k_m.gguf"
    echo "  • Host: 0.0.0.0"
    echo "  • Port: 11434"
    echo "  • GPU Layers: 41"
    echo "  • Context Size: 88832"
    echo "  • Threads: 12"
    echo "  • Batch Size: 1024"
    echo "  • Micro-batch Size: 512"
    echo "  • Flash Attention: Enabled"
    echo "  • Continuous Batching: Enabled"
    echo "  • Parallel Slots: 1"
    echo ""
    
    # Start container with fixed parameters (based on .env file)
    CONTAINER_ID=$(docker run -d \
        --name llama-cpp-test \
        --gpus all \
        -p 11434:11434 \
        -v ~/.models:/models \
        -e LLAMA_ARG_HOST=0.0.0.0 \
        -e LLAMA_ARG_PORT=11434 \
        -e LLAMA_ARG_MODEL=/models/devstral-q4_k_m.gguf \
        -e LLAMA_ARG_CTX_SIZE=88832 \
        -e LLAMA_ARG_N_GPU_LAYERS=41 \
        -e LLAMA_ARG_THREADS=12 \
        -e LLAMA_ARG_BATCH_SIZE=1024 \
        -e LLAMA_ARG_UBATCH_SIZE=512 \
        -e LLAMA_ARG_FLASH_ATTN=1 \
        -e LLAMA_ARG_CONT_BATCHING=1 \
        -e LLAMA_ARG_PARALLEL=1 \
        -e NVIDIA_VISIBLE_DEVICES=all \
        -e NVIDIA_DRIVER_CAPABILITIES=compute,utility \
        -e MODEL_ALIAS=devstral-2507 \
        llama-cpp-devstral)
    
    echo "✅ Container started with ID: $CONTAINER_ID"
    echo "⏳ Waiting 5 seconds for container to initialize..."
    sleep 5
    
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
    
    # Wait for health endpoint to be ready
    echo "⏳ Waiting for llama.cpp server to be ready..."
    for i in {1..30}; do
        if curl -s http://localhost:11434/health >/dev/null 2>&1; then
            echo "✅ llama.cpp server is ready!"
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
            echo "❌ Server failed to start within 30 seconds"
            echo "🔍 Container logs:"
            docker logs --tail 20 $CONTAINER_NAME
            echo ""
            echo "🔍 Container status:"
            docker ps -a --filter "name=$CONTAINER_NAME"
            exit 1
        fi
        
        echo "⏳ Attempt $i/30 - waiting for server..."
        sleep 1
    done
    
    # Test basic endpoints
    echo "🔍 Testing basic API endpoints..."
    
    # Test health endpoint
    HEALTH_RESPONSE=$(curl -s http://localhost:11434/health 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$HEALTH_RESPONSE" ]; then
        echo "✅ Health endpoint: $HEALTH_RESPONSE"
    else
        echo "❌ Health endpoint failed"
        exit 1
    fi
    
    # Test models endpoint
    if curl -s http://localhost:11434/v1/models | jq . >/dev/null 2>&1; then
        echo "✅ Models endpoint working"
    else
        echo "❌ Models endpoint failed"
        echo "🔍 Raw response:"
        curl -s http://localhost:11434/v1/models
        echo ""
        exit 1
    fi
    
    echo ""
    echo "🎉 llama.cpp container is running successfully!"
    echo "  • Container: llama-cpp-test"
    echo "  • Health: http://localhost:11434/health"
    echo "  • Models: http://localhost:11434/v1/models"
    echo "  • API Base: http://localhost:11434/v1"
    echo ""
    echo "🧪 Run './test-llama-cpp.sh test' to test API endpoints"
}

# Function to stop container
stop_container() {
    echo "🛑 Stopping llama.cpp Container"
    echo "==============================="
    
    CONTAINER_NAME="llama-cpp-test"
    
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
}

# Function to show container logs
show_logs() {
    CONTAINER_NAME="llama-cpp-test"
    
    echo "📋 llama.cpp Container Logs"
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
        echo "💡 Run './test-llama-cpp.sh up' to start the container"
    fi
}

# Function to show container status
show_status() {
    CONTAINER_NAME="llama-cpp-test"
    
    echo "📊 llama.cpp Container Status"
    echo "=============================="
    
    # Check container status
    if docker ps -q --filter "name=$CONTAINER_NAME" | grep -q .; then
        echo "✅ Container is running"
        docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        echo ""
        
        # Test endpoints
        echo "🔍 API Endpoint Status:"
        echo "----------------------"
        
        # Health check
        if curl -s http://localhost:11434/health >/dev/null 2>&1; then
            HEALTH_STATUS=$(curl -s http://localhost:11434/health)
            echo "✅ Health: $HEALTH_STATUS"
        else
            echo "❌ Health: Not responding"
        fi
        
        # Models endpoint
        if curl -s http://localhost:11434/v1/models >/dev/null 2>&1; then
            echo "✅ Models: Available"
        else
            echo "❌ Models: Not responding"
        fi
        
    elif docker ps -aq --filter "name=$CONTAINER_NAME" | grep -q .; then
        echo "❌ Container exists but is stopped"
        docker ps -a --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        echo "❌ Container does not exist"
    fi
    
    echo ""
    echo "🌐 API Endpoints:"
    echo "  • Health: http://localhost:11434/health"
    echo "  • Models: http://localhost:11434/v1/models"
    echo "  • Chat: http://localhost:11434/v1/chat/completions"
    echo "  • Completions: http://localhost:11434/v1/completions"
    echo ""
    echo "📊 Quick Test Commands:"
    echo "  curl http://localhost:11434/health"
    echo "  curl http://localhost:11434/v1/models | jq ."
    echo "  ./test-llama-cpp.sh test"
}

# Function to calculate tokens per second from response
calculate_tps() {
    local response="$1"
    
    # Extract token counts from response
    local completion_tokens=$(echo "$response" | jq -r '.usage.completion_tokens // 0' 2>/dev/null)
    local prompt_tokens=$(echo "$response" | jq -r '.usage.prompt_tokens // 0' 2>/dev/null)
    local total_tokens=$(echo "$response" | jq -r '.usage.total_tokens // 0' 2>/dev/null)
    
    # Check if llama.cpp includes timing information in the response
    local prompt_eval_duration=$(echo "$response" | jq -r '.usage.prompt_eval_duration // null' 2>/dev/null)
    local eval_duration=$(echo "$response" | jq -r '.usage.eval_duration // null' 2>/dev/null)
    local total_duration=$(echo "$response" | jq -r '.usage.total_duration // null' 2>/dev/null)
    
    # llama.cpp might also include these fields
    local timings_predicted_ms=$(echo "$response" | jq -r '.timings.predicted_ms // null' 2>/dev/null)
    local timings_predicted_n=$(echo "$response" | jq -r '.timings.predicted_n // null' 2>/dev/null)
    local timings_prompt_ms=$(echo "$response" | jq -r '.timings.prompt_ms // null' 2>/dev/null)
    local timings_prompt_n=$(echo "$response" | jq -r '.timings.prompt_n // null' 2>/dev/null)
    
    echo "📊 Token usage: ${prompt_tokens} prompt + ${completion_tokens} completion = ${total_tokens} total"
    
    # Try to calculate TPS using response timing data first
    if [ "$timings_predicted_ms" != "null" ] && [ "$timings_predicted_n" != "null" ] && [ "$timings_predicted_ms" != "0" ]; then
        # llama.cpp native timing format
        local tps=$(echo "scale=2; $timings_predicted_n * 1000 / $timings_predicted_ms" | bc -l 2>/dev/null)
        echo "⚡ Performance: ${timings_predicted_n} tokens in ${timings_predicted_ms}ms = ${tps} tokens/sec"
        if [ "$timings_prompt_ms" != "null" ] && [ "$timings_prompt_n" != "null" ]; then
            local prompt_tps=$(echo "scale=2; $timings_prompt_n * 1000 / $timings_prompt_ms" | bc -l 2>/dev/null)
            echo "⚡ Prompt eval: ${timings_prompt_n} tokens in ${timings_prompt_ms}ms = ${prompt_tps} tokens/sec"
        fi
    elif [ "$eval_duration" != "null" ] && [ "$completion_tokens" != "0" ] && [ "$eval_duration" != "0" ]; then
        # Duration in nanoseconds, convert to seconds
        local duration_sec=$(echo "scale=6; $eval_duration / 1000000000" | bc -l 2>/dev/null)
        local tps=$(echo "scale=2; $completion_tokens / $duration_sec" | bc -l 2>/dev/null)
        echo "⚡ Performance: ${completion_tokens} tokens in ${duration_sec}s = ${tps} tokens/sec"
    else
        echo "⚡ Performance: No timing data available in response"
        echo "🔍 Available timing fields:"
        echo "$response" | jq -r '.usage, .timings' 2>/dev/null | head -10
    fi
}

# Function to run API tests
run_api_tests() {
    echo "🧪 Running llama.cpp API Tests"
    echo "=============================="
    
    # Check if container is running
    if ! docker ps -q --filter "name=llama-cpp-test" | grep -q .; then
        echo "❌ Container is not running"
        echo "💡 Run './test-llama-cpp.sh up' first"
        exit 1
    fi
    
    BASE_URL="http://localhost:11434"
    MODEL="devstral-2507"
    
    echo "🔍 Testing OpenAI-compatible API endpoints with performance metrics..."
    echo ""
    
    # Test 1: Health check
    echo "🔍 Test 1: Health Check"
    echo "========================"
    HEALTH_RESPONSE=$(curl -s "$BASE_URL/health" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$HEALTH_RESPONSE" ]; then
        echo "✅ Health check passed: $HEALTH_RESPONSE"
    else
        echo "❌ Health check failed"
        return 1
    fi
    echo ""
    
    # Test 2: Models endpoint
    echo "🔍 Test 2: Models Endpoint"
    echo "=========================="
    if curl -s "$BASE_URL/v1/models" | jq . >/dev/null 2>&1; then
        echo "✅ Models endpoint passed"
        echo "📋 Available models:"
        curl -s "$BASE_URL/v1/models" | jq -r '.data[].id'
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
        }" 2>/dev/null)
    
    if echo "$CHAT_RESPONSE" | jq . >/dev/null 2>&1; then
        echo "✅ Chat completion (non-streaming) passed"
        echo "💬 Response: $(echo "$CHAT_RESPONSE" | jq -r '.choices[0].message.content')"
        calculate_tps "$CHAT_RESPONSE"
    else
        echo "❌ Chat completion (non-streaming) failed"
        echo "📋 Response: $CHAT_RESPONSE"
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
        }" 2>/dev/null)
    
    if echo "$GENERATE_RESPONSE" | jq . >/dev/null 2>&1; then
        echo "✅ Generate completion (non-streaming) passed"
        echo "💬 Response: $(echo "$GENERATE_RESPONSE" | jq -r '.choices[0].text')"
        calculate_tps "$GENERATE_RESPONSE"
    else
        echo "❌ Generate completion (non-streaming) failed"
        echo "📋 Response: $GENERATE_RESPONSE"
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
                {\"role\": \"user\", \"content\": \"Count to 3\"}
            ],
            \"stream\": true,
            \"max_tokens\": 30
        }" 2>/dev/null)
    
    if echo "$STREAM_OUTPUT" | grep -q "data:"; then
        echo "✅ Chat completion (streaming) passed"
        echo "📋 Sample streaming chunks:"
        echo "$STREAM_OUTPUT" | head -3
    else
        echo "❌ Chat completion (streaming) failed"
        echo "📋 Response: $STREAM_OUTPUT"
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
            \"max_tokens\": 20,
            \"stream\": true
        }" 2>/dev/null)
    
    if echo "$STREAM_OUTPUT" | grep -q "data:"; then
        echo "✅ Generate completion (streaming) passed"
        echo "📋 Sample streaming chunks:"
        echo "$STREAM_OUTPUT" | head -3
    else
        echo "❌ Generate completion (streaming) failed"
        echo "📋 Response: $STREAM_OUTPUT"
    fi
    echo ""
    
    # Test 7: System prompt
    echo "🔍 Test 7: System Prompt"
    echo "========================"
    
    SYSTEM_RESPONSE=$(curl -s -X POST "$BASE_URL/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$MODEL\",
            \"messages\": [
                {\"role\": \"system\", \"content\": \"You are a helpful assistant that responds in exactly 5 words.\"},
                {\"role\": \"user\", \"content\": \"What is your name?\"}
            ],
            \"stream\": false,
            \"max_tokens\": 20
        }" 2>/dev/null)
    
    if echo "$SYSTEM_RESPONSE" | jq . >/dev/null 2>&1; then
        echo "✅ System prompt passed"
        echo "💬 Response: $(echo "$SYSTEM_RESPONSE" | jq -r '.choices[0].message.content')"
        calculate_tps "$SYSTEM_RESPONSE"
    else
        echo "❌ System prompt failed"
        echo "📋 Response: $SYSTEM_RESPONSE"
    fi
    echo ""
    
    # Test 8: Multi-turn conversation
    echo "🔍 Test 8: Multi-turn Conversation"
    echo "=================================="
    
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
        }" 2>/dev/null)
    
    if echo "$MULTI_TURN_RESPONSE" | jq . >/dev/null 2>&1; then
        echo "✅ Multi-turn conversation passed"
        echo "💬 Response: $(echo "$MULTI_TURN_RESPONSE" | jq -r '.choices[0].message.content')"
        calculate_tps "$MULTI_TURN_RESPONSE"
    else
        echo "❌ Multi-turn conversation failed"
        echo "📋 Response: $MULTI_TURN_RESPONSE"
    fi
    echo ""
    
    # Test 9: Performance Benchmark (Higher token count)
    echo "🔍 Test 9: Performance Benchmark"
    echo "================================"
    
    BENCHMARK_RESPONSE=$(curl -s -X POST "$BASE_URL/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$MODEL\",
            \"messages\": [
                {\"role\": \"user\", \"content\": \"Write a detailed explanation of how machine learning works, including neural networks, training processes, and practical applications. Make it comprehensive but accessible.\"}
            ],
            \"stream\": false,
            \"max_tokens\": 200
        }" 2>/dev/null)
    
    if echo "$BENCHMARK_RESPONSE" | jq . >/dev/null 2>&1; then
        echo "✅ Performance benchmark passed"
        echo "💬 Response preview: $(echo "$BENCHMARK_RESPONSE" | jq -r '.choices[0].message.content' | head -c 150)..."
        calculate_tps "$BENCHMARK_RESPONSE"
    else
        echo "❌ Performance benchmark failed"
        echo "📋 Response: $BENCHMARK_RESPONSE"
    fi
    echo ""
    
    echo "🎯 Test Summary"
    echo "==============="
    echo "✅ Completed comprehensive API testing with performance metrics"
    echo "🔗 OpenAI-compatible endpoints tested"
    echo "📝 Both streaming and non-streaming modes tested"
    echo "🎭 System prompts and multi-turn conversations tested"
    echo "⚡ Tokens per second (TPS) calculated for all non-streaming tests"
    echo "🚀 Performance benchmark included for detailed TPS analysis"
    echo ""
    echo "🚀 llama.cpp container is ready for use!"
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
        run_api_tests
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
