#! /bin/bash

set -ex

package=$1
repo=$2

echo "Container running"

export PATH=$(ls /opt/R-* -d)/bin:$PATH
echo "options(repos = c(CRAN = \"https://cran.r-hub.io/\"))" >> ~/.Rprofile

# Download source package and extract it
echo "Downloading source package"
pkgfile=$(Rscript -e 'p <- download.packages("'$package'", "."); cat(p[,2])')
tar xzf $pkgfile

# Install the sysreqs package
echo "Installing sysreqs package"
Rscript -e 'source("https://install-github.me/r-hub/sysreqs")'

# Install remotes package
echo "Installing remotes package"
Rscript -e 'source("https://install-github.me/mangothecat/remotes")'

# Get system requirements
echo "Querying system requirements"
(
    cd $package
    sysreqs=$(Rscript -e "cat(sysreqs::sysreq_commands(\"DESCRIPTION\", soft = FALSE))")
    if [[ ! -z "$sysreqs" ]]; then
	echo "$sysreqs" > sysreqs.sh
	chmod +x sysreqs.sh
	echo "Installing system requirements"
	./sysreqs.sh
    else
	echo "No system requirements are needed"
    fi
)

# Install package and create a binary from it
echo "Installing dependencies, package (and building binary)"
if [ ! -z "$repo" ]; then
    Rscript -e 'remotes::install_local("'$package'", INSTALL_opts = "--build", contriburl = "'$repo'")'
else
    echo "Warning: RHUB binary repo was not specified"
    Rscript -e 'remotes::install_local("'$package'", INSTALL_opts = "--build")'
fi

# Put down the filename in a file
rm $pkgfile
echo ${package}_${version}*.tar.gz > output_file
