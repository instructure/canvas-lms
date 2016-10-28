module Canvas
  module AWS
    OLD_KEYS_SYMBOLS = [:kinesis_endpoint, :kinesis_port,
                        :s3_endpoint, :s3_port,
                        :server, :port,
                        :sqs_endpoint, :sqs_port,
                        :use_ssl].freeze
    OLD_KEYS = (OLD_KEYS_SYMBOLS + OLD_KEYS_SYMBOLS.map(&:to_s)).freeze

    def self.validate_v2_config(config, source)
      old_keys = config.keys & OLD_KEYS
      unless old_keys.empty?
        ActiveSupport::Deprecation.warn(
          "Configuration options #{old_keys.join(', ')} for #{source} are no longer supported; just configure endpoint with a full URI and/or use region to form regional endpoints",
          caller(1))
        config = config.except(*OLD_KEYS)
      end
      unless config.key?(:region) || config.key?('region')
        ActiveSupport::Deprecation.warn("Please supply region for #{source}; for now defaulting to us-east-1", caller(1))
        config = config.dup
        config[:region] = 'us-east-1'
      end
      config
    end
  end
end
