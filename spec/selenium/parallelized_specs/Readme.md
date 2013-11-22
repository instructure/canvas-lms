Speedup Test::RSpec by running parallel on multiple CPUs (or cores).<br/>
ParallelizedSpecs splits tests into even groups(by number of tests or runtime) and runs each group in a single process with its own database.

Setup Requirements
***IMPORTANT***
**OutcomeBuilder Formatter and FailuresFormatter must be enabled when using reruns or some ruby 1.9.3 version will provide false positives.
This allows streamlined pass\fail determination and thorough false positive checking while handling unusual pass\fail conditions in some versions of ruby 1.9.3

See FailuresFormatter readme section and set RERUNS to 0 if don't want to allow reruns but are using a ruby 1.9.3 version


Setup for Rails
===============
## Install
### Rails 3
If you use RSpec: ensure you have >= 2.4

As gem

    # add to Gemfile
    gem "parallelized_specs", :group => :development

OR as plugin

    rails plugin install git://github.com/jakesorce/parallelized_specs.git

    # add to Gemfile
    gem "parallel", :group => :development


### Rails 2

As gem

    gem install parallelized_specs

    # add to config/environments/development.rb
    config.gem "parallelized_specs"

    # add to Rakefile
    begin; require 'parallelized_specs/tasks'; rescue LoadError; end

OR as plugin

    gem install parallel

    # add to config/environments/development.rb
    config.gem "parallel"

    ./script/plugin install git://github.com/jakesorce/parallelized_specs.git

## Setup
ParallelizedSpecs uses 1 database per test-process, 2 processes will use `*_test` and `*_test2`.


### 1: Add to `config/database.yml`
    test:
      database: xxx_test<%= ENV['TEST_ENV_NUMBER'] %>

### 2: Create additional database(s)
    rake parallel:create

### 3: Copy development schema (repeat after migrations)
    rake parallel:prepare

### 4: Run!
    rake parallel:spec          # RSpec

    rake parallel:spec[1] --> force 1 CPU --> 86 seconds
    rake parallel:spec    --> have 2 CPUs? --> 47 seconds
    rake parallel:spec    --> have 4 CPUs? --> 26 seconds
    ...

Test by pattern (e.g. use one integration server per subfolder / see if you broke any 'user'-related tests)

    rake parallel:spec[4,user,]  # force 4 CPU and run users specs
    rake parallel:spec['user|product']  # run user and product related specs

Example output
--------------
    2 processes for 210 specs, ~ 105 specs per process
    ... spec output ...

    843 examples, 0 failures, 1 pending

    Took 29.925333 seconds

Loggers
===================

Even process runtimes
-----------------

Log test runtime to give each process the same runtime.

Rspec: Add to your `spec/parallelized_specs.opts` (or `spec/spec.opts`) :

    RSpec 1.x:
      --format progress
      --require parallelized_specs/spec_runtime_logger
      --format ParallelizedSpecs::SpecRuntimeLogger:tmp/parallel_profile.log
    RSpec >= 2.4:
      If installed as plugin: -I vendor/plugins/parallelized_specs/lib
      --format progress
      --format ParallelizedSpecs::SpecRuntimeLogger --out tmp/parallel_profile.log

SpecSummaryLogger
--------------------

This logger logs the test output without the different processes overwriting each other.

Add the following to your `spec/parallel_spec.opts` (or `spec/spec.opts`) :

    RSpec 1.x:
      --format progress
      --require parallelized_specs/spec_summary_logger
      --format ParallelizedSpecs::SpecSummaryLogger:tmp/spec_summary.log
    RSpec >= 2.2:
      If installed as plugin: -I vendor/plugins/parallelized_specs/lib
      --format progress
      --format ParallelizedSpecs::SpecSummaryLogger --out tmp/spec_summary.log

SpecFailuresLogger
-----------------------

This logger produces pasteable command-line snippets for each failed example.

This also stores all failures in this file for later consumption during an optional RERUN process
which can rerun all failed specs and potentially change the pass\fail outcome of a build if all specs pass.
Enable this formatter

E.g.

    rspec /path/to/my_spec.rb:123 # should do something

Add the following to your `spec/parallelized_spec.opts` (or `spec/spec.opts`) :

    RSpec 1.x:
      --format progress
      --require parallelized_specs/spec_failures_logger
      --format ParallelizedSpecs::SpecFailuresLogger:tmp/failing_specs.log
    RSpec >= 2.4:
      If installed as plugin: -I vendor/plugins/parallelized_specs/lib
      --format progress
      --format ParallelizedSpecs::SpecFailuresLogger --out tmp/failing_specs.log

FailuresFormatter
-----------------------
 **REQUIRED FOR RERUNS** *Note reruns cause some more false positive handling in multiple spots during runtime
                          and should also include the OutcomeBuilder formatter explained separately which handles these conditions*


This formatter captures all needed data about failed examples and stores them in a file for an additional run
at the end of the first build. If all specs that failed the first time pass the build will be marked as passed in the exit status.
The output location defined below is not optional and if this formatter is used must not be changed.

Use default MAX_RERUNS of 9 or set max number of failed specs to be allowed for reruns by exporting environment variable
export RERUNS=10

E.g.


