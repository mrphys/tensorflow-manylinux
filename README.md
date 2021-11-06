# TensorFlow manylinux

[![build](https://github.com/mrphys/tensorflow-manylinux/actions/workflows/build-image.yml/badge.svg)](https://github.com/mrphys/tensorflow-manylinux/actions/workflows/build-image.yml)

A `manylinux` compatible Docker image to build the `mrphys` TensorFlow ops. It
is based on `manylinux` and `multipython` Docker images created by the
TensorFlow team. Then the following changes are applied.

  - Install TensorFlow on all Python versions.
  - Patch `auditwheel` to whitelist the TensorFlow framework library.
  - Install some system dependencies for `mrphys` or third-party packages.
  - Install dependencies for docs.
  - Install latest Git version.
  - Compile FFTW3 and FINUFFT for generic x86-64 architectures.
  - Patch TensorFlow installations to add CUDA headers.
  - Install `patchelf` 0.12 from source to fix an
    [issue](https://github.com/pypa/auditwheel/issues/103) with `auditwheel`.
  - Install `spiral_waveform`.
  - Patch `sphinx` to add custom `autosummary` templates.

TensorFlow Versions
^^^^^^^^^^^^^^^^^^^

Each manylinux image has a specific TensorFlow version as detailed below:

| TensorFlow manylinux | TensorFlow |
| -------------------- | ---------- |
| v1.7                 | v2.6       |
| v1.8                 | v2.7       |
