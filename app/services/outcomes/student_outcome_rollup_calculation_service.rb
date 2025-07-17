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
  # Calculates and persists outcome rollups for a single student in a course.
  #
  # Usage:
  #   Outcomes::StudentOutcomeRollupCalculationService.call(course_id: course.id, student_id: student.id)
  class StudentOutcomeRollupCalculationService < ApplicationService
    include Outcomes::ResultAnalytics
    include OutcomesServiceAuthoritativeResultsHelper
    include CanvasOutcomesHelper

    attr_reader :course, :student

    class << self
      # Schedule a delayed job to calculate outcome rollups for a student in a course.
      # This method creates a singleton delayed job that will be scheduled to run after
      # a short delay. If an existing job exists for the same course/student pair,
      # it will be replaced with this new job.
      #
      # @param course_id [Integer] The ID of the course containing the outcomes
      # @param student_id [Integer] The ID of the student for whom to calculate outcome rollups
      def calculate_for_student(course_id:, student_id:)
        delay(run_at: 1.minute.from_now,
              on_conflict: :overwrite,
              singleton: "calculate_for_student:#{course_id}:#{student_id}")
          .call(course_id:, student_id:)
      end

      # Schedule outcome rollup calculations for all students in a course
      #
      # @param course_id [Integer] the ID of the course to calculate rollups for
      def calculate_for_course(course_id:)
        course = Course.find(course_id)

        course.students.find_in_batches do |student_batch|
          student_batch.each do |student|
            calculate_for_student(course_id:, student_id: student.id)
          end
        end
      end
    end

    # @param course_id [Integer] the course_id whose outcomes to roll up
    # @param student_id [Integer] the student_id for whom to calculate rollups
    def initialize(course_id:, student_id:)
      super()
      @course  = Course.find(course_id)
      @student = User.find(student_id)
    end

    # Runs the full calculation and returns student outcome rollups.
    # @return [Array<Rollup>]
    def call
      # Fetch both Canvas and Outcomes Service results
      canvas_results = fetch_canvas_results
      os_results     = fetch_outcomes_service_results

      combined_results = combine_results(canvas_results, os_results)
      return [] if combined_results.empty?

      generate_student_rollups(combined_results)
    end

    private

    # Generates student outcome rollups from the provided results
    # @param combined_results [Array<LearningOutcomeResult>]
    # @return [Array<Rollup>]
    def generate_student_rollups(combined_results)
      return [] if combined_results.empty?

      ActiveRecord::Associations.preload(combined_results, :learning_outcome)
      outcome_results_rollups(
        results: combined_results,
        users: [student],
        context: course
      )
    end

    # @return [ActiveRecord::Relation<LearningOutcomeResult>]
    def fetch_canvas_results
      find_outcome_results(
        student,
        users: [student],
        context: course,
        outcomes: course.linked_learning_outcomes
      )
    end

    # @return [Array<LearningOutcomeResult>]
    def fetch_outcomes_service_results
      # May be Array (in tests stub) or Relation
      new_quiz_assignments = Assignment.active.where(context: course).quiz_lti
      return [] if new_quiz_assignments.blank?

      outcomes = course.linked_learning_outcomes
      return [] if outcomes.blank?

      begin
        os_results_json = find_outcomes_service_outcome_results(
          users: [student],
          context: course,
          outcomes:,
          assignments: new_quiz_assignments
        )
        return [] if os_results_json.blank?
      rescue => e
        Rails.logger.error("Failed to fetch outcomes service results: #{e.message}")
        raise e
      end

      handle_outcomes_service_results(
        os_results_json,
        course,
        outcomes,
        [student],
        new_quiz_assignments
      )
    end

    # Combines and deduplicates results from two sources
    # @param canvas_results [ActiveRecord::Relation<LearningOutcomeResult>, Array<LearningOutcomeResult>]
    # @param outcomes_service_results [Array<LearningOutcomeResult>]
    # @return [Array<LearningOutcomeResult>]
    def combine_results(canvas_results = [], outcomes_results = [])
      return canvas_results.to_a if outcomes_results.blank?
      return outcomes_results if canvas_results.blank?

      # Merge into one array
      all_results = canvas_results.to_a + outcomes_results

      # Deduplicate
      all_results.uniq do |result|
        [
          result.learning_outcome_id,
          result.user_uuid || result.user_id,
          result.associated_asset_id || result.artifact_id
        ]
      end
    end

    # @param rollups [Array<Rollup>]
    def store_rollups(rollups)
      # Validate that we have exactly one student's rollups
      case rollups.size
      when 0
        # Student has been removed from all outcomes, mark all as deleted
        delete_all_student_rollups
        return []
      when 1
        student_rollup = rollups.first
        # When a student has no outcome scores, it means they have no scored outcomes
        if student_rollup.scores.blank?
          delete_all_student_rollups
          return []
        end
      else
        raise ArgumentError, "Expected rollups for exactly one student, got #{rollups.size} students"
      end

      rows = build_rollup_rows(student_rollup)
      outcome_ids = student_rollup.scores.map { |s| s.outcome.id }

      upserted_ids = []
      OutcomeRollup.transaction do
        # If a student has been removed from assignments associated with an outcome
        # They should have those OutcomeRollups marked as deleted
        if outcome_ids.any?
          OutcomeRollup.where(
            course_id: course.id,
            user_id: student.id,
            workflow_state: "active"
          ).where.not(outcome_id: outcome_ids)
                       .update_all(workflow_state: "deleted")
        end

        # Upsert in batches to avoid oversized statements
        rows.each_slice(500) do |batch|
          result = OutcomeRollup.upsert_all(
            batch,
            unique_by: %i[course_id user_id outcome_id],
            update_only: %i[calculation_method aggregate_score last_calculated_at workflow_state],
            returning: %w[id]
          )
          # Collect generated or updated ids
          batch_ids = result.map { |row| row["id"] }
          upserted_ids.concat(batch_ids)
        end
      end

      # Reload persisted records to ensure ActiveRecord objects
      OutcomeRollup.where(id: upserted_ids)
    end

    def build_rollup_rows(rollup)
      rollup.scores.map do |score|
        {
          root_account_id: course.root_account_id,
          course_id: course.id,
          user_id: student.id,
          outcome_id: score.outcome.id,
          calculation_method: score.outcome.calculation_method,
          aggregate_score: score.score,
          workflow_state: "active",
          last_calculated_at: Time.current,
        }
      end
    end

    # Helper method to delete all active rollups for the student
    def delete_all_student_rollups
      OutcomeRollup.where(
        course_id: course.id,
        user_id: student.id,
        workflow_state: "active"
      ).update_all(
        workflow_state: "deleted"
      )
    end
  end
end
