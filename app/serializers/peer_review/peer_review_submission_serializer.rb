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

class PeerReview::PeerReviewSubmissionSerializer
  class MissingPeerReviewSubmissionError < StandardError
    def initialize(message = nil)
      super(message || I18n.t("Submission is missing for PeerReviewSubAssignment"))
    end
  end

  def self.serialize(assignment:, user_id:)
    peer_review_sub_assignment = assignment.peer_review_sub_assignment
    return { has_peer_review_submission: false, submission: nil } unless peer_review_sub_assignment&.active?

    submission = find_peer_review_submission(peer_review_sub_assignment, user_id)

    {
      has_peer_review_submission: submission.present?,
      submission:
    }
  end

  def self.find_peer_review_submission(peer_review_sub_assignment, user_id)
    peer_review_submission = peer_review_sub_assignment.submissions.where(user_id:)
                                                       .where(workflow_state: %w[submitted graded])
                                                       .first

    if peer_review_submission.present?
      peer_review_submission
    else
      any_submission_ever = Submission.unscoped.find_by(assignment_id: peer_review_sub_assignment.id, user_id:)

      if any_submission_ever.nil?
        raise MissingPeerReviewSubmissionError, I18n.t("Submission is missing for PeerReviewSubAssignment %{assignment_id} and user %{user_id}",
                                                       assignment_id: peer_review_sub_assignment.id,
                                                       user_id:)
      else
        nil
      end
    end
  end
end
