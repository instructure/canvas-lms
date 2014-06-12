ic-modal
========

[![Build Status](https://travis-ci.org/instructure/ic-modal.png?branch=master)](https://travis-ci.org/instructure/ic-modal)

[WAI-ARIA][wai-aria] accessible modal dialog component for [Ember.js][ember].

Demo
----

http://instructure.github.io/ic-modal

Installation
------------

```sh
$ npm install ic-modal
```

or ...

```sh
$ bower install ic-modal
```

or just grab your preferred distribution from `dist/`.

Then include the script(s) into your application:

### npm+browserify

`require('ic-modal')`

### amd

Register `ic-modal` as a [package][rjspackage], then:

`define(['ic-modal'], ...)`

### named-amd

You ought to know what you're doing if this is the case.

### globals

`<script src="bower_components/ic-styled/main.js"></script>`
`<script src="bower_components/ic-modal/dist/globals/main.js"></script>`

{{ic-modal}} Usage
------------------

In its simplest form:

```html
{{#ic-modal-trigger controls="ohai"}}
  open the modal
{{/ic-modal-trigger}}

{{#ic-modal id="ohai"}}
  Ohai!
{{/ic-modal}}
```

Here are all the bells and whistles:

```html
<!--
  Triggers can live anywhere in your template, just give them the id of
  the modal they control, you can even have multiple triggers for the
  same modal.
-->

{{#ic-modal-trigger controls="tacos"}}
  abrir los tacos
{{/ic-modal-trigger}}

<!--
  The "closed-when" attribute can be bound to a controller property. If
  `tacosOrdered` gets set to `true` then the modal will close.

  "open-when" is the same, but opposite.
-->

{{#ic-modal id="tacos" closed-when=tacosOrdered}}

  <!--
    This is optional, but you really should provide your own title,
    it gets used in the UI and is important for screenreaders to tell the
    user what modal they are in. If you hate it, write some CSS to hide
    it.
  -->

  {{#ic-modal-title}}Tacos{{/ic-modal-title}}

  <!--
    If a trigger lives inside a modal it doesn't need a "controls"
    attribute, it'll just know.

    If you don't provide a trigger inside the modal, you'll get one
    automatically, but if you're translating, you're going to want your
    own.

    Put the text to be read to screenreaders in an "aria-label" attribute
  -->

  {{#ic-modal-trigger aria-label="Cerrar los tacos"}}×{{/ic-modal-trigger}}

  <!-- Finally, just provide some content -->

  <p>
    ¡Los tacos!
  </p>
{{/ic-modal}}
```

{{ic-modal-form}} Usage
-----------------------

One of the most common use-cases for a modal dialog is a form.

```html
<!-- we still use ic-modal-trigger -->
{{#ic-modal-trigger controls="new-user-form"}}
  open
{{/ic-modal-trigger}}

<!-- note this is ic-modal-form -->
{{#ic-modal-form
  id="new-user-form"

  <!--
    map the component's "on-submit" to controller's "submitForm",
    the component handles the submit for you
   -->
  on-submit="submitForm"

  <!--
    if the form is closed w/o being submit, maybe you need to restore
    the old properties of a model, etc.
  -->
  on-cancel="restoreModel"

  <!-- same thing as above -->
  on-invalid-close="handleCloseWhileSaving"

  <!--
    bind component's "awaiting-return-value" to local "saving",
    more on this in the js section
  -->
  awaiting-return-value=saving

}}

  <!-- in here you are already a form, just add your form elements -->

  <fieldset>
    <label for="name">Name</label>
    {{input id="name" value=newUser.name}}
  </fieldset>

  <!-- and put your buttons in the footer -->

  <fieldset>
    <!-- when "awaiting-return-value" is true, "saving" will be also -->
    {{#if saving}}
      saving ...
    {{else}}
      {{#ic-modal-trigger}}Cancel{{/ic-modal-trigger}}
      <button type="submit">Save</button>
    {{/if}}
  </fieldset>

{{/ic-modal-form}}
```

```js
App.ApplicationController = Ember.Controller.extend({

  newUser: {},

  actions: {

    // this will be called when the user submits the form because we
    // mapped it to the "on-submit" actions of the component
    submitForm: function(modal, event) {

      // If you set the event.returnValue to a promise, ic-modal-form
      // will set its 'awaiting-return-value' to true, that's why our
      // `{{#if saving}}` in the template works. You also get an
      // attribute on the component to style it differently, see the css
      // section about that. You don't need to set the `event.returnValue`.
      event.returnValue = ic.ajax.request(newUserUrl).then(function(json) {
        addUser(json);
        this.set('newUser', {});
      }.bind(this));
    },

    // if the user tries to close the component while the
    // `event.returnValue` is stil resolving, this event is sent.
    handleCloseWhileSaving: function(modal) {
      alert("Hold your horses, we're still saving stuff");
    },

    restoreModel: function(modal) {
      this.get('model').setProperties(this.get('modelPropsBeforeEdit'));
    }
  }
});
```

```css
// while the promise is resolving, you can style the elements
#new-user-form[awaiting-return-value] ic-modal-main {
  opacity: 0.5;
}
```

CSS
---

### Overriding styles

This component ships with some CSS to be usable out-of-the-box, but the
design has been kept pretty minimal. See `templates/modal-css.hbs` to
know what to override for your own design.

### Animations

There is a class "hook" provided to create animations when the a modal
is opened, `after-open`. For example, you could add this CSS to your
stylesheet to create a fade-in effect:

```css
ic-modal[is-open] {
  opacity: 0;
  transition: opacity 150ms ease;
}

ic-modal[after-open] {
  opacity: 1;
}
```

Contributing
------------

```sh
$ git clone <this repo>
$ npm install
$ npm test
# during dev
$ broccoli serve
# localhost:4200/globals/main.js instead of dist/globals/main.js
# new tab
$ karma start
```

Make a new branch, send a pull request, squashing commits into one
change is preferred.

  [rjspackage]:http://requirejs.org/docs/api.html#packages
  [ember]:http://emberjs.com
  [wai-aria]:http://www.w3.org/TR/wai-aria/roles#dialog

