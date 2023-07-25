# CanvasErrors

A callback-hub for taking actions when an error
is reported somewhere in the app.

## Usage

When things go wrong, we want to know about it.  When things error out in expected ways because that’s how we’re communicating to the user they’ve done something wrong, we DON’T want to know about it.  This gem organizes where our exceptions go, and how you should deal with sending them there (or NOT sending them there!).

### Where do we capture exceptions for analysis?

The short answer is that they get sent to [sentry](https://www.sentry.io). Mostly we use the Sentry integration (see config/initializers/sentry.rb in canvas-lms).  This means that any time an UNHANDLED exception pops all the way out of the rails process, we’ll tell Sentry.

We also sometimes report errors that we handle if it’s important to report them (because it’s unexpected) but also not explode (because we’re in the middle of doing something important that is continuable).  See page view logging in canvas for an example: `app/controllers/application_controller.rb`.  Because we register sentry as a callback from Canvas Errors, things that we send there also get sent to Sentry.  An error can be captured from anywhere using the capture method:

```ruby
begin
  # risky thing
rescue ExpectedError => e
  Canvas::Errors.capture(e, extra_context: "foobar")
end
```

Sentry is not the only system that can be rigged up to the Canvas Errors system as a callback.
If something else should happen as part of an error being declared, you can define a callback
to make that happen:

```ruby
Rails.configuration.to_prepare do
  # write a database record to our application DB capturing useful info for looking
  # at this error later
  CanvasErrors.register!(:error_report) do |exception, data, level|
    report = ErrorReport.log_exception_from_canvas_errors(exception, data)
    report.try(:global_id)
  end
end
```

callbacks have a name, so only one callback with the same name can be registered,
but this is also useful for sending callback "responses".  the return value
of every block registered as a callback gets packed into a hash that gets returned
from "capture" calls so that you can inspect and use some identifier from a given
callback if you need to.

### Which exceptions should get reported?

Actionable ones.  We aspire to be in a state where any error that ends up in sentry provokes a response.  Possibly to fix the code, sometimes to catch and handle an exception that is really more of an operational signal.  We often send those to sentry because “we want to know if they’re happening a lot”, but sentry isn’t great at surfacing that information.  If something is an error that is going to happen sometimes as part of doing business, but shouldn’t happen too much (think of like transient networking failures when talking to an upstream service), then we want that to get sent to datadog as a metric we can alarm on.  As long as it’s not happening so often that we need to fire an alarm, it can just be incorporated into a dashboard.  That is the kind of signal that should NOT get sent to sentry.

The CanvasErrors has a mechanism for this, the “level” parameter:

```ruby
def some_action
  # ... hard important work
rescue ErrorClassA => e
  CanvasErrors.capture_exception(:important_subsystem, e, :info)
  render :plain => 'unauthorized', :status => :unauthorized
rescue ErrorClassB => e
  CanvasErrors.capture_exception(:important_subsystem, e, :warn)
  render :plain => "Service is currently unavailable. Try again later.",
          :status => :service_unavailable
rescue ErrorClassC => e
  CanvasErrors.capture_exception(:important_subsystem, e, :info)
  render :plain => 'Bad Request', :status => :bad_request
rescue ErrorClassD => e
  CanvasErrors.capture_exception(:important_subsystem, e, :error)
  render :plain => 'Unknown Error', :status => :service_unavailable
end
```

Above, the same action can fail in many ways, but some of them
are part of doing business, and some of them are surprises.
The third argument to "capture_exception" lets you declare
which type of failure this is, and that parameter is available
to the callback blocks you write so you can decide for a given callback
whether or not to take action for a given error based on it's level.

### Best practices@

* Throw and catch SPECIFIC errors.  New error classes are cheap, and can help localize problems when they occur.  If everything is a RuntimeException or ArgumentError, both sentry and the stats systems loose their fidelity.  Instead use things like a custom MissingGoogleDriveParameterError, which will show up as it’s own stat in datadog, and it’s own “issue” in sentry (and will be easy to localize to one spot in the code).  It’s perfectly acceptable to INHERIT from ArgumentError or other general exception if they do fall into those categories, but try to throw errors that are specifically named for your use case.  ERRORS THAT BUBBLE UP TO ABORT THE REQUEST OR JOB STILL GET CAPTURED, BUT THEY WILL ALWAYS BE OF THE “:error” TYPE BECAUSE WE DON’T WANT EXPECTED ERRORS TO RESULT IN 500s.

* Capture your exceptions explicitly with CanvasErrors.capture (or capture_exception). This will make sure that ANY callbacks we register to keep track of our errors will get run (logs, stats, sentry, etc), even ones we add in the future.

* Use the ‘type’ parameter for errors to specify a subsystem, just like the example above. If you use “capture_exception”, this is the first parameter.  This will let us capture stats (and tags in sentry) for ALL the errors that are part of a given subystem (oauth, global_lookups, local_cache, etc).

* Use the ‘level’ argument to indicate severity.  The default is “:error”.  This is what we want for errors that are a surprise, and we should do something about them.  If you’re capturing something that’s going to happen from time to time (upstream service timeouts, auth failures, parsing user content errors, etc, etc), use “:warn” if it’s something that might need attention if it climbs above a certain level (think redis or db timeouts or connection failures, things that we’re resiliant to but want to watch out for spikes in), and :info if it’s something like user input validation that we WANT to fail in order to make business logic work.

## Running Tests

This gem is tested with rspec.  You can use `test.sh` to run it, or
do it yourself with `bundle exec rspec spec`.
