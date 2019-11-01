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

# Use bash to make `heroku ps:exec` work. See: https://stackoverflow.com/questions/46652928/shell-into-a-docker-container-running-on-a-heroku-dyno-how
RUN rm /bin/sh && ln -s /bin/bash /bin/sh \
  && apt-get -qqy remove ruby ruby-dev ruby1.9.1 ruby1.9.1-dev libruby1.9.1 \
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
  && rm -rf /var/lib/apt/lists/* \
  && gem install bundler -v 1.15.2 \
  && mkdir /app \
  && useradd -m dockeruser \
  && chown dockeruser:dockeruser /app

WORKDIR /app

# Copy files needed for bundle install to work.
# By explicitly doing only the files needed, rebuilds won't re-run 
# 'bundle install' unless one of these changes.
COPY Gemfile Gemfile.lock /app/
COPY Gemfile.d /app/Gemfile.d
COPY gems /app/gems
COPY config/canvas_rails4_2.rb /app/config/

USER dockeruser
#RUN bundle install --path vendor/bundle --without=sqlite mysql --jobs 4 --verbose
RUN bundle install --path vendor/bundle --without=sqlite mysql --jobs 4

# Copy the files needed for rake canvas:compile_assets to work
# By explicitly doing only the files needed, rebuilds won't re-run 
# 'canvas:compile_assets' unless one of these changes.
USER root
COPY .babelrc .bowerrc .fontcustom-manifest.json .i18nignore .jshintrc .npmrc .selinimumignore \
      package.json \
      npm-shrinkwrap.json \
      Rakefile \
      gulpfile.babel.js /app/
COPY app/stylesheets /app/app/stylesheets
COPY app/coffeescripts /app/app/coffeescripts
COPY app/jsx /app/app/jsx
COPY app/assets /app/app/assets
COPY app/views/jst /app/app/views/jst
COPY bin /app/bin
COPY config/application.rb \
     config/boot.rb \
     config/build.js.erb \
     config/brandable_css.yml \
     config/browsers.yml \
     config/routes.rb \
     config/styleguide.yml /app/config/
COPY config/initializers/webpack.rb \
     config/initializers/plugin_symlinks.rb \
     config/initializers/client_app_symlinks.rb \
     config/initializers/json.rb /app/config/initializers/
COPY config/locales /app/config/locales
COPY client_apps/canvas_quizzes /app/client_apps/canvas_quizzes
COPY doc /app/doc
COPY lib/tasks /app/lib/tasks
COPY lib/canvas.rb \
     lib/canvas_yaml.rb \
     lib/logging_filter.rb \
     lib/canvas_logger.rb \
     lib/ember_bundle.rb \
     lib/brandable_css.rb \
     lib/api_routes.rb \
     lib/api_route_set.rb /app/lib/
COPY lib/canvas/draft_state_validations.rb \
     lib/canvas/coffee_script.rb \
     lib/canvas/require_js.rb /app/lib/canvas/
COPY lib/canvas/require_js/plugin_extension.rb \
     lib/canvas/require_js/client_app_extension.rb /app/lib/canvas/require_js/
COPY lib/lti/re_reg_constraint.rb /app/lib/lti/
COPY public /app/public
COPY script /app/script
COPY spec/javascripts /app/spec/javascripts
COPY spec/coffeescripts /app/spec/coffeescripts

# We have to mkdir app/views/info b/c bin/dress_code tries to write styleguide.html.erb to this dir.
# Files are copied as root, so we need to change ownership
#
# Heroku doesn't run with root privilege, so setup the app as a non-root user
# See: https://devcenter.heroku.com/articles/container-registry-and-runtime#testing-an-image-locally
RUN mkdir -p /app/app/views/info/ \
    && find /app /home/dockeruser ! -user dockeruser -print0 | xargs -0 chown -h dockeruser:dockeruser
    
USER dockeruser

# We have to explicitly run `npm install` for canvas_i18nliner b/c it uses an older version
# of the i18nliner gem (18nliner@0.0.16) than the rest of the app (18nliner@0.1.6). Ideally,
# we would upgrade canvas_i18nliner as shown in these commits: 
#  - https://github.com/instructure/canvas-lms/commit/f02b43f5744c32fdf0864c14d6c21c8a77311596#diff-8e298f3a69736b529005b3495d96c273
#  - https://github.com/instructure/canvas-lms/commit/e4d7de76e391f9af6222f5374a4fef1a99c25f5a#diff-8e298f3a69736b529005b3495d96c273
# but we'd have to upgrade node 0.12.14 to node 6.x.x
# Note: we could look into downgrading the main app to this same version of 18nliner. I'm not sure anything else other than 
# canvas_i18nliner uses it...
#
# Here is the error you get if we try and use 18nliner@0.1.6
#/app/gems/canvas_i18nliner/js/main.js:2
#var Commands = I18nliner.Commands;
#                        ^
#TypeError: Cannot read property 'Commands' of undefined
#    at Object.<anonymous> (/app/gems/canvas_i18nliner/js/main.js:2:25)
#    ... ommitted ...
#    at Object.<anonymous> (/app/gems/canvas_i18nliner/bin/i18nliner:3:1)
#Error extracting JS translations; confirm that `./gems/canvas_i18nliner/bin/i18nliner generate_js` works

RUN cd /app/gems/canvas_i18nliner/ && npm install -dd \
    && bundle exec rake canvas:compile_assets --trace

# Do this last (after bundle install and canvas:compile_assets) so that the previous steps are cached
# and don't have to run again when we change things and rebuild (it just uses the cache).
# Note: in .dockerignore we exclude vendor/bundle and other things like node_modules and public/dist so the 
# host machine values in there (maybe from a manual build) 
# don't get copied in. Only the fresh built ones are inside the container.
COPY --chown=dockeruser:dockeruser . /app

# Let either heroku.yml (for prod) or docker-compose.yml (for dev) specify the start command)
# Decouple the container itself from how we'll start it in each env.
CMD ["bash"]
#CMD ["rails", "s", "-p", "3001", "-b", "0.0.0.0"]
#CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
