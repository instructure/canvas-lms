Rails.configuration.to_prepare do
  require_dependency 'test_cluster'
  require_dependency 'jsenv'
end