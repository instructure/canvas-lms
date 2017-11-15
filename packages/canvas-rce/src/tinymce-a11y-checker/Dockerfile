FROM instructure/node:8

ARG NPM_PRIVATE_SCOPE
ARG NPM_PRIVATE_REGISTRY
ARG NPM_PRIVATE_USERNAME
ARG NPM_PRIVATE_PASSWORD
ARG NPM_PRIVATE_EMAIL

COPY . /usr/src/app
WORKDIR /usr/src/app

RUN npm install \
 && npm-private install @inst/sync-format-message-translations; exit 0

CMD ["tail", "-f", "/dev/null"]