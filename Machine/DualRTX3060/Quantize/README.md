# Quantize Coding Models with Layer Offloading

## Swap

The two RTX3060 are too small an even the 64GB of RAM are too small, so that we need to create a Swap File.

```
sudo fallocate -l 32G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

If you need to delete it later:

```
sudo swapoff /swapfile
sudo rm /swapfile
```

## venv

```
mkdir quantise_qwen3-coder && cd quantise_qwen3-coder
python3 -m venv .venv
source .venv/bin/activate
```

## Quantise

Install the dependencies

```
pip install datasets transformers torch accelerate llmcompressor
```

Then Download and quantise the Qwen3-coder model with the CodeAlpaca Calibration Dataset.

```
python3 quantize_qwen3-coder.py
```

## Run qunatised in vLLM

```
export LOCAL_MODEL_PATH=$(pwd)/Qwen3-Coder-30B-AWQ-final
echo "Modellpfad ist: $LOCAL_MODEL_PATH"

docker run \
--gpus '"device=0,1"' --rm --name vllm_server \
-v "$LOCAL_MODEL_PATH":/home/vllm/model \
--env TORCH_CUDA_ARCH_LIST="8.6" \
--env PYTORCH_CUDA_ALLOC_CONF="expandable_segments:True" \
-p 8000:8000  \
--ipc=host vllm/vllm-openai:latest \
--model /home/vllm/model \
--served-model-name qwen3-coder-30b-awq \
--dtype float16 \
--tensor-parallel-size 2 \
--tokenizer-mode auto \
--disable-custom-all-reduce \
--swap-space 8 \
--max-num-batched-tokens 2048 \
--max-model-len 32768 \
--gpu-memory-utilization 0.96 \
--max-num-seqs 16
```

### Parameter Erklärung

* --env TORCH_CUDA_ARCH_LIST="8.6"
Gibt die Architektur an

* --env PYTORCH_CUDA_ALLOC_CONF="expandable_segments:True"
Hilft Speicherfragmentierung zu reduzieren, was in extrem knappen Speichersituationen den Unterschied ausmachen kann

* --dtype float16
Nutzt explizit FP16 und nicht BF16

* --tensor-parallel-size 2 \
Tensor Parallelism

* --gpu-memory-utilization 0.90
Gibt an, wieviel Prozent für Gewichte und KV Cache reserviert werden

* --swap-space 16
Lagert KV Cache in bis zu 16GB Ram aus / kostet performance / Ram Reservierung muss mit der Menge der Prozesse (TP) multipliziert werden

* --max-model-len 8192
Context Window

* --disable-custom-all-reduce
Wenn P2P PCIe nicht vorhanden

* --max-num-seqs 16
Reduziet die maximalen parallelen Requests auf 16 (Default 256)

* --max-num-batched-tokens
Der Prefill Process Input Tokens in Batches der angegebenen Token Größe / je größer, je schneller, je mehr VRAM Bedarf

### Test

Liste die Modelle auf

```
curl -s http://localhost:8000/v1/models | jq
```

Führe einen Prompt aus

```
curl http://localhost:8000/v1/chat/completions \
-H "Content-Type: application/json" \
-d '{
    "model": "qwen3-coder-30b-awq",
    "messages": [
        {"role": "user", "content": "Schreibe eine Python-Funktion, die die ersten n Fibonacci-Zahlen berechnet und eine Liste zurückgibt."}
    ],
    "max_tokens": 256,
    "temperature": 0.2
}'
```

Führe einen Prompt aus und streame die Token Generation

```
curl -N http://localhost:8000/v1/chat/completions \
-H "Content-Type: application/json" \
-d '{
    "model": "qwen3-coder-30b-awq",
    "messages": [
        {"role": "user", "content": "Schreibe eine kurze und elegante Python-Funktion, die prüft, ob eine Zahl eine Primzahl ist."}
    ],
    "max_tokens": 256,
    "temperature": 0.2,
    "stream": true
}'
```

Teste single und parallel streams

```
python3 test_qwen3_stream.py
python3 test_qwen3_parallel_stream.py 16
```

### Finetuning

* https://www.youtube.com/watch?v=pTaSDVz0gok
* https://www.youtube.com/watch?v=AnfHWbcnlMU
