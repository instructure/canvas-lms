# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

SUBMISSION_COMMENT_LIMIT = 200

class Mutations::MarkSubmissionCommentsRead < Mutations::BaseMutation
  graphql_name "MarkSubmissionCommentsRead"

  argument :submission_comment_ids, [ID], required: true, prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("SubmissionComment")
  argument :submission_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Submission")
  field :submission_comments, [Types::SubmissionCommentType], null: true

  def resolve(input:)
    submission = Submission.find(input[:submission_id])
    verify_authorized_action!(submission, :read_comments)

    input_sc_ids = submission.submission_comments
                             .where(id: input[:submission_comment_ids]).limit(SUBMISSION_COMMENT_LIMIT).pluck(:id)
    created_vscsc_ids = ViewedSubmissionComment.where(submission_comment_id: input[:submission_comment_ids], user: current_user).pluck(:submission_comment_id)
    ids_to_be_created = input_sc_ids - created_vscsc_ids
    ids_to_be_created.each do |sc_id|
      ViewedSubmissionComment.create!(submission_comment_id: sc_id, user: current_user)
    end
    { submission_comments: SubmissionComment.where(id: input_sc_ids) }
  rescue ActiveRecord::RecordInvalid => e
    errors_for(e.record)
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, "not found"
  end
end
