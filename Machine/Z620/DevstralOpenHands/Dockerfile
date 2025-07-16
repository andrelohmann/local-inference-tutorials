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

### Full
FROM base AS full

COPY --from=build /app/full /app

WORKDIR /app

RUN apt-get update \
    && apt-get install -y \
    git \
    python3 \
    python3-pip \
    && pip install --upgrade pip setuptools wheel \
    && pip install -r requirements.txt \
    && apt autoremove -y \
    && apt clean -y \
    && rm -rf /tmp/* /var/tmp/* \
    && find /var/cache/apt/archives /var/lib/apt/lists -not -name lock -type f -delete \
    && find /var/cache -type f -delete


ENTRYPOINT ["/app/tools.sh"]

### Light, CLI only
FROM base AS light

COPY --from=build /app/full/llama-cli /app

WORKDIR /app

ENTRYPOINT [ "/app/llama-cli" ]

### Server, Server only
FROM base AS server

ENV LLAMA_ARG_HOST=0.0.0.0

COPY --from=build /app/full/llama-server /app

WORKDIR /app

# Install wget for model download
RUN apt-get update && apt-get install -y wget && rm -rf /var/lib/apt/lists/*

# Create intelligent health check script
RUN echo '#!/bin/bash\n\
# Intelligent health check script\n\
# Returns different states: downloading, ready, serving\n\
\n\
MODEL_DIR="/models"\n\
MODEL_FILE="${MODEL_FILE:-devstral-q4_k_m.gguf}"\n\
MODEL_PATH="$MODEL_DIR/$MODEL_FILE"\n\
\n\
# Check if model file exists and is complete\n\
if [ ! -f "$MODEL_PATH" ]; then\n\
    # Check if download is in progress\n\
    if [ -f "$MODEL_PATH.tmp" ]; then\n\
        echo "DOWNLOADING: Model download in progress..."\n\
        exit 0  # Healthy - downloading\n\
    else\n\
        echo "WAITING: Waiting for model download to start..."\n\
        exit 0  # Healthy - waiting\n\
    fi\n\
elif [ ! -s "$MODEL_PATH" ]; then\n\
    echo "ERROR: Model file exists but is empty"\n\
    exit 1  # Unhealthy - corrupted\n\
else\n\
    # Model exists, check if server is responding\n\
    if curl -sf http://localhost:11434/health > /dev/null 2>&1; then\n\
        echo "SERVING: Model loaded and server responding"\n\
        exit 0  # Healthy - serving\n\
    else\n\
        echo "LOADING: Model found, server starting..."\n\
        exit 0  # Healthy - loading\n\
    fi\n\
fi\n\
' > /app/health-check.sh && chmod +x /app/health-check.sh

# Create startup script that downloads model if needed
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
MODEL_DIR="/models"\n\
MODEL_FILE="${MODEL_FILE:-devstral-q4_k_m.gguf}"\n\
MODEL_URL="${MODEL_URL:-https://huggingface.co/mistralai/Devstral-Small-2507_gguf/resolve/main/Devstral-Small-2507-Q4_K_M.gguf}"\n\
\n\
echo "=== Devstral Model Check ==="\n\
echo "Model file: $MODEL_FILE"\n\
echo "Model path: $MODEL_DIR/$MODEL_FILE"\n\
\n\
# Create models directory if it does not exist\n\
mkdir -p "$MODEL_DIR"\n\
\n\
# Check if model exists\n\
if [ ! -f "$MODEL_DIR/$MODEL_FILE" ]; then\n\
    echo "Model not found. Downloading..."\n\
    echo "URL: $MODEL_URL"\n\
    \n\
    # Download with progress\n\
    if wget --progress=bar:force -O "$MODEL_DIR/$MODEL_FILE.tmp" "$MODEL_URL"; then\n\
        mv "$MODEL_DIR/$MODEL_FILE.tmp" "$MODEL_DIR/$MODEL_FILE"\n\
        echo "✓ Model downloaded successfully"\n\
    else\n\
        echo "✗ Failed to download model"\n\
        rm -f "$MODEL_DIR/$MODEL_FILE.tmp"\n\
        exit 1\n\
    fi\n\
else\n\
    echo "✓ Model already exists ($(du -h "$MODEL_DIR/$MODEL_FILE" | cut -f1))"\n\
fi\n\
\n\
# Validate model file\n\
if [ ! -s "$MODEL_DIR/$MODEL_FILE" ]; then\n\
    echo "✗ Model file is empty or corrupted"\n\
    exit 1\n\
fi\n\
\n\
echo "=== Starting llama-server ==="\n\
echo "Model: $MODEL_DIR/$MODEL_FILE"\n\
\n\
# Start the server\n\
exec /app/llama-server "$@"\n\
' > /app/start-server.sh && chmod +x /app/start-server.sh

HEALTHCHECK CMD [ "/app/health-check.sh" ]

ENTRYPOINT [ "/app/start-server.sh" ]
