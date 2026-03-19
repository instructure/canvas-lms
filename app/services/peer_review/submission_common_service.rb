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

class PeerReview::SubmissionCommonService < ApplicationService
  DEFAULT_PEER_REVIEW_COUNT = 0

  def initialize(parent_assignment: nil, assessor: nil)
    super()

    @parent_assignment = parent_assignment
    @assessor = assessor
  end

  private

  def peer_review_sub_assignment
    @peer_review_sub_assignment ||= @parent_assignment&.peer_review_sub_assignment
  end

  def assessor_active?
    @assessor.present? && @assessor.workflow_state != "deleted"
  end

  def completed_assessment_requests
    @completed_assessment_requests ||= AssessmentRequest
                                       .complete
                                       .joins(:submission)
                                       .where(
                                         assessor_id: @assessor.id,
                                         submissions: { assignment_id: @parent_assignment.id }
                                       )
  end

  def required_peer_reviews_met?
    required_peer_reviews = peer_review_sub_assignment&.peer_review_count || DEFAULT_PEER_REVIEW_COUNT
    completed_assessment_requests.count >= required_peer_reviews
  end

  def peer_reviews_submitted_at
    return @peer_reviews_submitted_at if defined?(@peer_reviews_submitted_at)

    @peer_reviews_submitted_at = if @parent_assignment.rubric.present?
                                   # For assignment with rubric, peer assessment is provided via RubricAssessments
                                   completed_assessment_requests.joins(:rubric_assessment).minimum("rubric_assessments.created_at")
                                 else
                                   # For assignment without rubric, peer assessment is provided via SubmissionComments
                                   completed_assessment_requests.joins(:submission_comments).minimum("submission_comments.created_at")
                                 end
  end
end
