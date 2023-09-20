# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

class Mutations::UpdateSubmissionStudentEnteredScore < Mutations::BaseMutation
  argument :entered_score, Float, required: true
  argument :submission_id, ID, required: true

  field :submission, Types::SubmissionType, null: true
  def resolve(input:)
    entered_score = input[:entered_score]
    submission = Submission.where(id: input[:submission_id]).first

    errors = {}

    if submission.nil?
      errors = { message: I18n.t("Submission not found") }
    elsif submission.grants_right?(current_user, :read)
      submission.student_entered_score = entered_score
      submission.save!
    else
      errors[submission.id.to_s] = I18n.t("Not authorized to read Submission")
    end

    response = {}
    response[:submission] = submission unless submission.nil?
    response[:errors] = errors if errors.any?
    response
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, "not found"
  end
end
