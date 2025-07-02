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
    end

    # @param course_id [Integer] the course_id whose outcomes to roll up
    # @param student_id [Integer] the student_id for whom to calculate rollups
    def initialize(course_id:, student_id:)
      super()
      @course  = Course.find(course_id)
      @student = User.find(student_id)
    end

    # Runs the full calculation and persists the calculation.
    #
    # @return [Array<OutcomeRollup>] the created or updated rollup records
    def call
      # TODO: implement fetch data, generate rollups, persist, return rollups
      []
    end

    private

    # @return [Array<LearningOutcome>]
    def load_course_outcomes
      # TODO: load course.learning_outcomes
      []
    end

    # @return [Array<OutcomeRollup>]
    def generate_student_rollups
      # TODO: fetch_canvas_results, fetch_outcomes_service_results, combine_results, map to OutcomeRollup
      []
    end

    # @return [Array<LearningOutcomeResult>]
    def fetch_canvas_results
      # TODO: fetch results from Canvas
      []
    end

    # @return [Array<LearningOutcomeResult>]
    def fetch_outcomes_service_results
      # TODO: fetch results from Outcomes Service
      []
    end

    # @param canvas_results [Array<LearningOutcomeResult>]
    # @param outcomes_service_results [Array<LearningOutcomeResult>]
    # @return [Array<LearningOutcomeResult>]
    def combine_results
      # TODO: merge result sets
      []
    end

    # @param rollups [Array<OutcomeRollup>]
    def store_rollups(rollups)
      # TODO: upsert OutcomeRollup records
    end
  end
end
