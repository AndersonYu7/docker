## 1. Installation Steps

First, run `install_docker.sh`.

### 2. Create the Docker group

```sh
sudo groupadd docker
```

### 3. Add your user to the Docker group

```sh
sudo usermod -aG docker $USER
```

### 4. Log out and log back in

Log out and log back in so that your group membership is re-evaluated.

If you're running Linux in a virtual machine, it may be necessary to restart the virtual machine for changes to take effect.

### 5. Activate the changes to groups

You can also run the following command to activate the changes to groups:

```sh
newgrp docker
```

### 6. Try Docker

To verify that Docker is installed correctly, run the following command:

```sh
docker run hello-world
```

This command downloads a test image and runs it in a container. When the container runs, it prints a message and exits.

### 7. Install NVIDIA Container Toolkit

To enable GPU support in Docker containers, run the following script:

```sh
./install_nv_container_toolkit.sh
```

This script installs the NVIDIA Container Toolkit, which allows Docker containers to access the GPU using:

```sh
docker run --gpus all nvidia/cuda:11.8.0-base nvidia-smi
```

After the script completes, restart Docker to apply changes:

```sh
sudo systemctl restart docker
```