# Webpack!

Canvas is in the midst of transitioning from require_js to webpack.  If
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
your assets with webpack (webpack and webpack-production). Make sure you've
run "rake canvas:compile_assets" first so translations are in place,
webpack depends on those already existing. You can use these scripts with "npm run":

`npm run webpack`

This will build uncompressed js with eval'd sourcemaps, useful for development.
It also runs webpack with the "--watch" option so as you continue to
change things your updates will get compiled quickly.

`npm run webpack-production`

This uglifies the resulting bundles, and takes longer.  Don't use for development.

Webpack's output goes to "public/webpack-dist" for development js and
"public/webpack-dist-optimized" for minified production js.

### Using webpack javascript in canvas

The environment variable USE_WEBPACK is useful for trying out the assets
that webpack builds locally.  If set to 'true', when you start your server
you'll load JS from your webpack-dist directory rather than public/js.  You
can do the same thing by touching the file "config/WEBPACK" (if present, it's
like having the USE_WEBPACK env var set).

At any time you can use the url parameter "require_js=1" to get the requirejs
version of the js instead so you can compare them side by side.

While running _without_ USE_WEBACK set, you can use the url parameter "webpack=1"
to see webpack's js instead of the default requirejs loaded assets.

### Running js tests with webpack

We have built a seperate configuration for building one big test bundle
(webpack.test.config.js) which extends the default development config.
It builds the test bundle into spec/javascripts/webpack, and can be run
with the npm script "webpack-test".

karma.conf.js has been adjusted to look for that bundle for testing instead
when the USE_WEBPACK environment variable is set.

Which specs are included are right now configured manually in
"spec/javascripts/webpack_spec_index.js".

To build the test bundle, you can run:

`npm run webpack-test`

Once you have the test bundle built, karma should work normally.  I prefer
to run it headless in a container, so I run it with:

`docker-compose run --rm js-tests`

which spools up the "js-tests" container specified in docker-compose.yml, which
has an entry point that knows how to kick off karma with a headless runner.

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
[X] setup context for quiz_submission_events.coffee so it doesn't have to
include the whole freaking bundles directory (fixed by removing errback)

[X] Make sure all bundles in app/coffeescripts/bundles (at least The
  ones that actually get used) compile ok

[X] use loader to replace "worker" RequireJs
plugin

[X] loading partials from handlebars need to result
in partials registration

[X] loading bracketed partials in handlebars templates
must result in partials registration

[X] unbracketed nested partials need registration

[X] all handlebars helpers known to handlebars helper
should be counted as knownHelpers;

[X] all handlebars files need a dependency on
handlebars helpers

[X] make sure this works on node 0.12

[X] Bundles defined in plugins
like analytics must be
compiled into entries.  Right
now we're specifying them all,
but we'll need to sniff for plugin
directories and find bundles
to add to the entry point list
(and to resolver paths).
No more symlinks.

[X] make sure we can still load
canvas_quizzes from core bundles.
Building client_apps will need
to be a pre-build task (js:build_client_apps).

[X] JSTs living in a plugin
like analytics or instructure_misc_plugin
must be available.  Instead
of symlinks, this probably
means finding plugin directories
at runtime for webpack
and adding them as paths to the
config for resolving.

[X] split up webpack build to avoid memory limitation

[X] remove public/javascript/jsx
and start requiring jsx files
directly from their app/jsx
directory

[X] load JSX with a jsx webpack loader (babel).

[X] split vendor modules from app modules to reduce
build time and require it everywhere.

[X] Load jquery into an AMD friendly module (will need some kind of shim)

