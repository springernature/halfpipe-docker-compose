team: engineering-enablement
pipeline: halfpipe-docker-compose
slack_channel: "#ee-re"

tasks:
- type: docker-push
  image: eu.gcr.io/halfpipe-io/halfpipe-docker-compose
