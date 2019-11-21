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

class Submission::ShowPresenter
  include Rails.application.routes.url_helpers
  include ApplicationHelper

  def initialize(submission:, current_user:, assessment_request: nil)
    @submission = submission
    @current_user = current_user
    @assessment_request = assessment_request

    @assignment = @submission.assignment
    @context = @assignment.context
  end

  def default_url_options
    { protocol: HostUrl.protocol, host: HostUrl.context_host(@context.root_account) }
  end

  # NB: Currently this method assumes that the only possible source of anonymity
  # on the submission details is anonymous peer reviews (since teachers cannot
  # view the page at all if anonymous grading is enabled). If it becomes possible
  # to view submission details anonymously as a teacher, this check will need to
  # be adjusted accordingly.
  def anonymize_submission_owner?
    @assessment_request.present? && @assignment.anonymous_peer_reviews?
  end

  def add_comment_url
    if viewing_as_grader?
      context_url(@context, :update_submission_context_gradebook_url)
    else
      submission_data_url
    end
  end

  def add_comment_method
    if viewing_as_grader?
      "POST"
    else
      "PUT"
    end
  end

  def submission_data_url(**additional_params)
    submission_route = if anonymize_submission_owner?
      :context_assignment_anonymous_submission_url
    else
      :context_assignment_submission_url
    end

    context_url(@context, submission_route, @assignment.id, anonymizable_student_id, **additional_params)
  end

  def submission_preview_frame_url
    submission_data_url(preview: 1, rand: rand(999999))
  end

  def comment_attachment_download_url(submission_comment:, attachment:)
    submission_data_url(comment_id: submission_comment.id, download: attachment.id)
  end

  def comment_attachment_template_url
    submission_data_url(comment_id: "{{ comment_id }}", download: "{{ id }}")
  end

  def currently_peer_reviewing?
    @assessment_request&.assigned?
  end

  private
  def anonymizable_student_id
    anonymize_submission_owner? ? @submission.anonymous_id : @submission.user_id
  end

  def viewing_as_grader?
    !currently_peer_reviewing? && @context.grants_right?(@current_user, :manage_grades)
  end
end
