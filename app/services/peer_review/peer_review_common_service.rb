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
  require_relative "peer_review_error"

  def initialize(
    parent_assignment: nil,
    points_possible: nil,
    grading_type: nil,
    due_at: nil,
    unlock_at: nil,
    lock_at: nil
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

  def validate_parent_assignment
    unless @parent_assignment.present? && @parent_assignment.is_a?(Assignment) && @parent_assignment.persisted?
      raise PeerReview::PeerReviewInvalidParentAssignmentError, I18n.t("Invalid parent assignment")
    end
  end

  def validate_assignment_submission_types
    if @parent_assignment.external_tool?
      raise PeerReview::PeerReviewInvalidAssignmentSubmissionTypesError, I18n.t("Peer reviews cannot be used with External Tool assignments")
    end
  end

  def validate_feature_enabled
    unless @parent_assignment.context.feature_enabled?(:peer_review_allocation_and_grading)
      raise PeerReview::PeerReviewFeatureDisabledError, I18n.t("Peer Review Allocation and Grading feature flag is disabled")
    end
  end

  def validate_peer_review_sub_assignment_not_exist
    if @parent_assignment.peer_review_sub_assignment.present?
      raise PeerReview::PeerReviewSubAssignmentExistsError, I18n.t("Peer review sub assignment exists")
    end
  end

  def validate_peer_review_sub_assignment_exists
    if @parent_assignment.peer_review_sub_assignment.blank?
      raise PeerReview::PeerReviewSubAssignmentNotExistError, I18n.t("Peer review sub assignment does not exist")
    end
  end

  def peer_review_attributes
    inherited_attributes.merge(specific_attributes)
  end

  def attributes_to_inherit_from_parent
    %w[
      assignment_group_id
      context_id
      context_type
      description
      peer_review_count
      peer_reviews
      peer_reviews_due_at
      peer_reviews_assigned
      anonymous_peer_reviews
      automatic_peer_reviews
      intra_group_peer_reviews
      submission_types
      workflow_state
    ]
  end

  def inherited_attributes
    @parent_assignment.attributes.slice(*attributes_to_inherit_from_parent).symbolize_keys
  end

  def specific_attributes
    attrs = {
      title: I18n.t("%{title} Peer Review", title: @parent_assignment.title),
      parent_assignment_id: @parent_assignment.id,
      has_sub_assignments: false
    }
    attrs[:points_possible] = @points_possible if @points_possible
    attrs[:grading_type] = @grading_type if @grading_type
    attrs[:due_at] = @due_at if @due_at
    attrs[:unlock_at] = @unlock_at if @unlock_at
    attrs[:lock_at] = @lock_at if @lock_at
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

    # Peer review specific attributes that have changed
    attrs[:points_possible] = @points_possible if @points_possible != peer_review_sub.points_possible
    attrs[:grading_type] = @grading_type if @grading_type != peer_review_sub.grading_type
    attrs[:due_at] = @due_at if @due_at != peer_review_sub.due_at
    attrs[:unlock_at] = @unlock_at if @unlock_at != peer_review_sub.unlock_at
    attrs[:lock_at] = @lock_at if @lock_at != peer_review_sub.lock_at

    # Title requires special handling
    expected_title = I18n.t("%{title} Peer Review", title: @parent_assignment.title)
    if expected_title != peer_review_sub.title
      attrs[:title] = expected_title
    end

    attrs
  end

  def compute_due_dates_and_create_submissions(peer_review_sub_assignment)
    PeerReviewSubAssignment.clear_cache_keys(peer_review_sub_assignment, :availability)
    SubmissionLifecycleManager.recompute(peer_review_sub_assignment, update_grades: true, create_sub_assignment_submissions: false)
  end
end
