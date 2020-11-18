# syntax=docker/dockerfile:experimental

ARG PATCHSET_TAG
ARG WEBPACK_BUILDER_TAG

FROM $PATCHSET_TAG AS patchset

FROM $WEBPACK_BUILDER_TAG
ENV APP_HOME /usr/src/app/
ENV NODE_ENV test
ENV CHROME_BIN /usr/bin/chromium-browser

USER root
RUN apt-get update --quiet=2 \
 && apt-get install --quiet=2 chromium-browser  > /dev/null \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER docker
RUN --mount=type=bind,target=/tmp/src,source=/usr/src/app,from=patchset \
  cp -rf /tmp/src/. /usr/src/app

EXPOSE 9876
