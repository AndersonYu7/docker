#!/usr/bin/env bash

# Get dependent parameters
source "$(dirname "$(readlink -f "${0}")")/get_param.sh"

# Build docker images
# Get the image name from command line argument or use default
IMAGE_NAME=${1:-${IMAGE}}

# Check if the image name is provided as an argument
if [ $# -eq 0 ]; then
    echo "Error: Missing required parameters."
    echo "Usage: $0 {image_name}"
    echo "  image_name: Docker image to build"
    echo ""
    echo "Example: $0 ubuntu:latest"
    exit 1
fi

docker build -t "${IMAGE_NAME}" \
    --build-arg USER="${user}" \
    --build-arg UID="${uid}" \
    --build-arg GROUP="${group}" \
    --build-arg GID="${gid}" \
    --build-arg HARDWARE="${hardware}" \
    --build-arg ENTRYPOINT_FILE="${ENTRYPOINT_FILE}" \
    -f "${FILE_DIR}"/"${DOCKERFILE_NAME}" "${FILE_DIR}"

#     --progress=plain \
#     --no-cache \
# -t "${DOCKER_HUB_USER}"/"${IMAGE_NAME}" \

