
require_dependency 'sfu_api'

# Should run with each request
config.to_prepare do
  SfuApi::initialize
end
