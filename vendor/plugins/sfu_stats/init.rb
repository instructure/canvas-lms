require_dependency 'sfu_stats'

# Should run with each request
config.to_prepare do
  SFU::Stats::initialize
end
