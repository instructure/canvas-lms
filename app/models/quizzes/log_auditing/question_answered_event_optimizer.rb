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
  # @class QuestionAnsweredEventOptimizer
  #
  # Operates on a single EVT_QUESTION_ANSWERED event to make sure it contains no
  # redundant data based on what had been previously recorded.
  class QuestionAnsweredEventOptimizer

    # Given a set of previously recorded answer events, optimize the answer
    # records recorded in this event by:
    #
    #  1. removing all answer records that were previously recorded with a
    #     similar answer value
    #  2. keeping newly recorded answers
    #
    # @return [Boolean]
    #   Whether any answer records were removed from this event; e.g, it was
    #   optimized.
    def run!(answers, previous_events)
      initial_answer_count = answers.length

      answers.keep_if do |answer|
        question_id = answer['quiz_question_id']
        previous_answer = nil

        # locate the most recent answer to this question (keep in mind that this
        # event set is sorted by created_at DESC):
        previous_events.each do |previous_event|
          previous_answer = previous_event.answers.detect do |answer|
            answer['quiz_question_id'] == question_id
          end

          break unless previous_answer.nil?
        end

        # keep the new answer only if no previous answer was recorded, or if it's
        # not the same as the new one:
        previous_answer.nil? || !identical_records?(answer, previous_answer)
      end

      initial_answer_count != answers.length
    end

    protected

    def identical_records?(a,b)
      a['answer'].to_json == b['answer'].to_json
    end
  end
end