# Canvas Rich Content Editor

The Canvas LMS Rich Content Editor extracted in it's own npm package for use
across multiple services. This npm module is used in pair with a running
`canvas-rce-api` microservice.

You need a running instance of the `canvas-rce-api` in order to utilize
the `canvas-rce` npm module, but you do not need that instance in order to
do development on `canvas-rce`. (see [docs/development.md](docs/development.md))

The first customer of the `canvas-rce` was the `canvas-lms` LMS so documentation
and references throughout documentation might reflect and assume the use of
`canvas-lms`.

# Install and setup

As a published npm module, you can add canvsas-rce to your node project by doing
the following:

```bash
npm install canvas-rce --save
```

Please reference the [canvas-lms use of canvas-rce](https://github.com/instructure/canvas-lms/tree/stable/app/jsx/shared/rce)
to get an idea on how to incorporate it into your project. Pay
special attention to the `RichContentEditor.js` and `serviceRCELoader.js`.