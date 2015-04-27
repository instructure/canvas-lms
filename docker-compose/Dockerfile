FROM ruby:2.1

ENV DEBIAN_FRONTEND noninteractive

RUN curl -sL https://deb.nodesource.com/setup | bash -
RUN  apt-get update -qq \
  && apt-get install -qqy \
       locales \
       nodejs \
       postgresql-client \
  && rm -rf /var/lib/apt/lists/*

# Ensure UTF-8 locale
RUN echo en_US.UTF-8 UTF-8 >> /etc/locale.gen
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8
RUN dpkg-reconfigure locales

# Canvas requires bundler 1.7.10
RUN gem uninstall bundler \
  && gem install bundler -v 1.7.10

RUN mkdir /app
WORKDIR /app
RUN bundle config path /app/vendor/bundle/docker
RUN bundle config bin /usr/local/bin
ENV RAILS_ENV development
