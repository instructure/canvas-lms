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
  class StudentOutcomeRollupCalculationService < RollupCommonService
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

      # @param course_id [Integer] the ID of the course to calculate rollups for
      # @param outcome_id [Integer] the ID of the specific outcome to calculate rollups for
      def calculate_for_course_outcome(course_id:, outcome_id:)
        Course.find(course_id)
        LearningOutcome.find(outcome_id)

        # TODO: Implementation steps:
        # 1. Get the course and outcome (done above)
        # 2. Find students who have results for this specific outcome
        # 3. Fetch Canvas results for just this outcome and these students
        # 4. Fetch Outcome Service results for just this outcome and these students
        # 5. Combine results using existing combine_results method
        # 6. Calculate rollups using existing generate_student_rollups method
        # 7. Update OutcomeRollup records (need modified store_rollups for single outcome)
        # 8. Track success/failure metrics
        #
        # REUSABLE METHODS:
        # - combine_results
        # - generate_student_rollups
        # - build_rollup_rows
        #
        # NEED NEW/MODIFIED METHODS:
        # - fetch_canvas_results_for_outcome (filter to specific outcome)
        # - fetch_outcomes_service_results_for_outcome (filter to specific outcome)
        # - store_rollups_for_outcome (only update specific outcome, don't delete others)
      end
    end

    # @param course_id [Integer] the course_id whose outcomes to roll up
    # @param student_id [Integer] the student_id for whom to calculate rollups
    def initialize(course_id:, student_id:)
      super()
      @course = Course.find(course_id)
      @student = @course.students.find(student_id)
    rescue ActiveRecord::RecordNotFound => e
      raise ArgumentError, "Invalid course_id (#{course_id}) or student_id (#{student_id}): #{e.message}"
    end

    # Runs the full calculation and returns student outcome rollups.
    # @return [Array<Rollup>]
    def call
      Utils::InstStatsdUtils::Timing.track("rollup.student.runtime") do |timing_meta|
        rollups_created = 0

        begin
          # Fetch both Canvas and Outcomes Service results
          canvas_results = fetch_canvas_results
          os_results     = fetch_outcomes_service_results

          combined_results = combine_results(canvas_results, os_results)
          if combined_results.empty?
            timing_meta.tags = { course_id: course.id }
            InstStatsd::Statsd.distributed_increment("rollup.student.success", tags: { course_id: course.id })
            InstStatsd::Statsd.count("rollup.student.records_processed", rollups_created, tags: { course_id: course.id })
            return OutcomeRollup.none
          end

          student_rollups = generate_student_rollups(combined_results)
          stored_rollups = store_rollups(student_rollups)

          rollups_created = stored_rollups.is_a?(ActiveRecord::Relation) ? stored_rollups.count : 0
          timing_meta.tags = { course_id: course.id, records_processed: rollups_created }

          InstStatsd::Statsd.distributed_increment("rollup.student.success", tags: { course_id: course.id })
          InstStatsd::Statsd.count("rollup.student.records_processed", rollups_created, tags: { course_id: course.id })

          stored_rollups
        rescue => e
          timing_meta.tags = { course_id: course.id, error: true }
          InstStatsd::Statsd.distributed_increment("rollup.student.error", tags: { course_id: course.id })
          InstStatsd::Statsd.count("rollup.student.records_processed", rollups_created, tags: { course_id: course.id })
          raise e
        end
      end
    end

    private

    # @return [ActiveRecord::Relation<LearningOutcomeResult>]
    def fetch_canvas_results
      # Override to query for a specific student
      super(course:, users: [student])
    end

    # @return [Array<LearningOutcomeResult>]
    def fetch_outcomes_service_results
      super(course:, users: [student])
    end

    # Generates student outcome rollups from the provided results
    # @param combined_results [Array<LearningOutcomeResult>]
    # @return [Array<Rollup>]
    def generate_student_rollups(combined_results)
      generate_rollups(combined_results, [student], course)
    end

    # @param rollups [Array<Rollup>]
    def store_rollups(rollups)
      # Validate that we have exactly one student's rollups
      case rollups.size
      when 0
        # Student has been removed from all outcomes, mark all as deleted
        delete_all_student_rollups
        return OutcomeRollup.none
      when 1
        student_rollup = rollups.first
        # When a student has no outcome scores, it means they have no scored outcomes
        if student_rollup.scores.blank?
          delete_all_student_rollups
          return OutcomeRollup.none
        end
      else
        raise ArgumentError, "Expected rollups for exactly one student, got #{rollups.size} students"
      end

      rows = build_rollup_rows(student_rollup, course, student)
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
