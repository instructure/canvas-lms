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

    # Lock on the assessor's submission to ensure only one allocation process
    # runs at a time for this assessor, preventing duplicate allocations
    assessor_submission = @assignment.submissions.find_by(user: @assessor)
    assessor_submission.with_lock do
      ongoing_reviews = find_ongoing_reviews
      total_assigned = count_all_reviews
      remaining_needed = @assignment.peer_review_count - total_assigned

      available_submissions = preload_available_submissions

      if total_assigned.zero? && available_submissions.empty?
        return error_result(:no_submissions_available, I18n.t("There are no peer reviews available to allocate to you."))
      end

      submissions_to_allocate = select_submissions_to_allocate(available_submissions, remaining_needed)
      newly_allocated = []
      submissions_to_allocate.each do |submission|
        assessment_request = @assignment.assign_peer_review(@assessor, submission.user)
        newly_allocated << assessment_request if assessment_request
      end

      all_requests = ongoing_reviews + newly_allocated
      return success_result(all_requests)
    end
  end

  private

  def validate
    # Validation: Feature flag must be enabled
    unless @assignment.context.feature_enabled?(:peer_review_allocation_and_grading)
      return error_result(:feature_disabled, I18n.t("Peer review allocation and grading feature is not enabled"), :forbidden)
    end

    # Validation: Assignment must have peer reviews enabled
    unless @assignment.has_peer_reviews?
      return error_result(:peer_reviews_not_enabled, I18n.t("Assignment does not have peer reviews enabled"), :forbidden)
    end

    # Validation: Check submission requirement based on assignment configuration
    if @assignment.peer_review_submission_required
      student_submission = @assignment.submissions.find_by(user: @assessor)
      unless student_submission&.has_submission?
        return error_result(:not_submitted, I18n.t("You must submit the assignment before requesting peer reviews"), :forbidden)
      end
    end

    # Validation: Check if assignment is locked or not yet available
    locked = @assignment.low_level_locked_for?(@assessor)
    if locked
      if locked[:unlock_at]
        return error_result(:not_unlocked, I18n.t("The assignment is locked until %{unlock_at}", unlock_at: locked[:unlock_at]), :forbidden)
      elsif locked[:lock_at]
        return error_result(:locked, I18n.t("This assignment is no longer available as of %{lock_at}", lock_at: locked[:lock_at]), :forbidden)
      end
    end

    # Validation: Check if peer review start date has passed
    peer_review_start_date = peer_review_start_date_for_assessor
    if peer_review_start_date && peer_review_start_date > Time.zone.now
      return error_result(:peer_review_not_started, I18n.t("Peer reviews are not available until %{start_date}", start_date: peer_review_start_date), :forbidden)
    end

    # Validation: Check if past peer review lock date
    peer_review_lock_date = peer_review_lock_date_for_assessor
    if peer_review_lock_date && peer_review_lock_date < Time.zone.now
      return error_result(:peer_review_locked, I18n.t("This assignment is no longer available as of %{lock_date}", lock_date: peer_review_lock_date), :forbidden)
    end

    # Validation: Check if assessor has reached the required peer review count
    review_count = count_all_reviews
    if review_count >= @assignment.peer_review_count
      return error_result(:limit_reached, I18n.t("You have been assigned all required peer reviews"), :forbidden)
    end

    { success: true }
  end

  def find_ongoing_reviews
    AssessmentRequest.for_assignment(@assignment.id)
                     .for_assessor(@assessor.id)
                     .incomplete
                     .to_a
  end

  def count_all_reviews
    AssessmentRequest.for_assignment(@assignment.id)
                     .for_assessor(@assessor.id)
                     .count
  end

  def preload_available_submissions
    already_assigned_user_ids = AssessmentRequest
                                .for_assignment(@assignment.id)
                                .for_assessor(@assessor.id)
                                .pluck(:user_id)

    rules = fetch_allocation_rules
    must_not_review_user_ids = rules[:must_not_review]

    # Find submissions excluding those by the assessor,
    # already assigned users, and users in must_not_review allocation rule list
    submissions = @assignment.submissions
                             .active
                             .having_submission
                             .where.not(user_id: [@assessor.id, *already_assigned_user_ids, *must_not_review_user_ids])

    unless @assignment.peer_review_across_sections
      section_ids = assessor_section_ids
      if section_ids.any?
        section_user_ids = Enrollment.where(course_id: @assignment.context_id)
                                     .where(type: "StudentEnrollment")
                                     .where(workflow_state: "active")
                                     .where(course_section_id: section_ids)
                                     .distinct
                                     .pluck(:user_id)
        submissions = submissions.where(user_id: section_user_ids)
      end
    end

    submissions.preload(:user).to_a
  end

  def assessor_section_ids
    Enrollment.where(user_id: @assessor.id, course_id: @assignment.context_id)
              .where(type: "StudentEnrollment")
              .where(workflow_state: "active")
              .pluck(:course_section_id)
  end

  def select_submissions_to_allocate(available_submissions, count)
    return [] if available_submissions.empty?

    rules = fetch_allocation_rules
    review_counts = calculate_review_counts(available_submissions)

    # Sort by priority tier (1=must, 2=should, 3=regular, 4=should_not), then review count, then date
    available_submissions.sort_by do |sub|
      priority = submission_priority(sub.user_id, rules)
      [priority, review_counts[sub.id] || 0, sub.submitted_at]
    end.take(count)
  end

  # Fetches all allocation rules for the assessor in a single query
  # Returns a hash with rule categories: must_review, should_review, must_not_review, should_not_review
  def fetch_allocation_rules
    all_rules = AllocationRule.active
                              .where(assignment: @assignment, assessor_id: @assessor.id)
                              .pluck(:must_review, :review_permitted, :assessee_id)

    {
      must_review: all_rules.select { |must, permitted, _| must && permitted }.map(&:last),
      should_review: all_rules.select { |must, permitted, _| !must && permitted }.map(&:last),
      must_not_review: all_rules.select { |must, permitted, _| must && !permitted }.map(&:last),
      should_not_review: all_rules.select { |must, permitted, _| !must && !permitted }.map(&:last)
    }
  end

  # Determines priority tier for a submission based on allocation rules
  # Returns: 1 (must_review), 2 (should_review), 3 (regular), or 4 (should_not_review)
  def submission_priority(user_id, rules)
    return 1 if rules[:must_review].include?(user_id)
    return 2 if rules[:should_review].include?(user_id)
    return 4 if rules[:should_not_review].include?(user_id)

    3 # regular submission (no rules)
  end

  # Calculates how many reviews each submission has received
  def calculate_review_counts(submissions)
    submission_ids = submissions.map(&:id)
    AssessmentRequest
      .where(asset_type: "Submission", asset_id: submission_ids)
      .group(:asset_id)
      .count
  end

  def success_result(assessment_requests)
    {
      success: true,
      assessment_requests:
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

  def peer_review_dates_for_assessor
    peer_review_overrides = @assignment.peer_review_overrides_for_dates
    return @peer_review_dates_for_assessor = nil unless peer_review_overrides

    user_assignment = @assignment.overridden_for(@assessor)
    applied_override = user_assignment.applied_overrides&.first
    override_hash = build_override_hash(applied_override)

    peer_review_dates = @assignment.peer_review_dates_for_override(override_hash, peer_review_overrides)
    return @peer_review_dates_for_assessor = nil unless peer_review_dates

    @peer_review_dates_for_assessor = {
      dates: peer_review_dates,
      user_assignment:
    }
  end

  def peer_review_start_date_for_assessor
    result = @peer_review_dates_for_assessor ||= peer_review_dates_for_assessor
    return nil unless result

    # Use unlock_at if set, otherwise fall back to parent assignment's due_at
    result[:dates][:unlock_at] || result[:user_assignment].due_at
  end

  def peer_review_lock_date_for_assessor
    result = @peer_review_dates_for_assessor ||= peer_review_dates_for_assessor
    return nil unless result

    result[:dates][:lock_at]
  end
end

def build_override_hash(applied_override)
  if applied_override
    { id: applied_override.id, base: false }
  else
    { id: nil, base: true }
  end
end
