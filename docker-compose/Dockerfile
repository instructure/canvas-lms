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
       python-lxml \
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
  && gem install bundler --no-document -v 1.12.5 \
  && find $GEM_HOME ! -user docker | xargs chown docker:docker

USER docker

RUN mkdir -p /home/docker/.gem/ruby/$RUBY_MAJOR.0
WORKDIR /usr/src/app

ENV RAILS_ENV development
ENV NGINX_MAX_UPLOAD_SIZE 10g
