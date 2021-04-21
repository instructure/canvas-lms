FROM instructure/node:14

ENV APP_HOME /usr/src/app/
ENV NODE_ENV test
ENV CHROME_BIN /usr/bin/chromium-browser

USER root

RUN apt-get update --quiet=2 \
 && apt-get install --quiet=2 chromium-browser  > /dev/null \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER docker

EXPOSE 9876
