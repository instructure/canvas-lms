# Testing JavaScript

The process of testing JavaScript sometimes confuses people. This document's goal
is to alleviate that confusion and establish how to run JavaScript tests.

## Jest
Whenever possible, which for now means when you are testing something that only imports
stuff that does not use AMD imports (eg, it only requires
stuff from app/jsx or node_modules), you should write your js tests for
[Jest](https://facebook.github.io/jest/) going forward. It is faster and the testing experience will be better.

Jest is a Node-based runner. This means that the tests always run in a Node environment and not in a real browser. This lets us enable fast iteration speed and prevent flakiness.

While Jest provides browser globals such as `window` thanks to [jsdom](https://github.com/tmpvar/jsdom), they are only approximations of the real browser behavior. Jest is intended to be used for unit tests of your logic and your components rather than the DOM quirks. Use a QUnit Karma test or Selenium for browser end-to-end tests if you need them.

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

*NOTE: You cannot run jest if there is anything with AMD, CoffeeScript, or some of the Webpack aliases (which lead to AMD or CoffeeScript).

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

### Running Tests

To run all tests:
```
yarn test:jest
```

To run a subset of files or directories:
```
yarn test:jest path/to/components/__tests__/spec.js path/to/other_component/ ...
```

To rerun tests on a file change and/or debug remotely:
```
yarn test:jest:debug path/to/components/__tests__/spec.js
```

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

## Running QUnit Karma Tests

A lot of the older stuff is still QUnit.  For more info on running those older tests, see the "Running js tests with webpack" section of [working_with_webpack.md](https://github.com/instructure/canvas-lms/blob/master/doc/working_with_webpack.md).

Tl;dr: run a single test in watch mode like:

```
yarn jspec-watch spec/coffeescripts/util/deparamSpec.js
```

## Running Tests in Docker

See the "Running javascript tests" section of [developing_with_docker.md](https://github.com/instructure/canvas-lms/blob/master/doc/docker/developing_with_docker.md).

## Javascript Test Coverage

You can generate code coverage locally by having webpack
set up( `touch config/WEBPACK`) then running `COVERAGE=1 yarn test`.
You should then have a folder in your root directory called `coverage-js`
in which contains an `index.html` which if you open it will show you
the test coverage for all javascript (js, jsx)
