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
#

class Mutations::DeleteOutcomeProficiency < Mutations::BaseMutation
  graphql_name "DeleteOutcomeProficiency"

  # input arguments
  argument :id, ID, required: true

  # the return data if the delete is successful
  field :outcome_proficiency_id, ID, null: false

  def self.outcome_proficiency_id_log_entry(_entry, context)
    context[:deleted_models][:outcome_proficiency].context
  end

  def resolve(input:)
    record_id = GraphQLHelpers.parse_relay_or_legacy_id(input[:id], "OutcomeProficiency")
    record = OutcomeProficiency.active.find_by(id: record_id)
    raise GraphQL::ExecutionError, "Unable to find OutcomeProficiency" if record.nil?
    raise GraphQL::ExecutionError, "insufficient permission" unless record.context.grants_right? current_user, :manage_proficiency_scales
    context[:deleted_models][:outcome_proficiency] = record
    record.destroy
    {outcome_proficiency_id: record.id}
  end
end
