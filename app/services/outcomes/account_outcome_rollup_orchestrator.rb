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
#

module Outcomes
  # Orchestrates outcome rollup calculations for an account when an outcome changes.
  # Processes courses in batches.
  #
  # Usage:
  #   Outcomes::AccountOutcomeRollupOrchestrator.process_account_outcome_change(
  #     account_id: account.id,
  #     outcome_id: outcome.id
  #   )
  class AccountOutcomeRollupOrchestrator < ApplicationService
    BATCH_SIZE = 50
    MAX_ATTEMPTS = 3

    attr_reader :account, :outcome, :progress

    def initialize(account_id:, outcome_id:, progress: nil)
      super()
      @account = Account.find_by(id: account_id)
      raise ArgumentError, "Invalid account_id provided" unless @account

      @outcome = LearningOutcome.find_by(id: outcome_id)
      raise ArgumentError, "Invalid outcome_id provided" unless @outcome

      @progress = progress

      validate_outcome_account!
    end

    # Processes an account outcome change using the Progress.process_job pattern
    # @param account_id [Integer] The ID of the account
    # @param outcome_id [Integer] The ID of the outcome that changed
    # @return [Progress] The progress object for tracking job status
    def self.process_account_outcome_change(account_id:, outcome_id:)
      progress = Progress.create!(
        context: Account.find(account_id),
        tag: "account_outcome_rollup_orchestrator",
        message: "Processing outcome rollup calculations"
      )

      singleton_key = "AccountOutcomeRollupOrchestrator:#{account_id}:#{outcome_id}"

      progress.process_job(self,
                           :perform_rollup_calculation,
                           {
                             priority: Delayed::LOW_PRIORITY,
                             singleton: singleton_key,
                             on_conflict: :use_earliest,
                             max_attempts: MAX_ATTEMPTS
                           },
                           account_id:,
                           outcome_id:)

      progress
    end

    def self.perform_rollup_calculation(progress, account_id:, outcome_id:)
      orchestrator = new(account_id:, outcome_id:, progress:)
      orchestrator.call
    end

    def call
      affected_courses = find_affected_courses
      total_courses = affected_courses.count

      if total_courses.zero?
        progress&.complete!
        return
      end

      progress&.update!(message: "Processing #{total_courses} courses with outcome #{outcome.short_description}")

      processed_count = 0
      affected_courses.find_in_batches(batch_size: BATCH_SIZE) do |course_batch|
        process_course_batch(course_batch)
        processed_count += course_batch.size
        update_progress(processed_count, total_courses)
      end

      progress&.complete!
    end

    private

    def validate_outcome_account!
      outcome_account_id = outcome.context_id if outcome.context_type == "Account"

      return if outcome_account_id && account.id == outcome_account_id

      raise ArgumentError, "Outcome #{outcome.id} does not belong to account #{account.id} or its hierarchy"
    end

    # Finds courses in the account that are affected by the outcome change
    # @return [ActiveRecord::Relation<Course>] Courses that use the outcome
    def find_affected_courses
      account_ids = [account.id] + account.all_accounts.pluck(:id)

      # Get distinct course IDs first to avoid temp table issues with find_in_batches
      course_ids = Course.active
                         .where(account_id: account_ids)
                         .joins(:linked_learning_outcomes)
                         .where(learning_outcomes: { id: outcome.id })
                         .distinct
                         .pluck(:id)

      # Return a simple relation that works with find_in_batches
      Course.where(id: course_ids)
    end

    # Processes a batch of courses
    # @param course_batch [Array<Course>] Batch of courses to process
    def process_course_batch(course_batch)
      course_batch.each do |course|
        CourseOutcomeRollupCalculationService.calculate_for_course_outcome(
          course_id: course.id,
          outcome_id: outcome.id
        )
      rescue => e
        Canvas::Errors.capture_exception(:account_outcome_rollup_orchestrator, e, {
                                           account_id: account.id,
                                           outcome_id: outcome.id,
                                           course_id: course.id
                                         })
        Rails.logger.error("Failed to process course #{course.id} for outcome #{outcome.id}: #{e.message}")
      end
    end

    # Updates progress after processing each batch
    # @param processed_count [Integer] Number of courses processed so far
    # @param total_count [Integer] Total number of courses to process
    def update_progress(processed_count, total_count)
      return unless progress

      percentage = (processed_count.to_f / total_count * 100).round(1)
      progress.update!(
        completion: percentage,
        message: "Processed #{processed_count}/#{total_count} courses (#{percentage}%)"
      )
    end
  end
end
