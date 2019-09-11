# This is end-of-lifed Ubuntu 14, but we want to at least get canvas into a container and 
# running first before we figure out how to uprade the OS and all dependencies (like versions 
# of node and native built gems). 
FROM heroku/cedar:14

# Required for Docker heroku.yml builds to change it. 
# See: https://devcenter.heroku.com/articles/build-docker-images-heroku-yml#setting-build-time-environment-variables
ARG RAILS_ENV=development

# Required to prevent: Error: lib/dress_code/extractor.rb:31:in `scan': invalid byte sequence in US-ASCII 
ENV LC_ALL "en_US.UTF-8" 
ENV LANG "en_US.UTF-8"

# Make `heroku ps:exec` work. See: https://stackoverflow.com/questions/46652928/shell-into-a-docker-container-running-on-a-heroku-dyno-how
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN apt-get -qqy remove ruby ruby-dev ruby1.9.1 ruby1.9.1-dev libruby1.9.1 \
  && apt-get -qqy autoremove \
  && apt-get update -qq \
  && apt-get install -qqy software-properties-common \
  && apt-add-repository -y ppa:brightbox/ruby-ng \
  && apt-get update -qq \
  && apt-get install -qqy ruby2.1 ruby2.1-dev

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
  && apt-get install -qqy \
      libsqlite3-dev \
      nodejs \
      postgresql-client \
      libxmlsec1-dev \
      unzip \
      fontforge \
      vim \
  && npm cache clean -f \
  && npm install -g n \
  && n 0.12.14 \
#  && npm install -g gulp \
  && rm -rf /var/lib/apt/lists/* 

RUN gem install bundler -v 1.15.2

RUN mkdir /app
WORKDIR /app

COPY Gemfile /app/
COPY Gemfile.lock /app/
COPY Gemfile.d /app/Gemfile.d
COPY gems /app/gems
COPY config/canvas_rails4_2.rb /app/config/

#RUN bundle install --path vendor/bundle --without=sqlite mysql --jobs 4 --verbose
RUN bundle install --path vendor/bundle --without=sqlite mysql --jobs 4

## Do this after bundle install b/c if we do it before, then any changes cause bundle install to run again.
## Note: in .dockerignore we exclude vendor/bundle and other things like node_modules and public/dist so the 
# host machine values in there (maybe from a manual build) 
## don't get copied in. Only the fresh built ones are inside the container.
COPY . /app

# TODO: compile_assets is supposed to call npm install. However, If I don't do it myself in the canvas_i18nliner directory it fails with
# the error below. May have something to do with the npm version of i18nliner. 
# For now, just call npm install myself. To figure out the root cause and remove this, comment out this and compile_assets. Manually run
# compile assets where it fails and do an `npm ls` to see what is installed. Then run the line below and look at the diff. See if there
# are different versions i18nliner, handlebars, or something else.
RUN cd /app/gems/canvas_i18nliner/ && npm install
# Error without running the above and just relying on compile_assets:
#/app/gems/canvas_i18nliner/js/main.js:2
#var Commands = I18nliner.Commands;
#                        ^
#TypeError: Cannot read property 'Commands' of undefined
#    at Object.<anonymous> (/app/gems/canvas_i18nliner/js/main.js:2:25)
#    ... ommitted ...
#    at Object.<anonymous> (/app/gems/canvas_i18nliner/bin/i18nliner:3:1)
#Error extracting JS translations; confirm that `./gems/canvas_i18nliner/bin/i18nliner generate_js` works

RUN bundle exec rake canvas:compile_assets --trace

# Let either heroku.yml (for prod) or docker-compose.yml (for dev) specify the start command)
# Decouple the container itself from how we'll start it in each env.
CMD ["bash"]
#CMD ["rails", "s", "-p", "3001", "-b", "0.0.0.0"]
#CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
