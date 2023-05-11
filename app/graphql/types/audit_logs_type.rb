# frozen_string_literal: true

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
#

module Types
  class AuditLogsType < ApplicationObjectType
    alias_method :dynamo, :object

    field :mutation_logs, MutationLogType.connection_type, null: true do
      description "A list of all recent graphql mutations run on the specified object"
      argument :asset_string, String, required: true
      argument :start_time, DateTimeType, required: false
      argument :end_time, DateTimeType, required: false
    end

    def mutation_logs(asset_string:, start_time: nil, end_time: nil)
      return nil unless AuditLogFieldExtension.enabled? &&
                        context[:domain_root_account].grants_right?(current_user, :manage_account_settings)

      start_time ||= 1.year.ago
      end_time ||= 1.year.from_now

      DynamoQuery.new(dynamo,
                      AuditLogFieldExtension.ddb_table_name,
                      partition_key: "object_id",
                      value: "#{context[:domain_root_account].global_id}-#{asset_string}",
                      key_condition_expression: "mutation_id BETWEEN :start_time AND :end_time",
                      expression_attribute_values: {
                        ":start_time" => start_time.to_i.to_s,
                        ":end_time" => end_time.to_i.to_s,
                      },
                      sort_key: "mutation_id",
                      scan_index_forward: false)
    end
  end
end
