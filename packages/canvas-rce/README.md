# Canvas Rich Content Editor

_WARNING:_ While our intent is to make the RCE avaiable outside of
canvas-lms, it currently has dependencies on canvas that make that
impossible. Please be patient.

---

The Canvas LMS Rich Content Editor extracted in it's own npm package for use
across multiple services. This npm module is used in pair with a running
`canvas-rce-api` microservice.

You need a running instance of the `canvas-rce-api` in order to utilize
the `canvas-rce` npm module, but you do not need that instance in order to
do development on `canvas-rce`. (see [docs/development.md](docs/development.md))

The first customer of the `canvas-rce` was the `canvas-lms` LMS so documentation
and references throughout documentation might reflect and assume the use of
`canvas-lms`.

## Install and setup

As a published npm module, you can add canvas-rce to your node project by doing
the following:

```bash
npm install canvas-rce --save
```

Please reference the [canvas-lms use of canvas-rce](https://github.com/instructure/canvas-lms/tree/stable/app/jsx/shared/rce)
to get an idea on how to incorporate it into your project. Pay
special attention to the `RichContentEditor.js` and `serviceRCELoader.js`.

## Polyfills

This project makes use of modern JavaScript APIs like Promise, Object.assign,
Array.prototype.includes, etc. which are present in modern
browsers but may not be present in old browsers like IE 11. In order to not
send unnecessarily large and duplicated code bundles to the browser, consumers
are expected to have already globally polyfilled those APIs.
Canvas already does this but if you need suggestions for how to this in your
own app, you can just put this in your html above the script that includes
canvas-rce:

```
<script src="https://cdn.polyfill.io/v2/polyfill.min.js?rum=0"></script>
```

(See: https://polyfill.io/v2/docs/ for more info)

## Development

See [DEVELOPMENT.md](./DEVELOPMENT.md)
