#
# Copyright (C) 2011 - 2013 Instructure, Inc.
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

class Quizzes::QuizSortables
  attr_accessor :group, :quiz, :items

  def initialize(options = {})
    @group = options[:group]
    @quiz = options[:quiz] || group.quiz
    @items = build_items(options[:order])
  end

  def reorder!
    items.each_with_index { |item, i| item.position = i+1 }
    questions.each { |question| question.quiz_group_id = quiz_group_id }
    update_object_positions!
    quiz.mark_edited!
  end

  private

  def update_object_positions!
    Quizzes::QuizQuestion.update_all_positions!(questions, group)
    Quizzes::QuizGroup.update_all_positions!(groups)
  end

  # items is in format: [{"type" => "question", "id" => 1},
  #                      {"type" => "group",    "id" => 3}]
  def build_items(items)
    items.each_with_index.map { |item, i| find_object_for_item(item) }.compact
  end

  def find_object_for_item(item)
    all_objects_hash["quiz_#{item['type']}_#{item['id']}"]
  end

  def all_objects_hash
    @quiz_objects_hash ||= all_objects.each_with_object({}) do |obj, hash|
      hash["#{obj.class.name.demodulize.underscore}_#{obj.id}"] = obj
    end
  end

  def all_objects
    quiz.quiz_groups + quiz.quiz_questions.active
  end

  def questions
    @questions ||= items.select { |item| item.respond_to?(:quiz_group_id) }
  end

  def groups
    @groups ||= items.reject { |item| item.respond_to?(:quiz_group_id) }
  end

  def quiz_group_id
    group.id if group
  end
end
