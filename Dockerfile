# inspired by https://github.com/testcontainers/dind-drone-plugin/blob/master/Dockerfile
FROM docker:20.10-dind

ARG DOCKER_COMPOSE_VERSION=2.2.3

# Install everything we need including for cdcs
RUN apk add --no-cache \
  bash \
  curl \
  jq \
  git

RUN DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker} && mkdir -p $DOCKER_CONFIG/cli-plugins && \
     curl -SL https://github.com/docker/compose/releases/download/v$DOCKER_COMPOSE_VERSION/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose \
    && chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose && docker compose version


RUN  curl -fL https://github.com/docker/compose-switch/releases/download/v1.0.4/docker-compose-linux-amd64 -o /usr/local/bin/docker-compose \
     &&  chmod +x /usr/local/bin/docker-compose


# RUN apt-get update && apt-get install -y \
#     curl \
#     dumb-init \
#     git \
#     iproute2 \
#     iptables \
#     jq \
#     libdevmapper-dev \
#     nfs-common \
#     openssh-server \
#     pigz \
#     python-pip \
#     python-backports.ssl-match-hostname && \
#     apt-get autoremove -y && apt-get clean

COPY bin/ /halfpipe/bin/

ENTRYPOINT ["/halfpipe/bin/entrypoint.sh"]
