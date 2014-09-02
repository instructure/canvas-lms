ic-styled
=========

Automatically style components with css templates.

Installation
------------

`bower install ic-styled`

`npm install ic-styled`

... or download `main.js` and include it into your app however you want.

Module Support
--------------

ic-styled doesn't export anything, it just adds functionality to
`Ember.Component`. If using a module system, require it somewhere in the
root of your application somewhere (like `application.js`).

- AMD

  `define(['ic-styled'], function() {});`

- CJS

  `require('ic-styled')`

Usage
-----

Given a component named `x-foo`, create an additional component template
at `components/x-foo-css`, treat it like a css file. The css will be
imported into your app automatically on the first instance of `x-foo`.

Sounds tricky but its not; here's a sample app:

```html
<script type="text/x-handlebars">
  <h1>Application Template using x-foo</h1>
  {{x-foo}}
</script>

<script type="text/x-handlebars" id="components/x-foo">
  I am x-foo, the main component.
</script>

<script type="text/x-handlebars" id="components/x-foo-css">
  /* I am x-foo-css, the styles that go with x-foo */
  x-foo { color: red; font-weight: bold; }
</script>

<script>
  var App = Ember.Application.create();
  App.XFooComponent = Ember.Component.extend({
    tagName: 'x-foo'
  });
</script>
```

At the first render of `{{x-foo}}` the `{{x-foo-css}}` template is
imported into the app to style `x-foo` elements.

Overriding Component Styles
---------------------------

`Styled` injects the css template to the top of the `<head>` element so
its the first-ish css to be applied. This means that you can override
the CSS of styled components the same as any native element since your
app's CSS will be applied after.

Vim Config
----------

If you use vim, add this to your `vimrc` to get css highlighting for
these templates:

`au BufNewFile,BufRead *-css.hbs set filetype=css`

Use Tags to Style
-----------------

I know, its been hammered into our brains not to use tagNames when
writing CSS. But, when you build a component, you are creating a new
custom element; you should mimick native elements as much as possible.
Therefore, style it by tagName so everybody consuming your component can
override styles the same way they override a `<button>`.

About the Implementation
------------------------

A lot of questions come up, hopefully this answers them:

- all styles are injected into a shared `<style>` tag to avoid the IE
  issue of only allowing 31 style/link tags
- this style tag is at the top of the `<head>` so application CSS can
  override the same way they override native element css
- styles for a component definition are only injected once, even if the
  component is used several times
- a comment is inserted so you can see which component injected the css

Contributing
------------

```sh
bower install
npm install
npm test
```

License and Copyright
---------------------

MIT Style license

(c) 2013 Instructure, Inc.

