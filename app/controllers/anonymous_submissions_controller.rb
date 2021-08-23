# frozen_string_literal: true

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

class AnonymousSubmissionsController < SubmissionsBaseController
  include Submissions::ShowHelper

  before_action :require_context

  def show
    @submission_for_show = Submissions::AnonymousSubmissionForShow.new(
      assignment_id: params.fetch(:assignment_id),
      anonymous_id: params.fetch(:anonymous_id),
      context: @context
    )
    begin
      @assignment = @submission_for_show.assignment
      @submission = @submission_for_show.submission
    rescue ActiveRecord::RecordNotFound
      return render_user_not_found
    end

    return render_user_not_found unless @submission.can_view_details?(@current_user)

    super
  end

  def update
    @assignment = @context.assignments.active.find(params.fetch(:assignment_id))
    @submission = @assignment.submissions.find_by!(anonymous_id: params.fetch(:anonymous_id))
    @user = @submission.user

    super
  end

  def redo_submission
    @assignment = @context.assignments.active.find(params.fetch(:assignment_id))
    @submission = @assignment.submissions.find_by!(anonymous_id: params.fetch(:anonymous_id))
    @user = @submission.user

    super
  end

  def plagiarism_report(type)
    return head(:bad_request) unless params_are_integers?(:assignment_id)

    @assignment = @context.assignments.active.find(params.require(:assignment_id))
    @submission = @assignment.submissions.find_by(anonymous_id: params.require(:anonymous_id))

    super(type)
  end

  def resubmit_to_plagiarism(type)
    return head(:bad_request) unless params_are_integers?(:assignment_id)

    @assignment = @context.assignments.active.find(params.require(:assignment_id))
    @submission = @assignment.submissions.find_by(anonymous_id: params.require(:anonymous_id))

    super(type)
  end

  private
  def default_plagiarism_redirect_url
    speed_grader_course_gradebook_url(
      @context,
      assignment_id: @assignment.id,
      anonymous_id: @submission.anonymous_id
    )
  end
end
