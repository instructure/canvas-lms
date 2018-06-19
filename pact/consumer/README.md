To run specs to create pact files:

From canvas-lms directory, run:
bundle exec rspec pact/consumer/spec/

The pact files will be placed in:
canvas-lms/spec/pacts

The pact directory path is relative to the working directory where you run
the rspec command, not relative to where the files exist.
