color-slicer
=======

Generate lists of readable text colors, starting at a given hue and
dividing the hue space into progressively smaller increments.

Installation
------------

`bower install color-slicer`

Or just download [dist/color-slicer.js](https://raw.github.com/instructure/color-slicer/master/dist/color-slicer.js).

Usage
-----

```
var colorSlicer = require('color-slicer');
var count = myObjects.length;
var startHue = 180;
var colors = colorSlicer.getColors(count, startHue);
```

See [dist/example.html](https://github.com/instructure/color-slicer/blob/master/dist/example.html).

Development
-----------

1. Fork the repo
2. `npm install`
3. Create a new branch for your feature/bug fix
4. `grunt` to build and watch files.
5. `grunt test` to run tests.
6. Send a pull request.

