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
  include Api::V1::AssignmentOverride

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

  def learning_object_dates_json(learning_object, overridable, include_peer_review: false, exclude_peer_review_overrides: false)
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
    add_peer_review_info(hash, overridable, exclude_overrides: exclude_peer_review_overrides) if include_peer_review
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

  def add_peer_review_info(hash, overridable, exclude_overrides: false)
    return unless peer_review_overrides_supported?(overridable)

    peer_review_sub = overridable.peer_review_sub_assignment

    hash[:peer_review_sub_assignment] = {
      id: peer_review_sub.id,
      due_at: peer_review_sub.due_at,
      unlock_at: peer_review_sub.unlock_at,
      lock_at: peer_review_sub.lock_at,
      only_visible_to_overrides: peer_review_sub.only_visible_to_overrides,
      visible_to_everyone: peer_review_sub.visible_to_everyone
    }

    unless exclude_overrides
      peer_review_overrides = peer_review_sub.active_assignment_overrides
      peer_review_overrides_json = assignment_overrides_json(
        peer_review_overrides,
        @current_user,
        include_names: true,
        include_child_override_due_dates: false
      )
      hash[:peer_review_sub_assignment][:overrides] = peer_review_overrides_json
    end
  end

  def peer_review_overrides_supported?(overridable)
    overridable.is_a?(Assignment) &&
      overridable.peer_reviews? &&
      !overridable.discussion_topic? &&
      overridable.peer_review_sub_assignment.present? &&
      overridable.context.feature_enabled?(:peer_review_allocation_and_grading)
  end
end
