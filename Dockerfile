# Inspired by https://github.com/meAmidos/dcind and https://github.com/mumoshu/dcind
FROM debian:buster-slim

ENV DOCKER_VERSION="19.03.0"
ENV DOCKER_COMPOSE_VERSION="1.24.1"

# Install everything
RUN apt-get update && apt-get install -y \
    curl \
    dumb-init \
    git \
    iproute2 \
    iptables \
    jq \
    libdevmapper-dev \
    nfs-common \
    openssh-server \
    pigz \
    python-pip \
    python-backports.ssl-match-hostname && \
    apt-get autoremove -y && apt-get clean

RUN curl https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz | tar zx && \
    mv /docker/* /bin/ && \
    chmod +x /bin/docker* && \
    pip install docker-compose==${DOCKER_COMPOSE_VERSION} && \
    sed -i "s/Network(client, name, 'default')/Network(client, name, 'default', driver_opts={'com.docker.network.driver.mtu': '1460'})/" /usr/local/lib/python2.7/dist-packages/compose/network.py

# Include useful functions to start/stop docker daemon in garden-runc containers in Concourse CI.
# Example: source docker-lib.sh && start_docker
COPY bin/ /usr/local/bin/

ENTRYPOINT ["/usr/bin/dumb-init", "--", "docker.sh"]
