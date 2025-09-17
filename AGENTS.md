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

## Final Notes

Some users may run Canvas differently, so consider these useful default suggestions for
starting and interacting with Canvas if no other methods have been specified.
