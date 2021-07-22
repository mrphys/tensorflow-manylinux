# TensorFlow manylinux

A `manylinux` compatible Docker image to build TensorFlow ops.

Fixes a few issues with the standard `custom-op` images.

- Patches `auditwheel` to whitelist the TensorFlow framework library.
