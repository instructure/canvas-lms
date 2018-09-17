FROM instructure/node:8

ARG NPM_PRIVATE_SCOPE
ARG NPM_PRIVATE_REGISTRY
ARG NPM_PRIVATE_USERNAME
ARG NPM_PRIVATE_PASSWORD
ARG NPM_PRIVATE_EMAIL

USER root
ENV YARN_VERSION 1.9.4-1
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends yarn="$YARN_VERSION" \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/

# do this first so npm install can be cached if package.json has not changed
COPY package.json yarn.lock /usr/src/app/
RUN yarn \
    && yarn-private add @inst/sync-format-message-translations; exit 0

COPY . /usr/src/app
RUN chown -R docker:docker /usr/src/app

USER docker

CMD ["tail", "-f", "/dev/null"]
