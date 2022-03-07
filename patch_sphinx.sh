#!bin/bash
set -e

PYTHONLIB=${1}

TEMPLATE_PATH=${PYTHONLIB}/site-packages/sphinx/ext/autosummary/templates/autosummary
cp class.rst ${TEMPLATE_PATH}/

# The following patches the autosummary extension so that only object names are
# added to the toctrees, rather than the fully qualified names.
SEARCH_STRING="tocnode\['entries'\] = \[(None, docn) for docn in docnames\]"
REPLACE_STRING="tocnode\['entries'\] = \[(docn.split('\/')[-1], docn) for docn in docnames\]"
FILE_PATH=${PYTHONLIB}/site-packages/sphinx/ext/autosummary/__init__.py
sed -i "s/${SEARCH_STRING}/${REPLACE_STRING}/" ${FILE_PATH}
