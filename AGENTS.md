# AGENTS.md

AI coding assistant guidance for Canvas LMS.

## Quick Start

```bash
docker-compose up                    # Start services
dc run --rm web bash                 # Dev shell
yarn build:watch                     # Frontend dev mode
```

## Essential Commands

| Task | Command |
|------|---------|
| **Build** | `yarn build` (all), `yarn build:watch` (dev) |
| **Test JS** | `yarn test`, `yarn test:vitest`, `yarn test:watch` |
| **Test Ruby** | `bundle exec rspec` |
| **Lint** | `yarn lint` (JS), `bundle exec rubocop` (Ruby), `yarn check:biome` |
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

- Update packages: Edit package.json, run `docker_yarn` function
- Access Rails console: `dc run --rm web rails c`
- Database operations run inside containers

## Testing Docs

- JS testing guide: `doc/ui/testing_javascript.md`
- Run specific tests: `yarn test path/to/test`
- Coverage: `yarn test:coverage`
