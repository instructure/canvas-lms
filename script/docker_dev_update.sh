#!/bin/bash -e

usage () {
  echo "usage: $0 [-f] [-h] [-n phase]"
}

bad_usage () {
  usage
  exit 1
}

while getopts ":fhn:" opt
do
  case $opt in
    n )
      case $OPTARG in
        build )
          SKIP_BUILD=true;;
        code )
          SKIP_CODE=true;;
        * )
          bad_usage;;
      esac
      echo "Skipping $OPTARG";;
    f )
      FORCE=yes;;
    h )
      usage;;
    * )
      echo "Sorry, -$OPTARG is not a valid option!"
      bad_usage;;
  esac
done

if [[ -z "$FORCE" && "$(docker-compose ps | wc -l)" -gt 2 ]] ; then
  echo "You should probably stop services before running this command"
  echo "(use -f to skip this check)"
  exit 1
fi

[[ -z "$SKIP_CODE" ]] && ./script/canvas_update -n data
[[ -z "$SKIP_BUILD" ]] && docker-compose build --pull
if [[ -z "$SKIP_BUILD" ]] ; then
  # assets are currently compiled during dc build --pull
  docker-compose run --rm web ./script/canvas_update -n code -n assets
else
  docker-compose run --rm web ./script/canvas_update -n code
fi
