# Infere with llama.cpp

* https://github.com/ggml-org/llama.cpp/blob/master/docs/docker.md


For the P4000/5000 Models, an older Cuda Version and an older driver is required. Also therefor these instances require a Unbuntu 22.04.

```
sudo add-apt-repository ppa:graphics-drivers/ppa --yes
sudo apt update
sudo apt install nvidia-headless-535-server --yes
#sudo apt install nvidia-headless-570-server nvidia-cuda-toolkit nvidia-cudnn --yes
sudo apt install nvtop pciutils screen curl cmake build-essential git-lfs --yes

wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb
sudo dpkg -i cuda-keyring_1.0-1_all.deb
sudo apt-get update
sudo apt-get -y install cuda
```

### llama.cpp

* https://github.com/ggml-org/llama.cpp

Llama.cpp doesn't support tensor-parallelism, but we need it fro test purposes and because it brings some other tools e.g. for merging gguf partial files.

```
git clone https://github.com/ggml-org/llama.cpp.git
cd llama.cpp
cmake -B build -DLLAMA_CUDA=ON
cmake --build build --config Release
```

mkdir build && cd build
cmake .. -DLLAMA_CUDA=ON
make -j$(nproc)

### Python virtual env

Install python venv

```
sudo apt install python3-pip python3-virtualenv python3-venv -y
```

### Hugginface cli

Install huggingface-cli to the User environment and set its path.

```
pip3 install -U "huggingface_hub[cli]" --break-system-packages
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
```

You need to fetch a huggingface token and the login to the cli.

* https://huggingface.co/settings/tokens

```
huggingface-cli login
```

### Convert Huggingface Deepseek Distilled Model

```
python3 -m venv quant_venv
source quant_venv/bin/activate
```
