#!/bin/bash

# Cleanup script for direct llama.cpp container testing

set -e

CONTAINER_NAME="llama-cpp-test"
IMAGE_NAME="llama-cpp-test"

echo "🧹 Cleaning up llama.cpp test container"
echo "======================================="

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

# Optionally remove the image
if [ "$1" = "--remove-image" ]; then
    if docker images -q "$IMAGE_NAME" | grep -q .; then
        echo "🗑️  Removing image: $IMAGE_NAME"
        docker rmi $IMAGE_NAME
    else
        echo "ℹ️  Image $IMAGE_NAME does not exist"
    fi
fi

echo "✅ Cleanup complete!"
echo ""
echo "Usage:"
echo "  ./cleanup-test.sh              # Remove container only"
echo "  ./cleanup-test.sh --remove-image  # Remove container and image"
