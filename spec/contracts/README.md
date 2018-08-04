# Contract Tests

Canvas LMS has numerous API clients and Live Events subscribers. The purpose
behind contract tests is to prevent regressions in the API responses' and Live
Events messages' schemas for a given API request or Live Event subscription.

We follow a decoupled contract testing paradigm, as suggested by [Martin Fowler]
and the folks at Thoughtworks. This allows microservices to retain independent
CI and deployment pipelines. We use [Pact] to make this happen.

We use a Pact Broker web service to share Pact files between consumers and
providers. Ours is hosted internally at [https://inst-pact-broker.inseng.net].
Ask for credentials in the #test_advisory_board Slack channel.

## Running the tests locally

Running the contracts tests is a simple three step process:

1. Generate the contract(s)
2. Share the contract(s)
3. Verify the contract(s)

### Generate the Contracts

API clients and Live Events subscribers are responsible for defining,
generating, and publishing Pact files so that Canvas LMS can import and verify
them. Each Canvas LMS API client and Canvas LMS Live Event subscriber who's
integrated with Pact should have instructions in their own repo for generating
their Pact file(s).

If you'd like to see this in action, you're welcome to generate Quiz LTI's Pact
files:

```sh
cd path/to/quiz_lti # clone the repo first if necessary
dinghy up # if not already running
bin/dev-setup
bin/contracts-generate
```

All specs should pass and Quiz LTI should generate the Pact files. The script
will fail, however, because it's trying to publish those Pact files to a Pact
Broker. Let's spin that up now.

### Share the Contracts

The Pact Broker is a simple web application with a database for storing Pact
files.

To use a Pact Broker on your computer:

1. Clone the `quiz_pact_broker` repo
2. `cd quiz_pact_broker`
3. Execute:

```sh
bin/dev-setup && open http://pact:broker@pact-broker.docker
```

Now you're ready to publish a Pact file to the Pact Broker. Let's run that Quiz
LTI script again. It should finish successfully this time.

```sh
cd path/to/quiz_lti
bin/contracts-generate
```

Now refresh the Pact Broker in your web browser. You should see at least two
Pact files there, one of which contains contracts between "Quiz LTI" and "Canvas
LMS Live Events". Click on the document icon to view the contract, if you like.

### Verify the Contracts

Because we're only verifying the Quiz LTI contracts, you'll first want to open
`canvas-lms/spec/contracts/service_consumers/pact_config.rb` and comment out all
constants in the `Consumers` module with the exception of `QUIZ_LTI` and `ALL`.
For example:

```ruby
module Consumers
  # GENERIC_CONSUMER = 'Generic Consumer'.freeze
  QUIZ_LTI = 'Quiz LTI'.freeze
  ALL = Consumers.constants.map { |c| Consumers.const_get(c) }.freeze
end
```

This avoids attempting to verify contracts for consumers whose Pact files we
didn't generate (otherwise you'd get errors). Now you're ready to verify the
Quiz LTI contracts.

To verify the contracts, start Canvas on your computer---either in docker or
natively---and then run:

```sh
bin/contracts-verify-live-events
bin/contracts-verify-api
```

The specs should pass. You're finished!

## More Info

If you'd like to learn more about contract testing and Pact, head over to the
[Test Advisory Board github repo]. There you'll find links to industry articles,
internal documentation, simple Pact code examples, and more.

You're also welcome to stop by the #test_advisory_board Slack channel!

[Martin Fowler]: https://martinfowler.com/articles/microservice-testing/#testing-contract-introduction
[Pact]: https://docs.pact.io/
[https://inst-pact-broker.inseng.net]: https://inst-pact-broker.inseng.net
[Test Advisory Board github repo]: https://github.com/instructure/test_advisory_board
