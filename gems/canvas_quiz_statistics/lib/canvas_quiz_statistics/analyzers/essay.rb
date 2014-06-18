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
      responses.select { |r| r[:correct] == 'defined' }.length
    end

    # The number of students who got graded with a full score.
    #
    # @return [Integer]
    metric :full_credit do |responses|
      full_credit = @question_data[:points_possible].to_f

      responses.select { |response| response[:points].to_f >= full_credit }.length
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
        { score: score, count: point_distribution[score] }
      end.sort_by { |v| v[:score] || -1 }
    end
  end
end
