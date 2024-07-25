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

sanitize_cgroups() {
  local cgroup="/sys/fs/cgroup"

  mkdir -p "${cgroup}"
  if ! mountpoint -q "${cgroup}"; then
    if ! mount -t tmpfs -o uid=0,gid=0,mode=0755 cgroup "${cgroup}"; then
      echo >&2 "Could not make a tmpfs mount. Did you use --privileged?"
      exit 1
    fi
  fi
  mount -o remount,rw "${cgroup}"

  # Skip AppArmor
  # See: https://github.com/moby/moby/commit/de191e86321f7d3136ff42ff75826b8107399497
  export container=docker

  # Mount /sys/kernel/security
  if [[ -d /sys/kernel/security ]] && ! mountpoint -q /sys/kernel/security; then
    if ! mount -t securityfs none /sys/kernel/security; then
      echo >&2 "Could not mount /sys/kernel/security."
      echo >&2 "AppArmor detection and --privileged mode might break."
    fi
  fi

  sed -e 1d /proc/cgroups | while read sys hierarchy num enabled; do
    if [[ "${enabled}" != "1" ]]; then
      # subsystem disabled; skip
      continue
    fi

    grouping="$(cat /proc/self/cgroup | cut -d: -f2 | grep "\\<${sys}\\>")"
    if [[ -z "${grouping}" ]]; then
      # subsystem not mounted anywhere; mount it on its own
      grouping="${sys}"
    fi

    mountpoint="${cgroup}/${grouping}"

    mkdir -p "${mountpoint}"

    # clear out existing mount to make sure new one is read-write
    if mountpoint -q "${mountpoint}"; then
      umount "${mountpoint}"
    fi

    mount -n -t cgroup -o "${grouping}" cgroup "${mountpoint}"

    if [[ "${grouping}" != "${sys}" ]]; then
      if [[ -L "${cgroup}/${sys}" ]]; then
        rm "${cgroup}/${sys}"
      fi

      ln -s "${mountpoint}" "${cgroup}/${sys}"
    fi
  done

  # Initialize systemd cgroup if host isn't using systemd.
  # Workaround for https://github.com/docker/for-linux/issues/219
  if ! [[ -d /sys/fs/cgroup/systemd ]]; then
    mkdir "${cgroup}/systemd"
    mount -t cgroup -o none,name=systemd cgroup "${cgroup}/systemd"
  fi
}

start_dockerd() {

  # check for /proc/sys being mounted readonly, as systemd does
  if grep '/proc/sys\s\+\w\+\s\+ro,' /proc/mounts >/dev/null; then
    mount -o remount,rw /proc/sys
  fi

  echo "Starting docker daemon..."

  dockerd \
    --data-root /scratch/docker \
    -s ${PLUGIN_STORAGE_DRIVER:-overlay2} \
    --log-level error \
    --tls=false \
    -H tcp://0.0.0.0:2375 \
    --registry-mirror=https://eu-mirror.gcr.io \
    -H unix:///var/run/docker.sock &>/scratch/dockerd.log &

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

sanitize_cgroups
start_dockerd
run_hook_scripts post-start

echo "Running Task..."
bash -c "$@"
