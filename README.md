# Halfpipe docker-compose

A docker-in-docker image for running tasks in Concourse. Used by Halfpipe for `docker-compose`, `docker-push`, `consumer-integration-test` and `buildpack` tasks.

Published to `eu.gcr.io/halfpipe-io/halfpipe-docker-compose`.

## What's included

Based on `docker:dind` (Alpine), the image ships with:

- **Docker Compose v2** (as a CLI plugin) with Compose Switch for `docker-compose` v1 backward compatibility
- **pack** (Cloud Native Buildpacks CLI)
- **QEMU + buildx** for multi-architecture builds (amd64 + arm64)
- bash, curl, jq, git

## How it works

The entrypoint (`bin/docker.sh`) handles the full lifecycle:

1. **Starts `dockerd`** on both a Unix socket and `tcp://0.0.0.0:2375`, using `eu-mirror.gcr.io` as a registry mirror
2. **Runs post-start hooks:**
   - Mounts a shared NFS cache (`cache.halfpipe.io:/cache`) at `/var/halfpipe/shared-cache`, scoped to your team. Gracefully continues if the NFS host is unreachable.
   - Registers QEMU binfmt for arm64 and creates a `multiarch` buildx builder
3. **Executes your command** via `bash -c`
4. **Cleans up** on exit (stops dockerd, unmounts cache)

## Shared cache

An NFS-backed shared cache is mounted automatically at:

```
/var/halfpipe/shared-cache
```

The deprecated path `/halfpipe-shared-cache` is symlinked for backward compatibility.

The cache directory is scoped per team based on the `HALFPIPE_TEAM` environment variable.

## Multi-arch builds

The image comes pre-configured with a `multiarch` buildx builder supporting `linux/amd64` and `linux/arm64`. Use it in your tasks:

```bash
docker buildx build --builder multiarch --platform linux/amd64,linux/arm64 -t myimage .
```

## Halfpipe CDC testing

The image includes scripts for running Consumer-Driven Contract tests:

- `run-cdc.sh` -- Fetches the consumer's deployed version, clones the consumer repo at that revision, and runs the CDC test suite via `docker-compose run`. Results are recorded in the Covenant service.
- `covenant.sh` -- HTTP client for the [Covenant](https://covenant.springernature.app) CDC result tracking service.

## Pipeline

The Concourse pipeline (`.pipeline.yml`) has three stages:

1. **build** -- Triggered on push to `main`. Builds and pushes the image tagged with the version number and `dev`.
2. **test** -- Runs integration tests covering docker-compose functionality, NFS cache availability/unavailability, backward compatibility, and multi-arch emulation.
3. **deploy** -- Manual trigger. Promotes the image to `stable`.
