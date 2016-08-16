FROM ubuntu:trusty
MAINTAINER Instructure

# Env
ENV PHANTOMJS_VERSION 2.1.1

RUN \
  apt-get update -yqq && \
  apt-get install -fyqq wget curl libfreetype6 libfontconfig

RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -
RUN  apt-get update -qq \
  && apt-get install -qqy nodejs


RUN \
  mkdir -p /srv/var && \
  wget -q --no-check-certificate -O /tmp/phantomjs-$PHANTOMJS_VERSION-linux-x86_64.tar.bz2 https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-$PHANTOMJS_VERSION-linux-x86_64.tar.bz2 && \
  tar -xjf /tmp/phantomjs-$PHANTOMJS_VERSION-linux-x86_64.tar.bz2 -C /tmp && \
  rm -f /tmp/phantomjs-$PHANTOMJS_VERSION-linux-x86_64.tar.bz2 && \
  mv /tmp/phantomjs-$PHANTOMJS_VERSION-linux-x86_64/ /srv/var/phantomjs && \
  ln -s /srv/var/phantomjs/bin/phantomjs /usr/bin/phantomjs

EXPOSE 9876

RUN mkdir /app
WORKDIR /app

COPY entry_point.sh /opt/bin/entry_point.sh

ENTRYPOINT ["/opt/bin/entry_point.sh"]
