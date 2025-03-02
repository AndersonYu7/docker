#!/usr/bin/env bash

# Get dependent parameters
source "$(dirname "$(readlink -f "${0}")")/get_param.sh"

# Function to display usage information
usage() {
    echo "Usage: $0 {container_name} {image_name}"
    echo "  container_name: Name for the Docker container"
    echo "  image_name: Docker image to use"
    echo ""
    echo "Example: $0 my_container ubuntu:latest"
    exit 1
}

# Check if container name and image name are provided as arguments
if [ $# -eq 2 ]; then
    CONTAINER=$1
    IMAGE=$2
else
    echo "Error: Missing required parameters."
    usage
fi

docker run --rm \
    --privileged \
    --network=host \
    --ipc=host \
    ${GPU_FLAG} \
    -e DISPLAY="${DISPLAY}" \
    -e QT_X11_NO_MITSHM=1 \
    -v /home/"${user}"/.Xauthority:/home/"${user}"/.Xauthority \
    -e XAUTHORITY=/home/"${user}"/.Xauthority \
    -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
    -v /etc/timezone:/etc/timezone:ro \
    -v /etc/localtime:/etc/localtime:ro \
    -v /dev:/dev \
    -v "${WS_PATH}":/home/"${user}"/work \
    -it --name "${CONTAINER}" "${IMAGE}"

