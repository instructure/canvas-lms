# Make sure you change the postgresql-server-dev package version when you change this
FROM postgres:9.5

# Install dependencies for postgres extension for I18n sorting
RUN apt-get update -qq \
  && apt-get install -qqy \
      build-essential \
      ca-certificates \
      libicu-dev \
      postgresql-server-dev-9.5 \
      pgxnclient \
      unzip \
  && rm -rf /var/lib/apt/lists/*

# Install postgres extension for I8n sorting
# This is pretty horrible but the package won't install with the default Makefile
# so we need to edit it a bit.
ENV PG_COLLKEY_VERSION 0.5.1
RUN pgxnclient download --yes --target ~ pg_collkey=${PG_COLLKEY_VERSION} \
    && unzip ~/pg_collkey-${PG_COLLKEY_VERSION}.zip -d ~/ \
    && cd ~/pg_collkey-${PG_COLLKEY_VERSION} \
    && mv Makefile Makefile.orig \
    && sed '/^DATA = \$(wildcard/d' Makefile.orig > Makefile \
    && make \
    && make install
