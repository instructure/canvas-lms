FROM mdillon/postgis:9.5

RUN echo "max_locks_per_transaction = 640" >> /usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample \
 && echo "max_stack_depth = 5MB" >> /usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample \
 && echo "random_page_cost = 1.0" >> /usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample \
 && echo "shared_buffers = 256MB" >> /usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample \
 && echo "effective_cache_size = 256MB" >> /usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample

COPY /wait-for-it /

ENV PG_COLLKEY_VERSION 0.5.1

RUN apt-get update --quiet=2 \
  && apt-get install --quiet=2 \
    build-essential \
    ca-certificates \
    libicu-dev \
    postgresql-server-dev-9.5 \
    pgxnclient \
    unzip \
  && pgxnclient download --yes --target ~ pg_collkey=${PG_COLLKEY_VERSION} \
  && unzip ~/pg_collkey-${PG_COLLKEY_VERSION}.zip -d ~/ \
  && cd ~/pg_collkey-${PG_COLLKEY_VERSION} \
  && mv Makefile Makefile.orig \
  && sed '/^DATA = \$(wildcard/d' Makefile.orig > Makefile \
  && make \
  && make install \
  && cp ~/pg_collkey-${PG_COLLKEY_VERSION}/pg_collkey--${PG_COLLKEY_VERSION}.sql /usr/share/postgresql/9.5/extension \
  && apt-get remove -qqy \
    build-essential \
    ca-certificates \
    postgresql-server-dev-9.5 \
    pgxnclient \
    unzip \
  && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*
