module Canvas
  module Cassandra
    module DatabaseBuilder
      def self.configured?(config_name, environment = :current)
        raise ArgumentError, "config name required" if config_name.blank?
        config = Setting.from_config('cassandra', environment)
        config = config && config[config_name]
        config && config['servers'] && config['keyspace']
      end

      def self.from_config(config_name, environment = :current)
        @connections ||= {}
        environment = Rails.env if environment == :current
        key = [config_name, environment]
        @connections.fetch(key) do
          config = Setting.from_config('cassandra', environment)
          config = config && config[config_name]
          unless config
            @connections[key] = nil
            return nil
          end
          servers = Array(config['servers'])
          raise "No Cassandra servers defined for: #{config_name.inspect}" unless servers.present?
          keyspace = config['keyspace']
          raise "No keyspace specified for: #{config_name.inspect}" unless keyspace.present?
          opts = {:keyspace => keyspace, :cql_version => '3.0.0'}
          opts[:retries] = config['retries'] if config['retries']
          opts[:connect_timeout] = config['connect_timeout'] if config['connect_timeout']
          opts[:timeout] = config['timeout'] if config['timeout']
          fingerprint = "#{config_name}:#{environment}"
          Bundler.require 'cassandra'
          @connections[key] = CanvasCassandra::Database.new(fingerprint, servers, opts, Rails.logger)
        end
      end

      def self.config_names
        Setting.from_config('cassandra').try(:keys) || []
      end
    end
  end
end
