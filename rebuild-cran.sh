#! /bin/bash

usage() {
    echo "Usage: $0 <image> <repodir>"
}

image=$1
repodir=$2

. urls.sh

if [[ -z "$image" || -z "$repodir" ]]; then usage; exit 1; fi

# In case it does not exist or not a proper repo
mkdir -p $repodir
Rscript -e 'tools::write_PACKAGES("'$repodir'")'

echo "Installing crandeps package"
Rscript -e 'if (!requireNamespace("crandeps", quietly = TRUE)) source("'$CRANDEPS_URL'")'

contid=$(cat /dev/urandom | LC_CTYPE=C  tr -dc 'a-zA-Z0-9' |
		fold -w 32 | head -n 1)

echo "Creating a custom container"
docker run -t -v `pwd`/custom-container.sh:/custom-container.sh \
       -v `pwd`/urls.sh:/urls.sh \
       --name $contid ${image} bash /custom-container.sh

newimage=$(docker commit $contid)

echo "Calculating topological package order"
pkgs=$(Rscript -e 'cat(crandeps::cran_topo_sort())')
numpkgs=$(echo "$pkgs" | wc -w)

echo "Listing packages already built"
repourl=$(Rscript -e 'cat(paste0("file://", normalizePath("'$repodir'")))')
ready=$(Rscript -e 'd <- "'$repourl'"; cat(rownames(available.packages(contriburl = d)))')
numready=$(echo "$ready" | wc -w)
tobuild=$(($numpkgs - $numready))

echo $numpkgs packages, $numready done, building $tobuild

echo > build.log

x=1
for pkg in $pkgs; do
    echo -n "[$x/$tobuild] $pkg $(date)"
    if echo "$ready" | grep -q '\b'$pkg'\b'; then
	echo " already built"
    else
	echo -n " building ... "
	if ./make-binary-package.sh "$newimage" "$pkg" "$repodir" 2>&1 >>build.log; then
	    echo -n "updating repo ... "
	    Rscript -e 'tools::write_PACKAGES("'$repodir'")'
	    echo "DONE"
	else
	    echo "FAILED"
	fi
    fi

    x=$(($x + 1))
done