Add the following to your `spec/parallelized_spec.opts` (or `spec/spec.opts`) :

    RSpec 1.x:
      --format progress
      --require parallelized_specs/failures_rerun_logger
      --format ParallelizedSpecs::SpecFailuresLogger:tmp/parallel_log/rspec.failures
    RSpec >= 2.4:
      If installed as plugin: -I vendor/plugins/parallelized_specs/lib
      --format progress
      --format ParallelizedSpecs::SpecFailuresLogger --out tmp/parallel_log/rspec.failures

OutcomeBuilder
-----------------------
 **RECOMMENDED WITH RERUNS** *Note reruns cause some more false positive handling in multiple spots during runtime
                              and should also include the OutcomeBuilder formatter*


Because previously the pass\fail determination was solely on exit status and now we do things besides always fail on non 0 exits
we must handle many other causes of non 0 exit codes that we don't want to start the rerun process if they happen.

E.g.


Add the following to your `spec/parallelized_spec.opts` (or `spec/spec.opts`) :

    RSpec 1.x:
      --format progress
      --require parallelized_specs/outcome_builder
      --format ParallelizedSpecs::SpecFailuresLogger:tmp/parallel_log/outcome_builder.txt
    RSpec >= 2.4:
      If installed as plugin: -I vendor/plugins/parallelized_specs/lib
      --format progress
      --format ParallelizedSpecs::SpecFailuresLogger --out tmp/parallel_log/outcome_builder.txt

TrendingExampleFailures
-----------------------
Create a single * delimited text file with all failed examples failure information
No built in interface to populate a database with these

E.g.


Add the following to your `spec/parallelized_spec.opts` (or `spec/spec.opts`) :

    RSpec 1.x:
      --format progress
      --require parallelized_specs/trending_example_failures_logger
      --format ParallelizedSpecs::SpecFailuresLogger:tmp/parallel_log/trends.log
    RSpec >= 2.4:
      If installed as plugin: -I vendor/plugins/parallelized_specs/lib
      --format progress
      --format ParallelizedSpecs::SpecFailuresLogger --out tmp/parallel_log/trends.log

SlowestSpecLogger
-----------------------
creates a text file with any specs taking longer than 30 seconds by default but can be overridden by setting a ENV["MAX_TIME"] var

E.g.


Add the following to your `spec/parallelized_spec.opts` (or `spec/spec.opts`) :

    RSpec 1.x:
      --format progress
      --require parallelized_specs/slow_spec_logger
      --format ParallelizedSpecs::SpecFailuresLogger:tmp/parallel_log/slowest_specs.log
    RSpec >= 2.4:
      If installed as plugin: -I vendor/plugins/parallelized_specs/lib
      --format progress
      --format ParallelizedSpecs::SpecFailuresLogger --out tmp/parallel_log/slowest_specs.log

Tools

selenium_trending_collector.rb
------------------------
This consumes the text files created by the trender formatter and parses it associates the data and pushes it to a database for storage


Setup for non-rails
===================
    sudo gem install parallelized_specs
    # go to your project dir
    parallelized_specs
    # [Optional] use ENV['TEST_ENV_NUMBER'] inside your tests to select separate db/memcache/etc.

[optional] Only run selected files & folders:

    parallelized_specs test/bar test/baz/xxx_text_spec.rb

TIPS
====
 - [RSpec] add a `spec/parallel_spec.opts` to use different options, e.g. no --drb (default: `spec/spec.opts`)
 - [RSpec] if something looks fishy try to delete `script/spec`
 - [RSpec] if `script/spec` is missing parallel:spec uses just `spec` (which solves some issues with double-loaded environment.rb)
 - [RSpec] 'script/spec_server' or [spork](http://github.com/timcharper/spork/tree/master) do not work in parallel
 - [RSpec] `./script/generate rspec` if you are running rspec from gems (this plugin uses script/spec which may fail if rspec files are outdated)
 - [RSpec] remove --loadby from you spec/*.opts
 - [Bundler] if you have a `Gemfile` then `bundle exec` will be used to run tests
 - [SQL schema format] use :ruby schema format to get faster parallel:prepare`
 - [ActiveRecord] if you do not have `db:abort_if_pending_migrations` add this to your Rakefile: `task('db:abort_if_pending_migrations'){}`
 - `export PARALLEL_TEST_PROCESSORS=X` in your environment and parallelized_specs will use this number of processors by default
 - with zsh this would be `rake "parallel:prepare[3]"`
 - [RERUNS] if you're using reruns formatter also use the outcome builder to make your builds handle syntax issues during example_group generation from rspec
   and thread crashes more cleanly

Authors
====
inspired by [pivotal labs](http://pivotallabs.com/users/miked/blog/articles/849-parallelize-your-rspec-suite)

based loosely from https://github.com/grosser/parallel_tests
### [Contributors](http://github.com/jakesorce/parallelized_specs/contributors)
 - [Bryan Madsen](http://github.com/bmad)

 - [Jake Sorce](http://github.com/jakesorce)

 - [Shawn Meredith](https://github.com/smeredith0506)

Hereby placed under public domain, do what you want, just do not hold me accountable...<br/>
[![Flattr](http://api.flattr.com/button/flattr-badge-large.png)](https://flattr.com/submit/auto?user_id=jakesorce&url=https://github.com/jakesorce/parallelized_specs&title=parallelized_specs&language=en_GB&tags=github&category=software)
