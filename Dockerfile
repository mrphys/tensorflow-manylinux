# docker build --tag ghcr.io/mrphys/tensorflow-manylinux:${VERSION} .
# docker push ghcr.io/mrphys/tensorflow-manylinux:${VERSION}
FROM gcr.io/tensorflow-testing/nosla-cuda11.2-cudnn8.1-ubuntu20.04-manylinux2014-multipython@sha256:48612bd85709cd014711d0b0f87e0806f3567d06d2e81c6e860516b87498b821

ARG PYBIN=/usr/local/bin/python
ARG PYLIB=/usr/local/lib/python
ARG TF_VERSION=2.11.0
ARG PY_VERSIONS="3.7 3.8 3.9 3.10"

# Uninstall some nightly packages.
ARG PACKAGES_TO_UNINSTALL="keras-nightly tf-estimator-nightly tb-nightly"
RUN for PYVER in ${PY_VERSIONS}; do ${PYBIN}${PYVER} -m pip uninstall -y ${PACKAGES_TO_UNINSTALL}; done

# Install TensorFlow on all supported Python versions.
RUN for PYVER in ${PY_VERSIONS}; do ${PYBIN}${PYVER} -m pip install tensorflow==${TF_VERSION}; done

# Install Git LFS.
RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash && \
    apt-get update && \
    apt-get install git-lfs && \
    git lfs install

# Copy CUDA headers to TF installation.
ARG CUDA_INCLUDE=/usr/local/cuda/targets/x86_64-linux/include
ARG TF_CUDA_INCLUDE=site-packages/tensorflow/include/third_party/gpus/cuda/include

RUN mkdir -p ${PYLIB}3.7/${TF_CUDA_INCLUDE} && \
    cp -r ${CUDA_INCLUDE}/* ${PYLIB}3.7/${TF_CUDA_INCLUDE} && \
    mkdir -p ${PYLIB}3.8/${TF_CUDA_INCLUDE} && \
    cp -r ${CUDA_INCLUDE}/* ${PYLIB}3.8/${TF_CUDA_INCLUDE} && \
    mkdir -p ${PYLIB}3.9/${TF_CUDA_INCLUDE} && \
    cp -r ${CUDA_INCLUDE}/* ${PYLIB}3.9/${TF_CUDA_INCLUDE} && \
    mkdir -p ${PYLIB}3.10/${TF_CUDA_INCLUDE} && \
    cp -r ${CUDA_INCLUDE}/* ${PYLIB}3.10/${TF_CUDA_INCLUDE}

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

# Using devtoolset with correct manylinux2014 libraries.
ARG PREFIX=/dt9/usr
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

# Install spiral waveform.
RUN cd /opt && \
    git clone https://github.com/mrphys/spiral-waveform --branch v1.0.0 && \
    cd spiral-waveform && \
    make install INSTALL_PREFIX=${PREFIX}

# Install system dependencies.
RUN apt-get update && \
    apt-get install -y libopenexr-dev pandoc graphviz

# Install other Python dependencies.
ARG SPHINX_VERSION="4.5.0"
ARG PYDATA_SPHINX_THEME_VERSION="0.8.0"
ARG SPHINX_BOOK_THEME_VERSION="0.3.3"
ARG PYTHON_DEPS="sphinx==${SPHINX_VERSION} pydata-sphinx-theme==${PYDATA_SPHINX_THEME_VERSION} ipython sphinx-sitemap myst-nb sphinx-book-theme==${SPHINX_BOOK_THEME_VERSION} pydot"
RUN ${PYBIN}3.7 -m pip install ${PYTHON_DEPS} && \
    ${PYBIN}3.8 -m pip install ${PYTHON_DEPS} && \
    ${PYBIN}3.9 -m pip install ${PYTHON_DEPS} && \
    ${PYBIN}3.10 -m pip install ${PYTHON_DEPS}

# Patch auditwheel.
COPY patch_auditwheel.sh .
RUN ./patch_auditwheel.sh ${PYLIB}3.7 && \
    ./patch_auditwheel.sh ${PYLIB}3.8 && \
    ./patch_auditwheel.sh ${PYLIB}3.9 && \
    ./patch_auditwheel.sh ${PYLIB}3.10

# Install custom sphinx extensions.
COPY extensions /opt/sphinx/extensions

# Install protoc.
ARG PROTOBUF_VERSION="3.9.2"
RUN mkdir /opt/protoc && \
    cd /opt/protoc && \
    wget https://github.com/google/protobuf/releases/download/v${PROTOBUF_VERSION}/protoc-${PROTOBUF_VERSION}-linux-x86_64.zip && \
    unzip /opt/protoc/protoc-${PROTOBUF_VERSION}-linux-x86_64.zip && \
    cp bin/protoc /usr/local/bin/protoc

ENV LD_LIBRARY_PATH=/dt9/usr/lib:$LD_LIBRARY_PATH
