FROM ruby:2.1.6

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

RUN mkdir /app
WORKDIR /app

COPY Gemfile* /app/
COPY ./config/canvas_rails4_2.rb /app/config/

RUN bundle install

COPY . /app

RUN bundle install

RUN rake canvas:compile_assets

CMD ["rails", "s", "-p", "3001", "-b", "0.0.0.0"]
