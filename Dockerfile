# See doc/docker/README.md or https://github.com/instructure/canvas-lms/tree/master/doc/docker
FROM instructure/ruby-passenger:2.4

ENV APP_HOME /usr/src/app/
ENV RAILS_ENV "production"
ENV NGINX_MAX_UPLOAD_SIZE 10g

# Work around github.com/zertosh/v8-compile-cache/issues/2
# This can be removed once yarn pushes a release including the fixed version
# of v8-compile-cache.
ENV DISABLE_V8_COMPILE_CACHE 1

USER root
WORKDIR /root
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -\
  && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -\
  && echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list \
  && apt-get update -qq \
  && apt-get install -qqy \
       nodejs \
       yarn \
       postgresql-client \
       libxmlsec1-dev \
       unzip \
       fontforge \
       python-lxml \
       libicu-dev \
  && yarn global add gulp \
  && rm -rf /var/lib/apt/lists/*\
  && mkdir -p /home/docker/.gem/ruby/$RUBY_MAJOR.0

# We will need sfnt2woff in order to build fonts
RUN if [ -e /var/lib/gems/$RUBY_MAJOR.0/gems/bundler-* ]; then BUNDLER_INSTALL="-i /var/lib/gems/$RUBY_MAJOR.0"; fi \
  && curl -O  https://people-mozilla.org/~jkew/woff/woff-code-latest.zip \
  && unzip woff-code-latest.zip \
  && make \
  && cp sfnt2woff /usr/local/bin \
  && gem uninstall --all --ignore-dependencies --force $BUNDLER_INSTALL bundler \
  && gem install bundler --no-document -v 1.14.3 \
  && gem update --system --no-document \
  && find $GEM_HOME ! -user docker | xargs chown docker:docker

WORKDIR $APP_HOME

USER root
COPY Gemfile      ${APP_HOME}
COPY Gemfile.d    ${APP_HOME}Gemfile.d
COPY config       ${APP_HOME}config
COPY gems         ${APP_HOME}gems
COPY script       ${APP_HOME}script
COPY package.json ${APP_HOME}
COPY yarn.lock    ${APP_HOME}
RUN chown -R docker:docker ${APP_HOME} /home/docker

# Install deps as docker to avoid sadness w/ npm lifecycle hooks
USER docker
RUN bundle install --jobs 8 \
  && yarn install --pure-lockfile
USER root

COPY . $APP_HOME
RUN mkdir -p log \
             tmp \
             public/javascripts/client_apps \
             public/dist \
             public/assets \
             client_apps/canvas_quizzes/node_modules \
             /home/docker/.cache/yarn/.tmp \
  && chown -R docker:docker ${APP_HOME} /home/docker

USER docker
RUN COMPILE_ASSETS_NPM_INSTALL=0 bundle exec rake canvas:compile_assets
