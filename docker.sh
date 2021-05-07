#!/usr/bin/env bash

readonly cache_mount="/mnt/halfpipe-cache"
readonly cache_host="${HALFPIPE_CACHE_HOST:-cache.halfpipe.io}"
readonly cache_share="${HALFPIPE_CACHE_SHARE:-/cache}"
readonly cache_team="${HALFPIPE_CACHE_TEAM:-common}"
readonly cache_dir="${HALFPIPE_CACHE_DIR:-/var/halfpipe/shared-cache}"

export HALFPIPE_DOCKER_DATA_ROOT="${HALFPIPE_DOCKER_DATA_ROOT:-/scratch/docker}"
export HALFPIPE_DOCKER_CACHE_ENABLED="${HALFPIPE_DOCKER_CACHE_ENABLED:-false}"
export HALFPIPE_DOCKER_CACHE_TAR="${HALFPIPE_DOCKER_CACHE_TAR:-/var/halfpipe/cache/docker.tar}"
export DOCKER_TMPDIR="${DOCKER_TMPDIR:-/scratch/docker-tmp}"

function mount_nfs {
  (
  set -e
  mkdir -p ${cache_mount}
  mount -t nfs -o nolock,retry=0,soft ${cache_host}:${cache_share} ${cache_mount}
  )

  if [[ 0 -eq $? ]]; then
      echo "team cache available: ${cache_dir}"
  else
      echo "team cache unavailable"
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
}

function unmount_nfs {
  echo "unmounting team cache"
  umount ${cache_mount}
}

function save_cache {
  if [[ "${HALFPIPE_DOCKER_CACHE_ENABLED}" == "true" ]]; then
    # find cache modified less than 1 day ago (1440 mins)
    if [[ "$(find ${HALFPIPE_DOCKER_CACHE_TAR} -mmin -10 -printf "found" 2>/dev/null)" == "found" ]]; then
      echo "recent docker cache exists"
    else
      echo "caching docker state"
      (cd ${HALFPIPE_DOCKER_DATA_ROOT}; tar -cf ${HALFPIPE_DOCKER_CACHE_TAR} .)
    fi
    ls -lh ${HALFPIPE_DOCKER_CACHE_TAR}
  fi
}

function restore_cache {
  if [[ "${HALFPIPE_DOCKER_CACHE_ENABLED}" == "true" ]]; then
    if [[ -f ${HALFPIPE_DOCKER_CACHE_TAR} ]]; then
      echo "restoring docker cache"
      ls -lh ${HALFPIPE_DOCKER_CACHE_TAR}
      mkdir -p ${HALFPIPE_DOCKER_DATA_ROOT}
      (cd ${HALFPIPE_DOCKER_DATA_ROOT}; tar -xf ${HALFPIPE_DOCKER_CACHE_TAR})
    else
      echo "no docker cache found"
    fi
  else
    echo "docker cache disabled. To enable, set HALFPIPE_DOCKER_CACHE_ENABLED=true"
  fi
}


function cleanup {
  echo
  echo "============================"
  echo "task finished (exit code: $1)"
  echo "============================"
  cleanup_docker
  stop_docker
  unmount_nfs
  save_cache
  echo "cleanup finished"
  exit "$1"
}


trap 'cleanup $?' EXIT
source /docker-lib.sh

restore_cache
mount_nfs
start_docker
cleanup_docker
docker images

echo "============="
echo "starting task"
echo "============="
bash -c "$@"
