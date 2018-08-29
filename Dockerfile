# Inspired by https://github.com/meAmidos/dcind and https://github.com/mumoshu/dcind
FROM alpine:3.7

ENV DOCKER_VERSION="18.03.1-ce" \
    DOCKER_COMPOSE_VERSION="1.22.0"

# Install everything
RUN apk --update --no-cache add curl device-mapper py-pip iptables bash git jq openssh && \
    rm -rf /var/cache/apk/* && \
    curl https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz | tar zx && \
    mv /docker/* /bin/ && chmod +x /bin/docker* && \
    pip install docker-compose==${DOCKER_COMPOSE_VERSION}

# Include useful functions to start/stop docker daemon in garden-runc containers in Concourse CI.
# Example: source /docker-lib.sh && start_docker
COPY docker-lib.sh /docker-lib.sh
COPY docker.sh /usr/local/bin/

ENTRYPOINT ["docker.sh"]
