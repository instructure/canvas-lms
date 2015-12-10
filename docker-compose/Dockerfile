FROM ruby:2.1

ENV DEBIAN_FRONTEND noninteractive

RUN curl -sL https://deb.nodesource.com/setup_0.12 | bash -
RUN  apt-get update -qq \
  && apt-get install -qqy \
       nodejs \
       postgresql-client \
       libxmlsec1-dev \
  && npm install -g gulp \
  && rm -rf /var/lib/apt/lists/*

# Ensure UTF-8 locale
ENV LANG C.UTF-8

# Canvas requires bundler 1.10.6
RUN gem uninstall bundler \
  && gem install bundler -v 1.10.6

RUN mkdir /app
WORKDIR /app

RUN mkdir /home/docker \
 && useradd -d /home/docker docker \
 && chown -R docker:docker /home/docker /usr/local/bundle

ENV PATH /usr/local/bundle/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
USER docker

RUN bundle config path /app/vendor/bundle/docker/$(ruby -e 'print RUBY_VERSION')/
RUN bundle config bin /usr/local/bundle/bin
ENV RAILS_ENV development
