# Testing with Selenium

You may run the Selenium tests either natively or in docker.

## Running Selenium Tests Natively (Mac)

We're making a few assumptions here:
  - you're using an Apple computer
  - you've already installed Homebrew
  - you've already installed Postgres (postgresapp.com is an excellent option),
    and Postgres is running on your computer
  - you've already installed Node.js

0. Install `yarn` if you haven't already:

```sh
brew install yarn
```

If you find you need an older version of yarn, follow these instructions to
install the older version and switch to it:

[https://stackoverflow.com/a/52525732/3038677](https://stackoverflow.com/a/52525732/3038677)

1. Follow the instructions in `script/prepare/README.md` to setup the `prepare`
script.

You'll use the `prepare` script later to automate installing and updating Canvas
on your computer.

Note: some features of `prepare` only work if you have access to Instructure's
Gerrit host. See the README for details.

2. Install a web browser driver on your computer for the browser you wish to run
the tests in. Homebrew is the easiest way to go:

```sh
brew install chromedriver # necessary for running tests in Chrome
brew install geckodriver # necessary for running tests in Firefox
```

Now let's get Canvas ready to run the tests.

3. Copy the Selenium and database configuration files:

```sh
cp config/selenium.yml.example config/selenium.yml
cp config/database.yml.example config/database.yml
```

4. Use `prepare` to install Canvas plugins and dependencies, create databases,
run database migrations, etc:

```sh
prepare
```

You might encounter problems with some Ruby dependencies. The ["Dependency
Installation" section](https://github.com/instructure/canvas-lms/wiki/Quick-Start#dependency-installation)
in the public Canvas LMS Github wiki has some useful tips.

4.a. Optional. Run delayed jobs in the foreground (not all Selenium tests need
this but some do):

```sh
script/delayed_job run
```

or run it in the background:

```sh
script/delayed_job run &
```

5. Run the Selenium tests:

```sh
bundle exec rspec spec/selenium
```

or run a specific Selenium test:

```sh
bundle exec rspec spec/selenium/accounts_spec.rb:36
```

## Running Selenium Tests in Docker

See the [Selenium section](https://github.com/instructure/canvas-lms/blob/master/doc/docker/developing_with_docker.md#selenium)
of the `doc/docker/developing_with_docker.md` instructions.
