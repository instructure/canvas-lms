ic-ajax
=======

Ember-friendly `jQuery.ajax` wrapper.

- returns RSVP promises
- makes apps more testable (resolves promises with `Ember.run`)
- makes testing ajax simpler with fixture support

Installation
------------

`bower install ic-ajax`

`npm install ic-ajax`

... or download `main.js` and include it into your app however you want.

Module Support
--------------

- AMD

  `define(['bower_components/ic-ajax'], function(ajax) {});`

- Node.JS (CJS)

  `var ajax = require('ic-ajax')`

- Globals

  `var ajax = ic.ajax;`

  All instructure canvas stuff lives on the `ic` global.

API
---

Ajax simply wraps `jQuery.ajax` with two exceptions:

- success and error callbacks are not supported
- does not resolve three arguments like $.ajax (real promises only
  resolve a single value). `ic.ajax` only resolves the response data
  from the request, while ic.ajax.raw resolves an object with the three
  "arguments" as keys if you need them.

Other than that, use it exactly like `$.ajax`.

```js
var ajax = ic.ajax;
App.ApplicationRoute = Ember.Route.extend({
  model: function() {
    return ajax('/foo');
  }
}

// if you need access to the jqXHR or textStatus, use raw
ajax.raw('/foo').then(function(result) {
  // result.response
  // result.textStatus
  // result.jqXHR
});
```

Simplified Testing
------------------

Adding fixtures with `defineFixture` tells ic-ajax to resolve the promise
with the fixture matching a url instead of making a request. This allows
you to test your app without creating fake servers with sinon, etc.

Example:

```js
ic.ajax.defineFixture('api/v1/courses', {
  response: [{name: 'basket weaving'}],
  jqXHR: {},
  textStatus: 'success'
});

ic.ajax('api/v1/courses').then(function(result) {
  deepEqual(result, ic.ajax.lookupFixture('api/v1/courses').response);
});
```

Contributing
------------

Install dependencies and run tests with the following:

```sh
bower install
npm install
npm test
```

Special Thanks
--------------

Inspired by [discourse ajax][1].

License and Copyright
---------------------

MIT Style license

(c) 2013 Instructure, Inc.


  [1]:https://github.com/discourse/discourse/blob/master/app/assets/javascripts/discourse/mixins/ajax.js#L19

