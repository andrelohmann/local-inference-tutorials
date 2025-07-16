# vLLM

## Huggingface

Export the huggingface token

```
export HF_TOKEN=hf_XXX
```

## Docker

### Latest

```
docker pull vllm/vllm-openai:latest
```

### Models

#### Devstral

* https://huggingface.co/mratsim/Devstral-Small-2505.w4a16-gptq

```
export LLM_MODEL=mratsim/Devstral-Small-2505.w4a16-gptq

docker run \
--gpus '"device=0,1"' --rm --name vllm_server \
-v ~/.cache/huggingface:/root/.cache/huggingface \
--env "HUGGING_FACE_HUB_TOKEN=$HF_TOKEN" -p 8000:8000  \
--ipc=host vllm/vllm-openai:latest \
--model $LLM_MODEL \
--tokenizer_mode mistral --pipeline-parallel-size 2 \
--gpu-memory-utilization 0.94 --max_model_len 48080
```
