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

class Mutations::CreateSubmissionComment < Mutations::BaseMutation
  graphql_name "CreateSubmissionComment"

  argument :submission_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Submission")
  argument :attempt, Integer, required: false
  argument :comment, String, required: true
  argument :file_ids, [ID], required: false, prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("Attachment")
  argument :media_object_id, ID, required: false
  argument :media_object_type, String, required: false
  argument :reviewer_submission_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Submission")

  field :submission_comment, Types::SubmissionCommentType, null: true

  def resolve(input:)
    submission = Submission.find input[:submission_id]
    verify_authorized_action!(submission, :comment)

    latest_attempt = submission.context.feature_enabled?(:assignments_2_student) ? submission.attempt : nil
    opts = {
      attempt: input[:attempt] || latest_attempt,
      author: current_user,
      comment: input[:comment]
    }

    if input[:media_object_id].present?
      media_objects = MediaObject.by_media_id(input[:media_object_id])
      raise GraphQL::ExecutionError, "not found" if media_objects.empty?

      opts[:media_comment_id] = input[:media_object_id]

      if input[:media_object_type].present?
        opts[:media_comment_type] = input[:media_object_type]
      end
    end

    file_ids = (input[:file_ids] || []).uniq
    unless file_ids.empty?
      attachments = Attachment.where(id: file_ids).to_a
      raise GraphQL::ExecutionError, "not found" unless attachments.length == file_ids.length

      attachments.each do |a|
        verify_authorized_action!(a, :attach_to_submission_comment)
        a.ok_for_submission_comment = true
      end
      opts[:attachments] = attachments
    end

    if input[:reviewer_submission_id].present?
      reviewer_submission = Submission.find input[:reviewer_submission_id]
      assessment_request = reviewer_submission
                           .assigned_assessments
                           .find_by(asset: submission)

      raise GraphQL::ExecutionError, "not found" if assessment_request.nil?

      opts[:assessment_request] = assessment_request
    end

    assignment = submission.assignment
    opts[:group_comment] = assignment.grade_as_group?

    comment = assignment.add_submission_comment(submission.user, opts).first
    comment.mark_read!(current_user)
    { submission_comment: comment }
  rescue ActiveRecord::RecordInvalid => e
    errors_for(e.record)
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, "not found"
  end
end
