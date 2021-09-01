# GENERATED FILE, DO NOT MODIFY!
# To update this file please edit the relevant template and run the generation
# task `build/dockerfile_writer.rb --env development --compose-file docker-compose.yml,docker-compose.override.yml --in build/Dockerfile.template --out Dockerfile`

ARG RUBY=2.7

FROM instructure/ruby-passenger:$RUBY
LABEL maintainer="Instructure"

ARG POSTGRES_CLIENT=12
ENV APP_HOME /usr/src/app/
ENV RAILS_ENV development
ENV NGINX_MAX_UPLOAD_SIZE 10g
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ARG CANVAS_RAILS6_0=1
ENV CANVAS_RAILS6_0=${CANVAS_RAILS6_0}

ENV YARN_VERSION 1.19.1-1
ENV BUNDLER_VERSION 2.2.17
ENV GEM_HOME /home/docker/.gem/$RUBY
ENV PATH $GEM_HOME/bin:$PATH
ENV BUNDLE_APP_CONFIG /home/docker/.bundle

WORKDIR $APP_HOME

USER root

ARG USER_ID
# This step allows docker to write files to a host-mounted volume with the correct user permissions.
# Without it, some linux distributions are unable to write at all to the host mounted volume.
RUN if [ -n "$USER_ID" ]; then usermod -u "${USER_ID}" docker \
        && chown --from=9999 docker /usr/src/nginx /usr/src/app -R; fi

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - \
  && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
  && printf 'path-exclude /usr/share/doc/*\npath-exclude /usr/share/man/*' > /etc/dpkg/dpkg.cfg.d/01_nodoc \
  && echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
  && curl -sS https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
  && apt-get update -qq \
  && apt-get install -qqy --no-install-recommends \
       nodejs \
       yarn="$YARN_VERSION" \
       libxmlsec1-dev \
       python-lxml \
       libicu-dev \
       parallel \
       postgresql-client-$POSTGRES_CLIENT \
       unzip \
       pbzip2 \
       fontforge \
       autoconf \
       automake \
       git \
       build-essential \
       python2 \
       python-is-python2 \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir -p /home/docker/.gem/ruby/$RUBY_MAJOR.0

# install pulsar stuff
ENV PULSAR_VERSION=2.8.0
ENV PULSAR_CLIENT_SHA512=56570e10d6935ecf319501ebe80d2ff7c9f344cba6e1c2cfd9ea6883730d3abd14c1a3037e800ca5296830ead8c6d8df066cb4f403de2362aec9c1662fa011df
ENV PULSAR_CLIENT_DEV_SHA512=fc3b5ecb0a69c0fbebd177fbb9c8c22273a81df48430f9175f79bc5b8e379744b83de394e1e8752b93cd96896721a8b4ddb4b4ed50c5019e000dd5c7901b8578
# pulsar installs 4 versions of this library, but we only need
# one, so at the end we remove the others to minimize the image size
RUN cd "$(mktemp -d)" && \
    curl -SLO 'https://mirror.cogentco.com/pub/apache/pulsar/pulsar-'$PULSAR_VERSION'/DEB/apache-pulsar-client.deb' && \
    curl -SLO 'https://mirror.cogentco.com/pub/apache/pulsar/pulsar-'$PULSAR_VERSION'/DEB/apache-pulsar-client-dev.deb' && \
    echo $PULSAR_CLIENT_SHA512 '*apache-pulsar-client.deb' | shasum -a 512 -c -s - && \
    echo $PULSAR_CLIENT_DEV_SHA512 '*apache-pulsar-client-dev.deb' | shasum -a 512 -c -s - && \
    apt install ./apache-pulsar-client*.deb && \
    rm ./apache-pulsar-client*.deb && \
    rm /usr/lib/libpulsarnossl.so* && \
    rm /usr/lib/libpulsar.a && \
    rm /usr/lib/libpulsarwithdeps.a

RUN if [ -e /var/lib/gems/$RUBY_MAJOR.0/gems/bundler-* ]; then BUNDLER_INSTALL="-i /var/lib/gems/$RUBY_MAJOR.0"; fi \
  && gem uninstall --all --ignore-dependencies --force $BUNDLER_INSTALL bundler \
  && gem install bundler --no-document -v $BUNDLER_VERSION \
  && find $GEM_HOME ! -user docker | xargs chown docker:docker
RUN npm install -g npm@latest && npm cache clean --force

USER docker

RUN set -eux; \
  mkdir -p \
    .yardoc \
    app/stylesheets/brandable_css_brands \
    app/views/info \
    config/locales/generated \
    gems/canvas_i18nliner/node_modules \
    log \
    node_modules \
    packages/canvas-media/es \
    packages/canvas-media/lib \
    packages/canvas-media/node_modules \
    packages/canvas-planner/lib \
    packages/canvas-planner/node_modules \
    packages/canvas-rce/canvas \
    packages/canvas-rce/lib \
    packages/canvas-rce/node_modules \
    packages/jest-moxios-utils/node_modules \
    packages/js-utils/es \
    packages/js-utils/lib \
    packages/js-utils/node_modules \
    packages/k5uploader/es \
    packages/k5uploader/lib \
    packages/k5uploader/node_modules \
    packages/old-copy-of-react-14-that-is-just-here-so-if-analytics-is-checked-out-it-doesnt-change-yarn.lock/node_modules \
    pacts \
    public/dist \
    public/doc/api \
    public/javascripts/translations \
    reports \
    tmp \
    /home/docker/.bundler/ \
    /home/docker/.cache/yarn \
    /home/docker/.gem/
