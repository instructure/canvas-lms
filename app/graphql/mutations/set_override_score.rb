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

    # If the relevant user has multiple enrollments in this course, we need
    # to update them all to prevent inconsistencies
    requested_enrollment = Enrollment.active.find(enrollment_id)
    current_enrollments = StudentEnrollment.active.where(
      course: requested_enrollment.course_id,
      user: requested_enrollment.user_id
    )

    # Even if we do update multiple enrollments, though, we only want to
    # return the score for the enrollment that was passed to us
    return_value = nil

    score_params = grading_period_id.present? ? {grading_period_id: grading_period_id} : nil
    current_enrollments.each do |enrollment|
      score = enrollment.find_score(score_params)
      raise ActiveRecord::RecordNotFound if score.blank?
      verify_authorized_action!(score.course, :manage_grades)

      score.update(override_score: input[:override_score])
      next unless enrollment == requested_enrollment

      return_value = if score.valid?
        {grades: score}
      else
        errors_for(score)
      end
    end

    return_value
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, "not found"
  end
end
