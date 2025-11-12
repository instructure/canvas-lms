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

class PeerReview::PeerReviewCreatorService < PeerReview::PeerReviewCommonService
  def call
    run_validations
    peer_review_sub_assignment = create_peer_review_sub_assignment
    link_existing_assessment_requests(peer_review_sub_assignment)
    compute_due_dates_and_create_submissions(peer_review_sub_assignment)
    peer_review_sub_assignment
  end

  private

  def run_validations
    validate_parent_assignment(@parent_assignment)
    validate_assignment_submission_types(@parent_assignment)
    validate_feature_enabled(@parent_assignment)
    validate_peer_review_sub_assignment_not_exist(@parent_assignment)
    validate_dates
  end

  def create_peer_review_sub_assignment
    AbstractAssignment.suspend_due_date_caching do
      peer_review_sub = PeerReviewSubAssignment.new(peer_review_attributes)
      peer_review_sub.save!
      peer_review_sub
    end
  end

  def link_existing_assessment_requests(peer_review_sub_assignment)
    existing_assessment_requests = AssessmentRequest.for_assignment(@parent_assignment.id)
    existing_assessment_requests.update_all(peer_review_sub_assignment_id: peer_review_sub_assignment.id)
  end
end
