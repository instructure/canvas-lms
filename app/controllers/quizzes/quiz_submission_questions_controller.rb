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
# API for answering and flagging questions in a quiz-taking session.
#
# @model QuizSubmissionQuestion
#     {
#       "id": "QuizSubmissionQuestion",
#       "required": ["id"],
#       "properties": {
#         "id": {
#           "description": "The ID of the QuizQuestion this answer is for.",
#           "example": 1,
#           "type": "integer",
#           "format": "int64"
#         },
#         "flagged": {
#           "description": "Whether this question is flagged.",
#           "example": true,
#           "type": "boolean"
#         },
#         "answer": {
#           "description": "The provided answer (if any) for this question. The format of this parameter depends on the type of the question, see the Appendix for more information.",
#           "type": "string"
#         },
#         "answers": {
#           "description": "The possible answers for this question when those possible answers are necessary.  The presence of this parameter is dependent on permissions.",
#           "type": "array"
#         }
#       }
#     }
#
class Quizzes::QuizSubmissionQuestionsController < ApplicationController
  include Api::V1::QuizSubmissionQuestion
  include ::Filters::QuizSubmissions

  before_filter :require_user, :require_quiz_submission, :export_scopes
  before_filter :require_question, only: [ :show, :flag, :unflag ]
  before_filter :prepare_service, only: [ :answer, :flag, :unflag ]
  before_filter :validate_ldb_status!, only: [ :answer, :flag, :unflag ]

  # @API Get all quiz submission questions.
  # @beta
  #
  # Get a list of all the question records for this quiz submission.
  #
  # @argument include[] [String, "quiz_question"]
  #   Associations to include with the quiz submission question.
  #
  # <b>200 OK</b> response code is returned if the request was successful.
  #
  # @example_response
  #  {
  #    "quiz_submission_questions": [QuizSubmissionQuestion]
  #  }
  def index
    retrieve_quiz_submission_attempt!(params[:quiz_submission_attempt]) if params[:quiz_submission_attempt]

    reject! 'Cannot receive one question at a time questions in the API', 401 if @quiz.one_question_at_a_time && censored?

    if @quiz_submission.completed? && !@quiz_submission.results_visible?(user: @current_user)
      reject! "Cannot view questions due to quiz settings", 401
    end

    if authorized_action(@quiz_submission, @current_user, :read)
      render json: quiz_submission_questions_json(@quiz_submission.quiz_questions,
        @quiz_submission,
        {
          user: @current_user,
          session: session,
          includes: extract_includes,
          censored: censored?,
          shuffle_answers: @quiz.shuffle_answers_for_user?(@current_user)
        })
    end
  end

  # @API Answering questions
  # @beta
  #
  # Provide or update an answer to one or more QuizQuestions.
  #
  # @argument attempt [Required, Integer]
  #   The attempt number of the quiz submission being taken. Note that this
  #   must be the latest attempt index, as questions for earlier attempts can
  #   not be modified.
  #
  # @argument validation_token [Required, String]
  #   The unique validation token you received when the Quiz Submission was
  #   created.
  #
  # @argument access_code [String]
  #   Access code for the Quiz, if any.
  #
  # @argument quiz_questions[] [QuizSubmissionQuestion]
  #   Set of question IDs and the answer value.
  #
  #   See {Appendix: Question Answer Formats} for the accepted answer formats
  #   for each question type.
  #
  # @example_request
  #  {
  #    "attempt": 1,
  #    "validation_token": "YOUR_VALIDATION_TOKEN",
  #    "access_code": null,
  #    "quiz_questions": [{
  #      "id": "1",
  #      "answer": "Hello World!"
  #    }, {
  #      "id": "2",
  #      "answer": 42.0
  #    }]
  #  }
  #
  # @returns [QuizSubmissionQuestion]
  def answer
    unless @quiz_submission.grants_right?(@service.participant.user, :update)
      reject! 'you are not allowed to update questions for this quiz submission', 403
    end

    answers = params.fetch(:quiz_questions, []).reduce({}) do |hsh, p|
      if p[:id].present?
        hsh[p[:id].to_i] = p[:answer] || []
      end

      hsh
    end

    quiz_questions = @quiz.quiz_questions.where(id: answers.keys)

    record = quiz_questions.reduce({}) do |hsh, quiz_question|
      serializer = serializer_for quiz_question
      serialization_rc = serializer.serialize(answers[quiz_question.id])

      unless serialization_rc.valid?
        reject! serialization_rc.error, 400
      end

      hsh.merge serialization_rc.answer
    end

    @service.update_question(record, @quiz_submission, params[:attempt])

    render json: quiz_submission_questions_json(quiz_questions.all, @quiz_submission.reload, censored: true)
  end

  # @API Flagging a question.
  # @beta
  #
  # Set a flag on a quiz question to indicate that you want to return to it
  # later.
  #
  # @argument attempt [Required, Integer]
  #   The attempt number of the quiz submission being taken. Note that this
  #   must be the latest attempt index, as questions for earlier attempts can
  #   not be modified.
  #
  # @argument validation_token [Required, String]
  #   The unique validation token you received when the Quiz Submission was
  #   created.
  #
  # @argument access_code [String]
  #   Access code for the Quiz, if any.
  #
  # @example_request
  #  {
  #    "attempt": 1,
  #    "validation_token": "YOUR_VALIDATION_TOKEN",
  #    "access_code": null
  #  }
  def flag
    unless @quiz_submission.grants_right?(@service.participant.user, :update)
      reject! 'you are not allowed to update questions for this quiz submission', 403
    end
    flag_current_question(true)
    render json: quiz_submission_questions_json([ @question ],
      @quiz_submission.reload)
  end

  # @API Unflagging a question.
  # @beta
  #
  # Remove the flag that you previously set on a quiz question after you've
  # returned to it.
  #
  # @argument attempt [Required, Integer]
  #   The attempt number of the quiz submission being taken. Note that this
  #   must be the latest attempt index, as questions for earlier attempts can
  #   not be modified.
  #
  # @argument validation_token [Required, String]
  #   The unique validation token you received when the Quiz Submission was
  #   created.
  #
  # @argument access_code [String]
  #   Access code for the Quiz, if any.
  #
  # @example_request
  #  {
  #    "attempt": 1,
  #    "validation_token": "YOUR_VALIDATION_TOKEN",
  #    "access_code": null
  #  }
  def unflag
    unless @quiz_submission.grants_right?(@service.participant.user, :update)
      reject! 'you are not allowed to update questions for this quiz submission', 403
    end
    flag_current_question(false)
    render json: quiz_submission_questions_json([ @question ],
      @quiz_submission.reload)
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
        reject! 'this quiz requires the lockdown browser', 403
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

  def extract_includes(key = :include, hash = params)
    Array(hash[key])
  end

  def serializer_for(quiz_question)
    Quizzes::QuizQuestion::AnswerSerializers.serializer_for(quiz_question)
  end

  def censored?
    !@quiz.grants_right?(@current_user, session, :update)
  end

  # @!appendix Question Answer Formats
  #
  #  {include:file:doc/examples/quiz_question_answers.md}
end
