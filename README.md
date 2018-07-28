# Halfpipe docker-compose

A docker image for running docker-compose tasks

Loads saved image resources from `/tmp/build/xxxxx/docker-images`.

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


