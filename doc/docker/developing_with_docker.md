# Using Docker for Canvas Development

You can use Docker in your development environment for a more seamless
way to get started developing Canvas.

**Note for previous docker for canvas development users**
If you have a `docker-compose.override.yml`, you'll need to update it to version 2 or delete it.

## Recommendations

If using dinghy or dory, you can use the auto-generated host names.

- web.canvaslms.docker

By default `docker-compose` will look at 2 files
- docker-compose.yml
- docker-compose.override.yml
If you need more than what the default override provides you should use a `.env` file to set your `COMPOSE_FILE` environment variable.

Create a `docker-compose.local.<username>.yml` and append it the `COMPOSE_FILE` environment variable.
Then add only the extras you need to that file.

```bash
touch docker-compose.local.`whoami`.yml
echo COMPOSE_FILE=docker-compose.yml:docker-compose.override.yml:docker-compose.local.`whoami`.yml >> .env
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
docker-compose run --rm web bash -c "bundle exec rake db:create db:initial_setup canvas:compile_assets"
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

Unfortunately you can't start a pry session in a remote byebug session. What
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

### Selenium

To enable Selenium: Add `docker-compose/selenium.override.yml` to your `COMPOSE_FILE` var in `.env`.

The container used to run the selenium browser is only started when spinning up
all docker-compose containers, or when specified explicitly. The selenium
container needs to be started before running any specs that require selenium.

```sh
docker-compose up selenium
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
Cassandra configuration isn't ennabled by default. Add `docker-compose/cassandra.override.yml` to your `COMPOSE_FILE` var in `.env`

Then:
- Uncomment configuration in config/cassandra.yml
- See config/cassandra.yml.example for further setup instructions

### Mail Catcher

To enable Mail Catcher: Add `docker-compose/mailcatcher.override.yml` to your `COMPOSE_FILE` var in `.env`.

Email is often sent through background jobs if you spin up the `jobs` container.
If you would like to test or preview any notifications, simply trigger the email
through it's normal actions, and it should immediately show up in the emulated
webmail inbox available here: http://mailcatcher.canvaslms.docker/

## Troubleshooting

If you are having trouble running the `web` container, make sure that permissions on the directory are permissive.  You can try the owner change (less disruptive):

```
chown -R 1000:1000 canvas-lms
```

Or the permissions change (which will make docker work, but causes the git working directory to become filthy):

```
chmod a+rwx -R canvas-lms
```

If your distro is equipped with selinux, make sure it is not interfering.

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
