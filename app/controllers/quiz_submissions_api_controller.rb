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

  before_filter :require_user, :require_context, :require_quiz

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
  #      "quiz_submissions": [
  #          {
  #              "attempt": 6,
  #              "end_at": null,
  #              "extra_attempts": null,
  #              "extra_time": null,
  #              "finished_at": "2013-11-07T13:16:18Z",
  #              "fudge_points": null,
  #              "id": 8,
  #              "kept_score": 4,
  #              "quiz_id": 8,
  #              "quiz_points_possible": 6,
  #              "quiz_version": 13,
  #              "score": 0,
  #              "score_before_regrade": null,
  #              "started_at": "2013-10-24T05:21:22Z",
  #              "submission_id": 6,
  #              "user_id": 2,
  #              "workflow_state": "pending_review",
  #              "time_spent": 1238095,
  #              "html_url": "http://example.com/courses/1/quizzes/8/submissions/8"
  #          },
  #          {
  #              "attempt": 1,
  #              "end_at": "2013-10-31T05:59:59Z",
  #              "extra_attempts": null,
  #              "extra_time": null,
  #              "finished_at": "2013-10-29T05:04:42Z",
  #              "fudge_points": 0,
  #              "id": 9,
  #              "kept_score": 5,
  #              "quiz_id": 8,
  #              "quiz_points_possible": 6,
  #              "quiz_version": 13,
  #              "score": 5,
  #              "score_before_regrade": null,
  #              "started_at": "2013-10-29T05:04:32Z",
  #              "submission_id": 7,
  #              "user_id": 5,
  #              "workflow_state": "complete",
  #              "time_spent": 10,
  #              "html_url": "http://example.com/courses/1/quizzes/8/submissions/9"
  #          }
  #      ]
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

  private

  def require_quiz
    unless @quiz = @context.quizzes.find(params[:quiz_id])
      raise ActiveRecord::RecordNotFound
    end
  end

  def visible_user_ids(opts = {})
    scope = @context.enrollments_visible_to(@current_user, opts)
    scope.pluck(:user_id)
  end
end
