# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

class Mutations::UpdateLearningOutcome < Mutations::BaseLearningOutcomeMutation
  graphql_name "UpdateLearningOutcome"

  argument :id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("LearningOutcome")

  def resolve(input:)
    record = LearningOutcome.active.find_by(id: input[:id])

    validate!(record, input[:id])

    outcome_input = attrs(input, record.context)

    if record.update(outcome_input)
      { learning_outcome: record }
    else
      errors_for(record, { short_description: :title })
    end
  end

  private

  def validate!(outcome, outcome_id)
    raise GraphQL::ExecutionError, I18n.t("unable to find LearningOutcome for id %{id}", id: outcome_id) unless outcome

    raise GraphQL::ExecutionError, I18n.t("insufficient permissions") unless check_permission(outcome)
  end

  def check_permission(outcome)
    outcome.grants_right? current_user, :update
  end
end
