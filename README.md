# local-inference-tutorials
Some best practices for inference of local LLMs

## Install Dependencies

### Docker (All)

```
sudo apt-get update
sudo apt-get install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo usermod -aG docker $USER
```

### Install Driver and Dependencies (Only GPU Nodes)

Install nvidia driver.

```
sudo add-apt-repository ppa:graphics-drivers/ppa --yes
sudo apt update
sudo apt install nvidia-driver-570-server --yes
sudo apt install nvtop pciutils screen curl cmake build-essential git-lfs --yes
```

To automate the lates driver selection, use the following commandline:

```
sudo apt install -y $(apt-cache search --names-only '^nvidia-driver-[0-9]+-server$' | awk '{print $1}' | sort -V | tail -n 1)
```

If necessary, when not infering within containers, install nvidia cuda

```
sudo apt install nvidia-cuda-toolkit nvidia-cudnn --yes
```

### Nvidia Container toolkit (Only GPU Nodes)

* https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html

```
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sed -i -e '/experimental/ s/^#//g' /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update

sudo apt-get install -y nvidia-container-toolkit

sudo nvidia-ctk runtime configure --runtime=docker

sudo systemctl restart docker
```
