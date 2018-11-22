#!/usr/bin/env bash
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

exec bash -c "$@"
