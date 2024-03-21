# Getting Docker Setup

_*Instructure employees should use the `inst` CLI. Go [here](./../../inst-cli/doc/docker/developing_with_docker.md) for more info.*_

**Note:** this works through the details of how to set docker up manually. If
you just want to set up a Canvas development environment with a minimum of
effort, run:

```
./script/docker_dev_setup.sh
```

The script will guide you through the process of installing docker and setting
up Canvas.

Docker has lots of info getting up and running [here](https://www.docker.com/products/docker). The info below should still get you going though.

## Docker Destkop on macOS

Make sure you have the following installed:

* Docker Desktop
* Docker Compose

### Via Homebrew

```
brew install --cask docker
brew install docker-compose
```
Once the install has completed, launch Docker Desktop to finalize the setup.
Navigate to Docker Desktop preferences → Resources and set the Memory to at least 8GB.

## Linux

In Linux you can run docker natively, as long as you are using
a 64-bit kernel that is version 3.10 or higher.

### Install the package

#### Arch Linux

```
$ pacman -S docker
```

#### Fedora

```
$ dnf install docker
```

#### Ubuntu

```
$ apt-get install docker.io
```

### Start and optionally enable the docker service

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

### Avoid requiring sudo to run the docker command (optional)

Because docker itself runs with root privileges, you must be root
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

### Install dory (optional)

Many people at Instructure are using [dory](https://github.com/FreedomBen/dory)
for reverse proxy as it uses the same
proxy under the hood as dinghy which gives you maximum compatibility.
Detailed instructions are available at the
[github page](https://github.com/FreedomBen/dory), but you can
install dory with:

```
gem install dory
```

# Getting Docker Compose Setup

## OS X

Docker Compose comes bundled with Docker Desktop. There are no additional steps needed.

## Linux

### Arch Linux

Install docker-compose from the AUR using your preferred method.  For example with aura:

```
aura -A docker-compose
```

### Fedora

In Fedora 22 and later, docker-compose is in the repos:

```
$ dnf install docker-compose
```

### Ubuntu and others

If you have [python pip](https://en.wikipedia.org/wiki/Pip_(package_manager)) installed, you can use it to install docker-compose:

```
$ pip install docker-compose
```
