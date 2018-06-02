#!/usr/bin/env bash
# this will look at the version in package.json and rev it for local distro
# example: take the version "1.2.3-aaaa" it modifies the package.json with
# version "1.2.4-local"

get_package_version () {
  rce_version=`grep \"version\": package.json | sed "s/.*://" | sed "s/[\", ]//g"`
  echo ${rce_version}
}

rev_package_version () {
  rce_version=${1}
  vers_pre=`echo ${rce_version} | sed "s/\.[0-9]*[-]*[a-zA-Z]*$//"`
  vers_rev=`echo ${rce_version} | sed "s/\.//" | sed "s/^.*.\.//" | sed "s/-.*//"`
  ((vers_rev++))
  new_ver="${vers_pre}.${vers_rev}-local"
  echo ${new_ver}
}

modify_package_version () {
  rce_version=${1}
  new_ver=${rce_version}
  if [[ ${rce_version} =~ "-local" ]]; then
    read -p "do you want to skip versioning ${rce_version}? (y/n) " -n 1 -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      new_ver=$(rev_package_version ${rce_version})
    else
      return 1
    fi
  else
    new_ver=$(rev_package_version ${rce_version})
  fi
  echo ${new_ver}
}

update_package_json () {
  ver=${1}
  sed -i ".bki" "s/\(\"version\":\).*/\1 \"${ver}\",/" package.json
  rm -f package.json.bki
}

rce_version=$(get_package_version)
new_rce_version=$(modify_package_version ${rce_version})
if [ "${?}" == "0" ]; then
  rce_version=${new_rce_version}
fi
update_package_json ${rce_version}