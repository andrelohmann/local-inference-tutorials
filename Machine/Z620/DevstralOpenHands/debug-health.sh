#!/bin/bash

# Debug script to test health check functionality
set -e

echo "🔍 Health Check Debug Script"
echo "============================="

# Check if containers are running
echo "📋 Container Status:"
docker compose ps

echo ""
echo "📋 All Docker Containers:"
docker ps -a | grep -E "(llama-cpp|openhands|devstral)" || echo "No matching containers found"

echo ""
echo "🔍 Health Check Tests:"

# Test llama.cpp container
if docker ps | grep -q "llama-cpp-devstral"; then
    echo "✅ llama.cpp container is running"
    
    # Test health check script
    echo "🔍 Testing health check script..."
    docker exec llama-cpp-devstral /app/health-check.sh || echo "Health check script failed"
    
    # Test API endpoint
    echo "🔍 Testing API endpoint..."
    docker exec llama-cpp-devstral curl -sf http://localhost:11434/health || echo "API endpoint not responding"
    
    # Check Docker health status
    echo "🔍 Docker health status:"
    docker inspect --format='{{.State.Health.Status}}' llama-cpp-devstral 2>/dev/null || echo "No health check configured"
else
    echo "❌ llama.cpp container not running"
fi

echo ""
if docker ps | grep -q "openhands"; then
    echo "✅ OpenHands container is running"
    
    # Test OpenHands endpoint
    echo "🔍 Testing OpenHands endpoint..."
    docker exec openhands curl -sf http://localhost:3000 || echo "OpenHands endpoint not responding"
else
    echo "❌ OpenHands container not running"
fi

echo ""
echo "🔍 Recent logs:"
echo "llama.cpp logs:"
docker compose logs --tail=10 llama-cpp-server 2>/dev/null || echo "No logs available"

echo ""
echo "OpenHands logs:"
docker compose logs --tail=10 openhands 2>/dev/null || echo "No logs available"
