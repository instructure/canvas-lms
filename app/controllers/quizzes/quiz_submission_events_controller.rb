#
# Copyright (C) 2014 Instructure, Inc.
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

class Quizzes::QuizSubmissionEventsController < ApplicationController
  include Filters::Quizzes
  include Filters::QuizSubmissions

  before_filter :require_user, :require_context
  before_filter :require_quiz, :only => [ :index ]
  before_filter :require_quiz_submission, :only => [ :index ]

  protect_from_forgery :only => [ :index ]

  def index
    authorized_action(@quiz_submission, @current_user, :read)

    unless @context.feature_enabled?(:quiz_log_auditing)
      flash[:error] = t('errors.quiz_log_auditing_required',
      "The quiz log auditing feature needs to be enabled for this course.")

      return redirect_to named_context_url(@context, :context_quiz_history_url,
        @quiz.id,
        user_id: @quiz_submission.user_id)
    end

    dont_show_user_name = @quiz.anonymous_submissions || (!@quiz_submission.user || @quiz_submission.user == @current_user)

    add_crumb(t('#crumbs.quizzes', "Quizzes"), named_context_url(@context, :context_quizzes_url))
    add_crumb(@quiz.title, named_context_url(@context, :context_quiz_url, @quiz))

    submission_crumb = if dont_show_user_name
      t(:default_submission_crumb, "Submission %{id}", { id: @quiz_submission.id })
    else
      @quiz_submission.user.name
    end

    add_crumb(submission_crumb, named_context_url(@context, :context_quiz_quiz_submission_url, @quiz, @quiz_submission))
    add_crumb(t(:log_crumb, "Log"), course_quiz_quiz_submission_events_url(@context, @quiz, @quiz_submission))

    js_env({
      quiz_url: api_v1_course_quiz_url(@context, @quiz),
      questions_url: api_v1_course_quiz_questions_url(@context, @quiz, quiz_submission_id: @quiz_submission.id, quiz_submission_attempt: @quiz_submission.attempt),
      submission_url: api_v1_course_quiz_submission_url(@context, @quiz, @quiz_submission),
      events_url: api_v1_course_quiz_submission_events_url(@context, @quiz, @quiz_submission),
      can_view_answer_audits: @quiz.grants_right?(@current_user, :view_answer_audits)
    })
  end
end
