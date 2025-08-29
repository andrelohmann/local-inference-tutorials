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
-p 8000:8000  \
--ipc=host vllm/vllm-openai:latest \
--model /home/vllm/model \
--dtype float16 \
--tensor-parallel-size 2 \
--tokenizer-mode auto \
--gpu-memory-utilization 0.90 \
--swap-space 16 \
--max-model-len 8192 \
--disable-custom-all-reduce
```

### Parameter Erklärung

* --env TORCH_CUDA_ARCH_LIST="8.6"
Gibt die Architektur an

* --dtype float16
Nutzt explizit FP16 und nicht BF16

* --tensor-parallel-size 2 \
Tensor Parallelism

* --gpu-memory-utilization 0.90
Gibt an, wieviel Prozent für Gewichte und KV Cache reserviert werden

* --swap-space 16
Lagert KV Cache in bis zu 16GB Ram aus / kostet performance

* --max-model-len 8192
Context Window

* --disable-custom-all-reduce
Wenn P2P PCIe nicht vorhanden
