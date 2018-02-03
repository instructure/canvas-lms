# Testing JavaScript

The process of testing JavaScript sometimes confuses people. This document's goal
is to alleviate that confusion and establish how to run JavaScript tests.

## Jest
Whenever possible, which for now means when you are testing something that only imports
stuff that does not use AMD imports (eg, it only requires
stuff from app/jsx or node_modules), you should write your js tests for
[Jest](https://facebook.github.io/jest/) going forward. It is faster and the testing experience will be better.

Jest is a Node-based runner. This means that the tests always run in a Node environment and not in a real browser. This lets us enable fast iteration speed and prevent flakiness.

While Jest provides browser globals such as `window` thanks to [jsdom](https://github.com/tmpvar/jsdom), they are only approximations of the real browser behavior. Jest is intended to be used for unit tests of your logic and your components rather than the DOM quirks. Use a qUnit karma test or selenium for browser end-to-end tests if you need them.

### Filename Conventions

Put the test files (or `__tests__` folders) next to the code they are testing so that relative imports appear shorter. For example, if `App.test.js` and `App.js` are in the same folder, the test just needs to `import App from './App'` instead of a long relative path. Colocation also helps find tests more quickly in larger projects.

### Writing Jest Tests

To create tests, add `it()` (or `test()`) blocks with the name of the test and its code. You may optionally wrap them in `describe()` blocks for logical grouping but this is neither required nor recommended.

Jest provides a built-in `expect()` global function for making assertions. A basic test could look like this:

```js
import sum from './sum'

it('sums numbers', () => {
  expect(sum(1, 2)).toEqual(3)
  expect(sum(2, 2)).toEqual(4)
})
```

All `expect()` matchers supported by Jest are [extensively documented here](http://facebook.github.io/jest/docs/api.html#expect-value).<br>
You can also use [`jest.fn()` and `expect(fn).toBeCalled()`](http://facebook.github.io/jest/docs/api.html#tobecalled) to create “spies” or mock functions and in jest tests you should probably use that instead of sinon mocks/spies/stubs like we use in our QUnit tests.

### Testing Components

There is a broad spectrum of component testing techniques. They range from a “smoke test” using a jest snapshot, to shallow rendering and testing some of the output, to full rendering and testing component lifecycle and state changes.

An example of a simple smoke test for your components:

```js
import React from 'react'
import ReactDOM from 'react-dom'
import SomeComponent from './SomeComponent'

it('renders without crashing', () => {
  const div = document.createElement('div');
  ReactDOM.render(<App />, div);
});
```

This test mounts a component and makes sure that it didn’t throw during rendering. Tests like this provide a lot value with very little effort so they are great as a starting point.

When you encounter bugs caused by changing components, you will gain a deeper insight into which parts of them are worth testing in your application. This might be a good time to introduce more specific tests asserting specific expected output or behavior.

If you’d like to test components in isolation from the child components they render, we recommend using [`shallow()` rendering API](http://airbnb.io/enzyme/docs/api/shallow.html) from [Enzyme](http://airbnb.io/enzyme/). You can write a smoke test with it too:

```js
import React from 'react';
import { shallow } from 'enzyme';
import App from './App';

it('renders without crashing', () => {
  shallow(<App />);
});
```

Unlike the previous smoke test using `ReactDOM.render()`, this test only renders `<App>` and doesn’t go deeper. For example, even if `<App>` itself renders a `<Button>` that throws, this test will pass. Shallow rendering is great for isolated unit tests, but you may still want to create some full rendering tests to ensure the components integrate correctly. Enzyme supports [full rendering with `mount()`](http://airbnb.io/enzyme/docs/api/mount.html), and you can also use it for testing state changes and component lifecycle.

You can read the [Enzyme documentation](http://airbnb.io/enzyme/) for more testing techniques. Enzyme documentation uses Chai and Sinon for assertions but you don’t have to use them because Jest provides built-in `expect()` and `jest.fn()` for spies.

All Jest matchers are [extensively documented here](http://facebook.github.io/jest/docs/api.html#expect-value).

### Focusing and Excluding Tests

You can replace `it()` with `xit()` to temporarily exclude a test from being executed.<br>
Similarly, `fit()` lets you focus on a specific test without running any other tests.

### Coverage Reporting

Jest has an integrated coverage reporter that works well with ES6 and requires no configuration.<br>
Run `npm test -- --coverage` (note extra `--` in the middle) to include a coverage report like this:

![coverage report](http://i.imgur.com/5bFhnTS.png)

Note that tests run much slower with coverage so it is recommended to run it separately from your normal workflow.

### Snapshot Testing

Snapshot testing is a feature of Jest that automatically generates text snapshots of
your components and saves them on the disk so if the UI output changes, you get
notified without manually writing any assertions on the component output.
[Read more about snapshot testing.](http://facebook.github.io/jest/blog/2016/07/27/jest-14.html)

## With Docker and headless Chrome

This is probably the easiest way to run tests, especially for developers that
don't work with Canvas on a regular basis.

Create a `.env` file in the repository root, containing:

```
COMPOSE_FILE=docker-compose.yml:docker-compose.override.yml:docker-compose/js-tests.override.yml
```

Then run:

```
docker-compose run --rm js-tests
```

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

1) `yarn run jspec path/to/specs`
  This will build the specified specs using webpack and run them locally using Chrome.

  You can specify a directory or a single spec file to build and run. If no path
  is provided, all javascript specs are built and ran.

2) `yarn run jspec-watch path/to/specs`
  This will get webpack building the specified specs in watch mode, making it so your
  changes are instantly (or close to instantly) reflected in the test bundle.

  You can specify a directory or a single spec file to watch and build. If no path
  is provided, all javascript specs are watched and built.

  Using `jspec` in this way assumes you will run the specs yourself using PhantomJS
  (see below) or by using `yarn test` to run them locally in Chrome.

### PhantomJS

To run javascript specs using PhantomJS you can do so as follow:

1) `yarn run jspec-watch path/to/specs`
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

You can generate code coverage locally by having webpack
set up( `touch config/WEBPACK`) then running `COVERAGE=1 yarn test`.
You should then have a folder in your root directory called `coverage-js`
in which contains an `index.html` which if you open it will show you
the test coverage for all javascript (js, coffee, jsx)
