# Inspired by https://github.com/testcontainers/dind-drone-plugin/blob/master/Dockerfile
FROM docker:20.10-dind

ARG DOCKER_COMPOSE_VERSION=2.5.0
ARG COMPOSE_SWITCH_VERSION=1.0.4

# Install everything we need including for cdcs
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    git

# Install docker compose v2 and compose switch
# https://docs.docker.com/compose/cli-command/
RUN DOCKER_PLUGINS=$HOME/.docker/cli-plugins \
    && mkdir -p ${DOCKER_PLUGINS} \
    && curl -SL https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64 -o ${DOCKER_PLUGINS}/docker-compose \
    && chmod +x ${DOCKER_PLUGINS}/docker-compose \
    && curl -fL https://github.com/docker/compose-switch/releases/download/v${COMPOSE_SWITCH_VERSION}/docker-compose-linux-amd64 -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose

COPY bin/ /halfpipe/bin/

ENV PATH="/halfpipe/bin:${PATH}"

ENTRYPOINT ["/halfpipe/bin/docker.sh"]
