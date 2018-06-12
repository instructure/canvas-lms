canvas-planner
==================

Canvas Planner is the UI component for the List View Dashboard feature in [Canvas](https://github.com/instructure/canvas-lms).

## Development

### Getting Started

Canvas Planner includes a `prepublish` script which runs a build anytime it's installed. As canvas
resolves its dependencies, this builds planner before it's installed into `canvas-lms/node_modules`.

To facilitate active development, create a link between planner and canvas. Since the normal
`yarn install` process copies planner into `canvas-lms/node_modules/canvas-planner`, changes in planner's source
won't be reflected in canvas until `yarn` is rerun.  This inconvenience can be dealt with by linking
the two together.

- From the `canvas-lms/packages/canvas-planner` directory, run `yarn link`.
  - This only needs to be done once
- Then from the root `canvas-lms` directory, run `yarn link canvas-planner`.
  - This needs to be rerun anytime canvas' dependencies are reinstalled (say after `rm -fr node_modules`).

These steps create a symbolic link between the planner source subdirectory
and canvas' `node_modules`. You can confirm this by running `ls -l node_modules/canvas-planner` from the `canvas-lms` root directory, which should respond with
```
node_modules/canvas-planner -> ../packages/canvas-planner
```
and not the contents of the directory.

Finally, start watched builds
- In `canvas-lms/packages/canvas-planner`, run `yarn build:watch`
- In `canvas-lms`, run `yarn build:watch`

Now any changes to the planner source will trigger a planner incremental build, which will in turn trigger
a canvas incremental build.

If you are doing a lot of CSS work, the watch commands don't track changes so well. If you find this is the case,
you can run `yarn build:dev`. This variant does not watch, but still sets up the environment so that class
names and theme variables are not mangled by the INSTUI themeable tooling.

> *Any commands discussed in the rest of this document assume your current working directory is `canvas-lms/packages/canvas-planner`.*

### Linting

This project uses [eslint-config-react-app](https://github.com/facebookincubator/create-react-app/tree/master/packages/eslint-config-react-app)
for linting JS files.  Linting is enforced at the build level.  ESLint errors will cause the build to fail.
You can run the linter by running `yarn lint`.

### Debugging

In lieu of verbose console logging, planner uses the [Redux DevTools Extension](https://github.com/zalmoxisus/redux-devtools-extension).
To use it, simply [install](https://github.com/zalmoxisus/redux-devtools-extension#installation) the extension for your
browser of choice, then go to the planner and open your web inspector. From there, select the newly added `Redux` tab
and a plethora of useful debugging tools and information will be displayed.

### Testing

We use [Jest](http://facebook.github.io/jest/) for testing the codebase.  You can run it
by running `yarn test` for a single run or `yarn test:watch` to start up a watcher process for it.
If you are having trouble with the watch process you may need to set up [watchman] (https://facebook.github.io/watchman/).
It should be as simple as `brew install watchman` on a Mac, no configuration is required.  For more details about these
issues see the discussion on the issue, [watch mode stopped working on macOS Sierra](https://github.com/facebook/jest/issues/1767).
We require test coverage percentages to be maintained.  Run the test coverage by running `yarn run test:coverage`

You can limit the scope of your testing to a single file by providing it on the command line.
```
yarn test src/components/BadgeList/__test__/BadgeList.spec.js
```

## Production
When canvas is built for production, the same process applies. When satisfying its `canvas-planner` dependency,
planner is built and installed it into `node_modules`. From there it is packaged
and minified by canvas' webpack build process.
