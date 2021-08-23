# Auditors

Records of important things that happened in canvas, stored in a streaming-ish manner,
with convenient query methods.

## why is this here?
Aspirationally, the "auditors" functionality that exists within canvas
is getting pulled out into an engine named "audits".  The name is different
so that it's clear which code still lives in canvas and which has been extracted,
making it easier to do this migration in little increments.  This is not because it will
be SUPER helpful to modularize auditors (it's already pretty modular),
but it's more because auditors is a test case with a small surface area;
we can use it to find out how pulling functionality into engines works,
what needs to be done to make dependency unwinding work, and whether we like it.

## what does it do?
Audits writes a database record every time something "important" occurs.
What's important gets defined by the canvas app itself.

## Usage
[TODO]

## Development

If you want to make changes to the audits engine, you'll want to be able
to work with just the code in this directory.  Make sure your dependencies
are installed ok like this:

`bundle install`

## Running Tests

you can run the tests for this engine alone, in isolation from the parent
canvas app.  cd to this directory and just:

`bundle exec rspec spec`

If you don't want to be bothered to control which specs run yourself,
you can use the script the build uses:

`./test.sh`

## Why is there no dockerfile?

It seems like it might be wasteful to create a different image/container
for every sub-engine/gem in canvas.  If you're working on a canvas docker
image, you can use `docker-compose run --rm web bash` to get a shell
open in your docker container, then cd to this directory and install your
dependencies and run your tests, etc.