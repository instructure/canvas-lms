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

class Mutations::UpdateSubmissionGrade < Mutations::BaseMutation
  graphql_name "UpdateSubmissionsGrade"

  argument :submission_id, ID, required: true
  argument :score, Int, required: true

  field :submission, Types::SubmissionType, null: true
  def resolve(input:)
    submission = Submission.find(input[:submission_id])
    errors = {}

    if submission.grants_right?(current_user, :grade)
      submission.update(score: input[:score])
    else
      errors[submission.id.to_s] = "Not authorized to score Submission"
    end
    response = {}
    response[:submission] = submission unless errors.any?
    response[:errors] = errors if errors.any?
    response
  end
end
