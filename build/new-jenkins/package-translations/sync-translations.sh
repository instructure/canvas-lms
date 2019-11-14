#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

##
# This file is the main file for translating packages. It will run
# other scripts to facilitate the translation process.
##

export COMPOSE_FILE=docker-compose.new-jenkins-package-translations.yml

docker-compose build
docker-compose up -d

# Run the English extraction for each package, skipping packages without one.
docker-compose exec -T translations yarn wsrun --exclude-missing i18n:extract

# Merge translations from all packages together
docker-compose exec -T translations ./package-translations/merge-strings.sh

# Sync translations to both s3 and transifex (for crowd sourced stuff)
# Running as root so that we can have access to the sshkey
docker-compose exec -T -u root translations ./package-translations/sync-strings.sh
