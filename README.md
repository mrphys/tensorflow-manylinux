# TensorFlow manylinux

[![build](https://github.com/mrphys/tensorflow-manylinux/actions/workflows/build-image.yml/badge.svg)](https://github.com/mrphys/tensorflow-manylinux/actions/workflows/build-image.yml)

A `manylinux` compatible Docker image to build TensorFlow ops. It is based on
`manylinux` and `multipython` Docker images created by the TensorFlow team. Then
the following changes are applied.

  - Install TensorFlow on all Python versions.
  - Patch `auditwheel` to whitelist the TensorFlow framework library.
  - Install some dependencies required by other `mrphys` packages.
