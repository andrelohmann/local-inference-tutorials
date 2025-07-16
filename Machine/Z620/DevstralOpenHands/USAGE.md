# Usage G3. **Access the interfaces**:
   - OpenHands: http://localhost:3000
   - llama.cpp API: http://localhost:11434e

## Quick Start

1. **Start the services** (model downloads automatically):
   ```bash
   ./start.sh
   ```

2. **Access the interfaces**:
   - OpenHands: http://localhost:3000
   - llama.cpp API: http://localhost:8080

3. **Monitor model download** (first run only):
   ```bash
   docker-compose logs -f llama-cpp-server
   ```

## Manual Steps

### 1. Pull Required Images
```bash
# Pull OpenHands runtime container (required)
docker pull docker.all-hands.dev/all-hands-ai/runtime:0.48-nikolaik

# Pull OpenHands main container
docker pull docker.all-hands.dev/all-hands-ai/openhands:0.48
```

### 2. Build and Start Services
```bash
# Build containers and start services
docker-compose up --build -d

# Monitor logs (including model download)
docker-compose logs -f
```

### 3. Verify Services
```bash
# Check service status
docker-compose ps

# Test llama.cpp server
curl http://localhost:11434/health

# Test model loading
curl http://localhost:11434/v1/models
```

## Model Management

The model is automatically downloaded on first startup and stored in `./models/devstral-q4_k_m.gguf`.

### Manual Model Download
If you want to download the model manually:
```bash
# Download Devstral model manually
mkdir -p models
wget -O models/devstral-q4_k_m.gguf \
  https://huggingface.co/mistralai/Devstral-Small-2507_gguf/resolve/main/Devstral-Small-2507-Q4_K_M.gguf
```

## Configuration

### GPU Settings
Edit `.env` file to modify GPU settings:
```env
CUDA_DOCKER_ARCH=61          # Pascal architecture
LLAMA_N_GPU_LAYERS=35        # Number of layers to run on GPU
LLAMA_CTX_SIZE=4096          # Context size
LLAMA_PARALLEL=4             # Parallel processing slots
```

### Model Settings
```env
MODEL_NAME=devstral-q4_k_m.gguf
LLAMA_THREADS=6              # CPU threads
LLAMA_BATCH_SIZE=512         # Batch size
```

## Troubleshooting

### Common Issues

1. **Model not found or download failed**:
   - Check container logs: `docker-compose logs -f llama-cpp-server`
   - Verify internet connectivity
   - Try manual download (see Model Management section)
   - Check available disk space

2. **GPU not detected**:
   - Verify NVIDIA drivers: `nvidia-smi`
   - Check Docker GPU support: `docker run --rm --gpus all nvidia/cuda:12.6.0-base-ubuntu24.04 nvidia-smi`
   - Install NVIDIA Container Toolkit

3. **Service startup failure**:
   - Check logs: `docker-compose logs service-name`
   - Verify resource availability (RAM, GPU memory)
   - Check if ports are available

4. **OpenHands can't connect to llama.cpp**:
   - Verify network connectivity: `docker-compose exec openhands ping llama-cpp-server`
   - Check llama.cpp health: `curl http://localhost:11434/health`
   - Review OpenHands configuration

### Debug Commands

```bash
# Check service logs
docker-compose logs -f llama-cpp-server
docker-compose logs -f openhands

# Enter container for debugging
docker-compose exec llama-cpp-server /bin/bash
docker-compose exec openhands /bin/bash

# Check GPU usage
docker-compose exec llama-cpp-server nvidia-smi

# Test model loading manually
docker-compose exec llama-cpp-server /app/llama-server --model /models/devstral-q4_k_m.gguf --host 0.0.0.0 --port 11434
```

## Performance Tuning

### For Pascal Architecture (Quadro P4000/P5000)

1. **Memory Optimization**:
   - Reduce `LLAMA_CTX_SIZE` if running out of VRAM
   - Adjust `LLAMA_N_GPU_LAYERS` based on available VRAM
   - Use `LLAMA_BATCH_SIZE=256` for lower memory usage

2. **Performance Settings**:
   - Set `LLAMA_THREADS` to match CPU cores (6 for Z620)
   - Use `LLAMA_PARALLEL=2` for better throughput
   - Enable `LLAMA_FLASH_ATTN=1` for faster attention

3. **Model Selection**:
   - Use Q4_K_M quantization for balance of speed/quality
   - Consider Q5_K_M for better quality with more VRAM
   - Use Q8_0 only if you have sufficient VRAM (16GB+)

## API Usage

### Direct llama.cpp API
```bash
# Generate text
curl -X POST http://localhost:11434/completion \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Write a Python function to sort a list:", "n_predict": 100}'

# Chat completion
curl -X POST http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "Hello!"}], "temperature": 0.7}'
```

### OpenHands Integration
- Access via web interface at http://localhost:3000
- Configure model parameters in OpenHands settings
- Use for code generation, debugging, and development tasks

## Maintenance

### Regular Tasks
```bash
# Update containers
docker-compose pull
docker-compose up --build

# Clean up old containers
docker system prune

# Backup models
tar -czf models-backup.tar.gz models/

# Monitor disk usage
du -sh models/ workspace/
```

### Log Management
```bash
# View logs
docker-compose logs --tail=100 -f

# Clear logs
docker-compose down
docker system prune -f
```
