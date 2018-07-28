#!/usr/bin/env bash
source /docker-lib.sh
start_docker

cache="$(echo $PWD | cut -d/ -f1-4)/docker-images"

if [ -d "${cache}" ]; then
  for image in ${cache}/*/ ; do
    docker load -i "${image}image"
    docker tag \
      "$(cat "${image}image-id")" \
      "$(cat "${image}repository"):$(cat "${image}tag")"
  done
fi

exec bash -ec "$@"
