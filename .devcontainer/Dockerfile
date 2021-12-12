# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.208.0/containers/ubuntu/.devcontainer/base.Dockerfile

# [Choice] Ubuntu version (use hirsuite or bionic on local arm64/Apple Silicon): hirsute, focal, bionic
ARG VARIANT="hirsute"
FROM mcr.microsoft.com/vscode/devcontainers/base:0-${VARIANT}

# Install stuff that doesn't rely on the repo being present.
RUN sudo apt-get update && export DEBIAN_FRONTEND=noninteractive && \
    sudo apt-get -y install ruby-dev postgresql zlib1g-dev libxml2-dev libsqlite3-dev libpq-dev libxmlsec1-dev curl build-essential pkg-config
    # sudo gem install bundle && \
    # sudo gem install bundler -v 2.2.30 && \
    # sudo gem install nokogumbo scrypt sanitize

USER vscode 
RUN echo '\
# Ensure that the devcontainer is ready before giving the user a shell.\n\
if [ ! -f /home/vscode/.setupDone ]\n\
then\n\
  echo "Waiting to make sure the container is ready..."\n\
  echo "Press F1, and run "Codespaces: View Creation Log" to check on it. It should take about 5-10 minutes."\n\
fi\n\
while [ ! -f /home/vscode/.setupDone ]\n\
do\n\
  sleep 2\n\
done\n\
\n\
echo "🎉 The container is ready!"\n\
echo "To initialize the database, run \"bundle exec rails db:initial_setup\". Then, to run Canvas, run \"bundle exec rails server\"."\n\
echo "For more information, check out https://github.com/instructure/canvas-lms/wiki/Quick-Start#github-codespaces-setup"\n\
echo "Have fun!"\n\
\n\
export PGHOST=localhost' >> /home/vscode/.bashrc

