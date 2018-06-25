FROM instructure/node:8

# the instructure/node:8 docker image uses yarn 0.27 still, we want to use at least 1.3.2
USER root
ENV YARN_VERSION 1.3.2-1
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends yarn="$YARN_VERSION" \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/
USER docker

ENV APP_HOME /usr/src/app
USER root

RUN mkdir -p $APP_HOME

COPY package.json $APP_HOME/

WORKDIR $APP_HOME

RUN yarn

COPY . $APP_HOME

# This makes the container stay running, until explicitly stopped
# rather than being a build only image.
CMD ["tail", "-f", "/dev/null"]
