#!/bin/bash

# Devstral OpenHands Startup Script
# This script sets up and starts the complete environment

set -e

echo "=== Devstral OpenHands Setup ==="
echo "Starting llama.cpp server with OpenHands integration"
echo "Target Architecture: NVIDIA Pascal (Quadro P4000/P5000)"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker first."
    exit 1
fi

# Check if NVIDIA Docker runtime is available
if ! docker run --rm --gpus all nvidia/cuda:12.6.0-base-ubuntu24.04 nvidia-smi > /dev/null 2>&1; then
    echo "Warning: NVIDIA Docker runtime not available. GPU acceleration will not work."
    echo "Please install NVIDIA Container Toolkit."
fi

# Create necessary directories
echo "Creating required directories..."
mkdir -p models workspace ~/.openhands

# Pull runtime container (required for OpenHands)
echo "Pulling OpenHands runtime container..."
docker pull docker.all-hands.dev/all-hands-ai/runtime:0.48-nikolaik

# Build and start services
echo "Building and starting services..."
echo "The model will be downloaded automatically on first startup..."

docker compose up --build -d

echo ""
echo "=== Startup Complete ==="
echo ""
echo "Services starting up. Model download will take 20-30 minutes for 15GB model..."
echo "The health check now provides detailed status during the entire process."
echo ""
echo "Monitor detailed health status:"
echo "  ./monitor-health.sh"
echo ""
echo "Monitor model download progress:"
echo "  docker compose logs -f llama-cpp-server"
echo ""
echo "Access points (available after model download):"
echo "- OpenHands Interface: http://localhost:3000"
echo "- llama.cpp Server API: http://localhost:11434"
echo "- Health Check: http://localhost:11434/health"
echo ""
echo "To monitor all logs:"
echo "  docker compose logs -f"
echo ""
echo "To stop services:"
echo "  docker compose down"
echo ""

# Wait for services to be ready
echo "Waiting for services to initialize..."
sleep 10

# Check service health
echo "Checking service status..."
docker compose ps

echo ""
echo "Setup complete! Use './monitor-health.sh' to track download progress."
echo "Expected timeline:"
echo "  - WAITING: Container starting up"
echo "  - DOWNLOADING: Model download (20-30 minutes)"
echo "  - LOADING: Model loading into memory"
echo "  - SERVING: Ready for requests"
