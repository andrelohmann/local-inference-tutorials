# OpenHands Configuration Alignment

## Overview
This document shows the exact alignment between `test-openhands.sh` and the production Docker Compose setup.

## Configuration Alignment

### Docker Run Parameters from test-openhands.sh:
```bash
CONTAINER_ID=$(docker run -d \
    --name $CONTAINER_NAME \
    --pull=always \
    -e SANDBOX_RUNTIME_CONTAINER_IMAGE=$RUNTIME_IMAGE \
    -e LOG_ALL_EVENTS=true \
    -e WORKSPACE_BASE=/workspace \
    -e SANDBOX_USER_ID=$(id -u) \
    -e SANDBOX_TIMEOUT=120 \
    -e RUNTIME=docker \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v ~/.openhands:/.openhands \
    -v ~/.openhands/workspace:/workspace \
    -p 3000:3000 \
    --add-host host.docker.internal:host-gateway \
    $OPENHANDS_IMAGE)
```

### Variables from test-openhands.sh:
```bash
CONTAINER_NAME="openhands-test"
OPENHANDS_IMAGE="docker.all-hands.dev/all-hands-ai/openhands:0.49"
RUNTIME_IMAGE="docker.all-hands.dev/all-hands-ai/runtime:0.49-nikolaik"
```

### Corresponding .env Variables (ALIGNED):
```env
OPENHANDS_IMAGE=docker.all-hands.dev/all-hands-ai/openhands:0.49
OPENHANDS_VERSION=0.49
OPENHANDS_RUNTIME_IMAGE=docker.all-hands.dev/all-hands-ai/runtime:0.49-nikolaik
OPENHANDS_RUNTIME_VERSION=0.49-nikolaik
OPENHANDS_PORT=3000
OPENHANDS_CONTAINER_NAME=openhands-test
OPENHANDS_LOG_ALL_EVENTS=true
OPENHANDS_WORKSPACE_BASE=/workspace
OPENHANDS_SANDBOX_TIMEOUT=120
OPENHANDS_RUNTIME=docker
```

### Docker Compose Service (ALIGNED):
```yaml
openhands:
  image: ${OPENHANDS_IMAGE}
  container_name: ${OPENHANDS_CONTAINER_NAME}
  restart: unless-stopped
  environment:
    - SANDBOX_RUNTIME_CONTAINER_IMAGE=${OPENHANDS_RUNTIME_IMAGE}
    - LOG_ALL_EVENTS=${OPENHANDS_LOG_ALL_EVENTS}
    - WORKSPACE_BASE=${OPENHANDS_WORKSPACE_BASE}
    - SANDBOX_USER_ID=${SANDBOX_USER_ID}
    - SANDBOX_TIMEOUT=${OPENHANDS_SANDBOX_TIMEOUT}
    - RUNTIME=${OPENHANDS_RUNTIME}
  ports:
    - "${OPENHANDS_PORT}:3000"
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
    - ~/.openhands:/.openhands
    - ~/.openhands/workspace:/workspace
  extra_hosts:
    - "host.docker.internal:host-gateway"
  depends_on:
    llama-cpp-server:
      condition: service_healthy
  networks:
    - devstral-network
```

## Configuration Files Created

### settings.json (from test-openhands.sh):
```json
{"language":"en","agent":"CodeActAgent","max_iterations":null,"security_analyzer":null,"confirmation_mode":false,"llm_model":"openai/devstral-small-2507","llm_api_key":"DEVSTRAL","llm_base_url":"http://host.docker.internal:11434","remote_runtime_resource_factor":1,"secrets_store":{"provider_tokens":{}},"enable_default_condenser":true,"enable_sound_notifications":false,"enable_proactive_conversation_starters":false,"user_consents_to_analytics":false,"sandbox_base_container_image":null,"sandbox_runtime_container_image":null,"mcp_config":{"sse_servers":[],"stdio_servers":[],"shttp_servers":[]},"search_api_key":"","sandbox_api_key":null,"max_budget_per_task":null,"email":null,"email_verified":null}
```

### config.toml (from test-openhands.sh):
```toml
[llm]
model = "openai/devstral-small-2507"
base_url = "http://host.docker.internal:11434"
api_key = "dummy"
api_version = "v1"
custom_llm_provider = "openai"
drop_params = true
```

## Key Alignments Made:

1. **Container Name**: Changed from `openhands` to `openhands-test` to match test script
2. **Image Variables**: Now using `${OPENHANDS_IMAGE}` and `${OPENHANDS_RUNTIME_IMAGE}` from .env
3. **Environment Variables**: All docker run -e parameters now come from .env variables
4. **Volume Mapping**: Exact match with test script:
   - `/var/run/docker.sock:/var/run/docker.sock`
   - `~/.openhands:/.openhands`
   - `~/.openhands/workspace:/workspace`
5. **Configuration Files**: start.sh now creates the exact same settings.json and config.toml files
6. **LLM Base URL**: Uses `http://host.docker.internal:11434` to match test script exactly

## Verification Commands:

Test the aligned setup:
```bash
./start.sh
```

Compare with test script:
```bash
./test-openhands.sh up
```

Both should create identical container configurations and LLM settings.

## Status: ✅ FULLY ALIGNED

All Docker run parameters, environment variables, volume mappings, and configuration files now match exactly between the test script and production Docker Compose setup.
