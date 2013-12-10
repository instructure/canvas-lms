#
# Copyright (C) 2011 - 2012 Instructure, Inc.
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

# @API Quiz Submission Questions
# @beta
#

class QuizSubmissionQuestionsController < ApplicationController
  include Api::V1::QuizSubmissionQuestion
  include Api::V1::Helpers::QuizzesApiHelper
  include Api::V1::Helpers::QuizSubmissionsApiHelper

  before_filter :require_user,
    :require_quiz_submission,
    :export_scopes,
    :prepare_service,
    :validate_ldb_status!,
    :require_question

  # @API Answering a question.
  # @beta
  #
  # Provide or modify an answer to a QuizQuestion.
  #
  # @argument attempt [Integer]
  #   The attempt number of the quiz submission being taken. Note that this
  #   must be the latest attempt index, as questions for earlier attempts can
  #   not be modified.
  #
  # @argument validation_token [String]
  #   The unique validation token you received when the Quiz Submission was
  #   created.
  #
  # @argument access_code [Optional, String]
  #   Access code for the Quiz, if any.
  #
  # @argument answer [Optional, Mixed]
  #   The answer to the question. The type and format of this argument depend
  #   on the question type.
  #
  #   See {Appendix: Question Answer Formats} for the accepted answer formats
  #   for each question type.
  #
  # @example_request
  #  {
  #    "attempt": 1,
  #    "validation_token": "YOUR_VALIDATION_TOKEN",
  #    "access_code": null,
  #    "answer": "Hello World!"
  #  }
  def answer
    unless params.has_key?(:answer)
      reject! 400, 'missing required parameter :answer'
    end

    serializer = QuizQuestion::AnswerSerializers.serializer_for @question
    serialization_rc = serializer.serialize(params[:answer])

    unless serialization_rc.valid?
      reject! 400, serialization_rc.error
    end

    submission_data = @service.update_question(serialization_rc.answer,
      @quiz_submission,
      params[:attempt])

    render json: quiz_submission_questions_json([ @question ], submission_data)
  end

  # @API Flagging a question.
  # @beta
  #
  # Set a flag on a quiz question to indicate that you want to return to it
  # later.
  #
  # @argument attempt [Integer]
  #   The attempt number of the quiz submission being taken. Note that this
  #   must be the latest attempt index, as questions for earlier attempts can
  #   not be modified.
  #
  # @argument validation_token [String]
  #   The unique validation token you received when the Quiz Submission was
  #   created.
  #
  # @argument access_code [Optional, String]
  #   Access code for the Quiz, if any.
  #
  # @example_request
  #  {
  #    "attempt": 1,
  #    "validation_token": "YOUR_VALIDATION_TOKEN",
  #    "access_code": null
  #  }
  def flag
    render json: quiz_submission_questions_json([ @question ],
      flag_current_question(true))
  end

  # @API Unflagging a question.
  # @beta
  #
  # Remove the flag that you previously set on a quiz question after you've
  # returned to it.
  #
  # @argument attempt [Integer]
  #   The attempt number of the quiz submission being taken. Note that this
  #   must be the latest attempt index, as questions for earlier attempts can
  #   not be modified.
  #
  # @argument validation_token [String]
  #   The unique validation token you received when the Quiz Submission was
  #   created.
  #
  # @argument access_code [Optional, String]
  #   Access code for the Quiz, if any.
  #
  # @example_request
  #  {
  #    "attempt": 1,
  #    "validation_token": "YOUR_VALIDATION_TOKEN",
  #    "access_code": null
  #  }
  def unflag
    render json: quiz_submission_questions_json([ @question ],
      flag_current_question(false))
  end

  private

  def require_question
    @question = @quiz.quiz_questions.find(params[:id].to_i)
  end

  # Export the Quiz and Course from the resolved QS.
  def export_scopes
    @quiz = @quiz_submission.quiz

    require_overridden_quiz

    @context = @quiz.context
  end

  # This is duplicated from QuizSubmissionsApiController and will be moved into
  # a Controller Filter once CNVS-10071 is in.
  #
  # [Transient:CNVS-10071]
  def validate_ldb_status!(quiz = @quiz)
    if quiz.require_lockdown_browser?
      unless ldb_plugin.authorized?(self)
        reject! 403, 'this quiz requires the lockdown browser'
      end
    end
  end

  # This is duplicated from QuizSubmissionsApiController and will be moved into
  # a Controller Filter once CNVS-10071 is in.
  #
  # [Transient:CNVS-10071]
  def ldb_plugin
    Canvas::LockdownBrowser.plugin.base
  end

  # Toggle a question's "flagged" status.
  #
  # @param [Boolean] flagged_unflagged
  #
  # @return [Hash] the QS's submission_data.
  def flag_current_question(flagged_unflagged)
    question_record = {}.with_indifferent_access
    question_record["question_#{@question.id}_marked"] = flagged_unflagged

    @service.update_question(question_record,
      @quiz_submission,
      params[:attempt],
      # we don't want a snapshot generated for each flagging action
      false)
  end

  # @!appendix Question Answer Formats
  #
  #  {include:file:doc/examples/quiz_question_answers.md}
end
