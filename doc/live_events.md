# Live Events

Canvas includes the ability to push a subset of real-time events to a
Kinesis stream, which can then be consumed for various analytics
purposes. This is not a full-fidelity feed of all changes to the
database, but a targeted set of interesting actions such as
`grade_change`, `login`, etc.

## Development and Testing

There are two components to local development:
- the kinesis stream (which can hook into the `live-events-publish` lambda)
- the subscription service and its UI (`live-events-subscriptions`, `live-events-lti`)

### Kinesis Stream

If using the docker-compose dev setup, there is a "fake kinesis" available in
docker-compose/kinesis.override.yml available for use. To start this kinesis
container run `docker compose up -d kinesis`. Once it's up, make sure you have
the `aws` cli installed, and run the following command to create a stream (with
canvas running). Keep in mind that we are running this locally so actual AWS
credentials are not needed, run the following command as you see it here:

```bash
AWS_ACCESS_KEY_ID=key AWS_SECRET_ACCESS_KEY=secret aws --endpoint-url http://kinesis.docker/ kinesis create-stream --stream-name=live-events --shard-count=1 --region=us-east-1
```

Once the stream is created, configure your Canvas to use it in your
`config/dynamic_settings.yml`. This file is a local shim for Consul. If you have
copied the example file at `config/dynamic_settings.yml.example` recently, you
should already see a live_events block and it should already be configured properly.
If you don't see a live_events block, check the example file or copy this block:

```yml
      live_events.yml: |-
        aws_endpoint: http://kinesis:4567
        kinesis_stream_name: live-events
        aws_access_key_id: key
        aws_secret_access_key_dec: secret
```

Depending on your docker networking setup, you may need to substitute either
`http://kinesis:4567`, `http://kinesis.docker`, or `http://kinesis.canvaslms.docker`
for the aws_endpoint (the first two should be equivalent).

Restart Canvas, and events should start flowing to your kinesis stream.
You can view the stream with the `tail_kinesis` tool:

```bash
docker compose run --rm web script/tail_kinesis http://kinesis:4567 live-events
```

#### Stubbing Kinesis

Instead of viewing events in the kinesis stream, you can add the `stub_kinesis`
attribute to the dynamic_settings live_events block that you configured above,
with a value of `true`. This will print live events to stdout instead of sending
them to a kinesis stream.

An easy way of accessing stdout when using dockerized Canvas is this:

```
docker compose logs -f --tail=100 <jobs|web> # whichever container you need
```

#### Connecting to local Publisher Lambda

The `live-events-publish` repo should be checked out and running locally.
This contains the publisher lambda, and other infrastructure including a local
kinesis stream. Note the url of that kinesis stream, which may look like
`http://kinesis.live-events-publish.docker:4567`.

There should already be a stream created in that container, with the name
found in `docker-compose.yml`, in the `KINESIS_LOCAL_STREAM_NAME` environment
variable. If that stream doesn't exist, create it with this `aws` command:

```bash
AWS_ACCESS_KEY_ID=ACCESS_KEY AWS_SECRET_ACCESS_KEY=SECRET_KEY aws --endpoint-url http://kinesis.live-events-publish.docker/ kinesis create-stream --stream-name=live-events-local-test-stream --shard-count=1 --region=us-east-1
```

Once the stream is created, configure your Canvas to use it in your `config/dynamic_settings.yml`.
This file is a local shim for Consul. If you have copied the example file at
`config/dynamic_settings.yml.example` recently, you should already see a live_events block.
Note that these settings differ from the example block above. If you don't see a live_events
block, check the example file or copy this block:

```yml
      live_events.yml: |-
        aws_endpoint: http://kinesis.live-events-publish.docker
        kinesis_stream_name: live-events-local-test-stream
        aws_access_key_id: ACCESS_KEY
        aws_secret_access_key_dec: SECRET_KEY
```

Restart Canvas, and events should start flowing to the kinesis stream, and to
the publisher lambda itself. You can view the stream and publisher lambda
activity by looking at the output of `docker compose up` in the `live-events-publish`
repo.

### Subscription Management

#### Connecting to local Subscription Service

The `live-events-subscriptions` repo should be checked out and running locally.
This contains the subscriptions for live events, which the publisher uses when
propagating events.

To connect Canvas with the subscription service, open `config/dynamic_settings.yml`
and make sure that the `live-events-subscription-service` prefix contains the
proper `app-host` value, which should be the url where your local subscription
service is running. Instructions for connecting on the subscription service side
are found in the `live-events-subscriptions` repo, in `README.md`.

#### Connecting to local Live Events LTI Tool

The `live-events-lti` repo should also be checked out and running locally. This
is an LTI tool which provides a UI for managing the subscriptions contained in
the subscription service. Instructions for configuring this LTI tool are
contained in the `live-events-lti` repo, in `README.md`.

## Canvas LMS Live Events Consumers

Canvas LMS emits live events to multiple subscribers including Quiz LTI and
Gauge, among others.
