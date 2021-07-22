#!bin/bash

# This script adds the TensorFlow framework library to the auditwheel whitelist.
# As a result auditwheel will be happy with the fact that this package links
# against TensorFlow.
PYTHONLIB=${1}

TF_SHARED_LIBRARY_NAME=libtensorflow_framework.so.2

AUDITWHEEL_POLICY_JSON=${PYTHONLIB}/site-packages/auditwheel/policy/policy.json

sed -i "s/libresolv.so.2\"/libresolv.so.2\", \"$TF_SHARED_LIBRARY_NAME\"/g" $AUDITWHEEL_POLICY_JSON
