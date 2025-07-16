# Dell Precision 7550

* 6Cores/12Threads
* 64GB RAM
* 1 x NVIDIA Quadro RTX 5000 (16GB VRAM - Turing Architecture)

## Prerequisites - Containerized Inference Workloads

* Install Ubuntu
* Install NVIDIA Driver
* Install Docker
* Install Nvidia Container Toolkit
* Install nvtop

## llama.cpp inference

### Build Container

```bash
cd llama.cpp
docker build -t llama-cpp-turing .
```

### Download DeepSeek-Coder V2 (devstral) Q4 Model

```bash
# Create models directory
mkdir -p models

# Download the Q4_K_M quantized model (recommended for 16GB VRAM)
wget -O models/deepseek-coder-v2-lite-instruct-q4_k_m.gguf \
  https://huggingface.co/bartowski/DeepSeek-Coder-V2-Lite-Instruct-GGUF/resolve/main/DeepSeek-Coder-V2-Lite-Instruct-Q4_K_M.gguf

wget -O models/devstral-q4_k_m.gguf \
  https://huggingface.co/mistralai/Devstral-Small-2507_gguf/resolve/main/Devstral-Small-2507-Q4_K_M.gguf
```

### Run Inference

```bash
# Run container with GPU support and mount models directory
docker run --gpus all -it --rm \
  -v $(pwd)/models:/app/models \
  llama-cpp-turing

# Inside the container, run inference
./llama-server \
  --model /app/models/deepseek-coder-v2-lite-instruct-q4_k_m.gguf \
  --host 0.0.0.0 \
  --port 8080 \
  --ctx-size 8192 \
  --n-gpu-layers -1

# Inside the container, run inference
./llama-server \
  --model /app/models/devstral-q4_k_m.gguf \
  --host 0.0.0.0 \
  --port 8080 \
  --ctx-size 8192 \
  --n-gpu-layers -1



# Or for direct chat interface
./llama-cli \
  --model /app/models/deepseek-coder-v2-lite-instruct-q4_k_m.gguf \
  --ctx-size 8192 \
  --n-gpu-layers -1 \
  --interactive

  # Or for direct chat interface
./llama-cli \
  --model /app/models/devstral-q4_k_m.gguf \
  --ctx-size 8192 \
  --n-gpu-layers -1 \
  --interactive



docker run  --gpus all -v $(pwd)/models:/models -p 8000:8000 ghcr.io/ggml-org/llama.cpp:server -m /models/devstral-q4_k_m.gguf --port 8000 --host 0.0.0.0 -n 512 -c 16384 -np 2 --n-gpu-layers 99
```

### Performance Notes

- The Q4_K_M model should fit comfortably in 16GB VRAM
- Use `--n-gpu-layers -1` to offload all layers to GPU for maximum performance
- Monitor VRAM usage with `nvtop` on the host system