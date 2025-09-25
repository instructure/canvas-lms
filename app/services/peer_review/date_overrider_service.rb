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
    overrides: nil
  )
    super()

    @peer_review_sub_assignment = peer_review_sub_assignment
    @assignment = @peer_review_sub_assignment&.parent_assignment
    @overrides = overrides || []
  end

  def call
    run_validations
    create_or_update_peer_review_overrides
  end

  private

  def run_validations
    validate_parent_assignment(@assignment)
    validate_feature_enabled(@assignment)
    validate_peer_reviews_enabled(@assignment)
    validate_peer_review_sub_assignment_exists(@assignment)
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
end
