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

  def required_peer_reviews_count
    peer_review_sub_assignment&.peer_review_count || DEFAULT_PEER_REVIEW_COUNT
  end

  def required_peer_reviews_met?
    completed_assessment_requests.count >= required_peer_reviews_count
  end

  def peer_reviews_submitted_at
    return @peer_reviews_submitted_at if defined?(@peer_reviews_submitted_at)

    required_count = required_peer_reviews_count

    # Use the timestamp of the last review needed to meet the requirement.
    # Extra reviews beyond the required count are excluded so that late
    # submissions cannot push the timestamp past the due date.
    @peer_reviews_submitted_at = if @parent_assignment.rubric.present?
                                   # For assignment with rubric, peer assessment is provided via RubricAssessments
                                   completed_assessment_requests
                                     .joins(:rubric_assessment)
                                     .order("rubric_assessments.created_at ASC")
                                     .pluck("rubric_assessments.created_at")
                                     .first(required_count)
                                     .max
                                 else
                                   # For assignment without rubric, peer assessment is provided via SubmissionComments.
                                   # Group by assessment request to collapse multiple comments per review into one
                                   # timestamp (the earliest comment per AR = when the review was first submitted).
                                   completed_assessment_requests
                                     .joins(:submission_comments)
                                     .group("assessment_requests.id")
                                     .order(Arel.sql("MIN(submission_comments.created_at) ASC"))
                                     .pluck(Arel.sql("MIN(submission_comments.created_at)"))
                                     .first(required_count)
                                     .max
                                 end
  end
end
