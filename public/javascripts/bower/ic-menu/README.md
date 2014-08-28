ic-menu [![Build Status](https://travis-ci.org/instructure/ic-menu.svg)](https://travis-ci.org/instructure/ic-menu)
=======

An accessible menu component for ember applications.

Demo
----

http://instructure.github.io/ic-menu/

Installation
------------

`bower install ic-menu`

Usage
-----

__application.hbs__

```handlebars
{{#ic-menu}}
  {{#ic-menu-trigger}}Actions{{/ic-menu-trigger}}
  {{#ic-menu-list}}
    {{#ic-menu-item on-select="remove"}}Remove{{/ic-menu-item}}
    {{#ic-menu-item on-select="save"
                    on-disabled-select="notifyDisabled"
                    disabled=foo}}
      Save
    {{/ic-menu-item}}
  {{/ic-menu-list}}
{{/ic-menu}}
```

__application_controller.js__

```js
App.ApplicationController = Ember.Controller.extend({

  actions: {
    remove: function(icMenuItem) {
      // do stuff with the icMenuItem instance
    },
    save: function(icMenuItem) {
      // do stuff with the icMenuItem instance
    }
  }

});
```

Development
-----------

1. Fork the repo
2. `npm install && bower install`
3. Create a new branch for your feature/bug fix
4. `grunt` to build and watch files.
5. `testem` in a new tab to run tests.
6. Send a pull request.

