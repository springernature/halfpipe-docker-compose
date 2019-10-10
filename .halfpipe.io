team: engineering-enablemennt
pipeline: halfpipe-docker-compose-oscar

triggers:
- type: git
  branch: oscar

tasks:
- type: docker-push
  image: eu.gcr.io/halfpipe-io/simon-test
