ARG UBUNTU_VERSION=24.04
# This needs to generally match the container host's environment.
ARG CUDA_VERSION=12.6.0
# Target the CUDA build image
ARG BASE_CUDA_DEV_CONTAINER=nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${UBUNTU_VERSION}

ARG BASE_CUDA_RUN_CONTAINER=nvidia/cuda:${CUDA_VERSION}-runtime-ubuntu${UBUNTU_VERSION}

FROM ${BASE_CUDA_DEV_CONTAINER} AS build

# CUDA architecture to build for (defaults to all supported archs)
#ARG CUDA_DOCKER_ARCH=default
# pascal = 61, turing = 75, ampere = 86
ARG CUDA_DOCKER_ARCH=61

RUN apt-get update && \
    apt-get install -y build-essential cmake python3 python3-pip git libcurl4-openssl-dev libgomp1

WORKDIR /app

RUN git clone --recursive https://github.com/ggerganov/llama.cpp.git .

RUN if [ "${CUDA_DOCKER_ARCH}" != "default" ]; then \
    export CMAKE_ARGS="-DCMAKE_CUDA_ARCHITECTURES=${CUDA_DOCKER_ARCH}"; \
    fi && \
    cmake -B build -DGGML_NATIVE=OFF -DGGML_CUDA=ON -DGGML_BACKEND_DL=ON -DGGML_CPU_ALL_VARIANTS=ON -DLLAMA_BUILD_TESTS=OFF ${CMAKE_ARGS} -DCMAKE_EXE_LINKER_FLAGS=-Wl,--allow-shlib-undefined . && \
    cmake --build build --config Release -j$(nproc)

RUN mkdir -p /app/lib && \
    find build -name "*.so" -exec cp {} /app/lib \;

