ARG POSTGRES=14
ARG POSTGRESIMAGE=postgres

FROM $POSTGRESIMAGE:$POSTGRES

RUN echo "max_locks_per_transaction = 640" >> /usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample \
 && echo "max_stack_depth = 5MB" >> /usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample \
 && echo "random_page_cost = 1.0" >> /usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample \
 && echo "shared_buffers = 256MB" >> /usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample \
 && echo "effective_cache_size = 256MB" >> /usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample

RUN apt-get update -qq \
 && apt-get install -qqy --no-install-recommends postgresql-$PG_MAJOR-pgvector

COPY /create-dbs.sh /docker-entrypoint-initdb.d/
COPY /wait-for-it /
