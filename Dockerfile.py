FROM ghcr.io/mrphys/tensorflow-manylinux-base:latest

ARG PY_VERSION

# Use only the requested Python version
ENV PATH="/opt/python/cp${PY_VERSION/./}-cp${PY_VERSION/./}/bin:${PATH}"
ENV PYBIN="/opt/python/cp${PY_VERSION/./}-cp${PY_VERSION/./}/bin/python"

# Upgrade pip & install TensorFlow
# https://www.tensorflow.org/install/source
# I only see 2.16 on the tensorflow website...?
ARG TF_VERSION=2.19

RUN ${PYBIN} -m pip install --upgrade pip setuptools wheel

# ✅ Force numpy<2 to keep TensorFlow compatible
# ✅ Pin NumPy < 2 (TF 2.19 not yet compatible with NumPy 2.x)
RUN ${PYBIN} -m pip install "numpy<2" "tensorflow==${TF_VERSION}"

RUN ${PYBIN} -m pip install tensorflow==${TF_VERSION}

# ✅ Pin protobuf to match protoc (6.32.1 from Dockerfile.base)
RUN ${PYBIN} -m pip install "protobuf==6.32.1"

# -------------------------------------------------
# Python setup
# -------------------------------------------------
# manylinux ships with multiple Python versions in /opt/python
# Example: cp38-cp38, cp39-cp39, cp310-cp310, cp311-cp311, cp312-cp312
# Pick one version (default: 3.10)


# Install TensorFlow on all supported Python versions.
# RUN for PYVER in ${PY_VERSION}; do ${PYBIN}${PYVER} -m pip install tensorflow==${TF_VERSION}; done

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

ARG PYTHON_DEPS="sphinx==${SPHINX_VERSION} \
                pydata-sphinx-theme==${PYDATA_SPHINX_THEME_VERSION} \
                ipython sphinx-sitemap \
                myst-nb==${MYST_VERSION} \
                sphinx-book-theme==${SPHINX_BOOK_THEME_VERSION} \
                pydot pylint flake8 black pydantic"

RUN ${PYBIN} -m pip install ${PYTHON_DEPS}

# -------------------------------------------------
# Auditwheel
# -------------------------------------------------
RUN ${PYBIN} -m pip install --upgrade pip setuptools wheel auditwheel

COPY patch_auditwheel.sh .

RUN ./patch_auditwheel.sh "/opt/python/cp${PY_VERSION/./}-cp${PY_VERSION/./}/lib/python3.*"

# COPY extensions /opt/sphinx/extensions

# -------------------------------------------------
# Copy source, lint configs, and extensions
# -------------------------------------------------
WORKDIR /app
COPY . /app
COPY extensions /opt/sphinx/extensions

RUN ${PYBIN} -m pylint --generate-rcfile > /app/pylintrc