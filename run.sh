#!/usr/bin/env bash
# filepath: /home/ubuntu-6th/yu/docker_new/run.sh

source "$(dirname "$(readlink -f "${0}")")/get_param.sh"

usage() {
    echo "Usage: $0 {container_name} {image_name} [no-rm] [bash|terminator]"
    echo "  container_name: Name for the Docker container"
    echo "  image_name: Docker image to use"
    echo "  no-rm: Optional flag. If provided, container will NOT be removed after exit and will run in background with tail -f."
    echo "         (default --rm mode: runs in foreground, stops when terminator closes)"
    echo "  bash|terminator: Optional parameter to decide which command to use to attach to container (default: terminator)."
    echo ""
    echo "Example:"
    echo "  ./run.sh my_container ubuntu:latest           # use --rm mode, attach with terminator"
    echo "  ./run.sh my_container ubuntu:latest no-rm bash   # use no‑rm mode, attach with bash"
    exit 1
}

# Require at least container name and image name
if [ $# -lt 2 ]; then
    echo "Error: Missing required parameters."
    usage
fi

CONTAINER=$1
IMAGE=$2

# Default values
RM_OPTION="--rm"
EXEC_CMD="terminator"
RUN_MODE="rm"

# Parse optional arguments
shift 2
for param in "$@"; do
    if [ "$param" = "no-rm" ]; then
        RM_OPTION=""
        RUN_MODE="no-rm"
    elif [ "$param" = "bash" ] || [ "$param" = "terminator" ]; then
        EXEC_CMD="$param"
    else
        echo "Unknown parameter: $param"
        usage
    fi
done

# Check if the container already exists
EXISTING_CONTAINER=$(docker ps -a --filter "name=^${CONTAINER}$" --format '{{.Names}}')
if [ -n "${EXISTING_CONTAINER}" ]; then
    if docker ps --format '{{.Names}}' | grep -wq "${CONTAINER}"; then
        echo "Container '${CONTAINER}' is already running. Attaching with ${EXEC_CMD}..."
    else
        echo "Container '${CONTAINER}' exists but is not running. Starting..."
        docker start "${CONTAINER}" > /dev/null
    fi
    docker exec -it "${CONTAINER}" ${EXEC_CMD}
    exit 0
fi

# Set runtime flags based on mode
if [ "${RUN_MODE}" = "rm" ]; then
    DETACH_FLAG=""
    INTERACTIVE="-it"
    CMD="${EXEC_CMD}"
else
    DETACH_FLAG="-d"
    INTERACTIVE=""
    CMD="tail -f /dev/null"  # Keep container alive without executing terminator
fi

# Run container
docker run ${RM_OPTION} \
    --privileged \
    --network=host \
    --ipc=host \
    ${GPU_FLAG} \
    -e NVIDIA_VISIBLE_DEVICES=all \
    -e NVIDIA_DRIVER_CAPABILITIES=all \
    -e VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json \
    -e VK_LAYER_PATH=/usr/share/vulkan/explicit_layer.d \
    -e DOCKER_NAME="${CONTAINER}" \
    -e DISPLAY="${DISPLAY}" \
    -e QT_X11_NO_MITSHM=1 \
    -v /home/"${user}"/.Xauthority:/home/"${user}"/.Xauthority \
    -e XAUTHORITY=/home/"${user}"/.Xauthority \
    -e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR \
    -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
    -v /etc/timezone:/etc/timezone:ro \
    -v /etc/localtime:/etc/localtime:ro \
    -v /dev:/dev \
    -v /usr/share/vulkan:/usr/share/vulkan \
    -v "${WS_PATH}":/home/"${user}"/work \
    ${INTERACTIVE} ${DETACH_FLAG} --name "${CONTAINER}" \
    --entrypoint bash "${IMAGE}" -c "${CMD}"

# If in background mode, automatically exec into the container after startup
if [ "${RUN_MODE}" = "no-rm" ]; then
    docker exec -it "${CONTAINER}" ${EXEC_CMD}
fi
