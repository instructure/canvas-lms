# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

module DataFixup
  module FixPointsPossibleSumsInQuizzes
    def self.run
      Quizzes::Quiz.find_ids_in_ranges(:batch_size => 10000) do |min_id, max_id|
        affected_quizzes.where(id: min_id..max_id).find_each do |quiz|
          begin
            possible = Quizzes::Quiz.count_points_possible(quiz.root_entries(true))
            quiz.update!(points_possible: possible)
          rescue => e
            Rails.logger.error("Error occured trying to repair Quiz #{quiz.global_id} #{e}")
          end
        end
      end
    end

    def self.affected_quizzes
      Quizzes::Quiz.where('CHAR_LENGTH(CAST(points_possible AS text)) > 8')
    end
  end
end
