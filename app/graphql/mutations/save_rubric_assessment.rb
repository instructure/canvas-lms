# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class Mutations::SaveRubricAssessment < Mutations::BaseMutation
  argument :assessment_details, GraphQL::Types::JSON, required: true
  argument :graded_anonymously, Boolean, required: true
  argument :provisional, Boolean, required: false, default_value: false
  argument :rubric_assessment_id, ID, required: false
  argument :rubric_association_id, ID, required: true
  argument :submission_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Submission")

  field :rubric_assessment, Types::RubricAssessmentType, null: true
  field :submission, Types::SubmissionType, null: true
  def resolve(input:)
    root_account = context[:domain_root_account]
    submission = Submission.find_by(id: input[:submission_id], root_account:)
    raise GraphQL::ExecutionError, "Submission not found" if submission.nil?

    association = RubricAssociation.find(input[:rubric_association_id])
    association_object = association.association_object

    assessment = association.rubric_assessments.find(input[:rubric_assessment_id]) if input[:rubric_assessment_id].present?

    verify_authorized_action!(assessment, :update) if assessment.present?

    # only check if there's no assessment object, since that's the only time
    # this param matters (find_asset_for_assessment)
    user_id = assessment.present? ? assessment.user_id : submission.user_id
    raise ActiveRecord::RecordNotFound if user_id.blank?

    # For a moderated assignment, submitting an assessment claims a grading
    # slot for the submitting provisional grader (or throws an error if no
    # slots remain).
    begin
      opts = {}
      provisional = input[:provisional]
      ensure_adjudication_possible(provisional:, association_object:) do
        asset, user = association_object.find_asset_for_assessment(association, user_id, opts)
        assessment_details = JSON.parse(input[:assessment_details]).with_indifferent_access
        assessment_type = assessment_details[:assessment_type]

        unless association.user_can_assess_for?(assessor: current_user, assessee: user, assessment_type:)
          raise GraphQL::ExecutionError, "Not authorized to assess user"
        end

        rubric_assessment = association.assess(
          assessor: current_user,
          user:,
          artifact: asset,
          assessment: assessment_details,
          graded_anonymously: input[:graded_anonymously]
        )

        submission.reload
        return { submission:, rubric_assessment: }
      end
    rescue Assignment::GradeError
      raise GraphQL::ExecutionError, "Assignment Grade Error"
    end
  rescue ActiveRecord::RecordNotFound => e
    raise GraphQL::ExecutionError, "#{e.model} not found"
  end

  def ensure_adjudication_possible(provisional:, association_object:, &)
    # Non-assignment association objects crash if they're passed into this
    # controller, since find_asset_for_assessment only exists on assignments.
    # The check here thus serves only to make sure the crash doesn't happen on
    # the call below.
    return yield unless association_object.is_a?(Assignment)

    association_object.ensure_grader_can_adjudicate(
      grader: @current_user,
      provisional:,
      occupy_slot: true,
      &
    )
  end
end
