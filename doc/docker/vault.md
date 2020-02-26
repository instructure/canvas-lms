# Vault

[Vault](https://www.vaultproject.io/) is a secrets management system from
Hashicorp. Canvas will eventually use Vault for its key-value store and for
authentication tokens for some backend services, though there will be a
file-based alternative in the style of `dynamic_settings.yml`

For those who need to run Vault in development we've provided a docker-compose
override file to start up a vault server and a rake task to initialize the vault
container.  Note that you will need to re-init vault every time you restart the
container, as development vault cannot persist data to disk

## Enabling Vault
To enable use of Vault with Docker there are three things that you need to do.

1. Add `docker-compose/vault.override.yml` to your `COMPOSE_FILE` env var.
2. Un-comment the development vault configuration in `config/vault.yml`
3. Run the rake task to pre-populate the config values in vault: `docker-compose run --rm web bin/rake canvas:seed_vault`
