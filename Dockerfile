# 1. Use an NVIDIA base image compatible with target CUDA version (e.g., 12.1)
FROM nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04
ENV DEBIAN_FRONTEND=noninteractive

# 2. Install Miniconda prerequisites
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    bzip2 \
    ca-certificates \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 3. Install Miniconda
ENV CONDA_DIR=/opt/conda
ENV PATH=${CONDA_DIR}/bin:${PATH}
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p ${CONDA_DIR} && \
    rm ~/miniconda.sh && \
    conda init bash && \
    conda config --set auto_activate_base false && \
    conda config --set changeps1 False

SHELL ["/bin/bash", "--login", "-c"]

# 4. Create the dedicated environment (as recommended by micro_sam docs)
ENV CONDA_ENV_NAME=micro-sam
ENV PYTHON_VERSION=3.10
RUN conda create -n ${CONDA_ENV_NAME} python=${PYTHON_VERSION} -y

# 5. Install micro_sam using conda-forge AND specify PyTorch GPU version
ARG CUDA_VERSION_SHORT=12.1
RUN conda run -n ${CONDA_ENV_NAME} conda install \
    -c pytorch \
    -c nvidia \
    -c conda-forge \
    micro_sam \
    pytorch \
    torchvision \
    torchaudio \
    pytorch-cuda=${CUDA_VERSION_SHORT} \
    -y

# 6. Clean up conda cache (optional)
RUN conda run -n ${CONDA_ENV_NAME} conda clean --all -f -y

# 7. Add Jupyter to the environment for notebook support
RUN conda run -n ${CONDA_ENV_NAME} conda install -c conda-forge jupyter ipywidgets -y

# 8. Create entrypoint script that will work with both Docker and Singularity
RUN echo '#!/bin/bash' > /entrypoint.sh && \
    echo 'source ${CONDA_DIR}/etc/profile.d/conda.sh' >> /entrypoint.sh && \
    echo 'conda activate ${CONDA_ENV_NAME}' >> /entrypoint.sh && \
    echo 'exec "$@"' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

# 9. Set working directory
WORKDIR /app

# 10. Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# 11. Default command (if no command is provided)
CMD ["bash"]