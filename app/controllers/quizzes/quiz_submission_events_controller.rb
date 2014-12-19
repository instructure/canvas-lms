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

# @API QuizSubmissionEvent
# @model QuizSubmissionEvent
#     {
#       "id": "QuizSubmissionEvent",
#       "description": "An event passed from the Quiz Submission take page",
#       "properties": {
#         "created_at": {
#           "description": "a timestamp record of creation time",
#           "example": "2014-10-08T19:29:58Z",
#           "type": "datetime"
#         },
#         "event_type": {
#           "description": "the type of event being sent",
#           "example": "question_answered",
#           "type": "string"
#         },
#         "data": {
#           "description": "the event data",
#           "example": {"answer": "42"},
#           "type": "object"
#         }
#       }
#     }
class Quizzes::QuizSubmissionEventsController < ApplicationController
  include Filters::Quizzes
  include Filters::QuizSubmissions

  before_filter :require_user
  before_filter :require_quiz_submission, :only => [ :create ]

  # @API Submit captured events
  # @beta
  #
  # Store a set of events which were captured during a quiz taking session.
  #
  # On success, the response will be 204 No Content with an empty body.
  #
  # @argument quiz_submission_events[] [Required, Array]
  #  The submission events to be recorded
  #
  # @example_request
  #  {
  #    "quiz_submission_events":
  #    [
  #      {
  #       "created_at": "2014-10-08T19:29:58Z",
  #       "event_type": "question_answered",
  #       "data" : {"answer": "42"}
  #      }, {
  #       "created_at": "2014-10-08T19:30:17Z",
  #       "event_type": "question_answered",
  #       "data" : {"answer": "43"}
  #     }
  #   ]
  #  }
  #
  def create
    if authorized_action(@quiz_submission, @current_user, :record_events)
      params["quiz_submission_events"].each do |datum|
        Quizzes::QuizSubmissionEvent.create do |event|
          event.quiz_submission_id = @quiz_submission.id
          event.created_at = datum["created_at"]
          event.event_type = datum["event_type"]
          event.attempt = @quiz_submission.attempt
        end
      end
      head :no_content
    end
  end
end
