# Devstral + OpenHands Production Environment

This project provides a production environment for running Devstral with OpenHands on GPU-accelerated hardware.

## Important Notes

⚠️ **Hardware Requirements**: This configuration requires NVIDIA GPUs with proper driver support and NVIDIA Container Toolkit.

⚠️ **Workspace Configuration**: OpenHands uses the modern `SANDBOX_VOLUMES` configuration (the `WORKSPACE_*` variables are deprecated).

## Quick Start

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
- Git (for cloning the repository)

### Deployment Steps
1. **Clone repository on target machine**:
   ```bash
   git clone https://github.com/andrelohmann/local-inference-tutorials.git
   cd local-inference-tutorials/Machine/Z620/DevstralOpenHands
   ```

2. **Start the services**:
   ```bash
   ./start.sh  # User ID will be automatically detected
   ```

### User ID Detection
The startup script automatically detects the current user ID using `$(id -u)` and sets the `SANDBOX_USER_ID` environment variable accordingly. This ensures proper file permissions in the OpenHands sandbox environment.

## Configuration

### Environment Variables

All configuration is managed through the `.env` file. The docker-compose files use environment variables **without default values** to ensure `.env` file values take precedence.

#### Model Configuration
- `LLAMA_ARG_MODEL`: Path to the model file inside the container
- `LLAMA_ARG_CTX_SIZE`: Context window size (128k tokens for Devstral)
- `LLAMA_ARG_N_GPU_LAYERS`: Number of layers on GPU (-1 = all, 0 = CPU-only)

#### GPU Configuration
- `NVIDIA_VISIBLE_DEVICES`: Control which GPUs are available
  - `all` - Use all available GPUs (default)
  - `0` - Use only GPU 0
  - `1` - Use only GPU 1  
  - `0,1` - Use GPUs 0 and 1
  - `none` - Disable GPU usage (CPU-only mode)
- `NVIDIA_DRIVER_CAPABILITIES`: Driver capabilities (usually `compute,utility`)

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
- ✅ Optimized for GPU-accelerated production environments

### Workspace Configuration

OpenHands uses the modern `SANDBOX_VOLUMES` approach for mounting your workspace:

```bash
# In .env file
SANDBOX_VOLUMES=$PWD/workspace:/workspace:rw
```

This mounts your local `./workspace` directory to `/workspace` inside the container with read-write access. The `SANDBOX_USER_ID` is automatically detected at runtime.

## File Structure

- `docker-compose.yml` - Service configuration (GPU-accelerated)
- `Dockerfile` - Multi-stage build for llama.cpp server
- `.env` - Environment variables configuration
- `start.sh` - Production startup script
- `test-config.sh` - System configuration verification script
- `workspace/` - Your working directory (mounted into OpenHands)
- `openhands-logs/` - OpenHands logs directory

### External Dependencies
- **~/.models/** - Model storage (shared across projects)
- **Docker & NVIDIA Container Toolkit** - Runtime dependencies

## GPU Architecture Support

The setup supports multiple NVIDIA GPU architectures by configuring `CUDA_DOCKER_ARCH` in `.env`:
- **Pascal (61)**: GTX 10xx, Quadro P series (configured for Z620)
- **Turing (75)**: RTX 20xx, GTX 16xx series  
- **Ampere (86)**: RTX 30xx, A40, A100 series
- **Ada (89)**: RTX 40xx series
- **Hopper (90)**: H100, H200 series

The production configuration includes:
- ✅ **NVIDIA Runtime**: Enabled in docker-compose.yml
- ✅ **CUDA Support**: llama.cpp compiled with CUDA backend
- ✅ **GPU Detection**: Automatic GPU layer offloading (-1 = all layers)
- ✅ **Memory Management**: Optimized batch sizes for GPU memory
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
- **Download Progress**: Built into `start.sh` script with real-time progress
- **Service Status**: `docker compose ps` - Check service status
- **Service Logs**: `docker compose logs -f` - Real-time container logs
- **Health Check**: `curl http://localhost:11434/health` - API health check

## Access Points

- **OpenHands Interface**: http://localhost:3000
- **llama.cpp API**: http://localhost:11434
- **Health Check**: http://localhost:11434/health

## Implementation Status

### ✅ Complete Setup
- [x] Custom Dockerfile with Pascal optimization
- [x] Integrated model download capability
- [x] Service health checks and monitoring
- [x] OpenHands integration with modern configuration
- [x] Streamlined Docker Compose orchestration
- [x] One-command startup with documentation

## Troubleshooting

### GPU Not Detected
If you see "no usable GPU found" in the logs:

1. **Check NVIDIA Docker support**:
   ```bash
   # Test NVIDIA runtime
   docker run --rm --runtime=nvidia nvidia/cuda:12.6.0-base-ubuntu24.04 nvidia-smi
   ```

2. **Verify GPU visibility**:
   ```bash
   # Should show your GPU(s)
   nvidia-smi
   ```

3. **Check Docker configuration**:
   ```bash
   # Should show nvidia runtime
   docker info | grep -i runtime
   ```

4. **Test GPU configuration**:
   ```bash
   # Run the configuration test
   ./test-config.sh
   ```

### GPU Selection
Configure which GPUs to use by editing `.env`:

```bash
# Use all GPUs (default)
NVIDIA_VISIBLE_DEVICES=all

# Use only first GPU
NVIDIA_VISIBLE_DEVICES=0

# Use specific GPUs
NVIDIA_VISIBLE_DEVICES=0,1

# Disable GPU (CPU-only)
NVIDIA_VISIBLE_DEVICES=none
```

### User Permission Issues
If you see permission errors for `/logs` or `/.openhands`:

1. **Check user ID**:
   ```bash
   # Should match the user running the container
   echo $SANDBOX_USER_ID
   id -u
   ```

2. **Fix permissions**:
   ```bash
   # Create and fix ownership
   mkdir -p openhands-logs workspace
   sudo chown -R $(id -u):$(id -g) openhands-logs workspace
   ```

### Common Solutions
- **NVIDIA Container Toolkit**: Install from https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html
- **Docker restart**: `sudo systemctl restart docker` after installing NVIDIA toolkit
- **Container rebuild**: `docker compose down && docker compose up --build -d`