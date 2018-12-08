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

class Mutations::SetOverrideScore < Mutations::BaseMutation
  graphql_name "SetOverrideScore"

  argument :enrollment_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Enrollment")
  argument :grading_period_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("GradingPeriod")
  argument :override_score, Float, required: false

  field :grades, Types::GradesType, null: true

  def resolve(input:)
    enrollment_id = input[:enrollment_id]
    grading_period_id = input[:grading_period_id]

    enrollment = Enrollment.find(enrollment_id)
    score_params = grading_period_id.present? ? {grading_period_id: grading_period_id} : nil
    score = enrollment.find_score(score_params)
    raise ActiveRecord::RecordNotFound if score.blank?

    if authorized_action?(score.course, :manage_grades)
      score.override_score = input[:override_score]
      if score.save
        {grades: score}
      else
        errors_for(score)
      end
    end
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, "not found"
  end
end
