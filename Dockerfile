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

RUN mkdir /app
WORKDIR /app

COPY Gemfile /app/
COPY Gemfile.lock /app/
COPY Gemfile.d /app/Gemfile.d
COPY gems /app/gems
COPY config/canvas_rails4_2.rb /app/config/

RUN bundle install --path vendor/bundle --without=sqlite mysql --jobs 4 --verbose

# Do this after bundle install b/c if we do it before, then any changes cause bundle install to run again.
# Note: in .dockerignore we exclude vendor/bundle so the host values in there (maybe from a manual build) 
# don't get copied in. Only the fresh built ones are inside the container.
COPY . /app

# TODO: uncomment me. This is just to get the Proof Of Concept going
#RUN rake canvas:compile_assets

#CMD ["rails", "s", "-p", "3001", "-b", "0.0.0.0"]
#CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
