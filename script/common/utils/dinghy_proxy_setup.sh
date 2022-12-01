#!/bin/bash
source script/common/utils/common.sh

function setup_dinghy_proxy {
  DOMAIN_TLD="docker"

  while ! [ -z "$1" ]; do
    case $1 in
      --domain-tld)
        shift
        DOMAIN_TLD=$1
        ;;
      *)
        echo "Unrecognized option: $1"
        return 1
        ;;
    esac
    shift
  done

  if [[ "$(docker ps -aq --filter ancestor=codekitchen/dinghy-http-proxy)" == "" ]]; then
    docker run -d --restart=always \
    -v /var/run/docker.sock:/tmp/docker.sock:ro \
    -v ~/.dinghy/certs:/etc/nginx/certs \
    -p 80:80 -p 443:443 -p 19322:19322/udp \
    -e DNS_IP=192.168.42.42  -e CONTAINER_NAME=http-proxy -e DOMAIN_TLD=$DOMAIN_TLD \
    --name http-proxy \
    codekitchen/dinghy-http-proxy

    sudo mkdir -p /etc/resolver

    echo 'nameserver 192.168.42.42' | sudo tee /etc/resolver/$DOMAIN_TLD > /dev/null
    echo 'port 19322' | sudo tee -a /etc/resolver/$DOMAIN_TLD > /dev/null

    if [[ ! -f /Library/LaunchDaemons/com.user.lo0-loopback.plist ]]; then
      message "There's no plist for the loopback. Creating plist file"
      create_plist_for_restart_persistence
      if [[ "$(loopback_ip_exists)" != "" ]] ; then
        message "plist file works!"
      else
        message "Your plist file failed to add the loopback. " \
           "We will try the rest of the install but it may fail"
      fi
    else
      CURRENT_IP_VALUE=$(cat /Library/LaunchDaemons/com.user.lo0-loopback.plist | grep -A 1 '<string>alias' | tail -n 1 | sed 's/<[\/]*string>//g'| sed 's/^ *//')
      if [[ "$(loopback_ip_exists)" != "" ]]  && [[ $CURRENT_IP_VALUE =~ "192.168.42.42" ]]; then
        message "Loopback interface is set and your plist is okay!"
      else
        message "The value currently set in your plist is ${CURRENT_IP_VALUE}\n" \
           "which will affect how containers communicate outside of canvas. Now updating the file"
        sudo launchctl unload /Library/LaunchDaemons/com.user.lo0-loopback.plist
        create_plist_for_restart_persistence
        sleep 5
        if [[ "$(loopback_ip_exists)" == "" ]] ; then
          warning_message "Updating plist and adding to interface failed \n" \
            "Setting manually but will not persist between reboots"
          sudo ifconfig lo0 alias 192.168.42.42
        fi
      fi
    fi
  fi
}

function loopback_ip_exists {
  echo "$(ifconfig lo0 | grep 'inet 192.168.42.42')"
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

function create_plist_for_restart_persistence () {
  PLIST_FOR_LOOPBACK=$(cat << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC -//Apple Computer//DTD PLIST 1.0//EN http://www.apple.com/DTDs/PropertyList-1.0.dtd >
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.user.lo0-loopback</string>
  <key>ProgramArguments</key>
  <array>
    <string>/sbin/ifconfig</string>
    <string>lo0</string>
    <string>alias</string>
    <string>192.168.42.42</string>
  </array>
  <key>RunAtLoad</key> <true/>
  <key>Nice</key>
  <integer>10</integer>
  <key>KeepAlive</key>
  <false/>
  <key>AbandonProcessGroup</key>
  <true/>
  <key>StandardErrorPath</key>
  <string>/var/log/loopback-alias.log</string>
  <key>StandardOutPath</key>
  <string>/var/log/loopback-alias.log</string>
</dict>
</plist>
EOF
)
  echo "${PLIST_FOR_LOOPBACK}" | sudo tee /Library/LaunchDaemons/com.user.lo0-loopback.plist > /dev/null
  chmod 0644 /Library/LaunchDaemons/com.user.lo0-loopback.plist
  chown root:wheel /Library/LaunchDaemons/com.user.lo0-loopback.plist
  sudo launchctl load /Library/LaunchDaemons/com.user.lo0-loopback.plist
}
