FROM ruby:2.1

ENV DEBIAN_FRONTEND noninteractive

RUN curl -sL https://deb.nodesource.com/setup | bash -
RUN  apt-get update -qq \
  && apt-get install -qqy \
       locales \
       nodejs \
       postgresql-client \
       libxmlsec1-dev \
  && rm -rf /var/lib/apt/lists/*

# Ensure UTF-8 locale
RUN echo en_US.UTF-8 UTF-8 >> /etc/locale.gen
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8
RUN dpkg-reconfigure locales

# Canvas requires bundler 1.7.10
#RUN gem uninstall bundler \
#  && gem install bundler -v 1.7.10
# 1.7.10 has a bug preventing bundle install to work.  Error is "NoMethodError: undefined method `spec' for nil:NilClass"
RUN gem uninstall bundler -i /usr/local/lib/ruby/gems/2.1.0 bundler \
  && gem install bundler -v 1.7.15

RUN mkdir /app
WORKDIR /app

RUN mkdir /home/docker \
 && useradd -d /home/docker docker \
 && chown -R docker:docker /home/docker /usr/local/bundle

ENV PATH /usr/local/bundle/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
USER docker

# Note that setting the path where the gems go to /app/vendor causes them to be built to the
# local machine since /app is mounted to the root dir on the local machine.  This is done using
# docker-compose run web bundle install after the contain is created.
#RUN bundle config path /app/vendor/bundle/docker/2.1
# This is set already (by the base image I think), so our change above doesn't take effect
ENV BUNDLE_PATH /app/vendor/bundle/docker/2.1
# No idea why this was here.  It's the default anyway.
#RUN bundle config bin /usr/local/bundle/bin
ENV RAILS_ENV development
