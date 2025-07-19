# OpenWebUI Configuration Alignment

## Comparison Summary

### Variables from test-openwebui.sh docker run command:
```bash
docker run -d \
    --name openwebui-test \
    -p 8080:8080 \
    -v ~/.openwebui:/app/backend/data \
    --add-host=host.docker.internal:host-gateway \
    -e PUID=$USER_ID \
    -e PGID=$GROUP_ID \
    -e WEBUI_AUTH=false \
    -e ENABLE_OLLAMA_API=false \
    -e ENABLE_OPENAI_API=true \
    -e OPENAI_API_BASE_URL=http://host.docker.internal:11434/v1 \
    -e OPENAI_API_KEY=sk-no-key-required \
    ghcr.io/open-webui/open-webui:latest
```

### Updated .env file variables:
```bash
OPENWEBUI_PORT=8080
OPENWEBUI_WEBUI_AUTH=false
OPENWEBUI_ENABLE_OLLAMA_API=false
OPENWEBUI_ENABLE_OPENAI_API=true
OPENWEBUI_OPENAI_API_BASE_URL=http://host.docker.internal:11434/v1
OPENWEBUI_OPENAI_API_KEY=sk-no-key-required
OPENWEBUI_WEBUI_NAME=Devstral WebUI
OPENWEBUI_DEFAULT_MODELS=devstral-small-2507
OPENWEBUI_DEFAULT_USER_ROLE=admin
```

### Updated docker-compose.yml openwebui service:
```yaml
openwebui:
  image: ghcr.io/open-webui/open-webui:latest
  container_name: openwebui
  restart: unless-stopped
  environment:
    - PUID=${SANDBOX_USER_ID}
    - PGID=${SANDBOX_USER_ID}
    - WEBUI_AUTH=${OPENWEBUI_WEBUI_AUTH}
    - ENABLE_OLLAMA_API=${OPENWEBUI_ENABLE_OLLAMA_API}
    - ENABLE_OPENAI_API=${OPENWEBUI_ENABLE_OPENAI_API}
    - OPENAI_API_BASE_URL=${OPENWEBUI_OPENAI_API_BASE_URL}
    - OPENAI_API_KEY=${OPENWEBUI_OPENAI_API_KEY}
    - WEBUI_NAME=${OPENWEBUI_WEBUI_NAME}
    - DEFAULT_MODELS=${OPENWEBUI_DEFAULT_MODELS}
    - DEFAULT_USER_ROLE=${OPENWEBUI_DEFAULT_USER_ROLE}
  ports:
    - "${OPENWEBUI_PORT}:8080"
  volumes:
    - ~/.openwebui:/app/backend/data
  extra_hosts:
    - "host.docker.internal:host-gateway"
```

## Key Changes Made:

1. **Volume mapping**: Changed from `./openwebui-data` to `~/.openwebui` to match test script
2. **User permissions**: Added `PUID` and `PGID` using `SANDBOX_USER_ID` 
3. **API configuration**: 
   - Disabled Ollama API (`ENABLE_OLLAMA_API=false`)
   - Enabled OpenAI API (`ENABLE_OPENAI_API=true`)
   - Set correct base URL (`http://host.docker.internal:11434/v1`)
4. **Authentication**: Disabled (`WEBUI_AUTH=false`)
5. **Network**: Added `host.docker.internal:host-gateway` mapping
6. **Directory creation**: Updated start.sh to create `~/.openwebui` instead of `./openwebui-data`

## Benefits:

- **Exact alignment** with working test script configuration
- **Proper permissions** using user/group IDs
- **Correct API endpoint** for llama.cpp integration
- **Simplified authentication** (disabled for easier testing)
- **Host network access** for container-to-host communication
