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

# @API Quiz Submission Events
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
#         "event_data": {
#           "description": "custom contextual data for the specific event type",
#           "example": {"answer": "42"},
#           "type": "object"
#         }
#       }
#     }
class Quizzes::QuizSubmissionEventsApiController < ApplicationController
  include ::Filters::Quizzes
  include ::Filters::QuizSubmissions

  before_filter :require_user,
    :require_context,
    :require_quiz,
    :require_active_quiz_submission

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
  #        "client_timestamp": "2014-10-08T19:29:58Z",
  #        "event_type": "question_answered",
  #        "event_data" : {"answer": "42"}
  #      }, {
  #        "client_timestamp": "2014-10-08T19:30:17Z",
  #        "event_type": "question_flagged",
  #        "event_data" : { "question_id": "1", "flagged": true }
  #      }
  #    ]
  #  }
  #
  def create
    if authorized_action(@quiz_submission, @current_user, :record_events)
      params["quiz_submission_events"].each do |datum|
        Quizzes::QuizSubmissionEvent.create do |event|
          event.quiz_submission_id = @quiz_submission.id
          event.event_type = datum["event_type"]
          event.event_data = datum["event_data"]
          event.client_timestamp = datum["client_timestamp"]
          event.attempt = @quiz_submission.attempt
        end
      end

      head :no_content
    end
  end

  # @API Retrieve captured events
  # @beta
  #
  # Retrieve the set of events captured during a specific submission attempt.
  #
  # @argument attempt [Integer]
  #  The specific submission attempt to look up the events for. If unspecified,
  #  the latest attempt will be used.
  #
  # @example_response
  #  {
  #    "quiz_submission_events": [
  #      {
  #        "id": "3409",
  #        "event_type": "page_blurred",
  #        "event_data": null,
  #        "created_at": "2014-11-16T13:37:21Z"
  #      },
  #      {
  #        "id": "3410",
  #        "event_type": "page_focused",
  #        "event_data": null,
  #        "created_at": "2014-11-16T13:37:27Z"
  #      }
  #    ]
  #  }
  #
  def index
    if authorized_action(@quiz_submission, @current_user, :view_log)
      unless @context.feature_enabled?(:quiz_log_auditing)
        reject! "quiz log auditing must be enabled", 400
      end

      if params.has_key?(:attempt)
        retrieve_quiz_submission_attempt!(params[:attempt])
      end

      scope = @quiz_submission.events.
        where('attempt = :attempt AND created_at > :started_at', {
          attempt: @quiz_submission.attempt,
          started_at: @quiz_submission.started_at
        }).
        order('created_at ASC')

      api_route = api_v1_course_quiz_submission_events_url(@context, @quiz, @quiz_submission)
      events = Api.paginate(scope, self, api_route)

      render({
        json: {
          quiz_submission_events: events.map do |e|
            {
              id: "#{e.id}",
              event_type: e.event_type,
              event_data: e.event_data,
              created_at: e.created_at
            }
          end
        }
      })
    end
  end
end
