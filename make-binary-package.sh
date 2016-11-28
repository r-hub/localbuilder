#! /bin/bash

usage() {
    echo "Usage: $0 <image> <package>"
}

image=$1
package=$2

if [[ -z "$image" || -z "$package" ]]; then usage; exit 1; fi

dir=$(pwd)
echo "Starting container"
cont=$(docker run -d -t -v "${dir}/build-in-docker.sh":/build-in-docker.sh \
	      ${image} bash /build-in-docker.sh ${package})

docker attach $cont || true

## Get exit status
status=$(docker inspect $cont | grep ExitCode | cut -d: -f2 | \
		sed 's/[^0-9]//g')

if [[ "$status" == 0 ]]; then
    echo "Copy binary package from container"
    docker cp "${cont}:output_file" .
    output=$(cat output_file)
    docker cp "${cont}:${output}" .
    exit 0
else
    echo "Build failed, no binary package was produced"
    exit 1
fi
