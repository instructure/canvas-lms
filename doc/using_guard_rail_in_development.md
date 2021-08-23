# Using GuardRail in Development

GuardRail allows activating different database configurations for specific blocks of code. This is frequently done to offload read queries to a replica (secondary) database in Canvas.

When offloading read queries to a replica, it's important to have the ability to test the change locally and verify no writes are occurring by accident.

This guide shows how to configure a read-only user to allow testing these kind of changes during development.

For more information on GuardRail see [The Canvas Manual](https://instructure.atlassian.net/wiki/spaces/CE/pages/1214382120/Canvas+ActiveRecord+Extensions#DATABASE-ENVIRONMENT-NUANCED-CONFIGURATION-WITH-GUARDRAIL).

## 1. Open `config/database.yml`
## 2. Add the following to the `common` YML section:
```
secondary:
    username: canvas_read_only
```

This should result in a `common` section that looks something like this:
```yml
common: &common
  adapter: postgresql
  host: <%= ENV.fetch('CANVAS_DATABASE_HOST', 'postgres') %>
  ...
  secondary:
    username: canvas_read_only
```

## 3. Create a new user and grant read-only access to databases:
First, create the new user
```bash
docker-compose run --rm web psql -h postgres -U postgres -c "CREATE USER canvas_read_only WITH PASSWORD 'sekret'"
```

When prompted for a password, use the Canvas default postgres password (`sekret` at the time of writing),

Next, grant the user read-only privileges to all tables in each database.

For each database (development, test, etc.) run the following, substituting the correct name for `<database name>`:
```bash
docker-compose run --rm web psql -h postgres -U postgres -d <database name> -c 'GRANT SELECT ON ALL TABLES IN SCHEMA public TO canvas_read_only'
```

## 4. That's it!
To validate that the new user has read-only access try activating the read-only DB configuration (using GuardRail) and try creating a row in a Canvas Rails console:
```ruby
=> GuardRail.activate(:secondary) { DeveloperKey.create! }
```

This should result in the following error:

```
ActiveRecord::StatementInvalid (PG::InsufficientPrivilege: ERROR:  permission denied for table developer_keys)
```

Activating the primary DB configuration, however, should allow inserting the new row:
```ruby
=> GuardRail.activate(:primary) { DeveloperKey.create! }
...
SQL  (1.3ms)  COMMIT  [development:1 primary]
```