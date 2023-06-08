# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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
    module DevUtils
      SCHEMA_FIXTURES = {
        "graphql_mutations" => {
          attribute_definitions: [
            { attribute_name: "object_id", attribute_type: "S" },
            { attribute_name: "mutation_id", attribute_type: "S" },
          ],
          key_schema: [
            { attribute_name: "object_id", key_type: "HASH" },
            { attribute_name: "mutation_id", key_type: "RANGE" },
          ]
        }
      }.freeze

      def self.initialize_ddb_for_development!(category, table_name, recreate: false, schema: nil, ddb: nil, credentials: nil)
        unless ["development", "test"].include?(Rails.env)
          raise "DynamoDB should not be initialized this way in a real environment!!!"
        end

        canvas_ddb = ddb || Canvas::DynamoDB::DatabaseBuilder.from_config(category, credentials:)
        dynamodb = canvas_ddb.client
        local_table_name = canvas_ddb.prefixed_table_name(table_name)
        exists = begin
          dynamodb.describe_table(table_name: local_table_name)
          true
        rescue Aws::DynamoDB::Errors::ResourceNotFoundException
          false
        end
        if exists
          Rails.logger.debug("Local DDB table #{local_table_name} already exists!")
          return true unless recreate

          Rails.logger.debug("Deleting existing table...")
          dynamodb.delete_table(table_name: local_table_name)
        end
        Rails.logger.debug("Creating local DDB table for #{local_table_name}...")
        schema_opts = schema || SCHEMA_FIXTURES[table_name]
        params = schema_opts.merge({
                                     table_name: local_table_name,
                                     provisioned_throughput: { read_capacity_units: 5, write_capacity_units: 5 }
                                   })
        begin
          result = dynamodb.create_table(params)
          Rails.logger.debug("Created table. Status: " + result.table_description.table_status)
          true
        rescue Aws::DynamoDB::Errors::ServiceError => e
          Rails.logger.debug("Unable to create table:")
          Rails.logger.debug(e.message)
          false
        end
      end
    end
  end
end
