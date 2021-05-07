# Ref: https://github.com/concourse/docker-image-resource/blob/master/assets/common.sh

sanitize_cgroups() {
  mkdir -p /sys/fs/cgroup
  mountpoint -q /sys/fs/cgroup || \
    mount -t tmpfs -o uid=0,gid=0,mode=0755 cgroup /sys/fs/cgroup

  mount -o remount,rw /sys/fs/cgroup

  # Skip AppArmor
  # See: https://github.com/moby/moby/commit/de191e86321f7d3136ff42ff75826b8107399497
  export container=docker

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


  local docker_opts="--data-root ${HALFPIPE_DOCKER_DATA_ROOT} --registry-mirror https://eu-mirror.gcr.io --max-concurrent-downloads 6 --pidfile /scratch/docker.pid"
  echo "starting docker with opts ${docker_opts}"
  dockerd ${docker_opts}  >/scratch/docker.log 2>&1 &

  sleep 1

  until docker info >/dev/null 2>&1; do
    echo 'waiting for docker to come up...'
    sleep 1
  done

  docker --version
  docker-compose --version
}

stop_docker() {
  echo 'stopping docker'
  local pid=$(cat /scratch/docker.pid)
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
    echo 'docker did not cleanly shut down, gonna kill -9 it'
    kill -9 $pid
  fi
}

cleanup_docker() {
  [[ -n "$(docker container ls -aq)" ]] && docker container rm --force --volumes $(docker container ls -aq)
  docker system prune --volumes --force
}
