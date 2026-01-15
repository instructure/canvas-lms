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

class PeerReview::PeerReviewCommonService < ApplicationService
  include PeerReview::Validations

  # Sentinel value to distinguish "not provided" from "explicitly nil"
  # This allows us to preserve existing values when params are omitted
  # and support explicit nil to clear values
  NOT_PROVIDED = Object.new.freeze

  def initialize(
    parent_assignment: nil,
    points_possible: NOT_PROVIDED,
    grading_type: NOT_PROVIDED,
    due_at: NOT_PROVIDED,
    unlock_at: NOT_PROVIDED,
    lock_at: NOT_PROVIDED
  )
    super()
    @parent_assignment = parent_assignment
    @points_possible = points_possible
    @grading_type = grading_type
    @due_at = due_at
    @unlock_at = unlock_at
    @lock_at = lock_at
  end

  private

  def peer_review_attributes
    inherited_attributes.merge(specific_attributes)
  end

  def attributes_to_inherit_from_parent
    PeerReviewSubAssignment::SYNCABLE_ATTRIBUTES - %w[title]
  end

  def inherited_attributes
    @parent_assignment.attributes.slice(*attributes_to_inherit_from_parent).symbolize_keys
  end

  def specific_attributes
    attrs = {
      title: generate_peer_review_title,
      parent_assignment_id: @parent_assignment.id,
      has_sub_assignments: false
    }

    # Only include attributes that were explicitly provided
    attrs[:points_possible] = @points_possible if @points_possible != NOT_PROVIDED
    attrs[:grading_type] = @grading_type if @grading_type != NOT_PROVIDED
    attrs[:due_at] = @due_at if @due_at != NOT_PROVIDED
    attrs[:unlock_at] = @unlock_at if @unlock_at != NOT_PROVIDED
    attrs[:lock_at] = @lock_at if @lock_at != NOT_PROVIDED

    attrs
  end

  def peer_review_attributes_to_update
    peer_review_sub = @parent_assignment.peer_review_sub_assignment
    attrs = {}

    # Inherited attributes that have changed on the parent
    attributes_to_inherit_from_parent.each do |attr|
      attr_sym = attr.to_sym
      parent_value = @parent_assignment.send(attr)
      sub_value = peer_review_sub.send(attr)

      attrs[attr_sym] = parent_value if parent_value != sub_value
    end

    # Peer review specific attributes that have changed - only update if explicitly provided
    attrs[:points_possible] = @points_possible if @points_possible != NOT_PROVIDED && @points_possible != peer_review_sub.points_possible
    attrs[:grading_type] = @grading_type if @grading_type != NOT_PROVIDED && @grading_type != peer_review_sub.grading_type
    attrs[:due_at] = @due_at if @due_at != NOT_PROVIDED && @due_at != peer_review_sub.due_at
    attrs[:unlock_at] = @unlock_at if @unlock_at != NOT_PROVIDED && @unlock_at != peer_review_sub.unlock_at
    attrs[:lock_at] = @lock_at if @lock_at != NOT_PROVIDED && @lock_at != peer_review_sub.lock_at

    # Title requires special handling
    expected_title = generate_peer_review_title
    if expected_title != peer_review_sub.title
      attrs[:title] = expected_title
    end

    attrs
  end

  def compute_due_dates_and_create_submissions(peer_review_sub_assignment)
    PeerReviewSubAssignment.clear_cache_keys(peer_review_sub_assignment, :availability)
    SubmissionLifecycleManager.recompute(peer_review_sub_assignment, update_grades: true, create_sub_assignment_submissions: false)
  end

  def generate_peer_review_title
    count = @parent_assignment.peer_review_count
    if count && count > 0
      I18n.t("%{title} Peer Review (%{count})", title: @parent_assignment.title, count:)
    else
      I18n.t("%{title} Peer Review", title: @parent_assignment.title)
    end
  end

  def validate_dates
    # Only validate if at least one date was explicitly provided
    has_dates = [@due_at, @unlock_at, @lock_at].any? { |date| date != NOT_PROVIDED }

    if has_dates
      # Build hash with only explicitly provided dates
      peer_review_dates = {}
      peer_review_dates[:due_at] = @due_at if @due_at != NOT_PROVIDED
      peer_review_dates[:unlock_at] = @unlock_at if @unlock_at != NOT_PROVIDED
      peer_review_dates[:lock_at] = @lock_at if @lock_at != NOT_PROVIDED

      validate_peer_review_dates_against_parent_assignment(peer_review_dates, @parent_assignment)
    end
  end
end
