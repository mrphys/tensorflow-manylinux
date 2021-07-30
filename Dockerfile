FROM gcr.io/tensorflow-testing/nosla-cuda11.2-cudnn8.1-ubuntu18.04-manylinux2010-multipython:latest

ARG PYBIN=/usr/local/bin/python
ARG PYLIB=/usr/local/lib/python

# Install TensorFlow on all supported Python versions.
RUN ${PYBIN}3.6 -m pip install tensorflow && \
    ${PYBIN}3.7 -m pip install tensorflow && \
    ${PYBIN}3.8 -m pip install tensorflow && \
    ${PYBIN}3.9 -m pip install tensorflow

# Patch auditwheel.
COPY patch_auditwheel.sh .
RUN ./patch_auditwheel.sh ${PYLIB}3.6 && \
    ./patch_auditwheel.sh ${PYLIB}3.7 && \
    ./patch_auditwheel.sh ${PYLIB}3.8 && \
    ./patch_auditwheel.sh ${PYLIB}3.9

# Dependency of tensorflow-graphics.
RUN apt-get update && \
    apt-get install -y libopenexr-dev

# Install other Python dependencies.
ARG PYTHON_DEPS="sphinx furo"
RUN ${PYBIN}3.6 -m pip install ${PYTHON_DEPS} && \
    ${PYBIN}3.7 -m pip install ${PYTHON_DEPS} && \
    ${PYBIN}3.8 -m pip install ${PYTHON_DEPS} && \
    ${PYBIN}3.9 -m pip install ${PYTHON_DEPS}

# Install a newer Git version (GitHub Actions requires 2.18+ as of July 2021).
RUN add-apt-repository -y ppa:git-core/ppa && \
    apt-get update && \
    apt-get install -y git

# Install Git LFS.
RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash && \
    apt-get update && \
    apt-get install git-lfs && \
    git lfs install

ARG PREFIX=/dt7/usr
ARG CC="${PREFIX}/bin/gcc"
ARG CXX="${PREFIX}/bin/g++"
ARG LIBDIR="${PREFIX}/lib"
ARG CFLAGS="-O3 -march=x86-64 -mtune=generic -mavx2 -fPIC"

RUN cd /opt && \
    curl -sL http://www.fftw.org/fftw-3.3.9.tar.gz | tar xz && \ 
    cd fftw-3.3.9 && \
    ./configure CC="${CC}" CFLAGS="${CFLAGS}" --prefix ${PREFIX} --enable-openmp --enable-float && \
    make && \
    make install && \
    ./configure CC="${CC}" CFLAGS="${CFLAGS}" --prefix ${PREFIX} --enable-openmp && \
    make && \
    make install

RUN cd /opt && \
    git clone https://github.com/mrphys/finufft && \
    cd finufft && \
    make lib CXX="${CXX}" CFLAGS="${CFLAGS} -funroll-loops -fcx-limited-range" && \
    cp -r . /dt7/usr/include/finufft && \
    cp lib-static/libfinufft.a ${LIBDIR}/

RUN cd /opt && \
    git clone https://github.com/mrphys/cufinufft --branch release && \
    cd cufinufft && \
    make lib CXX="${CXX}" CFLAGS="${CFLAGS} -funroll-loops" && \
    cp -r . /dt7/usr/include/cufinufft && \
    cp lib-static/libcufinufft.a ${LIBDIR}/

ARG CUDA_INCLUDE=/usr/local/cuda/targets/x86_64-linux/include
ARG TF_CUDA_INCLUDE=site-packages/tensorflow/include/third_party/gpus/cuda/include

RUN mkdir -p ${PYLIB}3.6/${TF_CUDA_INCLUDE} && \
    cp -r ${CUDA_INCLUDE}/* ${PYLIB}3.6/${TF_CUDA_INCLUDE} && \
    mkdir -p ${PYLIB}3.7/${TF_CUDA_INCLUDE} && \
    cp -r ${CUDA_INCLUDE}/* ${PYLIB}3.7/${TF_CUDA_INCLUDE} && \
    mkdir -p ${PYLIB}3.8/${TF_CUDA_INCLUDE} && \
    cp -r ${CUDA_INCLUDE}/* ${PYLIB}3.8/${TF_CUDA_INCLUDE} && \
    mkdir -p ${PYLIB}3.9/${TF_CUDA_INCLUDE} && \
    cp -r ${CUDA_INCLUDE}/* ${PYLIB}3.9/${TF_CUDA_INCLUDE}

ENV LD_LIBRARY_PATH=/dt7/usr/lib:$LD_LIBRARY_PATH
