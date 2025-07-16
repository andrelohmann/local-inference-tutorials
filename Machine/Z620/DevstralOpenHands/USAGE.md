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
   docker compose logs -f llama-cpp-server
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
docker compose up --build -d

# Monitor logs (including model download)
docker compose logs -f
```

### 3. Verify Services
```bash
# Check service status
docker compose ps

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
CUDA_DOCKER_ARCH=61          # Pascal=61, Turing=75, Ampere=86, Ada=89, Hopper=90
LLAMA_ARG_N_GPU_LAYERS=35    # Number of layers to run on GPU (-1 = all layers)
```

### Context and Memory Configuration
```env
LLAMA_ARG_CTX_SIZE=131072     # Context window size (131072 = 128k tokens)
LLAMA_ARG_BATCH_SIZE=2048     # Batch size for prompt processing (higher = faster, more VRAM)
LLAMA_ARG_UBATCH_SIZE=512     # Micro-batch size for generation (lower = less VRAM)
```

### Performance and Concurrency
```env
LLAMA_ARG_THREADS=6           # CPU threads (match your CPU cores)
LLAMA_ARG_PARALLEL=2          # Parallel processing slots (2 = dual concurrent streams)
LLAMA_ARG_FLASH_ATTN=1        # Flash attention (1=on, 0=off) - faster processing
LLAMA_ARG_CONT_BATCHING=1     # Continuous batching (1=on, 0=off) - better throughput
```

### Parameter Explanations

#### Context Window (`LLAMA_ARG_CTX_SIZE`)
- **4096**: Small context, fast processing, low VRAM usage
- **32768**: Medium context (32k tokens), balanced performance
- **131072**: Full Devstral context (128k tokens), high VRAM usage
- **Higher values**: Better long-context understanding but require more VRAM

#### GPU Layers (`LLAMA_ARG_N_GPU_LAYERS`)
- **-1**: All layers on GPU (fastest, highest VRAM usage)
- **35**: Partial GPU acceleration (balanced)
- **0**: CPU only (slowest, no GPU VRAM needed)
- **Adjust based on available VRAM**: More layers = faster but more VRAM

#### Batch Sizes
- **BATCH_SIZE**: Prompt processing batch size
  - Higher = faster prompt processing but more VRAM
  - Lower = slower but less VRAM usage
- **UBATCH_SIZE**: Generation micro-batch size
  - Lower = less VRAM during generation
  - Higher = faster generation but more VRAM

#### Parallel Processing (`LLAMA_ARG_PARALLEL`)
- **1**: Single request processing
- **2**: Dual concurrent streams (your requirement)
- **4**: Quad concurrent streams (high VRAM usage)
- **Higher values**: More concurrent users but exponentially more VRAM

#### Flash Attention (`LLAMA_ARG_FLASH_ATTN`)
- **1**: Enabled - faster attention computation, less VRAM
- **0**: Disabled - slower but more compatible

#### Continuous Batching (`LLAMA_ARG_CONT_BATCHING`)
- **1**: Enabled - better throughput for multiple requests
- **0**: Disabled - simpler processing, lower throughput

### Architecture Override
To use a different GPU architecture, update the `CUDA_DOCKER_ARCH` in `.env`:
```env
# For RTX 30xx series (Ampere)
CUDA_DOCKER_ARCH=86

# For RTX 40xx series (Ada Lovelace)
CUDA_DOCKER_ARCH=89

# For RTX 20xx series (Turing)
CUDA_DOCKER_ARCH=75
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
   - Check container logs: `docker compose logs -f llama-cpp-server`
   - Verify internet connectivity
   - Try manual download (see Model Management section)
   - Check available disk space

2. **GPU not detected**:
   - Verify NVIDIA drivers: `nvidia-smi`
   - Check Docker GPU support: `docker run --rm --gpus all nvidia/cuda:12.6.0-base-ubuntu24.04 nvidia-smi`
   - Install NVIDIA Container Toolkit

3. **Service startup failure**:
   - Check logs: `docker compose logs service-name`
   - Verify resource availability (RAM, GPU memory)
   - Check if ports are available

4. **OpenHands can't connect to llama.cpp**:
   - Verify network connectivity: `docker compose exec openhands ping llama-cpp-server`
   - Check llama.cpp health: `curl http://localhost:11434/health`
   - Review OpenHands configuration

### Debug Commands

```bash
# Check service logs
docker compose logs -f llama-cpp-server
docker compose logs -f openhands

# Enter container for debugging
docker compose exec llama-cpp-server /bin/bash
docker compose exec openhands /bin/bash

# Check GPU usage
docker compose exec llama-cpp-server nvidia-smi

# Test model loading manually
docker compose exec llama-cpp-server /app/llama-server --model /models/devstral-q4_k_m.gguf --host 0.0.0.0 --port 11434
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

### VRAM Usage Estimation (Pascal Architecture)

For your Quadro P4000 (8GB) and P5000 (16GB) setup:

#### 128k Context Configuration
```env
LLAMA_ARG_CTX_SIZE=131072     # 128k tokens
LLAMA_ARG_PARALLEL=2          # 2 concurrent streams
LLAMA_ARG_N_GPU_LAYERS=35     # Partial GPU acceleration
```

**Estimated VRAM Usage:**
- **Model (Q4_K_M)**: ~4.5GB
- **128k Context (2 streams)**: ~8-10GB
- **Total**: ~12-14GB

**Recommendations:**
- **Single P5000 (16GB)**: Can handle 128k context with 2 streams
- **P4000 + P5000 (24GB total)**: Ideal for full GPU acceleration
- **If VRAM limited**: Reduce context size or parallel streams

#### Alternative Configurations

**Medium Context (32k tokens):**
```env
LLAMA_ARG_CTX_SIZE=32768      # 32k tokens
LLAMA_ARG_PARALLEL=2          # 2 concurrent streams
LLAMA_ARG_N_GPU_LAYERS=-1     # All layers on GPU
```
**VRAM Usage**: ~8-10GB (fits on P5000)

**Conservative Setup (P4000 only):**
```env
LLAMA_ARG_CTX_SIZE=16384      # 16k tokens
LLAMA_ARG_PARALLEL=2          # 2 concurrent streams
LLAMA_ARG_N_GPU_LAYERS=25     # Reduced GPU layers
```
**VRAM Usage**: ~6-7GB (fits on P4000)

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
docker compose pull
docker compose up --build

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
docker compose logs --tail=100 -f

# Clear logs
docker compose down
docker system prune -f
```
