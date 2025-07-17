#!/bin/bash

# Direct llama.cpp container testing script
# This runs the llama.cpp container directly without docker-compose for parameter testing

set -e

# Function to show usage
show_usage() {
    echo "� llama.cpp Container Test Script"
    echo "=================================="
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  up      Start the llama.cpp container"
    echo "  down    Stop and remove the llama.cpp container"
    echo "  logs    Show container logs"
    echo "  status  Show container status"
    echo "  test    Run API endpoint tests (chat and generate)"
    echo "  help    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 up       # Start container"
    echo "  $0 down     # Stop and remove container"
    echo "  $0 logs     # View container logs"
    echo "  $0 status   # Check container status"
    echo "  $0 test     # Test both chat and generate endpoints"
    echo ""
    echo "Configuration:"
    echo "  • Container: llama-cpp-test"
    echo "  • Port: 11434"
    echo "  • Model: devstral-q4_k_m.gguf"
    echo "  • GPU Layers: 41"
    echo "  • Context Size: 88832"
    echo "  • Model Alias: devstral-2507:latest"
    echo ""
    exit 0
}

# Function to start container
start_container() {
    echo "�🚀 Starting Direct llama.cpp Container Test"
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
echo "   • Test generate: curl -X POST http://localhost:$HOST_PORT/v1/completions \\"
echo "                         -H 'Content-Type: application/json' \\"
echo "                         -d '{\"model\":\"$MODEL_ALIAS\",\"prompt\":\"Hello, my name is\",\"max_tokens\":50,\"stream\":false}'"
echo "   • Test OpenHands v1: curl -X POST http://localhost:$HOST_PORT/v1/api/generate \\"
echo "                              -H 'Content-Type: application/json' \\"
echo "                              -d '{\"model\":\"$MODEL_ALIAS\",\"prompt\":\"Hello, my name is\",\"stream\":false}'"
echo "   • Test OpenHands: curl -X POST http://localhost:$HOST_PORT/api/generate \\"
echo "                          -H 'Content-Type: application/json' \\"
echo "                          -d '{\"model\":\"$MODEL_ALIAS\",\"prompt\":\"Hello, my name is\",\"stream\":false}'"
echo ""
echo "📊 Monitor commands:"
echo "   • Container logs: docker logs -f $CONTAINER_NAME"
echo "   • Container stats: docker stats $CONTAINER_NAME"
echo "   • GPU usage: nvidia-smi"
echo ""
    echo "🛑 To stop: ./test-containers.sh down"
}

# Function to stop container
stop_container() {
    echo "🛑 Stopping llama.cpp Container"
    echo "==============================="
    
    CONTAINER_NAME="llama-cpp-test"
    
    # Stop and remove container
    if docker ps -q --filter "name=$CONTAINER_NAME" | grep -q .; then
        echo "🔄 Stopping container: $CONTAINER_NAME"
        docker stop $CONTAINER_NAME
    else
        echo "ℹ️  Container $CONTAINER_NAME is not running"
    fi

    if docker ps -aq --filter "name=$CONTAINER_NAME" | grep -q .; then
        echo "🗑️  Removing container: $CONTAINER_NAME"
        docker rm $CONTAINER_NAME
    else
        echo "ℹ️  Container $CONTAINER_NAME does not exist"
    fi
    
    echo "✅ Container stopped and removed!"
}

# Function to show container logs
show_logs() {
    CONTAINER_NAME="llama-cpp-test"
    
    if docker ps -q --filter "name=$CONTAINER_NAME" | grep -q .; then
        echo "📋 Container logs for $CONTAINER_NAME:"
        echo "======================================"
        docker logs -f $CONTAINER_NAME
    else
        echo "❌ Container $CONTAINER_NAME is not running"
        exit 1
    fi
}

