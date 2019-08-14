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
    alias dynamo object

    field :mutation_logs, MutationLogType.connection_type, null: true do
      description "A list of all recent graphql mutations run on the specified object"
      argument :asset_string, String, required: true
    end

    def mutation_logs(asset_string:)
      return nil unless AuditLogFieldExtension.enabled? &&
        context[:domain_root_account].grants_right?(current_user, :manage_account_settings)

      DynamoQuery.new(dynamo, "graphql_mutations",
                      partition_key: "object_id",
                      value: "#{context[:domain_root_account].global_id}-#{asset_string}",
                      sort_key: "mutation_id",
                      scan_index_forward: false)
    end
  end
end
