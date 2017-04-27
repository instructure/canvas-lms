#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

module Canvas
  module Cassandra
    module DatabaseBuilder
      def self.configured?(config_name, environment = ::Rails.env)
        raise ArgumentError, "config name required" if config_name.blank?
        config = ConfigFile.load('cassandra', environment)
        config = config && config[config_name]
        config && config['servers'] && config['keyspace']
      end

      def self.from_config(config_name, environment = :current)
        @connections ||= {}
        environment = Rails.env if environment == :current
        key = [config_name, environment]
        @connections.fetch(key) do
          config = ConfigFile.load('cassandra', environment)
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
          begin
            @connections[key] = CanvasCassandra::Database.new(fingerprint, servers, opts, Rails.logger)
          rescue Exception => exception
            Rails.logger.error "Failed to create cassandra connection for #{key}: #{exception}"
            nil # don't save this nil into @connections[key], so we can retry later
          end
        end
      end

      def self.configs
        ConfigFile.load('cassandra') || {}
      end

      def self.config_names
        configs.keys
      end

      def self.read_consistency_setting(database_name = nil)
        setting_key = 'event_stream.read_consistency'
        setting_value = Setting.get("#{setting_key}.#{database_name}", nil) || Setting.get(setting_key, nil)

        setting_value if setting_value.present?
      end
    end
  end
end