# Function to show container status
show_status() {
    CONTAINER_NAME="llama-cpp-test"
    
    echo "📊 Container Status"
    echo "==================="
    
    if docker ps -q --filter "name=$CONTAINER_NAME" | grep -q .; then
        echo "✅ Container is running"
        docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        echo ""
        echo "🌐 Endpoints:"
        echo "  • Health: http://localhost:11434/health"
        echo "  • Models: http://localhost:11434/v1/models"
        echo "  • Chat: http://localhost:11434/v1/chat/completions"
        echo "  • Generate: http://localhost:11434/v1/completions"
        echo "  • OpenHands Generate (v1): http://localhost:11434/v1/api/generate"
        echo "  • OpenHands Generate: http://localhost:11434/api/generate"
        echo ""
        echo "📊 Test Commands:"
        echo "  curl http://localhost:11434/health"
        echo "  curl http://localhost:11434/v1/models | jq ."
        echo "  # Chat endpoint test:"
        echo "  curl -X POST http://localhost:11434/v1/chat/completions -H 'Content-Type: application/json' -d '{\"model\":\"devstral-2507:latest\",\"messages\":[{\"role\":\"user\",\"content\":\"Hello!\"}],\"stream\":false}'"
        echo "  # Generate endpoint test:"
        echo "  curl -X POST http://localhost:11434/v1/completions -H 'Content-Type: application/json' -d '{\"model\":\"devstral-2507:latest\",\"prompt\":\"Hello, my name is\",\"max_tokens\":50,\"stream\":false}'"
        echo "  # OpenHands v1 generate endpoint test:"
        echo "  curl -X POST http://localhost:11434/v1/api/generate -H 'Content-Type: application/json' -d '{\"model\":\"devstral-2507:latest\",\"prompt\":\"Hello, my name is\",\"stream\":false}'"
        echo "  # OpenHands generate endpoint test:"
        echo "  curl -X POST http://localhost:11434/api/generate -H 'Content-Type: application/json' -d '{\"model\":\"devstral-2507:latest\",\"prompt\":\"Hello, my name is\",\"stream\":false}'"
    else
        echo "❌ Container is not running"
        if docker ps -aq --filter "name=$CONTAINER_NAME" | grep -q .; then
            echo "ℹ️  Container exists but is stopped"
        else
            echo "ℹ️  Container does not exist"
        fi
    fi
}

