# Profiling Ruby

If you've got ruby code you're concerned is behaving badly (especially slowly),
there are some tools installed that can help you figure out why.

## Stackprof

[stackprof](https://github.com/tmm1/stackprof) is in the test bundle, and is a
nice choice because it's comparatively lightweight.  It uses sampling of the stack
at various intervals rather than complete instrumentation, so it can be statistically noisy,
but should still accumulate into a reasonable sense of where your time is going.

Apply it to a chunk of code like so:

```ruby
StackProf.run(mode: :wall, out: 'tmp/stackprof-canvas-test.dump', interval: 1000) do
  #...the code you want to profile, often the body of a test
end
```

This will sample every 1000 microseconds (1 millisecond), and write the
output to the specificed "out" file.  See the stackprof docs linked above for more
details on configuration options

Once you've produced a dumpfile, you can produce a report on the results
by using the stackprof command directly:

```bash
bundle exec stackprof tmp/stackprof-canvas-test.dump --limit 20
```

That should give you a report like:

```
==================================
  Mode: wall(1000)
  Samples: 1353 (90.17% miss rate)
  GC: 22 (1.63%)
==================================
     TOTAL    (pct)     SAMPLES    (pct)     FRAME
       376  (27.8%)         376  (27.8%)     RSpec::ExampleGroups::AssetUserAccessLog::Compact#await_message_bus_queue!
       304  (22.5%)         155  (11.5%)     ActiveRecord::ConnectionAdapters::PostgreSQLAdapter#exec_no_cache
       177  (13.1%)          39   (2.9%)     AssetUserAccessLog.message_bus_compact
        30   (2.2%)          30   (2.2%)     Pulsar::Producer::RubySideTweaks#send
        32   (2.4%)          21   (1.6%)     ActiveRecord::ConnectionAdapters::PostgreSQL::DatabaseStatements#execute
        20   (1.5%)          20   (1.5%)     Bundler::Runtime#require
        18   (1.3%)          18   (1.3%)     ActiveRecord::Base.logger
        14   (1.0%)          14   (1.0%)     Concurrent::Collection::NonConcurrentMapBackend#[]
        17   (1.3%)          13   (1.0%)     ActiveSupport::Cache::Entry#compress!
        15   (1.1%)          13   (1.0%)     Logger::LogDevice#write
        13   (1.0%)          13   (1.0%)     Pulsar::Client::RubySideTweaks#subscribe
        12   (0.9%)          12   (0.9%)     (sweeping)
        10   (0.7%)          10   (0.7%)     (marking)
        10   (0.7%)          10   (0.7%)     ActiveSupport::PerThreadRegistry#instance
        10   (0.7%)          10   (0.7%)     ActiveSupport::Notifications::Event#now_cpu
        10   (0.7%)          10   (0.7%)     Concurrent::Collection::NonConcurrentMapBackend#get_or_default
        10   (0.7%)          10   (0.7%)     ActiveRecord::ConnectionHandling#connection_specification_name
        58   (4.3%)           8   (0.6%)     Switchman::ActiveRecord::LogSubscriber#sql
         8   (0.6%)           8   (0.6%)     ActiveModel::Type::Helpers::Numeric#cast
         8   (0.6%)           8   (0.6%)     ActiveRecord::ConnectionAdapters::ConnectionHandler#owner_to_pool
```

Which can show you which stack frames are frequently at the top of the stack.