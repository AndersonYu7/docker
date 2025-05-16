# FROM nvidia/cuda:11.8.0-devel-ubuntu22.04
# FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu22.04
FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04
############################## SYSTEM PARAMETERS ##############################
# * Arguments
ARG USER=initial
ARG GROUP=initial
ARG UID=1000
ARG GID="${UID}"
ARG SHELL=/bin/bash
ARG HARDWARE=x86_64
ARG ENTRYPOINT_FILE=entrypint.sh

# * Env vars for the nvidia-container-runtime.
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES all
# ENV NVIDIA_DRIVER_CAPABILITIES graphics,utility,compute

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
RUN sed -i 's@archive.ubuntu.com@ubuntu.cs.nycu.edu.tw/@g' /etc/apt/sources.list
# ? Change to Taiwan
# RUN sed -i 's@archive.ubuntu.com@tw.archive.ubuntu.com@g' /etc/apt/sources.list

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

# * Install pip packages
RUN pip3 install --upgrade pip \
    && pip3 install setuptools

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
