#!/bin/bash

# Monitor model download progress
# This script monitors the download progress of the Devstral model

set -e

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo "❌ Error: .env file not found"
    exit 1
fi

MODEL_PATH="./models/${MODEL_NAME}"
TEMP_PATH="${MODEL_PATH}.tmp"

# Function to format bytes
format_bytes() {
    local bytes=$1
    if [ $bytes -lt 1024 ]; then
        echo "${bytes}B"
    elif [ $bytes -lt 1048576 ]; then
        echo "$((bytes/1024))KB"
    elif [ $bytes -lt 1073741824 ]; then
        echo "$((bytes/1048576))MB"
    else
        echo "$((bytes/1073741824))GB"
    fi
}

echo "📊 Model Download Monitor"
echo "========================"
echo "Model: $MODEL_NAME"
echo "Path: $MODEL_PATH"
echo ""

if [ -f "$MODEL_PATH" ]; then
    model_size=$(stat -f%z "$MODEL_PATH" 2>/dev/null || stat -c%s "$MODEL_PATH" 2>/dev/null || echo "0")
    model_formatted=$(format_bytes $model_size)
    echo "✅ Model already exists: $model_formatted"
    echo ""
    echo "🔍 Checking container status..."
    docker compose ps
    exit 0
fi

if [ ! -f "$TEMP_PATH" ]; then
    echo "ℹ️  No download in progress"
    echo "   Run './start.sh' to begin setup"
    exit 0
fi

echo "⏳ Monitoring download progress..."
echo "   Press Ctrl+C to stop monitoring (download will continue)"
echo ""

last_size=0
last_time=$(date +%s)

while [ -f "$TEMP_PATH" ]; do
    current_size=$(stat -f%z "$TEMP_PATH" 2>/dev/null || stat -c%s "$TEMP_PATH" 2>/dev/null || echo "0")
    current_time=$(date +%s)
    
    if [ $current_size -gt 0 ]; then
        current_formatted=$(format_bytes $current_size)
        
        # Calculate speed
        size_diff=$((current_size - last_size))
        time_diff=$((current_time - last_time))
        
        if [ $time_diff -gt 0 ] && [ $size_diff -gt 0 ]; then
            speed=$((size_diff / time_diff))
            speed_formatted=$(format_bytes $speed)
            
            # Calculate ETA (assuming 15GB total)
            expected_size=16106127360
            remaining=$((expected_size - current_size))
            if [ $speed -gt 0 ]; then
                eta_seconds=$((remaining / speed))
                eta_minutes=$((eta_seconds / 60))
                eta_hours=$((eta_minutes / 60))
                eta_display=""
                if [ $eta_hours -gt 0 ]; then
                    eta_display="${eta_hours}h $((eta_minutes % 60))m"
                else
                    eta_display="${eta_minutes}m"
                fi
            else
                eta_display="calculating..."
            fi
            
            percentage=$((current_size * 100 / expected_size))
            echo "[$(date '+%H:%M:%S')] $current_formatted / 15GB ($percentage%) at ${speed_formatted}/s - ETA: $eta_display"
        else
            echo "[$(date '+%H:%M:%S')] $current_formatted"
        fi
        
        last_size=$current_size
        last_time=$current_time
    fi
    
    sleep 5
done

if [ -f "$MODEL_PATH" ]; then
    final_size=$(stat -f%z "$MODEL_PATH" 2>/dev/null || stat -c%s "$MODEL_PATH" 2>/dev/null || echo "0")
    final_formatted=$(format_bytes $final_size)
    echo ""
    echo "✅ Download completed: $final_formatted"
    echo "🔍 Checking container status..."
    docker compose ps
else
    echo ""
    echo "❌ Download appears to have failed"
fi
