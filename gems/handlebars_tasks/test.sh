#!/bin/bash
set -e

bundle check || bundle install

# Looks at ./.nvmrc to see which version of node to run,
# installs it if it's not already, and loads it into PATH
echo "NVM_DIR is: $NVM_DIR"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  echo "loading nvm"
  . "$NVM_DIR/nvm.sh"
  [[ -s ../../.nvmrc ]] && nvm install
  echo "loading nvm worked"
fi

bundle exec rspec spec