[X] Load i18n into a module (it doesn't export itself)

[X] Make sure backbone is required all the places it's revealed

[X] use common bundle to extract modules common
to many dependencies and require that first
in all environments.

[X] Change js_bundle helper to use webpack
bundles

[X] configure webpack to pick up chunks from bundle entry points in the right
folder (webpack-dist for now)

[X]  Make sure this works
with the docker workflow

[X] Make sure _core_en_ translations are loaded before we start doing lookups (probably
  in the loader)

[X] Sort out tinymce PluginManager loading (pluginManager is coming up undefined)
(and how to munge together tinymce plugin dependencies which expect a global library
  and exposed submodules).

[X] fix HandlebarsHelper which can't find "registerHelper" as a function (probably loading wrong handlebars?)
(actually, was due to exports loader not being correctly applied)

[X] Timezone Loading is failing from the timezone plugin because the "load" function isn't defined
(needed to switch to using a return object, "load" was part of requirejs plugins)

[X] Solve module resolution error in ./app/coffeescripts/bundles/grade_question.coffee
(was a missing bundle, need to start sniffing for which bundles are actually in the
  directory soon)

[X] test in development and
make sure we have source to
debug with

[X] Ask jon to show me how
i18nliner works in finding
translation keys and whether we
can perform it on source
files rather than
mid-compilation.  If so,
than generating translations
would be a pre-build task.

[X] precompile handlebars templates through
i18nliner

[X] make sure backbone.js can load jquery off of window

[X] make i18nliner use a sync loader because async
    is causing it to hang (false, all handlebars loads are completeing, checked
      through log-grepping).  Now figure out why we're hanging at the emit stage...
      Ah, it's because the spawned processes are living forever.  Add a "kill" to
      each callback on completion so


[X] use canvas i18nliner instead of raw i18nliner

[X] make sure plugin i18n scopes run through i18nliner get
pickedup ok

[X] Too many processes being spawned by piping.  Better do i18nliner transform
in process

[X] in the "Permissions" screen under accounts (and announcements & assignments under course),
    View.coffee says "this.template is not a function"

[X] in "Discussions", discussions_topics_index.coffee says "Backbone is not defined"
(it was requiring only the "Router" attribute of backbone, but then referencing
Backbone globally)

[X] in the "Outcomes" nav item under accounts, learning_outcomes.coffee says "browserTemplate is not a function"

[X] on "Assignments" page for a course, "Uncaught TypeError: tz.parse is not a function"
by jquery.instructure_date_and_time (was using "require" instead of "define" in
timezone_plugin, require doesn't actually return a new module)

[X] when trying to create an announcment, "Uncaught TypeError: Cannot read property 'MS_TO_DEBOUNCE_SEARCH' of undefined" is thrown by DueDateTokenWrapper.jsx
("this" was actually undefined when they were using it outside of a function definition
in a class constructor)

[X]  ensure strings are still checked/exported w/o errors, i.e. `rake i18n:check` (it shells out to node stuffs)

[X] load up canvas w/ optimized js and RAILS_LOAD_ALL_LOCALES=1, switch your locale and ensure you see translations

[X] When loading a JST (probably a piped loader) will need to handle css registration

[X] Handle in-line partial registration when precompiling handlebars

[X] handle partial requirements from templates that depend on them

[X] When creating a new assignment, "Uncaught Error: The partial jst/assignments/_ submission_types_form could not be found"

[X] Talk with ryan about CDN
generation in the dist to make
sure that can be exported
on command.

[X] make sure webpack --watch
can deal with live changes in
development cycle

[X] upon requiring a module with extensions present (like plugins), make sure it loads the extensions (probably need to build a list of extensions up front from file system and check each require for it)

[X] When loading an ember JST
(hbs file), precompile through
i18nliner. (only can be tested in screenreader_gradebook)

[X] Make screenreader gradebook work

[X] test an ember app part of the site and make sure that still works

[X] Creating a quiz doesn't reference handlebars correctly

[X] assignments index, icons are missing, they don't know that scripts are loaded

[X] add ability to compress
outgoing builds.

[X] Make sure we can still use "with optimized js" environment variable for
local testing with prod-packaged code

[X] Replace or augment build steps in "rake canvas:compile_assets" pipeline with
webpack run based on USE_WEBPACK environment variable

[X] Build out the process that will probably work for getting code onto the CDN

[X] make "webpack-dist" rev-able and included in the CDN upload.

[X] make translations run before webpack if they aren't there

[X] Add basic docs.

[X] Make overriding webpack for requirejs (or vice versa) easy from a param
for testing

[X] make client-side
qunit tests work via webpack

[X] build a headless test runner, both for docker users and to avoid
that stupid browser window that tends to cache too much state.

[X] Discussion CSS seems slightly broken, apparently nested templates don't get parsed
correctly in i18nliner loader because of the differing root paths

[X]for screenreader_gradebook,
we could find files in
app/coffeescripts/ember/screenreader_gradebook and build
an entrypoint with a webpack plugin
that does all the work that
EmberBundle does now, but
it seems like an abstraction for one app.  Since we aren't planning on
making any _more_ Ember
apps inside canvas (and Since
we probably want to kill this one), I say we make the generated "main.coffee" and
bundle files permenant and
committed to the git repo, and
yank EmberBundle out entirely.

[X] Extract an actual commons chunk

[X]what app code changes there are, move them out into seperate
small commits that can be tested individually

[X] in a seperate commit, remove all the shared ember components that aren't
used from "app/coffeescripts/ember/shared/components"

[X] get _all_ qunit tests running in the webpack bundle (just spiked on a few)

[X] on building for production, fails with ProximityLoader ("ERROR in 232.bundle.js from UglifyJs
Unexpected token: operator (!) [./frontend_build/jsHandlebarsHelpers.js!./frontend_build/pluginsJstLoader.js!./frontend_build/nonAmdLoader.js!./app/coffeescripts/util/ProximityLoader.coffee:111,6]")

[X] Migrate requires that are in views to application js (check plugins like mra)


[X] Delay returning tz in "timezone_plugin.js" until after promises have been run,
or change how the rest of the app interacts with timezone_plugin so that we can
return a promise, since async return is just not going to happen, and we need to have
those promises done before using it.

[ ] sort out scopes for .app.app.coffeescripts.ember.shared.templates.components.ic_submission-download-dialog so that we don't need an awful exception in 18n.js

[X] sniff test files automatically rather than configuring them manually in webpack_spec_index.js

[ ] could get a nice performance boost out of reimplementing BrandableCSS.all_fingerprints_for(bundle)
in node rather than shelling out to ruby for it

[ ] extract duplicated loader code from i18nLinerHandlebars and emberHandlebars

[ ] in a seperate commit extract i18nLinerHandlebars loader function and what
it duplicates from prepare_hbs to a function both can use.

## After we're on webpack in production:

[ ] remove all the require-js build artifacts, re-write `compile_assets` to not build the require branch (still need to generate translations)

[ ] sweep for the `use_webpack` var and remove it

[ ] re-work js.rake to do away with requirejs stuff

[ ] un-amd all vendor dependencies that we've wrapped AMD wrappers around

[ ] re-write screenreader gradebook in not-ember

[ ] change all references to "compiled" to "coffeeescript" and then do away with that loader

[ ] delete our custom require-js plugins

[ ] migrate anything in bower to npm, dump bower

[ ] find other hard-coded vendor libs that can be ported to npm

[ ] rewrite qunit specs to actually have a qunit dependency and ditch that regex loader

[ ] kill the auto-css-in-handlebars imports (make them explicit) and remove that loader

[ ] plugins that need to be extended should have explicit extension points and let plugin register itself

[ ] audit all loaders to find dumb things we had to do for require

[ ] {low-priority} in chunks, take AMD requires off of our js files

[ ] {low-priority} re-write tests in mocha
