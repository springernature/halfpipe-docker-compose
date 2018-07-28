#!/usr/bin/env bash
set -e

source /docker-lib.sh
start_docker

cache="$(echo $PWD | cut -d/ -f1-4)/docker-images"

if [ -d "${cache}s" ]; then
  for image in ${cache}/*/ ; do
    echo docker load -i "${image}image"
    echo docker tag \
      "$(cat "${image}image-id")" \
      "$(cat "${image}repository"):$(cat "${image}tag")"
  done
fi

exec bash -ec "$@"
