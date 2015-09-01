FROM ruby:2.1

ENV DEBIAN_FRONTEND noninteractive

RUN curl -sL https://deb.nodesource.com/setup | bash -
RUN  apt-get update -qq \
  && apt-get install -qqy \
       locales \
       nodejs \
       postgresql-client \
       libxmlsec1-dev \
  && npm install -g gulp \
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

RUN mkdir /home/docker \
 && useradd -d /home/docker docker \
 && chown -R docker:docker /home/docker /usr/local/bundle

ENV PATH /usr/local/bundle/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
USER docker

RUN bundle config path /app/vendor/bundle/docker/$(ruby -e 'print RUBY_VERSION')/
RUN bundle config bin /usr/local/bundle/bin
ENV RAILS_ENV development
