FROM docker:stable-dind

RUN apk --no-cache add bash

COPY docker.sh /usr/local/bin/

ENTRYPOINT ["docker.sh"]
