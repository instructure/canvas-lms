Datadog.configure do |c|
  c.profiling.enabled = true
  c.tracer.enabled = true
  c.env = 'prod'
  c.service = 'canvas'
end
