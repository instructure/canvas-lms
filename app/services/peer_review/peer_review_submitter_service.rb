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

class PeerReview::PeerReviewSubmitterService < ApplicationService
  DEFAULT_PEER_REVIEW_COUNT = 0
  PEER_REVIEW_SUBMISSION_TYPE = "online_text_entry"
  PEER_REVIEW_SUBMISSION_BODY = "peer_review" # Placeholder text for peer review submission

  def initialize(parent_assignment: nil, assessor: nil)
    super()

    @parent_assignment = parent_assignment
    @assessor = assessor
  end

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

  def peer_review_sub_assignment
    @peer_review_sub_assignment ||= @parent_assignment&.peer_review_sub_assignment
  end

  def peer_review_sub_assignment_active?
    peer_review_sub_assignment.present? && peer_review_sub_assignment.active?
  end

  def peer_reviews_enabled?
    @parent_assignment.present? && @parent_assignment.peer_reviews?
  end

  def assessor_active?
    @assessor.present? && @assessor.workflow_state != "deleted"
  end

  def feature_enabled?
    @parent_assignment&.context&.feature_enabled?(:peer_review_allocation_and_grading)
  end

  def peer_review_submission_supported?
    parent_assignment_active? &&
      peer_reviews_enabled? &&
      peer_review_sub_assignment_active? &&
      assessor_active? &&
      feature_enabled?
  end

  def peer_review_unsubmitted?
    submission = peer_review_sub_assignment&.submissions&.active&.find_by(user_id: @assessor.id)
    submission.blank? || submission.workflow_state == "unsubmitted"
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
    scope = completed_assessment_requests
    return nil if scope.empty?

    if @parent_assignment.rubric.present?
      # For assignment with rubric, peer assessment is provided via RubricAssessments
      scope.joins(:rubric_assessment).minimum("rubric_assessments.created_at")
    else
      # For assignment without rubric, peer assessment is provided via SubmissionComments
      scope.joins(:submission_comments).minimum("submission_comments.created_at")
    end
  end

  def create_peer_review_submission(user)
    peer_review_sub_assignment.submit_homework(
      user,
      submission_type: PEER_REVIEW_SUBMISSION_TYPE,
      body: PEER_REVIEW_SUBMISSION_BODY,
      submitted_at: peer_reviews_submitted_at
    )
  end
end
