FROM instructure/node:8

ARG NPM_PRIVATE_SCOPE
ARG NPM_PRIVATE_REGISTRY
ARG NPM_PRIVATE_USERNAME
ARG NPM_PRIVATE_PASSWORD
ARG NPM_PRIVATE_EMAIL

USER root

# do this first so npm install can be cached if package.json has not changed
COPY package.json /usr/src/app
RUN npm install \
    && npm-private install @inst/sync-format-message-translations; exit 0

COPY . /usr/src/app
RUN chown -R docker:docker /usr/src/app

USER docker

CMD ["tail", "-f", "/dev/null"]
