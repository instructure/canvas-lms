#!/bin/bash
#
# This assumes "pulsar" is the name
# of the container we're interacting with,
# which is a safe assumption for the test/build
# environments
ADMIN_URL=http://pulsar:8080/

# give pulsar a chance to wake up
sleep 20

# These commands are necessary to create the tenants
# and namespaces for canvas operations.  You can run them in
# this order within the pulsar container to get your pulsar
# broker into an appropriate state for handling AUA traffic.
bin/pulsar-admin --admin-url $ADMIN_URL tenants create canvas
# the "test-only" namespace is provided to set an example
# of how to configure a namespace and for using in tests
# of the message bus integration.  In general you probably
# want to create a different namespace for each usecase within
# the application.
bin/pulsar-admin --admin-url $ADMIN_URL namespaces create canvas/test-only
bin/pulsar-admin --admin-url $ADMIN_URL namespaces set-retention --size 5M --time 5m canvas/test-only