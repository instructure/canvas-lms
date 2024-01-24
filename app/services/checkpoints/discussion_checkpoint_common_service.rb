# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class Checkpoints::DiscussionCheckpointCommonService < ApplicationService
  require_relative "discussion_checkpoint_error"

  def initialize(discussion_topic:, checkpoint_label:, dates:, points_possible:, replies_required: 1)
    super()
    @discussion_topic = discussion_topic
    @assignment = discussion_topic.assignment
    @checkpoint_label = checkpoint_label
    @dates = dates
    @points_possible = points_possible
    @replies_required = replies_required
  end

  private

  def validate_flag_enabled
    unless @discussion_topic.context.root_account.feature_enabled?(:discussion_checkpoints)
      raise Checkpoints::FlagDisabledError, "discussion_checkpoints feature flag must be enabled"
    end
  end

  def validate_dates
    valid_date_types = %w[everyone override].freeze

    @dates.each do |date|
      if date[:type].blank?
        raise Checkpoints::DateTypeRequiredError, "each date must have a type specified ('everyone' or 'override')"
      end
      unless valid_date_types.include?(date[:type])
        raise Checkpoints::InvalidDateTypeError, "invalid date type: #{date[:type]}"
      end
    end
  end

  def attributes_to_inherit_from_parent
    # TODO: handle peer reviews
    %w[
      assignment_group_id
      context_id
      context_type
      description
      grade_group_students_individually
      grading_type
      grading_standard_id
      group_category
      group_category_id
      position
      submission_types
      title
      workflow_state
    ]
  end

  def update_assignment
    @assignment.assign_attributes(assignment_attributes)
    @assignment.save! if @assignment.changed?
  end

  def assignment_attributes
    { only_visible_to_overrides: only_visible_to_overrides?, has_sub_assignments: true }
  end

  def checkpoint_attributes
    inherited_attributes.merge(specified_attributes)
  end

  def inherited_attributes
    @assignment.attributes.slice(*attributes_to_inherit_from_parent).symbolize_keys
  end

  def update_required_replies?
    return false unless @checkpoint_label == CheckpointLabels::REPLY_TO_ENTRY

    current_count = @discussion_topic.reply_to_entry_required_count
    count_is_invalid = current_count.nil? || current_count <= 0
    count_being_updated = current_count != @replies_required
    count_is_invalid || count_being_updated
  end

  def specified_attributes
    { sub_assignment_tag: @checkpoint_label, points_possible: @points_possible }.merge(date_fields)
  end

  def date_fields
    everyone_fields = everyone_date.slice(:due_at, :unlock_at, :lock_at)
    everyone_fields.merge(only_visible_to_overrides: only_visible_to_overrides?)
  end

  def only_visible_to_overrides?
    everyone_date.empty? && override_dates.any?
  end

  def everyone_date
    dates_by_type("everyone").first || {}
  end

  def override_dates
    dates_by_type("override")
  end

  def dates_by_type(type)
    @dates.select do |date|
      date_type = date.fetch(:type) { raise Checkpoints::DateTypeRequiredError, "each date must have a type specified ('everyone' or 'override')" }
      date_type == type
    end
  end

  def compute_due_dates_and_create_submissions(checkpoint)
    assignments = [checkpoint, checkpoint.parent_assignment]
    AbstractAssignment.clear_cache_keys(assignments, :availability)
    SubmissionLifecycleManager.recompute_course(checkpoint.course, assignments:, update_grades: true)
  end
end
