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

```
$ brew install https://github.com/codekitchen/dinghy/raw/latest/dinghy.rb
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

The container used to run the selenium browser is commented out of the
docker-compose file by default. To run selenium, just uncomment those lines,
rerun `docker-compose build`, and when you run your tests you can watch
the browser:

```
$ open vnc://secret:secret@selenium.docker/
```
