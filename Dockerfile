FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV VIRTUAL_ENV=/app/.venv
ENV PATH="/app/.venv/bin:$PATH"
ENV LD_LIBRARY_PATH="/app/.venv/lib/python3.10/site-packages/torch/lib:${LD_LIBRARY_PATH}"
ENV TORCH_CUDA_ARCH_LIST="8.6;8.9;9.0;12.0+PTX"
ENV CMAKE_CUDA_ARCHITECTURES="86;89;90;120"
ENV FORCE_CUDA=1
ENV MAX_JOBS=4
ENV PYOPENGL_PLATFORM=egl
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics

RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    && add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update && apt-get install -y --no-install-recommends \
    python3.10 python3.10-venv python3.10-dev \
    git build-essential cmake ninja-build pkg-config \
    libgl1 libglib2.0-0 libsm6 libxrender1 libxext6 \
    libglvnd0 libglx0 libegl1 libgles2 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN python3.10 -m venv /app/.venv

RUN pip install --upgrade pip setuptools wheel packaging

RUN pip install --no-cache-dir torch==2.7.1 torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/cu128

RUN echo "$VIRTUAL_ENV/lib/python3.10/site-packages/torch/lib" > /etc/ld.so.conf.d/torch.conf && ldconfig

ARG CACHEBUST=1
RUN git clone -b main https://github.com/mthodoris/NeuS.git

WORKDIR /app/NeuS

RUN pip install --no-cache-dir -r requirements.txt

RUN python -c "import torch; print(torch.__version__, torch.version.cuda); print(torch.cuda.get_arch_list())"

ENTRYPOINT ["bash", "-c", "git pull origin main && exec \"$@\"", "--"]
WORKDIR /app/NeuS

CMD ["/bin/bash"]
