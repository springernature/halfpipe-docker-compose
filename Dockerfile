# inspired by https://github.com/testcontainers/dind-drone-plugin/blob/master/Dockerfile
FROM docker:20.10-dind

# Install everything we need including for cdcs
RUN apk add --no-cache \
  bash \
  curl \
  jq \
  git

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
