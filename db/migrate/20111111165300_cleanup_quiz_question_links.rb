#
# Copyright (C) 2011 - present Instructure, Inc.
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

class CleanupQuizQuestionLinks < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    Quizzes::QuizQuestion.joins(:quiz).select("quiz_questions.id").where(
        "quizzes.context_type='Course' AND " \
        "quiz_questions.question_data LIKE '%/courses/%'").
        find_in_batches do |batch|
      Quizzes::QuizQuestion.send_later_if_production_enqueue_args(:batch_migrate_file_links, {
        :priority => Delayed::LOWER_PRIORITY,
        :max_attempts => 1,
        :strand => 'cleanup_quiz_question_links'
      }, batch.map(&:id))
    end

    Quizzes::Quiz.where(
        "quizzes.context_type='Course' AND " \
        "quizzes.quiz_data LIKE '%/courses/%'").select(:id).
        find_in_batches do |batch|
      Quizzes::Quiz.send_later_if_production_enqueue_args(:batch_migrate_file_links, {
        :priority => Delayed::LOWER_PRIORITY,
        :max_attempts => 1,
        :strand => 'cleanup_quiz_question_links'
      }, batch.map(&:id))
    end
  end

  def self.down
  end
end
