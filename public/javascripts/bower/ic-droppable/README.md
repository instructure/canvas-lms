ic-droppable
============

Ember component mixin that wraps native drop events.

Demo
----

https://instructure.github.io/ic-droppable

Installation
------------

`bower install ic-droppable`

`npm install ic-droppable`

... or download one of the distributions in `dist` and include however
you want.

Module Support
--------------

- AMD

  `define(['ic-droppable'], function(Droppable) {});`

- CJS

  `var Droppable = require('ic-styled')`

- Globals

  `var Droppable = ic.Droppable.default`

Usage
-----

```js
var Droppable = ic.Droppable.default;

// first mix Droppable into a component
App.XDropComponent = Ember.Component.extend(Droppable, {

  tagName: 'x-drop',

  // Next define a validateDragEvent method, native draggables have
  // data types that you can read while the drag is moving over your
  // component.

  validateDragEvent: function(event) {
    return event.dataTransfer.types.contains('text/x-drag');
  },

  // Finally, define an acceptDrop method to do whatever you need to
  // do when the user drops on your component.

  acceptDrop: function(event) {
    var data = event.dataTransfer.getData('text/x-drag');
    alert(data);
  }
});

// And just for demonstration, here's a simple draggable element.

App.XDragComponent = Ember.Component.extend({
  attributeBindings: ['draggable']
  draggable: true,
  setEventData: function(event) {
    event.dataTransfer.setData('text/x-drag', this.get('elementId'));
  }.on('dragStart')
});
```

```css
/*
  when a valid drag event is over your component
*/

x-drop.accepts-drag {
  background-color: green;
}

/*
  when the component is dragging over itself, and it is a valid drop
  target (the case with sortables sometimes)
*/

x-drop.self-drop {
  background-color: red;
}
```

And a simple template:

```handlebars
{{x-drag}}Drag me{{x-drag}}
{{x-drop}}Drop here{{/x-drop}}
```

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

(c) 2014 Instructure, Inc.

