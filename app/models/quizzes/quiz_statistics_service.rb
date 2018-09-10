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

class Quizzes::QuizStatisticsService
  attr_accessor :quiz

  def initialize(quiz)
    self.quiz = quiz
  end

  # @param [Boolean] all_versions
  #   Describes if you want the statistics to represent all the submissions versions.
  #
  # @return [QuizStatisticsSerializer::Input]
  #   An object ready for API serialization containing (persisted) versions of
  #   the *latest* Student and Item analysis for the quiz.
  def generate_aggregate_statistics(all_versions, includes_sis_ids = true, options = {})

    Quizzes::QuizStatisticsSerializer::Input.new(quiz, options, *[
      quiz.current_statistics_for('student_analysis', {
        includes_all_versions: all_versions,
        includes_sis_ids: includes_sis_ids
      }),
      quiz.current_statistics_for('item_analysis')
    ])
  end
end
