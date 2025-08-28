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
