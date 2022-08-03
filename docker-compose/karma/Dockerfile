FROM instructure/node:16

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
 && curl -LOs https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
 && apt-get install --quiet=2 -y ./google-chrome-stable_current_amd64.deb git \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ./google-chrome-stable_current_amd64.deb

USER docker

RUN set -eux; \
  mkdir -p \
    app/stylesheets/brandable_css_brands \
    log \
    node_modules \
    tmp \
    /home/docker/.cache/yarn \

EXPOSE 9876
