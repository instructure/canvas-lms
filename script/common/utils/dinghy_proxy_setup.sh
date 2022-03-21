#!/bin/bash
source script/common/utils/common.sh

function setup_dinghy_proxy {
  if [[ "$(docker ps -aq --filter ancestor=codekitchen/dinghy-http-proxy)" == "" ]]; then
    docker run -d --restart=always \
    -v /var/run/docker.sock:/tmp/docker.sock:ro \
    -v ~/.dinghy/certs:/etc/nginx/certs \
    -p 80:80 -p 443:443 -p 19322:19322/udp \
    -e DNS_IP=127.0.0.1 -e CONTAINER_NAME=http-proxy \
    --name http-proxy \
    codekitchen/dinghy-http-proxy

    sudo mkdir -p /etc/resolver

    echo 'nameserver 127.0.0.1' | sudo tee /etc/resolver/docker > /dev/null
    echo 'port 19322' | sudo tee -a /etc/resolver/docker > /dev/null
  fi
}

function dinghy_machine_exists {
  if installed dinghy; then
    if ! dinghy status | grep -q 'not created'; then
      warning_message "dinghy is no longer supported but was found installed!"
      return 0
    else
      warning_message "dinghy found installed but no machine created.\nYou should probably uninstall dinghy to avoid conflicts in the future."
      return 1
    fi
  fi
  return 1
}
