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

## Final Notes

Some users may run Canvas differently, so consider these useful default suggestions for
starting and interacting with Canvas if no other methods have been specified.
