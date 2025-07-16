# vllm

```
docker run --runtime nvidia --gpus all \
    -v $(pwd)/models:/app/models \
    -p 8000:8000 \
    --ipc=host \
    vllm/vllm-openai:latest \
    --model /app/models/devstral-q4_k_m.gguf --tokenizer_mode mistral
```
