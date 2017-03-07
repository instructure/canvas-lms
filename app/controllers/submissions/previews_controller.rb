# Copyright (C) 2016 Instructure, Inc.
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
module Submissions
  class PreviewsController < ApplicationController
    include KalturaHelper
    include Submissions::ShowHelper
    before_action :require_context

    rescue_from ActiveRecord::RecordNotFound, with: :render_user_not_found
    def show
      service = Submissions::SubmissionForShow.new(
        @context, params.slice(:assignment_id, :id, :preview, :version)
      )
      @assignment = service.assignment
      @user       = service.user
      @submission = service.submission
      prepare_js_env
      @assessment_request = @submission.assessment_requests.where(assessor_id: @current_user).first
      @body_classes << 'is-inside-submission-frame'

      if @assignment.moderated_grading?
        @crocodoc_ids = @submission.crocodoc_whitelist
      end

      unless @assignment.visible_to_user?(@current_user)
        flash[:notice] = t('This assignment will no longer count towards your grade.')
      end

      @headers = false
      if authorized_action(@submission, @current_user, :read)
        if redirect?
          redirect_to(
            named_context_url(
              @context, redirect_path_name, @assignment.quiz.id, redirect_params
            )
          )
        else
          render 'submissions/show_preview'
        end
      end
    end

    private
    def current_user_is_student?
      @context.user_is_student?(@current_user) && !@context.user_is_instructor?(@current_user)
    end

    def redirect?
      redirect_to_quiz? || redirect_to_quiz_history?
    end

    def prepare_js_env
      hash = {CONTEXT_ACTION_SOURCE: :submissions}
      append_sis_data(hash)
      js_env(hash)
    end

    def redirect_params
      return { headless: 1 }.tap do |h|
        if redirect_to_quiz_history?
          h.merge!({
            hide_student_name: params[:hide_student_name],
            user_id: @submission.user_id,
            version: params[:version] || @submission.quiz_submission_version
          })
        end
      end
    end

    def redirect_path_name
      if redirect_to_quiz?
        :context_quiz_url
      else
        :context_quiz_history_url
      end
    end

    def redirect_to_quiz?
      @assignment.quiz && @context.is_a?(Course) && current_user_is_student?
    end

    def redirect_to_quiz_history?
      !redirect_to_quiz? && (
        @submission.submission_type == "online_quiz" && @submission.quiz_submission_version
      )
    end
  end
end
