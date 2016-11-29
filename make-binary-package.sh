#! /bin/bash

usage() {
    echo "Usage: $0 <image> <package> <repo-url>"
}

set -e

image=$1
package=$2
repo=$3

if [[ -z "$image" || -z "$package" ]]; then usage; exit 1; fi

contid=$(cat /dev/urandom | LC_CTYPE=C  tr -dc 'a-zA-Z0-9' |
		fold -w 32 | head -n 1)

dir=$(pwd)
echo "Starting container"
docker run -t -v "${dir}/build-in-docker.sh":/build-in-docker.sh \
       -v "${dir}/urls.sh":/urls.sh \
       -v "${dir}/$repo":/cran --name $contid ${image} \
       bash /build-in-docker.sh ${package}

## Get exit status
status=$(docker inspect $contid | grep ExitCode | cut -d: -f2 | \
		sed 's/[^0-9]//g')

if [[ "$status" == 0 ]]; then
    echo "Copy binary package from container"
    docker cp "${contid}:output_file" .
    output=$(cat output_file)
    docker cp "${contid}:${output}" $repo/
    exit 0
else
    echo "Build failed, no binary package was produced"
    exit 1
fi
