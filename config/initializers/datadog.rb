Datadog.configure do |c|
  c.profiling.enabled = ActiveModel::Type::Boolean.new.cast(ENV['STRONGMIND_APM_ENABLED'])
  c.tracer.enabled = ActiveModel::Type::Boolean.new.cast(ENV['STRONGMIND_APM_ENABLED'])
  c.env = 'prod'
  c.service = 'canvas'
  c.use :action_view
  c.use :active_model_serializers
  c.use :action_pack
  c.use :active_record
  c.use :active_support
  c.use :aws
  c.use :delayed_job
  c.use :http
  c.use :rails
  c.use :rake
  c.use :redis
end
