#
# Copyright (C) 2018 - present Instructure, Inc.
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
  module DynamoDB
    module DatabaseBuilder
      class InvalidConfig < StandardError; end

      def self.configured?(category, environment = default_environment)
        raise ArgumentError, "config name required" if category.blank?
        config = configs(environment)[category]
        !!(config && config[:table_prefix] && config[:region])
      end

      def self.from_config(category, environment = default_environment)
        key = [category, environment]
        @clients ||= {}
        @clients.fetch(key) do
          config = configs(environment)[category]
          unless config
            @clients[key] = nil
            return nil
          end
          validate_config(config)
          opts = {
            region: config[:region],
            access_key_id: config[:access_key_id],
            secret_access_key: config[:secret_access_key]
          }
          opts[:endpoint] = config[:endpoint] if config[:endpoint]
          fingerprint = "#{category}:#{environment}"
          begin
            @clients[key] = CanvasDynamoDB::Database.new(
              fingerprint,
              config[:table_prefix],
              config[:autoscaling_role_arn],
              opts,
              Rails.logger
            )
          rescue Exception => exception
            Rails.logger.error "Failed to create DynamoDB client for #{key}: #{exception}"
            nil # don't save this nil into @clients[key], so we can retry later
          end
        end
      end

      def self.validate_config(config)
        unless config[:table_prefix].present?
          raise InvalidConfig, "No table prefix specified for: #{category.inspect}"
        end
        unless config[:region].present?
          raise InvalidConfig, "No region specified for: #{category.inspect}"
        end
      end

      def self.default_environment
        Rails.env
      end

      def self.configs(environment = default_environment)
        ConfigFile.load('dynamodb', environment) || {}
      end

      def self.categories
        configs.keys
      end

      def self.read_consistency_setting(category)
        Cavas::Cassandra::DatabaseBuilder.read_consistency_setting(category)
      end
    end
  end
end
