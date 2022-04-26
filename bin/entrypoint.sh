#!/bin/bash

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

  /usr/local/bin/dockerd-entrypoint.sh dockerd \
    --data-root /scratch/docker \
    -s ${PLUGIN_STORAGE_DRIVER:-overlay2} \
    --log-level error \
    -H tcp://0.0.0.0:2375 \
    -H unix:///var/run/docker.sock &

  for i in $(seq 1 30); do
    docker ps &> /dev/null && break || true
    sleep 1
  done

  docker ps &> /dev/null || exit 1
  echo "docker daemon is running."
  docker --version
  docker-compose --version

  # Determine IP address at which dockerd and spawned containers can be reached
  DOCKER_IP=$(ip route | awk '/docker0/ { print $7 }')
  export DIND_HOST="tcp://${DOCKER_IP}:2375"
  echo ""
  echo "Docker daemon will be available in the build container at:"
  echo "  /var/run/docker.sock"
  echo "  tcp://${DOCKER_IP}:2375 (no TLS)"

  echo "Available images before build:"
  docker image ls 2>&1 | sed 's/^/   /g'
}

stop_docker() {
  echo "Stopping docker daemon..."
  if ! [ -s /var/run/docker.pid ]; then
    return 0
  fi

  local pid=$(cat /var/run/docker.pid)
  ps -p $pid &> /dev/null
  if [ $? -eq 0 ]; then
    kill -TERM $pid
  fi
  sleep 5
  ps -p $pid &> /dev/null
  if [ $? -eq 0 ]; then
    echo "dockerd did not cleanly shut down, gonna kill -9 it"
    kill -9 $pid
  fi
}


cleanup() {
  echo
  echo "cleaning up..."
  stop_docker
  run_hook_scripts cleanup
  exit "$1"
}

#############################################

export PATH="$PATH:/halfpipe/bin"
export TINI_SUBREAPER=1

echo "Halfpipe docker-in-docker https://ee.public.springernature.app/rel-eng/"
echo

trap 'cleanup $?' EXIT

start_dockerd
run_hook_scripts post-start

echo "Running Task..."
bash -c "$@"
