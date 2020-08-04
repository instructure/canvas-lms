# must build ruby.Dockerfile image first
ARG RUBY_PATCHSET_IMAGE
FROM ${RUBY_PATCHSET_IMAGE}
LABEL maintainer="Instructure"

# default alpine HTTPS mirror
ARG ALPINE_MIRROR=https://alpine.global.ssl.fastly.net/alpine/
ARG NODE=10.19.0-r0

USER root
RUN set -eux; \
  \
  # these packages are temporary for generating this image \
  apk add --no-cache --virtual .builddeps --repository $ALPINE_MIRROR/v3.10/main \
    g++ \
    make \
    libsass \
  # these packages stick around in the final image \
  && apk add --no-cache --repository $ALPINE_MIRROR/v3.10/main \
    npm \
    nodejs=${NODE} \
    yarn \
  && apk add --no-cache curl \
  && cd /tmp \
  && curl -Ls https://github.com/instructure/phantomized/releases/download/2.1.1a/dockerized-phantomjs.tar.gz | tar xzv -C / \
  && curl -k -Ls https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2 | tar -jxf - \
  && cp phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/local/bin/phantomjs \
  && apk del --no-network curl \
  && rm -rf /tmp/*

USER docker
COPY --chown=docker:docker babel.config.js    ${APP_HOME}
COPY --chown=docker:docker build/new-jenkins  ${APP_HOME}build/new-jenkins
COPY --chown=docker:docker package.json       ${APP_HOME}
COPY --chown=docker:docker packages           ${APP_HOME}packages
COPY --chown=docker:docker script             ${APP_HOME}script
COPY --chown=docker:docker yarn.lock          ${APP_HOME}

RUN set -eux; \
  \
  mkdir -p \
    .yardoc \
    app/stylesheets/brandable_css_brands \
    app/views/info \
    client_apps/canvas_quizzes/dist \
    client_apps/canvas_quizzes/node_modules \
    client_apps/canvas_quizzes/tmp \
    config/locales/generated \
    gems/canvas_i18nliner/node_modules \
    node_modules \
    packages/canvas-planner/lib \
    packages/canvas-planner/node_modules \
    pacts \
    public/dist \
    public/doc/api \
    public/javascripts/client_apps \
    public/javascripts/compiled \
    public/javascripts/translations \
    reports \
    /home/docker/.cache/yarn \
  \
  && (yarn install --pure-lockfile || yarn install --pure-lockfile --network-concurrency 1) \
  && yarn cache clean

COPY --chown=docker:docker . ${APP_HOME}

RUN set -exu; \
  \
  COMPILE_ASSETS_NPM_INSTALL=0 bundle exec rails canvas:compile_assets \
  && yarn cache clean
