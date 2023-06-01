# frozen_string_literal: true

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

module Quizzes::LogAuditing
  # @class QuestionAnsweredEventExtractor
  #
  # Extracts EVT_QUESTION_ANSWERED events from a submission data construct.
  class QuestionAnsweredEventExtractor
    EVENT_TYPE = Quizzes::QuizSubmissionEvent::EVT_QUESTION_ANSWERED
    RE_QUESTION_ANSWER_FIELD = /^question_(\d+)_?/
    SQL_FIND_PREDECESSORS =
      <<~SQL.squish
            created_at >= :started_at
        AND created_at <= :created_at
        AND quiz_submission_id = :quiz_submission_id
        AND attempt = :attempt
        AND event_type = '#{EVENT_TYPE}'
      SQL

    # Main API. Extract, optimize, and persist an answer event from a given
    # submission data construct.
    #
    # @param [Hash] submission_data
    #   Similar to what you pass for generating snapshots, which is the payload
    #   that gets sent by the quiz-taking front-end. This is what gets pushed
    #   to the /backup endpoint in the quiz sub controller then goes through
    #   Quizzes::QuizSubmission#backup_submission_data.
    #
    # @param [Quizzes::QuizSubmission] quiz_submission
    #
    # @return [Quizzes::QuizSubmissionEvent|NilClass]
    #   Nothing will be returned/saved if the event is empty after optimizing;
    #   e.g, it contains no new answers.
    def create_event!(submission_data, quiz_submission)
      event = build_event(submission_data, quiz_submission)

      predecessors = Quizzes::QuizSubmissionEvent.where(SQL_FIND_PREDECESSORS, {
                                                          quiz_submission_id: quiz_submission.id,
                                                          attempt: event.attempt,
                                                          started_at: quiz_submission.started_at,
                                                          created_at: event.created_at
                                                        }).order("created_at DESC")

      if predecessors.any?
        optimizer = Quizzes::LogAuditing::QuestionAnsweredEventOptimizer.new
        optimizer.run!(event.answers, predecessors)
      end

      if event.answers.any?
        event.tap(&:save!)
      end
    end

    # @internal
    def build_event(submission_data, quiz_submission)
      submission_data.stringify_keys!

      Quizzes::QuizSubmissionEvent.new.tap do |event|
        event.event_type = EVENT_TYPE
        event.event_data = extract_answers(submission_data, quiz_submission.quiz_data)
        event.created_at = Time.now
        event.quiz_submission = quiz_submission
        event.attempt = submission_data["attempt"]
      end
    end

    protected

    def extract_answers(submission_data, quiz_data)
      quiz_questions = begin
        quiz_question_ids = submission_data.keys.filter_map do |key|
          if key =~ RE_QUESTION_ANSWER_FIELD
            $1
          end
        end.uniq

        quiz_data.select do |qq|
          quiz_question_ids.include?(qq["id"].to_s)
        end.map(&:symbolize_keys)
      end

      quiz_questions.reduce([]) do |answers, qq|
        serializer = Quizzes::QuizQuestion::AnswerSerializers.serializer_for(qq)
        serializer.override_question_data(qq)

        answers << {
          "quiz_question_id" => qq[:id].to_s,
          "answer" => serializer.deserialize(submission_data, full: true)
        }
      end
    end # extract_answers
  end
end
