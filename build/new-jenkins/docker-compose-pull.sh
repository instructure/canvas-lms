#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

# pull docker images (or build them if missing)

REGISTRY_BASE=starlord.inscloudgate.net/jenkins
POSTGIS=${POSTGIS:-2.5}

./build/new-jenkins/docker-with-flakey-network-protection.sh pull $PATCHSET_TAG

# When this build finishes, the docker clean-up script will remove the $PATCHSET_TAG
# because it is unlikely that another build that runs on the node will need it, saving
# disk space. The dependency image(s) will not be cleared however, so tag them to avoid
# future builds on this node from downloading the layers again.
WEBPACK_CACHE_SELECTED_TAG=$(docker image inspect -f "{{.Config.Labels.WEBPACK_CACHE_SELECTED_TAG}}" $PATCHSET_TAG)
./build/new-jenkins/docker-with-flakey-network-protection.sh pull $WEBPACK_CACHE_SELECTED_TAG

./build/new-jenkins/docker-with-flakey-network-protection.sh pull $REGISTRY_BASE/redis:alpine
./build/new-jenkins/docker-with-flakey-network-protection.sh pull $POSTGRES_IMAGE_TAG
./build/new-jenkins/docker-with-flakey-network-protection.sh pull $CASSANDRA_IMAGE_TAG
./build/new-jenkins/docker-with-flakey-network-protection.sh pull $DYNAMODB_IMAGE_TAG
