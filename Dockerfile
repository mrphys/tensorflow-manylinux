# docker build --tag ghcr.io/mrphys/tensorflow-manylinux:${VERSION} .
# docker push ghcr.io/mrphys/tensorflow-manylinux:${VERSION}
# https://github.com/pypa/manylinux
FROM quay.io/pypa/manylinux_2_28_x86_64

# manylinux_2_28 images support x86_64, i686, aarch64, ppc64le and s390x.
# Client-side pip version required: pip >= 20.3 
# CPython (sources) version embedding a compatible pip: 3.8.10+, 3.9.5+, 3.10.0+
# Distribution default pip compatibility: ALT Linux 10+, RHEL 9+, Debian 11+, Fedora 34+, Mageia 8+, Photon OS 3.0 with updates, Ubuntu 21.04+
#
# Toolchain: GCC 14
#   x86_64 image: quay.io/pypa/manylinux_2_28_x86_64
#   i686 image: quay.io/pypa/manylinux_2_28_i686
#   aarch64 image: quay.io/pypa/manylinux_2_28_aarch64
#   ppc64le image: quay.io/pypa/manylinux_2_28_ppc64le
#   s390x image: quay.io/pypa/manylinux_2_28_s390x
#
# Built wheels are also expected to be compatible with other distros using glibc 2.28 or later, including:
#    Debian 10+
#   Ubuntu 18.10+
#   Fedora 29+
#   CentOS/RHEL 8+

# https://www.tensorflow.org/install/source
ARG TF_VERSION=2.19
ARG CUDA_VERSION=12.5
ARG CUDNN_VERSION=9.3

ARG PY_VERSIONS="3.7 3.8 3.9 3.10"
ARG PYBIN=/usr/local/bin/python
ARG PYLIB=/usr/local/lib/python

# Environment (avoid interactive prompts)
RUN export DEBIAN_FRONTEND=noninteractive

# -------------------------------------------------
# Install CUDA repo, CUDA Toolkit, cuDNN
# -------------------------------------------------
RUN dnf install -y dnf-plugins-core wget && \
    dnf config-manager --add-repo \
        https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo && \
    dnf install -y \
        cuda-toolkit-${CUDA_VERSION/./-} \
        cudnn${CUDNN_VERSION%%.*}-cuda-${CUDA_VERSION%%.*} && \
    dnf clean all && \
    rm -rf /var/cache/dnf

# -------------------------------------------------
# System dependencies
# -------------------------------------------------
RUN dnf install -y \
        curl \
        tar \
        git \
        make \
        gcc \
        gcc-c++ \
        graphviz \
        pandoc \
        OpenEXR-libs \
        OpenEXR-devel \
    && dnf clean all \
    && rm -rf /var/cache/dnf

# -------------------------------------------------
# Python setup
# -------------------------------------------------
# manylinux ships with multiple Python versions in /opt/python
# Example: cp38-cp38, cp39-cp39, cp310-cp310, cp311-cp311, cp312-cp312
# Pick one version (default: 3.10)
ENV PATH="/opt/python/cp310-cp310/bin:${PATH}"

RUN python -m pip install --upgrade pip setuptools wheel

# Install TensorFlow on all supported Python versions.
RUN for PYVER in ${PY_VERSIONS}; do ${PYBIN}${PYVER} -m pip install tensorflow==${TF_VERSION}; done

# -------------------------------------------------
# FFTW3 (build from source)
# -------------------------------------------------
ARG PREFIX=/dt9/usr

# was 3.3.9
RUN cd /opt && \
    curl -sL http://www.fftw.org/fftw-3.3.10.tar.gz | tar xz && \
    cd fftw-3.3.10 && \
    ./configure CC="${CC}" CFLAGS="${CFLAGS}" --prefix ${PREFIX} --enable-openmp --enable-float && \
    make -j$(nproc) && \
    make install && \
    ./configure CC="${CC}" CFLAGS="${CFLAGS}" --prefix ${PREFIX} --enable-openmp && \
    make -j$(nproc) && \
    make install

# -------------------------------------------------
# Spiral waveform
# -------------------------------------------------
RUN cd /opt && \
    git clone https://github.com/mrphys/spiral-waveform --branch v1.0.0 && \
    cd spiral-waveform && \
    make install INSTALL_PREFIX=${PREFIX}

# -------------------------------------------------
# Patchelf (newer version)
# -------------------------------------------------
#was --branch 0.12
RUN cd /opt && \
    git clone https://github.com/NixOS/patchelf.git  && \
    cd patchelf && \
    ./bootstrap.sh && \
    ./configure && \
    make -j$(nproc) && \
    make check && \
    make install

# -------------------------------------------------
# Protobuf compiler
# -------------------------------------------------
# was PROTOBUF_VERSION="3.9.2"
ARG PROTOBUF_VERSION="32.1"
RUN mkdir /opt/protoc && \
    cd /opt/protoc && \
    wget https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/protoc-${PROTOBUF_VERSION}-linux-x86_64.zip && \
    unzip protoc-${PROTOBUF_VERSION}-linux-x86_64.zip && \
    cp bin/protoc /usr/local/bin/protoc

# -------------------------------------------------
# Disable Git detached head warnings
# -------------------------------------------------
RUN git config --global advice.detachedHead false

# -------------------------------------------------
# Sphinx & Python doc dependencies
# -------------------------------------------------
# was SPHINX_VERSION="4.5.0"
ARG SPHINX_VERSION="5.3.0"
# PYDATA_SPHINX_THEME_VERSION="0.8.0"
ARG PYDATA_SPHINX_THEME_VERSION="0.14.4"
# SPHINX_BOOK_THEME_VERSION="0.3.3"
ARG SPHINX_BOOK_THEME_VERSION="1.0.1"

# NEW
ARG MYST_VERSION="0.17.2"

ARG PYTHON_DEPS="sphinx==${SPHINX_VERSION} pydata-sphinx-theme==${PYDATA_SPHINX_THEME_VERSION} ipython sphinx-sitemap myst-nb==${MYST_VERSION} sphinx-book-theme==${SPHINX_BOOK_THEME_VERSION} pydot"

RUN /opt/python/cp38-cp38/bin/python -m pip install ${PYTHON_DEPS} && \
    /opt/python/cp39-cp39/bin/python -m pip install ${PYTHON_DEPS} && \
    /opt/python/cp310-cp310/bin/python -m pip install ${PYTHON_DEPS} && \
    /opt/python/cp311-cp311/bin/python -m pip install ${PYTHON_DEPS} && \
    /opt/python/cp312-cp312/bin/python -m pip install ${PYTHON_DEPS}

# -------------------------------------------------
# Patch auditwheel 
# -------------------------------------------------
# Install auditwheel for all Python versions
RUN for pybin in /opt/python/*/bin/python*; do \
      echo "Installing auditwheel for $pybin"; \
      "$pybin" -m pip install --upgrade pip setuptools wheel; \
      "$pybin" -m pip install auditwheel; \
    done

# Patch auditwheel (version-agnostic)
COPY patch_auditwheel.sh .

RUN for py in /opt/python/*/lib/python3.*; do \
      echo "Patching auditwheel for $py"; \
      ./patch_auditwheel.sh "$py"; \
    done

# -------------------------------------------------
# Install custom sphinx extensions
# -------------------------------------------------
COPY extensions /opt/sphinx/extensions

# -------------------------------------------------
# Final environment
# -------------------------------------------------
ENV LD_LIBRARY_PATH=/dt9/usr/lib:$LD_LIBRARY_PATH