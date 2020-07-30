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

class Mutations::UpdateOutcomeCalculationMethod < Mutations::OutcomeCalculationMethodBase
  graphql_name "UpdateOutcomeCalculationMethod"

  # input arguments
  argument :id, ID, required: true
  argument :context_type, String, required: false
  argument :context_id, ID, required: false
  argument :calculation_method, String, required: false
  argument :calculation_int, Integer, required: false

  def resolve(input:)
    record = OutcomeCalculationMethod.find_by(id: input[:id])
    raise GraphQL::ExecutionError, "Unable to find OutcomeCalculationMethod" if record.nil?
    check_permission(record.context)
    upsert(input, record)
  end
end
