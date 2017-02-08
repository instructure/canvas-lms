# See doc/docker/README.md or https://github.com/instructure/canvas-lms/tree/master/doc/docker
FROM instructure/ruby-passenger:2.4

ENV APP_HOME /usr/src/app/
ENV RAILS_ENV "production"
ENV NGINX_MAX_UPLOAD_SIZE 10g

USER root
WORKDIR /root
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -\
  && apt-get update -qq \
  && apt-get install -qqy \
       nodejs \
       postgresql-client \
       libxmlsec1-dev \
       unzip \
       fontforge \
       python-lxml \
  && npm install -g gulp \
  && rm -rf /var/lib/apt/lists/*\
  && mkdir -p /home/docker/.gem/ruby/$RUBY_MAJOR.0

# We will need sfnt2woff in order to build fonts
RUN if [ -e /var/lib/gems/$RUBY_MAJOR.0/gems/bundler-* ]; then BUNDLER_INSTALL="-i /var/lib/gems/$RUBY_MAJOR.0"; fi \
  && curl -O  https://people-mozilla.org/~jkew/woff/woff-code-latest.zip \
  && unzip woff-code-latest.zip \
  && make \
  && cp sfnt2woff /usr/local/bin \
  && gem uninstall --all --ignore-dependencies --force $BUNDLER_INSTALL bundler \
  && gem install bundler --no-document -v 1.12.5 \
  && find $GEM_HOME ! -user docker | xargs chown docker:docker

WORKDIR $APP_HOME

USER root
COPY Gemfile      ${APP_HOME}
COPY Gemfile.d    ${APP_HOME}Gemfile.d
COPY config       ${APP_HOME}config
COPY gems         ${APP_HOME}gems
COPY script       ${APP_HOME}script
COPY package.json ${APP_HOME}
RUN chown -R docker:docker ${APP_HOME} /home/docker

# Install deps as docker to avoid sadness w/ npm lifecycle hooks
USER docker
RUN bundle install --jobs 8
RUN npm install
USER root

COPY . $APP_HOME
RUN mkdir -p log \
            tmp \
            public/javascripts/client_apps \
            public/dist \
            public/assets \
  && chown -R docker:docker ${APP_HOME} /home/docker

USER docker
RUN bundle exec rake canvas:compile_assets
