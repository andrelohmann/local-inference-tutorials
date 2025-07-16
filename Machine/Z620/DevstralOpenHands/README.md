# Devstral + OpenHands Development Environment

This project provides a complete development environment for running Devstral with OpenHands, supporting both development (CPU-only) and production (GPU-accelerated) deployments.

## Important Notes

⚠️ **Hardware Requirements**: The main `docker-compose.yml` file is designed for production hardware with NVIDIA GPUs. For development on machines without proper GPU support, use `docker-compose.dev.yml`.

⚠️ **Workspace Configuration**: OpenHands uses the modern `SANDBOX_VOLUMES` configuration (the `WORKSPACE_*` variables are deprecated).

## Quick Start

### Development (CPU-only)
```bash
# Use the development startup script (handles user ID automatically)
./start-dev.sh

# Or manually:
export SANDBOX_USER_ID=$(id -u)
docker compose -f docker-compose.dev.yml up -d
```

### Production (GPU-accelerated)
```bash
# Use the production startup script (handles user ID automatically)
./start.sh

# Or manually:
export SANDBOX_USER_ID=$(id -u)
docker compose up -d
```

## Remote Deployment

### Target Machine Requirements
- NVIDIA GPU with Pascal architecture or newer
- NVIDIA Container Toolkit installed
- Docker Compose V2
- At least 8GB VRAM for full model loading

### Deployment Steps
1. **Copy configuration to target machine**:
   ```bash
   scp -r ./Machine/Z620/DevstralOpenHands user@target-machine:~/
   ```

2. **On target machine, run**:
   ```bash
   cd ~/DevstralOpenHands
   ./start.sh  # User ID will be automatically detected
   ```

### User ID Detection
The startup scripts automatically detect the current user ID using `$(id -u)` and set the `SANDBOX_USER_ID` environment variable accordingly. This ensures proper file permissions in the OpenHands sandbox environment.

## Configuration

### Environment Variables

All configuration is managed through the `.env` file. The docker-compose files use environment variables **without default values** to ensure `.env` file values take precedence.

#### Model Configuration
- `LLAMA_ARG_MODEL`: Path to the model file inside the container
- `LLAMA_ARG_CTX_SIZE`: Context window size (128k tokens for Devstral)
- `LLAMA_ARG_N_GPU_LAYERS`: Number of layers on GPU (-1 = all, 0 = CPU-only)

#### Performance Settings
- `LLAMA_ARG_THREADS`: CPU threads for processing
- `LLAMA_ARG_BATCH_SIZE`: Batch size for prompt processing
- `LLAMA_ARG_UBATCH_SIZE`: Micro-batch size for generation

#### OpenHands Configuration (Modern Approach)
- `SANDBOX_VOLUMES`: Workspace mount configuration (replaces deprecated WORKSPACE_*)
- `SANDBOX_USER_ID`: User ID for sandbox environment (automatically detected at runtime)
- `OPENHANDS_VERSION`: OpenHands container version
- `OPENHANDS_RUNTIME_VERSION`: Runtime container version
- `OPENHANDS_LLM_MODEL`: Model identifier for OpenHands
- `OPENHANDS_LLM_BASE_URL`: Base URL for llama.cpp server

### Configuration Validation

The configuration follows the latest OpenHands documentation:
- ✅ Uses `SANDBOX_VOLUMES` instead of deprecated `WORKSPACE_*` variables
- ✅ Automatically detects `SANDBOX_USER_ID` at runtime using `$(id -u)`
- ✅ Properly configured for Docker runtime with socket mounting
- ✅ Separate configurations for development and production environments

### Workspace Configuration

OpenHands uses the modern `SANDBOX_VOLUMES` approach for mounting your workspace:

```bash
# In .env file
SANDBOX_VOLUMES=$PWD/workspace:/workspace:rw
SANDBOX_USER_ID=1000
```

This mounts your local `./workspace` directory to `/workspace` inside the container with read-write access.

## File Structure

- `docker-compose.yml` - Production configuration (GPU-accelerated)
- `docker-compose.dev.yml` - Development configuration (CPU-only)
- `Dockerfile` - Multi-stage build for llama.cpp server
- `.env` - Environment variables configuration
- `workspace/` - Your working directory (mounted into OpenHands)
- `openhands-logs/` - OpenHands logs directory

## GPU Architecture Support

The setup supports multiple NVIDIA GPU architectures by configuring `CUDA_DOCKER_ARCH` in `.env`:
- **Pascal (61)**: GTX 10xx, Quadro P series (default for Z620)
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

## 📊 Enhanced Download & Startup Process

The system provides a streamlined workflow with better user experience:

### Host-based Model Download
- **Location**: Downloads to `~/.models/` directory in user's home
- **Progress Monitoring**: Real-time wget progress with speed and ETA
- **Resumable**: Supports interrupted downloads with `--continue`
- **Validation**: Checks file integrity before container startup
- **Shared**: Models can be reused across multiple projects

### Fast Container Startup
- **Immediate Start**: Containers start as soon as model is ready
- **No Waiting**: No timeout issues during download
- **Health Checks**: Simple validation that model exists and server responds
- **Better Error Handling**: Clear separation between download and runtime issues

### Monitoring Tools
1. **Download Progress**: `./monitor-download.sh` - Real-time progress with speed and ETA
2. **Health Status**: `./monitor-health.sh` - Service health monitoring
3. **Container Logs**: `docker compose logs -f` - Detailed container output

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
- **CUDA Architecture**: 61 (Pascal) - configurable via `CUDA_DOCKER_ARCH`
- **Memory**: Automatically configured based on available VRAM
- **Compute Mode**: Optimized for inference workloads

### Model Settings
- **Model**: Devstral (automatically downloaded)
- **Context Length**: 128k tokens (configurable via `LLAMA_ARG_CTX_SIZE`)
- **Concurrency**: 2 parallel streams (configurable via `LLAMA_ARG_PARALLEL`)
- **Batch Size**: Optimized for Pascal architecture
- **GPU Acceleration**: Partial layers on GPU (configurable via `LLAMA_ARG_N_GPU_LAYERS`)

### Performance Features
- **Flash Attention**: Enabled for faster processing
- **Continuous Batching**: Enabled for better throughput
- **Dual Concurrent Streams**: Support for 2 simultaneous requests
- **Full Context Window**: 128k tokens for long-context understanding

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

## Deployment Automation

### Automated Deployment Script

Use the `deploy.sh` script to automatically deploy the configuration to your target machine:

```bash
# Deploy to target machine
./deploy.sh user@target-machine

# Deploy to custom path
./deploy.sh -p /opt/devstral user@production-server
```

The deployment script will:
1. ✅ Test SSH connection to target machine
2. 📁 Copy all configuration files
3. 🔐 Set proper file permissions
4. 🔍 Check target machine requirements (Docker, NVIDIA toolkit)
5. 📋 Provide next steps for startup

### Manual Deployment

If you prefer manual deployment:

```bash
# Copy configuration to target machine
scp -r ./Machine/Z620/DevstralOpenHands user@target-machine:~/

# SSH to target machine
ssh user@target-machine

# Navigate to deployment directory
cd ~/DevstralOpenHands

# Set permissions
chmod +x start.sh start-dev.sh monitor-*.sh

# Start services
./start.sh
```