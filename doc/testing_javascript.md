# Testing JavaScript

The process of testing JavaScript sometimes confuses people. This document's goal
is to alleviate that confusion and establish how to run JavaScript tests.

## With Docker and Webpack

This is becoming the go to standard for running Canvas and compiling your not-JavaScript
(CoffeeScript, JSX, Handlebars, etc.) code into JavaScript code.  You should likely
be following this path when doing front-end development on Canvas.  If you need help
getting started with that please see [development_with_docker.md](https://github.com/instructure/canvas-lms/blob/master/doc/development_with_docker.md)
and [working_with_webpack.md](https://github.com/instructure/canvas-lms/blob/master/doc/working_with_webpack.md).

Before we can get started in earnest, we need to make a few changes to a couple
of files. Inside your `.env` file, add the phantomjs-tests override in your
`COMPOSE_FILE` definition: `docker-compose/js-phantomjs-tests.override.yml`

### JSpec

The `jspec` npm script allows you to build and run specific JavaScript specs as follows:

1) `npm run jspec path/to/specs`
  This will build the specified specs using webpack and run them locally using Chrome.

  You can specify a directory or a single spec file to build and run. If no path
  is provided, all javascript specs are built and ran.

2) `npm run jspec-watch path/to/specs`
  This will get webpack building the specified specs in watch mode, making it so your
  changes are instantly (or close to instantly) reflected in the test bundle.

  You can specify a directory or a single spec file to watch and build. If no path
  is provided, all javascript specs are watched and built.

  Using `jspec` in this way assumes you will run the specs yourself using PhantomJS
  (see below) or by using `npm run test` to run them locally in Chrome.

### PhantomJS

To run javascript specs using PhantomJS you can do so as follow:

1) `npm run jspec-watch path/to/specs`
   This will get webpack building the test bundle in watch mode, making it so your
   changes are instantly (or close to instantly) reflected in the test bundle.

   You can specify a directory or a single spec file to watch and build. If no path
   is provided, all javascript specs are watched and built.

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
