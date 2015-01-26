# Vagrant for Canvas

Vagrant is an easy way to spin up a development VM running Canvas.

## Prerequisites

There are a few prerequisites to meet before you can start.

* [Virtualbox](https://docs.vagrantup.com/v2/provisioning/basic_usage.html)
* [Vagrant](https://www.vagrantup.com/)
  * Vagrant plugin: [vagrant-hostsupdater](https://github.com/cogitatio/vagrant-hostsupdater)
* [Ansible](http://www.ansible.com/home)

You can install all of these individually using their GUI installer, or you can use the command line:

```bash
# install homebrew if you haven't already
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# install brew/cask
brew install caskroom/cask/brew-cask

# install virtualbox
brew cask install virtualbox

# install vagrant and plugin(s)
brew cask install vagrant
vagrant plugin install vagrant-hostsupdater

# install ansible
brew install ansible
```

## Optional (but recommended) setup

During `vagrant up` and `vagrant halt`, vagrant will attempt to modify your /etc/hosts and /etc/exports files with sudo. This will prompt you for your administrator password. This is annoying. Add the following to the bottom of your /etc/sudoers file (use `sudo visudo`, don't edit the file directly):

```
# Vagrant
Cmnd_Alias VAGRANT_EXPORTS_ADD = /usr/bin/tee -a /etc/exports
Cmnd_Alias VAGRANT_NFSD = /sbin/nfsd restart
Cmnd_Alias VAGRANT_EXPORTS_REMOVE = /usr/bin/sed
Cmnd_Alias VAGRANT_HOSTSUPDATER_ADD = /bin/sh -c echo "*" >> /etc/hosts
Cmnd_Alias VAGRANT_HOSTSUPDATER_REMOVE = /usr/bin/sed -i -e /*/ d /etc/hosts
%admin ALL=(root) NOPASSWD: VAGRANT_EXPORTS_ADD, VAGRANT_NFSD, VAGRANT_EXPORTS_REMOVE, VAGRANT_HOSTSUPDATER_ADD, VAGRANT_HOSTSUPDATER_REMOVE
```

## TL;DR

```
cd /path/to/your/canvas/repository
vagrant up
```

Go grab lunch. When you come back, go to http://canvas.dev in your browser. Type `vagrant ssh` from within your repo directory to ssh to the VM.

## What's going on?

When you type `vagrant up` for the first time, the following things happen:

### Initial boot

* Vagrant downloads a "base box". In this case, it's a Ubuntu Trusty 14.04.1 LTS image, slightly customized to change the `vagrant` user's UID to 501 so that NFS mounts from a Mac work better.
* Vagrant tells Virtualbox how to configure the VM (number of CPUs and memory, network settings, etc).
* Vagrant modifies your local /etc/exports file to export your current directory (e.g. your Canvas repository) over NFS
* Vagrant modifies your /etc/hosts file to point the VM's IP address at `canvas.dev`
* Vagrant boots the VM

### Provisioning

After the VM has booted, Vagrant starts the provisioning step. For details on what provisioning entails, see the [Vagrant docs](https://docs.vagrantup.com/v2/provisioning/basic_usage.html). In our case, we're using Ansible for provisioning, because it was far easier than getting Puppet to work. Ideally we'd use Puppet because Ansible has a host-side dependency, while Puppet doesn't.

Ansible uses "playbooks" for provisioning. These are all located in the `./provision` directory. Generally, the following happens during the provisioning phase:

* Dependencies are installed
* Bundler is installed
* Apache is installed and configured with a template config file
* Passenger is installed and configured with a template config file
* Postgres is installed and the Canvas databases are created
* Canvas-specific tasks run:
  * bundle install
  * npm install
  * config files are copied
  * compile assets
  * initial db setup
  * db migrate
  * db load notifications
  * symlink canvas_init script and start at boot

Finally, after the Ansible provisioning is complete, a shell script provisioner runs. This restarts both delayed jobs and apache. This is mostly for subsequent runs of `vagrant up` -- apache and delayed jobs are set to run at boot, but because NFS gets mounted after the init.d scripts run, they need to be bounced.

At this point, you now have a generic Canvas installation with a fresh, empty database. You should be able to visit [http://canvas.dev] in your browser and log in as the admin user (vagrant@localhost / vagrant). You should also be able to ssh to the VM by typing `vagrant ssh` from within your Canvas repo directory.

## Using your VM

Vagrant mounts your canvas repo's working directory over NFS at /vagrant on the VM. You can edit code on your local workstation in whatever editor or IDE you like, or you can ssh to the VM (`vagrant ssh`) and edit there with vim.

The vagrant VM is configured to run Canvas in development mode. In development mode, classes are reloaded on every HTTP request; while this is slow, it means that you don't need to restart the server after making a change. If you want to run in production mode; edit `/etc/apache2/sites-available/canvas.conf` (on the VM) and change the RAILS_ENV variable to `production`. Both production and development modes point at the same database.

If you need to restart passenger, you can `touch tmp/restart.txt` (which you can do from your local machine or the VM) or you can restart Apache (`sudo service apache2 restart` on the VM).

## Upgrading Canvas

If you upgade the Canvas code, you'll need to rerun some of the provisioning steps (e.g. bundle install, compile_assets, db:migrate). The easiest way to do this is to run `vagrant provision` from your local machine. This will re-run the provisioning steps that happened the first time you ran `vagrant up`. Note that it will delete `vendor/bundle` and `Gemfile.lock` prior to re-running `bundle install`. It will not re-run the initial DB setup unless `/home/vagrant/CanvasDBSetupDone` is not present (this file gets created after the initial db setup runs the first time).

You can, of course, just ssh to the VM and run the normal upgrade steps yourself.

## Git Excludes

Running `vagrant up` and some of the provisioning steps creates some files that should be ignored:

* `.vagrant`
* `vendor/bundle`
* `/vendor/plugins/*/public/*/compiled/`

Editing the Canvas `.gitignore` file often causes conflicts, so instead you should do one of the following:

### Create a global ignore file

You can create a global ignore file that will apply to all git repos on your local machine. This is a good place to put things like .DS_Store files, the .vagrant directory, etc. See [here](https://help.github.com/articles/ignoring-files/#create-a-global-gitignore) for instructions on creating a global ignore file.

### Add the exludes to .git/info/excludes

You can add the exluded files to `.git/info/excludes` (within the repo directory). These excludes are confined to that specific repo and are not pushed to any git remotes, so you will need to re-add them if you clone the repo elsewhere.
