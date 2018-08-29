team: engineering-enablement
pipeline: halfpipe-docker-compose
slack_channel: "#ee-re"

repo:
  branch: docker18

tasks:
- type: docker-push
  image: eu.gcr.io/halfpipe-io/halfpipe-docker-compose-docker18
