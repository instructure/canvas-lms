# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

module Api::V1::LearningObjectDates
  include Api::V1::Json

  BASE_FIELDS = %w[id].freeze
  LEARNING_OBJECT_DATES_FIELDS = %w[
    due_at
    unlock_at
    lock_at
    only_visible_to_overrides
    visible_to_everyone
    group_category_id
  ].freeze
  GRADED_MODELS = [Assignment, Quizzes::Quiz].freeze
  LOCKABLE_PSEUDO_COLUMNS = %i[due_dates availability_dates].freeze

  def learning_object_dates_json(learning_object, overridable)
    hash = learning_object.slice(BASE_FIELDS)
    LEARNING_OBJECT_DATES_FIELDS.each do |field|
      hash[field] = overridable.send(field) if overridable.respond_to?(field)
    end
    hash[:graded] = graded?(learning_object)
    if hash[:group_category_id].nil?
      group_category_id = group_category_id(learning_object)
      hash[:group_category_id] = group_category_id if group_category_id
    end
    add_checkpoint_info(hash, learning_object, overridable)
    hash
  end

  def blueprint_date_locks_json(learning_object)
    return {} unless learning_object.try(:is_child_content?)

    { blueprint_date_locks: learning_object.child_content_restrictions.filter_map { |k, v| k if LOCKABLE_PSEUDO_COLUMNS.include?(k) && v } }
  end

  def graded?(learning_object)
    return learning_object.assignment_id.present? if learning_object.is_a?(DiscussionTopic)

    GRADED_MODELS.include?(learning_object.class)
  end

  def group_category_id(learning_object)
    learning_object.group_category_id if learning_object.is_a?(DiscussionTopic)
  end

  private

  def add_checkpoint_info(hash, learning_object, overridable)
    if learning_object.context.discussion_checkpoints_enabled? && overridable.respond_to?(:has_sub_assignments?) && overridable.has_sub_assignments?
      hash["checkpoints"] = overridable.sub_assignments.map { |sub_assignment| Checkpoint.new(sub_assignment, @current_user).as_json.except("name", "points_possible") }
    end
  end
end
