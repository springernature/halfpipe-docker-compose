#!/usr/bin/env bash

readonly cache_mount="/mnt/halfpipe-cache"
readonly cache_host="${HALFPIPE_CACHE_HOST:-cache.halfpipe.io}"
readonly cache_share="${HALFPIPE_CACHE_SHARE:-/cache}"
readonly cache_team="${HALFPIPE_CACHE_TEAM:-common}"
readonly cache_dir="${HALFPIPE_CACHE_DIR:-/var/halfpipe/shared-cache}"

source /docker-lib.sh
start_docker

# load any saved images added by resources
cache="$(echo $PWD | cut -d/ -f1-4)/docker-images"

if [ -d "${cache}" ]; then
  for image in ${cache}/*/ ; do
    if [ -f "${image}image.tar" ]; then
      echo "Loading ${image} .."
      docker load -i "${image}image.tar"
    else
      echo "Loading $(cat "${image}repository"):$(cat "${image}tag") .."
      docker load -i "${image}image"
      docker tag \
        "$(cat "${image}image-id")" \
        "$(cat "${image}+"):$(cat "${image}tag")"
    fi
  done
fi

function cleanup {
  echo 'cleanup: unmounting cache'
  umount ${cache_mount}
}

trap cleanup EXIT
trap stop_docker EXIT

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
mkdir -p $(dirname ${cache_dir})

if [ ! -L ${cache_dir}/${cache_team} ]; then
  ln -s ${cache_mount}/${cache_team} ${cache_dir}
fi

# deprecated old cache dir location
if [ ! -L /halfpipe-shared-cache ]; then
  ln -s ${cache_mount}/${cache_team} /halfpipe-shared-cache
fi

bash -c "$@"
EXIT_STATUS=$?
exit $EXIT_STATUS
