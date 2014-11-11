#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

module Quizzes::LogAuditing
  # @class EventAggregator
  #
  # Generate submission_data ready for use by a submission from a bunch of
  # answer-related events.
  class EventAggregator

    # Main API for aggregating QuizSubmissionEvents
    #
    # @param [Integer] quiz_submission_id
    # @param [Integer] attempt_id
    # @param [Time] timestamp
    #   This is a timestamp which is used to filter out events. Any events
    #   which occurred after (inclusive) the given timestamp are excluded.
    #
    #  This queries the DB for the pertinent quiz submission events for the
    #  specified attempt and quiz submission.  It selects the events which are
    #  related to questions (question answers and question flags).  It also
    #  reduces the returned events to a conclusive set of events which describe
    #  the state of the quiz submission events up to and including the point in
    #  time corresponding to the provided timestamp.  These are returned in the
    #  form of submission data as would be stored in a QuizSubmission.
    #
    # @return [Hash] Submission data is returned
    #
    def run(quiz_submission_id, attempt, timestamp)
      sql_string = <<-SQL
        quiz_submission_id = :qs_id
        AND attempt = :attempt
        AND event_type IN(:filter)
        AND created_at <= :time
      SQL
      events = Quizzes::QuizSubmissionEvent.where(sql_string, {
        qs_id: quiz_submission_id,
        attempt: attempt,
        filter: [
          Quizzes::QuizSubmissionEvent::EVT_QUESTION_ANSWERED,
          Quizzes::QuizSubmissionEvent::EVT_QUESTION_FLAGGED
        ],
        time: timestamp
      }).order("created_at ASC")
      filtered_events = pick_latest_distinct_events(events)
      build_submission_data_from_events(filtered_events)
    end

    private
    # constructs submission data from events, including the parsing of flagged
    # to indicate that they are 'marked' or 'flagged'
    def build_submission_data_from_events(events)
      events.reduce({}) do |submission_data, event|
        response = case event.event_type
        when Quizzes::QuizSubmissionEvent::EVT_QUESTION_FLAGGED
          {"question_#{event.event_data['quiz_question_id']}_marked"=> event.event_data['flagged'] }
        when Quizzes::QuizSubmissionEvent::EVT_QUESTION_ANSWERED
          question = Quizzes::QuizQuestion.where(id: event.event_data['quiz_question_id']).first
          serializer = Quizzes::QuizQuestion::AnswerSerializers.serializer_for(question)
          serializer.serialize(event.event_data['answer']).answer
        end
        submission_data.merge! response if response
        submission_data
      end
    end

    # Filter out the redundant or overwritten events, creating a minimal set
    # of events which only contain the results of the series of events
    def pick_latest_distinct_events(events)
      kept_events = {}
      events.each do |event|
        kept_events["#{event.event_type}_#{event.event_data['quiz_question_id']}"] = event
      end
      kept_events.values
    end
  end
end