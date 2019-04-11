FROM ruby:2.1.9

#fix for jessie repo eol issues
RUN echo "deb [check-valid-until=no] http://cdn-fastly.deb.debian.org/debian jessie main" > /etc/apt/sources.list.d/jessie.list
RUN echo "deb [check-valid-until=no] http://archive.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/jessie-backports.list
RUN sed -i '/deb http:\/\/httpredir.debian.org\/debian jessie-updates main/d' /etc/apt/sources.list

RUN set -ex \
   && apt-get -o Acquire::Check-Valid-Until=false update \
   && apt-get install rlwrap \
   && curl -o nodejs.deb https://deb.nodesource.com/node_0.12/pool/main/n/nodejs/nodejs_0.12.14-1nodesource1~jessie1_amd64.deb  \
   && dpkg -i ./nodejs.deb \
   && rm nodejs.deb \
   && apt-get install -qqy postgresql-client libxmlsec1-dev unzip fontforge \
   && npm install -g gulp \
   && rm -rf /var/lib/apt/lists/*

RUN mkdir /app
WORKDIR /app

COPY Gemfile* /app/
COPY ./config/canvas_rails4_2.rb /app/config/

COPY . /app

RUN gem uninstall -x -i/usr/local/lib/ruby/gems/2.1.0 bundler

RUN gem install bundler -v 1.11.2

RUN bundle config path /app/vendor/bundle/docker/$(ruby -e 'print RUBY_VERSION')/
RUN bundle config bin /usr/local/bundle/bin

RUN bundle install

RUN rake canvas:compile_assets

#CMD ["rails", "s", "-p", "3001", "-b", "0.0.0.0"]
