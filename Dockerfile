# GENERATED FILE, DO NOT MODIFY!
# To update this file please edit the relevant template and run the generation
# task `build/dockerfile_writer.rb`

# For documentation, please check doc/docker/README.md in
# this local repo which is also published at:
# https://github.com/instructure/canvas-lms/tree/master/doc/docker
ARG RUBY_PASSENGER=2.4-xenial
FROM instructure/ruby-passenger:$RUBY_PASSENGER
ARG POSTGRES_VERSION=9.5

ENV APP_HOME /usr/src/app/
ENV RAILS_ENV "production"
ENV NGINX_MAX_UPLOAD_SIZE 10g
ENV YARN_VERSION 1.19.1-1

USER root
WORKDIR /root
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
       postgresql-client-$POSTGRES_VERSION \
       unzip \
       pbzip2 \
       fontforge \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir -p /home/docker/.gem/ruby/$RUBY_MAJOR.0

RUN if [ -e /var/lib/gems/$RUBY_MAJOR.0/gems/bundler-* ]; then BUNDLER_INSTALL="-i /var/lib/gems/$RUBY_MAJOR.0"; fi \
  && gem uninstall --all --ignore-dependencies --force $BUNDLER_INSTALL bundler \
  && gem install bundler --no-document -v 1.17.3 \
  && find $GEM_HOME ! -user docker | xargs chown docker:docker

# We will need sfnt2woff in order to build fonts
COPY --chown=docker:docker build/vendor/woff-code-latest.zip ./
RUN unzip woff-code-latest.zip -d woff \
  && cd woff \
  && make \
  && cp sfnt2woff /usr/local/bin \
  && cd - \
  && rm -rf woff*

WORKDIR $APP_HOME

COPY --chown=docker:docker Gemfile         ${APP_HOME}
COPY --chown=docker:docker Gemfile.d       ${APP_HOME}Gemfile.d
COPY --chown=docker:docker config          ${APP_HOME}config
COPY --chown=docker:docker gems            ${APP_HOME}gems
COPY --chown=docker:docker packages        ${APP_HOME}packages
COPY --chown=docker:docker script          ${APP_HOME}script
COPY --chown=docker:docker package.json    ${APP_HOME}
COPY --chown=docker:docker yarn.lock       ${APP_HOME}
COPY --chown=docker:docker babel.config.js ${APP_HOME}

USER docker
RUN bundle install --jobs 8 \
  && yarn install --pure-lockfile
COPY --chown=docker:docker . $APP_HOME
RUN mkdir -p .yardoc \
             app/stylesheets/brandable_css_brands \
             app/views/info \
             client_apps/canvas_quizzes/dist \
             client_apps/canvas_quizzes/node_modules \
             client_apps/canvas_quizzes/tmp \
             config/locales/generated \
             gems/canvas_i18nliner/node_modules \
             gems/selinimum/node_modules \
             log \
             node_modules \
             packages/canvas-planner/lib \
             packages/canvas-planner/node_modules \
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
             /home/docker/.gem/

# update Gemfile.lock in cases where a lock file was pulled in during the `COPY --chown=docker:docker . $APP_HOME` step
RUN bundle lock --local --conservative

# TODO: switch to canvas:compile_assets_dev once we stop using this Dockerfile in production/e2e
RUN COMPILE_ASSETS_NPM_INSTALL=0 bundle exec rake canvas:compile_assets
