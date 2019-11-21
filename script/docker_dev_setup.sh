#!/bin/bash

set -e

# shellcheck disable=1004
echo '
  ________  ________  ________   ___      ___ ________  ________
|\   ____\|\   __  \|\   ___  \|\  \    /  /|\   __  \|\   ____\
\ \  \___|\ \  \|\  \ \  \\ \  \ \  \  /  / | \  \|\  \ \  \___|_
 \ \  \    \ \   __  \ \  \\ \  \ \  \/  / / \ \   __  \ \_____  \
  \ \  \____\ \  \ \  \ \  \\ \  \ \    / /   \ \  \ \  \|____|\  \
   \ \_______\ \__\ \__\ \__\\ \__\ \__/ /     \ \__\ \__\____\_\  \
    \|_______|\|__|\|__|\|__| \|__|\|__|/       \|__|\|__|\_________\
                                                         \|_________|

Welcome! This script will guide you through the process of setting up a
Canvas development environment with docker and dinghy/dory.

When you git pull new changes, you can run ./scripts/docker_dev_update.sh
to bring everything up to date.'

if [[ "$USER" == 'root' ]]; then
  echo 'Please do not run this script as root!'
  echo "I'll ask for your sudo password if I need it."
  exit 1
fi

OS="$(uname)"

# Defaults
DINGHY_MEMORY='8192'
DINGHY_CPUS='4'
DINGHY_DISK='150'

function installed {
  type "$@" &> /dev/null
}

if [[ $OS == 'Darwin' ]]; then
  install='brew install'
  dependencies='docker docker-machine docker-compose dinghy'
elif [[ $OS == 'Linux' ]]; then
  install='sudo apt-get update && sudo apt-get install -y'
  dependencies='docker-compose'
else
  echo 'This script only supports MacOS and Linux :('
  exit 1
fi

BOLD="$(tput bold)"
NORMAL="$(tput sgr0)"

function message {
  echo ''
  echo "$BOLD> $*$NORMAL"
}

function prompt {
  read -r -p "$1 " "$2"
}

function confirm_command {
  prompt "OK to run '$*'? [y/n]" confirm
  [[ ${confirm:-n} == 'y' ]] || return 1
  eval "$*"
}

