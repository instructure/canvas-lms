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
#

class Mutations::PostDraftSubmissionComment < Mutations::BaseMutation
  graphql_name "PostDraftSubmissionComment"

  argument :submission_comment_id, ID, required: true

  field :submission_comment, Types::SubmissionCommentType, null: true
  def resolve(input:)
    submission_comment = SubmissionComment.find(input[:submission_comment_id])

    response = {}
    if submission_comment.grants_right?(current_user, :update)
      submission_comment.reload unless submission_comment.update(draft: false)

      response[:submission_comment] = submission_comment
    else
      raise GraphQL::ExecutionError, "Not authorized to update SubmissionComment"
    end

    response
  end
end
