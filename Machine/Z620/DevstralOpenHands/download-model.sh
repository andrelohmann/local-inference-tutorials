#!/bin/bash

# Enhanced Model Download Script
# Downloads Devstral model with proper error handling and validation

set -e

MODEL_DIR="./models"
MODEL_FILE="devstral-q4_k_m.gguf"
WORKSPACE_DIR="./workspace"

# Create directories
mkdir -p "$MODEL_DIR" "$WORKSPACE_DIR"

echo "=== Devstral Model Download ==="
echo "Model: $MODEL_FILE"
echo "Destination: $MODEL_DIR/$MODEL_FILE"
echo ""

# Check if model already exists
if [ -f "$MODEL_DIR/$MODEL_FILE" ]; then
    echo "✓ Model $MODEL_FILE already exists."
    echo "  Size: $(du -h "$MODEL_DIR/$MODEL_FILE" | cut -f1)"
    echo "  Skipping download."
    exit 0
fi

# Check if placeholder exists (from previous failed download)
if [ -f "$MODEL_DIR/$MODEL_FILE.placeholder" ]; then
    echo "⚠ Placeholder file found from previous failed download."
    echo "  Please manually download the model or remove the placeholder to retry."
    exit 1
fi

echo "Installing download dependencies..."
if command -v wget >/dev/null 2>&1; then
    DOWNLOADER="wget"
elif command -v curl >/dev/null 2>&1; then
    DOWNLOADER="curl"
else
    echo "Error: Neither wget nor curl found. Please install one of them."
    exit 1
fi

# Note: Update this URL with the actual Devstral model URL when available
# This is a placeholder - you'll need to replace with the real model URL
DEVSTRAL_URL="https://huggingface.co/mistralai/Devstral-Small-2507_gguf/resolve/main/Devstral-Small-2507-Q4_K_M.gguf"

echo "Downloading Devstral model..."
echo "URL: $DEVSTRAL_URL"
echo ""

# Download with progress indication
if [ "$DOWNLOADER" = "wget" ]; then
    if wget --progress=bar:force -O "$MODEL_DIR/$MODEL_FILE.tmp" "$DEVSTRAL_URL"; then
        mv "$MODEL_DIR/$MODEL_FILE.tmp" "$MODEL_DIR/$MODEL_FILE"
        echo "✓ Successfully downloaded $MODEL_FILE"
    else
        download_failed=true
    fi
elif [ "$DOWNLOADER" = "curl" ]; then
    if curl -L --progress-bar -o "$MODEL_DIR/$MODEL_FILE.tmp" "$DEVSTRAL_URL"; then
        mv "$MODEL_DIR/$MODEL_FILE.tmp" "$MODEL_DIR/$MODEL_FILE"
        echo "✓ Successfully downloaded $MODEL_FILE"
    else
        download_failed=true
    fi
fi

# Handle download failure
if [ "$download_failed" = true ]; then
    rm -f "$MODEL_DIR/$MODEL_FILE.tmp"
    echo "✗ Failed to download model automatically."
    echo ""
    echo "Manual download instructions:"
    echo "1. Visit the official Devstral model page"
    echo "2. Download the GGUF format model file"
    echo "3. Place it in: $MODEL_DIR/$MODEL_FILE"
    echo "4. Run the startup script again"
    echo ""
    echo "Alternative models you can try:"
    echo "- Code Llama: https://huggingface.co/codellama/CodeLlama-7b-Instruct-hf"
    echo "- Mistral: https://huggingface.co/mistralai/Mistral-7B-Instruct-v0.1"
    echo ""
    
    # Create placeholder to prevent repeated failures
    touch "$MODEL_DIR/$MODEL_FILE.placeholder"
    echo "Created placeholder file. Replace with actual model when available."
    exit 1
fi

# Validate downloaded file
if [ -f "$MODEL_DIR/$MODEL_FILE" ]; then
    file_size=$(stat -c%s "$MODEL_DIR/$MODEL_FILE" 2>/dev/null || stat -f%z "$MODEL_DIR/$MODEL_FILE" 2>/dev/null || echo "0")
    if [ "$file_size" -gt 1000000 ]; then  # At least 1MB
        echo "✓ Model file validated successfully"
        echo "  Size: $(du -h "$MODEL_DIR/$MODEL_FILE" | cut -f1)"
    else
        echo "✗ Downloaded file appears to be invalid (too small)"
        rm -f "$MODEL_DIR/$MODEL_FILE"
        exit 1
    fi
else
    echo "✗ Model file not found after download"
    exit 1
fi

echo ""
echo "Model download completed successfully!"
echo "You can now start the Docker Compose services."
