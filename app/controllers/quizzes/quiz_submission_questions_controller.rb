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
#           "description": "The provided answer (if any) for this question. The format of this parameter depends on the type of the question, see the Appendix for more information."
#         }
#       }
#     }
#
class Quizzes::QuizSubmissionQuestionsController < ApplicationController
  include Api::V1::QuizSubmissionQuestion
  include Filters::QuizSubmissions

  before_filter :require_user, :require_quiz_submission, :export_scopes
  before_filter :require_question, except: [ :index ]
  before_filter :prepare_service, except: [ :index, :show ]
  before_filter :validate_ldb_status!, except: [ :index, :show ]

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
    if authorized_action(@quiz_submission, @current_user, :read)
      render json: quiz_submission_questions_json(@quiz.quiz_questions,
        @quiz_submission.submission_data,
        {
          user: @current_user,
          session: session,
          includes: extract_includes
        })
    end
  end

  # @API Get a single quiz submission question.
  # @beta
  #
  # Get a single question record.
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
  def show
    if authorized_action(@quiz_submission, @current_user, :read)
      render json: quiz_submission_questions_json(@question,
        @quiz_submission.submission_data,
        {
          user: @current_user,
          session: session,
          includes: extract_includes
        })
    end
  end

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
      reject! 'missing required parameter :answer', 400
    end

    serializer = Quizzes::QuizQuestion::AnswerSerializers.serializer_for @question
    serialization_rc = serializer.serialize(params[:answer])

    unless serialization_rc.valid?
      reject! serialization_rc.error, 400
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

  # @!appendix Question Answer Formats
  #
  #  {include:file:doc/examples/quiz_question_answers.md}
end
