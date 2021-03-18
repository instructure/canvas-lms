#!/bin/bash

set -e
source script/common.sh
source script/common/canvas/build_helpers.sh

trap '_canvas_lms_telemetry_report_status' ERR EXIT
SCRIPT_NAME=$0

_canvas_lms_opt_in_telemetry "$SCRIPT_NAME"

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

# docker-compose version 1.20.0 introduced build-arg that we use for linux
DOCKER_COMPOSE_MIN_VERSION='1.20.0'
DOCKER='y'

if [[ $OS == 'Darwin' ]]; then
  #docker-compose is checked separately
  dependencies='docker docker-machine dinghy'
elif [[ $OS == 'Linux' ]]; then
  #when more dependencies get added, modify Linux install output below
  #docker-compose is checked separately
  dependencies='dory'
else
  echo 'This script only supports MacOS and Linux :('
  exit 1
fi

function check_dependencies {
  local packages=()
  #check for proper docker-compose version
  if ! check_docker_compose_version; then
    message "docker-compose $DOCKER_COMPOSE_MIN_VERSION or higher is required."
    printf "\tPlease see %s for installation instructions.\n" "https://docs.docker.com/compose/install/"
    packages+=("docker-compose")
    docker_missing=1
  fi
  #check for required packages installed
  for package in $dependencies; do
    if ! installed "$package"; then
      packages+=("$package")
    fi
  done
  #if missing packages, print missing packages with install assistance.
  if [[ ${#packages[@]} -gt 0 ]]; then
    #when more dependencies get added, modify this output to include them.
    if [[ $OS == 'Linux' ]];then
      if [[ "${packages[*]}" =~ "dory" ]];then
        message "Some additional dependencies need to be installed for your OS."
        printf "\tCanvas recommends using dory for a reverse proxy allowing you to
\taccess canvas at http://canvas.docker. Detailed instructions
\tare available at https://github.com/FreedomBen/dory.
\tIf you want to install it, run 'gem install dory' then rerun this script.\n"
        [[ ${docker_missing:-0} == 1 ]] || prompt 'Would you like to skip dory? [y/n]' skip_dory
        [[ ${skip_dory:-n} != 'y' ]] || return 0
      fi
    elif [[ $OS == 'Darwin' ]];then
      message "Some additional dependencies need to be installed for your OS."
      printf -v joined '%s,' "${packages[@]}"
      echo "Please install ${joined%,}."
      printf "\tTry: %s %s\n" "$install" "${packages[*]}"
    else
      echo 'This script only supports MacOS and Linux :('
      exit 1
    fi
    printf "\nOnce all dependencies are installed, rerun this script.\n"
    exit 1
  fi
}

function check_docker_compose_version {
  if ! installed "docker-compose"; then
    return 1
  fi
  compose_version=$(eval docker-compose --version |grep -oE "[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+")
  if (( $(echo "$compose_version $DOCKER_COMPOSE_MIN_VERSION" | awk '{print ($1 < $2)}') )); then
    return 1
  fi
}

function setup_docker_environment {
  check_dependencies
  if [[ $OS == 'Darwin' ]]; then
    . script/common/os/mac_setup.sh
  elif [[ $OS == 'Linux' ]]; then
    . script/common/os/linux_setup.sh
  fi
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

   Running Selenium tests:

    add docker-compose/selenium.override.yml in the .env file
      echo ':docker-compose/selenium.override.yml' >> .env

    build the selenium container
      docker-compose build selenium-chrome

    run selenium
      docker-compose run --rm web bundle exec rspec spec/selenium

    Virtual network remote desktop sharing to selenium container
      for Firefox:
        $ open vnc://secret:secret@seleniumff.docker
      for chrome:
        $ open vnc://secret:secret@seleniumch.docker:5901

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
message 'Now we can set up Canvas!'
copy_docker_config
setup_docker_compose_override
build_images
check_gemfile
build_assets
create_db
display_next_steps
