#! /bin/bash

usage() {
    echo "Usage: $0 <image> <repodir>"
}

set -ex

image=$1
repodir=$2

if [[ -z "$image" || -z "$repodir" ]]; then usage; exit 1; fi

# In case it does not exist or not a proper repo
mkdir -p $repodir
Rscript -e 'tools::write_PACKAGES("'$repodir'")'

echo "Installing crandeps package"
Rscript -e 'source("https://install-github.me/r-hub/crandeps")'

echo "Calculating topological package order"
pkgs=$(Rscript -e 'cat(crandeps::cran_topo_sort(), sep = "\\n")')
numpkgs=$(echo "$pkgs" | wc -w)

echo "Listing packages already built"
repourl=$(Rscript -e 'cat(paste0("file://", normalizePath("'$repodir'")))')
ready=$(Rscript -e 'd <- "'$repourl'"; cat(rownames(available.packages(contriburl = d)), sep = "\\n")')
numready=$(echo "$ready" | wc -w)
tobuild=$(($numpkgs - $numready))

echo $numpkgs packages, $numready done, building $tobuild

echo > build.log

x=1
for pkg in $pkgs; do
    echo -n "[$x/$tobuild] $pkg "
    if echo "$ready" | grep -q '^'$pkg'$'; then
	echo "already built"
    else
	echo "building"
	./make-binary-package.sh "$image" "$pkg" "$repourl" 2>&1 >>build.log
    fi

    x=$(($x + 1))
done
