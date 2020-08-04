ARG RUBY=2.6

FROM instructure/passenger-nginx-alpine:${RUBY} AS gems-only
LABEL maintainer="Instructure"

ARG POSTGRES_CLIENT=12.2
ARG ALPINE_MIRROR=http://dl-cdn.alpinelinux.org/alpine

ENV APP_HOME /usr/src/app/
ENV RAILS_ENV production
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_ALL en_US.UTF-8

WORKDIR $APP_HOME
COPY --chown=docker:docker config/canvas_rails_switcher.rb ${APP_HOME}/config/canvas_rails_switcher.rb
COPY --chown=docker:docker Gemfile   ${APP_HOME}
COPY --chown=docker:docker Gemfile.d ${APP_HOME}Gemfile.d
COPY --chown=docker:docker gems      ${APP_HOME}gems
ENV GEM_HOME /home/docker/.gem/$RUBY_VERSION
ENV PATH $GEM_HOME/bin:$PATH
ENV BUNDLE_APP_CONFIG /home/docker/.bundle

USER root
RUN set -eux; \
  \
  # create APP_HOME \
  chown docker:docker $APP_HOME \
  \
  # select a specific alpine repo mirror \
  && sed -i -E "s|http://dl-cdn.alpinelinux.org/alpine|${ALPINE_MIRROR}|g" /etc/apk/repositories \
  # these packages will be kept in the final image \
  && apk add --no-cache \
    # NOTE: why bash? some scripts have not been rewritten to be POSIX \
    # compliant, like rspec-with-retries.sh \
    # it would be ideal to get these scripts updated, but in the meantime  \
    # bash isn't the largest library so for size concerns it's not a dealbreaker \
    bash \
    coreutils \
    file \
    g++ \
    git \
    icu-dev \
    imagemagick \
    libffi-dev \
    libxml2-dev \
    libxslt-dev \
    make \
    postgresql-client~=$POSTGRES_CLIENT \
    postgresql-dev~=$POSTGRES_CLIENT \
    # TODO: need to upgrade to python 3 \
    py2-pip \
    python2 \
    ruby-dev \
    sqlite \
    sqlite-dev \
    tzdata \
    xmlsec \
    xmlsec-dev \
  && apk add --no-cache --virtual .pbzip2deps \
    bzip2-dev \
  \
  && apk add --no-cache --repository http://mirrors.gigenet.com/alpinelinux/v3.10/main \
    # qti_migration_tool dependency \
    py2-lxml \
  \
  # TODO: extract to its own build in a multi-image workflow \
  # pbzip2 installation \
  && cd /tmp/ \
  && wget -q https://launchpad.net/pbzip2/1.1/1.1.13/+download/pbzip2-1.1.13.tar.gz \
  && tar -xzf pbzip2-1.1.13.tar.gz \
  && cd pbzip2-1.1.13/ \
  && make install \
  && apk del --no-network .pbzip2deps \
  && cd $APP_HOME \
  && rm -r /tmp/pbzip2-1.1.13/ \
  \
  # python symlinks \
  && ln -s /usr/bin/python2 /usr/local/bin/python

USER docker
RUN set -eux; \
  \
  # set up bundle config options \
  bundle config --global build.nokogiri --use-system-libraries \
  && bundle config --global build.ffi --enable-system-libffi \
  && mkdir -p \
    /home/docker/.gem/$RUBY_VERSION \
    /home/docker/.bundle \
  # TODO: --without development \
  && bundle install --jobs $(nproc) \
  && rm -rf $GEM_HOME/cache

FROM gems-only AS final
COPY --chown=docker:docker . $APP_HOME
