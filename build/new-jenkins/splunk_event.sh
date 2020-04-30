#!/bin/bash

set -o errexit -o nounset -o xtrace -o errtrace -o pipefail

SPLUNK_URL=${SPLUNK_URL:-"https://http-inputs-inst.splunkcloud.com/services/collector"}
curl -k "$SPLUNK_URL" -H "Authorization: Splunk $SPLUNK_HEC_KEY" -d "$1"
