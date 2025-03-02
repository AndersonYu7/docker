#!/usr/bin/env bash
# filepath: /home/ubuntu-6th/yu/docker_new/run.sh

# 取得依賴參數
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

# 至少需要 container 與 image 兩個參數
if [ $# -lt 2 ]; then
    echo "Error: Missing required parameters."
    usage
fi

CONTAINER=$1
IMAGE=$2

# 預設值：使用 --rm 與 terminator 為 exec 命令
RM_OPTION="--rm"
EXEC_CMD="terminator"
RUN_MODE="rm"  # 默認模式

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

# 檢查是否已有同名 container (不論運行與否)
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

# 根據 RUN_MODE 決定啟動參數：
# 若用 --rm 模式（前台），則執行命令只啟動 terminator，
# 若用 no-rm 模式（背景），則加上 tail -f /dev/null 保持 container 運行
if [ "${RUN_MODE}" = "rm" ]; then
    DETACH_FLAG=""
    CMD="terminator"
else
    DETACH_FLAG="-d"
    CMD="terminator; tail -f /dev/null"
fi

# 執行 container，並透過 --entrypoint 覆寫 Dockerfile 的 ENTRYPOINT
docker run ${RM_OPTION} \
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
    -it ${DETACH_FLAG} --name "${CONTAINER}" \
    --entrypoint bash "${IMAGE}" -c "${CMD}"