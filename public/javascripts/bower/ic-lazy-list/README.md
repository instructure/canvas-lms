ic-lazy-list
============

Lazily loads records from an href as the user scrolls down the page, all
in your template.

Installation
------------

`npm install ic-lazy-list`

... or ...

`bower install ic-lazy-list`

... or just include `dist/main.js` into your app however you want.

Module Support
--------------

- AMD

  `define(['ic-lazy-list'], function() {});`

- Node.JS (CJS)

  `require('ic-lazy-list')`

- Globals

  `ic.LazyListComponent;`

  All instructure canvas stuff lives on the `ic` global.


Usage
-----

Once you've required ic-lazy-list into your application, you can use it
in your templates.

```handlebars
{{#ic-lazy-list
  href="http://addressbook-api.herokuapp.com/contacts"
  data-key="contacts"
  data=contacts
}}

  <ul>
  {{#each contacts}}
    <li style="height: 500px">{{first}} {{last}}</li>
  {{/each}}
  </ul>

{{/ic-lazy-list}}
```

- `href` - the url to load
- `data-key` - optional, the key in the response your data lives on
- `data` - data-binding, when the data loads it will be bound to
  whatever you map it to

Contributing
------------

After cloning this repo, install dependencies:

```sh
$ npm install
$ bower install
```

Fire up the grunt watcher:

```sh
$ grunt
```

Then in a different tab run the tests with testem:

```sh
$ testem
```

