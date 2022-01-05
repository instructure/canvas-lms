# The Message Bus!

Asynchronous message passing is cool again! (was it ever not? Right?)

Canvas uses Pulsar as the transport layer for messages that it wants to send
for consumption elsewhere (sometimes by our own jobs, sometimes by other apps,
could even be both).

## Why Pulsar?

In looking at what tech to use for a message bus, we looked a lot at what we were doing at Instructure and found that we had a variety of different messaging technologies with a variety of different messaging semantics.

Canvas has common use cases where SQS can be used to do a basic "work queue", and every message gets parsed by one consumer.

Sometimes we use SNS on top of that when events are still fairly ephemeral but are sent to multiple consumers. It is a really nice pattern for de-coupling applications.

However, we have other use cases where events may need to be "replayed" or retained for longer periods of time which get serviced by something like Kinesis or Kafka.

Apache Pulsar offers a way of handling all these use cases. It is a "unified" messaging platform, that builds a pub/sub system on top of a log data structure, and also is architected to make storing and retaining messages much easier than other systems (such as Kinesis/Kafka)

Although the docs aren't perfect, the [overview and concepts](https://pulsar.apache.org/docs/en/concepts-overview/) are
really good for building a mental model of how pulsar is intended to be used.

## How To Pulsar?

Canvas uses the [pulsar-client](https://github.com/instructure/pulsar-client-ruby) ruby gem, which is now
a dependency of this application, for interfacing with Pulsar.

The MessageBus library takes care of most of the configuration and auth needed to
actually integrate with a pulsar cluster.   Config reading, TLS cert management,
Vault integration to fetch an auth token, connection caching, etc.  If you
want to make canvas use pulsar in a new place, you need to do 3 things.

1) create the namespace you intend to use (see the overview and concepts above)
both in your production/testing environments ( preferably using [terraform](https://github.com/streamnative/terraform-provider-pulsar) ).

2) add that same namespace to your development environment by adding it
to the bootstrap script at docker-compose/pulsar/bootstrap.sh and
running that script (it should be idempotent, though you may
see output like "tenant already exists").

3) write code like this:

```ruby
producer = MessageBus.producer_for("my_namespace_name", "my_topic_name")
producer.send({some: "message"}.to_json)
```

and then somewhere else write code like this:

```ruby
consumer = MessageBus.consumer_for("my_namespace_name", "my_topic_name", "my_subscription_name")
msg = consumer.receive(1000)
# do something useful with msg.data
consumer.acknowledge(msg)
```

That's it.

## How to NOT Pulsar?

At the moment this integration isn't strictly required.

If you DON'T want to use pulsar, you can install your bundle "--without pulsar"
and none of the libraries you need will get installed.

Because the client gem is in it's own group, it will only get
required if you traverse a code path that includes
Bundler.require(:pulsar).

## Local Development

If you're using docker for canvas development, there is a docker-compose file for adding
a pulsar container to your swarm at docker-compose/pulsar.yml.  If you
add that file to your COMPOSE_FILE env var in .env then you'll have a
pulsar instance in "standalone" mode working with you.

You need to have the necessary tenant and namespaces created,
use the bootstrap script at `docker-compose/pulsar/bootstrap.sh`
as a guide or just execute it in the provided `pulsar-admin` container
as part of your docker-compose setup.

Your dynamic settings will need to return a value for
"pulsar.yml", you can find an example of what it should look like
in dynamic_settings.yml.example.  If you're using the docker container,
the hash should only need these entries:
```yml
development:
  private:
    pulsar.yml: |
      PULSAR_BROKER_URI: 'pulsar://pulsar:6650'
      PULSAR_TENANT: 'canvas'
test:
  private:
    pulsar.yml: |
      PULSAR_BROKER_URI: 'pulsar://pulsar:6650'
      PULSAR_TENANT: 'canvas'
```
You want the test dictionary too because otherwise canvas will skip any tests
that require pulsar to be present.

