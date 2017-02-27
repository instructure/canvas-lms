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
#           "description": "Amount of extra time allowed for the quiz submission, in minutes.",
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
#         "has_seen_results": {
#           "description": "Whether the student has viewed their results to the quiz.",
#           "example": true,
#           "type": "boolean"
#         },
#         "workflow_state": {
#           "description": "The current state of the quiz submission. Possible values: ['untaken'|'pending_review'|'complete'|'settings_only'|'preview'].",
#           "example": "untaken",
#           "type": "string"
#         },
#         "overdue_and_needs_submission": {
#           "description": "Indicates whether the quiz submission is overdue and needs submission",
#           "example": "false",
#           "type": "boolean"
#         }
#       }
#     }
#
class Quizzes::QuizSubmissionsApiController < ApplicationController
  include Api::V1::QuizSubmission
  include ::Filters::Quizzes
  include ::Filters::QuizSubmissions

  before_action :require_user, :require_context, :require_quiz
  before_action :require_overridden_quiz, :except => [ :index ]
  before_action :require_quiz_submission, :except => [ :index, :submission, :create ]
  before_action :prepare_service, :only => [ :create, :update, :complete ]
  before_action :validate_ldb_status!, :only => [ :create, :complete ]

  # @API Get all quiz submissions.
  # @beta
  #
  # Get a list of all submissions for this quiz. Users who can view or manage
  # grades for a course will have submissions from multiple users returned. A
  # user who can only submit will have only their own submissions returned. When
  # a user has an in-progress submission, only that submission is returned. When
  # there isn't an in-progress quiz_submission, all completed submissions,
  # including previous attempts, are returned.
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
    quiz_submissions = if @context.grants_any_right?(@current_user, session, :manage_grades, :view_all_grades)
      # teachers have access to all student submissions
      visible_student_ids = @context.apply_enrollment_visibility(@context.student_enrollments, @current_user).pluck(:user_id)
      Api.paginate @quiz.quiz_submissions.where(:user_id => visible_student_ids),
        self,
        api_v1_course_quiz_submissions_url(@context, @quiz)
    elsif @quiz.grants_right?(@current_user, session, :submit)
      # students have access only to their own submissions, both in progress, or completed`
      submission = @quiz.quiz_submissions.where(:user_id => @current_user).first
      if submission
        if submission.workflow_state == "untaken"
          [submission]
        else
          submission.submitted_attempts
        end
      else
        []
      end
    end

    if quiz_submissions
      # trigger delayed grading job for all submission id's which needs grading
      quiz_submissions_ids = quiz_submissions.map(&:id).uniq
      Quizzes::OutstandingQuizSubmissionManager.new(@quiz).send_later_if_production(:grade_by_ids, quiz_submissions_ids)
      serialize_and_render quiz_submissions
    else
      render_unauthorized_action
    end
  end

  # @API Get the quiz submission.
  # @beta
  #
  # Get the submission for this quiz for the current user.
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
  def submission
    unless @quiz.grants_right?(@current_user, session, :submit)
      render_unauthorized_action
    end

    quiz_submission = @quiz.quiz_submissions.where(user_id: @current_user).first(1)
    serialize_and_render(quiz_submission)
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
      if params.has_key?(:attempt)
        retrieve_quiz_submission_attempt!(params[:attempt])
      end

      serialize_and_render @quiz_submission
    end
  end

  # @API Create the quiz submission (start a quiz-taking session)
  # @beta
  #
  # Start taking a Quiz by creating a QuizSubmission which you can use to answer
  # questions and submit your answers.
  #
  # @argument access_code [String]
  #   Access code for the Quiz, if any.
  #
  # @argument preview [Boolean]
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
      if module_locked?
        raise RequestError.new("you are not allowed to participate in this quiz", 400)
      end

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
  # @argument attempt [Required, Integer]
  #   The attempt number of the quiz submission that should be updated. This
  #   attempt MUST be already completed.
  #
  # @argument fudge_points [Float]
  #   Amount of positive or negative points to fudge the total score by.
  #
  # @argument questions [Hash]
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
  # @argument attempt [Required, Integer]
  #   The attempt number of the quiz submission that should be completed. Note
  #   that this must be the latest attempt index, as earlier attempts can not
  #   be modified.
  #
  # @argument validation_token [Required, String]
  #   The unique validation token you received when this Quiz Submission was
  #   created.
  #
  # @argument access_code [String]
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

    # TODO: should this go in the service instead?
    Canvas::LiveEvents.quiz_submitted(@quiz_submission)

    serialize_and_render @quiz_submission
  end

  # @API Get current quiz submission times.
  # @beta
  #
  # Get the current timing data for the quiz attempt, both the end_at timestamp
  # and the time_left parameter.
  #
  # <b>Responses</b>
  #
  # * <b>200 OK</b> if the request was successful
  #
  # @example_response
  #  {
  #    "end_at": [DateTime],
  #    "time_left": [Integer]
  #  }
  def time
    if authorized_action(@quiz_submission, @current_user, :record_events)
      render :json =>
      {
        :end_at => @quiz_submission && @quiz_submission.end_at,
        :time_left => @quiz_submission && @quiz_submission.time_left
      }
    end
  end


  private

  def module_locked?
    @quiz.locked_for?(@current_user, :check_policies => true, :deep_check_if_needed => true)
  end

  def previewing?
    !!params[:preview]
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
