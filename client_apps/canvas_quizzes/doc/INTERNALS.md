## How the app configuration works

- Based on whether we're in a build, or running the app, `requirejs` is configured with a mapping that points `app/` to the path of the current running app. This map is scoped to `src/js/config.js` because it's the only file that needs it.
- Developer creates environment-specific config files at `/apps/[APP]/js/config/environments/[ENV].js`
- An app's `config.js` found at `/apps/[APP/js/config.js` delegates to the core `src/js/config.js` to do the actual config loading
- Core's config script attempts to load the _app's_ environment config using the pre-configured `app/` r.js map. For example, if the current running app is called `statistics`:
    + it attempts to load `/apps/statistics/js/config/environments/production.js` and uses that as a basis config hash
    + if we're running in development mode, it tries to load a `development.js` file, as well as a `development_local.js` file:
        * if none of these were found, it emits a warning to the developer to inform them that they can, and should, make use of these environment configurators

At build time, we cover two possible scenarios:

1. We're building the core bundle, so there's no "current app" to configure, and as such, those config files are flagged to be loaded later using the special r.js `:empty` path value.
2. We're building an app bundle, so we define a `map` entry that points `app/` to the path of the current app, like `/apps/statistics/js` **which will be included in the runtime loader config**.
