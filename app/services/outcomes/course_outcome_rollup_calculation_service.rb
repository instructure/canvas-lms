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
  # Calculates and persists outcome rollups for all students in a course for a single outcome.
  #
  # Usage:
  #   Outcomes::CourseOutcomeRollupCalculationService.call(course_id: course.id, outcome_id: outcome.id)
  class CourseOutcomeRollupCalculationService < RollupCommonService
    attr_reader :course, :outcome

    class << self
      # Schedule a delayed job to calculate outcome rollups for a specific outcome in a course.
      # This method creates a singleton delayed job that will be scheduled to run after
      # a short delay. If an existing job exists for the same course/outcome pair,
      # it will be replaced with this new job.
      #
      # @param course_id [Integer] The ID of the course containing the students
      # @param outcome_id [Integer] The ID of the outcome to calculate rollups for
      def calculate_for_course_outcome(course_id:, outcome_id:)
        course = Course.find(course_id)

        delay(run_at: 1.minute.from_now,
              on_conflict: :overwrite,
              singleton: "calculate_for_course_outcome:#{course_id}:#{outcome_id}",
              n_strand: "outcome_rollup_course_#{course.global_id}",
              max_attempts: 3,
              priority: Delayed::LOW_PRIORITY)
          .call(course_id:, outcome_id:)
      end
    end

    # @param course_id [Integer] the course_id whose students to calculate rollups for
    # @param outcome_id [Integer] the outcome_id to calculate rollups for
    def initialize(course_id:, outcome_id:)
      super()
      @course = Course.find(course_id)
      @outcome = LearningOutcome.find(outcome_id)

      # Verify the outcome is linked to the course
      unless @course.linked_learning_outcomes.exists?(@outcome.id)
        raise ArgumentError, "Outcome #{outcome_id} is not linked to course #{course_id}"
      end
    rescue ActiveRecord::RecordNotFound => e
      raise ArgumentError, "Invalid course_id (#{course_id}) or outcome_id (#{outcome_id}): #{e.message}"
    end

    # @return [ActiveRecord::Relation<OutcomeRollup>]
    def call
      execute_with_instrumentation do
        students = course.students
        return handle_empty_students unless students.exists?

        combined_results = gather_results
        return handle_empty_results if combined_results.empty?

        rollups = generate_rollups(combined_results, students, course)
        store_rollups_for_outcome(rollups, students)
      end
    end

    private

    # Executes the core rollup logic with instrumentation and error handling
    def execute_with_instrumentation
      Utils::InstStatsdUtils::Timing.track("rollup.course_outcome.runtime") do |timing_meta|
        rollups_created = 0

        begin
          Rails.logger.info("[OutcomeRollup] Starting rollup calculation for course #{course.id}, outcome #{outcome.id}")

          result = yield

          rollups_created = result.is_a?(ActiveRecord::Relation) ? result.count : 0
          timing_meta.tags = { course_id: course.id, outcome_id: outcome.id, records_processed: rollups_created }

          Rails.logger.info("[OutcomeRollup] Successfully created/updated #{rollups_created} rollups for course #{course.id}, outcome #{outcome.id}")

          InstStatsd::Statsd.distributed_increment("rollup.course_outcome.success",
                                                   tags: Utils::InstStatsdUtils::Tags.tags_for(course.shard))
          InstStatsd::Statsd.count("rollup.course_outcome.records_processed",
                                   rollups_created,
                                   tags: Utils::InstStatsdUtils::Tags.tags_for(course.shard))

          result
        rescue => e
          Rails.logger.error("[OutcomeRollup] Error calculating rollups for course #{course.id}, outcome #{outcome.id}: #{e.message}")
          Rails.logger.error(e.backtrace.first(5).join("\n")) if Rails.env.development?

          timing_meta.tags = { course_id: course.id, outcome_id: outcome.id, error: true }
          InstStatsd::Statsd.distributed_increment("rollup.course_outcome.error",
                                                   tags: Utils::InstStatsdUtils::Tags.tags_for(course.shard))
          InstStatsd::Statsd.count("rollup.course_outcome.records_processed",
                                   rollups_created,
                                   tags: Utils::InstStatsdUtils::Tags.tags_for(course.shard))
          raise e
        end
      end
    end

    # Fetches and combines results from both Canvas and Outcomes Service
    # @return [Array<LearningOutcomeResult>]
    def gather_results
      students = course.students
      canvas_results = fetch_canvas_results(course:, users: students, outcomes: [outcome])
      os_results = fetch_outcomes_service_results(course:, users: students, outcomes: [outcome])

      combined_results = combine_results(canvas_results, os_results)
      Rails.logger.info("[OutcomeRollup] Found #{combined_results.count} results for course #{course.id}, outcome #{outcome.id}")

      combined_results
    end

    # Handles the case when no students are found
    # @return [ActiveRecord::Relation<OutcomeRollup>]
    def handle_empty_students
      Rails.logger.info("[OutcomeRollup] No students found for course #{course.id}, skipping rollup")

      InstStatsd::Statsd.distributed_increment("rollup.course_outcome.success",
                                               tags: Utils::InstStatsdUtils::Tags.tags_for(course.shard))
      InstStatsd::Statsd.count("rollup.course_outcome.records_processed",
                               0,
                               tags: Utils::InstStatsdUtils::Tags.tags_for(course.shard))

      OutcomeRollup.none
    end

    # Handles the case when no results are found
    # @return [ActiveRecord::Relation<OutcomeRollup>]
    def handle_empty_results
      Rails.logger.info("[OutcomeRollup] No results found, marking existing rollups as deleted for course #{course.id}, outcome #{outcome.id}")
      mark_outcome_rollups_deleted

      InstStatsd::Statsd.distributed_increment("rollup.course_outcome.success",
                                               tags: Utils::InstStatsdUtils::Tags.tags_for(course.shard))
      InstStatsd::Statsd.count("rollup.course_outcome.records_processed",
                               0,
                               tags: Utils::InstStatsdUtils::Tags.tags_for(course.shard))

      OutcomeRollup.none
    end

    # @param rollups [Array<Rollup>]
    # @param students [Array<User>]
    # @return [ActiveRecord::Relation<OutcomeRollup>]
    def store_rollups_for_outcome(rollups, students)
      rows = []
      students_with_scores = Set.new

      rollups.each do |rollup|
        user = rollup.context
        rollup.scores.each do |score|
          next unless score.outcome.id == outcome.id
          next if score.score.nil?

          students_with_scores.add(user.id)
          rows << {
            root_account_id: course.root_account_id,
            course_id: course.id,
            user_id: user.id,
            outcome_id: outcome.id,
            calculation_method: outcome.calculation_method,
            aggregate_score: score.score,
            submitted_at: score.submitted_at,
            title: score.title,
            workflow_state: "active",
            last_calculated_at: Time.current,
          }
        end
      end

      students_without_scores = students.reject { |s| students_with_scores.include?(s.id) }

      upserted_ids = []
      OutcomeRollup.transaction do
        if students_without_scores.any?
          Rails.logger.info("[OutcomeRollup] Marking #{students_without_scores.count} student rollups as deleted for outcome #{outcome.id}")
          OutcomeRollup.where(
            course_id: course.id,
            user_id: students_without_scores.map(&:id),
            outcome_id: outcome.id,
            workflow_state: "active"
          ).update_all(workflow_state: "deleted")
        end

        if rows.any?
          rows.each_slice(500) do |batch|
            result = OutcomeRollup.upsert_all(
              batch,
              unique_by: %i[course_id user_id outcome_id],
              update_only: %i[calculation_method aggregate_score submitted_at title last_calculated_at workflow_state],
              returning: %w[id]
            )
            batch_ids = result.map { |row| row["id"] }
            upserted_ids.concat(batch_ids)
          end
        end
      end

      OutcomeRollup.where(id: upserted_ids)
    end

    def mark_outcome_rollups_deleted
      OutcomeRollup.where(
        course_id: course.id,
        outcome_id: outcome.id,
        workflow_state: "active"
      ).update_all(
        workflow_state: "deleted"
      )
    end
  end
end
