#!/usr/bin/env bash

# THIS IS A COPY OF SPRINGERNATURE/HALFPIPE-INFRA/ACTIONS/GHA-RUNNER-IMAGE/BIN
# When editing, dont forget to change that file as well!
set -euo pipefail

source covenant.sh

use_covenant() {
  [[ "${USE_COVENANT:-}" == "true" ]] && return 0 || return 1
}

echo "Running CDC. Docs: <https://ee.public.springernature.app/rel-eng/halfpipe/legacy-cdcs/>"

# get current revision of consumer, revert to HEAD if not found
REVISION=$(curl -m5 -fsSL "${CONSUMER_HOST}/internal/version" | jq -r '.revision' || echo "")
if [ "${REVISION}" == "" ]; then
  echo "Error fetching version of consumer from ${CONSUMER_HOST}/internal/version - using HEAD instead."
  REVISION=HEAD
  USE_COVENANT="false"
fi

echo "provider name: ${PROVIDER_NAME}"
echo "provider version: ${GIT_REVISION}"
echo "consumer name: ${CONSUMER_NAME}"
echo "consumer host: ${CONSUMER_HOST}"
echo "consumer version: ${REVISION}"

# return now if cdc has already been successful
if use_covenant; then
  cdc_has_been_successful "${PROVIDER_NAME}" "${GIT_REVISION}" "${CONSUMER_NAME}" "${REVISION}" && exit 0
else
  echo "covenant disabled"
fi

echo

# write git key to file
echo "${CONSUMER_GIT_KEY}" > .gitkey
chmod 600 .gitkey

# clone consumer into /scratch/consumer. dir may already exist when concourse restarts task
rm -rf /scratch/consumer
GIT_SSH_COMMAND="ssh -o StrictHostKeychecking=no -i .gitkey" git clone ${GIT_CLONE_OPTIONS} ${CONSUMER_GIT_URI} /scratch/consumer
cd /scratch/consumer

# checkout revision
git checkout ${REVISION}
cd /scratch/consumer/${CONSUMER_PATH}

# continue on error from this point so can record it
set +e

# run the tests with docker-compose
docker-compose -f ${DOCKER_COMPOSE_FILE:-docker-compose.yml} pull --quiet ${DOCKER_COMPOSE_SERVICE:-code}

echo running following docker-compose command:
echo docker-compose -f ${DOCKER_COMPOSE_FILE:-docker-compose.yml} run --no-deps \
  --entrypoint "${CONSUMER_SCRIPT}" \
  -e DEPENDENCY_NAME=${PROVIDER_NAME} \
  -e ${PROVIDER_HOST_KEY}=${PROVIDER_HOST} \
  -e CDC_CONSUMER_NAME=${CONSUMER_NAME} \
  -e CDC_CONSUMER_VERSION=${REVISION} \
  -e CDC_PROVIDER_NAME=${PROVIDER_NAME} \
  -e CDC_PROVIDER_VERSION=${GIT_REVISION} \
  ${ENV_OPTIONS:-} \
  ${VOLUME_OPTIONS:-} \
  ${DOCKER_COMPOSE_SERVICE:-code}

docker-compose -f ${DOCKER_COMPOSE_FILE:-docker-compose.yml} run --no-deps \
  --entrypoint "${CONSUMER_SCRIPT}" \
  -e DEPENDENCY_NAME=${PROVIDER_NAME} \
  -e ${PROVIDER_HOST_KEY}=${PROVIDER_HOST} \
  -e CDC_CONSUMER_NAME=${CONSUMER_NAME} \
  -e CDC_CONSUMER_VERSION=${REVISION} \
  -e CDC_PROVIDER_NAME=${PROVIDER_NAME} \
  -e CDC_PROVIDER_VERSION=${GIT_REVISION} \
  ${ENV_OPTIONS:-} \
  ${VOLUME_OPTIONS:-} \
  ${DOCKER_COMPOSE_SERVICE:-code}

DC_STATUS=$?

# record result in covenant
if use_covenant; then
  RESULT="FAIL"
  [[ $DC_STATUS == 0 ]] && RESULT="PASS"
  record_cdc_result "${PROVIDER_NAME}" "${GIT_REVISION}" "${CONSUMER_NAME}" "${REVISION}" "${RESULT}"
fi

exit $DC_STATUS
