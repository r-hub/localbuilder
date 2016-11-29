#! /bin/bash

export PATH=$(ls /opt/R-* -d)/bin:$PATH
echo "options(repos = c(CRAN = \"https://cran.r-hub.io/\"))" >> ~/.Rprofile

# Install the sysreqs package
echo "Installing sysreqs package"
Rscript -e 'source("https://install-github.me/r-hub/sysreqs")'

# Install remotes package
echo "Installing remotes package"
Rscript -e 'source("https://install-github.me/mangothecat/remotes")'
