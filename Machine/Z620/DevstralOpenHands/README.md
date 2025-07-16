# Devstral and OpenHands with llama.cpp

This Docker Compose setup provides an integrated environment for running Devstral model inference with OpenHands, specifically optimized for NVIDIA Pascal architecture (Quadro P4000/P5000).

## Overview

The setup consists of two main services:
1. **llama-cpp-server**: Custom-built llama.cpp server optimized for Pascal architecture with automatic Devstral model download on startup
2. **openhands**: All-hands/OpenHands container configured to use the llama.cpp server

## Architecture

- **Target GPU**: NVIDIA Pascal (Compute Capability 6.1)
- **Hardware**: HP Z620 with Quadro P4000 (8GB) and P5000 (16GB)
- **Model**: Devstral (automatically downloaded on first startup)
- **Inference Engine**: llama.cpp with CUDA support

## Implementation Plan

### Phase 1: llama.cpp Container Setup
1. **Custom Dockerfile Enhancement**
   - Build llama.cpp with Pascal architecture optimization (CUDA_DOCKER_ARCH=61)
   - Add automatic model download capability integrated into container startup
   - Configure server mode with proper networking

2. **Model Management**
   - Implement automatic Devstral model download on first container start
   - Configure model storage and caching in persistent volume
   - Add model validation checks

### Phase 2: OpenHands Integration
1. **Container Configuration**
   - Set up all-hands/OpenHands container
   - Configure network connectivity between services
   - Set up shared volumes for model access

2. **Service Communication**
   - Configure OpenHands to use llama.cpp server endpoint
   - Set up proper API communication
   - Configure model parameters and settings

### Phase 3: Docker Compose Orchestration
1. **Streamlined Setup**
   - Create docker-compose.yml with integrated model download
   - Configure service dependencies with health checks
   - Set up shared networks and volumes

2. **Environment Configuration**
   - Configure NVIDIA runtime support
   - Set up proper environment variables
   - Configure resource limits and GPU access

### Phase 4: Deployment and Testing
1. **One-Command Startup**
   - Single command starts everything including model download
   - Add health checks for both services
   - Configure automatic restart policies

2. **Documentation**
   - Add usage instructions
   - Document configuration options
   - Provide troubleshooting guide

## Quick Start

```bash
# Start everything (downloads model automatically on first run)
./start.sh

# Or manually:
docker compose up --build

# Access OpenHands interface
http://localhost:3000

# Access llama.cpp server directly
http://localhost:11434
```

## Configuration

### GPU Settings
- **CUDA Architecture**: 61 (Pascal)
- **Memory**: Automatically configured based on available VRAM
- **Compute Mode**: Optimized for inference workloads

### Model Settings
- **Model**: Devstral (automatically downloaded)
- **Context Length**: Configurable via environment variables
- **Batch Size**: Optimized for Pascal architecture

## Prerequisites

- Docker with NVIDIA Container Toolkit
- NVIDIA drivers installed
- Sufficient disk space for model files (~4-8GB)
- GPU with Pascal architecture support

## Implementation Details

### File Structure
```
DevstralOpenHands/
├── docker-compose.yml          # Main orchestration file (simplified)
├── Dockerfile                  # Custom llama.cpp build with integrated model download
├── .env                        # Environment configuration
├── .gitignore                  # Git ignore patterns
├── start.sh                    # Easy startup script
├── download-model.sh           # Manual model download script (optional)
├── USAGE.md                    # Detailed usage guide
├── models/                     # Model storage (auto-created)
│   └── devstral-q4_k_m.gguf   # Downloaded automatically on first run
├── workspace/                  # OpenHands workspace
│   └── .gitkeep
└── README.md                   # This file
```

### Services Configuration

#### llama-cpp-server
- **Base**: Custom Dockerfile with Pascal architecture support
- **GPU**: NVIDIA Pascal (Compute Capability 6.1)
- **Port**: 11434
- **Features**: 
  - Automatic model download on first startup
  - Health checks
  - Optimized for Quadro P4000/P5000
  - CUDA acceleration
  - Integrated startup script

#### openhands
- **Image**: Official all-hands/OpenHands container (v0.48)
- **Runtime**: Nikolaik runtime container for enhanced compatibility
- **Port**: 3000
- **Integration**: Configured to use llama-cpp-server
- **Features**:
  - Web-based interface
  - Code generation and debugging
  - Docker integration
  - Full event logging
  - Host network access for containerized workflows

### Key Features

1. **Pascal Architecture Optimization**
   - CUDA_DOCKER_ARCH=61 for optimal performance
   - Memory-efficient configuration
   - GPU layer distribution optimization

2. **Streamlined Model Management**
   - Downloads Devstral model automatically on first container start
   - Validates model integrity
   - Persistent storage in mounted volume
   - No separate downloader service needed

3. **Simplified Service Integration**
   - Two-service architecture instead of three
   - Health checks ensure proper startup sequence
   - Network isolation with inter-service communication
   - Shared volumes for model and workspace data

4. **Development-Ready**
   - One-command startup
   - Easy debugging and log access
   - Configurable parameters

## OpenHands Runtime Requirements

This setup uses the official OpenHands v0.48 configuration with the following components:

### Required Images
- **OpenHands Main**: `docker.all-hands.dev/all-hands-ai/openhands:0.48`
- **Runtime Container**: `docker.all-hands.dev/all-hands-ai/runtime:0.48-nikolaik`

### Configuration Features
- **Event Logging**: Full event logging enabled (`LOG_ALL_EVENTS=true`)
- **Runtime Container**: Uses nikolaik runtime for enhanced compatibility
- **Host Integration**: Proper host network access for containerized workflows
- **Docker Socket**: Mounted for container management within OpenHands
- **Config Persistence**: OpenHands configuration persisted in `~/.openhands`

## Implementation Status

### ✅ Phase 1: llama.cpp Container Setup
- [x] Custom Dockerfile with Pascal optimization
- [x] Integrated model download capability in container startup
- [x] Server mode configuration
- [x] Health checks and monitoring

### ✅ Phase 2: OpenHands Integration
- [x] Container configuration
- [x] Network connectivity setup
- [x] Shared volumes for model access
- [x] Service communication configuration

### ✅ Phase 3: Docker Compose Orchestration
- [x] Streamlined two-service setup
- [x] Service dependencies with health checks
- [x] Shared networks and volumes
- [x] Environment configuration

### ✅ Phase 4: Deployment and Testing
- [x] One-command startup
- [x] Integrated health checks
- [x] Documentation
- [x] Usage guide