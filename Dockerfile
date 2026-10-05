# FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04
# FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu22.04
# FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04
FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04
############################## SYSTEM PARAMETERS ##############################
# * Arguments
ARG USER=initial
ARG GROUP=initial
ARG UID=1000
ARG GID="${UID}"
ARG SHELL=/bin/bash
ARG HARDWARE=x86_64
ARG ENTRYPOINT_FILE=entrypint.sh
ARG ROS_DISTRO=jazzy
ARG DEBIAN_FRONTEND=noninteractive

# * Env vars for the nvidia-container-runtime.
# ENV NVIDIA_VISIBLE_DEVICES all
# ENV NVIDIA_DRIVER_CAPABILITIES all
# ENV NVIDIA_DRIVER_CAPABILITIES graphics,utility,compute

# * Ubuntu 24.04 ships a default "ubuntu" user with UID/GID 1000, remove it to avoid conflicts
RUN userdel -r ubuntu 2>/dev/null || true

# * Setup users and groups
RUN groupadd --gid "${GID}" "${GROUP}" \
    && useradd --gid "${GID}" --uid "${UID}" -ms "${SHELL}" "${USER}" \
    && mkdir -p /etc/sudoers.d \
    && echo "${USER}:x:${UID}:${UID}:${USER},,,:/home/${USER}:${SHELL}" >> /etc/passwd \
    && echo "${USER}:x:${UID}:" >> /etc/group \
    && echo "${USER} ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/${USER}" \
    && chmod 0440 "/etc/sudoers.d/${USER}"

# * Replace apt urls
# ? Change to NYCU
# RUN sed -i 's@archive.ubuntu.com@ubuntu.cs.nycu.edu.tw/@g' /etc/apt/sources.list
# ? Change to Taiwan (Ubuntu 24.04 uses deb822 format in ubuntu.sources)
RUN sed -i 's@archive.ubuntu.com@tw.archive.ubuntu.com@g' /etc/apt/sources.list.d/ubuntu.sources

# * Time zone
ENV TZ=Asia/Taipei
RUN ln -snf /usr/share/zoneinfo/"${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone

# * Copy custom configuration
# ? Requires docker version >= 17.09
COPY --chmod=0775 ./${ENTRYPOINT_FILE} /entrypoint.sh
COPY --chown="${USER}":"${GROUP}" --chmod=0775 config config
# ? docker version < 17.09
# COPY ./${ENTRYPOINT_FILE} /entrypoint.sh
# COPY config config
# RUN sudo chmod 0775 /entrypoint.sh && \
    # sudo chown -R "${USER}":"${GROUP}" config \
    # && sudo chmod -R 0775 config


# * ENV vars for CUDA and cuDNN
# ENV NV_CUDNN_VERSION=8.7.0.84-1
# ENV NV_CUDNN_PACKAGE_NAME=libcudnn8
# ENV NV_CUDNN_PACKAGE=libcudnn8=8.7.0.84-1+cuda11.8
# ENV NV_CUDNN_PACKAGE_DEV=libcudnn8-dev=8.7.0.84-1+cuda11.8


# * Install packages
RUN apt update \
    && apt install -y --no-install-recommends \
        sudo \
        git \
        htop \
        wget \
        curl \
        # tzdata \
        # psmisc \
        # * Shell
        tmux \
        udev \
        terminator \
        # * base tools
        python3-pip \
        python3-dev \
        python3-venv \
        python3-setuptools \
        software-properties-common \
        # lsb-release \
        #cudnn8.6-cuda11.8
        # ${NV_CUDNN_PACKAGE} ${NV_CUDNN_PACKAGE_DEV} \
        # && apt-mark hold ${NV_CUDNN_PACKAGE_NAME} \
        # * Work tools
        xvfb \
        ffmpeg \ 
        freeglut3-dev \
        build-essential \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

