# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

class PeerReview::SubmissionUpdaterService < PeerReview::SubmissionCommonService
  def call
    return unless peer_review_sub_assignment.present?
    return unless assessor_active?
    return unless submitted_submission_exists?

    if should_unsubmit_submission?
      unsubmit_submission
    elsif should_update_submission_timestamp?
      update_submission_timestamp
    end
  end

  private

  def peer_review_submission
    @peer_review_submission ||= peer_review_sub_assignment&.submissions&.active&.find_by(user_id: @assessor.id)
  end

  def submitted_submission_exists?
    peer_review_submission.present? && peer_review_submission.workflow_state != "unsubmitted"
  end

  def should_unsubmit_submission?
    # Unsubmit when the assessor no longer has enough completed peer reviews to meet the requirements
    !required_peer_reviews_met?
  end

  def should_update_submission_timestamp?
    correct_submitted_at = peer_reviews_submitted_at
    # Guard against edge cases where completed assessments lack
    # submission comments/rubric assessments (e.g. deleted records, race conditions etc)
    return false unless correct_submitted_at.present?

    peer_review_submission.submitted_at != correct_submitted_at
  end

  def update_submission_timestamp
    # Recalculate timestamp based on the currently present (non-deleted) assessment requests.
    # This ensures the submitted_at reflects when the threshold was actually met
    correct_submitted_at = peer_reviews_submitted_at
    return unless correct_submitted_at.present?

    peer_review_submission.update!(
      submitted_at: correct_submitted_at
    )
    peer_review_submission
  end

  def unsubmit_submission
    peer_review_submission.update!(
      workflow_state: "unsubmitted",
      submitted_at: nil,
      submission_type: nil
    )
    peer_review_submission
  end
end
