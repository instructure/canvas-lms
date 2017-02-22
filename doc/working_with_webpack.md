# Webpack!

Canvas is almost done transitioning from require_js to webpack.  If
you'd like, you can help.  Canvas is currently equipped to run
with either frontend build to make the transition painless as possible.

The philosophy is simple.

Step 1) Make Webpack able to build the canvas app as it is today, warts and all,
while it can still run on the require_js build. This includes building and
sending assets to the CDN on deployment.

2) test the heck out of the webpack version until we're sure the world isn't
broken.  With parameter-enabled webpack js loading, this can be done in all
environments.

3) Start using webpack by default instead of require_js by default in all environments.

4) Leverage ES6, no AMD, etc in app code, and start deleting some of our crazy
webpack loaders that were built to deal with some of the require-js specific
hoops we ran into over the years.

### Where things are

In order to make webpack able to consume our currently-somewhat-disorganized build structure,
we've build a series of loaders and plugins for webpack that extend webpack to digest
canvas JS and Coffeescript as-it-stands.  These are all in the "frontend_build" folder, and
are commented where it's deemed helpful.

The base webpack configuration is also in that folder (baseWebpackConfig.js).  This is so
that our normal webpack.config.js file can use the config as is, and the configuration files
for test and production can simply extend to add or remove elements as necessary.

### Building javascript with webpack

If you look at package.json, you can see there are 2 scripts for building
your assets with webpack (webpack and webpack-production). If you want to include
the translations (eg when you run webpack-production), make sure you've
run "rake i18nliner:generate_js" first so translations are in place,
webpack depends on those already existing. You can use these scripts with "npm run":

`yarn run webpack`

This will build uncompressed js with eval'd sourcemaps, useful for development.
It also runs webpack with the "--watch" option so as you continue to
change things your updates will get compiled quickly.

`yarn run webpack-production`

This uglifies the resulting bundles, and takes longer.  Don't use for development.

Webpack's output goes to "public/dist/webpack-<dist or production>/".

### Using webpack javascript in canvas

The environment variable USE_WEBPACK is useful for trying out the assets
that webpack builds locally.  If set to 'true', when you start your server
you'll load JS from webpack rather than public/js.  You
can do the same thing by touching the file "config/WEBPACK" (if present, it's
like having the USE_WEBPACK env var set).

At any time you can use the url parameter "require_js=1" to get the requirejs
version of the js instead so you can compare them side by side.

While running _without_ USE_WEBACK set, you can use the url parameter "webpack=1"
to see webpack's js instead of the default requirejs loaded assets.

### Running js tests with webpack

Lets say you are working on the “dashboard_cards” feature, just run:
 `yarn run jspec-watch spec/javascripts/jsx/dashboard_card`
While you write code and it will have a watcher that catches
any changes and re-runs just the dashboard_card specs if you save any
file that went into it. It should run & reload in less than a few 
seconds. You can give it the path to a specific spec file or have it 
run an entire directory.

Or, if you are working on something that might touch a lot of stuff, run:
`yarn run test-watch`
and while you are changing stuff, it will run *all* the QUnit specs on
any change. It should only take a couple seconds for webpack to process
the file change and to reload the specs in the browser.

When karma starts, it automatically starts a webpack-dev-server and
webpacks whatever it needs to run the tests. see karma.conf.js for
more info on how it works.

To run all the tests, you can run:

`yarn test`

If you are using docker and want to run them all in a headless container you can 
do so with with:

`docker-compose run --rm js-tests`

which spools up the "js-tests" container specified in docker-compose.yml, which
has an entry point that knows how to kick off karma with a headless runner.

### Webpack Notifications

If you use macOS, you can setup system notifications for when the Webpack build
starts and ends so that you don't have to constantly watch the terminal for it.

To do so, add the following to your .bashrc or .zshrc:
```
export ENABLE_CANVAS_WEBPACK_HOOKS=1
source ~/canvas-lms/frontend_build/webpackHooks/macNotifications.sh
```

`macNotifications.sh` simply defines some shell variables that Webpack will use
to execute commands on specific hooks during the build process.

If you use Linux, or would like to setup your own custom Webpack notifications,
you can take a at how `macNotifications.sh` works and write your own hooks.

### FAQ!

*I got some errors that look like "Cannot resolve module", but the module is totally there. What gives?*
We do a lot of path rewriting to find things that are buried in extensible areas
in canvas.  If you're working with a plugin, look at frontend_build/CompiledReferencePlugin.js
for an example of how we look at some require statements and rewrite them to find
the right file; see if you can apply those ideas to your own loader if need be.

*Webpack says it can't find some "translations/" modules.  What should I do?*
Run `rake i18n:generate_js`.  Webpack doesn't know how to generate the
translations files yet, though we may tackle that in the future.  For now
that extract task needs to run before the first webpack build.  When in doubt,
just run `rake canvas:compile_assets` for a fully up to date build.

## TODO List (update as needed):

*TASK LIST*

[ ] convert the i18nliner task that extracts all the translations from source files to
be a babel loader so you can work against the same ast that babel already made and so
it can work against the es6 source and not the compiled output.

[X]  ensure strings are still checked/exported w/o errors, i.e. `rake i18n:check` (it shells out to node stuffs)

[X] load up canvas w/ optimized js and RAILS_LOAD_ALL_LOCALES=1, switch your locale and ensure you see translations

[ ] extract duplicated loader code from i18nLinerHandlebars and emberHandlebars

[ ] in a separate commit extract i18nLinerHandlebars loader function and what
it duplicates from prepare_hbs to a function both can use.

## After we're on webpack in production:

[ ] remove all the require-js build artifacts, re-write `compile_assets` to not build the require branch (still need to generate translations)

[ ] sweep for the `use_webpack` var and remove it

[ ] re-work js.rake to do away with requirejs stuff

[ ] un-amd all vendor dependencies that we've wrapped AMD wrappers around

[ ] re-write screenreader gradebook in not-ember

[ ] change all references to "compiled" to "coffeeescript" and then do away with that loader

[ ] delete our custom require-js plugins

[ ] kill the auto-css-in-handlebars imports (make them explicit) and remove that loader

[ ] plugins that need to be extended should have explicit extension points and let plugin register itself

[ ] audit all loaders to find dumb things we had to do for require

[ ] {low-priority} in chunks, take AMD requires off of our js files

[ ] Use Jest for future JS tests
