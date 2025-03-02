# docker
This is the user guide, divided into pre-installation steps and usage instructions.

## Pre-Installation
This section provides installation instructions. For detailed steps, please refer to [README_INSTALL.md](README_INSTALL.md).

## Usage
1. Download this GitHub repository:
    ```sh
    git clone https://github.com/AndersonYu7/docker.git docker
    ```
2. Move to the target directory:
    ```sh
    cd docker
    ```
3. Copy the files to your workspace:
    ```sh
    cp -r . <workspace_path>
    ```
4. Adjust the Dockerfile to suit your needs.

5. Build the Docker image:
    ```sh
    ./build.sh {image_name}
    ```
    - `image_name`: Name for the Docker image you choose

    Example:
    ```sh
    ./build.sh ubuntu_image
    ```

6. Run the Docker container:
    ```sh
    ./run.sh {container_name} {image_name} [no-rm] [bash|terminator]
    ```

    - `container_name`: Name for the Docker container.
    - `image_name`: Docker image to use.
    - `no-rm`: Optional flag. If provided, the container will NOT be removed after exit and will run in the background with `tail -f`.
    - `bash|terminator`: Optional parameter to decide which command to use to attach to the container (default: `terminator`).

    Example:
    ```sh
    ./run.sh my_container ubuntu_image           # use --rm mode, attach with terminator
    ./run.sh my_container ubuntu_image no-rm bash   # use no-rm mode, attach with bash
    ```

## Deleting a Container
To delete a Docker container, use the `delete.sh` script:

```sh
./delete.sh {container_name}
```

- `container_name`: Name of the Docker container to delete.

Example:
```sh
./delete.sh my_container
```

The `delete.sh` script will check if the container exists and whether it is running. If the container is running, it will prompt you to confirm if you want to stop and remove it. If the container is not running, it will be removed directly.

