if Rails.env.test? && ENV['SELENIUM_WEBRICK_SERVER'] == '1'
  # in the selenium specs we switch back and forth between local and s3 storage
  # using some hacks that bypass normal attachment_fu initialization, so we
  # need to make sure we always have an established s3 connection somewhere.
  require 'aws/s3'
  s3_config = YAML.load(ERB.new(File.read(Rails.root+'config/amazon_s3.yml')).result)[Rails.env].symbolize_keys
  AWS::S3::Base.establish_connection!(s3_config.slice(:access_key_id, :secret_access_key, :server, :port, :use_ssl, :persistent, :proxy))
end