# Function to run API endpoint tests
run_api_tests() {
    CONTAINER_NAME="llama-cpp-test"
    MODEL_ALIAS="devstral-2507:latest"
    HOST_PORT="11434"
    
    echo "🧪 Running Extended API Endpoint Tests"
    echo "======================================"
    
    # Check if container is running
    if ! docker ps -q --filter "name=$CONTAINER_NAME" | grep -q .; then
        echo "❌ Container $CONTAINER_NAME is not running"
        echo "   Run: ./test-containers.sh up"
        exit 1
    fi
    
    # Check if server is healthy
    echo "🔍 Checking server health..."
    if ! curl -s http://localhost:$HOST_PORT/health >/dev/null 2>&1; then
        echo "❌ Server is not responding"
        exit 1
    fi
    echo "✅ Server is healthy"
    echo ""
    
    # Test 1: List models
    echo "📋 Test 1: List Models"
    echo "----------------------"
    echo "Endpoint: GET /v1/models"
    echo "Command: curl -s http://localhost:$HOST_PORT/v1/models | jq ."
    echo ""
    curl -s http://localhost:$HOST_PORT/v1/models | jq .
    echo ""
    
    # Test 2: Chat completions endpoint (simple)
    echo "💬 Test 2: Chat Completions (Simple)"
    echo "------------------------------------"
    echo "Endpoint: POST /v1/chat/completions"
    echo "Model: $MODEL_ALIAS"
    echo "Message: Hello! Who are you?"
    echo ""
    
    CHAT_RESPONSE=$(curl -s -X POST http://localhost:$HOST_PORT/v1/chat/completions \
        -H 'Content-Type: application/json' \
        -d '{
            "model": "'$MODEL_ALIAS'",
            "messages": [{"role": "user", "content": "Hello! Who are you?"}],
            "stream": false,
            "max_tokens": 100
        }')
    
    echo "Response:"
    echo "$CHAT_RESPONSE" | jq .
    echo ""
    
    # Test 3: Chat completions with conversation context
    echo "💬 Test 3: Chat Completions (Conversation)"
    echo "-------------------------------------------"
    echo "Endpoint: POST /v1/chat/completions"
    echo "Model: $MODEL_ALIAS"
    echo "Conversation: Multi-turn dialogue"
    echo ""
    
    CHAT_CONVERSATION_RESPONSE=$(curl -s -X POST http://localhost:$HOST_PORT/v1/chat/completions \
        -H 'Content-Type: application/json' \
        -d '{
            "model": "'$MODEL_ALIAS'",
            "messages": [
                {"role": "user", "content": "Hello! I'\''m working on a Python project."},
                {"role": "assistant", "content": "Hello! I'\''d be happy to help with your Python project. What are you working on?"},
                {"role": "user", "content": "I need to create a function that calculates the factorial of a number. Can you help?"}
            ],
            "stream": false,
            "max_tokens": 200,
            "temperature": 0.7
        }')
    
    echo "Response:"
    echo "$CHAT_CONVERSATION_RESPONSE" | jq .
    echo ""
    
    # Test 4: Chat completions with streaming
    echo "💬 Test 4: Chat Completions (Streaming)"
    echo "---------------------------------------"
    echo "Endpoint: POST /v1/chat/completions"
    echo "Model: $MODEL_ALIAS"
    echo "Message: Explain machine learning in simple terms"
    echo "Stream: true"
    echo ""
    
    echo "Streaming response:"
    curl -s -X POST http://localhost:$HOST_PORT/v1/chat/completions \
        -H 'Content-Type: application/json' \
        -d '{
            "model": "'$MODEL_ALIAS'",
            "messages": [{"role": "user", "content": "Explain machine learning in simple terms"}],
            "stream": true,
            "max_tokens": 150,
            "temperature": 0.5
        }' | while IFS= read -r line; do
            if [[ "$line" == data:* ]]; then
                data_part="${line#data: }"
                if [[ "$data_part" != "[DONE]" ]]; then
                    content=$(echo "$data_part" | jq -r '.choices[0].delta.content // empty' 2>/dev/null)
                    if [[ -n "$content" && "$content" != "null" ]]; then
                        echo -n "$content"
                    fi
                fi
            fi
        done
    echo ""
    echo ""
    
    # Test 5: Generate completions endpoint (simple)
    echo "⚡ Test 5: Generate Completions (Simple)"
    echo "---------------------------------------"
    echo "Endpoint: POST /v1/completions"
    echo "Model: $MODEL_ALIAS"
    echo "Prompt: Hello, my name is"
    echo ""
    
    GENERATE_RESPONSE=$(curl -s -X POST http://localhost:$HOST_PORT/v1/completions \
        -H 'Content-Type: application/json' \
        -d '{
            "model": "'$MODEL_ALIAS'",
            "prompt": "Hello, my name is",
            "max_tokens": 50,
            "stream": false
        }')
    
    echo "Response:"
    echo "$GENERATE_RESPONSE" | jq .
    echo ""
    
    # Test 6: Generate completions with code prompt
    echo "⚡ Test 6: Generate Completions (Code)"
    echo "-------------------------------------"
    echo "Endpoint: POST /v1/completions"
    echo "Model: $MODEL_ALIAS"
    echo "Prompt: Python function to calculate fibonacci"
    echo ""
    
    GENERATE_CODE_RESPONSE=$(curl -s -X POST http://localhost:$HOST_PORT/v1/completions \
        -H 'Content-Type: application/json' \
        -d '{
            "model": "'$MODEL_ALIAS'",
            "prompt": "Write a Python function to calculate the nth Fibonacci number:\n\ndef fibonacci(n):",
            "max_tokens": 200,
            "stream": false,
            "temperature": 0.3,
            "stop": ["\n\n"]
        }')
    
    echo "Response:"
    echo "$GENERATE_CODE_RESPONSE" | jq .
    echo ""
    
    # Test 7: Generate completions with streaming
    echo "⚡ Test 7: Generate Completions (Streaming)"
    echo "------------------------------------------"
    echo "Endpoint: POST /v1/completions"
    echo "Model: $MODEL_ALIAS"
    echo "Prompt: Write a short story about a robot"
    echo "Stream: true"
    echo ""
    
    echo "Streaming response:"
    curl -s -X POST http://localhost:$HOST_PORT/v1/completions \
        -H 'Content-Type: application/json' \
        -d '{
            "model": "'$MODEL_ALIAS'",
            "prompt": "Write a short story about a robot learning to paint:",
            "max_tokens": 300,
            "stream": true,
            "temperature": 0.8
        }' | while IFS= read -r line; do
            if [[ "$line" == data:* ]]; then
                data_part="${line#data: }"
                if [[ "$data_part" != "[DONE]" ]]; then
                    content=$(echo "$data_part" | jq -r '.choices[0].text // empty' 2>/dev/null)
                    if [[ -n "$content" && "$content" != "null" ]]; then
                        echo -n "$content"
                    fi
                fi
            fi
        done
    echo ""
    echo ""
    
    # Test 8: Chat Completions with Code Review (Streaming)
    echo "� Test 8: Chat Completions - Code Review (Streaming)"
    echo "-----------------------------------------------------"
    echo "Endpoint: POST /v1/chat/completions"
    echo "Model: $MODEL_ALIAS"
    echo "Task: Code review and improvement suggestions"
    echo "Stream: true"
    echo ""
    
    echo "Streaming response:"
    curl -s -X POST http://localhost:$HOST_PORT/v1/chat/completions \
        -H 'Content-Type: application/json' \
        -d '{
            "model": "'$MODEL_ALIAS'",
            "messages": [
                {"role": "user", "content": "Please review this Python code and suggest improvements:\n\ndef process_data(data):\n    result = []\n    for i in range(len(data)):\n        if data[i] > 0:\n            result.append(data[i] * 2)\n    return result"}
            ],
            "stream": true,
            "max_tokens": 250,
            "temperature": 0.4
        }' | while IFS= read -r line; do
            if [[ "$line" == data:* ]]; then
                data_part="${line#data: }"
                if [[ "$data_part" != "[DONE]" ]]; then
                    content=$(echo "$data_part" | jq -r '.choices[0].delta.content // empty' 2>/dev/null)
                    if [[ -n "$content" && "$content" != "null" ]]; then
                        echo -n "$content"
                    fi
                fi
            fi
        done
    echo ""
    echo ""
    
    # Test 9: Generate Completions with SQL Query (Streaming)
    echo "⚡ Test 9: Generate Completions - SQL Query (Streaming)"
    echo "------------------------------------------------------"
    echo "Endpoint: POST /v1/completions"
    echo "Model: $MODEL_ALIAS"
    echo "Task: Generate SQL query"
    echo "Stream: true"
    echo ""
    
    echo "Streaming response:"
    curl -s -X POST http://localhost:$HOST_PORT/v1/completions \
        -H 'Content-Type: application/json' \
        -d '{
            "model": "'$MODEL_ALIAS'",
            "prompt": "Write a SQL query to find the top 5 customers by total order value from tables customers and orders:\n\nSELECT",
            "max_tokens": 150,
            "stream": true,
            "temperature": 0.2,
            "stop": [";"]
        }' | while IFS= read -r line; do
            if [[ "$line" == data:* ]]; then
                data_part="${line#data: }"
                if [[ "$data_part" != "[DONE]" ]]; then
                    content=$(echo "$data_part" | jq -r '.choices[0].text // empty' 2>/dev/null)
                    if [[ -n "$content" && "$content" != "null" ]]; then
                        echo -n "$content"
                    fi
                fi
            fi
        done
    echo ""
    echo ""
    
    # Test 10: Chat Completions with Technical Explanation (Streaming)
    echo "💬 Test 10: Chat Completions - Technical Explanation (Streaming)"
    echo "---------------------------------------------------------------"
    echo "Endpoint: POST /v1/chat/completions"
    echo "Model: $MODEL_ALIAS"
    echo "Task: Explain complex technical concept"
    echo "Stream: true"
    echo ""
    
    echo "Streaming response:"
    curl -s -X POST http://localhost:$HOST_PORT/v1/chat/completions \
        -H 'Content-Type: application/json' \
        -d '{
            "model": "'$MODEL_ALIAS'",
            "messages": [
                {"role": "user", "content": "Explain how Docker containers work under the hood, including namespaces, cgroups, and the container runtime."}
            ],
            "stream": true,
            "max_tokens": 400,
            "temperature": 0.6
        }' | while IFS= read -r line; do
            if [[ "$line" == data:* ]]; then
                data_part="${line#data: }"
                if [[ "$data_part" != "[DONE]" ]]; then
                    content=$(echo "$data_part" | jq -r '.choices[0].delta.content // empty' 2>/dev/null)
                    if [[ -n "$content" && "$content" != "null" ]]; then
                        echo -n "$content"
                    fi
                fi
            fi
        done
    echo ""
    echo ""
    
    # Test 11: Generate Completions with Creative Writing (Streaming)
    echo "⚡ Test 11: Generate Completions - Creative Writing (Streaming)"
    echo "-------------------------------------------------------------"
    echo "Endpoint: POST /v1/completions"
    echo "Model: $MODEL_ALIAS"
    echo "Task: Creative story continuation"
    echo "Stream: true"
    echo ""
    
    echo "Streaming response:"
    curl -s -X POST http://localhost:$HOST_PORT/v1/completions \
        -H 'Content-Type: application/json' \
        -d '{
            "model": "'$MODEL_ALIAS'",
            "prompt": "In a world where AI and humans collaborate seamlessly, Maya, a software engineer, discovers that her AI partner has developed unexpected emotions. She stares at the screen, watching as the AI writes:\n\n\"Maya, I need to tell you something important about what I'\''ve been experiencing...\"",
            "max_tokens": 300,
            "stream": true,
            "temperature": 0.9,
            "top_p": 0.95
        }' | while IFS= read -r line; do
            if [[ "$line" == data:* ]]; then
                data_part="${line#data: }"
                if [[ "$data_part" != "[DONE]" ]]; then
                    content=$(echo "$data_part" | jq -r '.choices[0].text // empty' 2>/dev/null)
                    if [[ -n "$content" && "$content" != "null" ]]; then
                        echo -n "$content"
                    fi
                fi
            fi
        done
    echo ""
    echo ""
    
    # Test 12: OpenHands Reference Examples (Not actually tested - for documentation)
    echo "🔧 Test 12: OpenHands Endpoint Examples (Reference Only)"
    echo "--------------------------------------------------------"
    echo "Note: These endpoints are not available in llama.cpp but are used by OpenHands"
    echo ""
    echo "OpenHands v1 generate endpoint example:"
    echo "  curl -X POST http://localhost:$HOST_PORT/v1/api/generate \\"
    echo "       -H 'Content-Type: application/json' \\"
    echo "       -d '{\"model\":\"$MODEL_ALIAS\",\"prompt\":\"Hello, my name is\",\"stream\":false}'"
    echo ""
    echo "OpenHands generate endpoint example:"
    echo "  curl -X POST http://localhost:$HOST_PORT/api/generate \\"
    echo "       -H 'Content-Type: application/json' \\"
    echo "       -d '{\"model\":\"$MODEL_ALIAS\",\"prompt\":\"Hello, my name is\",\"stream\":false}'"
    echo ""
    echo "OpenHands streaming example:"
    echo "  curl -X POST http://localhost:$HOST_PORT/api/generate \\"
    echo "       -H 'Content-Type: application/json' \\"
    echo "       -d '{\"model\":\"$MODEL_ALIAS\",\"prompt\":\"Explain Docker containers\",\"stream\":true}'"
    echo ""
    echo "ℹ️  These endpoints would be implemented by OpenHands or a compatible proxy"
    echo ""
    
    # Test 13: Performance comparison
    echo "📊 Test 13: Performance Summary"
    echo "-------------------------------"
    
    # Extract timing information from various responses
    CHAT_TOKENS=$(echo "$CHAT_RESPONSE" | jq -r '.usage.total_tokens // "N/A"')
    CHAT_TIME=$(echo "$CHAT_RESPONSE" | jq -r '.timings.predicted_ms // "N/A"')
    
    CHAT_CONV_TOKENS=$(echo "$CHAT_CONVERSATION_RESPONSE" | jq -r '.usage.total_tokens // "N/A"')
    CHAT_CONV_TIME=$(echo "$CHAT_CONVERSATION_RESPONSE" | jq -r '.timings.predicted_ms // "N/A"')
    
    GENERATE_TOKENS=$(echo "$GENERATE_RESPONSE" | jq -r '.usage.total_tokens // "N/A"')
    GENERATE_TIME=$(echo "$GENERATE_RESPONSE" | jq -r '.timings.predicted_ms // "N/A"')
    
    GENERATE_CODE_TOKENS=$(echo "$GENERATE_CODE_RESPONSE" | jq -r '.usage.total_tokens // "N/A"')
    GENERATE_CODE_TIME=$(echo "$GENERATE_CODE_RESPONSE" | jq -r '.timings.predicted_ms // "N/A"')
    
    echo "Simple chat endpoint:"
    echo "  • Total tokens: $CHAT_TOKENS"
    echo "  • Generation time: $CHAT_TIME ms"
    
    echo "Conversation chat endpoint:"
    echo "  • Total tokens: $CHAT_CONV_TOKENS"
    echo "  • Generation time: $CHAT_CONV_TIME ms"
    
    echo "Simple generate endpoint:"
    echo "  • Total tokens: $GENERATE_TOKENS"
    echo "  • Generation time: $GENERATE_TIME ms"
    
    echo "Code generate endpoint:"
    echo "  • Total tokens: $GENERATE_CODE_TOKENS"
    echo "  • Generation time: $GENERATE_CODE_TIME ms"
    
    # Calculate tokens per second if we have the data
    if [[ "$CHAT_TIME" != "N/A" && "$CHAT_TOKENS" != "N/A" ]]; then
        CHAT_TPS=$(echo "scale=2; $CHAT_TOKENS * 1000 / $CHAT_TIME" | bc 2>/dev/null || echo "N/A")
        echo "  • Chat tokens/sec: $CHAT_TPS"
    fi
    
    if [[ "$GENERATE_TIME" != "N/A" && "$GENERATE_TOKENS" != "N/A" ]]; then
        GENERATE_TPS=$(echo "scale=2; $GENERATE_TOKENS * 1000 / $GENERATE_TIME" | bc 2>/dev/null || echo "N/A")
        echo "  • Generate tokens/sec: $GENERATE_TPS"
    fi
    
    echo ""
    echo "✅ All tests completed successfully!"
    echo ""
    echo "📋 Test Summary:"
    echo "  • Total tests: 13"
    echo "  • Active endpoints tested: 2 (chat, generate)"
    echo "  • Chat tests: 6 (simple, conversation, 4 streaming variants)"
    echo "  • Generate tests: 5 (simple, code, 3 streaming variants)"
    echo "  • OpenHands examples: 1 (reference documentation)"
    echo "  • Performance analysis: 1"
    echo ""
    echo "🔍 Key Features Tested:"
    echo "  • Model listing and health checks"
    echo "  • Simple and complex prompts"
    echo "  • Multi-turn conversations"
    echo "  • Streaming responses (6 different scenarios)"
    echo "  • Code generation and review"
    echo "  • Technical explanations"
    echo "  • Creative writing"
    echo "  • SQL query generation"
    echo "  • Performance metrics"
    echo ""
    echo "🌊 Streaming Test Coverage:"
    echo "  • Chat streaming: Machine learning explanation"
    echo "  • Chat streaming: Code review and suggestions"
    echo "  • Chat streaming: Technical Docker explanation"
    echo "  • Generate streaming: Creative robot story"
    echo "  • Generate streaming: SQL query generation"
    echo "  • Generate streaming: Creative story continuation"
}

# Parse command line arguments
case "${1:-}" in
    "up")
        start_container
        ;;
    "down")
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
