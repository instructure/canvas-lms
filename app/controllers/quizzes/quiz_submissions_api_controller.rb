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
#         "manually_unlocked": {
#           "description": "The student can take the quiz even if it's locked for everyone else",
#           "example": true,
#           "type": "boolean"
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
class Quizzes::QuizSubmissionsApiController < ApplicationController
  include Api::V1::QuizSubmission
  include Filters::Quizzes
  include Filters::QuizSubmissions

  before_filter :require_user, :require_context, :require_quiz
  before_filter :require_overridden_quiz, :except => [ :index ]
  before_filter :require_quiz_submission, :except => [ :index, :create ]
  before_filter :prepare_service, :only => [ :create, :update, :complete ]
  before_filter :validate_ldb_status!, :only => [ :create, :complete ]

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
    quiz_submissions = if is_authorized_action?(@context, @current_user, [:manage_grades, :view_all_grades])
      # teachers have access to all student submissions
      Api.paginate @quiz.quiz_submissions.where(:user_id => visible_user_ids),
        self,
        api_v1_course_quiz_submissions_url(@context, @quiz)
    elsif is_authorized_action?(@quiz, @current_user, :submit)
      # students have access only to their own
      @quiz.quiz_submissions.where(:user_id => @current_user)
    end

    if !quiz_submissions
      render_unauthorized_action
    else
      serialize_and_render quiz_submissions
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
      serialize_and_render @quiz_submission
    end
  end

  # @API Create the quiz submission (start a quiz-taking session)
  # @beta
  #
  # Start taking a Quiz by creating a QuizSubmission which you can use to answer
  # questions and submit your answers.
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

    serialize_and_render quiz_submission
  end

  # @API Update student question scores and comments.
  # @beta
  #
  # Update the amount of points a student has scored for questions they've
  # answered, provide comments for the student about their answer(s), or simply
  # fudge the total score by a specific amount of points.
  #
  # @argument attempt [Integer]
  #   The attempt number of the quiz submission that should be updated. This
  #   attempt MUST be already completed.
  #
  # @argument fudge_points [Optional, Float]
  #   Amount of positive or negative points to fudge the total score by.
  #
  # @argument questions [Optional, Hash]
  #   A set of scores and comments for each question answered by the student.
  #   The keys are the question IDs, and the values are hashes of `score` and
  #   `comment` entries. See {Appendix: Manual Scoring} for more on this
  #   parameter.
  #
  # <b>Responses</b>
  #
  # * <b>200 OK</b> if the request was successful
  # * <b>403 Forbidden</b> if you are not a teacher in this course
  # * <b>400 Bad Request</b> if the attempt parameter is missing or invalid
  # * <b>400 Bad Request</b> if the specified QS attempt is not yet complete
  #
  # @see Appendix: Manual Scoring
  #
  # @example_request
  #  {
  #    "quiz_submissions": [{
  #      "attempt": 1,
  #      "fudge_points": -2.4,
  #      "questions": {
  #        "1": {
  #          "score": 2.5,
  #          "comment": "This can't be right, but I'll let it pass this one time."
  #        },
  #        "2": {
  #          "score": 0,
  #          "comment": "Good thinking. Almost!"
  #        }
  #      }
  #    }]
  #  }
  #
  # @example_response
  #  {
  #    "quiz_submissions": [QuizSubmission]
  #  }
  #
  # @!appendix Manual Scoring
  #
  #   {include:file:doc/examples/quiz_submission_manual_scoring.md}
  def update
    resource_params = params[:quiz_submissions]

    unless resource_params.is_a?(Array)
      reject! 'missing required key :quiz_submissions'
    end

    if resource_params = resource_params[0]
      @service.update_scores(@quiz_submission,
        resource_params[:attempt],
        resource_params)
    end

    serialize_and_render @quiz_submission
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

    serialize_and_render @quiz_submission
  end

  private

  def previewing?
    !!params[:preview]
  end

  def visible_user_ids(opts = {})
    scope = @context.enrollments_visible_to(@current_user, opts)
    scope.pluck(:user_id)
  end

  def serialize_and_render(quiz_submissions)
    quiz_submissions = [ quiz_submissions ] unless quiz_submissions.is_a? Array

    render :json => quiz_submissions_json(quiz_submissions,
      @quiz,
      @current_user,
      session,
      @context,
      Array(params[:include]))
  end

  def validate_ldb_status!(quiz = @quiz)
    if quiz.require_lockdown_browser?
      unless ldb_plugin.authorized?(self)
        reject! 'this quiz requires the lockdown browser', :forbidden
      end
    end
  end

  def ldb_plugin
    Canvas::LockdownBrowser.plugin.base
  end
end
