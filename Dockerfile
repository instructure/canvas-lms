# GENERATED FILE, DO NOT MODIFY!
# To update this file please edit the relevant template and run the generation
# task `build/dockerfile_writer.rb --env development --compose-file docker-compose.yml,docker-compose.override.yml --in build/Dockerfile.template --out Dockerfile`

ARG RUBY=2.6-p6.0.4

FROM instructure/ruby-passenger:$RUBY AS dependencies
LABEL maintainer="Instructure"

ARG POSTGRES_CLIENT=12
ENV APP_HOME /usr/src/app/
ENV RAILS_ENV production
ENV NGINX_MAX_UPLOAD_SIZE 10g
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_ALL en_US.UTF-8

WORKDIR $APP_HOME
COPY --chown=docker:docker config/canvas_rails_switcher.rb ${APP_HOME}/config/canvas_rails_switcher.rb
COPY --chown=docker:docker Gemfile   ${APP_HOME}
COPY --chown=docker:docker Gemfile.d ${APP_HOME}Gemfile.d

COPY --chown=docker:docker gems      ${APP_HOME}gems

ENV YARN_VERSION 1.19.1-1
ENV GEM_HOME /home/docker/.gem/$RUBY
ENV PATH $GEM_HOME/bin:$PATH
ENV BUNDLE_APP_CONFIG /home/docker/.bundle

USER root
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
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
  && rm -rf /var/lib/apt/lists/* \
  && mkdir -p /home/docker/.gem/ruby/$RUBY_MAJOR.0
RUN if [ -e /var/lib/gems/$RUBY_MAJOR.0/gems/bundler-* ]; then BUNDLER_INSTALL="-i /var/lib/gems/$RUBY_MAJOR.0"; fi \
  && gem uninstall --all --ignore-dependencies --force $BUNDLER_INSTALL bundler \
  && gem install bundler --no-document -v 1.17.3 \
  && find $GEM_HOME ! -user docker | xargs chown docker:docker

USER docker
RUN set -eux; \
  \
  # set up bundle config options \
  bundle config --global build.nokogiri --use-system-libraries \
  && bundle config --global build.ffi --enable-system-libffi \
  && mkdir -p \
    /home/docker/.bundle \
  # TODO: --without development \
  && bundle install --jobs $(nproc) \
  && rm -rf $GEM_HOME/cache

COPY --chown=docker:docker package.json ${APP_HOME}
COPY --chown=docker:docker yarn.lock    ${APP_HOME}

COPY --chown=docker:docker client_apps  ${APP_HOME}client_apps
COPY --chown=docker:docker packages     ${APP_HOME}packages

RUN set -eux; \
  mkdir -p .yardoc \
             app/stylesheets/brandable_css_brands \
             app/views/info \
             client_apps/canvas_quizzes/dist \
             client_apps/canvas_quizzes/node_modules \
             client_apps/canvas_quizzes/tmp \
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
             public/javascripts/client_apps \
             public/javascripts/compiled \
             public/javascripts/translations \
             reports \
             tmp \
             /home/docker/.bundler/ \
             /home/docker/.cache/yarn \
             /home/docker/.gem/ \
  && (DISABLE_POSTINSTALL=1 yarn install --pure-lockfile || DISABLE_POSTINSTALL=1 yarn install --pure-lockfile --network-concurrency 1) \
  && yarn cache clean

COPY --chown=docker:docker babel.config.js ${APP_HOME}
COPY --chown=docker:docker script          ${APP_HOME}script

RUN yarn postinstall

FROM dependencies AS webpack-final
ARG JS_BUILD_NO_UGLIFY=0

COPY --chown=docker:docker . ${APP_HOME}
RUN COMPILE_ASSETS_NPM_INSTALL=0 JS_BUILD_NO_UGLIFY="$JS_BUILD_NO_UGLIFY" bundle exec rails canvas:compile_assets
