#!/bin/bash
set -o pipefail

source script/common.sh
source script/common/canvas/build_helpers.sh

LOG="$(pwd)/log/rebase_canvas_and_plugins.log"
FAILED_REPOS=()

trap print_results EXIT
trap "printf '\nTerminated\n' && exit 130" SIGINT

usage () {
  echo "usage:"
  printf "  --skip-canvas\t\t\t\tSkip rebasing of canvas repo.\n"
  printf "  --skip-plugins [<repo>,<repo2>,...]\tSpecify repos to skip, comma separated list.\n"
  printf "  \t\t\t\t\tOr leave blank to skip all plugins.\n"
  printf "  -h|--help\t\t\t\tDisplay usage\n\n"
}

die() {
  echo "$*" 1>&2
  usage
  exit 1
  }

while :; do
  case $1 in
    -h|-\?|--help)
      usage # Display a usage synopsis.
      exit
      ;;
    --skip-canvas)
      SKIP_CANVAS=true
      ;;
    --skip-plugins)
      if [[ "$2" ]] && [[ "$2" != --* ]]; then
        repos=$2
        IFS=',' read -r -a skip_repos <<< "$repos"
        shift
      else
        SKIP_PLUGINS=true
      fi
      ;;
    ?*)
      die 'ERROR: Unknown option: ' "$1" >&2
      ;;
    *)
      break
  esac

  shift
done

function rebase_canvas {
  echo_console_and_log "Rebasing canvas-lms on HEAD ..."
  if ! git pull --rebase origin master 2>&1 | tee -a "$LOG"; then
    FAILED_REPOS+=("canvas-lms")
  fi
  echo ""
}

function rebase_plugins {
  iterate_plugins rebase_plugin
}

function rebase_plugin {
    echo_console_and_log "Rebasing plugin $1 ..."
    if ! git pull --rebase origin master 2>&1 | tee -a "$LOG"; then
      FAILED_REPOS+=("$1")
    fi
    echo ""
}

function iterate_plugins {
  COMMAND=$1
  for dir in {gems,vendor}; do
    if [ -d "$dir/plugins" ]; then
      for plugin in $dir/plugins/*; do
        [[ "${skip_repos[*]}" =~ $(basename "$plugin") ]] && continue
        pushd "$plugin" > /dev/null
        if is_git_dir; then
          $COMMAND "$plugin"
        fi
        popd > /dev/null
      done
    fi
  done
}

# Provide array of repos to stash.
function stash_repos {
  repos=$*
  for repo in ${repos[*]}; do
    if [ "$repo" == "canvas-lms" ]; then
      echo_console_and_log "Stashing $repo"
      git stash push -m "Stashed as part of rebase_canvas_and_plugins" 2>&1 | tee -a "$LOG"
    else
      echo_console_and_log "Stashing plugin $repo"
      pushd "$repo" > /dev/null && git stash push -m "Stashed as part of rebase_canvas_and_plugins" 2>&1 | tee -a "$LOG"
      popd > /dev/null
    fi
  done
}

function stash_plugin_maybe {
  if [ -n "$(git diff --name-only)" ]; then
    stash_code+=("$1")
  fi
}

function check_for_changes {
  stash_code=()
  # check for uncommitted tracked changes
  if [[ -z "$SKIP_CANVAS" ]] && [ -n "$(git diff --name-only)" ]; then
   stash_code+=("canvas-lms")
  fi
  if [[ -z "$SKIP_PLUGINS" ]]; then
    iterate_plugins stash_plugin_maybe
  fi
  # If uncommitted changes, prompt to stash before running rebase.
  if [ ${#stash_code[@]} -gt 0 ]; then
    printf -v joined '%s, ' "${stash_code[@]}"
    message "You have uncommitted changes in ${joined%, }." | tee -a "$LOG"
    prompt "  Ok to run \"git stash push -m 'Stashed as part of rebase_canvas_and_plugins'\" for each repo above? [y/n/skip]" run_stash
    if [[ ${run_stash:-n} == 'skip' ]]; then
      printf "\nSkipping stash, attempting to rebase with uncommitted changes.\n" | tee -a "$LOG" && return
    elif [[ ${run_stash:-n} != 'y' ]]; then
      printf "\nStash or commit your changes then run this script again.\n" | tee -a "$LOG" && exit
    fi
    stash_repos "${stash_code[@]}"
  else
    echo_console_and_log "No uncommitted changes found. \o/"
  fi
}

function print_results {
  exit_code=$?
  set +e

  if [ "${#FAILED_REPOS[@]}" -gt 0 ]; then
    echo ""
    message "Something went wrong. Check ${LOG} for details." | tee -a "$LOG"
    for repo in ${FAILED_REPOS[*]}; do
      echo_console_and_log "  $repo failed to rebase cleanly!"
    done
    exit 1
  elif [ "${exit_code}" == 0 ]; then
    # if no stashing, don't print anymore.
    [[ ${run_stash:-} == 'n' ]] && exit 1
    echo ""
    echo_console_and_log "\o/ SUCCESS!"
  elif [ "${exit_code}" != 130 ]; then
    echo ""
    message "Something went wrong. Check ${LOG} for details." | tee -a "$LOG"
  fi
  exit ${exit_code}
}

ensure_in_canvas_root_directory
create_log_file
intro_message "Rebase Canvas and Plugins"
check_for_changes
[[ -n "$SKIP_CANVAS" ]] || rebase_canvas
[[ -n "$SKIP_PLUGINS" ]] || rebase_plugins
