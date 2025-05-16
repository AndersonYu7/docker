#!/usr/bin/env bash

usage() {
    echo "Usage: $0 {container_name}"
    exit 1
}

# check the number of parameters
if [ $# -ne 1 ]; then
    usage
fi

CONTAINER_NAME=$1

# check if the container exists
EXISTING_CONTAINER=$(docker ps -a --filter "name=^${CONTAINER_NAME}$" --format '{{.Names}}')
if [ -z "${EXISTING_CONTAINER}" ]; then
    echo "Container '${CONTAINER_NAME}' does not exist."
    exit 0
fi

# check if the container is running
if docker ps --format '{{.Names}}' | grep -wq "${CONTAINER_NAME}"; then
    echo "Container '${CONTAINER_NAME}' is currently running."
    read -p "Do you want to stop and remove it? (y/N): " confirm
    if [[ "${confirm}" =~ ^[Yy]$ ]]; then
        docker stop "${CONTAINER_NAME}"
        docker rm "${CONTAINER_NAME}"
        echo "Container '${CONTAINER_NAME}' has been stopped and removed."
    else
        echo "Aborted."
    fi
else
    echo "Container '${CONTAINER_NAME}' is not running. Removing..."
    docker rm "${CONTAINER_NAME}"
    echo "Container '${CONTAINER_NAME}' has been removed."
fi