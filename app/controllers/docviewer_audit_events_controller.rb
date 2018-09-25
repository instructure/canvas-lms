#
# Copyright (C) 2018 - present Instructure, Inc.
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

class DocviewerAuditEventsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :check_jwt_token

  def create
    submission = Submission.find(params[:submission_id])
    canvadoc = canvadoc_from_submission(submission, params[:document_id])
    assignment = submission.assignment
    user = User.find(params[:canvas_user_id])

    unless assignment.moderated_grading? || assignment.anonymous_grading?
      return render json: {message: 'Assignment is neither anonymous nor moderated'}, status: :not_acceptable
    end

    if assignment.moderated_grading? && !assignment.grades_published? && !admin_or_student(user, assignment.course)
      begin
        assignment.ensure_grader_can_adjudicate(grader: user, provisional: true, occupy_slot: true)
      rescue Assignment::MaxGradersReachedError
        return render json: {message: 'Reached maximum number of graders for assignment'}, status: :forbidden
      end
    end

    event_params = docviewer_audit_event_params
    event = AnonymousOrModerationEvent.new(
      assignment: assignment,
      canvadoc: canvadoc,
      event_type: "docviewer_#{event_params[:event_type]}",
      submission: submission,
      user: user,
      payload: {
        annotation_body: event_params[:annotation_body],
        annotation_id: event_params[:annotation_id],
        context: event_params[:context],
        related_annotation_id: event_params[:related_annotation_id]
      },
    )

    respond_to do |format|
      if event.save
        format.json { render json: event.as_json, status: :ok }
      else
        format.json { render json: event.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def admin_or_student(user, course)
    return true if course.account_membership_allows(user)
    enrollment = user.enrollments.find_by!(course: course)
    enrollment.student_or_fake_student?
  end

  def check_jwt_token
    Canvas::Security.decode_jwt(params[:token], [Canvadoc.jwt_secret])
  rescue
    return render json: {message: 'JWT signature invalid'}, status: :unauthorized
  end

  def docviewer_audit_event_params
    params.require(:docviewer_audit_event).permit(
      :annotation_id,
      :context,
      :event_type,
      :related_annotation_id,
      annotation_body: %i[color content created_at modified_at page type]
    )
  end

  def canvadoc_from_submission(submission, document_id)
    submission.submission_history.reverse_each do |versioned_submission|
      attachments = versioned_submission.versioned_attachments

      attachments.each do |attachment|
        canvadoc = attachment.canvadoc
        return canvadoc if canvadoc&.document_id == document_id
      end
    end

    raise ActiveRecord::RecordNotFound, 'No canvadoc with given document id was found for this submission'
  end
end
