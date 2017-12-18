canvas-planner
==================

Canvas Planner is the UI component for the List View Dashboard feature in [Canvas](https://github.com/instructure/canvas-lms).

## Production

### Usage

```bash
yarn add canvas-planner
```

```js
import Planner from 'canvas-planner';
```

### Polyfill

Canvas Planner is developed using modern JavaScript and supports modern browsers.
If you are using it in an environment such as IE 11 where some core browser features
are unavailable, then you should make sure to polyfill appropriately.  This package
does not ship any polyfills to maintain a smaller footprint.


## Development

### Getting Started

```bash
yarn
yarn start
```

Go to your browser to http://localhost:3005 to see the app.  This will
also start a json-server instance at http://localhost:3004 which api requests
will be proxied from webpack-dev-server to eliminating the need to have an
instance of Canvas running to do development.

#### Running without a delay

By default, all requests to the json-server have a 1.5 second delay introduced
to help us develop for proper loading states.  If you want to run without the
delay you'll need to instead run:

```bash
yarn run start:json-server:no-delay
```

And then in a separate terminal tab/session/window/etc.

```bash
yarn run start:webpack-dev
```

### Linting

This project uses [eslint-config-react-app](https://github.com/facebookincubator/create-react-app/tree/master/packages/eslint-config-react-app)
for linting JS files.  Linting is enforced at the build level.  ESLint errors will cause the build to fail.
You can run the linter by running `yarn run lint`

### Testing

We use [Jest](http://facebook.github.io/jest/) for testing the codebase.  You can run it
by running `yarn test` for a single run or `yarn test:watch` to start up a watcher process for it.
If you are having trouble with the watch process you may need to set up [watchman] (https://facebook.github.io/watchman/).
It should be as simple as `brew install watchman` on a Mac, no configuration is required.  For more details about these
issues see the discussion on the issue, [watch mode stopped working on macOS Sierra](https://github.com/facebook/jest/issues/1767).
We require test coverage percentages to be maintained.  Run the test coverage by running `yarn run test:coverage`

### Testing a local Canvas Planner version

If you want to test a version of the planner locally without publishing it you can
do so by using [yarn link](https://yarnpkg.com/en/docs/cli/link).

The way it is done is as follows:

```bash
cd canvas-planner
yarn run build # Build the proper transpiled versions of the files
yarn link

cd ./canvas-lms
yarn link canvas-planner
```

Once you've done those things, run the proper build steps for your Canvas
installation and you'll see your local copy of canvas-planner working inside
Canvas.

### Deploying

To deploy a new version of canvas-planner to npm first update the version field in the package.json.
You will then commit that version to canvas-planner and in your commit message paste the output
of the command below.
`git log v(enter previous version here)...origin/master --pretty=format:"[%h] (%an)  %s"`
Next run `./scripts/release` if you have already updated the planner version in your package.json
you can press enter otherwise follow the instructions on screen.

After published go to your canvas-lms directory and open the package.json.  Update the canvas-planner
dependency to the one you just released.  After that you will need to remove your node_modules and reinstall
using `yarn`.  From there you should commit the yarn.lock and the diff in the package.json.
