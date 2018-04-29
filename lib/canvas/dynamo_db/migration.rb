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
    module Migration

      DEFAULT_READ_CAPACITY_UNITS = 5
      DEFAULT_WRITE_CAPACITY_UNITS = 5

      module ClassMethods
        def db
          @dyanmodb ||= Canvas::DynamoDB::DatabaseBuilder.from_config(category)
        end

        def category(category = nil)
          return @dynamodb_category if category.nil?
          @dynamodb_category = category
        end

        def runnable?
          raise "Configuration category is required to be set" unless category.present?
          Switchman::Shard.current == Switchman::Shard.birth && 
            Canvas::DynamoDB::DatabaseBuilder.configured?(category)
        end

        def create_table(params)
          ttl_attribute = params.delete(:ttl_attribute)
          params = provisioned_throughput.merge(params)
          params[:global_secondary_indexes].try(:each_with_index) do |gsi, idx|
            params[:global_secondary_indexes][idx] = provisioned_throughput.merge(gsi)
          end
          db.create_table_with_autoscaling(params)
          if ttl_attribute
            db.update_time_to_live({
              table_name: params[:table_name],
              time_to_live_specification: {
                enabled: true,
                attribute_name: ttl_attribute,
              },
            })
          end
        end

        def delete_table(params)
          db.delete_table_with_autoscaling(params)
        end

        private

        def read_capacity_units
          key = "dynamodb_migration_read_capacity_units"
          units = Setting.get("#{key}_#{category}", nil) if category
          units ||= Setting.get(key, DEFAULT_READ_CAPACITY_UNITS  )
        end

        def write_capacity_units
          key = "dynamodb_migration_write_capacity_units"
          units = Setting.get("#{key}_#{category}", nil) if category
          units ||= Setting.get(key, DEFAULT_READ_CAPACITY_UNITS)
        end

        def provisioned_throughput
          {
            provisioned_throughput: {
              read_capacity_units: read_capacity_units,
              write_capacity_units: write_capacity_units,
            }
          }
        end
      end

      def self.included(migration)
        migration.tag :dynamodb
        migration.singleton_class.include(ClassMethods)
      end
    end

  end
end
