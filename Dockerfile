FROM gcr.io/tensorflow-testing/nosla-cuda11.2-cudnn8.1-ubuntu18.04-manylinux2010-multipython:latest

ARG PYTHON36=/usr/local/bin/python3.6
ARG PYTHON37=/usr/local/bin/python3.7
ARG PYTHON38=/usr/local/bin/python3.8
ARG PYTHON39=/usr/local/bin/python3.9

# Install TensorFlow on all supported Python versions.
RUN ${PYTHON36} -m pip install tensorflow && \
    ${PYTHON37} -m pip install tensorflow && \
    ${PYTHON38} -m pip install tensorflow && \
    ${PYTHON39} -m pip install tensorflow

# Patch auditwheel.
COPY patch_auditwheel.sh .
RUN ./patch_auditwheel.sh $(echo "${PYTHON36}" | sed "s/bin/lib/") && \
    ./patch_auditwheel.sh $(echo "${PYTHON37}" | sed "s/bin/lib/") && \
    ./patch_auditwheel.sh $(echo "${PYTHON38}" | sed "s/bin/lib/") && \
    ./patch_auditwheel.sh $(echo "${PYTHON39}" | sed "s/bin/lib/")

# Dependencies of some `mrphys` packages.
RUN apt-get update && \
    apt-get install -y libfftw3-dev libopenexr-dev

# Install other Python dependencies.
ARG PYTHON_DEPS="sphinx furo"
RUN ${PYTHON36} -m pip install ${PYTHON_DEPS} && \
    ${PYTHON37} -m pip install ${PYTHON_DEPS} && \
    ${PYTHON38} -m pip install ${PYTHON_DEPS} && \
    ${PYTHON39} -m pip install ${PYTHON_DEPS}
