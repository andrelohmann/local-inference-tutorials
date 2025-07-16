# llama.cpp

```bash
cd llama.cpp
docker build -t llama-cpp-ampere .
```

```bash
# Create models directory
mkdir -p models

wget -O models/devstral-q4_k_m.gguf \
  https://huggingface.co/mistralai/Devstral-Small-2507_gguf/resolve/main/Devstral-Small-2507-Q4_K_M.gguf

wget -O models/glm-4-9b-0414-q4_k_l.gguf \
  https://huggingface.co/bartowski/THUDM_GLM-4-9B-0414-GGUF/resolve/main/THUDM_GLM-4-9B-0414-Q4_K_L.gguf

wget -O models/glm-4-9b-0414-q8.gguf \
  https://huggingface.co/bartowski/THUDM_GLM-4-9B-0414-GGUF/resolve/main/THUDM_GLM-4-9B-0414-Q8_0.gguf

wget -O models/glm-4-32b-0414-q4_k_l.gguf \
  https://huggingface.co/bartowski/THUDM_GLM-4-32B-0414-GGUF/resolve/main/THUDM_GLM-4-32B-0414-Q4_K_L.gguf
```

```
docker run --gpus '"device=0,1"' \
-v $(pwd)/models:/models -p 8000:8000 llama-cpp-ampere -m /models/glm-4-9b-0414-q4_k_l.gguf --port 8000 --host 0.0.0.0 -n 512 -c 16384 -np 1 --n-gpu-layers 99
```
