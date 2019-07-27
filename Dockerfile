# This is end-of-lifed Ubuntu 14, but we want to at least get canvas into a container and 
# running first before we figure out how to uprade the OS and all dependencies (like versions 
# of node and native built gems). 
FROM heroku/cedar:14

RUN curl -sL https://deb.nodesource.com/setup_0.12 | bash -
RUN apt-get -qqy remove ruby ruby-dev ruby1.9.1 ruby1.9.1-dev libruby1.9.1 \
  && apt-get -qqy autoremove \
  && apt-get install -qqy software-properties-common \
  && apt-add-repository -y ppa:brightbox/ruby-ng \
  && apt-get update -qq \
  && apt-get install -qqy ruby2.1 ruby2.1-dev

RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
  && apt-get install -qqy \
      libsqlite3-dev \
       nodejs \
#       postgresql-client \
       libxmlsec1-dev \
       unzip \
       fontforge \
       vim \
  && npm cache clean -f \
  && npm install -g n \
  && n 0.12.14 \
  && npm install -g gulp \
  && rm -rf /var/lib/apt/lists/* 

RUN gem install bundler -v 1.15.2

RUN mkdir /app
WORKDIR /app

COPY Gemfile /app/
COPY Gemfile.lock /app/
COPY Gemfile.d /app/Gemfile.d
COPY gems /app/gems
COPY config/canvas_rails4_2.rb /app/config/

#RUN bundle config bin /usr/local/bin/bundle
#RUN bundle config path /app/vendor/bundle/ruby/2.1.0/
#RUN bundle config gemfile /app/Gemfile

RUN bundle install --path vendor/bundle --without=sqlite mysql --jobs 4 --verbose

## Do this after bundle install b/c if we do it before, then any changes cause bundle install to run again.
## Note: in .dockerignore we exclude vendor/bundle so the host values in there (maybe from a manual build) 
## don't get copied in. Only the fresh built ones are inside the container.
COPY . /app

# TODO: uncomment me. This is just to get the Proof Of Concept going
#RUN rake canvas:compile_assets

#CMD ["rails", "s", "-p", "3001", "-b", "0.0.0.0"]
#CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
