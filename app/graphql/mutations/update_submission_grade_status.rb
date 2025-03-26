# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class Mutations::UpdateSubmissionGradeStatus < Mutations::BaseMutation
  graphql_name "UpdateSubmissionsGradeStatus"

  argument :checkpoint_tag, String, required: false
  argument :custom_grade_status_id, ID, required: false
  argument :late_policy_status, String, required: false
  argument :submission_id, ID, required: true

  field :submission, Types::SubmissionType, null: true
  def resolve(input:)
    submission = Submission.find(input[:submission_id])
    if input[:checkpoint_tag].present? && submission.course.discussion_checkpoints_enabled?
      submission = submission.effective_checkpoint_submission(input[:checkpoint_tag])
    end

    return { errors: { submission.id => "Not authorized to set submission status" } } unless submission.grants_right?(current_user, :grade)

    if input[:custom_grade_status_id]
      submission.update(custom_grade_status_id: input[:custom_grade_status_id])
    elsif input[:late_policy_status] && input[:late_policy_status] != "none"
      if input[:late_policy_status] == "excused"
        submission.update(late_policy_status: nil, custom_grade_status_id: nil, excused: true)
      else
        submission.update(late_policy_status: input[:late_policy_status])
      end
    elsif (input[:custom_grade_status_id].nil? && input[:late_policy_status].nil?) || input[:late_policy_status] == "none"
      submission.update(custom_grade_status_id: nil, late_policy_status: input[:late_policy_status], excused: false)
    end

    { submission: }
  end
end
