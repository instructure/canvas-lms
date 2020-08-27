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

class Mutations::UpdateOutcomeProficiency < Mutations::OutcomeProficiencyBase
  graphql_name "UpdateOutcomeProficiency"

  # input arguments
  argument :id, ID, required: true
  argument :proficiency_ratings, [Mutations::OutcomeProficiencyRatingCreate], required: false

  def resolve(input:)
    record_id = GraphQLHelpers.parse_relay_or_legacy_id(input[:id], "OutcomeProficiency")
    record = OutcomeProficiency.find_by(id: record_id)
    raise GraphQL::ExecutionError, "Unable to find OutcomeProficiency" if record.nil?
    check_permission(record.context)
    upsert(input, record)
  end
end
