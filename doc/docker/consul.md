# Consul

[Consul](https://www.consul.io/) is a service discovery and configuration
management system from Hashicorp. Canvas currently only uses the configuration
management k/v store. Generally speaking you won't need to run Consul during
development (or even small production deployments) because we have full
configuration support through `config/dynamic_settings.yml`.

For those who need to run Consul in development we've provided a docker-compose
override file to start up a Consul server and a rake task to pre-populate the
KV store from the values in `config/dynamic_settings.yml`. This rake task
(`canvas:seed_consul`) will traverse the tree found in the config file and write
the values found to the KV store, if a value already exists it will not be
overwritten. Due to the change in population mechanisms we have also enabled
persistence in the Consul container so users don't have to constantly refresh
the values in the KV store.

## Enabling Consul
To enable use of Consul with Docker there are three things that you need to do.

1. Add `docker-compose/consul.override.yml` to your `COMPOSE_FILE` env var.
2. Un-comment the development consul configuration in `config/consul.yml`
3. Run the rake task to pre-populate the config values in consul: `docker-compose run --rm web bin/rake canvas:seed_consul`
