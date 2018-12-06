# Inspired by https://github.com/meAmidos/dcind and https://github.com/mumoshu/dcind
FROM debian:stretch-slim

ENV DOCKER_VERSION="18.03.1-ce"
ENV DOCKER_COMPOSE_VERSION="1.23.1"

# Install everything
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    dumb-init
    git \
    iptables \
    jq \
    libdevmapper-dev \
    nfs-common \
    openssh-server \
    python-pip

RUN curl https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz | tar zx && \
    mv /docker/* /bin/ && chmod +x /bin/docker*

RUN pip install docker-compose==${DOCKER_COMPOSE_VERSION}

RUN apt-get autoremove -y && apt-get clean

# Include useful functions to start/stop docker daemon in garden-runc containers in Concourse CI.
# Example: source /docker-lib.sh && start_docker
COPY docker-lib.sh /docker-lib.sh
COPY docker.sh /usr/local/bin/

ENTRYPOINT ["/usr/bin/dumb-init", "--", "docker.sh"]
