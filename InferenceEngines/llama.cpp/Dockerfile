# Wir verwenden ein offizielles NVIDIA CUDA Image. CUDA 11.8 ist eine sehr stabile Wahl für Pascal-Karten.
# Die "-devel" Variante enthält alle notwendigen Compiler und Bibliotheken (nvcc, etc.).
FROM nvidia/cuda:11.8.0-devel-ubuntu22.04

# Umgebungsvariable, um interaktive Abfragen bei der Paketinstallation zu unterbinden.
ENV DEBIAN_FRONTEND=noninteractive

# Installieren der notwendigen Build-Abhängigkeiten.
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    cmake \
    libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Ein Arbeitsverzeichnis im Container erstellen und dorthin wechseln.
WORKDIR /app

# Das llama.cpp Repository klonen. --recursive ist wichtig für die Submodule.
RUN git clone --recursive https://github.com/ggerganov/llama.cpp.git .

# --- FINALE BUILD-KORREKTUR ---
# Wir zwingen CMake jetzt, bei ALLEN Linker-Vorgängen (Shared Libraries UND Executables)
# nicht nur den Pfad zu den Stubs zu verwenden, sondern auch explizit gegen die CUDA-Bibliothek zu linken.
# -L/usr/local/cuda/lib64/stubs   -> Der Suchpfad.
# -lcuda                          -> Die Anweisung, "libcuda.so" zu linken.
RUN mkdir build && \
    cd build && \
    cmake .. \
        -DGGML_CUDA=ON \
        -DGGML_CUDA_ARCH=61 \
        -DCMAKE_SHARED_LINKER_FLAGS="-L/usr/local/cuda/lib64/stubs -lcuda" \
        -DCMAKE_EXE_LINKER_FLAGS="-L/usr/local/cuda/lib64/stubs -lcuda" && \
    make -j$(nproc) && \
    mv bin/* /app

# (Optional) Setzen Sie einen Standardbefehl, der beim Starten des Containers ausgeführt wird.
# In diesem Fall starten wir einfach eine Bash-Shell.
CMD ["/bin/bash"]
