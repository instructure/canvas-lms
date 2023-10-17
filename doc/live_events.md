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
container run `docker-compose up -d kinesis`. Once it's up, make sure you have
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
docker-compose run --rm web script/tail_kinesis http://kinesis:4567 live-events
```

#### Stubbing Kinesis

Instead of viewing events in the kinesis stream, you can add the `stub_kinesis`
attribute to the dynamic_settings live_events block that you configured above,
with a value of `true`. This will print live events to stdout instead of sending
them to a kinesis stream.

An easy way of accessing stdout when using dockerized Canvas is this:

```
docker-compose logs -f --tail=100 <jobs|web> # whichever container you need
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
activity by looking at the output of `docker-compose up` in the `live-events-publish`
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

## Contract Tests

We use [Pact] to ensure our live events messages don't regress. For contract
testing live events we use the [pact-messages] gem. Here's some helpful
terminology to get started:

- `Provider`: the live events producer
- `Consumer`: the live events subscriber
- `Pact file`: the json file in which the consumer-dictated contract is defined
- `Pact Broker`: the web app that serves as a permanent storage repository for
  sharing Pact files between consumers and providers. Instructure has its own
  internal [Pact Broker].

## Canvas LMS Live Events Consumers

Canvas LMS emits live events to multiple subscribers including Quiz LTI and
Gauge, among others.

You can view which consumers have contract tests in place for Canvas LMS live
events in this repo's `spec/contracts/service_consumers/live_events/` directory.

Any consumers who desire to have contract tests with Canvas LMS live events will
need to initiate that effort as Canvas LMS cannot run the tests without the
consumer's Pact file.

## Development Workflow:

This example uses the `quiz_lti` repo, which you can substitute with any other
live events consumer.

0. If you're adding a new consumer to the contract tests suite, open
`spec/contracts/service_consumers/pact_config.rb` and add a new constant
to the `Consumers` module. The new constant's value *must* match the one
defined in the new consumer's Pact file(s)! For example, if the consumer calls
itself "Quiz LTI" in its Pact file(s) then the new constant should be
`QUIZ_LTI = 'Quiz LTI'.freeze`
1. In the quiz_pact_broker repo, spin up a Pact Broker with `bin/dev-setup`
2. In the `quiz_lti` repo, spin up the Quiz LTI service with `bin/dev-setup`
3. In the `quiz_lti` repo's `spec/contracts/service_providers/live_events`
directory, write or modify a live events contract test
4. In the `quiz_lti` repo, run `bin/contracts-generate` to generate a
Pact file and publish it to the local Pact Broker
5. In this repo, open `spec/contracts/service_consumers/pact_config.rb` and
comment out the consumers you *won't* be testing. For example:

```ruby
module Consumers
  # GAUGE = 'Gauge'.freeze
  QUIZ_LTI = 'Quiz LTI'.freeze
  All = Consumers.constants.map { |c| Consumers.const_get(c) }.freeze
end
```

6. In this repo, spin up the Canvas LMS service with `script/docker_dev_setup.sh`
7. In this repo, run `bin/contracts-verify-live-events` to pull the new Pact
files from the local Pact Broker and run the contract tests against the Canvas
LMS service. The new tests will most likely fail. That's OK! This is a TDD
workflow.
8. In this repo, write or modify Pact::Messages RSpec tests in the
`spec/contracts/service_consumers/live_events/` directory for the new live
events contracts. We've written a module to help you get started. See the
`quiz_lti/assignment_created_spec.rb` for an example.
9. Run `bin/contracts-verify-live-events` again
10. Repeat steps 8 and 9 until all tests pass

Bonus: You can view the Pact file(s) in the Pact Broker at http://pact:broker@pact-broker.docker
along with an API dependency graph!

## Debugging Failures

Pact has some basic RSpec output for failed specs. It also keeps a log in
`log/pact.log` and offers general pointers for debugging.

Above all, learn the Pact [basics].

## What should live events contract tests cover?

The aim of contract testing here is *not* for every consumer to verify the
entirety of every live events message emitted by Canvas LMS. Rather, the goal is
to ensure changes to the Canvas LMS live events service won't break its
consumers. We can best accomplish this when each consumer's Pact file defines
only the message contents on which the consumer relies.

For example, let's say both Quiz LTI and Gauge subscribe to the Canvas LMS live
event, `quizzes.item_created`. Let's say Quiz LTI only relies on the following
hash in the live event message:

```ruby
{
  root_account_uuid: 'abcd-example-uuid',
  outcome_alignment_set_guid: '1234-example-guid'
}
```

And let's say Gauge only relies on this hash:

```ruby
{
  root_account_uuid: 'abcd-example-uuid',
  item_id: '1'
}
```

But the actual `quizzes.item_created` live event message looks like this:

```ruby
{
  root_account_uuid: 'abcd-example-uuid',
  outcome_alignment_set_guid: '1234-example-guid',
  item_id: '1',
  scoring_algorithm: 'Equalized'
}
```

Therefore Gauge's Pact file shouldn't include `outcome_alignment_set_guid` or
`scoring_algorithm`, and Quiz LTI's Pact file shouldn't include `item_id` or
`scoring_algorithm`. Each Pact file defines the minimum contract required. This
way if Canvas LMS were to change its Live Events service such that it no longer
emits the `item_id`, then Canvas LMS will know right away that merging the code
change would break Quiz LTI but not Gauge.

## Changing Contracts

When a Pact spec fails in Canvas LMS this means your code change isn't
compatible with what a consumer expects from Canvas LMS. These consumer
expectations are defined in the given consumer code base and communicated via
its Pact file(s).

If your code change is absolutely necessary and you need to break the consumer
contract, then you'll first need to talk with that team and work with them to
change the contract in their repo. After that change is merged then you can
merge your new changes to Canvas LMS.

[Pact]:           https://docs.pact.io/
[pact-messages]:  https://github.com/reevoo/pact-messages/
[basics]:         https://docs.pact.io/documentation/matching.html
[Pact Broker]: https://inst-pact-broker.inseng.net
