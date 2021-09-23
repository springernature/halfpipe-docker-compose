#!/usr/bin/env bash
set -euo pipefail

_COVENANT_URL="https://covenant.springernature.app"

source colours.sh

is_covenant_available() {
    if curl -m 1 -Ls "$_COVENANT_URL" >/dev/null 2>&1; then
        return 0
    else
        echo -e "${LIGHT_RED}* Covenant is not available; skipping ${NC}"
        return 1
    fi
}

sanitise_cdc_name() {
    echo "${1/\//%2F}"
}

cdc_has_been_successful() {
    local CDC_PROVIDER_NAME="$(sanitise_cdc_name "${1}")"
    local CDC_PROVIDER_VERSION="${2}"
    local CDC_CONSUMER_NAME="$(sanitise_cdc_name "${3}")"
    local CDC_CONSUMER_VERSION="${4}"

    if ! is_covenant_available; then
        return 1
    else
        local RESULT
        echo -e "${GREEN}* Checking CDC for consumer ${BLUE}${CDC_CONSUMER_NAME}${GREEN}@${BLUE}${CDC_CONSUMER_VERSION}${GREEN} of provider ${BLUE}${CDC_PROVIDER_NAME}${GREEN}@${BLUE}${CDC_PROVIDER_VERSION}${NC}"
        RESULT=$(curl -Ls "$_COVENANT_URL/api/v1/result/$CDC_PROVIDER_NAME/$CDC_PROVIDER_VERSION/$CDC_CONSUMER_NAME/$CDC_CONSUMER_VERSION")
        if [[ "$RESULT" = "PASS" ]]; then
            echo -e "${GREEN}* Covenant reports a pass for the given versions - skipping execution${NC}"
            return 0
        else
            echo -e "${GREEN}* Covenant reports ${BLUE}$RESULT${GREEN} for the given versions - executing now${NC}"
            return 1
        fi
    fi
}

record_cdc_result() {
    local CDC_PROVIDER_NAME="$(sanitise_cdc_name "${1}")"
    local CDC_PROVIDER_VERSION="${2}"
    local CDC_CONSUMER_NAME="$(sanitise_cdc_name "${3}")"
    local CDC_CONSUMER_VERSION="${4}"
    local RESULT="${5}"

    if  is_covenant_available; then
        echo -e "${GREEN}* This CDC has completed with result ${BLUE}$RESULT${GREEN} - updating Covenant${NC}"
        echo curl -X POST -Ls "$_COVENANT_URL/api/v1/result/$CDC_PROVIDER_NAME/$CDC_PROVIDER_VERSION/$CDC_CONSUMER_NAME/$CDC_CONSUMER_VERSION" -d "$RESULT"
    fi
}
