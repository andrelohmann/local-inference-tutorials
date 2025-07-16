# Infere with ollama

* https://github.com/ollama/ollama/blob/main/docs/docker.md

## Infere in the container

### Run ollama in a container

```
docker run -d --gpus=all -v ollama:/root/.ollama -p 11434:11434 --name ollama ollama/ollama
```

### Load a model

```
docker exec -it ollama ollama pull mistral:7b-instruct-q8_0
```

### Infere the model

```
docker exec -it ollama ollama run --verbose mistral:7b-instruct-q8_0
```

### Test the inference via API

```
curl http://localhost:11434/api/generate -d '{
  "model": "mistral:7b-instruct-q8_0",
  "prompt": "Why is the sky blue?"
}'
```

### Model Catalog for 8GB and 16GB GPUs

* gemma3:12b-it-q8_0 (13GB, 15,5 T/s)
* phi4:14b-q8_0 (15GB, 14,5 T/s)
* mistral-small:24b-instruct-2501-q4_K_M (14GB, 11,5 T/s)
* mistral-nemo:12b-instruct-2407-q8_0
* deepseek-r1:14b-qwen-distill-q8_0 (15GB, 11T/s)
* dolphin3:8b-llama3.1-q8_0
* gemma3:12b-it-q8_0
* command-r7b:7b-12-2024-q8_0
* phi4:14b-q8_0
* mistral-small:24b-instruct-2501-q4_K_M
* mistral-nemo:12b-instruct-2407-q8_0
* deepseek-r1:14b-qwen-distill-q8_0
* dolphin3:8b-llama3.1-q8_0
* llama3.2-vision:11b-instruct-q8_0
* llava:13b-v1.5-q8_0
* * deepseek-r1:8b-llama-distill-q4_K_M (4,9GB, 25,5T/s)
* mistral:7b-instruct-q8_0 (7,7GB, 23 T/s)
* mistral-nemo:12b-instruct-2407-q4_K_M
* dolphin3:8b-llama3.1-q4_K_M
* ardonplay/english-to-german-translate
* kisz/llama3.2-leichte-sprache-ft
* granite-embedding:278m-fp16 (0,5GB, ) <- not doing inference
* granite3-moe:3b-instruct-q8_0 (3,6GB, 40,5 T/s)
* granite3.2-vision:2b-q8_0 (2,7GB, 49T/s)
* jeffh/intfloat-multilingual-e5-large-instruct:f16
* llama3.2-vision:11b-instruct-q4_K_M (6GB, 5T/s)
* llava:13b-v1.5-q4_0 Vision model (7,4GB, 6,5T/s)

## WebUIs

### OpenWebUI (Only API Proxy)

* https://docs.openwebui.com/getting-started/quick-start/

```
docker run -d -p 3000:8080 -v open-webui:/app/backend/data --name open-webui ghcr.io/open-webui/open-webui:main
```

### N8N

* https://docs.n8n.io/hosting/installation/docker/

```
docker run -it --rm --name n8n -p 5678:5678 -v n8n_data:/home/node/.n8n docker.n8n.io/n8nio/n8n
```

### OpenHands

```
docker run -it --rm --pull=always -e SANDBOX_RUNTIME_CONTAINER_IMAGE=docker.all-hands.dev/all-hands-ai/runtime:0.48-nikolaik -e LOG_ALL_EVENTS=true -v /var/run/docker.sock:/var/run/docker.sock -v ~/.openhands:/.openhands -p 3000:3000 --add-host host.docker.internal:host-gateway --name openhands-app docker.all-hands.dev/all-hands-ai/openhands:0.48
```
