# Canvas Rich Content Editor

> The Canvas LMS Rich Content Editor (RCE) extracted in it's own npm package for use across multiple services

In the Canvas ecosystem, this npm module is used in conjunction with the Rich Content Service (RCS) microservice. The code for the RCS is also open source and lives in the `canvas-rce-api` repository. (see https://github.com/instructure/canvas-rce-api)

Some features require a running instance of the `canvas-rce-api`, but you do not need an instance in order to do development on `@instructure/canvas-rce`. (see the [Development section](#development))

The primary consumer of the `@instructure/canvas-rce` is `canvas-lms`, so documentation
and references throughout documentation might reflect and assume the use of `canvas-lms`.

## Install and Setup

As a published npm module, you can add `@instructure/canvas-rce` to your node project by doing
the following:

```bash
npm install @instructure/canvas-rce --save
```

For guidance on how `@instructure/canvas-rce` is used within Canvas, please reference
the [canvas-lms use of canvas-rce](https://github.com/instructure/canvas-lms/tree/master/ui/shared/rce) to get an idea on how to incorporate it into your project. Pay
special attention to the `RichContentEditor.js` and `serviceRCELoader.js`.

Outside of Canvas, the `CanvasRce` React component is your entry point.

## Tests

First, build assets. Then you can run the tests:

```bash
yarn build:all
yarn test:jest
```

There are still legacy mocha tests run with `yarn test:mocha`. The command `yarn test` runs them all.

### Test Debugging Hints

```
yarn test:jest:debug path/to/__test__/file.test.js
```

will break and wait for you to attach a debugger (e.g. `chrome://inspect/#devices`).

Similarly, for mocha tests

```
yarn test:mocha:debug path/to/test/file.test.js
```

Both those commands may include a `--watch` argument to keep the process alive
while you iterate.

## Polyfills

This project makes use of modern JavaScript APIs like `Promise`, `Object.assign`,
`Array.prototype.includes`, etc. which are present in modern
browsers but may not be present in old browsers like IE 11. In order to not
send unnecessarily large and duplicated code bundles to the browser, consumers
are expected to have already globally polyfilled those APIs.
Canvas only supports modern browsers and the RCE has not been tested
in older browsers like IE. If you need suggestions for how to include
polyfills in your own app, you can put this in your html above the script that includes
`@instructure/canvas-rce`:

```
<script src="https://cdn.polyfill.io/v2/polyfill.min.js?rum=0"></script>
```

(See https://polyfill.io/v2/docs/ for more info)

## Development

See [DEVELOPMENT.md](https://github.com/instructure/canvas-lms/blob/master/packages/canvas-rce/DEVELOPMENT.md)
