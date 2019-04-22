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

class Mutations::CreateSubmissionComment < Mutations::BaseMutation
  graphql_name 'CreateSubmissionComment'

  argument :submission_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func('Submission')
  argument :attempt, Integer, required: false
  argument :comment, String, required: true
  argument :file_ids, [ID], required: false, prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func('Attachment')
  argument :media_object_id, ID, required: false

  field :submission_comment, Types::SubmissionCommentType, null: true

  def resolve(input:)
    submission = Submission.find input[:submission_id]
    verify_authorized_action!(submission, :comment)

    opts = {
      attempt: input[:attempt],
      author: current_user,
      comment: input[:comment]
    }

    if input[:media_object_id].present?
      media_objects = MediaObject.by_media_id(input[:media_object_id])
      raise GraphQL::ExecutionError, 'not found' if media_objects.empty?
      opts[:media_comment_id] = input[:media_object_id]
    end

    file_ids = (input[:file_ids] || []).uniq
    unless file_ids.empty?
      attachments = Attachment.where(id: file_ids).to_a
      raise GraphQL::ExecutionError, 'not found' unless attachments.length == file_ids.length
      attachments.each do |a|
        verify_authorized_action!(a, :attach_to_submission_comment)
        a.ok_for_submission_comment = true
      end
      opts[:attachments] = attachments
    end

    assignment = submission.assignment
    comment = assignment.add_submission_comment(submission.user, opts).first
    {submission_comment: comment}
  rescue ActiveRecord::RecordInvalid => invalid
    errors_for(invalid.record)
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, 'not found'
  end
end
