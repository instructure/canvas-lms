## App configuration

The framework mimics Rails in terms of configuration support. Your app(s) may define any number of parameters that can be configured at mount-time by the user. This is done using *environment* configuration scripts; those scripts cover production, development, test, and "local" development environments.

On a more "internal" grounds, third-party libraries used by the app can be configured in a streamlined manner using *initializers*.

### Environment-based configuration

```js
// @file /apps/foo/js/config/environments/production.js
define({
    quizUrl: undefined
});
```

Conveniently, when running in development, you can override the quiz's url to point to the one you're currently busy with:

```js
// @file /apps/foo/js/config/environments/development.js
define({
    quizUrl: '/api/v1/courses/1/quizzes/1'
});
```

Now, when the app is built, `config.quizUrl` will be `undefined`, whereas if you're running the app directly via the server, it will be `/api/v1/courses/1/quizzes/1`.

Taking it a step further, perhaps you don't want these changes to be tracked in SCM, probably because they're not helpful to others, or are really specific to your environment. In that case, you may define a new file called `development_local.js` which is *not* tracked in git, and will override any parameters defined in `production.js` and `development.js`.

### The `initializer` routine

This is also referred to as the "boot" routine, and is the primary entry point for your app (like `main` for C programs.) It's worth noting that the initializer is expected to be *asynchronous* and should return a `Promise` that fulfills when the app has booted up and is ready for usage. This is very handy for apps that need to load initial data on boot-up, or may take a while setting up.

Your initializer function must be defined in `/config/initializer.js`.

### 3rd-party (aka vendor) library configuration

Naturally, vendor libraries expose some configuration API, and it is likely that you'll want to tune a library in a specific way before using it in your app. Library initializers are made exactly for that reason.

You may define those initializers in `/config/initializers/[name_of_library].js` and require them in your initializer file (see the previous section.) Thanks to the initializer being asynchronous, the rest of the modules in your app are guaranteed that those vendor libraries are properly configured by the time they get to use them.

Example: configuring Backbone.js to use a custom AJAX implementation:

```js
// @file /config/initializers/backbone.js
define(function(require) {
    var Backbone = require('backbone');

    Backbone.ajax = function() {
        // ...
    };
});
```

And register it in the initializer script:

```js
// @file /config/initializer.js
define(function(require) {
    require('./initializers/backbone');

    return Promise.resolve();
});
```