FROM instructure/node:18

ENV APP_HOME /usr/src/app/
ENV NODE_ENV test
ENV CHROME_BIN /usr/bin/google-chrome

USER root

ARG USER_ID
# This step allows docker to write files to a host-mounted volume with the correct user permissions.
# Without it, some linux distributions are unable to write at all to the host mounted volume.
RUN if [ -n "$USER_ID" ]; then usermod -u "${USER_ID}" docker \
        && chown --from=9999 docker /usr/src/nginx /usr/src/app -R; fi

RUN apt-get update --quiet=2 \
  && if [ "$(dpkg --print-architecture)" = "amd64" ]; then \
    curl -LOs https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt-get install --quiet=2 -y ./google-chrome-stable_current_amd64.deb git \
    && rm -rf ./google-chrome-stable_current_amd64.deb ; \
  elif [ "$(dpkg --print-architecture)" = "arm64" ]; then \
    apt-get install --quiet=2 -y  software-properties-common \
    && add-apt-repository ppa:phd/chromium-browser \
    && echo 'Package: *\nPin: release o=LP-PPA-phd-chromium-browser\nPin-Priority: 1001\n' | tee /etc/apt/preferences.d/phd-chromium-browser \
    && apt-get update --quiet=2 \
    && apt-get install --quiet=2 -y chromium-browser \
    && apt-get remove -y --autoremove software-properties-common \
    && ln -s /usr/bin/chromium-browser /usr/bin/google-chrome; \
  fi \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER docker

RUN set -eux; \
  mkdir -p \
    app/stylesheets/brandable_css_brands \
    log \
    node_modules \
    tmp \
    /home/docker/.cache/yarn

EXPOSE 9876
