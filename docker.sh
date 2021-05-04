#!/usr/bin/env bash

readonly cache_mount="/mnt/halfpipe-cache"
readonly cache_host="${HALFPIPE_CACHE_HOST:-cache.halfpipe.io}"
readonly cache_share="${HALFPIPE_CACHE_SHARE:-/cache}"
readonly cache_team="${HALFPIPE_CACHE_TEAM:-common}"
readonly cache_dir="${HALFPIPE_CACHE_DIR:-/var/halfpipe/shared-cache}"

function unmountNFS {
  echo 'unmounting cache'
  umount ${cache_mount}
}

function cleanup {
  echo
  echo "======="
  echo "cleaning up"
  stop_docker
  unmountNFS
  exit "$1"
}

trap 'cleanup $?' EXIT



source /docker-lib.sh
start_docker

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
