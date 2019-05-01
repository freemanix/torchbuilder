ARG cuda_version=10.0
ARG cudnn_version=7
ARG ubuntu=18.04
FROM nvidia/cuda:${cuda_version}-cudnn${cudnn_version}-devel-ubuntu${ubuntu}

USER root
WORKDIR /root

RUN apt-get -y update && apt-get -y upgrade
RUN apt-get -y install g++ git libgflags-dev libgoogle-glog-dev\
    libiomp-dev libopenmpi-dev protobuf-compiler\
    python3 python3-pip python3-setuptools python3-yaml wget

# Install CMake 3.14

ARG CMAKE=cmake-3.14.1.tar.gz
RUN wget https://github.com/Kitware/CMake/releases/download/v3.14.1/${CMAKE}
RUN tar xvzf ${CMAKE} && cd cmake* && ./bootstrap --parallel=$(nproc)
RUN cd cmake* && make -j$(nproc) && make install

# Intel MKL installation

RUN wget https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB
RUN apt-key add GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB && rm GPG-PUB*
RUN sh -c 'echo deb https://apt.repos.intel.com/mkl all main > /etc/apt/sources.list.d/intel-mkl.list'
RUN apt-get update && apt-get -y install intel-mkl-64bit-2019.1-053
RUN rm /opt/intel/mkl/lib/intel64/*.so

# Download and build libtorch with MKL support

ENV TORCH_CUDA_ARCH_LIST="5.2 6.0 6.1 7.0 7.5"
ENV TORCH_NVCC_FLAGS="-Xfatbin -compress-all"
RUN git clone --recurse-submodules -j8 https://github.com/pytorch/pytorch.git
RUN cd pytorch && mkdir build && cd build && BUILD_TEST=OFF USE_NCCL=OFF python3 ../tools/build_libtorch.py

# Prepare built package

RUN cd && mkdir -p libtorch/include && mkdir -p libtorch/share
RUN cp -r pytorch/build/lib libtorch
RUN cp -r pytorch/torch/share/cmake libtorch/share/cmake
RUN for dir in ATen c10 caffe2 torch; do cp -r pytorch/torch/include/$dir libtorch/include; done

CMD [ "/bin/bash", "-" ]
