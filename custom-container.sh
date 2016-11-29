#! /bin/bash

. urls.sh

export PATH=$(ls /opt/R-* -d)/bin:$PATH
echo "options(repos = c(CRAN = \"${CRAN_MIRROR_URL}/\"))" >> ~/.Rprofile

# Install the sysreqs package
echo "Installing sysreqs package"
Rscript -e 'source("'$SYSREQS_URL'")'

# Install remotes package
echo "Installing remotes package"
Rscript -e 'source("'$REMOTES_URL'")'
