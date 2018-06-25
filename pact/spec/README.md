# Canvas LMS API "Generic" Contract Tests

Normally the Pact paradigm for contract testing is such that an API consumer
publishes its Pact file for the API provider to verify. Canvas LMS has
multitudinous API consumers, so in order to gain the most contract test coverage
possible for consumers who choose not to publish a Pact file we've created a
generic API consumer called "Generic Consumer". We write the contract tests for
this generic consumer in the canvas-lms repo, generate its Pact file, and verify
the Pact file in the same canvas-lms repo.

To follow the normal Pact paradigm to contract test real API and Live Event
consumers, see `canvas-lms/spec/contracts/service_consumers/README.md`.

## Running the generic contract tests locally

Running the contracts tests is a simple three step process:

1. Generate the contract(s)
2. Share the contract(s)
3. Verify the contract(s)

### Generate the Contracts

From the canvas-lms directory, run:

```sh
bin/contracts-generate
```

### Share the Contracts

The pact file is already placed in `canvas-lms/pacts/` for you.

### Verify the Contracts

To verify the Pact file, run:

```sh
bin/contracts-verify-api
```

All specs should pass.

### Publish the pact file to broker

```sh 
bin/contracts-publish-api
```
