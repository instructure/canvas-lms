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

# @API Quiz Submissions
# @beta
#
# API for accessing quiz submissions
#
# @model QuizSubmission
#     {
#       "id": "QuizSubmission",
#       "required": ["id", "quiz_id"],
#       "properties": {
#         "id": {
#           "description": "The ID of the quiz submission.",
#           "example": 1,
#           "type": "integer",
#           "format": "int64"
#         },
#         "quiz_id": {
#           "description": "The ID of the Quiz the quiz submission belongs to.",
#           "example": 2,
#           "type": "integer",
#           "format": "int64"
#         },
#         "user_id": {
#           "description": "The ID of the Student that made the quiz submission.",
#           "example": 3,
#           "type": "integer",
#           "format": "int64"
#         },
#         "submission_id": {
#           "description": "The ID of the Submission the quiz submission represents.",
#           "example": 1,
#           "type": "integer",
#           "format": "int64"
#         },
#         "started_at": {
#           "description": "The time at which the student started the quiz submission.",
#           "example": "2013-11-07T13:16:18Z",
#           "type": "string",
#           "format": "date-time"
#         },
#         "finished_at": {
#           "description": "The time at which the student submitted the quiz submission.",
#           "example": "2013-11-07T13:16:18Z",
#           "type": "string",
#           "format": "date-time"
#         },
#         "end_at": {
#           "description": "The time at which the quiz submission will be overdue, and be flagged as a late submission.",
#           "example": "2013-11-07T13:16:18Z",
#           "type": "string",
#           "format": "date-time"
#         },
#         "attempt": {
#           "description": "For quizzes that allow multiple attempts, this field specifies the quiz submission attempt number.",
#           "example": 3,
#           "type": "integer",
#           "format": "int64"
#         },
#         "extra_attempts": {
#           "description": "Number of times the student was allowed to re-take the quiz over the multiple-attempt limit.",
#           "example": 1,
#           "type": "integer",
#           "format": "int64"
#         },
#         "extra_time": {
#           "description": "Amount of extra time allowed for the quiz submission, in seconds.",
#           "example": 60,
#           "type": "integer",
#           "format": "int64"
#         },
#         "time_spent": {
#           "description": "Amount of time spent, in seconds.",
#           "example": 300,
#           "type": "integer",
#           "format": "int64"
#         },
#         "score": {
#           "description": "The score of the quiz submission, if graded.",
#           "example": 3,
#           "type": "integer",
#           "format": "int64"
#         },
#         "score_before_regrade": {
#           "description": "The original score of the quiz submission prior to any re-grading.",
#           "example": 2,
#           "type": "integer",
#           "format": "int64"
#         },
#         "kept_score": {
#           "description": "For quizzes that allow multiple attempts, this is the score that will be used, which might be the score of the latest, or the highest, quiz submission.",
#           "example": 5,
#           "type": "integer",
#           "format": "int64"
#         },
#         "fudge_points": {
#           "description": "Number of points the quiz submission's score was fudged by.",
#           "example": 1,
#           "type": "integer",
#           "format": "int64"
#         },
#         "workflow_state": {
#           "description": "The current state of the quiz submission. Possible values: ['untaken'|'pending_review'|'complete'|'settings_only'|'preview'].",
#           "example": "untaken",
#           "type": "string"
#         }
#       }
#     }
#
class QuizSubmissionsApiController < ApplicationController
  include Api::V1::QuizSubmission
  include Api::V1::Helpers::QuizzesApiHelper
  include Api::V1::Helpers::QuizSubmissionsApiHelper

  before_filter :require_user, :require_context, :require_quiz
  before_filter :require_overridden_quiz, :except => [ :index ]
  before_filter :require_quiz_submission, :except => [ :index, :create ]
  before_filter :prepare_service, :only => [ :create, :complete ]

  # @API Get all quiz submissions.
  # @beta
  #
  # Get a list of all submissions for this quiz.
  #
  # @argument include[] [String, "submission"|"quiz"|"user"]
  #   Associations to include with the quiz submission.
  #
  # <b>200 OK</b> response code is returned if the request was successful.
  #
  # @example_response
  #  {
  #    "quiz_submissions": [QuizSubmission]
  #  }
  def index
    if authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])
      scope = @quiz.quiz_submissions.where(:user_id => visible_user_ids)
      api_route = polymorphic_url([:api, :v1, @context, @quiz, :submissions])

      quiz_submissions = Api.paginate(scope, self, api_route)

      includes = Array(params[:include])
      out = quiz_submissions_json(quiz_submissions, @quiz, @current_user, session, @context, includes)

      render :json => out
    end
  end

  # @API Get a single quiz submission.
  # @beta
  #
  # Get a single quiz submission.
  #
  # @argument include[] [String, "submission"|"quiz"|"user"]
  #   Associations to include with the quiz submission.
  #
  # <b>200 OK</b> response code is returned if the request was successful.
  #
  # @example_response
  #  {
  #    "quiz_submissions": [QuizSubmission]
  #  }
  def show
    if authorized_action(@quiz_submission, @current_user, :read)
      render_quiz_submission(@quiz_submission)
    end
  end

  # @API Create the quiz submission (start a quiz-taking session)
  # @beta
  #
  # Start taking a Quiz by creating a QuizSubmission which you can use to answer
  # questions and submit your answers.
  #
  # @argument validation_token [String]
  #   The unique validation token you received when this Quiz Submission was
  #   created.
  #
  # @argument access_code [Optional, String]
  #   Access code for the Quiz, if any.
  #
  # @argument preview [Optional, Boolean]
  #   Whether this should be a preview QuizSubmission and not count towards
  #   the user's course record. Teachers only.
  #
  # <b>Responses</b>
  #
  # * <b>200 OK</b> if the request was successful
  # * <b>400 Bad Request</b> if the quiz is locked
  # * <b>403 Forbidden</b> if an invalid access code is specified
  # * <b>403 Forbidden</b> if the Quiz's IP filter restriction does not pass
  # * <b>409 Conflict</b> if a QuizSubmission already exists for this user and quiz
  #
  # @example_response
  #  {
  #    "quiz_submissions": [QuizSubmission]
  #  }
  def create
    quiz_submission = if previewing?
      @service.create_preview(@quiz, session)
    else
      @service.create(@quiz)
    end

    log_asset_access(@quiz, 'quizzes', 'quizzes', 'participate')

    render_quiz_submission(quiz_submission)
  end

  def update
  end

  # @API Complete the quiz submission (turn it in).
  # @beta
  #
  # Complete the quiz submission by marking it as complete and grading it. When
  # the quiz submission has been marked as complete, no further modifications
  # will be allowed.
  #
  # @argument attempt [Integer]
  #   The attempt number of the quiz submission that should be completed. Note
  #   that this must be the latest attempt index, as earlier attempts can not
  #   be modified.
  #
  # @argument validation_token [String]
  #   The unique validation token you received when this Quiz Submission was
  #   created.
  #
  # @argument access_code [Optional, String]
  #   Access code for the Quiz, if any.
  #
  # <b>Responses</b>
  #
  # * <b>200 OK</b> if the request was successful
  # * <b>403 Forbidden</b> if an invalid access code is specified
  # * <b>403 Forbidden</b> if the Quiz's IP filter restriction does not pass
  # * <b>403 Forbidden</b> if an invalid token is specified
  # * <b>400 Bad Request</b> if the QS is already complete
  # * <b>400 Bad Request</b> if the attempt parameter is missing
  # * <b>400 Bad Request</b> if the attempt parameter is not the latest attempt
  #
  # @example_response
  #  {
  #    "quiz_submissions": [QuizSubmission]
  #  }
  def complete
    @service.complete @quiz_submission, params[:attempt]

    render_quiz_submission(@quiz_submission)
  end

  private

  def previewing?
    !!params[:preview]
  end

  def visible_user_ids(opts = {})
    scope = @context.enrollments_visible_to(@current_user, opts)
    scope.pluck(:user_id)
  end

  def render_quiz_submission(qs)
    render :json => quiz_submissions_json([ qs ],
      @quiz,
      @current_user,
      session,
      @context,
      Array(params[:include]))
  end
end
