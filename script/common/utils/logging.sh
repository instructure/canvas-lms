#
# Copyright (C) 2021 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

BOLD="$(tput bold)"
NORMAL="$(tput sgr0)"

function is_logfile_enabled() {
  [[ -n "${LOG:-}" ]] && touch "$LOG"
}

function is_logfile_created() {
  [ -f "${LOG:-}" ]
}

function create_log_file {
  if ! is_logfile_created; then
    echo "" > "$LOG"
  fi
}

function echo_console_and_log {
  if is_logfile_enabled; then
    echo "$1" | tee -a "$LOG"
  else
    echo "$1"
  fi
}

# Parameter: the name of the script calling this function
function init_log_file {
  script_name="$1"
  echo "  Log file is $LOG"

  echo >>"$LOG"
  echo "-----------------------------" >>"$LOG"
  echo "$1 ($(date)):" >>"$LOG"
  echo "-----------------------------" >>"$LOG"
}

function message {
  echo_console_and_log ''
  echo_console_and_log "$BOLD> $*$NORMAL"
}

function prompt {
  read -r -p "$1 " "$2"
}

function print_missing_dependencies {
  echo "    Missing Dependencies:"
  if [[ ${#missing_packages[@]} -gt 0 ]]; then
    for dep in "${missing_packages[@]}"; do
      printf "\t%s\n" "$dep"
    done
  fi
  if [[ ${#wrong_version[@]} -gt 0 ]]; then
    printf -v joined '\t%s\n' "${wrong_version[@]}"
    echo "${joined%}"
  fi
  printf "Once all dependencies are satisfied, rerun this script.\n"
  exit 1
}

function display_next_steps {
  message "You're good to go! Next steps:"

  # shellcheck disable=SC2016
  [[ $OS == 'Darwin' ]] && (! is_mutagen) && echo '
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

    ${DOCKER_COMMAND} up -d
    open http://canvas.docker

  Running the tests:

    ${DOCKER_COMMAND} run --rm web bundle exec rspec

   Running Selenium tests:

    add docker-compose/selenium.override.yml in the .env file
      echo ':docker-compose/selenium.override.yml' >> .env

    build the selenium container
      ${DOCKER_COMMAND} build selenium-chrome

    run selenium
      ${DOCKER_COMMAND} run --rm web bundle exec rspec spec/selenium

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
