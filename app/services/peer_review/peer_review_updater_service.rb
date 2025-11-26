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

class PeerReview::PeerReviewUpdaterService < PeerReview::PeerReviewCommonService
  def call
    run_validations
    updated_peer_review_sub_assignment = update_peer_review_sub_assignment
    compute_due_dates_and_create_submissions(updated_peer_review_sub_assignment)
    updated_peer_review_sub_assignment
  end

  private

  def run_validations
    validate_parent_assignment(@parent_assignment)
    validate_assignment_submission_types(@parent_assignment)
    validate_feature_enabled(@parent_assignment)
    validate_peer_review_sub_assignment_exists(@parent_assignment)
    validate_dates
  end

  def update_peer_review_sub_assignment
    peer_review_sub = @parent_assignment.peer_review_sub_assignment
    attrs_to_update = peer_review_attributes_to_update

    if attrs_to_update.any?
      AbstractAssignment.suspend_due_date_caching do
        peer_review_sub.assign_attributes(attrs_to_update)
        peer_review_sub.save!
      end
    end

    peer_review_sub
  end
end
