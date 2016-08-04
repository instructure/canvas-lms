# Testing JavaScript

The process of testing JavaScript sometimes confuses people. This document's goal
is to alleviate that confusion and establish how to run JavaScript tests.

## With Docker and Webpack

This is becoming the go to standard for running Canvas and compiling your not-JavaScript
(CoffeeScript, JSX, Handlebars, etc.) code into JavaScript code.  You should likely
be following this path when doing front-end development on Canvas.  If you need help
getting started with that please see [development_with_docker.md](https://github.com/instructure/canvas-lms/blob/master/doc/development_with_docker.md)
and [working_with_webpack.md](https://github.com/instructure/canvas-lms/blob/master/doc/working_with_webpack.md).

Before we can get started in earnest, we need to make a few changes to a couple of files.
Inside `docker-compose.yml` you should see an entry for `phantomjs-tests`.  You should
uncomment it so we can use it. It is the container we will use because of its awesome
flexibility even if we aren't planning to run tests using PhantomJS.

The next file to be aware of is `webpack_spec_index.js`.  This file is how the test bundle
gets created.  We can modify it to limit what tests get run.  For instance, if you don't
want to run any of the CoffeeScript tests, just comment out that portion of the file.
If you want to scope tests to a certain folder, adjust the path to that folder so that

```
var jsxTestsContext = require.context(__dirname + "/jsx", true, /Spec$/);

requireAll(jsxTestsContext);
```

becomes

```
var jsxTestsContext = require.context(__dirname + "/jsx/theFolderIWanted", true, /Spec$/);

requireAll(jsxTestsContext);
```

If you want to scope it to a single file adjust the RegEx as needed so it might look
something like this:

```
var jsxTestsContext = require.context(__dirname + "/jsx", true, /MyCoolComponentSpec$/);

requireAll(jsxTestsContext);
```

Now that we have all the files we needed prepared we are going to do two things:

1) `docker-compose run --rm web npm run webpack-test-watch`
   This will get webpack building the test bundle in watch mode, making it so your
   changes are instantly (or close to instantly) reflected in the test bundle.
2) `docker-compose run --rm phantomjs-tests`
   This will start the PhantomJS container in watch mode running the test bundle
   anytime the test bundle gets updated.

So you'll now see PhantomJS almost instantly complete the test suite for you.
Unfortunately, you'll also see some failures :(. Don't worry though!  The reason
you see failures is the lack of full support for some browser standards in PhantomJS.
We don't polyfill for PhantomJS (at least when this is being written) so you'll generally
see a few failures there.

Now navigate in your browser to http://phantom.docker and your tests will run inside
the browser you have open (in addition to PhantomJS).  This will give you the chance
to debug them as well as see how they work in a fully functional browser.  Our JS
specs currently run in Chrome so make sure that your tests pass there.

## Javascript Test Coverage

You can generate code coverage locally by first running `npm install` having webpack
set up( `touch config/WEBPACK`) then running `bundle exec rake js:test` or `npm run webpack-test`.
You should then have a folder in your root directory called `coverage-js`
in which contains an `index.html` which if you open it will show you
the test coverage for all javascript (js, coffee, jsx)
