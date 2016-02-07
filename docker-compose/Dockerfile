FROM ruby:2.1

ENV DEBIAN_FRONTEND noninteractive

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

# Ensure UTF-8 locale
ENV LANG C.UTF-8

# We will need sfnt2woff in order to build fonts
WORKDIR /root
RUN wget http://people.mozilla.org/~jkew/woff/woff-code-latest.zip \
  && unzip woff-code-latest.zip \
  && make \
  && cp sfnt2woff /usr/local/bin

# Canvas requires bundler 1.11.2
RUN gem uninstall -i /usr/local/lib/ruby/gems/2.1.0 bundler \
  && gem install bundler -v 1.11.2

RUN mkdir /app
WORKDIR /app

RUN mkdir /home/docker \
 && useradd -d /home/docker docker \
 && chown -R docker:docker /home/docker /usr/local/bundle

ENV PATH /usr/local/bundle/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV BUNDLE_PATH /app/vendor/bundle/docker/"$RUBY_VERSION"
USER docker

ENV RAILS_ENV development
