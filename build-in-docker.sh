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
    sysreqs=$(Rscript -e "cat(sysreqs::sysreq_commands(\"DESCRIPTION\"))")    
    if [[ ! -z "$sysreqs" ]]; then
	echo "$sysreqs" > sysreqs.sh
	chmod +x sysreqs.sh
	./sysreqs.sh
    fi
)

# Install package
R CMD INSTALL $package

# Create binary snapshot from it
bindir=$(Rscript -e 'd <- system.file(package="'$package'"); cat(d)')
version=$(Rscript -e 'v <- packageVersion("'$package'"); cat(as.character(v))')
tar czf ${package}_${version}.tgz -C $(dirname $bindir) $package

# Put down the filename in a file
echo ${package}_${version}.tgz > output_file

# Test loading it
rm -rf $bindir
R CMD INSTALL ${package}_${version}.tgz
if R -e 'library('$package')'; then
    exit 0
else
    exit 1
fi
