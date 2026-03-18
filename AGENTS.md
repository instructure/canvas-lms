# AGENTS.md

AI coding assistant guidance for Canvas LMS.

## Quick Start

```bash
docker compose up                    # Start services
docker compose run --rm web bash     # Dev shell
yarn build:watch                     # Frontend dev mode
```

## Essential Commands

| Task | Command |
|------|---------|
| **Build** | `yarn build` (all), `yarn build:watch` (dev) |
| **Test JS** | `yarn test`, `yarn test:vitest`, `yarn test:watch` |
| **Test Ruby** | `bin/rspec` |
| **Lint** | `yarn lint` (JS), `bin/rubocop` (Ruby), `yarn check:biome` |
| **Type Check** | `yarn check:ts` |
| **Webpack** | `yarn webpack-development` (build), `yarn webpack` (watch) |

## Project Structure

- `ui/` - React components & shared packages
- `app/` - Rails MVC (controllers, models, views)
- `packages/` - Shared NPM packages
- `gems/plugins/` - Canvas plugins (account_reports, analytics, etc.)
- `lib/` - Ruby business logic

## Key Concepts

- **Multi-tenancy** via Account hierarchies
- **Database sharding** with Switchman gem
- **Plugin system** in `gems/plugins/`
- **LTI integrations** for external tools
- **Brandable CSS** theming (`yarn build:css`)
- **Feature flags** for gradual rollouts

## Docker Tips

- Any commands that use yarn, rake, bundle, or rails should be run inside the web container.
- Update packages: Edit package.json, run `docker_yarn` function
- Access Rails console: `docker compose run --rm web rails c`
- Database operations run inside containers

## Testing Docs

- JS testing guide: `doc/ui/testing_javascript.md`
- Run specific frontend tests: `yarn test path/to/test`
- Run specific RSpec tests: `bin/rspec path/to/test:<line_number>`
- Coverage: `yarn test:coverage`

## Git Commit Guidelines

- Keep each line in commit messages under 60 characters
- Keep it short
- Provide the why behind the change

## Updating Gems

- Never touch `Gemfile*.lock` files directly
- Run `bundle outdated` to find the list of outdated gems.
  Keep this list in memory so you don't have to keep running it, since it is a relatively slow command.
- Run `bundle update --conservative <gem_name>` to update individual gems
- Run `bundle install` one more time to ensure all lockfiles are in sync
- Commit the changes, with a commit message of `bundle update <gem_name>` (you don't need to include the conservative flag in the commit message).
  Be sure to check for changes in `Gemfile*.lock`, `Gemfile.d/*.lock`, and `gems/*/Gemfile*.lock`.
- Some groups of gems can be updated as a group:
  - `aws*`
  - `google*`
  - Rails: `action*`, `active*`, `rack*`, `rails`, `railties`, and `zeitwerk` -- except `active_model_serializers`
  - `datadog` and its dependencies that aren't shared with other gems, such as `libdatadog`
  - `faraday*`
  - `redis*`
  - `rspec*`
  - `rubocop*` (and their dependencies that aren't shared with other gems, such as `ast`)
  - `ruby-lsp*`
  - `sentry*`
- All other gems should be updated and committed independently.
- The commit message for a group of gems should be the base name without the wildcard as the "gem name", or `rails` for the Rails group.
- Look in `Gemfile.lock` to determine a gem's dependencies - they're indented one level deeper than the gem that depends on them in each `specs` section.
- Don't attempt to update any gems that already have an exact version requirement on them.
- Don't bother updating `sorbet-runtime` for patch version changes.
- Do the rubocop group last, after all other groups and individual gems, since it will likely have new offenses that will need to be resolved.
- If there are any `Gemfile.rails*.lock` files, you need to check them for updates as well, after the main lockfile is up to date.
  Do this by prefixing the commands with something like `BUNDLE_LOCKFILE=rails80`.
  You still need to run a bare `bundle install` afterwards to ensure the main lockfile and any child lockfiles stay in sync.

## Squashing Migrations

Squashing migrations is the process of going through individual migrations in db/migrate by date, and "squashing" them into the `InitCanvasDb` migration, then deleting the original.
- `change_table` blocks that add new structures can be moved into the corresponding `create_table` block.
- Individual DDL statements such as `add_index`, `add_reference`, etc. should also be moved to the corresponding `create_table` block, and modified as appropriate if their arguments differ.
- `remove_`-style statements should result in the removal of the corresponding `add_`-style structure from `InitCanvasDb`.
  Check the model file for any removed columns, and if the column has been ignored there, remove it from the list.
  Remove the `ignored_columns` line completely if the list is empty.
- `create_table` blocks should be moved into `InitCanvasDb` completely, putting it into its properly alphabetized position (using the non-plural form of the table name, so that for example `discussion_topics` is placed before `discussion_topic_replies`)
- `set_replication_identity` calls are moved into the `SetReplicaIdenties` migration, in their same alphabetized position.
- Any options (such as `algorithm: :concurrently`, `if_not_exists: true`, `validate: false`, `validate_constraint`) used to make the original migration idempotent are not necessary in `InitCanvasDb`, and should be removed.
- Options that are already the default should not be specified:
  - `default: nil`
  - `null: true`
  - `index: true` on `t.references` calls
  - `index: false` on non-reference column addition calls
- Keep the statements within `create_table` blocks organized, with a blank line between each section:
  - Column additions (including `t.timestamps`) are the first section, preserving their original order they were added
  - Additional constraints are the next section, preserving their original order they were added
  - Additional indexes are the final section, preserving their original order they were added, with the exception that the `t.replica_identity_index` is first.
- If the migration queues a `DataFixup`, find the file defining it, and any associated spec file. If the DataFixup is not reference by any other migration, just delete the spec file, the `DataFixup` file, and the migration file.
- `create_initial_partitions` calls can be squashed into the `CreateInitialPartitions` migration.
- Before making any modifications, reset the test database with `RAILS_ENV=test bin/rake db:test:reset`, and then store a copy of the structure to a temporary file for later validation: `pg_dump -s --restrict-key=MQTD3FxKJiJ5XiNN2cfyqy9ctUI0Tt9i3SWn8wZ7l2dYLJGctear9gqS1IRbdO5 canvas_test > original.sql`
- After making modifications, reset the test database again, dump it to a separate temporary file, and confirm that the structure has not changed by running `diff -u original.sql modified.sql`.
  The output should be empty.
  Exceptions are allowed if the order of columns has changed, because a column that was squashed is now earlier in the table than a column that is added in migration in gems/plugins/*/db/migrate/*.
- Finally, alter `ValidateMigrationIntegrity` by replacing the timestamp in `last_squashed_migration_version` with the value from the last deleted migration, and increment the version number in the filename.
- Be sure to run `script/rlint -a` afterwards to fix any formatting issues.

## Final Notes

Some users may run Canvas differently, so consider these useful default suggestions for
starting and interacting with Canvas if no other methods have been specified.
