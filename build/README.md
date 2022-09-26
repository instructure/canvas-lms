# About

This directory contains the scripts for our Jenkins build.

# Docker Build Images

The docker build is split into several distinct images to take full advantage
of caching.

- Ruby Gems (ruby-runner)
    - This image contains instructure/ruby-passenger + gems
- Yarn Packages (yarn-runner)
    - This image contains ruby-runner and yarn packages without postinstall executed
- Canvas Packages (webpack-builder)
    - This image contains yarn-runner and built packages from the packages/ directory
- Webpack Built Assets (webpack-assets)
    - This image contains the fully built webpack assets in public/. It does not contain
  yarn-runner or webpack-builder.
- Patchset
    - This image contains webpack-assets and the rest of the application files for
  running tests under. It is the primary image used by the rspec / selenium jobs.

# Docker Build Tags

Each image is built through docker-build.sh, and is tagged with the following format:

```
starlord.inscloudgate.net/jenkins/canvas-lms-[image type]:[image scope]-[salt]-[cache id]
```

- image type = one of ruby-runner, yarn-runner, webpack-builder, webpack-assets
- image scope = one of master, [patchset number]
- salt = unique value that changes if the image labels need to change
- cache id = hash of all relevant files for that image

The patchset image is tagged differently in order to be pulled by the testing jobs, since they
don't and shouldn't know about the hash ID formats. The webpack-builder image has an additional
tag with the unique patchset id for similar reasons.

- `starlord.inscloudgate.net/jenkins/canvas-lms:[unique patchset id]`
- `starlord.inscloudgate.net/jenkins/canvas-lms-webpack-builder:[unique patchset id]`

Examples:

- `starlord.inscloudgate.net/jenkins/canvas-lms:20.255220.11-postgres-12-ruby-2.6`
- `starlord.inscloudgate.net/jenkins/canvas-lms-webpack-builder:20.255220.11-postgres-12-ruby-2.6`
- `starlord.inscloudgate.net/jenkins/canvas-lms-yarn-runner:master-39e953ae-9414c88300488700236b8f34cd228fe0`
- `starlord.inscloudgate.net/jenkins/canvas-lms-webpack-assets:master-39e953ae-642ae86a8baf46e598852d6adbdf4766`
- `starlord.inscloudgate.net/jenkins/canvas-lms-webpack-builder:master-39e953ae-cad9edddd890801ee5cb811267c7299c`
- `starlord.inscloudgate.net/jenkins/canvas-lms-ruby-runner:master-39e953ae-f98271e7f6a8da245c645b3087238be7`

# Docker Build Flow

The build is structured in a way that reduces the number of computations that need to be done for each patchset. It
relies heavily on the MD5SUM of important files in the build to accomplish it's tasks. The script is contained
in `docker-build.sh`.

1. Jenkins starts to build a patchset with changes.
2. It computes the hash of all relevant dependencies for the above images, which is the cache id above.
3. It attempts to pull the images in the following order, ordered by least build time required.
    1. webpack-assets:master, webpack-assets:[patchset number]
        * The most ideal cached image for ruby-only changes, requires only copying in the changed application files.
    2. webpack-builder:master, webpack-builder:[patchset number]
        * The most ideal cached image for webpack-related changes
    3. yarn-runner:master, yarn-runner:[patchset number]
        * The most ideal cached image for packages-folder-related changes, such as canvas-rce
    4. ruby-runner:master, ruby-runner:[patchset number]
        * The most ideal cached image for yarn.lock and related changes
4. It builds all of the missing images
5. It retags relevant patchset-scoped images to be master-scoped upon post-merge
6. It pushes up all images to starlord

Each pre-merge build pushes up images under the [patchset number] scope, and you can expect that there will be 1 image
per revision that contains unique file changes. Upon merging the patchset, the post-merge build will attempt to pull
an image that is already built from the pre-merge cache. This helps the cache to be available sooner for other builds
to use when gems or yarn has changed, for example. All images with a scope of "master" can be expected to correspond
with a commit that was actually merged.

# Debugging

All images that are uploaded are tagged with the other images that were used to build it to trace their history.

```
docker pull starlord.inscloudgate.net/jenkins/canvas-lms:20.255220.11-postgres-12-ruby-2.6
docker image inspect starlord.inscloudgate.net/jenkins/canvas-lms:20.255220.11-postgres-12-ruby-2.6 --format '{{json .Config.Labels }}' | python -m json.tool

{
    "RUBY_RUNNER_SELECTED_TAG": "starlord.inscloudgate.net/jenkins/canvas-lms-ruby-runner:master-c480fc86-a30b30a43fb95f996d13db8d5236c772",
    "WEBPACK_BUILDER_SELECTED_TAG": "starlord.inscloudgate.net/jenkins/canvas-lms-webpack-builder:master-c480fc86-350f70e66da25a6e27dd0851be751e15",
    "WEBPACK_ASSETS_SELECTED_TAG": "starlord.inscloudgate.net/jenkins/canvas-lms-webpack-assets:master-c480fc86-dccd0b970e09db19fd839da2cb9150e0",
    "YARN_RUNNER_SELECTED_TAG": "starlord.inscloudgate.net/jenkins/canvas-lms-yarn-runner:master-c480fc86-217b3c20e3a7d4a66de8fc4e10871a48",
    "maintainer": "Instructure"
}
```

# FAQ

Q: I added a new file dependency to `bundle exec rake canvas:compile_assets` or similar task, and
   the build is throwing an error because it can't find it. How do I fix it?

A: The cache images used for the computation are built in `Dockerfile.jenkins-cache`. Please take
   care to add as few files as possible to each tarball.
