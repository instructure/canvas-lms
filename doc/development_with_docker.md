# Using Docker for Canvas Development

You can use Docker in your development environment for a more seamless
way to get started developing Canvas.

## Getting Started

### Dependencies

On OS X, make sure you have the following installed:

#### VMWare Fusion

Preferred over VirtualBox for performance reasons.

#### Vagrant (with VMWare Fusion plugin)

Required for Dinghy to work with VMWare Fusion.

#### Dinghy

```
$ brew install https://github.com/codekitchen/dinghy/raw/latest/dinghy.rb
$ dinghy up --memory=4096 --cpus=4 --provider=vmware_fusion --proxy
```

Type `docker ps` in your terminal to make sure your Docker environment
is happy.

Dinghy currently requires OS X Yosemite.

#### Docker-Compose

```
$ brew install docker-compose --without-boot2docker
```

### Bootstrapping

With those dependencies installed, go to your Canvas directory and run
the following:

(this will take awhile as containers are built and downloaded.)

```
$ docker-compose run --rm web bundle install
$ docker-compose run --rm web npm install
```

The `docker-compose/config` directory has some config files already set up to use
the linked containers supplied by config. You can just copy them to
`config/`:

```
$ cp docker-compose/config/* config/
```

Get your database set up and assets built:

```
$ docker-compose run --rm web bundle exec rake db:create
$ docker-compose run --rm web bundle exec rake db:initial_setup
$ docker-compose run --rm web bundle exec rake canvas:compile_assets
$ docker-compose up
```

Now you can open Canvas at http://canvas.docker/


## Normal Usage

Normally you can just start everything with `docker-compose up`, and
access Canvas at http://canvas.docker/.

After pulling new code, you'll probably want to run migrations and
update assets:

```
$ docker-compose run --rm web bundle exec rake db:migrate
$ docker-compose run --rm web bundle exec rake canvas:compile_assets
```

Changes you're making are not showing up? See the Caveats section below.
Ctrl-C your `docker-compose up` window and restart.


## Running tests

```
$ docker-compose run --rm web bundle exec rspec spec
```

### Selenium

When selenium tests run, you can open a vnc window to the container
running firefox with:

```
$ open vnc://secret:secret@$(docker-compose ps | grep canvaslms_selenium_ | awk '{print $1}').docker/
```


## Caveats

Filesystem notification events don't get propagated to your docker
images, so spring doesn't know to reload classes and guard doesn't work
well. (It tries to poll, but there are so many files to poll for
changes, it can take awhile). Until we can figure out how to remedy,
you'll be stopping/starting for awhile to restart services.

See https://github.com/codekitchen/dinghy/issues/9 to track progress on
getting inotify events into the docker containers with Dinghy.
