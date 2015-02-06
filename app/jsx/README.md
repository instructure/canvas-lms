This directory is temporary until we rework the front-end build [This is
where we are headed][1].

Stuff you can do in Canvas JSX files
====================================

BUT WAIT!
---------

Your file needs to:

1. Have a file name with the `.jsx` extension.
2. Start with `/** @jsx React.DOM */`

JSX
---

```js
function foo(paths) {
  return <svg>{paths}</svg>;
}
```

Arrow Functions
---------------

[Arrow Function Reference][arrows]

```js
var arr = ['hydrogen', 'helium', 'lithium'];

// es5
var a = arr.map(function(s){ return s.length });

// es6
var b = arr.map( s => s.length );

// with curlies requires normal return
var b = arr.map( (s) => {
  return s.length
});

// lexical `this`
var obj = {
  multiplier: 3,
  
  multiplyStuff (stuff) {
    return stuff.map((x) =>
      // no bind!
      return this.multiplier * x;
    )
  }
};
```

Classes
-------

[Class Reference][class]


```
class EventEmitter {
  constructor() {
    // called when created
  }
  emit() {
    // ...
  }
  on() {
    // ...
  }
  once() {
    // ...
  }
  removeListener() {
    // ...
  }
  removeAllListeners() {
    // ...
  }
}
```

Extending and calling `super`.

```js
class Domain extends EventEmitter {
  constructor() {
    super();
    this.members = [];
  }
}
```

Creating instances

```js
var domain = new Domain();
```

Destructuring
-------------

```js
// es5
var map = _.map;
var each = _.each;

// es6
var {map, each} = _;
```

Concise Object Methods
----------------------

```js
// es5
var obj = {
  foo: function() {}
  bar: function() {}
};

// es6
var obj = {
  foo() {}
  bar() {}
};
```

Object Short Notation
---------------------

```js
// es5
function() {
  // ...
  return {foo: foo, bar: bar, x: 10};
}

// es6
function() {
  // ...
  return {foo, bar, x: 10};
}
```

Rest Parameters
---------------

[Rest Parameters Reference][rest]

```
// es5
function multiply(multiplier) {
  var numbers = Array.prototype.slice.call(arguments, 0);
  return number.map(function(n) { return multiplier * n; });
}

// es6
function multiply(multiplier, ...numbers) {
  return numbers.map( n => multiplier * n);
}
```

String Templates
----------------

[String Template Reference][templates]

Multiline strings:

```js
// es5
console.log("string text line 1" +
"string text line 2");

// es6
console.log(`string text line 1
string text line 2`);
```

Interpolated strings

```js
var a = 5;
var b = 10;

// es5
console.log("Fifteen is " + (a + b) + " and not " + (2 * a + b) + ".");

// es6
console.log(`Fifteen is ${a + b} and not ${2 * a + b}.`);
```


  [1]:https://github.com/instructure-wfx/RFCs/blob/master/active/canvas-js-structure-build.md 
  [arrows]:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Functions/Arrow_functions
  [class]:http://tc39wiki.calculist.org/es6/classes/
  [rest]:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Functions/rest_parameters
  [templates]:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/template_strings

