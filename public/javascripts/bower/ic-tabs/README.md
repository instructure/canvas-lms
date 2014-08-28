ic-tabs
=======

[![Build Status](https://travis-ci.org/instructure/ic-tabs.png?branch=master)](https://travis-ci.org/instructure/ic-tabs)

[WAI-ARIA][wai-aria] accessible tab component for [Ember.js][ember].

Demo
----

http://instructure.github.io/ic-tabs

Installation
------------

```sh
$ npm install ic-tabs
```

or ...

```sh
$ bower install ic-tabs
```

or just grab your preferred distribution from `dist/`.

Then include the script(s) into your application:

### npm+browserify

`require('ic-tabs')`

### amd

Register `ic-tabs` as a [package][rjspackage], then:

`define(['ic-tabs'], ...)`

### named-amd

You ought to know what you're doing if this is the case.

### globals

`<script src="bower_components/ic-tabs/dist/globals/main.js"></script>`

Usage
-----

```handlebars
{{#ic-tabs}}
  {{#ic-tab-list}}
    {{#ic-tab}}Foo{{/ic-tab}}
    {{#ic-tab}}Bar{{/ic-tab}}
    {{#ic-tab}}Baz{{/ic-tab}}
  {{/ic-tab-list}}

  {{#ic-tab-panel}}
    <h2>Foo</h2>
  {{/ic-tab-panel}}

  {{#ic-tab-panel}}
    <h2>Bar</h2>
  {{/ic-tab-panel}}

  {{#ic-tab-panel}}
    <h2>Baz</h2>
  {{/ic-tab-panel}}
{{/ic-tabs}}
```

- associations between tabs and tab-panes are inferred by order.
- `ic-tab-list` must be an immediate child of `ic-tabs`
- `ic-tab` must be an immediate child of `ic-tab-list`
- `ic-tab-panel` must be an immediate child of `ic-tabs`

Options
-------

- `{{ic-tab selected-index=prop}}` - binds the active-index to prop,
  mostly useful for `queryParams`.

Contributing
------------

```sh
$ git clone <this repo>
$ npm install
$ npm test
# during dev
$ broccoli serve
# edit examples/ files and karma.conf to point to
# localhost:4200/globals/main.js instead of dist/globals/main.js
# new tab
$ karma start
```

Make a new branch, send a pull request, squashing commits into one
change is preferred.



  [rjspackage]:http://requirejs.org/docs/api.html#packages
  [ember]:http://emberjs.com
  [wai-aria]:http://www.w3.org/TR/wai-aria/roles#tab

