#! /bin/bash

set -e

package=$1

export PATH=$(ls /opt/R-* -d)/bin:$PATH
echo "options(repos = c(CRAN = \"https://cran.r-hub.io/\"))" >> ~/.Rprofile

# Download source package and extract it
pkgfile=$(Rscript -e 'p <- download.packages("'$package'", "."); cat(p[,2])')
tar xzf $pkgfile

# Install the sysreqs package
Rscript -e 'source("https://install-github.me/r-hub/sysreqs")'

# Get system requirements
(
    cd $package
    sysreqs=$(Rscript -e "cat(sysreqs::sysreq_commands(\"DESCRIPTION\", soft = FALSE))")
    if [[ ! -z "$sysreqs" ]]; then
	echo "$sysreqs" > sysreqs.sh
	chmod +x sysreqs.sh
	./sysreqs.sh
    fi
)

# Install package and create a binary from it
R CMD INSTALL --build $package

# Put down the filename in a file
rm $pkgfile
echo ${package}_${version}*.tar.gz > output_file
