FROM gcr.io/tensorflow-testing/nosla-cuda11.2-cudnn8.1-ubuntu18.04-manylinux2010-multipython:latest

ARG PYBIN=/usr/local/bin/python
ARG PYLIB=/usr/local/lib/python
ARG TF_VERSION=2.6.0

# Install TensorFlow on all supported Python versions.
RUN ${PYBIN}3.6 -m pip install tensorflow==${TF_VERSION} && \
    ${PYBIN}3.7 -m pip install tensorflow==${TF_VERSION} && \
    ${PYBIN}3.8 -m pip install tensorflow==${TF_VERSION} && \
    ${PYBIN}3.9 -m pip install tensorflow==${TF_VERSION}

# Install a newer Git version (GitHub Actions requires 2.18+ as of July 2021).
RUN add-apt-repository -y ppa:git-core/ppa && \
    apt-get update && \
    apt-get install -y git

# Install Git LFS.
RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash && \
    apt-get update && \
    apt-get install git-lfs && \
    git lfs install

# Copy CUDA headers to TF installation.
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

# Ubuntu 18.04 has patchelf 0.9, which has a number of bugs. Install version
# 0.12 from source.
RUN cd /opt && \
    git clone https://github.com/NixOS/patchelf.git --branch 0.12 && \
    cd patchelf && \
    ./bootstrap.sh && \
    ./configure && \
    make && \
    make check && \
    make install

# Install system dependencies.
RUN apt-get update && \
    apt-get install -y libopenexr-dev pandoc

# Install other Python dependencies.
ARG PYTHON_DEPS="sphinx furo nbsphinx ipython"
RUN ${PYBIN}3.6 -m pip install ${PYTHON_DEPS} && \
    ${PYBIN}3.7 -m pip install ${PYTHON_DEPS} && \
    ${PYBIN}3.8 -m pip install ${PYTHON_DEPS} && \
    ${PYBIN}3.9 -m pip install ${PYTHON_DEPS}

# Using devtoolset with correct manylinux2010 libraries.
ARG PREFIX=/dt7/usr
ARG CC="${PREFIX}/bin/gcc"
ARG CXX="${PREFIX}/bin/g++"
ARG LIBDIR="${PREFIX}/lib"
ARG INCLUDEDIR="${PREFIX}/include"
ARG CFLAGS="-O3 -march=x86-64 -mtune=generic -fPIC"

# Install FFTW3.
RUN cd /opt && \
    curl -sL http://www.fftw.org/fftw-3.3.9.tar.gz | tar xz && \ 
    cd fftw-3.3.9 && \
    ./configure CC="${CC}" CFLAGS="${CFLAGS}" --prefix ${PREFIX} --enable-openmp --enable-float && \
    make && \
    make install && \
    ./configure CC="${CC}" CFLAGS="${CFLAGS}" --prefix ${PREFIX} --enable-openmp && \
    make && \
    make install

# Disable Git detached head warnings.
RUN git config --global advice.detachedHead false

# Install FINUFFT.
RUN cd /opt && \
    git clone https://github.com/mrphys/finufft --branch mrphys/v1.0.0 && \
    cd finufft && \
    make lib CXX="${CXX}" CFLAGS="${CFLAGS} -DFFTW_PLAN_SAFE -funroll-loops -fcx-limited-range" && \
    cp -r . ${INCLUDEDIR}/finufft && \
    cp lib-static/libfinufft.a ${LIBDIR}/

# Install CUFINUFFT.
RUN cd /opt && \
    git clone https://github.com/mrphys/cufinufft --branch mrphys/v1.2.2 && \
    cd cufinufft && \
    make -j $(nproc) lib CXX="${CXX}" CFLAGS="${CFLAGS} -funroll-loops" && \
    cp -r . ${INCLUDEDIR}/cufinufft && \
    cp lib-static/libcufinufft.a ${LIBDIR}/

# Install spiral waveform.
RUN cd /opt && \
    git clone https://github.com/mrphys/spiral-waveform --branch v1.0.0 && \
    cd spiral-waveform && \
    make install INSTALL_PREFIX=${PREFIX}

# Patch auditwheel.
COPY patch_auditwheel.sh .
RUN ./patch_auditwheel.sh ${PYLIB}3.6 && \
    ./patch_auditwheel.sh ${PYLIB}3.7 && \
    ./patch_auditwheel.sh ${PYLIB}3.8 && \
    ./patch_auditwheel.sh ${PYLIB}3.9

# Patch sphinx.
COPY patch_sphinx.sh .
COPY class.rst .
RUN ./patch_sphinx.sh ${PYLIB}3.6 && \
    ./patch_sphinx.sh ${PYLIB}3.7 && \
    ./patch_sphinx.sh ${PYLIB}3.8 && \
    ./patch_sphinx.sh ${PYLIB}3.9

ENV LD_LIBRARY_PATH=/dt7/usr/lib:$LD_LIBRARY_PATH
