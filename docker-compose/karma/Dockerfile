FROM instructure/node:8

ENV APP_HOME /usr/src/app/
ENV NODE_ENV test
ENV CHROME_BIN /usr/bin/google-chrome

USER root

RUN curl --silent "https://dl-ssl.google.com/linux/linux_signing_key.pub" | apt-key add - \
 && curl --silent "https://dl.yarnpkg.com/debian/pubkey.gpg" | apt-key add - \
 && echo "deb https://dl.google.com/linux/chrome/deb/ stable main" > "/etc/apt/sources.list.d/google.list" \
 && echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
 && apt-get update --quiet=2 \
 && apt-get install --quiet=2 google-chrome-beta yarn > /dev/null \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER docker

EXPOSE 9876
