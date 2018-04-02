# Development

NOTE: The `RichContentService` and `canvas-rce-api` are the same project. It
started out as `RichContentService` and was later renamed `canvas-rce-api`.

`git clone` the code and do the following:
```bash
cd canvas-rce
npm
```

There is a built-in demo application to the `canvas-rce` that allows you to
develop locally without having to setup an instance of `canvas-rce-api`
this works for many things you might want to develop against, but not all
things.

## Debugging the module

### debug using the demo app

There is a demo app included in the `canvas-rce` that will allow you to see
many of the changes that You make. you can run this demo app by executing
`npm run dev` and then browsing to http://localhost:8080/demo.html

This demo app loads up with some fake data that makes interaction between
the sidebar and the editors not work out well. You can, however, load up the
demo app with real data by doing the following

1. Start the demo app (`npm run dev`) and open it up in a browser:
   http://localhost:8080/demo.html
2. In a separate window, start your `canvas-lms` instance. This instance should
   be configured to hit the RCS (so you need to have RCS running as well).
3. Go to a page in `canvas-lms` that has the RCE loaded through the RCS
4. Open the developer console and on the commandline enter `ENV.JWT`. This will
   display the JWT token. copy this token into your buffer.
5. Go back to the RCE Demo app and below the sidebar, click on the
   "Show Options" button
6. In the "Canvas JWT" field, paste your JWT token.
7. In the "API Host" field, enter `http://rce.docker` to hit your local RCS.
8. Make sure the "Context Type" field is selected for whatever context you
   pulled the ENV.JWT from (usually "course").
9. Make sure the "Context ID" field contains the ID for whatever context you
   pulled the ENV.JWT from (if "course" above, then this is the course id).
10. Select "Update" and you'll be able to use the Demo app for real data.

### debug in canvas-lms

If you need/want to see these changes in Canvas, you need to get a
local version of canvas-lms to use a new module. Follow these steps to get your
local version of canvas to use the newly changed npm module.

1. Make sure you have a running copy of `canvas-lms` configured to hit a
   running copy of `canvas-rce-api`.
2. Perform a "local publish" of the npm module by executing the
   `scripts/npm_localpublish.sh` script from the root `canvas-rce` directory.
   The script handles both local file system copy and docker-machine copy.
   example1: `scripts/npm_localpublish.sh -t /tmp/canvas-rce`
   example2: `scripts/npm_localpublish.sh -t /tmp/canvas-rce -d dinghy`
3. Modify your local `canvas-lms`'s `package.json` file to change the
   `"devDependencies"` entry for `canvas-rce` from: `"canvas-rce": "x.y.z",` to:
   `"canvas-rce": "file:/tmp/canvas-rce",`.
4. Run `yarn install` in your `canvas-lms` root directory to install the
   the `canvas-rce` version you are working on.
   example1: `yarn install`
   example2: `docker-compose run --rm web yarn install`

When you have the module loaded into `canvas-lms`, you can test out the module
by seeing what changes were made to the `canvas-lms` environment. It's also
useful to to debug the npm module while it's loaded into `canvas-lms`. The
non-obvious part is figuring out where the module is in the webpack build. In
chrome, just open the 'developer tools', then select the 'sources' tab. In the
'sources' tree, browse to 'webpack://' > '.' > '~' > 'canvas-rce' > 'lib' and
you'll be able to see all the canvas-rce src files under there. Set your
breakpoints as needed and troubleshoot for what you need.