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
      @course = Course.find(course_id)
      @student = @course.students.find(student_id)
    rescue ActiveRecord::RecordNotFound => e
      raise ArgumentError, "Invalid course_id (#{course_id}) or student_id (#{student_id}): #{e.message}"
    end

    # @return [Array<Rollup>]
    def call
      execute_with_instrumentation do
        combined_results = gather_results
        return handle_empty_results if combined_results.empty?

        rollups = generate_rollups(combined_results, [student], course)
        store_rollups(rollups)
      end
    end

    private

    def execute_with_instrumentation
      Utils::InstStatsdUtils::Timing.track("rollup.student.runtime") do |timing_meta|
        rollups_created = 0

        begin
          result = yield

          rollups_created = result.is_a?(ActiveRecord::Relation) ? result.count : 0
          timing_meta.tags = { course_id: course.id, records_processed: rollups_created }
          Rails.logger.info("[OutcomeRollup] Successfully created/updated #{rollups_created} rollups for student #{student&.id} in course #{course&.id}")

          InstStatsd::Statsd.distributed_increment("rollup.student.success", tags: Utils::InstStatsdUtils::Tags.tags_for(course.shard))
          InstStatsd::Statsd.count("rollup.student.records_processed", rollups_created, tags: Utils::InstStatsdUtils::Tags.tags_for(course.shard))

          result
        rescue => e
          Rails.logger.error("[OutcomeRollup] Error calculating rollups for student #{student&.id} in course #{course&.id}: #{e.message}")
          timing_meta.tags = { course_id: course.id, error: true }
          InstStatsd::Statsd.distributed_increment("rollup.student.error", tags: Utils::InstStatsdUtils::Tags.tags_for(course.shard))
          InstStatsd::Statsd.count("rollup.student.records_processed", rollups_created, tags: Utils::InstStatsdUtils::Tags.tags_for(course.shard))
          raise e
        end
      end
    end

    # @return [Array<LearningOutcomeResult>]
    def gather_results
      canvas_results = fetch_canvas_results(course:, users: [student])
      os_results = fetch_outcomes_service_results(course:, users: [student])
      combine_results(canvas_results, os_results)
    end

    # @param rollups [Array<Rollup>]
    def store_rollups(rollups)
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

        rows.each_slice(500) do |batch|
          result = OutcomeRollup.upsert_all(
            batch,
            unique_by: %i[course_id user_id outcome_id],
            update_only: %i[calculation_method aggregate_score submitted_at title hide_points last_calculated_at workflow_state],
            returning: %w[id]
          )
          batch_ids = result.map { |row| row["id"] }
          upserted_ids.concat(batch_ids)
        end
      end

      OutcomeRollup.where(id: upserted_ids)
    end

    # @return [ActiveRecord::Relation<OutcomeRollup>]
    def handle_empty_results
      Rails.logger.info("[OutcomeRollup] No results found for student #{student&.id} in course #{course&.id}, skipping rollup")
      InstStatsd::Statsd.distributed_increment("rollup.student.success", tags: Utils::InstStatsdUtils::Tags.tags_for(course.shard))
      InstStatsd::Statsd.count("rollup.student.records_processed", 0, tags: Utils::InstStatsdUtils::Tags.tags_for(course.shard))

      OutcomeRollup.none
    end

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
