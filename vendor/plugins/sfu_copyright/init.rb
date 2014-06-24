require_dependency 'sfu_copyright'

# Should run with each request
config.to_prepare do
  SFU::Copyright::initialize
end
