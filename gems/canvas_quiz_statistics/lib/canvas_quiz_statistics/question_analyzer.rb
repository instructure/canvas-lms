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

require 'active_support/core_ext'

class CanvasQuizStatistics::QuestionAnalyzer
  attr_reader :question_data

  def initialize(question_data)
    @question_data = question_data
    @answer_analyzer = AnswerAnalyzers[question_data[:question_type].to_s].new
  end

  # Gathers all types of stats from a set of student responses.
  #
  # The output will contain the output of an answer analyzer.
  #
  # @return [Hash]
  #   {
  #     // Number of students who have answered this question.
  #     "responses": 2,
  #
  #     // IDs of those students.
  #     "user_ids": [ 1, 133 ]
  #   }
  def run(responses)
    {}.tap do |stats|
      stats.merge! @answer_analyzer.run(question_data, responses)
      stats.merge! count_filled_responses(responses)
    end
  end

  private

  AnswerAnalyzers = CanvasQuizStatistics::AnswerAnalyzers

  # Returns the number of and IDs of students who provided any kind of answer,
  # regardless of whether it's correct or not.
  def count_filled_responses(responses)
    answers = responses.select do |response|
      @answer_analyzer.answer_present?(response)
    end

    { responses: answers.size, user_ids: answers.map { |a| a[:user_id] }.uniq }
  end
end
