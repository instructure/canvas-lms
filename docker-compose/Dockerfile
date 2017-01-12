FROM instructure/ruby-passenger:2.1

USER root
RUN curl -sL https://deb.nodesource.com/setup_0.12 | bash -
RUN  apt-get update -qq \
  && apt-get install -qqy \
       nodejs \
       postgresql-client \
       libxmlsec1-dev \
       unzip \
       fontforge \
  && npm install -g gulp \
  && rm -rf /var/lib/apt/lists/*

# We will need sfnt2woff in order to build fonts
WORKDIR /root
RUN if [ -e /var/lib/gems/$RUBY_MAJOR.0/gems/bundler-* ]; then BUNDLER_INSTALL="-i /var/lib/gems/$RUBY_MAJOR.0"; fi \
  && curl -O http://people.mozilla.org/~jkew/woff/woff-code-latest.zip \
  && unzip woff-code-latest.zip \
  && make \
  && cp sfnt2woff /usr/local/bin \
  && gem uninstall --all --ignore-dependencies --force $BUNDLER_INSTALL bundler \
  && gem install bundler --no-document -v 1.11.2 \
  && find $GEM_HOME ! -user docker | xargs chown docker:docker

USER docker
WORKDIR /usr/src/app

# Note that setting the path where the gems go to /app/vendor causes them to be built to the
# local machine since /app is mounted to the root dir on the local machine.  This is done using
# docker-compose run web bundle install after the contain is created.
#RUN bundle config path /app/vendor/bundle/docker/2.1
# This is set already (by the base image I think), so our change above doesn't take effect
ENV BUNDLE_PATH /app/vendor/bundle/docker/2.1
# No idea why this was here.  It's the default anyway.
#RUN bundle config bin /usr/local/bundle/bin
ENV RAILS_ENV development
