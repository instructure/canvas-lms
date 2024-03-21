# Using inst CLI for Canvas Development

You can use the `inst` CLI Ruby gem for a more seamless way to get started developing Canvas in Docker.

Eventually we'll publish `inst` to RubyGems. For now it's available to Instructure employees only.

We have lots of improvements planned for `inst` CLI. Please share your feedback so that we can build what you need! #devx

## Prerequisites

Follow the prerequisites listed [here](https://instructure.atlassian.net/wiki/spaces/CE/pages/85912256716/INST-CLI+local+docker+dev+canvas+quizzes#Prerequisites).

Then in your terminal:

```bash
gem install inst inst-private
inst config-file
```

## Automated setup script

The easiest way to get a working Canvas development environment is to run:

```bash
inst canvas setup
```

inst CLI will guide you through the process of building the docker images and setting up Canvas.

Normally Canvas will give you a series of prompts when setting up a fresh Canvas database. To skip those prompts:

```bash
export CANVAS_LMS_ADMIN_EMAIL=admin@email.com
export CANVAS_LMS_ADMIN_PASSWORD=password
export CANVAS_LMS_ACCOUNT_NAME=inst
export CANVAS_LMS_STATS_COLLECTION=opt_out
inst canvas setup
```

We'll improve this in the future. :)

## Normal Usage

Normally you can just start everything with `inst canvas setup`.

To rebase your canvas-lms repo clone and all its plugins:

```bash
inst canvas rebase
```

After pulling new code, you'll want to rebuild your docker images, run migrations, and recompile assets:

```bash
inst canvas rebuild
```

To do both you can use either one of these commands:

```bash
inst canvas rebase --rebuild

# or

inst canvas rebuild --rebase
```

### With an IDE

This feature is not yet supported.

### Byebug

This feature is not yet supported.

### Prefer pry?

This feature is not yet supported.

## Testing

Running tests in Canvas works best after `inst canvas setup`.

### Running Ruby tests

```bash
$ docker-compose exec canvas-web bundle exec rspec spec
```

### Running javascript tests

First add `docker-compose/js-tests.override.yml` to your `COMPOSE_FILE` var in `.env`. Then prepare that container with:

```bash
docker-compose run --rm js-tests yarn install
```

If you run into issues with `yarn install`, either during initial setup or after updating master, try to fix it with a `nuke_node`:

```bash
docker-compose run --rm js-tests ./script/nuke_node.sh
docker-compose run --rm js-tests yarn install
```

#### QUnit Karma Tests in Headless Chrome

Run all QUnit tests in watch mode with:

```bash
docker-compose up js-tests
```

Or, if you're iterating on something and want to just run a targeted test file in watch mode, set the `JSPEC_PATH` env var, e.g.:

```bash
export JSPEC_PATH=spec/coffeescripts/util/deparamSpec.js
docker-compose up js-tests
```

To run a targeted test without watch mode:

```bash
docker-compose run --rm -e JSPEC_PATH=spec/coffeescripts/util/deparamSpec.js js-tests yarn test:karma:headless
```

#### Jest Tests

Run all Jest tests with:

```bash
docker-compose run --rm js-tests yarn test:jest
```

Or run a targeted subset of tests:

```bash
docker-compose run --rm js-tests yarn test:jest ui/features/speed_grader/react/__tests__/CommentArea.test.js
```

To run a targeted subset of tests in watch mode, use `test:jest:watch` and specify the paths to the test files as one or more arguments, e.g.:

```bash
docker-compose run --rm js-tests yarn test:jest:watch ui/features/speed_grader/react/__tests__/CommentArea.test.js
```

### Selenium

To enable Selenium: Add `docker-compose/selenium.override.yml` to your `COMPOSE_FILE` var in `.env`.

For M1 Mac users using Chrome, the official selenium images are not ARM compatible so a standalone chromium image must be used. In the `docker-compose/selenium.override.yml` file, replace the image with the following:

```bash
image: seleniarm/standalone-chromium
```

The container used to run the selenium browser is only started when spinning up all docker-compose containers, or when specified explicitly. The selenium container needs to be started before running any specs that require selenium. Select a browser to run in selenium through `config/selenium.yml` and then ensure that only the corresponding browser is configured in `docker-compose/selenium.override.yml`.

```bash
docker-compose up -d selenium-hub
```

With the container running, you should be able to open a VNC session:

```bash
open vnc://secret:secret@localhost:5900   # (firefox)
open vnc://secret:secret@localhost:5901   # (chrome)
open vnc://secret:secret@localhost:5902   # (edge)
```

Now just run your choice of selenium specs:

```bash
docker-compose exec canvas-web bundle exec rspec spec/selenium/dashboard/dashboard_spec.rb
```

### Capturing Rails Logs and Screenshots

When selenium specs fail, the root cause isn't always obvious from the
stdout/stderr of `rspec`. E.g. you might just see an `Uncaught Error: Internal
Server Error`. To see the actual stack trace that led to the 500 response, you
have to look at the rails logs. One way to do that is to just view
`/usr/src/app/log/test.log` after the fact, or `tail -f` it during the run.
Note that the log directory is a non-synchronized volume mount, so you need to
actually view it from inside the `canvas-web` container rather than just on your
native host.

But here's a hot tip -- you can capture the portion of the rails log that
corresponds to each failed spec, plus a screenshot of the page at the time of
the failure, by running your specs with the `spec/spec.opts` options like:

```sh
docker-compose exec canvas-web bundle exec rspec --options spec/spec.opts spec/selenium/dashboard/dashboard_spec.rb
```

This will produce a `log/spec_failures` directory in the container, which you
can then `docker cp` to your host to view in a browser:

```sh
docker cp "$(docker-compose ps -q canvas-web | head -1)":/usr/src/app/log/spec_failures .
open -a "Google Chrome" file:///"$(pwd)"/spec_failures
```

That directory tree contains a web page per spec failure, each featuring a
colorized rails log and a browser screenshot taken at the time of the failure.

## Extra Services

### Cassandra

This feature is not yet supported.

### Mail Catcher

To enable Mail Catcher: Add `docker-compose/mailcatcher.override.yml` to your `COMPOSE_FILE` var in `.env`. Then you can `docker-compose up mailcatcher`.

Email is often sent through background jobs in the jobs container. If you would like to test or preview any notifications, simply trigger the email through its normal actions, and it should immediately show up in the emulated webmail inbox available here: <http://mailcatcher.inseng.test>

### Canvas RCE API

Edit `.env`

```
COMPOSE_FILE=<CURRENT_VALUE>:inst-cli/docker-compose/rce-api.override.yml
```

Edit `config/dynamic_settings.yml` (first `cp config/dynamic-settings.yml.example config/dynamic-settings.yml` if necessary):

```yaml
development:
  # tree
  config:
    # service
    canvas:
      # prefix
      # ... omitted for brevity ...
      rich-content-service:
        app-host: "http://canvas-canvasrceapi.inseng.test"
```

Then

```bash
# start the RCE API service
docker compose up -d canvasrceapi

# setup canvas if you haven't already
inst canvas setup

# or, if you already ran `inst canvas setup` prior, restart canvas to make it read the new RCS app-host config
docker compose restart web
```

## Storybook

Edit `.env`

```
COMPOSE_FILE=<CURRENT_VALUE>:inst-cli/docker-compose/storybook.override.yml
```

`inst proxy up` if you haven't already, then `docker-compose up storybook` and open <http://canvas-storybook.inseng.test> in your browser.

## Tips

It will likely be helpful to alias the various docker-compose commands like `docker-compose run --rm canvas-web` because that can get tiring to type over and over. Here are some recommended aliases you can add to your `~/.bash_profile` and reload your Terminal.

```bash
alias dc='docker-compose'
alias dcu='docker-compose up'
alias dce='docker-compose exec'
alias dcex='docker-compose exec canvas-web bundle exec'
alias dcr='docker-compose run --rm canvas-web'
alias dcrx='docker-compose run --rm canvas-web bundle exec'
```

Now you can just run commands like `dcex rake db:migrate` or `dcr bundle install`

## Troubleshooting

### Building the canvas-web Docker container

If you get an error about some gems requiring a newer ruby, you may have to change `2.4-xenial` to `2.5` in the `FROM` line in Dockerfile.

### Permissions

If you are having trouble running the `canvas-web` container, make sure that permissions on the directory are permissive.  You can try the owner change (less disruptive):

```bash
chown -R 1000:1000 canvas-lms
```

Instead of `1000`, you may need to use `9999` -- the `docker` user inside the container may have uid `9999`.

Or the permissions change (which will make Docker work, but causes the git working directory to become filthy):

```bash
chmod a+rwx -R canvas-lms
```

If your distro is equipped with [SELinux](https://en.wikipedia.org/wiki/Security-Enhanced_Linux), make sure it is not interfering.

```bash
$ sestatus
...
Current mode:                   disabled
...

```

If so, it can be disabled temporarily with:

```bash
sudo setenforce 0
```

Or it can be disabled permanently by editing `/etc/selinux/config` thusly:

```bash
SELINUX=disabled
```

### Performance

If you are having performance or other issues with your canvas-web container starting up, you may try adding `DISABLE_SPRING: 1` to your `docker-compose.override.yml` file, like so:

```bash
canvas-web: &WEB
  environment:
    DISABLE_SPRING: 1
```

Sometimes, very poor performance (or not loading at all) can be due to webpack problems. Running
`docker-compose exec canvas-web bundle exec rake canvas:compile_assets` again, or
`docker-compose exec canvas-web bundle exec rake js:webpack_development` again, may help.
