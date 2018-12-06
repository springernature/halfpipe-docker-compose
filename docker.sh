#!/usr/bin/env bash

readonly cache_mount="/opt/halfpipe-nfs"
readonly cache_host="${HALFPIPE_CACHE_HOST:-cache.halfpipe.io}"
readonly cache_share="${HALFPIPE_CACHE_SHARE:-/cache}"
readonly cache_team="${HALFPIPE_CACHE_TEAM:-common}"
readonly cache_dir="${HALFPIPE_CACHE_DIR:-/halfpipe-shared-cache}"

source /docker-lib.sh
start_docker

# load any saved images added by resources
cache="$(echo $PWD | cut -d/ -f1-4)/docker-images"

if [ -d "${cache}" ]; then
  for image in ${cache}/*/ ; do
    echo "Loading $(cat "${image}repository"):$(cat "${image}tag") .."
    docker load -i "${image}image"
    docker tag \
      "$(cat "${image}image-id")" \
      "$(cat "${image}repository"):$(cat "${image}tag")"
  done
fi

function cleanup {
  umount ${cache_mount}
}

trap cleanup EXIT
(
set -e
mkdir -p ${cache_mount}
mount -t nfs -o nolock,retry=0,soft ${cache_host}:${cache_share} ${cache_mount}
)

if [[ 0 -eq $? ]]; then
    echo "Cache dir available: ${cache_dir}"
else
    echo "Cache dir unavailable"
fi

mkdir -p ${cache_mount}/${cache_team}
ln -s ${cache_mount}/${cache_team} ${cache_dir}

exec bash -c "$@"
