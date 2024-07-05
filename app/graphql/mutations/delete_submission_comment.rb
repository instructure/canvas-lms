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

class Mutations::DeleteSubmissionComment < Mutations::BaseMutation
  graphql_name "DeleteSubmissionComment"

  argument :submission_comment_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("SubmissionComment")

  field :submission_comment, Types::SubmissionCommentType, null: true

  def resolve(input:)
    submission_comment = SubmissionComment.find_by(id: input[:submission_comment_id])

    response = {}
    if submission_comment&.grants_right?(current_user, :delete)
      submission_comment.updating_user = @current_user
      submission_comment.destroy

      response[:submission_comment] = submission_comment
    else
      raise GraphQL::ExecutionError, "Not authorized to delete SubmissionComment"
    end

    response
  end
end
