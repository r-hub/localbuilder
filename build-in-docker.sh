#! /bin/bash

set -e

package=$1

. urls.sh

echo "Container running"

export PATH=$(ls /opt/R-* -d)/bin:$PATH
echo "options(repos = c(CRAN = \"${CRAN_MIRROR_URL}/\"))" >> ~/.Rprofile

# Download source package and extract it
echo "Downloading source package"
pkgfile=$(Rscript -e 'p <- download.packages("'$package'", "."); cat(p[,2])')
tar xzf $pkgfile

# Install the sysreqs package
echo "Installing sysreqs package (if not installed)"
Rscript -e 'if (! requireNamespace("sysreqs", quietly = TRUE)) source("'$SYSREQS_URL'")'

# Install remotes package
echo "Installing remotes package (if not installed)"
Rscript -e 'if (! requireNamespace("remotes", quietly = TRUE)) source("'$REMOTES_URL'")'

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

# Install package dependencies
echo "Installing dependencies"
Rscript -e 'remotes::install_deps("'$package'", contriburl = "file:///cran")'

# Install package and create a binary from it
echo "Installing package (and building binary)"
Rscript -e 'remotes::install_local("'$package'", INSTALL_opts = "--build")'

# Put down the filename in a file
rm $pkgfile
mv ${package}_*.tar.gz $pkgfile || exit 1
mv $pkgfile /cran
