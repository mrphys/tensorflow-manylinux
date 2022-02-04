#!bin/bash

# This script adds the TensorFlow framework library and the CUDA libraries to
# the auditwheel whitelist. As a result auditwheel will not attempt to package
# these libraries with the wheel.
PYTHONLIB=${1}

TF_SHARED_LIBRARY_NAME=libtensorflow_framework.so.2

AUDITWHEEL_POLICY_JSON=${PYTHONLIB}/site-packages/auditwheel/policy/manylinux-policy.json

WHITELIST="\"$TF_SHARED_LIBRARY_NAME\", \"libcudart.so.11.0\", \"libnvToolsExt.so.1\""

sed -i "s/libresolv.so.2\"/libresolv.so.2\", $WHITELIST/g" $AUDITWHEEL_POLICY_JSON
