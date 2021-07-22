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


# # Ubuntu 16.04 has patchelf 0.9, which is a bit buggy. Install version
# # 0.12 from source.
# RUN cd /opt && \
#     git clone https://github.com/NixOS/patchelf.git --branch 0.12 && \
#     cd patchelf && \
#     ./bootstrap.sh && \
#     ./configure && \
#     make && \
#     make check && \
#     make install

# # We need the FFTW3 library for some of the `mrphys` packages.
# RUN apt-get update && \
#     apt-get install -y libfftw3-dev
