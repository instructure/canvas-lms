
require_dependency 'sfu'

# Should run with each request
config.to_prepare do
  SFU::initialize
end
