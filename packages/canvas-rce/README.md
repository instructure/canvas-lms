# Canvas Rich Content Editor

The Canvas LMS Rich Content Editor extracted in it's own npm package for use
across multiple services. In the canvas ecosystem, this npm module is used
in pair with a running `canvas-rce-api` microservice.

Some features require a running instance of the `canvas-rce-api`,
but you do not need that instance in order to
do development on `canvas-rce`. (see [docs/development.md](docs/development.md))

The first customer of the `canvas-rce` is the `canvas-lms` LMS so documentation
and references throughout documentation might reflect and assume the use of
`canvas-lms`.

## Install and setup

As a published npm module, you can add canvas-rce to your node project by doing
the following:

```bash
npm install canvas-rce --save
```

For guidance on how `canvas-rce` is used within canvas, please reference
the [canvas-lms use of canvas-rce](https://github.com/instructure/canvas-lms/tree/stable/ui/shared/rce)
to get an idea on how to incorporate it into your project. Pay
special attention to the `RichContentEditor.js` and `serviceRCELoader.js`.

Outside of canvas, the `CanvasRce` React component is your entry point.
_Work is ongoing to make the props to `CanvasRce` more rational.
Please be patient._

## Tests

While canvas consumes the es modules build of the rce,
Jest tests are run against the commonjs build, so make sure you've built the
commonjs assets before running tests:

```bash
yarn build:canvas
yarn test:jest
```

There are still legacy mocha tests run with `yarn test:mocha`. `yarn test` runs them all.

### test debugging hints

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

This project makes use of modern JavaScript APIs like Promise, Object.assign,
Array.prototype.includes, etc. which are present in modern
browsers but may not be present in old browsers like IE 11. In order to not
send unnecessarily large and duplicated code bundles to the browser, consumers
are expected to have already globally polyfilled those APIs.
Canvas only supports modern browsers and the rce has not been tested
in older browsers like IE. If you need suggestions for how to include
polyfills in your
own app, you can just put this in your html above the script that includes
canvas-rce:

```
<script src="https://cdn.polyfill.io/v2/polyfill.min.js?rum=0"></script>
```

(See: https://polyfill.io/v2/docs/ for more info)

## Development

See [DEVELOPMENT.md](./DEVELOPMENT.md)