# * Install ROS 2 (must match the Anvil Devbox: Jazzy)
RUN add-apt-repository -y universe \
    && ROS_APT_SOURCE_VERSION=$(curl -sI https://github.com/ros-infrastructure/ros-apt-source/releases/latest \
        | grep -i '^location:' | awk -F/ '{print $NF}' | tr -d '\r') \
    && curl -fsSL -o /tmp/ros2-apt-source.deb \
        "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo ${VERSION_CODENAME})_all.deb" \
    && dpkg -i /tmp/ros2-apt-source.deb \
    && rm /tmp/ros2-apt-source.deb \
    && apt update \
    && apt install -y --no-install-recommends \
        ros-${ROS_DISTRO}-desktop \
        ros-${ROS_DISTRO}-rmw-cyclonedds-cpp \
        ros-${ROS_DISTRO}-xacro \
        ros-${ROS_DISTRO}-joint-state-publisher-gui \
        ros-dev-tools \
    && rosdep init \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

# * DDS middleware (the Anvil Devbox uses CycloneDDS when ENABLE_CYCLONEDDS=true)
ENV ROS_DISTRO=${ROS_DISTRO}
ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

# * OpenGL on the NVIDIA GPU (PRIME render offload on hybrid laptops); otherwise RViz falls back
# * to llvmpipe software rendering. __GL_YIELD=USLEEP stops the driver busy-waiting on a CPU core.
ENV __NV_PRIME_RENDER_OFFLOAD=1
ENV __GLX_VENDOR_LIBRARY_NAME=nvidia
ENV __GL_YIELD=USLEEP

# * Install pip packages
# ? Ubuntu 24.04 marks the system python as externally managed (PEP 668)
ENV PIP_BREAK_SYSTEM_PACKAGES=1
# ? pip itself is installed by apt on 24.04 and cannot be upgraded in place
RUN pip3 install setuptools \
    nvitop \
    ninja \
    packaging

# ? --index-url (not --extra-index-url), otherwise pip picks the newer CUDA 13 build from PyPI
RUN pip3 install torch torchvision --index-url https://download.pytorch.org/whl/cu128

# RUN ./config/pip/pip_setup.sh

############################## USER CONFIG ####################################
# * Switch user to ${USER}
USER ${USER}

RUN ./config/shell/bash_setup.sh "${USER}" "${GROUP}" \
    && ./config/shell/terminator/terminator_setup.sh "${USER}" "${GROUP}" \
    && ./config/shell/tmux/tmux_setup.sh "${USER}" "${GROUP}" \
    && sudo rm -rf /config

RUN export CXX=g++
RUN export MAKEFLAGS="-j nproc"

RUN CUDA_PATH=$(dirname $(dirname $(which nvcc))) \
    && echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc \
    && echo 'export PATH="${CUDA_PATH}/bin:$PATH"' >> ~/.bashrc \
    && echo 'export LD_LIBRARY_PATH="${CUDA_PATH}/lib64:$LD_LIBRARY_PATH"' >> ~/.bashrc

# * ROS 2 environment
RUN rosdep update \
    && echo '' >> ~/.bashrc \
    && echo '# ROS 2' >> ~/.bashrc \
    && echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc \
    && echo '[ -f ~/work/install/setup.bash ] && source ~/work/install/setup.bash' >> ~/.bashrc \
    && echo 'source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash 2>/dev/null' >> ~/.bashrc

# * Switch workspace to ~/work
RUN sudo mkdir -p /home/"${USER}"/work
WORKDIR /home/"${USER}"/work

# * Make SSH available
EXPOSE 22

# CMD ["terminator"]
ENTRYPOINT [ "/entrypoint.sh", "terminator" ]
# ENTRYPOINT [ "/entrypoint.sh", "tmux" ]
# ENTRYPOINT [ "/entrypoint.sh", "bash" ]
# ENTRYPOINT [ "/entrypoint.sh" ]
