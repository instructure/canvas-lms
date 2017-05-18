#
# Copyright (C) 2011 - present Instructure, Inc.
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

module Filters::QuizSubmissions
  protected

  def require_overridden_quiz
    @quiz = @quiz.overridden_for(@current_user)
  end

  def require_quiz_submission(active: false)
    query = {}
    scope = @quiz ? @quiz.quiz_submissions : Quizzes::QuizSubmission
    id = if params.has_key?(:quiz_submission_id)
      params[:quiz_submission_id]
    else
      params[:id]
    end

    if active
      scope = scope.not_settings_only
    end

    if id.to_s == 'self'
      query[:user_id] = @current_user
    else
      query[:id] = id.to_i
    end

    unless @quiz_submission = scope.where(query).first
      # TODO: Should be a 404 Not Found, not a 500 error
      raise ActiveRecord::RecordNotFound.new('Quiz Submission not found')
    end

    @quiz_submission.ensure_question_reference_integrity!
    @quiz_submission
  end

  def require_active_quiz_submission
    require_quiz_submission(active: true)
  end

  def retrieve_quiz_submission_attempt!(attempt)
    unless @quiz_submission = @quiz_submission.model_for_attempt(attempt.to_i)
      reject! "unable to find a submission with that attempt", 404
    end
  end

  def prepare_service
    participant = Quizzes::QuizParticipant.new(@current_user, temporary_user_code)
    participant.access_code = params[:access_code]
    participant.ip_address = request.remote_ip
    participant.validation_token = params[:validation_token]

    @service = Quizzes::QuizSubmissionService.new(participant)
  end
end
