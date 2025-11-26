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

class PeerReview::AllocationService < ApplicationService
  def initialize(assignment:, assessor:)
    super()
    @assignment = assignment
    @assessor = assessor
  end

  def allocate
    validation_result = validate
    return validation_result unless validation_result[:success]

    ongoing_review = find_ongoing_review
    return success_result(ongoing_review) if ongoing_review

    submission_to_review = find_available_submission
    return error_result(:no_submissions_available, I18n.t("There are no peer reviews available to allocate to you.")) unless submission_to_review

    # Lock the submission to prevent race conditions during concurrent allocations
    # Create the assessment request (assign_peer_review handles duplicates)
    assessment_request = submission_to_review.with_lock do
      @assignment.assign_peer_review(@assessor, submission_to_review.user)
    end
    success_result(assessment_request)
  end

  private

  def validate
    # Validation: Feature flag must be enabled
    unless @assignment.context.feature_enabled?(:peer_review_allocation_and_grading)
      return error_result(:feature_disabled, I18n.t("Peer review allocation and grading feature is not enabled"), :bad_request)
    end

    # Validation: Assignment must have peer reviews enabled
    unless @assignment.has_peer_reviews?
      return error_result(:peer_reviews_not_enabled, I18n.t("Assignment does not have peer reviews enabled"), :bad_request)
    end

    # Validation: Check submission requirement based on assignment configuration
    if @assignment.peer_review_submission_required
      student_submission = @assignment.submissions.find_by(user: @assessor)
      unless student_submission && %w[submitted graded complete].include?(student_submission.workflow_state)
        return error_result(:not_submitted, I18n.t("You must submit the assignment before requesting peer reviews"), :bad_request)
      end
    end

    # Validation: Check if assignment is locked or not yet available
    locked = @assignment.low_level_locked_for?(@assessor)
    if locked
      if locked[:unlock_at]
        return error_result(:not_unlocked, I18n.t("The assignment is locked until %{unlock_at}", unlock_at: locked[:unlock_at]), :bad_request)
      elsif locked[:lock_at]
        return error_result(:locked, I18n.t("This assignment is no longer available as of %{lock_at}", lock_at: locked[:lock_at]), :bad_request)
      end
    end

    # Validation: Check if assessor has reached the required peer review count
    review_count = count_all_reviews
    if review_count >= @assignment.peer_review_count
      return error_result(:limit_reached, I18n.t("You have completed all required peer reviews"), :bad_request)
    end

    { success: true }
  end

  def find_ongoing_review
    AssessmentRequest.for_assignment(@assignment.id)
                     .for_assessor(@assessor.id)
                     .incomplete
                     .first
  end

  def count_all_reviews
    AssessmentRequest.for_assignment(@assignment.id)
                     .for_assessor(@assessor.id)
                     .count
  end

  def find_available_submission
    must_review_submission = find_must_review_submission
    return must_review_submission if must_review_submission

    all_submissions = @assignment.submissions
                                 .where(workflow_state: %w[submitted graded complete])
                                 .where.not(user_id: @assessor.id)

    return nil if all_submissions.empty?

    # Get submissions already assigned to this assessor for review
    # This ensures that an assessor does not get the same submission assigned multiple times
    already_assigned_user_ids = AssessmentRequest
                                .for_assignment(@assignment.id)
                                .for_assessor(@assessor.id)
                                .pluck(:user_id)

    available_user_ids = all_submissions.pluck(:user_id) - already_assigned_user_ids
    return nil if available_user_ids.empty?

    reviewed_user_ids = AssessmentRequest
                        .for_assignment(@assignment.id)
                        .where(user_id: available_user_ids)
                        .distinct
                        .pluck(:user_id)

    unreviewed_user_ids = available_user_ids - reviewed_user_ids

    if unreviewed_user_ids.any?
      # Return oldest unreviewed submission
      all_submissions.where(user_id: unreviewed_user_ids)
                     .order(:submitted_at)
                     .first
    else
      # All available submissions have been reviewed by someone
      # Return oldest submission even if it has been reviewed
      all_submissions.where(user_id: available_user_ids)
                     .order(:submitted_at)
                     .first
    end
  end

  def find_must_review_submission
    must_review_rules = AllocationRule.active
                                      .where(assignment: @assignment)
                                      .where(assessor_id: @assessor.id)
                                      .where(must_review: true)

    return nil if must_review_rules.empty?

    assessee_ids = must_review_rules.pluck(:assessee_id)
    already_assigned_user_ids = AssessmentRequest
                                .for_assignment(@assignment.id)
                                .for_assessor(@assessor.id)
                                .pluck(:user_id)

    available_user_ids = assessee_ids - already_assigned_user_ids
    return nil if available_user_ids.empty?

    available_submissions = @assignment.submissions
                                       .where(workflow_state: %w[submitted graded complete])
                                       .where(user_id: available_user_ids)

    return nil if available_submissions.empty?

    submission_ids = available_submissions.pluck(:id)
    review_counts = AssessmentRequest
                    .where(asset_type: "Submission", asset_id: submission_ids)
                    .group(:asset_id)
                    .count

    # Choose the submission with fewest reviews, and if tied, the oldest one
    available_submissions.min_by do |submission|
      [review_counts[submission.id] || 0, submission.submitted_at]
    end
  end

  def success_result(assessment_request)
    {
      success: true,
      assessment_request:
    }
  end

  def error_result(error_code, message, status = :bad_request)
    {
      success: false,
      error_code:,
      message:,
      status:
    }
  end
end
