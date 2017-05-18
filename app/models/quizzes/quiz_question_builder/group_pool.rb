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
  # Draw a number of QuizQuestions from a QuizGroup.
  class GroupPool
    def initialize(questions, picked, &mark_picked)
      @questions = questions
      @picked = picked
      @mark_picked = mark_picked
    end

    def draw(quiz_id, quiz_group_id, count)
      # try picking as many questions as requested:
      questions = @questions.shuffle.slice(0, count)

      # and discard ones we already picked:
      questions.reject! { |q| @picked[:qq].include?(q[:id]) }

      @mark_picked.call(questions) if questions.any?

      # if we ended up with less questions than was requested, this gets tricky:
      # we need to pull as many more questions as needed (duplicates), and make
      # sure that we have distinct QuizQuestions that represent them.
      duplicate_index = 1
      while questions.count < count
        duplicates = @questions.shuffle.slice(0, count - questions.count)
        sources = AssessmentQuestion.where(id: duplicates.map { |q| q[:assessment_question_id] }).to_a
        break if sources.empty?

        duplicates = AssessmentQuestion.find_or_create_quiz_questions(
          sources, quiz_id, quiz_group_id, duplicate_index)
        duplicate_index += 1

        @mark_picked.call(duplicates)
        questions.concat(duplicates.map(&:data))
      end

      questions
    end
  end
end