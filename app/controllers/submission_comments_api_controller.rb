# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

# @API Submission Comments
#
# This API can be used to edit and delete submission comments.
class SubmissionCommentsApiController < ApplicationController
  before_action :require_context

  include Api::V1::Attachment
  include Api::V1::SubmissionComment

  # @API Edit a submission comment
  #
  # Edit the given submission comment.
  #
  # @argument comment [String]
  #   If this argument is present, edit the text of a comment.
  #
  # @returns SubmissionComment
  def update
    submission_comment = SubmissionComment.find(params[:id])
    if authorized_action(submission_comment, @current_user, :update)
      submission_comment.updating_user = @current_user
      submission_comment.reload unless submission_comment.update(submission_comment_params)

      render json: submission_comment_json(
        submission_comment,
        @current_user
      )
    end
  end

  def submission_comment_params
    params.permit(:comment)
  end

  # @API Delete a submission comment
  #
  # Delete the given submission comment.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/courses/<course_id>/assignments/<assignment_id>/submissions/<user_id>/comments/<id> \
  #          -X DELETE \
  #          -H 'Authorization: Bearer <token>'
  # @returns SubmissionComment
  def destroy
    submission_comment = SubmissionComment.find(params[:id])
    if authorized_action(submission_comment, @current_user, :delete)
      comment_data = anonymous_moderated_submission_comments_json(
        assignment: submission_comment.submission.assignment,
        course: @context,
        current_user: @current_user,
        avatars: service_enabled?(:avatars),
        submission_comments: [submission_comment],
        submissions: [submission_comment.submission]
      )[0]

      submission_comment.updating_user = @current_user
      submission_comment.destroy!

      render json: comment_data
    end
  end

  # @API Upload a file
  #
  # Upload a file to attach to a submission comment
  #
  # See the {file:file_uploads.html File Upload Documentation} for details on the file upload workflow.
  #
  # The final step of the file upload workflow will return the attachment data,
  # including the new file id. The caller can then PUT the file_id to the
  # submission API to attach it to a comment
  def create_file
    @assignment = api_find(@context.assignments.active, params[:assignment_id])
    @user = api_find(@context.students_visible_to(@current_user, include: :inactive),
                     params[:user_id])

    if authorized_action?(@assignment,
                          @current_user,
                          :attach_submission_comment_files)
      api_attachment_preflight(@assignment, request, check_quota: false)
    end
  end

  # Internal: annotation_notification
  #
  # Send notification of annotation to other users of the submission
  # Must have permission to send_messages on Site Admin account.
  # annotation notifications go to all users on the submission and the observers for those users.
  # annotation notifications also go to the instructors unless it is sent from an instructor.
  # annotation notifications from instructors go to students if assignment is set to post automatically or if the assignment is posted.
  #
  # @argument author_id [Required, String]
  #   The user that created the annotation
  #
  # @example_request
  #    curl https://<canvas>/api/v1/courses/:course_id/assignments/:assignment_id/submissions/:user_id/annotation_notification
  #      -H 'Authorization: Bearer <token>' \
  #      -X POST \
  #      -F "author_id": "1"
  #
  # returns {}, status 200
  def annotation_notification
    GuardRail.activate(:secondary) do
      if authorized_action?(Account.site_admin, @current_user, :send_messages)
        assignment = api_find(@context.assignments.active, params[:assignment_id])
        author = assignment.shard.activate { api_find(User.active, params[:author_id]) }
        user = api_find(@context.all_current_users, params[:user_id])
        submission = assignment.submissions.where(user_id: user).take
        unless submission
          return render json: { error: "Couldn't find Submission for user with API id #{params[:user_id]}" },
                        status: :bad_request
        end

        GuardRail.activate(:primary) { user.mark_submission_annotations_unread!(submission) } unless user == author

        instructors = @context.instructors_in_charge_of(user)

        # If the author is an instructor, check post_policies to see if we should notify others.
        # Don't notify other instructors if author is an instructor
        #
        if author_is_instructor?(author, instructors)
          # author is instructors, so check post_policies, if submission is not posted
          # and not set to automatically post, don't notify anyone.
          if assignment.post_manually? && !submission.posted?
            return render json: {}, status: :ok
          end
        else # author is a student or admin
          # always notify instructor
          broadcast_annotation_notification(submission:, to_list: instructors, data: broadcast_data(author))
        end

        submissions_by_user_id = if submission.group_id
                                   assignment.submissions.where(user_id: submission.group.users.select(:id)).index_by(&:user_id)
                                 else
                                   # if the user is the author there are no more people to notify.
                                   return render json: {}, status: :ok if author == user

                                   { user.id => submission }
                                 end

        # either an instructor made the annotation, and it should go to users and observers,
        # or this is a group assignment, and other users + observers should be notified.
        observers_by_user = User.observing_students_in_course(submissions_by_user_id.keys - [author.id], @context)
                                .select("users.id, associated_user_id").group_by(&:associated_user_id)
        submissions_by_user_id.each_value do |sub|
          to_list = Array(observers_by_user[sub.user_id]) + ["user_#{sub.user_id}"] - ["user_#{author.id}"]
          broadcast_annotation_notification(submission: sub, to_list:, data: broadcast_data(author), teacher: false)
        end

        render json: {}, status: :ok
      end
    end
  end

  private

  def author_is_instructor?(author, instructors)
    !!instructors.include?(author)
  end

  def broadcast_data(author)
    data = @context.broadcast_data
    data.merge({ author_name: author.name, author_id: author.id })
  end

  def broadcast_annotation_notification(submission:, to_list:, data:, teacher: true)
    return if to_list.empty?
    return unless submission

    notification_type = teacher ? "Annotation Teacher Notification" : "Annotation Notification"
    notification = BroadcastPolicy.notification_finder.by_name(notification_type)

    GuardRail.activate(:primary) do
      BroadcastPolicy.notifier.send_notification(submission, notification_type, notification, to_list, data)
    end
  end
end
