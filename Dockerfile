# Inspired by https://github.com/meAmidos/dcind and https://github.com/mumoshu/dcind
FROM debian:buster-slim

ENV DOCKER_VERSION="20.10.6"
ENV DOCKER_COMPOSE_VERSION="1.29.1"

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
    && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN curl https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz | tar zx && \
    mv /docker/* /bin/ && \
    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /bin/docker-compose && \
    chmod +x /bin/docker*


# Include useful functions to start/stop docker daemon in garden-runc containers in Concourse CI.
# Example: source /docker-lib.sh && start_docker
COPY docker-lib.sh /docker-lib.sh
COPY docker.sh /usr/local/bin/


#RUN docker.sh adoptopenjdk/openjdk15

ENTRYPOINT ["/usr/bin/dumb-init", "--", "docker.sh"]
