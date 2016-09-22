# Getting Docker Setup

Docker has lots of info getting up and running [here](https://www.docker.com/products/docker). The info below should still get you going though.

## OS X

On OS X, you can opt for [dinghy](https://github.com/codekitchen/dinghy)
or [Docker for Mac](https://docs.docker.com/docker-for-mac/).  They each have
various strengths.  If you don't know which to choose, you should
probably match your team.  We have engineers using both at Instructure
so either one is fine.

### Dinghy

Make sure you have the following installed:

* VMWare Fusion

Preferred over VirtualBox for performance reasons. (although Virtualbox 5 is
pretty close, about 90% of VMWare fusion in basic testing)

* Dinghy

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

### Docker for Mac

You can install Docker for Mac to get a very similar experience
to the native Linux experience, but from your OS X machine.

Download the [stable dmg](https://download.docker.com/mac/stable/Docker.dmg)
from the [Docker for Mac website](https://docs.docker.com/docker-for-mac/).
Or the [beta](https://download.docker.com/mac/beta/Docker.dmg) if you want to get cray.

After installing docker for Mac, you will need
[dory](https://github.com/FreedomBen/dory) for the reverse proxy
portion that is provided by dinghy.  Install with:

```
gem install dory
```

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

### Install dory (optional)

People using dinghy will have a reverse proxy that allows them to access
canvas at `http://canvas.docker`.  On Linux and Docker for Mac, you will need
to run your own reverse proxy (or access your containers via IP/port).

Many people at Instructure are using [dory](https://github.com/FreedomBen/dory)
for this as it uses the same
proxy under the hood as dinghy which gives you maximum compatibility.
Detailed instructions are available at the
[github page](https://github.com/FreedomBen/dory), but you can
install dory with:

```
gem install dory
```

# Getting Docker Compose Setup

## OS X

```
$ brew install docker-compose --without-boot2docker
```

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
