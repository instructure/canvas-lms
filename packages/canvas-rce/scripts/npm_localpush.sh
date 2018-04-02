#!/usr/bin/env bash
# this script will "publish" canvas-rce to a file location
# specified by the user. it allows for remote copying and
# even docker machine copying

CANVASLMS_VOLUME=canvaslms_tmp

print_help () {
  echo "Usage: ${0} -f file_package -t target_dir [-d docker_machine]
    -d docker_machine specifies a copy to a docker machine using the
      docker-machine scp command.
    -t refers to the local directory to put the package in unless -d
      is specified. in that case it refers to the directory on the
      docker-machine to scp to"
}

get_canvasvolume_mountpoint () {
  docker volume inspect ${CANVASLMS_VOLUME} | grep "\"Mountpoint\":" | sed "s/.*\": \"\(.*\)\",/\1/"
}

local_copy () {
  package_file=${1}
  target_dir=${2}
  eval "tar -xf ${package_file} -C ${target_dir} -s /package\//g"
}


# docker volume inspect canvaslms_tmp | grep "\"Mountpoint\":" | sed "s/.*\": \"\(.*\)\",/\1/"
# sudo -i ls -al /mnt/sda1/var/lib/docker/volumes/canvaslms_tmp/_data
# docker_copy () copies the canvas-rce to the specified docker_machine's /tmp
# dir and then moves it into the volume's mount point so it can be accessed
# by canvas in the package.json. 
docker_copy () {
  package_file=${1}
  target_dir=${2}
  docker_machine=${3}
  volume_mountpt=$(get_canvasvolume_mountpoint)
  bn=$(basename "${target_dir}")
  tmp_dir=`mktemp -d -t ${bn}`
  canvas_rce_dir="${tmp_dir}/${bn}"
  mkdir ${canvas_rce_dir}
  echo "extracting tar file ${package_file} to ${canvas_rce_dir}"
  tar -xf ${package_file} -C "${canvas_rce_dir}" -s /package\//g > /dev/null
  docker-machine ssh ${docker_machine} "if [ ! -d \"${target_dir}\" ]; then mkdir \"${target_dir}\" ; fi" # create tmp target dir
  docker-machine ssh ${docker_machine} "sudo -i rm -Rf ${volume_mountpt}/${bn}" # remove target volume directory
  echo "copying to docker-machine: ${docker_machine}:${target_dir}..."
  docker-machine scp -r "${canvas_rce_dir}/." ${docker_machine}:"${target_dir}/"
  echo "copying to shared volume on docker-machine: ${volume_mountpt}"
  docker-machine ssh ${docker_machine} "sudo -i mv ${target_dir} ${volume_mountpt}"
  rm -Rf "${tmp_dir}"
}

FILE_PACKAGE=
TARGET_DIR=
DOCKER_MACHINE=

while getopts f:t:d: opt; do
  case "${opt}" in
  f)
    FILE_PACKAGE=$OPTARG ;;
  t)
    TARGET_DIR=$OPTARG ;;
  d)
    DOCKER_MACHINE=$OPTARG ;;
  [?]) print_help
    exit 1;;
  esac
done
shift $((OPTIND-1))

if [ "${FILE_PACKAGE}" == "" -o "${TARGET_DIR}" == "" ]; then
  print_help
  exit 1
fi

if [ "${DOCKER_MACHINE}" == "" ]; then
  local_copy ${FILE_PACKAGE} ${TARGET_DIR}
else
  docker_copy ${FILE_PACKAGE} ${TARGET_DIR} ${DOCKER_MACHINE}
fi
echo "done!"