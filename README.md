# Halfpipe docker-compose

A container running the docker daemon for times when docker-in-docker ("dind") is needed. Used by the halfpipe `docker-compose` and `consumer-integration-test` tasks.


It sets the environment variable `DIND_HOST` which can be passed into containers which need access to the docker daemon.

example `docker-compose.yml`:
```
version: '3'
services:
  app:
    image: ubuntu
    command: ./build
    working_dir: /work
    volumes:
      - .:/work
    environment:
      DOCKER_HOST: $DIND_HOST
```

### Docker Image Cache

> This feature is not used by halfpipe since it turns out that loading an image from cache is no faster than downloading it :(

The startup script supports loading saved docker image tar files. They can be passed into the task as inputs in a subdirectory under `./docker-images` - i.e. `/tmp/build/xxxxx/docker-images`.

On startup the task loops through these directories and `docker load`s them.


#### example
```yaml
resources:
- name: git
  type: git
  source:
    paths:
    - docker-compose
    private_key: ((github.private_key))
    uri: git@github.com:springernature/halfpipe-examples
- name: appropriate_curl
  type: docker-image
  source:
    repository: appropriate/curl
- name: nginx
  type: docker-image
  source:
    repository: nginx
jobs:
- name: test in docker-compose
  serial: true
  plan:
  - aggregate:
    - get: git
      trigger: true
    - get: appropriate_curl
      params:
        save: true
    - get: nginx
      params:
        save: true
  - task: test in docker-compose
    privileged: true
    config:
      platform: linux
      image_resource:
        type: docker-image
        source:
          password: ((gcr.private_key))
          repository: eu.gcr.io/halfpipe-io/halfpipe-docker-compose
          tag: latest
          username: _json_key
      params:
        GCR_PRIVATE_KEY: ((gcr.private_key))
      run:
        path: docker.sh
        args:
        - |
          export GIT_REVISION=`cat ../.git/ref`
          docker login -u _json_key -p "$GCR_PRIVATE_KEY" https://eu.gcr.io
          docker-compose run -e GIT_REVISION app
        dir: git/docker-compose
      inputs:
      - name: git
      - name: appropriate_curl
        path: docker-images/appropriate_curl
      - name: nginx
        path: docker-images/nginx
```
