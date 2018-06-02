#!/usr/bin/env bash
# does a local build, revision, and publish to file system or
# docker-machine of this revision of canvas-rce

print_help () {
  script_name=$(basename ${0})
  echo "Usage: ${script_name} -t target_dir [-d docker_machine]
    -t target_dir specifies the target dir to publish the module to.
       it's either a local directory or a directory on a docker_machine
    -d if copying to a docker machine, specify the name of the docker
       machine here param"
}

TARGET_DIR=
DOCKER_MACHINE=

while getopts t:d: opt; do
  case "${opt}" in
  t) TARGET_DIR=$OPTARG ;;
  d) DOCKER_MACHINE=$OPTARG ;;
  [?]) print_help; exit 1 ;;
  esac
done
shift $((OPTIND-1))

if [ "${TARGET_DIR}" == "" ]; then
  print_help
  exit 1
fi

scripts/npm_localrev.sh
echo -n "npm pack (will take a while)..."
PACKAGE_FILE=$(scripts/npmlocal_build.sh)
opts="-t ${TARGET_DIR} -f ${PACKAGE_FILE}"
if [ "${DOCKER_MACHINE}" != "" ]; then
  opts="${opts} -d ${DOCKER_MACHINE}"
fi
echo "running scripts/npm_localpush.sh ${opts}"
scripts/npm_localpush.sh ${opts}
