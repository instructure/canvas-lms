# Using Docker for Canvas Development

You can use Docker in your development environment for a more seamless
way to get started developing Canvas.

**Note for previous Docker for Canvas development users**
If you have a `docker-compose.override.yml`, you'll need to update it to version 2 or delete it.

## Automated setup script

The easiest way to get a working development environment is to run:

```
./script/docker_dev_setup.sh
```

This will guide you through the process of installing docker, dinghy/dory,
building the docker images, and setting up Canvas.

If you would rather do things manually, read on!

## Recommendations

By default `docker-compose` will look at 2 files
- docker-compose.yml
- docker-compose.override.yml

If you need more than what the default override provides you should use a `.env` file to set your `COMPOSE_FILE` environment variable.

### Create your own local docker-compose overrides file(s)

In order to tweak your local environment (which you may want to do for any of several reasons),
you can create your own [docker-compose overrides file](https://docs.docker.com/compose/compose-file/).
To get docker-compose to pick up your file and use its settings, you'll want to set an
environment variable `COMPOSE_FILE`.  The place to do this is in a `.env` file.
Create a `docker-compose.local.<username>.yml` and add a `COMPOSE_FILE` environment variable.
This variable can then have a list of files, separated by `:`.  You need to keep the main docker-compose and docker-compose.override otherwise everything will be ruined.

```bash
echo "COMPOSE_FILE=docker-compose.yml:docker-compose.override.yml:docker-compose.local.`whoami`.yml" >> .env
```

Setup your user-specific docker-compose override file as an empty file using the following command:

```bash
echo "version: '2'" > docker-compose.local.`whoami`.yml
```

## Getting Started
After you have [installed the dependencies](getting_docker.md). You'll need to copy
over the required configuration files.

The `docker-compose/config` directory has some config files already set up to use
the linked containers supplied by config. You can just copy them to
`config/`:

```
$ cp docker-compose/config/* config/
```

Now you're ready to build all of the containers. This will take a while as a lot is going on here.

- Images are downloaded and built
- Database is created and initial setup is run
- Assets are compiled

```bash
docker-compose run --rm web bundle install
docker-compose run --rm web bundle exec rake db:create db:initial_setup canvas:compile_assets_dev
```

Now you should be able to start up and access canvas like you would any other container.
```bash
docker-compose up
open http://web.canvaslms.docker
```

## Normal Usage

Normally you can just start everything with `docker-compose up`, and
access Canvas at http://web.canvaslms.docker/.

After pulling new code, you'll probably want to run migrations and
update assets:

```
$ docker-compose run --rm web bundle update
$ docker-compose run --rm web bundle exec rake db:migrate
$ docker-compose run --rm web bundle exec rake canvas:compile_assets
```

Changes you're making are not showing up? See the Caveats section below.
Ctrl-C your `docker-compose up` window and restart.

## Debugging

### Byebug

A byebug server is running in development mode on the web and job containers
to allow you to remotely control any sessions where `byebug` has yielded
execution. To use it, you will need to enable `REMOTE_DEBUGGING_ENABLED` in your
`docker-compose.<user>.override.yml` file in your app's root directory. If you don't have
this file, you will need to create it and add the following:

```
version: '2'
services:
  web:
    environment:
      REMOTE_DEBUGGING_ENABLED: 'true'
```

Make sure you add this new file to your `COMPOSE_FILE` var in `.env`.

You can attach to the byebug server once the container is started:

Debugging web:

```
docker-compose exec web bin/byebug-remote
```

Debugging jobs:

```
docker-compose exec jobs bin/byebug-remote
```

### Prefer pry?

Unfortunately, you can't start a pry session in a remote byebug session. What
you can do instead is use `pry-remote`.

1. Add `pry-remote` to your Gemfile
2. Run `docker-compose run --rm web bundle install` to install `pry-remote`
3. Add `binding.remote_pry` in code where you want execution to yield a pry REPL
4. Launch pry-remote and have it wait for execution to yield to you:
```
docker-compose exec web pry-remote --wait
```

## Running tests

```
$ docker-compose run --rm web bundle exec rspec spec
```

## Running javascript tests

To run tests in headless Chrome, add the `docker-compose/js-tests.override.yml`
to the `COMPOSE_FILE` environment variable in your .env, and run:

```
$ docker-compose run --rm js-tests
```

### Selenium

To enable Selenium: Add `docker-compose/selenium.override.yml` to your `COMPOSE_FILE` var in `.env`.

The container used to run the selenium browser is only started when spinning up
all docker-compose containers, or when specified explicitly. The selenium
container needs to be started before running any specs that require selenium.

```sh
docker-compose up selenium-firefox # or selenium-chrome
```

With the container running, you should be able to open a VNC session:

```sh
open vnc://secret:secret@seleniumff.docker          (firefox)
open vnc://secret:secret@seleniumch.docker:5901     (chrome)
```

Now just run your choice of selenium specs:

```sh
docker-compose run --rm web bundle exec rspec spec/selenium/dashboard_spec.rb
```


## Extra Services

### Cassandra

If you're using the analytics package, you'll also need Cassandra. The
Cassandra configuration isn't enabled by default. Add `docker-compose/cassandra.override.yml` to your `COMPOSE_FILE` var in `.env`

Then:
- Uncomment configuration in config/cassandra.yml
- See config/cassandra.yml.example for further setup instructions

### Mail Catcher

To enable Mail Catcher: Add `docker-compose/mailcatcher.override.yml` to your `COMPOSE_FILE` var in `.env`.

Email is often sent through background jobs if you spin up the `jobs` container.
If you would like to test or preview any notifications, simply trigger the email
through its normal actions, and it should immediately show up in the emulated
webmail inbox available here: http://mailcatcher.canvaslms.docker/

## Tips

It will likely be helpful to alias the various docker-compose commands like `docker-compose run --rm web` because that can get tiring to type over and over. Here are some recommended aliases you can add to your `~/.bash_profile` and reload your Terminal.

```
alias dc='docker-compose'
alias dcu='docker-compose up'
alias dcr='docker-compose run --rm web'
alias dcrx='docker-compose run --rm web bundle exec'
```

Now you can just run commands like `dcrx rake db:migrate` or `dcr bundle install`

## Troubleshooting

If you are having trouble running the `web` container, make sure that permissions on the directory are permissive.  You can try the owner change (less disruptive):

```
chown -R 1000:1000 canvas-lms
```

Or the permissions change (which will make Docker work, but causes the git working directory to become filthy):

```
chmod a+rwx -R canvas-lms
```

If your distro is equipped with [SELinux](https://en.wikipedia.org/wiki/Security-Enhanced_Linux),
make sure it is not interfering.

```
$ sestatus
...
Current mode:                   disabled
...

```

If so, it can be disabled temporarily with:

```
sudo setenforce 0
```

Or it can be disabled permanently by editing `/etc/selinux/config` thusly:

```
SELINUX=disabled
```

If you are having performance or other issues with your web container
starting up, you may try adding `DISABLE_SPRING: 1` to your
`docker-compose.override.yml` file, like so:

```
web: &WEB
  environment:
    DISABLE_SPRING: 1
```

If you are getting DNS resolution errors, and you use Docker for Mac or Linux,
make sure [dory](https://github.com/FreedomBen/dory) is running:

```
dory status
```

If dory is not running, you can start it with:

```
dory up
```
