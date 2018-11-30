team: engineering-enablement
pipeline: halfpipe-docker-compose
slack_channel: "#halfpipe-team"

feature_toggles:
  - versioned

tasks:
- type: docker-push
  image: eu.gcr.io/halfpipe-io/halfpipe-docker-compose
