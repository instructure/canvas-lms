require ['jquery', 'compiled/jobs'], ($, jobs) ->
  # TODO: get this stuff off window, need to move the domready stuff out of
  # jobs.coffee into here
  window.jobs = new jobs.Jobs(ENV.JOBS.opts).init()
  window.running = new jobs.Workers(ENV.JOBS.running_opts).init()
  window.tags = new jobs.Tags(ENV.JOBS.tags_opts).init()

