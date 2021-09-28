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

class Quizzes::QuizQuestionBuilder
  # Draw a number of QuizQuestions from an AssessmentQuestionBank.
  class BankPool
    def initialize(bank, picked, &mark_picked)
      @bank = bank
      @picked = picked
      @mark_picked = mark_picked
    end

    def draw(quiz_id, quiz_group_id, count)
      questions = @bank.select_for_submission(quiz_id, quiz_group_id, count, @picked[:aq])
      @mark_picked.call(questions)

      duplicate_index = 1
      while questions.count < count
        remaining_picks = count - questions.count
        duplicated = @bank.select_for_submission(quiz_id, quiz_group_id, remaining_picks, [], duplicate_index)
        break if duplicated.empty?
        duplicate_index += 1
        @mark_picked.call(duplicated)
        questions.concat(duplicated)
      end

      questions.map(&:data)
    end
  end
end