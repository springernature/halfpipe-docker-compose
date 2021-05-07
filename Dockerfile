# Inspired by https://github.com/meAmidos/dcind
FROM debian:buster-slim

ENV DOCKER_VERSION="19.03.0"
ENV DOCKER_COMPOSE_VERSION="1.24.1"

# Install everything
RUN apt-get update \
    && apt-get install -y \
        curl \
        dumb-init \
        git \
        iptables \
        jq \
        libdevmapper-dev \
        nfs-common \
        openssh-server \
        pigz \
    && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN curl https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz | tar zx && \
    mv /docker/* /bin/ && \
    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-Linux-x86_64" -o /bin/docker-compose && \
    chmod +x /bin/docker*

COPY docker-lib.sh /docker-lib.sh
COPY docker.sh /usr/local/bin/

ENTRYPOINT ["/usr/bin/dumb-init", "--", "docker.sh"]
