ARG CUDA_IMAGE_TAG=11.8.0
ARG OS_VERSION=22.04
ARG USER_ID=1000
# Define base image.

FROM nvidia/cuda:${CUDA_IMAGE_TAG}-devel-ubuntu${OS_VERSION}
ARG CUDA_IMAGE_TAG
ARG OS_VERSION
ARG USER_ID

# metainformation
LABEL org.opencontainers.image.version = "0.1.18"
LABEL org.opencontainers.image.source = "https://github.com/nerfstudio-project/nerfstudio"
LABEL org.opencontainers.image.licenses = "Apache License 2.0"
LABEL org.opencontainers.image.base.name="docker.io/library/nvidia/cuda:${CUDA_IMAGE_TAG}-devel-ubuntu${OS_VERSION}"

# Variables used at build time.
## CUDA architectures, required by Colmap and tiny-cuda-nn.
## NOTE: All commonly used GPU architectures are included and supported here. To speedup the image build process remove all architectures but the one of your explicit GPU. Find details here: https://developer.nvidia.com/cuda-gpus (8.6 translates to 86 in the line below) or in the docs.
ARG CUDA_ARCHITECTURES=86;80;75

# Set environment variables.
## Set non-interactive to prevent asking for user inputs blocking image creation.
ENV DEBIAN_FRONTEND=noninteractive
## Set timezone as it is required by some packages.
ENV TZ=Europe/Berlin
## CUDA Home, required to find CUDA in some packages.
ENV CUDA_HOME="/usr/local/cuda"

# Install required apt packages and clear cache afterwards.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    curl \
    ffmpeg \
    git \
    nano \
    sudo \
    vim-tiny \
    wget \
    libglfw3-dev libegl1-mesa-dev \
    libgl1-mesa-dev \
    libgles2-mesa-dev \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /programs

ARG PYTHON_VERSION=3.10
ARG PYTORCH_VERSION=1.13.1
ARG TORCHVISION_VERSION=0.14.1
ARG CUDA=11.7

RUN export CUDA_SHORT=$(echo "$CUDA" | sed "s/[.]//") && \
     curl -o ~/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
     chmod +x ~/miniconda.sh && \
     bash ~/miniconda.sh -b -p /opt/conda && \
     rm ~/miniconda.sh && \
     /opt/conda/bin/conda install -y python=$PYTHON_VERSION cython && \
     /opt/conda/bin/conda install -y -c pytorch magma-cuda$(echo "$CUDA" | sed "s/[.]//") && \
     /opt/conda/bin/conda clean -ya && \
     rm -rf /root/.cache/
ENV PATH /opt/conda/bin:$PATH

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on

# now use pip to install to avoid conda install all cuda stuff again, and clean cache afterwards (it's ~3G cache!)
RUN export CUDA_SHORT=$(echo "$CUDA" | sed "s/[.]//") && \
    pip install --no-cache-dir mkl-include==2023.0.0 && \
    pip install --no-cache-dir torch==${PYTORCH_VERSION}+cu$CUDA_SHORT torchvision==${TORCHVISION_VERSION}+cu$CUDA_SHORT --extra-index-url https://download.pytorch.org/whl/cu$CUDA_SHORT && \
    rm -rf /root/.cache/


ENV TCNN_CUDA_ARCHITECTURES=${CUDA_ARCHITECTURES}
RUN python -m pip install git+https://github.com/NVlabs/tiny-cuda-nn.git@v1.6#subdirectory=bindings/torch
RUN #pip install git+https://github.com/KAIR-BAIR/nerfacc.git@v0.5.2

#nerfw
RUN pip install kornia einops torch_optimizer lightning\<2.1.0  PyMCubes trimesh plyfile
#    python -m pip install mmcv-full==1.6.0 -f https://download.openmmlab.com/mmcv/dist/cu113/torch1.12/index.html && \
#    python -m pip install mmsegmentation==0.30.0

# Install nerfstudio dependencies.
RUN pip install git+https://github.com/Dawars/sdfstudio.git@historic && pip uninstall nerfstudio -y
RUN export CUDA_SHORT=$(echo "$CUDA" | sed "s/[.]//") && \
    pip install nerfacc -f https://nerfacc-bucket.s3.us-west-2.amazonaws.com/whl/torch-${PYTORCH_VERSION}_cu${CUDA_SHORT}.html
RUN export CUDA_SHORT=$(echo "$CUDA" | sed "s/[.]//") && \
    IGNORE_TORCH_VER=1 pip install git+https://github.com/Dawars/kaolin.git pyrender

RUN pip install git+https://github.com/Dawars/Hierarchical-Localization.git@f46d20bc58a275916c5ead68cd88dd20d79a158e

# threestudio
RUN pip install omegaconf==2.3.0 jaxtyping typeguard diffusers<0.20 transformers==4.28.1 accelerate \
    imageio>=2.28.0 imageio[ffmpeg] git+https://github.com/NVlabs/nvdiffrast.git libigl xatlas trimesh[easy] networkx pysdf \
     gradio==4.11.0 git+https://github.com/ashawkey/envlight.git xformers bitsandbytes==0.38.1 sentencepiece safetensors \
     huggingface_hub taming-transformers-rom1504 git+https://github.com/openai/CLIP.git controlnet_aux

# Create non root user and setup environment.
RUN useradd -m -d /programs -g root -G sudo -u ${USER_ID} user
RUN usermod -aG sudo user
# Set user password
RUN echo "user:user" | chpasswd
# Ensure sudo group users are not asked for a password when using sudo command by ammending sudoers file
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers


# Switch to new uer and workdir.
USER root
RUN chmod -R a+w /programs
RUN chown -R  ${USER_ID} /programs
USER ${USER_ID}
WORKDIR /programs
#RUN chmod -R a+w /programs
# Add local user binary folder to PATH variable.
ENV PATH="${PATH}:/programs/.local/bin"
#SHELL ["/bin/bash", "-c"]



# Copy nerfstudio folder and give ownership to user.
#ADD . /home/user/nerfstudio
#USER root
#RUN chmod -R a+w /programs
#RUN chown -R  ${USER_ID} /programs
#USER ${USER_ID}

# Change working directory
WORKDIR /workspace

# Install nerfstudio cli auto completion and enter shell if no command was provided.
# CMD ns-install-cli --mode install && /bin/bash

