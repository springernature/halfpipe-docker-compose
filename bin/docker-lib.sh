# Ref: https://github.com/concourse/docker-image-resource/blob/master/assets/common.sh

sanitize_cgroups() {
  mkdir -p /sys/fs/cgroup
  mountpoint -q /sys/fs/cgroup || \
    mount -t tmpfs -o uid=0,gid=0,mode=0755 cgroup /sys/fs/cgroup

  mount -o remount,rw /sys/fs/cgroup

  sed -e 1d /proc/cgroups | while read sys hierarchy num enabled; do
    if [ "$enabled" != "1" ]; then
      # subsystem disabled; skip
      continue
    fi

    grouping="$(cat /proc/self/cgroup | cut -d: -f2 | grep "\\<$sys\\>")"
    if [ -z "$grouping" ]; then
      # subsystem not mounted anywhere; mount it on its own
      grouping="$sys"
    fi

    mountpoint="/sys/fs/cgroup/$grouping"

    mkdir -p "$mountpoint"

    # clear out existing mount to make sure new one is read-write
    if mountpoint -q "$mountpoint"; then
      umount "$mountpoint"
    fi

    mount -n -t cgroup -o "$grouping" cgroup "$mountpoint"

    if [ "$grouping" != "$sys" ]; then
      if [ -L "/sys/fs/cgroup/$sys" ]; then
        rm "/sys/fs/cgroup/$sys"
      fi

      ln -s "$mountpoint" "/sys/fs/cgroup/$sys"
    fi
  done

  mkdir -p /sys/fs/cgroup/systemd
  mountpoint -q /sys/fs/cgroup/systemd || \
    mount -t cgroup -o none,name=systemd cgroup /sys/fs/cgroup/systemd
}

start_docker() {
  mkdir -p /var/log
  mkdir -p /var/run

  sanitize_cgroups

  # check for /proc/sys being mounted readonly, as systemd does
  if grep '/proc/sys\s\+\w\+\s\+ro,' /proc/mounts >/dev/null; then
    mount -o remount,rw /proc/sys
  fi

  local server_args="--data-root /scratch/docker -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock --mtu 1460"

  echo "starting dockerd with args: [ ${server_args} ]"
  dockerd ${server_args} >/tmp/docker.log 2>&1 &
  echo $! > /tmp/docker.pid

  sleep 1

  until docker info >/dev/null 2>&1; do
    echo 'waiting for docker to come up...'
    sleep 1
  done

  docker --version
  docker-compose --version

  # see https://github.com/testcontainers/dind-drone-plugin
  # Determine IP address at which dockerd and spawned containers can be reached
  DOCKER_IP=$(ip route | awk '/docker0/ { print $9 }')
  export DIND_HOST="tcp://${DOCKER_IP}:2375"
  echo "  Docker daemon will be available in the build container:"
  echo "    at /var/run/docker.sock"
  echo "    at tcp://${DOCKER_IP}:2375 (no TLS)"
  echo "  Containers spawned by the build container will be accessible at ${DOCKER_IP} (do not hardcode this value)"
  echo "    set DOCKER_HOST in your container to the value of $DIND_HOST. e.g. in docker-compose.yml:"
  echo "      environment:"
  echo '        DOCKER_HOST: $DIND_HOST'
}

stop_docker() {
  echo 'stopping docker'
  local pid=$(cat /tmp/docker.pid)
  if [ -z "$pid" ]; then
    return 0
  fi

  ps -p $pid &> /dev/null
  if [ $? -eq 0 ]; then
    kill -TERM $pid
  fi
  sleep 5
  ps -p $pid &> /dev/null
  if [ $? -eq 0 ]; then
    echo docker did not cleanly shut down, gonna kill -9 it
    kill -9 $pid
  fi
}
