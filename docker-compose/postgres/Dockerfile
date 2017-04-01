FROM postgres:9.3

# Install dependencies for postgres extension for I18n sorting
RUN apt-get update -qq \
  && apt-get install -qqy \
      build-essential \
      ca-certificates \
      libicu-dev \
      postgresql-server-dev-all \
      pgxnclient \
  && rm -rf /var/lib/apt/lists/*
# Install postgres extension for I8n sorting
RUN pgxnclient install pg_collkey
