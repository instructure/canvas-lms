#
# Copyright (C) 2012 Instructure, Inc.
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

# Stores the scoring information for a user's answer to a quiz question
class Quizzes::QuizQuestion::UserAnswer < Struct.new(:question_id, :points_possible, :total_parts, :correct_parts, :incorrect_parts, :answer_id, :undefined, :answer_details, :incorrect_dock)
  def initialize(question_id, points_possible, answer_data)
    super(question_id, points_possible, 1, 0, 0)
    @points = 0.0
    @answer_data = answer_data
    self.answer_details = {:text => answer_text || ""}
  end


  def [](k)
    @answer_data["question_#{question_id}_#{k}".to_sym]
  end

  def answer_text
    @answer_data["question_#{question_id}".to_sym]
  end

  def score
    if total_parts == 0
      return 0
    end
    score = (correct_parts.to_f / total_parts) * points_possible
    if incorrect_parts > 0
      if incorrect_dock
        score -= incorrect_dock * incorrect_parts
      else
        score -= (incorrect_parts.to_f / total_parts) * points_possible
      end
      score = 0.0 if score < 0
    end
    score
  end

  # this seems like it should be part of the question data, not the user answer data
  def undefined_if_blank?
    @answer_data[:undefined_if_blank]
  end

  # returns whether the answer is correct, in a bit of an odd way --
  # returns boolean true or false if the answer is completely correct or incorrect
  # returns the string "partial" if the answer is partially correct
  # returns the string "no_score" for text-only questions
  # returns the string "undefined" if no answer was given and
  #   undefined_if_blank is specified, or if the question can't be scored
  #   automatically (like an essay question)
  def correctness
    if total_parts == 0
      "no_score"
    elsif undefined
      "undefined"
    elsif correct_parts == total_parts && incorrect_parts == 0
      true
    elsif (correct_parts - incorrect_parts) > 0
      "partial"
    else
      false
    end
  end
end

Dir[Rails.root + "app/models/quizzes/quiz_question/*_answer.rb"].each { |f| require_dependency f }
