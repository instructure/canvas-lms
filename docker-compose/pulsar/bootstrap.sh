#!/bin/bash

# This assumes "pulsar" is the name
# of the container we're interacting with,
# which is a safe assumption for the test/build
# environments
ADMIN_URL=http://pulsar:8080/
DISPATCHER_URL=pulsar://pulsar:6650/
PULSAR_TENANT=canvas

function check_ready {
  bin/pulsar-client --url $DISPATCHER_URL produce my-topic --messages "hello-pulsar"
  DISPATCHER_STATUS=$?
  if [ $DISPATCHER_STATUS -eq 0 ]; then
    echo "dispatcher ready..."
    bin/pulsar-admin --admin-url $ADMIN_URL tenants list
    ADMIN_STATUS=$?
    if [ $ADMIN_STATUS -eq 0 ]; then
      return 0
    fi
    echo "admin NOT ready..."
  fi
  return 1
}

CHECK_COUNT=0
until check_ready; do
  echo "Waiting for pulsar to be ready ... $CHECK_COUNT ... "
  sleep 3
  CHECK_COUNT=$((CHECK_COUNT+1))
  if [ "$CHECK_COUNT" -gt "2" ]; then
    echo ":cry: I don't think pulsar is ever going to be ready..."
    exit 1
  fi
done

echo "Pulsar is ready!"

# These commands are necessary to create the tenants
# and namespaces for canvas operations.  You can run them in
# this order within the pulsar container to get your pulsar
# broker into an appropriate state for handling AUA traffic.
echo "creating tenant..."
bin/pulsar-admin --admin-url $ADMIN_URL tenants create $PULSAR_TENANT
# the "test-only" namespace is provided to set an example
# of how to configure a namespace and for using in tests
# of the message bus integration.  In general you probably
# want to create a different namespace for each usecase within
# the application.
echo "creating namespaces..."
bin/pulsar-admin --admin-url $ADMIN_URL namespaces create $PULSAR_TENANT/test-only
bin/pulsar-admin --admin-url $ADMIN_URL namespaces set-retention --size 5M --time 5m $PULSAR_TENANT/test-only
# namespaces for specific use cases within canvas that will be tested
# via integration with the message bus (both manually and in specs)
# should be added here so that they exist when you need them, kind of
# like database migrations.
bin/pulsar-admin --admin-url $ADMIN_URL namespaces create $PULSAR_TENANT/asset_user_access_log
bin/pulsar-admin --admin-url $ADMIN_URL namespaces set-retention --size 5M --time 5m $PULSAR_TENANT/asset_user_access_log

echo "PULSAR BOOTSTRAP COMPLETE, LISTING NAMESPACES:"
bin/pulsar-admin --admin-url $ADMIN_URL namespaces list $PULSAR_TENANT