RUN mkdir -p /app/full \
    && cp build/bin/* /app/full \
    && cp *.py /app/full \
    && cp -r gguf-py /app/full \
    && cp -r requirements /app/full \
    && cp requirements.txt /app/full \
    && cp .devops/tools.sh /app/full/tools.sh

## Base image
FROM ${BASE_CUDA_RUN_CONTAINER} AS base

RUN apt-get update \
    && apt-get install -y libgomp1 curl\
    && apt autoremove -y \
    && apt clean -y \
    && rm -rf /tmp/* /var/tmp/* \
    && find /var/cache/apt/archives /var/lib/apt/lists -not -name lock -type f -delete \
    && find /var/cache -type f -delete

COPY --from=build /app/lib/ /app

### Server, Server only
FROM base AS server

ENV LLAMA_ARG_HOST=0.0.0.0

COPY --from=build /app/full/llama-server /app

WORKDIR /app

# Create simple health check script
RUN echo '#!/bin/bash\n\
# Simple health check for llama-server\n\
MODEL_DIR="/models"\n\
MODEL_FILE="${MODEL_FILE:-devstral-q4_k_m.gguf}"\n\
MODEL_PATH="$MODEL_DIR/$MODEL_FILE"\n\
\n\
# Check if model file exists\n\
if [ ! -f "$MODEL_PATH" ]; then\n\
    echo "ERROR: Model file not found at $MODEL_PATH"\n\
    exit 1\n\
fi\n\
\n\
# Check if server is responding\n\
if curl -sf http://localhost:11434/health > /dev/null 2>&1; then\n\
    echo "SERVING: Server ready"\n\
    exit 0\n\
else\n\
    echo "LOADING: Server starting..."\n\
    exit 0\n\
fi\n\
' > /app/health-check.sh && chmod +x /app/health-check.sh

# Create startup script that expects model to exist
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
MODEL_DIR="/models"\n\
MODEL_FILE="${MODEL_FILE:-devstral-q4_k_m.gguf}"\n\
MODEL_PATH="$MODEL_DIR/$MODEL_FILE"\n\
\n\
echo "=== Devstral llama-server Startup ==="\n\
echo "Model file: $MODEL_FILE"\n\
echo "Model path: $MODEL_PATH"\n\
echo ""\n\
\n\
# Check if model exists\n\
if [ ! -f "$MODEL_PATH" ]; then\n\
    echo "❌ Error: Model file not found at $MODEL_PATH"\n\
    echo "   Please ensure the model is downloaded to the host models directory"\n\
    exit 1\n\
fi\n\
\n\
# Validate model file\n\
if [ ! -s "$MODEL_PATH" ]; then\n\
    echo "❌ Error: Model file is empty or corrupted"\n\
    exit 1\n\
fi\n\
\n\
model_size=$(stat -c%s "$MODEL_PATH" 2>/dev/null || echo "0")\n\
if [ $model_size -lt 1073741824 ]; then\n\
    echo "❌ Error: Model file seems too small ($model_size bytes)"\n\
    exit 1\n\
fi\n\
\n\
echo "✅ Model validated successfully"\n\
echo ""\n\
echo "=== Starting llama-server ==="\n\
echo "Model: $MODEL_PATH"\n\
echo "Host: ${LLAMA_ARG_HOST:-0.0.0.0}"\n\
echo "Port: ${LLAMA_ARG_PORT:-11434}"\n\
echo "Context Size: ${LLAMA_ARG_CTX_SIZE:-131072} tokens"\n\
echo "GPU Layers: ${LLAMA_ARG_N_GPU_LAYERS:--1}"\n\
echo "Parallel Streams: ${LLAMA_ARG_PARALLEL:-2}"\n\
echo ""\n\
\n\
# Build server arguments from environment variables\n\
SERVER_ARGS=()\n\
\n\
# Model path (required)\n\
SERVER_ARGS+=("--model" "$MODEL_PATH")\n\
\n\
# Network settings\n\
SERVER_ARGS+=("--host" "${LLAMA_ARG_HOST:-0.0.0.0}")\n\
SERVER_ARGS+=("--port" "${LLAMA_ARG_PORT:-11434}")\n\
\n\
# Context and GPU settings\n\
SERVER_ARGS+=("--ctx-size" "${LLAMA_ARG_CTX_SIZE:-131072}")\n\
SERVER_ARGS+=("--n-gpu-layers" "${LLAMA_ARG_N_GPU_LAYERS:--1}")\n\
SERVER_ARGS+=("--threads" "${LLAMA_ARG_THREADS:-6}")\n\
\n\
# Batch settings\n\
SERVER_ARGS+=("--batch-size" "${LLAMA_ARG_BATCH_SIZE:-4096}")\n\
SERVER_ARGS+=("--ubatch-size" "${LLAMA_ARG_UBATCH_SIZE:-2048}")\n\
\n\
# Performance features\n\
if [ "${LLAMA_ARG_FLASH_ATTN:-1}" = "1" ]; then\n\
    SERVER_ARGS+=("--flash-attn")\n\
fi\n\
\n\
if [ "${LLAMA_ARG_CONT_BATCHING:-1}" = "1" ]; then\n\
    SERVER_ARGS+=("--cont-batching")\n\
fi\n\
\n\
SERVER_ARGS+=("--parallel" "${LLAMA_ARG_PARALLEL:-2}")\n\
\n\
# Debug: Show all arguments being passed\n\
echo "=== Debug: llama-server arguments ==="\n\
echo "Full command: /app/llama-server ${SERVER_ARGS[@]}"\n\
echo "GPU Layers argument: --n-gpu-layers ${LLAMA_ARG_N_GPU_LAYERS:--1}"\n\
echo "==================================="\n\
\n\
# Start the server with proper arguments\n\
exec /app/llama-server "${SERVER_ARGS[@]}" "$@"\n\
' > /app/start-server.sh && chmod +x /app/start-server.sh

HEALTHCHECK CMD [ "/app/health-check.sh" ]

ENTRYPOINT [ "/app/start-server.sh" ]
