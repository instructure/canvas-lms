FROM instructure/node:14

ENV APP_HOME /usr/src/app/
ENV NODE_ENV test
ENV CHROME_BIN /usr/bin/google-chrome

USER root

RUN apt-get update --quiet=2 \
 && curl -LOs https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
 && apt-get install --quiet=2 -y ./google-chrome-stable_current_amd64.deb git \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ./google-chrome-stable_current_amd64.deb

USER docker

EXPOSE 9876
