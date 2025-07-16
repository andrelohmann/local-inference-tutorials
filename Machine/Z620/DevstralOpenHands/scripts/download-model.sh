#!/bin/sh

# Devstral Model Download Script
# This script downloads the Devstral model if it doesn't exist

MODEL_DIR="/models"
MODEL_FILE="devstral-q4_k_m.gguf"
MODEL_URL="https://huggingface.co/mistralai/Devstral-Small-2507_gguf/resolve/main/Devstral-Small-2507-Q4_K_M.gguf"

# Create models directory if it doesn't exist
mkdir -p "$MODEL_DIR"

# Check if model already exists
if [ -f "$MODEL_DIR/$MODEL_FILE" ]; then
    echo "Model $MODEL_FILE already exists. Skipping download."
    exit 0
fi

echo "Installing required packages..."
apk add --no-cache curl wget

echo "Downloading Devstral model..."
echo "Model: $MODEL_FILE"
echo "Destination: $MODEL_DIR/$MODEL_FILE"

# Note: Replace with actual Devstral model URL when available
# For now, this is a placeholder URL - you'll need to update this with the actual Devstral model URL
DEVSTRAL_URL="https://huggingface.co/mistralai/Devstral-Small-2507_gguf/resolve/main/Devstral-Small-2507-Q4_K_M.gguf"

# Try to download the model
if wget -O "$MODEL_DIR/$MODEL_FILE.tmp" "$DEVSTRAL_URL"; then
    mv "$MODEL_DIR/$MODEL_FILE.tmp" "$MODEL_DIR/$MODEL_FILE"
    echo "Successfully downloaded $MODEL_FILE"
else
    echo "Failed to download model. Please check the URL or download manually."
    echo "Expected location: $MODEL_DIR/$MODEL_FILE"
    echo ""
    echo "Manual download instructions:"
    echo "1. Download Devstral model from the official source"
    echo "2. Place it in the models directory as: $MODEL_FILE"
    echo "3. Restart the containers"
    
    # Create a placeholder file to prevent repeated failures
    touch "$MODEL_DIR/$MODEL_FILE.placeholder"
    echo "Created placeholder file. Please replace with actual model."
    exit 1
fi

echo "Model download completed successfully!"
