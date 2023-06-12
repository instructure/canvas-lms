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
#
module CanvasQuizStatistics::Analyzers
  # Generates statistics for a set of student responses to an essay question.
  #
  # Response is expected to look something like this:
  #
  # ```javascript
  # {
  #   "correct": "undefined",
  #   "points": 0,
  #   "question_id": 18,
  #   "text": "<p>*grunts*</p>",
  #   "user_id": 4
  # }
  # ```
  class Essay < Base
    # Number of students who have answered this question.
    #
    # @return [Integer]
    metric :responses do |responses|
      responses.select(&method(:answer_present?)).length
    end

    # The number of students whose responses were graded by the teacher so far.
    #
    # @return [Integer]
    metric :graded do |responses|
      responses.select { |r| r[:correct] == "defined" }.length
    end

    # The number of students who got graded with a full score.
    #
    # @return [Integer]
    metric :full_credit do |responses|
      full_credit = @question_data[:points_possible].to_f

      responses.count { |response| response[:points].to_f >= full_credit }
    end

    # A set of scores and the number of students who received them.
    #
    # @return [Hash]
    #
    # ```javascript
    # {
    #   "point_distribution": [
    #     { "score": 0, "count": 1 },
    #     { "score": 3, "count": 1 }
    #   ]
    # }
    # ```
    metric :point_distribution do |responses|
      point_distribution = Hash.new(0)

      responses.each { |response| point_distribution[response[:points]] += 1 }

      point_distribution.keys.map do |score|
        { score:, count: point_distribution[score] }
      end.sort_by { |v| v[:score] || -1 }
    end

    # Statistics for answers which scored specific values
    #
    # @return [Hash]
    #
    # Output synopsis:
    #
    # ```json
    # {
    #   "answers": [
    #     {
    #       // Number of students who picked this answer.
    #       "responses": 3,
    #
    #       // The ids of the students who scored this value.
    #       "user_ids": [100, 101, 102],
    #
    #       // The names of the students who scored this value.
    #       "user_names": ["John", "Jim", "Jenny"],
    #
    #       // The score shared by these students
    #       "score": 0.5,
    #
    #       // The id (or type) of the answer bucket
    #       // The top and bottom buckets represent the respective extreme 27%
    #       // ends of the student performance.
    #       // The middle represents the middle 46% in performance across the item.
    #       "id": "bottom", # one of %w|bottom top middle ungraded|
    #
    #       // If the score represents full credit on the item
    #       "full_credit": true,
    #     }
    #   ]
    # }
    # ```
    metric :answers do |responses|
      answers = Hash.new do |h, k|
        h[k] = {
          user_ids: [],
          user_names: [],
          responses: 0
        }
      end

      buckets = [
        [:top, 0.73],
        [:middle, 0.27],
        [:bottom, 0]
      ]

      graded_responses = []
      ungraded_responses = []
      responses.each { |r| (r[:correct] == "defined") ? graded_responses << r : ungraded_responses << r }
      ranked_responses_by_score = graded_responses.sort_by { |h| h[:points] }

      previous_floor = ranked_responses_by_score.length
      buckets.each do |name, cutoff|
        floor = (cutoff * ranked_responses_by_score.length).round
        floor_score = ranked_responses_by_score[floor].try { |h| h[:points] }

        # include all tied users in this bucket
        floor -= 1 while (floor > 0) && (ranked_responses_by_score[floor - 1][:points] == floor_score)

        # Set bucket for selected buckets
        ranked_responses_by_score[floor...previous_floor].map { |r| r[:performance_bucket] = name.to_s }
        previous_floor = floor
      end

      ungraded_responses.each { |r| r[:performance_bucket] = "ungraded" }

      sorted_graded_responses = graded_responses.sort_by { |h| h[:performance_bucket] }.reverse

      (sorted_graded_responses + ungraded_responses).each do |response|
        hash = answers[response[:performance_bucket]]
        hash[:id] ||= response[:performance_bucket]
        hash[:score] ||= response[:points]
        # This will indicate correct if any point value reaches 100%
        hash[:full_credit] ||= response[:points].to_f >= @question_data[:points_possible].to_f

        hash[:user_ids] << response[:user_id]
        hash[:user_names] << response[:user_name]
        hash[:responses] += 1
      end
      answers.values
    end
  end
end
