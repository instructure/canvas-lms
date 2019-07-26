# If we want to try and get it going on Debian 9 (stretch) instead of Debian 8 (jessie), try this:
# https://gitlab.com/qixtand/dockerhub/blob/master/debian/stretch/ruby/2.1.9/Dockerfile

FROM ruby:2.1.9

RUN curl -sL https://deb.nodesource.com/setup_0.12 | bash -
RUN  apt-get update -qq \
  && apt-get install -qqy \
       nodejs \
       postgresql-client \
       libxmlsec1-dev \
       unzip \
       fontforge \
       vim \
  && npm cache clean -f \
  && npm install -g n \
  && n 0.12.14 \
  && npm install -g gulp \
  && rm -rf /var/lib/apt/lists/* 

# Blow away the existing bundler. We're going to install our own verion and make sure it's the only one.
RUN gem uninstall -x -i /usr/local/lib/ruby/gems/2.1.0 bundler
RUN gem uninstall -x -i /usr/local/lib/ruby/gems/2.1.0 rubygems-update
RUN gem install bundler -v 1.15.2

RUN mkdir /app
WORKDIR /app

COPY Gemfile /app/
COPY Gemfile.lock /app/
COPY Gemfile.d /app/Gemfile.d
COPY gems /app/gems
COPY config/canvas_rails4_2.rb /app/config/

RUN bundle config bin /usr/local/bin/bundle
RUN bundle config path /app/vendor/bundle/ruby/2.1.0/
RUN bundle config gemfile /app/Gemfile

RUN bundle install --path vendor/bundle --without=sqlite mysql --jobs 4 --verbose

# Do this after bundle install b/c if we do it before, then any changes cause bundle install to run again.
# Note: in .dockerignore we exclude vendor/bundle so the host values in there (maybe from a manual build) 
# don't get copied in. Only the fresh built ones are inside the container.
COPY . /app

# TODO: uncomment me. This is just to get the Proof Of Concept going
#RUN rake canvas:compile_assets

#CMD ["rails", "s", "-p", "3001", "-b", "0.0.0.0"]
#CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
