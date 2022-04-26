#!/usr/bin/env bash
set -u

run_hook_scripts() {
  for HOOK_SCRIPT in /halfpipe/bin/hooks/$1/*; do
    if [[ -x $HOOK_SCRIPT ]]; then
      echo "Running $1 script ${HOOK_SCRIPT}..."
      $HOOK_SCRIPT
    fi
  done
}

start_dockerd() {
  echo "Starting docker daemon..."

  export TINI_SUBREAPER=1
  /usr/local/bin/dockerd-entrypoint.sh dockerd \
    --data-root /scratch/docker \
    -s ${PLUGIN_STORAGE_DRIVER:-overlay2} \
    --log-level error \
    --tls=false \
    -H tcp://0.0.0.0:2375 \
    -H unix:///var/run/docker.sock &

  # wait for it
  for i in $(seq 1 30); do
    docker ps &>/dev/null && break || true
    if [[ $i -eq 30 ]]; then
      echo "Failed to start"
      exit 1
    fi
    sleep 1
  done

  docker --version
  docker-compose --version

  # Determine IP address at which dockerd and spawned containers can be reached
  DOCKER_IP=$(ip route | awk '/docker0/ { print $7 }')
  export DIND_HOST="tcp://${DOCKER_IP}:2375"
  echo
  echo "Docker daemon available at:"
  echo "  /var/run/docker.sock"
  echo "  tcp://${DOCKER_IP}:2375 (exported as environment variable DIND_HOST)"
  echo
}

stop_docker() {
  echo "Stopping docker daemon..."
  pkill -TERM dockerd

  for s in `seq 1 30`; do
    sleep 1
    pgrep dockerd > /dev/null || break
    if [ $s -eq 30 ]; then
      echo "Failed to stop nicely, trying to kill..."
      pkill -KILL dockerd
      sleep 5
    fi
  done
  echo "Stopped"
}

cleanup() {
  echo
  echo "Cleaning up..."
  stop_docker
  run_hook_scripts cleanup
  exit "$1"
}

#############################################

echo "Halfpipe docker-in-docker https://ee.public.springernature.app/rel-eng/"
echo

trap 'cleanup $?' EXIT

start_dockerd
run_hook_scripts post-start

echo "Running Task..."
bash -c "$@"
