FROM mdillon/postgis:9.5

RUN echo "max_locks_per_transaction = 640" >> /usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample \
 && echo "max_stack_depth = 5MB" >> /usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample \
 && echo "random_page_cost = 1.0" >> /usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample \
 && echo "shared_buffers = 256MB" >> /usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample \
 && echo "effective_cache_size = 256MB" >> /usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample

# needs to be named .sh for it to get run
COPY /create-dbs.sh /docker-entrypoint-initdb.d/
COPY /zz-run-update-postgis.sh /docker-entrypoint-initdb.d/

COPY /wait-for-it /
