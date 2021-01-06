FROM instructure/node:12

USER docker

ENV APP_HOME /usr/src/app
USER root

RUN mkdir -p $APP_HOME

# The yarn.lock file doesn't exist in canvas-planner anymore and should be copied from canvas-lms before running this Docker build
COPY package.json yarn.lock $APP_HOME/

WORKDIR $APP_HOME

RUN yarn

COPY . $APP_HOME

# This makes the container stay running, until explicitly stopped
# rather than being a build only image.
CMD ["tail", "-f", "/dev/null"]
