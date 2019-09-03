#!/bin/bash
bash_src_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
join_src_path="$( cd $bash_src_path; cd ../../ && pwd )"
echo "Setting up Join development environment at: $join_src_path"

vboxmanage --version &> /dev/null || { echo >&2 "VirtualBox not installed.  Please install it first"; exit 1; }
vboxmanage list extpacks &> /dev/null || { echo >&2 "VirtualBox Extension pack not installed.  Please install it first"; exit 1; }

if [ "$(uname)" == "Darwin" ]; then
  # OS X platform
  echo "Setting up Docker VM for Mac"

  if ! dinghy version &> /dev/null; then
    echo "Installing dinghy"
    git clone https://github.com/codekitchen/dinghy.git ../dinghy
    if [ $? -ne 0 ]
    then
     echo "Failed cloning dinghy source code"
     exit 1;
    fi
    cd ../dinghy
    brew update || { echo >&2 "Error: brew update failed!"; exit 1; }

    brew tap codekitchen/dinghy
    brew install dinghy
    # TODO: there is a bug in the stable dinghy that prevents the http proxy from working.  Using master to fix it.
    # See: https://github.com/codekitchen/dinghy/issues/135
    # Revert to stable version once it's fixed there.
    #brew install --HEAD dinghy
    if [ $? -ne 0 ]
    then
     echo "Failed installing dinghy to $(pwd)"
     exit 1;
    fi
    brew install docker docker-machine || { echo >&2 "Error: brew install docker docker-machine failed!"; exit 1; }

    dingyoutput="$(dinghy create --memory=4096 --cpus=4 --provider=virtualbox)"
    if [ $? -ne 0 ]
    then
     echo "Failed creating dinghy VM: dinghy create --memory=4096 --cpus=4 --provider=virtualbox"
     exit 1;
    fi

    # TODO!!! grab the ENV variables output by dinghy create and add them to .bashrc
    # e.g. 
    # export DOCKER_HOST=tcp://192.168.99.100:2376
    # export DOCKER_CERT_PATH=/Users/sadleb/.docker/machine/machines/dinghy
    # export DOCKER_TLS_VERIFY=1
    # export DOCKER_MACHINE_NAME=dinghy

    read response $'Please add the above ENV variables to your ~/.bashrc and hit Enter'
    source ~/.bashrc

    echo "Installed dinghy to $(pwd)"
  fi

  dinghy up || { echo >&2 "Error: dinghy up failed."; exit 1; }
  docker ps &> /dev/null || { echo >&2 "Error: somethings wrong with docker.  Make sure this command lists your containers: docker ps"; exit 1; }

  if ! docker-compose --version &> /dev/null; then
    echo "Installing docker-compose"
    brew install docker-compose --without-boot2docker || { echo >&2 "Error: brew install docker-compose --without-boot2docker failed!"; exit 1; }
  fi

  cd $join_src_path
  if [ ! -e .env ]; then
    echo "Error: No .env file found.  Make sure that exists by copying env.sample and editing it before running the Docker VM."
    exit 1;
  fi

  # Set the ROOT_DOMAIN to be join.docker
  cat .env | sed 's/ROOT_DOMAIN=.*$/ROOT_DOMAIN=join.docker/' > tmp.env && mv tmp.env .env

  cp -a docker-compose/config/* config/
  cp -a docker-compose/db/seeds.rb db/
  docker-compose build --no-cache || { echo >&2 "Error: docker-compose build --no-cache failed."; exit 1; }
  docker-compose up -d || { echo >&2 "Error: docker-compose up failed. A possible cause is that files use Windows newlines \(CRLF\). Check that all files in the docker-compose directory use Unix newlines \(LF\)."; exit 1; }

  #####
  #TODO: pull staging database instead of using the follow rake commands
  ####
  docker-compose run --rm web /bin/bash -c "bundle exec rake db:create; bundle exec rake db:migrate; bundle exec rake db:seed;"
  if [ $? -ne 0 ]
  then
     echo "Error: could not setup Join database."
     exit 1;
  fi

  open http://join.docker/
  echo "It'll say Bad Gateway.  Wait a couple of minutes and refresh.  If it doesn't work, ensure the join web container is running using docker ps"

elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
  # GNU/Linux platform
  echo "ERROR: setup script not written for Linux.  Please write it!"
  exit 1;
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
  # Windows NT platform
  echo "ERROR: setup script not written for Windows.  Please write it!"
  exit 1;
fi

echo "Setup complete!  Please start a new shell to get your environment variables"
