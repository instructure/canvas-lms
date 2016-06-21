# Using Docker for Canvas Development

You can use Docker in your development environment for a more seamless
way to get started developing Canvas.

## Getting Started

### Dependencies

#### OS X

On OS X, make sure you have the following installed:

##### VMWare Fusion

Preferred over VirtualBox for performance reasons. (although Virtualbox 5 is
pretty close, about 90% of VMWare fusion in basic testing)

##### Dinghy

You'll want to walk through https://github.com/codekitchen/dinghy#install, but
when you run create, you may want to increase the system resources you give the
VM, like so:

```
$ dinghy create --memory=4096 --cpus=4 --provider=vmware_fusion
```

Type `docker ps` in your terminal to make sure your Docker environment
is happy.

Dinghy currently requires OS X Yosemite. Make sure you're using the most recent
Dinghy release, or else you'll probably have a bad time.

#### Linux

In Linux you can run docker natively, as long as you are using
a 64-bit kernel that is version 3.10 or higher.

##### Install the package

###### Arch Linux

```
$ pacman -S docker
```

###### Fedora

```
$ dnf install docker
```

###### Ubuntu

```
$ apt-get install docker.io
```

##### Start and optionally enable the docker service

In order to use docker, the docker service must be running.  You can start the
service using systemd:

```
systemctl start docker.service
```

You can optionally enable the docker service, which will cause it to
start automatically at boot time:

```
systemctl enable docker.service
```

##### Avoid requiring sudo to run the docker command (optional)

Because docker itelf runs with root privileges, you must be root
in order to command it.  Unfortunately, this is very
inconvenient and super annoying.  Fortunately, there is an elegant
work-around that simply involves creating a 'docker' group and
adding any users to that group that should have permission to
run docker.  First, add the docker group:

```
groupadd docker
```

Now add your user to that group:

```
usermod -a -G docker $(whoami)
```

Now you can run the docker command without root or sudo.
Note that you _will_ need to log out and back in for the group
addition to take effect.

NOTE: Adding non-privileged users to the docker group can be
a security risk.  Don't add users to this group that shouldn't
have root privileges.  Dev responsibly my friends.

#### Docker-Compose

##### OS X

```
$ brew install docker-compose --without-boot2docker
```

##### Linux

###### Arch Linux

Install docker-compose from the AUR using your preferred method.  For example with aura:

```
aura -A docker-compose
```

###### Fedora

In Fedora 22 and later, docker-compose is in the repos:

```
$ dnf install docker-compose
```

###### Ubuntu and others

If you have [python pip](https://en.wikipedia.org/wiki/Pip_(package_manager)) installed, you can use it to install docker-compose:

```
$ pip install docker-compose
```

### Bootstrapping

#### In a hurry?
These commands should get you going?

```bash
cp docker-compose/config/* config/
docker-compose run --rm web script/docker_first_time_build.sh
```

#### Not in a hurry. Or I want to see whats happening
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

If on OS X and using dinghy, you can now open Canvas at http://canvas.docker/.
If on Linux, canvas is listening and available on localhost port 3000 (http://localhost:3000)

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

## Debugging

A byebug server is running in development mode on the web and job containers
to allow you to remotely control any sessions where `byebug` has yielded
execution. To use it, you will need to enable `REMOTE_DEBUGGING_ENABLED` in your
`docker-compose.override.yml` file in your app's root directory. If you don't have
this file, you will need to create it and add the following:

```
web: &WEB
  environment:
    REMOTE_DEBUGGING_ENABLED: 'true'
```

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

## Cassandra

If you're using the analytics package, you'll also need Cassandra. The
Cassandra configuration is commented out in the docker-compose file; uncomment
it and also uncomment the Cassandra configuration in cassandra.yml. Also follow
the directions in cassandra.yml.example.

## Email

Email is often sent through background jobs if you spin up the `jobs` container.
If you would like to test or preview any notifications, simply trigger the email
through it's normal actions, and it should immediately show up in the emulated
webmail inbox available here: http://mail.canvas.docker/

## Running tests

```
$ docker-compose run --rm web bundle exec rspec spec
```

### Selenium

The container used to run the selenium browser is only started when spinning up
all docker-compose containers, or when specified explicitly. The selenium
container needs to be started before running any specs that require selenium.

```sh
docker-compose up selenium
```

With the container running, you should be able to open a VNC session:

```sh
open vnc://secret:secret@selenium.docker/
```

Now just run your choice of selenium specs:

```sh
docker-compose run --rm web bundle exec rspec spec/selenium/dashboard_spec.rb
```

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