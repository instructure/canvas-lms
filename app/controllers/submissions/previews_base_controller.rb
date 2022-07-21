# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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
  class PreviewsBaseController < ApplicationController
    include KalturaHelper
    include Submissions::ShowHelper
    include CoursesHelper

    before_action :require_context

    rescue_from ActiveRecord::RecordNotFound, with: :render_user_not_found

    def show
      @assignment = @submission_for_show.assignment
      @user = @submission_for_show.user
      @submission = @submission_for_show.submission
      @enrollment_type = user_type(@context, @current_user)

      prepare_js_env

      @assessment_request = @submission.assessment_requests.where(assessor_id: @current_user).first
      @body_classes << "is-inside-submission-frame"

      # We're re-using the preview view for viewing Student Annotation
      # submissions in SpeedGrader, but the default padding for previews does
      # not work well for SpeedGrader.
      if @submission.submission_type == "student_annotation"
        @body_classes.push("full-width", "student-annotation-container")
      end

      if @assignment.moderated_grading?
        @moderated_grading_allow_list = @submission.moderated_grading_allow_list
      end

      @anonymous_instructor_annotations = @context.grants_right?(@current_user, :manage_grades) &&
                                          @assignment.anonymous_instructor_annotations

      unless @assignment.visible_to_user?(@current_user)
        flash[:notice] = t("This assignment will no longer count towards your grade.")
      end

      @headers = false
      if authorized_action(@submission, @current_user, :read)
        if redirect? && @assignment&.quiz&.id
          redirect_to(named_context_url(@context, redirect_path_name, @assignment.quiz.id, redirect_params))
        else
          @anonymize_students = anonymize_students?
          render template: "submissions/show_preview", locals: {
            anonymize_students: @anonymize_students
          }
        end
      end
    end

    protected

    def anonymize_students?
      if current_user_is_student?
        @submission_for_show.assignment.anonymous_peer_reviews? && @submission_for_show.submission.peer_reviewer?(@current_user)
      elsif current_user_is_observing_submission_owner?
        false
      else
        @submission_for_show.assignment.anonymize_students?
      end
    end

    private

    def current_user_is_student?
      @context.user_is_student?(@current_user) && !@context.user_is_instructor?(@current_user)
    end

    def current_user_is_observing_submission_owner?
      @context_enrollment.present? && @current_user.present? && @context_enrollment.observer? && @submission_for_show.submission.observer?(@current_user)
    end

    def redirect?
      redirect_to_quiz? || redirect_to_quiz_history?
    end

    def prepare_js_env
      hash = {
        CONTEXT_ACTION_SOURCE: :submissions,
        EMOJIS_ENABLED: @context.feature_enabled?(:submission_comment_emojis),
        EMOJI_DENY_LIST: @context.root_account.settings[:emoji_deny_list]
      }
      append_sis_data(hash)
      js_env(hash)
    end

    def redirect_params
      { headless: 1 }.tap do |h|
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
      !redirect_to_quiz? && (@submission.submission_type == "online_quiz" && @submission.quiz_submission_version)
    end
  end
end