function install_dependencies {
  local packages=()
  for package in $dependencies; do
    installed "$package" || packages+=("$package")
  done
  [[ ${#packages[@]} -gt 0 ]] || return 0

  message "First, we need to install some dependencies."
  if [[ $OS == 'Darwin' ]]; then
    if ! installed brew; then
      echo 'We need homebrew to install dependencies, please install that first!'
      echo 'See https://brew.sh/'
      exit 1
    elif ! brew ls --versions dinghy > /dev/null; then
      brew tap codekitchen/dinghy
    fi
  elif [[ $OS == 'Linux' ]] && ! installed apt-get; then
    echo 'This script only supports Debian-based Linux (for now - contributions welcome!)'
    exit 1
  fi
  confirm_command "$install ${packages[*]}"
}

function create_dinghy_vm {
  if ! dinghy status | grep -q 'not created'; then
    existing_memory="$(docker-machine inspect --format "{{.Driver.Memory}}" "${DOCKER_MACHINE_NAME}")"
    if [[ "$existing_memory" -lt "$DINGHY_MEMORY" ]]; then
      echo "
  Canvas requires at least 8GB of memory dedicated to the VM. Please recreate
  your VM with a memory value of at least ${DINGHY_MEMORY}. For Example:

      $ dinghy create --memory ${DINGHY_MEMORY}"
      exit 1
    else
      message "Using existing dinghy VM..."
      return 0
    fi
  fi

  prompt 'OK to create a dinghy VM? [y/n]' confirm
  [[ ${confirm:-n} == 'y' ]] || return 1

  if ! installed VBoxManage; then
    message 'Please install VirtualBox first!'
    return 1
  fi

  prompt "How much memory should I allocate to the VM (in MB)? [$DINGHY_MEMORY]" memory
  prompt "How many CPUs should I allocate to the VM? [$DINGHY_CPUS]" cpus
  prompt "How big should the VM's disk be (in GB)? [$DINGHY_DISK]" disk

  message "OK let's do this."
  dinghy create \
    --provider=virtualbox \
    --memory "${memory:-$DINGHY_MEMORY}" \
    --cpus "${cpus:-$DINGHY_CPUS}" \
    --disk "${disk:-$DINGHY_DISK}000"
}

function start_dinghy_vm {
  if dinghy status | grep -q 'stopped'; then
    dinghy up
  else
    message 'Looks like the dinghy VM is already running. Moving on...'
  fi
  eval "$(dinghy env)"
}

function start_docker_daemon {
  service docker status &> /dev/null && return 0
  prompt 'The docker daemon is not running. Start it? [y/n]' confirm
  [[ ${confirm:-n} == 'y' ]] || return 1
  sudo service docker start
  sleep 1 # wait for docker daemon to start
}

function setup_docker_as_nonroot {
  docker ps &> /dev/null && return 0
  message 'Setting up docker for nonroot user...'

  if ! id -Gn "$USER" | grep -q '\bdocker\b'; then
    message "Adding $USER user to docker group..."
    confirm_command "sudo usermod -aG docker $USER" || true
  fi

  message 'We need to login again to apply that change.'
  confirm_command "exec sg docker -c $0"
}

function install_dory {
  installed dory && return 0
  message 'Installing dory...'

  if ! installed gem; then
    message "You need ruby to run dory (it's a gem). Install ruby and try again."
    return 1
  fi

  prompt "Use sudo to install dory gem? You may need this if using system ruby [y/n]" use_sudo
  if [[ ${use_sudo:-n} == 'y' ]]; then
    confirm_command 'sudo gem install dory'
  else
    confirm_command 'gem install dory'
  fi
}

function start_dory {
  message 'Starting dory...'
  if dory status | grep -q 'not running'; then
    confirm_command 'dory up'
  else
    message 'Looks like dory is already running. Moving on...'
  fi
}

function setup_docker_environment {
  install_dependencies
  if [[ $OS == 'Darwin' ]]; then
    message "It looks like you're using a Mac. You'll need a dinghy VM. Let's set that up."
    create_dinghy_vm
    start_dinghy_vm
  elif [[ $OS == 'Linux' ]]; then
    message "It looks like you're using Linux. You'll need dory. Let's set that up."
    start_docker_daemon
    setup_docker_as_nonroot
    install_dory
    start_dory
  fi
  if [ -f "docker-compose.override.yml" ]; then
    message "docker-compose.override.yml exists, skipping copy of default configuration"
  else
    message "Copying default configuration from config/docker-compose.override.yml.example to docker-compose.override.yml"
    cp config/docker-compose.override.yml.example docker-compose.override.yml
  fi
}

function copy_docker_config {
  message 'Copying Canvas docker configuration...'
  confirm_command 'cp docker-compose/config/* config/' || true
}

function build_images {
  message 'Building docker images...'
  docker-compose build --pull
}

function check_gemfile {
  if [[ -e Gemfile.lock ]]; then
    message \
'For historical reasons, the Canvas Gemfile.lock is not tracked by git. We may
need to remove it before we can install gems, to prevent conflicting depencency
errors.'
    confirm_command 'rm Gemfile.lock' || true
  fi

  # Fixes 'error while trying to write to `/usr/src/app/Gemfile.lock`'
  if ! docker-compose run --no-deps --rm web touch Gemfile.lock; then
    message \
"The 'docker' user is not allowed to write to Gemfile.lock. We need write
permissions so we can install gems."
    touch Gemfile.lock
    confirm_command 'chmod a+rw Gemfile.lock' || true
  fi
}

function database_exists {
  docker-compose run --rm web \
    bundle exec rails runner 'ActiveRecord::Base.connection' &> /dev/null
}

function create_db {
  if ! docker-compose run --no-deps --rm web touch db/structure.sql; then
    message \
"The 'docker' user is not allowed to write to db/structure.sql. We need write
permissions so we can run migrations."
    touch db/structure.sql
    confirm_command 'chmod a+rw db/structure.sql' || true
  fi

  if database_exists; then
    message \
'An existing database was found.

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
This script will destroy ALL EXISTING DATA if it continues
If you want to migrate the existing database, use docker_dev_update.sh
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
    message 'About to run "bundle exec rake db:drop"'
    prompt "type NUKE in all caps: " nuked
    [[ ${nuked:-n} == 'NUKE' ]] || exit 1
    docker-compose run --rm web bundle exec rake db:drop
  fi

  message "Creating new database"
  docker-compose run --rm web \
    bundle exec rake db:create
  docker-compose run --rm web \
    bundle exec rake db:migrate
  docker-compose run --rm web \
    bundle exec rake db:initial_setup
}

function setup_canvas {
  message 'Now we can set up Canvas!'
  copy_docker_config
  build_images

  check_gemfile
  docker-compose run --rm web ./script/canvas_update -n code -n data
  create_db
  docker-compose run --rm web ./script/canvas_update -n code -n deps
}

function display_next_steps {
  message "You're good to go! Next steps:"

  # shellcheck disable=SC2016
  [[ $OS == 'Darwin' ]] && echo '
  First, run:

    eval "$(dinghy env)"

  This will set up environment variables for docker to work with the dinghy VM.'

  [[ $OS == 'Linux' ]] && echo '
  I have added your user to the docker group so you can run docker commands
  without sudo. Note that this has security implications:

  https://docs.docker.com/engine/installation/linux/linux-postinstall/

  You may need to logout and login again for this to take effect.'

  echo "
  Running Canvas:

    docker-compose up -d
    open http://canvas.docker

  Running the tests:

    docker-compose run --rm web bundle exec rspec

  I'm stuck. Where can I go for help?

    FAQ:           https://github.com/instructure/canvas-lms/wiki/FAQ
    Dev & Friends: http://instructure.github.io/
    Canvas Guides: https://guides.instructure.com/
    Vimeo channel: https://vimeo.com/canvaslms
    API docs:      https://canvas.instructure.com/doc/api/index.html
    Mailing list:  http://groups.google.com/group/canvas-lms-users
    IRC:           http://webchat.freenode.net/?channels=canvas-lms

    Please do not open a GitHub issue until you have tried asking for help on
    the mailing list or IRC - GitHub issues are for verified bugs only.
    Thanks and good luck!
  "
}

setup_docker_environment
setup_canvas
display_next_steps
