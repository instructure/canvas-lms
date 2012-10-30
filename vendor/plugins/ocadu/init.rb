require_dependency 'ocadu'

# Should run with each request
config.to_prepare do
  OCADU::initialize
end
