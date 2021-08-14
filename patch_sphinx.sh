#!bin/bash

PYTHONLIB=${1}

TEMPLATE_PATH=${PYTHONLIB}/site-packages/sphinx/ext/autosummary/templates/autosummary

cp class.rst $TEMPLATE_PATH/
