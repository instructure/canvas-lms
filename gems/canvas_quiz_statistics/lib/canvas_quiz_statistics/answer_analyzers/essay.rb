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
module CanvasQuizStatistics::AnswerAnalyzers
  # Generates statistics for a set of student responses to an essay question.
  class Essay < Base
    # @param [Array<Hash>] responses
    #   Set of student responses. Entry is expected to look something like this:
    #   {
    #     "correct": "undefined",
    #     "points": 0,
    #     "question_id": 18,
    #     "text": "<p>*grunts*</p>",
    #     "user_id": 4
    #   }
    #
    # @example output
    # {
    #   // The number of students whose responses were graded by the teacher so
    #   // far.
    #   "graded": 1,
    #
    #   // The number of students who got graded with a full score.
    #   "full_credit": 1,
    #
    #   // A set of vectors of scores and the number of students who received
    #   // each score.
    #   "point_distribution": [
    #     { "score": 0, "count": 1 },
    #     { "score": 3, "count": 1 }
    #   ]
    # }
    def run(question_data, responses)
      full_credit = question_data[:points_possible]

      stats = {}
      stats[:graded] = responses.select { |r| r[:correct] == 'defined' }.length

      stats[:full_credit] = responses.select do |response|
        response[:points] == full_credit
      end.length

      point_distribution = Hash.new(0).tap do |vector|
        responses.each { |response| vector[response[:points]] += 1 }
      end

      stats[:point_distribution] = point_distribution.keys.map do |score|
        { score: score, count: point_distribution[score] }
      end

      stats[:point_distribution].sort_by! { |v| v[:score] || -1 }

      stats
    end
  end
end
