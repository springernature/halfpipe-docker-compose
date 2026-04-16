# Inspired by https://github.com/testcontainers/dind-drone-plugin/blob/master/Dockerfile
FROM tonistiigi/binfmt@sha256:d3b963f787999e6c0219a48dba02978769286ff61a5f4d26245cb6a6e5567ea3 AS binfmt

FROM docker:dind@sha256:a6dd5322747a95cd8e3207bd8d415a8fd20ec34e9c00f06dc019cbd912013489

ARG DOCKER_COMPOSE_VERSION=5.1.3
ARG COMPOSE_SWITCH_VERSION=1.0.5
ARG PACK_VERSION=0.40.2

# Install everything we need including for cdcs
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    git \
    qemu-aarch64

# Copy binfmt binary for registering QEMU interpreters
COPY --from=binfmt /usr/bin/binfmt /usr/bin/binfmt

# Install docker compose v2 and compose switch
# https://docs.docker.com/compose/cli-command/
RUN DOCKER_PLUGINS=$HOME/.docker/cli-plugins \
    && mkdir -p ${DOCKER_PLUGINS} \
    && curl -SL https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64 -o ${DOCKER_PLUGINS}/docker-compose \
    && chmod +x ${DOCKER_PLUGINS}/docker-compose \
    && curl -fL https://github.com/docker/compose-switch/releases/download/v${COMPOSE_SWITCH_VERSION}/docker-compose-linux-amd64 -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose

# Install pack
ADD https://github.com/buildpacks/pack/releases/download/v${PACK_VERSION}/pack-v${PACK_VERSION}-linux.tgz /tmp/pack.tgz
RUN tar -xzf /tmp/pack.tgz -C /usr/local/bin && rm /tmp/pack.tgz

COPY bin/ /halfpipe/bin/

ENV PATH="/halfpipe/bin:${PATH}"

ENTRYPOINT ["/halfpipe/bin/docker.sh"]
