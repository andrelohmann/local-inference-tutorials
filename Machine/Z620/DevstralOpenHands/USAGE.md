# Usage Guide

## 🚀 Quick Start

1. **Start the complete setup** (downloads model if needed):
   ```bash
   ./start.sh
   ```

2. **Monitor download progress** (if downloading):
   ```bash
   ./monitor-download.sh
   ```

3. **Monitor service health**:
   ```bash
   ./monitor-health.sh
   ```

4. **Check container logs**:
   ```bash
   docker compose logs -f llama-cpp-server
   ```

5. **Stop services**:
   ```bash
   docker compose down
   ```

## 🔍 Debugging Tools

### Quick Health Check
```bash
./debug-health.sh
```

### Simple Startup (for testing)
```bash
./start-simple.sh
```

### Manual Container Start
```bash
docker compose up -d
```

## 📊 New Workflow

### Model Download (Host-based)
- **Location**: Downloads to `~/.models/` in user's home directory
- **Progress**: Full wget progress with speed and ETA
- **Monitoring**: `./monitor-download.sh` shows real-time progress
- **Resumable**: Supports interrupted downloads with `--continue`
- **Shared**: Models can be used across multiple projects

### Container Startup
- **Fast startup**: Containers start immediately when model is ready
- **Health checks**: Simple validation that model exists and server responds
- **No timeouts**: No waiting for downloads in containers

### Service Communication
- **Immediate availability**: OpenHands starts as soon as llama.cpp is ready
- **Better error handling**: Clear separation between download and runtime issues

## 🔧 Manual Operations

### Check Service Status
```bash
docker compose ps
```

### View Container Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f llama-cpp-server
docker compose logs -f openhands
```

### Manual Health Check
```bash
docker exec llama-cpp-devstral /app/health-check.sh
```

### Test llama.cpp API
```bash
curl http://localhost:11434/health
```

## 📁 File Structure

```
./
├── ~/.models/             # Model files in user home (shared across projects)
│   └── devstral-q4_k_m.gguf
├── workspace/             # OpenHands workspace
├── docker-compose.yml     # Service definitions
├── Dockerfile            # llama.cpp container
├── .env                  # Configuration
├── start.sh              # Main startup script
├── monitor-download.sh   # Download progress monitor
└── monitor-health.sh     # Health status monitor
```

## 🌐 Access Points

- **OpenHands Interface**: http://localhost:3000
- **llama.cpp API**: http://localhost:11434
- **Health Check**: http://localhost:11434/health

## 🛠️ Troubleshooting

### Common Issues

1. **Download fails**:
   - Check internet connection
   - Verify disk space (need ~15GB free)
   - Download will resume automatically with `--continue`

2. **Container won't start**:
   - Ensure model file exists in `~/.models/`
   - Check Docker and NVIDIA runtime
   - Verify ports 3000 and 11434 are available

3. **GPU not detected**:
   - Verify NVIDIA drivers: `nvidia-smi`
   - Check Docker GPU support: `docker run --rm --gpus all nvidia/cuda:12.6.0-base-ubuntu24.04 nvidia-smi`
   - Install NVIDIA Container Toolkit

4. **Service startup failure**:
   - Check logs: `docker compose logs service-name`
   - Verify resource availability (RAM, GPU memory)
   - Check if ports are available

5. **OpenHands can't connect to llama.cpp**:
   - Verify llama.cpp is serving: `curl http://localhost:11434/health`
   - Check network connectivity between containers
   - Ensure model is fully loaded

### Log Analysis

**Normal startup sequence**:
1. Model validation
2. llama.cpp server startup
3. Model loading into GPU
4. Health check passes
5. OpenHands connects

**Common error patterns**:
- "Model file not found" → Run download first
- "CUDA out of memory" → Reduce GPU layers or batch size
- "Port already in use" → Change ports in .env file
