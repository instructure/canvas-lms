FROM instructure/node:10

USER root
RUN apt-get update \
    && apt-get install -y xvfb libgtk2.0-0 libnotify-dev libgconf-2-4 libnss3 libxss1 libasound2

USER docker

ARG NPM_PRIVATE_SCOPE
ARG NPM_PRIVATE_REGISTRY
ARG NPM_PRIVATE_USERNAME
ARG NPM_PRIVATE_PASSWORD
ARG NPM_PRIVATE_EMAIL

COPY . /usr/src/app
WORKDIR /usr/src/app

USER root
RUN chown -R docker:docker /usr/src/app
USER docker

RUN npm install \
    && npm-private install @inst/sync-format-message-translations; exit 0

CMD ["tail", "-f", "/dev/null"]
