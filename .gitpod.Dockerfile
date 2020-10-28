FROM gitpod/workspace-postgres

# Install custom tools, runtimes, etc.
# For example "bastet", a command-line tetris clone:
# RUN brew install bastet
#
# More information: https://www.gitpod.io/docs/config-docker/
RUN sudo apt update \
sudo apt install -y ruby ruby-dev postgresql zlib1g-dev libxml2-dev libsqlite3-dev libpq-dev libxmlsec1-dev curl build-essential \
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash - \
sudo apt-get install -y nodejs \
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - \
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list \
sudo apt-get update && sudo apt-get install yarn=1.10.1-1 \
