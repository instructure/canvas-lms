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
  && npm cache clean -f \
  && npm install -g n \
  && n 0.12.14 \
  && npm install -g gulp \
  && rm -rf /var/lib/apt/lists/* 

RUN mkdir /app
WORKDIR /app

COPY Gemfile* /app/
COPY ./config/canvas_rails4_2.rb /app/config/

COPY . /app

# Having trouble getting Heroku to work with bundler v1.11.2, so I upgraded it to v1.12.5 elsewhere.
#RUN gem uninstall -x --all --ignore-dependencies -i/usr/local/lib/ruby/gems/2.1.0 bundler
#RUN gem install bundler -v 1.11.2

RUN bundle install --path vendor/bundle --without=sqlite mysql --jobs 4

# TODO: uncomment me. This is just to get the Proof Of Concept going
#RUN rake canvas:compile_assets

#CMD ["rails", "s", "-p", "3001", "-b", "0.0.0.0"]
