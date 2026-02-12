# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class PeerReview::DateOverriderService < ApplicationService
  include PeerReview::Validations

  def initialize(
    peer_review_sub_assignment: nil,
    overrides: nil,
    reload_associations: false
  )
    super()

    @peer_review_sub_assignment = peer_review_sub_assignment
    @assignment = @peer_review_sub_assignment&.parent_assignment
    @overrides = format_overrides(overrides || [])
    @reload_associations = reload_associations
  end

  def call
    refresh_parent_associations if @reload_associations
    run_validations
    create_or_update_peer_review_overrides
    update_only_visible_to_overrides
  end

  private

  # Reloads parent assignment and its overrides to ensure changes made upstream are visible,
  # preventing stale cache when linking peer review overrides to parent overrides.
  # Set reload_associations: true when parent overrides are modified in same request.
  def refresh_parent_associations
    return unless @assignment && @peer_review_sub_assignment

    @peer_review_sub_assignment.association(:parent_assignment).reload
    @peer_review_sub_assignment.parent_assignment.association(:assignment_overrides).reload
  end

  def run_validations
    validate_parent_assignment(@assignment)
    validate_feature_enabled(@assignment)
    validate_peer_reviews_enabled(@assignment)
    validate_peer_review_sub_assignment_exists(@assignment)
  end

  def format_overrides(overrides)
    overrides.filter_map do |override|
      if needs_formatting?(override)
        format_api_override(override)
      else
        override
      end
    end
  end

  def needs_formatting?(override)
    override[:course_section_id].present? ||
      override[:group_id].present? ||
      override[:course_id].present? ||
      (override[:student_ids].present? && override[:set_type].blank?)
  end

  # Overrides coming from the API use different keys to specify the set_type and set_id
  # Course Section Override: { course_section_id: 5 } instead of { set_type: "CourseSection", set_id: 5 }
  # Group Override: { group_id: 10 } instead of { set_type: "Group", set_id: 10 }
  # Course Override: { course_id: 3 } instead of { set_type: "Course", set_id: 3 }
  # Adhoc Override: { student_ids: [1,2,3] } instead of { set_type: "ADHOC", student_ids: [1,2,3] }
  # This method reformats such overrides to match the format expected by the service layer
  def format_api_override(override)
    formatted_override = {}

    formatted_override[:id] = override[:id].to_i if override[:id].present?
    formatted_override[:due_at] = override[:due_at] if override.key?(:due_at)
    formatted_override[:unlock_at] = override[:unlock_at] if override.key?(:unlock_at)
    formatted_override[:lock_at] = override[:lock_at] if override.key?(:lock_at)
    formatted_override[:unassign_item] = override[:unassign_item] if override.key?(:unassign_item)

    if override[:course_section_id].present?
      formatted_override[:set_type] = "CourseSection"
      formatted_override[:set_id] = override[:course_section_id].to_i
    elsif override[:student_ids].present?
      student_ids = Array(override[:student_ids]).map(&:to_i)
      formatted_override[:set_type] = "ADHOC"
      formatted_override[:student_ids] = student_ids
    elsif override[:group_id].present?
      formatted_override[:set_type] = "Group"
      formatted_override[:set_id] = override[:group_id].to_i
    elsif override[:course_id].present?
      formatted_override[:set_type] = "Course"
      formatted_override[:set_id] = override[:course_id].to_i
    end

    formatted_override
  end

  def create_or_update_peer_review_overrides
    update_overrides, create_overrides = @overrides.partition { |override| override[:id].present? }

    existing_override_ids = @peer_review_sub_assignment.assignment_overrides.active.pluck(:id).to_set
    update_override_ids = update_overrides.to_set { |override| override[:id] }
    override_ids_to_delete = existing_override_ids - update_override_ids

    destroy_overrides(override_ids_to_delete) unless override_ids_to_delete.empty?

    unless update_overrides.empty?
      PeerReview::DateOverrideUpdaterService.call(
        peer_review_sub_assignment: @peer_review_sub_assignment,
        overrides: update_overrides
      )
    end

    unless create_overrides.empty?
      PeerReview::DateOverrideCreatorService.call(
        peer_review_sub_assignment: @peer_review_sub_assignment,
        overrides: create_overrides
      )
    end
  end

  def destroy_overrides(override_ids)
    @peer_review_sub_assignment.assignment_overrides.where(id: override_ids).destroy_all
  end

  def update_only_visible_to_overrides
    updated_only_visible_to_overrides = only_visible_to_overrides?

    if @peer_review_sub_assignment.only_visible_to_overrides != updated_only_visible_to_overrides
      @peer_review_sub_assignment.update!(only_visible_to_overrides: updated_only_visible_to_overrides)
    end
  end

  def only_visible_to_overrides?
    return false unless no_base_dates?

    override_types = @peer_review_sub_assignment.active_assignment_overrides.distinct.pluck(:set_type).to_set
    no_course_override = !override_types.include?("Course")
    has_other_overrides = (override_types - Set["Course"]).any?

    no_course_override && has_other_overrides
  end

  def no_base_dates?
    @peer_review_sub_assignment.due_at.nil? &&
      @peer_review_sub_assignment.unlock_at.nil? &&
      @peer_review_sub_assignment.lock_at.nil?
  end
end
