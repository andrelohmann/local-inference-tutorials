# HP Z620 GPU Machine

* 6Cores/12Threads
* 32GB RAM
* 2 x NVIDIA Quadro P4000 (8GB VRAM - Pascal Architecture)
* 1 x NVIDIA Quadro P5000 (16GB VRAM - Pascal Architecture)

## Prerequisites - Containerized Inference Workloads

* Install Ubuntu
* Install NVIDIA Driver
* Install Docker
* Install Nvidia Container Toolkit
* Install nvtop

## Ollama Inference

```
docker build -t llama-cpp-pascal .