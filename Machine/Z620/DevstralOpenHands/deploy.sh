#!/bin/bash

# Remote Deployment Helper Script
# This script helps deploy the Devstral + OpenHands configuration to a target machine

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_USER=""
TARGET_HOST=""
TARGET_PATH="~/DevstralOpenHands"

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS] <user@host>"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -p, --path     Target path on remote machine (default: ~/DevstralOpenHands)"
    echo ""
    echo "Example:"
    echo "  $0 user@192.168.1.100"
    echo "  $0 -p /opt/devstral user@production-server"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -p|--path)
            TARGET_PATH="$2"
            shift 2
            ;;
        *)
            if [[ -z "$TARGET_USER" ]]; then
                TARGET_USER="$1"
            else
                echo "Error: Unknown option $1"
                usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate required parameters
if [[ -z "$TARGET_USER" ]]; then
    echo "Error: Target user@host is required"
    usage
    exit 1
fi

echo "🚀 Deploying Devstral + OpenHands to target machine..."
echo "=================================================="
echo "• Target: $TARGET_USER"
echo "• Path: $TARGET_PATH"
echo ""

# Test SSH connection
echo "🔗 Testing SSH connection..."
if ! ssh -o ConnectTimeout=10 "$TARGET_USER" "echo 'SSH connection successful'"; then
    echo "❌ Error: Cannot connect to $TARGET_USER"
    exit 1
fi

# Copy files to target machine
echo "📁 Copying configuration files..."
scp -r "$SCRIPT_DIR"/* "$TARGET_USER:$TARGET_PATH/"

# Set permissions on target machine
echo "🔐 Setting file permissions..."
ssh "$TARGET_USER" "chmod +x $TARGET_PATH/start.sh $TARGET_PATH/start-dev.sh $TARGET_PATH/monitor-*.sh"

# Check target machine requirements
echo "🔍 Checking target machine requirements..."
ssh "$TARGET_USER" << 'EOF'
    echo "Checking Docker installation..."
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker is not installed on target machine"
        exit 1
    fi
    
    echo "Checking Docker Compose..."
    if ! docker compose version &> /dev/null; then
        echo "❌ Docker Compose V2 is not available on target machine"
        exit 1
    fi
    
    echo "Checking NVIDIA Container Toolkit..."
    if ! docker run --rm --gpus all nvidia/cuda:12.6.0-base-ubuntu24.04 nvidia-smi &> /dev/null; then
        echo "⚠️  NVIDIA Container Toolkit may not be properly configured"
        echo "   GPU acceleration may not work"
    else
        echo "✅ NVIDIA Container Toolkit is working"
    fi
    
    echo "Current User ID: $(id -u)"
    echo "✅ Target machine requirements check complete"
EOF

echo ""
echo "🎉 Deployment complete!"
echo "=================================================="
echo "📋 Next steps on target machine:"
echo "  1. SSH to target: ssh $TARGET_USER"
echo "  2. Navigate to: cd $TARGET_PATH"
echo "  3. Start production: ./start.sh"
echo "  4. Access OpenHands: http://target-machine:3000"
echo ""
echo "🔧 For development/testing:"
echo "  • Start dev mode: ./start-dev.sh (CPU-only)"
echo "  • Monitor logs: docker compose logs -f"
echo "  • Check status: docker compose ps"
echo ""
echo "🛑 To stop services:"
echo "  • Stop: docker compose down"
echo "  • Cleanup: docker compose down -v --remove-orphans"
