#!/bin/bash

# Cleanup script for direct llama.cpp container testing
# This is a companion script to test-containers.sh for advanced cleanup

set -e

CONTAINER_NAME="llama-cpp-test"
IMAGE_NAME="llama-cpp-test"

echo "🧹 Advanced Cleanup for llama.cpp Test Container"
echo "================================================"

# Show usage
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --remove-image    Remove the built image as well"
    echo "  --help, -h        Show this help message"
    echo ""
    echo "Note: For basic container stop/start, use:"
    echo "  ./test-containers.sh down  # Stop and remove container"
    echo "  ./test-containers.sh up    # Start container"
    echo ""
    exit 0
fi

# Stop and remove container (same as test-containers.sh down)
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

# Remove image if requested
if [ "$1" = "--remove-image" ]; then
    if docker images -q "$IMAGE_NAME" | grep -q .; then
        echo "🗑️  Removing image: $IMAGE_NAME"
        docker rmi $IMAGE_NAME
    else
        echo "ℹ️  Image $IMAGE_NAME does not exist"
    fi
fi

# Clean up any dangling images
echo "🧹 Cleaning up dangling images..."
docker image prune -f

echo "✅ Cleanup complete!"
echo ""
echo "Next steps:"
echo "  ./test-containers.sh up    # Start fresh container"
echo "  ./test-containers.sh help  # Show usage"
