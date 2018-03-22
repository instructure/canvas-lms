#
# Copyright (C) 2014 - present Instructure, Inc.
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

# @API Quiz Extensions
#
# API for setting extensions on student quiz submissions
#
# @model QuizExtension
#     {
#       "id": "QuizExtension",
#       "required": ["quiz_id", "user_id"],
#       "properties": {
#         "quiz_id": {
#           "description": "The ID of the Quiz the quiz extension belongs to.",
#           "example": 2,
#           "type": "integer",
#           "format": "int64"
#         },
#         "user_id": {
#           "description": "The ID of the Student that needs the quiz extension.",
#           "example": 3,
#           "type": "integer",
#           "format": "int64"
#         },
#         "extra_attempts": {
#           "description": "Number of times the student is allowed to re-take the quiz over the multiple-attempt limit.",
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
#         "end_at": {
#           "description": "The time at which the quiz submission will be overdue, and be flagged as a late submission.",
#           "example": "2013-11-07T13:16:18Z",
#           "type": "string",
#           "format": "date-time"
#         }
#       }
#     }
class Quizzes::QuizExtensionsController < ApplicationController
  include ::Filters::Quizzes

  before_action :require_user, :require_context, :require_quiz

  # @API Set extensions for student quiz submissions
  #
  # @argument user_id [Required, Integer]
  #   The ID of the user we want to add quiz extensions for.
  #
  # @argument extra_attempts [Integer]
  #   Number of times the student is allowed to re-take the quiz over the
  #   multiple-attempt limit. This is limited to 1000 attempts or less.
  #
  # @argument extra_time [Integer]
  #   The number of extra minutes to allow for all attempts. This will
  #   add to the existing time limit on the submission. This is limited to
  #   10080 minutes (1 week)
  #
  # @argument manually_unlocked [Boolean]
  #   Allow the student to take the quiz even if it's locked for
  #   everyone else.
  #
  # @argument extend_from_now [Integer]
  #   The number of minutes to extend the quiz from the current time. This is
  #   mutually exclusive to extend_from_end_at. This is limited to 1440
  #   minutes (24 hours)
  #
  # @argument extend_from_end_at [Integer]
  #   The number of minutes to extend the quiz beyond the quiz's current
  #   ending time. This is mutually exclusive to extend_from_now. This is
  #   limited to 1440 minutes (24 hours)
  #
  # <b>Responses</b>
  #
  # * <b>200 OK</b> if the request was successful
  # * <b>403 Forbidden</b> if you are not allowed to extend quizzes for this course
  #
  # @example_request
  #  {
  #    "quiz_extensions": [{
  #      "user_id": 3,
  #      "extra_attempts": 2,
  #      "extra_time": 20,
  #      "manually_unlocked": true
  #    },{
  #      "user_id": 2,
  #      "extra_attempts": 2,
  #      "extra_time": 20,
  #      "manually_unlocked": false
  #    }]
  #  }
  #
  # @example_request
  #  {
  #    "quiz_extensions": [{
  #      "user_id": 3,
  #      "extend_from_now": 20
  #    }]
  #  }
  #
  # @example_response
  #  {
  #    "quiz_extensions": [QuizExtension]
  #  }
  #
  def create
    unless params[:quiz_extensions].is_a?(Array)
      reject! 'missing required key :quiz_extensions'
    end

    # check permissions on all extensions before performing on submissions
    quiz_extensions = Quizzes::QuizExtension.build_extensions(
       students, [@quiz], params[:quiz_extensions]) do |extension|

      unless extension.quiz_submission.grants_right?(participant.user, :add_attempts)
        reject! 'you are not allowed to change extension settings for this submission', 403
      end
    end

    # after we've validated permissions on all extend all submissions
    quiz_extensions.each(&:extend_submission!)

    render json: serialize_jsonapi(quiz_extensions)
  end


  private

  def serialize_jsonapi(quiz_extensions)
    serialized_set = Canvas::APIArraySerializer.new(quiz_extensions, {
      each_serializer: Quizzes::QuizExtensionSerializer,
      controller: self,
      scope: @current_user,
      root: false,
      include_root: false
    }).as_json

    { quiz_extensions: serialized_set }
  end

  def participant
    Quizzes::QuizParticipant.new(@current_user, temporary_user_code)
  end

  def students
    @context.students
  end

end
