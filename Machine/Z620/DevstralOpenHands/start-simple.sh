#!/bin/bash

# Simple startup script for testing
set -e

echo "🚀 Simple Startup Test"
echo "====================="

# Load environment variables
if [ -f .env ]; then
    source .env
    echo "✅ Environment variables loaded"
else
    echo "❌ Error: .env file not found"
    exit 1
fi

# Create models directory
mkdir -p ~/.models

# Check if model exists
MODEL_PATH_EXPANDED="${MODEL_DIR/#\~/$HOME}/${MODEL_NAME}"
if [ ! -f "$MODEL_PATH_EXPANDED" ]; then
    echo "❌ Model not found at: $MODEL_PATH_EXPANDED"
    echo "   Please run the full ./start.sh to download the model first"
    exit 1
fi

echo "✅ Model exists: $MODEL_PATH_EXPANDED"

# Start containers
echo "🔧 Starting containers..."
docker compose up -d

echo "⏳ Waiting for containers to start..."
sleep 10

echo "📋 Container Status:"
docker compose ps

echo ""
echo "🔍 Testing health..."
./debug-health.sh

echo ""
echo "🎉 Startup complete!"
echo "Check the debug output above for any issues."
