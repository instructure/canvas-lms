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

class PeerReview::SubmissionCreatorService < PeerReview::SubmissionCommonService
  def call
    return unless peer_review_submission_supported?
    return unless required_peer_reviews_met?
    return unless peer_review_unsubmitted?

    create_peer_review_submission(@assessor)
  end

  private

  def parent_assignment_active?
    @parent_assignment.present? && @parent_assignment.active?
  end

  def peer_review_sub_assignment_active?
    peer_review_sub_assignment.present? && peer_review_sub_assignment.active?
  end

  def peer_reviews_enabled?
    @parent_assignment.present? && @parent_assignment.peer_reviews?
  end

  # To maintain backward compatibility with legacy peer reviews, we
  # create peer review submissions regardless of the feature flag state
  def peer_review_submission_supported?
    parent_assignment_active? &&
      peer_reviews_enabled? &&
      peer_review_sub_assignment_active? &&
      assessor_active?
  end

  def peer_review_unsubmitted?
    submission = peer_review_sub_assignment&.submissions&.active&.find_by(user_id: @assessor.id)
    submission.blank? || submission.workflow_state == "unsubmitted"
  end

  def create_peer_review_submission(user)
    peer_review_sub_assignment.submit_homework(
      user,
      submission_type: PeerReviewSubAssignment::PEER_REVIEW_SUBMISSION_TYPE,
      submitted_at: peer_reviews_submitted_at
    )
  end
end
