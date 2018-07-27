#!/usr/bin/env bash
set -e

source /docker-lib.sh
start_docker

while read -r image; do
  # Load image
  docker load -i "${image}/image"
  # Tag image
  docker tag \
    "$(cat "${image}/image-id")" \
    "$(cat "${image}/repository"):$(cat "${image}/tag")"
done < <(find /images/* -type d)

exec bash -ec "$@"
